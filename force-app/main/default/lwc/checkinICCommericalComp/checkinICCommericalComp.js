import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
import { getLocationService } from 'lightning/mobileCapabilities';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import LightningAlert from 'lightning/alert';
import { gql, graphql } from 'lightning/uiGraphQLApi';
import USER_ID from '@salesforce/user/Id';
import USERNAME_FIELD from '@salesforce/schema/User.Username';
import SA_ID from '@salesforce/schema/ServiceAppointment.Id';
import SA_CHECKIN_TIME from '@salesforce/schema/ServiceAppointment.O_MCheckInTimestamp__c';
import SA_LATLON from '@salesforce/schema/ServiceAppointment.Check_In_Lat_Long__c';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import SA_STATUS from '@salesforce/schema/ServiceAppointment.Status';

import WO_ID from '@salesforce/schema/WorkOrder.Id';
import WO_APPOINTMENT_STATUS from '@salesforce/schema/WorkOrder.Appointment_Status__c';
import WO_STATUS from '@salesforce/schema/WorkOrder.Status';
import WO_ATTENDED_DATE from '@salesforce/schema/WorkOrder.Attended_Date__c';
import WSTEP_ID from '@salesforce/schema/WorkStep.Id';
import WSTEP_STATUS from '@salesforce/schema/WorkStep.Status';
const GET_SERVICE_APPOINTMENTS = gql`
    query getServiceAppointments($workOrderId: ID!) {
    uiapi {
        query {
            ServiceAppointment(
                where: { Work_Order__c: { eq: $workOrderId } }
                first: 5
            ) {
                edges {
                    node {
                        Id
                        Work_Order__c { value }
                    }
                }
            }
        }
    }
}
`;

const GET_DOC_APPROVAL_STATUS = gql`
    query GetDocApprovalStatus($username: String!) {
        uiapi {
            query {
                Document__c(
                    where: {
                        Submitted_Agent_Name__c: { eq: $username }
                    }
                    first: 5
                ) {
                    edges {
                        node {
                            Approval_Status_O_M__c {
                                value
                                label
                            }
                        }
                    }
                }
            }
        }
    }
`;



export default class CheckinICCommercialComp extends LightningElement {

    @api recordId; // WorkOrderid
     error;
    @track lat;
    @track long;
    @track lstMarkers = [];
    @track showEnableMessage = false;
    @track showMap = true;
    @track showSuccessMessage = false;
    @track isLoading = false;
    @track mapAvailable = true;
     @track username;
     docVarsReady=false;

    get isOnline() {
        return navigator.onLine;
    }
    serviceAppointments;
    serviceAppointmentId;
    workstepsId;
    approvalStatus;

    @wire(getRecord, {
    recordId: '$recordId',
    fields: [SA_LATLON]
    })
    serviceAppointment;

    get latitude() {
        return getFieldValue(this.serviceAppointment.data, 
            'ServiceAppointment.Check_In_Lat_Long__Latitude__s');
    }

    get longitude() {
        return getFieldValue(this.serviceAppointment.data, 
            'ServiceAppointment.Check_In_Lat_Long__Longitude__s');
    }

    //get related service appointments
    // @wire(getRelatedListRecords, {
    //     parentRecordId: '$recordId',
    //     relatedListId: 'ServiceAppointments',
    //     fields: [
    //         'ServiceAppointment.Id',
    //         'ServiceAppointment.Status'
    //     ]
    // })
    // wiredServiceAppointments({ data, error }) {
    //     if (data && data.records.length > 0) {

    //         let selectedSA = data.records[0]; // first SA

    //         this.serviceAppointmentId = selectedSA.fields.Id.value;

    //         console.log('Picked SA:', this.serviceAppointmentId);

    //     } else if (error) {
    //         console.error('Error fetching service appointments:', error);
    //     }
    // }

       //get related service appointments
     get variables() {
    return { workOrderId: this.recordId };
    }


    @wire(graphql, { query: GET_SERVICE_APPOINTMENTS, variables: '$variables' })
    wiredAppointments({ data, errors }) {
        if (data) {
            this.serviceAppointments =
                data.uiapi.query.ServiceAppointment.edges.map(e => e.node);

            if (this.serviceAppointments.length > 0) {
                this.serviceAppointmentId = this.serviceAppointments[0].Id;
                console.log("Selected ServiceAppointment:", this.serviceAppointmentId);
            }
        } else if (errors) {
            console.error(errors);
        }
    }

    
    //get related worksteps
    // Normalize text (lowercase + remove spaces + remove hyphens)
    normalize(text) {
        return text ? text.toLowerCase().replace(/[\s-]/g, '') : '';
    }

    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'WorkSteps',
        fields: ['WorkStep.Id','WorkStep.Name','WorkStep.Status']
    })
    wiredSteps({ data, error }) {
        if (data && data.records && data.records.length > 0) {

            let selectedworkst = data.records.find(r => {
                let wsName = this.normalize(r.fields.Name.value);
                return wsName === 'checkin';  // normalized target
            });

            if (!selectedworkst) {
                console.warn('No "Check-in" WorkStep found');
                return;
            }

            this.workstepsId = selectedworkst.fields.Id.value;
            console.log('WorkStep ID:', this.workstepsId);

        } else if (error) {
            console.error('Error fetching work steps:', error);
        }
    }
     // ---------------------- GET USER NAME ----------------------
    @wire(getRecord, { recordId: USER_ID, fields: [USERNAME_FIELD] })
    wiredUser({ data, error }) {
        if (data) {
            this.username = data.fields.Username.value;
            console.log(' this.username::', this.username);
            // this.fetchApprovalStatus();
               this.docVarsReady = true; 
        } else if (error) {
            console.error('Error fetching user:', error);
        }
    }
       get docvars() {
    return this.docVarsReady ? { username: this.username } : null;
}


      // ------------ GRAPHQL APPROVAL STATUS -----------------
