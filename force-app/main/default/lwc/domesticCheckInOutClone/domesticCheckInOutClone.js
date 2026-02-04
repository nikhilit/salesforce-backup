import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { getLocationService } from 'lightning/mobileCapabilities';
import { NavigationMixin } from 'lightning/navigation';

import { updateRecord } from 'lightning/uiRecordApi';
import { graphql, gql } from 'lightning/uiGraphQLApi';

import getServiceAppoinment from '@salesforce/apex/DomesticCheckInOutController.getServiceAppoinment';
import updateServiceAppoinmentApex from '@salesforce/apex/DomesticCheckInOutController.updateServiceAppoinment';

import SA_ID_FIELD from '@salesforce/schema/ServiceAppointment.Id';
import SA_STATUS_FIELD from '@salesforce/schema/ServiceAppointment.Status';
import SA_APPT_TYPE_FIELD from '@salesforce/schema/ServiceAppointment.Appointment_Type__c';
import SA_CHECKIN_TIME_FIELD from '@salesforce/schema/ServiceAppointment.Check_In_Timestamp__c';
import SA_CHECKIN_LAT_FIELD from '@salesforce/schema/ServiceAppointment.Check_In_Location__c';
import SA_CHECKIN_LONG_FIELD from '@salesforce/schema/ServiceAppointment.Check_In_Location__c';
import SA_CHECKOUT_TIME_FIELD from '@salesforce/schema/ServiceAppointment.Check_Out_Timestamp__c';
import SA_CHECKOUT_LAT_FIELD from '@salesforce/schema/ServiceAppointment.Check_Out_Location__c';
import SA_CHECKOUT_LONG_FIELD from '@salesforce/schema/ServiceAppointment.Check_Out_Location__c';

// Schema Imports (Work Order)
import WO_ID_FIELD from '@salesforce/schema/WorkOrder.Id';
import WO_STATUS_FIELD from '@salesforce/schema/WorkOrder.Status';
import WO_APPT_STATUS_FIELD from '@salesforce/schema/WorkOrder.Appointment_Status__c';
import WO_CHECKIN_TIME_FIELD from '@salesforce/schema/WorkOrder.Check_In_Date_Time__c';
import WO_CHECKIN_LAT_FIELD from '@salesforce/schema/WorkOrder.Check_In_Location__c';
import WO_CHECKIN_LONG_FIELD from '@salesforce/schema/WorkOrder.Check_In_Location__c';
import WO_CHECKOUT_TIME_FIELD from '@salesforce/schema/WorkOrder.Check_Out_Date_Time__c';
import WO_CHECKOUT_LAT_FIELD from '@salesforce/schema/WorkOrder.Check_Out_Location__c';
import WO_CHECKOUT_LONG_FIELD from '@salesforce/schema/WorkOrder.Check_Out_Location__c';
import WO_SA_COUNT_FIELD from '@salesforce/schema/WorkOrder.ServiceAppointmentCount__c';
import WO_FOLLOWUP_REMARKS_FIELD from '@salesforce/schema/WorkOrder.Follow_up_Remarks__c';
import WO_OTHER_REMARK_FIELD from '@salesforce/schema/WorkOrder.Other_Follow_Up_Remark__c';

// Schema Imports (Work Step)
import WS_ID_FIELD from '@salesforce/schema/WorkStep.Id';
import WS_STATUS_FIELD from '@salesforce/schema/WorkStep.Status';

// --- GraphQL Queries ---

const SA_QUERY = gql`
  query GetSA($recordId: ID!) {
    uiapi {
      query {
        ServiceAppointment(
          where: { or: [{ Id: { eq: $recordId } }, { ParentRecordId: { eq: $recordId } }] }
          first: 1
          orderBy: { CreatedDate: { order: DESC } }
        ) {
          edges {
            node {
              Id
              ParentRecordId { value }
              Status { value }
              Check_In_Timestamp__c { value }
              Check_Out_Timestamp__c { value }
              FollowUpRemarks__c { value }
              Other_Follow_Up_Remark__c { value }
              Check_In_Location__Latitude__s { value }
              Check_In_Location__Longitude__s { value }
              Check_Out_Location__Latitude__s { value }
              Check_Out_Location__Longitude__s { value }
            }
          }
        }
      }
    }
  }
`;

const WO_QUERY = gql`
  query GetWO($woId: ID!) {
    uiapi {
      query {
        WorkOrder(where: { Id: { eq: $woId } }, first: 1) {
          edges {
            node {
              Id
              ServiceAppointmentCount__c { value }
            }
          }
        }
      }
    }
  }
`;

