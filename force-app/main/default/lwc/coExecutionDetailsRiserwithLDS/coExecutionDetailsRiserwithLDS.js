import { LightningElement,api,wire,track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
import { getLocationService } from 'lightning/mobileCapabilities';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import USER_ID from '@salesforce/user/Id';
import WORKORDERTYPE_NAME_FIELD from '@salesforce/schema/WorkOrder.WorkType.Name';
import LightningAlert from 'lightning/alert';
import { gql, graphql } from 'lightning/uiGraphQLApi';
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
export default class CoExecutionDetailsRiserwithLDS extends LightningElement {
 @api recordId; // WorkOrderid
     error;
    @track lat;
    @track long;
     serviceAppointments;
    serviceAppointmentId;
    workstepsId;
    @track username;
    @track worktypename;
    @track showRiserMaintenance=false;
    @track showRiserReplacement=false;
    @track showRiserPainting=false;
    @track showworktypemessage;


    //get related service appointments
     get variables() {
    return { workOrderId: this.recordId };
    }

    @wire(getRecord, {
    recordId: '$recordId',
    fields: [WORKORDERTYPE_NAME_FIELD]
    })
    wiredWorkOrder({ data, error }) {
        if (data) {
            this.worktypename = getFieldValue(data, WORKORDERTYPE_NAME_FIELD);
            console.log('this.worktypename::',this.worktypename);

            if(this.worktypename !=null){
                this.checkworkordertype();
            }
        }else if(error){
            console.log('error in fetching workorder.worktype.name');
        }
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
            console.error('Error in fetching service appointments::',errors);
        }
    }

    checkworkordertype(){
        console.log('checkworkordertype::');
        if(this.worktypename == 'Riser Maintenance' || this.worktypename == 'I&C Commercial Maintenance'){
             this.showRiserMaintenance=true;
             this.showRiserReplacement=false;
             this.showRiserPainting=false;
        }

        if(this.worktypename == 'Riser Replacement'){
             this.showRiserMaintenance=false;
             this.showRiserReplacement=true;
             this.showRiserPainting=false;
        }

        if(this.worktypename == 'Riser Painting'){
             this.showRiserMaintenance=false;
             this.showRiserReplacement=false;
             this.showRiserPainting=true;
        }

        // if(this.worktypename != 'Riser Maintenance' && this.worktypename != 'Riser Replacement' && this.worktypename != 'Riser Painting'){
        //     this.showworktypemessage='Something Went Wrong,Please Try Later';
        //      this.showRiserMaintenance=false;
        //      this.showRiserReplacement=false;
        //      this.showRiserPainting=false;
        // }

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


}