@wire(graphql, { query: GET_DOC_APPROVAL_STATUS, variables: '$docvars' })
wiredApprovals({ data, errors }) {

    console.log('wiredApprovals raw:', data);

    if (errors) {
        console.error('GraphQL Errors:', errors);
        return;
    }

    if (data?.uiapi?.query?.Document__c?.edges?.length) {
        const doc = data.uiapi.query.Document__c.edges[0].node;

        this.approvalStatus = doc?.Approval_Status_O_M__c?.value;
        console.log('Approval Status:', this.approvalStatus);
    } 
    else {
        console.log('No matching Document__c found.');
        this.approvalStatus = null;
    }
}


//     get docvariables() {
//     return { username: this.username };
//     }

//  @wire(graphql, { query: GET_DOC_APPROVAL_STATUS, variables: '$docvariables' })
//     fetchApprovalStatus({ data, errors }) {
//         if (data) {
//             this.documentss =
//                 data.uiapi.query.Document__c.edges.map(e => e.node);

//             if (this.serviceAppointments.length > 0) {
//                 this.approvalStatus = doc?.Approval_Status_O_M__c[0]?.value;
//                 console.log("Selected ServiceAppointment:", this.serviceAppointmentId);
//             }
//         } else if (errors) {
//             console.error(errors);
//         }
//     }


    //  @wire(getRelatedListRecords, {
    //     parentRecordId: '$recordId',
    //     relatedListId: 'WorkSteps',
    //     fields: ['WorkStep.Id','WorkStep.Name','WorkStep.Status']
    // })
    // wiredSteps({ data, error }) {

    //     if (data && data.records && data.records.length > 0) {

    //         let selectedworkst = data.records.find(
    //             r => r.fields.Name.value === 'Check - IN'
    //         );

    //         if (!selectedworkst) {
    //             console.warn('No "Check - IN" WorkStep found');
    //             return;
    //         }

    //         this.workstepsId = selectedworkst.fields.Id.value;

    //         console.log('WorkStep ID:', this.workstepsId);

    //     } else if (error) {
    //         console.error('Error fetching work steps:', error);
    //     }
    // }

    async handleCheckIn() {
    this.isLoading = true;
    // await this.fetchApprovalStatus();
    if (this.approvalStatus !== 'Approved') {
        await LightningAlert.open({
            message: 'Please upload TBT Documents and get them approved.',
            theme: 'warning',
            label: 'Warning'
        });
        this.isLoading = false; 
        return;
    }

    await this.handleGetLocation();
    await this.autoCheckIn();
    this.isLoading = false;
 }

    //get lat long
    handleGetLocation() {
        return getLocationService()
            .getCurrentPosition()
            .then((pos) => {
                this.lat = pos.coords.latitude;
                this.long = pos.coords.longitude;

                this.lstMarkers = [{
                    location: {
                        Latitude: this.lat,
                        Longitude: this.long
                    },
                    title: 'Current Location'
                }];
            })
            .catch(() => {
                this.showEnableMessage = true;
                LightningAlert.open({
                    message: 'GPS not enabled',
                    theme: 'error',   // red error dialog
                    label: 'Error'    // header text
                });
                // this.showToast('Error', 'GPS not enabled', 'error');
            });
    }

    //auto checkin
    async autoCheckIn() {

        if (!this.lat || !this.long) {
            //this.showToast('Error', 'GPS location not found', 'error');
            LightningAlert.open({
                message: 'GPS location not found',
                theme: 'error',   // red error dialog
                label: 'Error'    // header text
            });
            return;
        }

        if (!this.serviceAppointmentId) {
            //this.showToast('Error', 'No Service Appointment found', 'error');
            LightningAlert.open({
                message: 'No Service Appointment found.',
                theme: 'error',   // red error dialog
                label: 'Error'    // header text
            });
            return;
        }

        try {
            //update service appointment
            const saFields = {};
            saFields[SA_ID.fieldApiName] = this.serviceAppointmentId;
            saFields[SA_CHECKIN_TIME.fieldApiName] = new Date().toISOString();
            saFields['Check_In_Lat_Long__Latitude__s'] = this.lat;
saFields['Check_In_Lat_Long__Longitude__s'] = this.long;

            saFields[SA_STATUS.fieldApiName] = 'In Progress';

            await updateRecord({ fields: saFields });

            //update workorder
            const woFields = {};
            woFields[WO_ID.fieldApiName] = this.recordId;
            woFields[WO_STATUS.fieldApiName] = 'In Progress';
            woFields[WO_APPOINTMENT_STATUS.fieldApiName]='In Progress';
            woFields[WO_ATTENDED_DATE.fieldApiName] = new Date().toISOString().slice(0, 10);

            await updateRecord({ fields: woFields });
            
            //update worksteps
            const wostepsfields = {};
            wostepsfields[WSTEP_ID.fieldApiName] = this.workstepsId;
            wostepsfields[WSTEP_STATUS.fieldApiName] = 'Completed';
            await updateRecord({ fields: wostepsfields });

            // UI Feedback
            this.showSuccessMessage = true;
             //to go back
            setTimeout(() => {
                history.back();
            }, 500);
            this.showToast('Success', 'Check-In successful', 'success');

        } catch (err) {
            this.showToast('Error', err.body.message, 'error');
        }
    }

    showToast(title, msg, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message: msg, variant }));
    }
}