// 3. Fetch Work Steps (Check In / Check Out)
const WS_QUERY = gql`
  query GetWorkSteps($woId: ID!) {
    uiapi {
      query {
        WorkStep(where: { ParentRecordId: { eq: $woId } }, first: 50) {
          edges {
            node {
              Id
              Name { value }
              Status { value }
            }
          }
        }
      }
    }
  }
`;

export default class DomesticCheckInOutClone extends NavigationMixin(LightningElement) {
    
    @api recordId;

    @track checkIn = false;
    @track checkOut = false;
    @track lat;
    @track long;
    @track lstMarkers = [];
    @track showEnableMessage = false;
    @track showMap = false;
    @track currentDateTime;
    @track CheckOutLocation = '';
    @track CheckInLocation = '';
    @track CheckOutDateTime = '';
    @track CheckINDateTime = '';
    @track requestInProgress = false;
    @track message = '';

    // Offline Data Cache
    _offlineSA;
    _offlineWorkSteps = [];
    _woCount = 0;

    serviceAppointmentId;

    connectedCallback() {
        if (navigator.onLine) {
            this.getServiceAppoinment();
        } else {
            this.requestInProgress = false;
        }
    }

    // --- GRAPHQL WIRES (OFFLINE DATA) ---

    get gqlVars() {
        return { recordId: this.recordId };
    }

    @wire(graphql, { query: SA_QUERY, variables: '$gqlVars' })
    wiredSA({ data, errors }) {
        if (!navigator.onLine && data) {
            const node = data.uiapi?.query?.ServiceAppointment?.edges?.[0]?.node;
            if (node) {
                this._offlineSA = node;
                this.serviceAppointmentId = node.Id;        
                const formatLoc = (lat, long) => (lat && long) ? `${lat}, ${long}` : null;
                const inLat = node.Check_In_Location__Latitude__s?.value;
                const inLong = node.Check_In_Location__Longitude__s?.value;
                const outLat = node.Check_Out_Location__Latitude__s?.value;
                const outLong = node.Check_Out_Location__Longitude__s?.value;

                const result = {
                    serviceAppId: node.Id,
                    checkInDateTime: node.Check_In_Timestamp__c?.value,
                    checkOutDateTime: node.Check_Out_Timestamp__c?.value,
                    checkInLocation: formatLoc(inLat, inLong),
                    checkOutLocation: formatLoc(outLat, outLong)
                };     
                this.showBtns(result);
            }
        } else if (errors) {
            console.error('SA GraphQL Error', JSON.stringify(errors));
        }
    }

    get woId() {
        return this._offlineSA?.ParentRecordId?.value;
    }

    get gqlWOVars() {
        return this.woId ? { woId: this.woId } : undefined;
    }

    @wire(graphql, { query: WO_QUERY, variables: '$gqlWOVars' })
    wiredWO({ data }) {
        if (!navigator.onLine && data) {
            const node = data.uiapi?.query?.WorkOrder?.edges?.[0]?.node;
            if (node) {
                this._woCount = node.ServiceAppointmentCount__c?.value ? Number(node.ServiceAppointmentCount__c.value) : 0;
            }
        }
    }

    @wire(graphql, { query: WS_QUERY, variables: '$gqlWOVars' })
    wiredWS({ data }) {
        if (!navigator.onLine && data) {
            this._offlineWorkSteps = (data.uiapi?.query?.WorkStep?.edges || []).map(e => e.node);
        }
    }

    // --- END WIRES ---

    getServiceAppoinment() {
        this.requestInProgress = true;
        getServiceAppoinment({ recordId: this.recordId })
        .then(result => {
            if(result) {
                console.log('=====result===>', JSON.stringify(result));
                this.serviceAppointmentId = result.serviceAppId;
                this.handleGetLocation(result);
            } else {
                this.requestInProgress = false;
            }
        })
        .catch(error => {
            this.showtoast('Error', error.body?.message || error.message, 'Error');
            this.handleCancel();
        });
    }

    handleCheckInCheckOut() {
        this.requestInProgress = true;
        this.currentDateTime = new Date().toISOString();
        
        if (navigator.onLine) {
            this.handleCheckInCheckOutOnline();
        } else {
            this.handleCheckInCheckOutOffline();
        }
    }

