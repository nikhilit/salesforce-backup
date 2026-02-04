import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
import { getLocationService } from 'lightning/mobileCapabilities';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import LightningAlert from 'lightning/alert';
import { gql, graphql } from 'lightning/uiGraphQLApi';
import userId from '@salesforce/user/Id';
import SA_ID from '@salesforce/schema/ServiceAppointment.Id';

import SA_CHECKOUT_TIME from '@salesforce/schema/ServiceAppointment.O_MCheckOutTimestamp__c';
import SA_LATLON from '@salesforce/schema/ServiceAppointment.Check_Out_Lat_Long__c';
// import SA_LAT from '@salesforce/schema/ServiceAppointment.Check_In_Lat_Long__c';
// import SA_LON from '@salesforce/schema/ServiceAppointment.Check_In_Lat_Long__c';
import SA_STATUS from '@salesforce/schema/ServiceAppointment.Status';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import WO_ID from '@salesforce/schema/WorkOrder.Id';
import WO_STATUS from '@salesforce/schema/WorkOrder.Status';
import WO_APPOINTMENT_STATUS from '@salesforce/schema/WorkOrder.Appointment_Status__c';
import WO_ATTENDED_DATE from '@salesforce/schema/WorkOrder.Completion_Datetime__c';

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
export default class CheckoutICCommercialComp extends LightningElement {

    @api recordId; // WorkOrderid

    @track lat;
    @track long;
    @track lstMarkers = [];
    @track showEnableMessage = false;
    @track showMap = true;
    @track showSuccessMessage = false;
    @track isLoading = false;
    serviceAppointment;
    serviceAppointmentId;
    workstepsId;
    serviceAppointments;
    isCheckinDone=false;

    get isOnline() {
        return navigator.onLine;
    }

     @wire(getRecord, {
    recordId: '$recordId',
    fields: [SA_LATLON]
    })
    serviceAppointment;

    get latitude() {
    return getFieldValue(this.serviceAppointment.data, 
        'ServiceAppointment.Check_Out_Lat_Long__Latitude__s'
    );
    }

    get longitude() {
        return getFieldValue(this.serviceAppointment.data, 
            'ServiceAppointment.Check_Out_Lat_Long__Longitude__s'
        );
    }


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

    
    //get related worksteps
     @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'WorkSteps',
        fields: ['WorkStep.Id','WorkStep.Name','WorkStep.Status']
    })
    wiredCheckoutStep({ data, error }) {

        if (data && data.records && data.records.length > 0) {

           let selectedworkst = data.records.find(r => {
                let wsName = this.normalize(r.fields.Name.value);
                return wsName === 'checkout';
            });

            if (!selectedworkst) {
                console.warn('No "Check-out" WorkStep found');
                return;
            }

            this.workstepsId = selectedworkst.fields.Id.value;
            console.log('WorkStep ID:', this.workstepsId);

        } else if (error) {
            console.error('Error fetching work steps:', error);
        }
    }

    //get whether checkin is done or not
    // Normalize text (lowercase + remove spaces + remove hyphens)
        normalize(text) {
            return text ? text.toLowerCase().replace(/[\s-]/g, '') : '';
        }

        @wire(getRelatedListRecords, {
            parentRecordId: '$recordId',
            relatedListId: 'WorkSteps',
            fields: ['WorkStep.Id','WorkStep.Name','WorkStep.Status']
        })
        wiredCheckinStep({ data, error }) {
            if (data && data.records && data.records.length > 0) {

                let selectedworkst = data.records.find(r => {
                    let wsName = this.normalize(r.fields.Name.value);
                    return wsName === 'checkin';  // normalized target
                });

                if (!selectedworkst) {
                    console.warn('No "Check-in" WorkStep found');
                    return;
                }

                // Get Status
                const status = selectedworkst.fields.Status.value;
                console.log('Check-In Status:', status);

                // Flag to use in template
                this.isCheckinDone = (status?.toLowerCase() === 'completed');

                console.log('Is Check-In Completed?:::', this.isCheckinDone);

            } else if (error) {
                console.error('Error fetching work steps:', error);
            }
        }



   //call checkin on connectedcallback
    // async connectedCallback() {
    //     this.isLoading = true;
    //     await this.handleGetLocation();
    //     await this.autoCheckOut();
    //     this.isLoading = false;
    // }

   async handleCheckOut(){
        if (!this.isCheckinDone) {
            console.log('checkin is not done::');
             LightningAlert.open({
                message: 'Please Checkin Before Checkout',
                theme: 'warning',   
                label: 'Warning'    
            });
            return;
        }
        this.isLoading = true;
        await this.handleGetLocation();
        await this.autoCheckOut();
        this.isLoading = false;
    }

    //get lat long
    handleGetLocation() {
            console.log('handleGetLocation:::');
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
                // this.showToast('Error', 'GPS not enabled', 'error');
                  LightningAlert.open({
                    message: 'GPS not enabled',
                    theme: 'error',   
                    label: 'Error' 
                });
            });
    }

    //auto checkout
    async autoCheckOut() {
        console.log('autoCheckOut:::');
        if (!this.lat || !this.long) {
            // this.showToast('Error', 'GPS location not found', 'error');
             LightningAlert.open({
                message: 'GPS location not found',
                theme: 'error',   // red error dialog
                label: 'Error'    // header text
            });
            return;
        }

    
         if (!this.workstepsId) {
           // this.showToast('Error', 'No Service Appointment found', 'error');
             LightningAlert.open({
                message: 'No WorkStep found.',
                theme: 'error',   // red error dialog
                label: 'Error'    // header text
            });
            return;
        }
            if (!this.serviceAppointmentId) {
           // this.showToast('Error', 'No Service Appointment found', 'error');
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
            saFields[SA_CHECKOUT_TIME.fieldApiName] = new Date().toISOString();
            // saFields[SA_LAT.fieldApiName] = this.lat;
            // saFields[SA_LON.fieldApiName] = this.long;
            saFields['Check_Out_Lat_Long__Latitude__s'] = this.lat;
            saFields['Check_Out_Lat_Long__Longitude__s'] = this.long;

            saFields[SA_STATUS.fieldApiName] = 'Completed';

            await updateRecord({ fields: saFields });

            //update workorder
            const woFields = {};
            woFields[WO_ID.fieldApiName] = this.recordId;
            woFields[WO_STATUS.fieldApiName] = 'Completed';
            woFields[WO_APPOINTMENT_STATUS.fieldApiName]='Completed';
            woFields[WO_ATTENDED_DATE.fieldApiName] = new Date().toISOString();

            await updateRecord({ fields: woFields });
            
            //update worksteps
            const wostepsfields = {};
            wostepsfields[WSTEP_ID.fieldApiName] = this.workstepsId;
            wostepsfields[WSTEP_STATUS.fieldApiName] = 'Completed';
            await updateRecord({ fields: wostepsfields });

            // UI Feedback
            this.showSuccessMessage = true;
            
            setTimeout(() => {
                history.back();
            }, 500);

            this.showToast('Success', 'Check-Out successful', 'success');

        } catch (err) {
            this.showToast('Error', err.body.message, 'error');
        }
    }

    showToast(title, msg, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message: msg, variant }));
    }
}