    // ONLINE Logic (Apex)
    handleCheckInCheckOutOnline() {
        updateServiceAppoinmentApex({ 
            recordId: this.serviceAppointmentId, 
            latitude: this.lat, 
            longitude: this.long, 
            checkINDateTime: this.currentDateTime, 
            checkOutDateTime: this.currentDateTime, 
            checkOutLocation: this.CheckOutLocation, 
            checkInLocation: this.CheckInLocation, 
            checkOutTime: this.CheckOutDateTime, 
            checkInTime: this.CheckINDateTime 
        })
        .then(result => {
            this.requestInProgress = false;
            if (result === 'Check In Successfully') { 
                this.showtoast('Success', 'Check In Successfully', 'success');
            }
            else if (result === 'Check Out Successfully') {
                this.showtoast('Success', 'Check Out Successfully', 'success');
            }
            this.handleCancel();
        })
        .catch(error => {
            this.requestInProgress = false;
            this.showtoast('Error', error.body?.message || error.message, 'Error');
            this.handleCancel();
        });
    }

    // OFFLINE Logic (LDS) - Parity with Apex
    async handleCheckInCheckOutOffline() {
        try {
            const isCheckIn = (this.CheckInLocation == '' || this.CheckINDateTime == '');
            const saId = this.serviceAppointmentId;
            const woId = this.woId;

            if (!saId || !woId) {
                throw new Error('Service Appointment or Parent Work Order not found in cache.');
            }

            // 1. UPDATE SERVICE APPOINTMENT
            const saFields = { Id: saId };
            // 2. UPDATE WORK ORDER
            const woFields = { Id: woId };
            // 3. IDENTIFY WORK STEP
            let stepName = '';

            if (isCheckIn) {
                
                // SA Fields
                saFields[SA_STATUS_FIELD.fieldApiName] = 'In Progress';
                saFields[SA_APPT_TYPE_FIELD.fieldApiName] = 'In Progress';
                saFields[SA_CHECKIN_TIME_FIELD.fieldApiName] = this.currentDateTime;
                saFields[SA_CHECKIN_LAT_FIELD.fieldApiName] = this.lat;
                saFields[SA_CHECKIN_LONG_FIELD.fieldApiName] = this.long;
                saFields[SA_CHECKOUT_TIME_FIELD.fieldApiName] = null;
                saFields[SA_CHECKOUT_LAT_FIELD.fieldApiName] = null;
                saFields[SA_CHECKOUT_LONG_FIELD.fieldApiName] = null;

                // WO Fields
                woFields[WO_STATUS_FIELD.fieldApiName] = 'In Progress';
                woFields[WO_APPT_STATUS_FIELD.fieldApiName] = 'In Progress';
                woFields[WO_CHECKIN_TIME_FIELD.fieldApiName] = this.currentDateTime;
                woFields[WO_CHECKIN_LAT_FIELD.fieldApiName] = this.lat;
                woFields[WO_CHECKIN_LONG_FIELD.fieldApiName] = this.long;

                stepName = 'Check In';

            } else {
                // --- CHECK OUT LOGIC ---

                // SA Fields
                saFields[SA_STATUS_FIELD.fieldApiName] = 'Completed';
                saFields[SA_APPT_TYPE_FIELD.fieldApiName] = 'Completed';
                saFields[SA_CHECKOUT_TIME_FIELD.fieldApiName] = this.currentDateTime;
                saFields[SA_CHECKOUT_LAT_FIELD.fieldApiName] = this.lat;
                saFields[SA_CHECKOUT_LONG_FIELD.fieldApiName] = this.long;

                // WO Fields
                woFields[WO_STATUS_FIELD.fieldApiName] = 'Completed';
                woFields[WO_APPT_STATUS_FIELD.fieldApiName] = 'Completed';
                woFields[WO_CHECKOUT_TIME_FIELD.fieldApiName] = this.currentDateTime;
                woFields[WO_CHECKOUT_LAT_FIELD.fieldApiName] = this.lat;
                woFields[WO_CHECKOUT_LONG_FIELD.fieldApiName] = this.long;
                
                if (this._offlineSA) {
                    woFields[WO_FOLLOWUP_REMARKS_FIELD.fieldApiName] = this._offlineSA.FollowUpRemarks__c?.value;
                    woFields[WO_OTHER_REMARK_FIELD.fieldApiName] = this._offlineSA.Other_Follow_Up_Remark__c?.value;
                    
                    if (this._offlineSA.Check_In_Timestamp__c?.value) {
                        woFields[WO_CHECKIN_TIME_FIELD.fieldApiName] = this._offlineSA.Check_In_Timestamp__c.value;
                    }
                    if (this._offlineSA.Check_In_Location__Latitude__s?.value) {
                        woFields[WO_CHECKIN_LAT_FIELD.fieldApiName] = this._offlineSA.Check_In_Location__Latitude__s.value;
                        woFields[WO_CHECKIN_LONG_FIELD.fieldApiName] = this._offlineSA.Check_In_Location__Longitude__s.value;
                    }
                }
                woFields[WO_SA_COUNT_FIELD.fieldApiName] = this._woCount + 1;

                stepName = 'Check Out';
            }

            // Perform Updates
            await updateRecord({ fields: saFields });
            await updateRecord({ fields: woFields });

            // Update Work Step
            const targetStep = this._offlineWorkSteps.find(s => s.Name.value === stepName);
            if (targetStep) {
                await updateRecord({
                    fields: {
                        [WS_ID_FIELD.fieldApiName]: targetStep.Id,
                        [WS_STATUS_FIELD.fieldApiName]: 'Completed'
                    }
                });
            }

            const msg = isCheckIn ? 'Check In Successfully' : 'Check Out Successfully';
            this.showtoast('Success', msg + ' (Offline)', 'success');
            this.handleCancel();

        } catch (e) {
            this.showtoast('Error', 'Offline Update Failed: ' + e.message, 'error');
        } finally {
            this.requestInProgress = false;
        }
    }

    handleCheckIn() {
        this.checkIn = true;
        this.checkOut = false;
        this.handleCheckInCheckOut();
    }

    handleCheckOut() {
        this.checkIn = false;
        this.checkOut = true;
        this.handleCheckInCheckOut();
    }

    handleGetLocation(result) {
        if (FORM_FACTOR === 'Large') {
            this.getBrowserLocation(result);
        } else {
            this.getMobileLocation(result);
        }
    }

    showBtns(result) {
        this.requestInProgress = false;
        this.showMap = true;

        this.followUpDate = result.followUpDate ? result.followUpDate : '';
        this.CheckOutLocation = result.checkOutLocation ? String(result.checkOutLocation) : '';
        this.CheckInLocation = result.checkInLocation ? String(result.checkInLocation) : '';
        this.CheckOutDateTime = result.checkOutDateTime ? result.checkOutDateTime : '';
        this.CheckINDateTime = result.checkInDateTime ? result.checkInDateTime : '';

        if (this.CheckOutLocation != '' && this.CheckInLocation != '' && this.CheckOutDateTime != '' && this.CheckINDateTime != '') {
            this.checkOut = false;
            this.checkIn = false;
            this.showEnableMessage = true;
            this.message = 'Task is already completed. Please refresh the WorkOrder page and continue.';
            this.showMap = false;
        }
        else if ((this.CheckInLocation != '' || this.CheckINDateTime != '') && (this.CheckOutLocation == '' || this.CheckOutDateTime == '')) {            
            this.showEnableMessage = true;
            this.message = 'Task is already completed. Please refresh the WorkOrder page and continue.'; 
            
           
            this.checkIn = false;
            this.checkOut = true;
            return;
        }
        else if ((this.CheckInLocation == '' || this.CheckINDateTime == '') && (this.CheckOutLocation == '' || this.CheckOutDateTime == '')) {
            if (this.followUpDate != '') {
                this.showToast('Warning', 'This is a Follow-Up task. If you want to attempt follow-up task today then continue else go back to Home screen.', 'warning');
            }
            this.checkIn = true;
            this.checkOut = false;
        }
    }

    getBrowserLocation(resultBtn) {
        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition(
                (position) => {
                    this.lat = position.coords.latitude;
                    this.long = position.coords.longitude;
                    
                    if (resultBtn) this.showBtns(resultBtn);
                },
                (error) => {
                    this.showtoast('Warning', 'Please enable your device location', 'warning');
                    this.checkIn = false;
                    this.checkOut = false;
                }
            );
        } else {
            this.showtoast('Warning', 'Geolocation is not supported by this browser', 'warning');
            this.checkIn = false;
            this.checkOut = false;
        }
    }
    
    getMobileLocation(resultBtn) {
        const locationService = getLocationService();

        if (!locationService || !locationService.isAvailable()) {
            this.showtoast('LocationService Not Available', 'Please use a GPS-enabled mobile device and ensure location is turned on.', 'error');
            this.checkIn = false;
            this.checkOut = false;
            this.showMap = true;
            return;
        }

        const options = {
            enableHighAccuracy: true
        };

        locationService.getCurrentPosition(options)
        .then(result => {
            this.lat = result.coords.latitude;
            this.long = result.coords.longitude;
            if (resultBtn) this.showBtns(resultBtn);
        })
        .catch(error => {
             console.error('Location Error', error);
             if (resultBtn) this.showBtns(resultBtn); 
        });
    }

    handleCancel() {
        if (FORM_FACTOR === 'Large') {
            const closeQA = new CustomEvent('close');
            this.dispatchEvent(closeQA);
        } else {
            history.back();
        }
    }

    showtoast(title, msg, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}