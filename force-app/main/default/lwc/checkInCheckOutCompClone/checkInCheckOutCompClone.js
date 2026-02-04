import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getLocationService } from 'lightning/mobileCapabilities';
import { NavigationMixin } from 'lightning/navigation';
import { updateRecord } from 'lightning/uiRecordApi';
import { graphql, gql } from 'lightning/uiGraphQLApi';
import FORM_FACTOR from '@salesforce/client/formFactor';

// Apex
import getCheckInStatus from '@salesforce/apex/CheckInCheckOutCompContr.getCheckInStatus';
import updateServiceAppoinment from '@salesforce/apex/CheckInCheckOutCompContr.updateServiceAppoinment';
import checkWorkStep from '@salesforce/apex/CheckInCheckOutCompContr.checkWorkStep';

// Schema Imports for LDS (Fixed Casing for Geolocation)
import SA_ID_FIELD from '@salesforce/schema/ServiceAppointment.Id';
import SA_STATUS_FIELD from '@salesforce/schema/ServiceAppointment.Status';
import SA_CHECKIN_TIME_FIELD from '@salesforce/schema/ServiceAppointment.O_MCheckInTimestamp__c';
import SA_CHECKOUT_TIME_FIELD from '@salesforce/schema/ServiceAppointment.O_MCheckOutTimestamp__c';

// NOTE: Ensure these API names match your Object Manager exactly (Latitude vs latitude)
import SA_CHECKIN_LAT_FIELD from '@salesforce/schema/ServiceAppointment.Check_In_Lat_Long__c';
import SA_CHECKIN_LONG_FIELD from '@salesforce/schema/ServiceAppointment.Check_In_Lat_Long__c';
import SA_CHECKOUT_LAT_FIELD from '@salesforce/schema/ServiceAppointment.Check_Out_Lat_Long__c';
import SA_CHECKOUT_LONG_FIELD from '@salesforce/schema/ServiceAppointment.Check_Out_Lat_Long__c';

import WS_ID_FIELD from '@salesforce/schema/WorkStep.Id';
import WS_STATUS_FIELD from '@salesforce/schema/WorkStep.Status';

// --- GraphQL Queries for Offline Data ---

// 1. Fetch SA details (Fixed Casing: __Latitude__s / __Longitude__s)
const SA_QUERY = gql`
  query GetSA($recordId: ID!) {
    uiapi {
      query {
        ServiceAppointment(
          where: { or: [{ Id: { eq: $recordId } }, { ParentRecordId: { eq: $recordId } }] }
          first: 1
        ) {
          edges {
            node {
              Id
              ParentRecordId { value }
              Status { value }
              O_MCheckInTimestamp__c { value }
              O_MCheckOutTimestamp__c { value }
              Check_In_Lat_Long__Latitude__s { value }
              Check_In_Lat_Long__Longitude__s { value }
              Check_Out_Lat_Long__Latitude__s { value }
              Check_Out_Lat_Long__Longitude__s { value }
              Scheduled_Location__Latitude__s { value }
              Scheduled_Location__Longitude__s { value }
            }
          }
        }
      }
    }
  }
`;

// 2. Fetch Work Order WorkType
const WO_QUERY = gql`
  query GetWO($recordId: ID!) {
    uiapi {
      query {
        WorkOrder(where: { Id: { eq: $recordId } }, first: 1) {
          edges {
            node {
              Id
              WorkType {
                Name { value }
              }
            }
          }
        }
      }
    }
  }
`;

// 3. Fetch Work Steps
const WS_QUERY = gql`
  query GetWorkSteps($recordId: ID!) {
    uiapi {
      query {
        WorkStep(where: { ParentRecordId: { eq: $recordId } }, first: 20) {
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

export default class CheckInCheckOutCompClone extends NavigationMixin(LightningElement) {
    @api recordId;

    @track checkIn = true;
    @track checkOut = false;
    @track lat;
    @track long;
    @track lstMarkers = [];
    @track showEnableMessage = false;
    @track showMap = true;
    @track currentDateTime;
    @track CheckOutLocation = '';
    @track CheckInLocation = '';
    @track CheckOutDateTime = '';
    @track CheckINDateTime = '';
    @track requestInProgress = false;

    // Offline Data Cache
    _offlineSA;
    _offlineWO;
    _offlineWorkSteps = [];

    connectedCallback() {
        if (navigator.onLine) {
            this.checkWorkStep();
            this.getCheckInStatus();
        }
        // If Offline, wires handle logic
        this.handleGetLocation();
    }

    /* =================================================================================
       OFFLINE WIRES (GraphQL)
       ================================================================================= */

    get gqlVars() {
        return { recordId: this.recordId };
    }

    // 1. Wire Service Appointment Data
    @wire(graphql, { query: SA_QUERY, variables: '$gqlVars' })
    wiredSA({ data, errors }) {
        if (errors) {
            console.error('SA GraphQL Errors:', JSON.stringify(errors));
            return;
        }
        if (!navigator.onLine && data) {
            const node = data.uiapi?.query?.ServiceAppointment?.edges?.[0]?.node;
            if (node) {
                this._offlineSA = node;
                // Map fields to UI logic variables (Using fixed casing)
                this.CheckInLocation = node.Check_In_Lat_Long__Latitude__s?.value ? 'Set' : '';
                this.CheckOutLocation = node.Check_Out_Lat_Long__Latitude__s?.value ? 'Set' : '';
                this.CheckINDateTime = node.O_MCheckInTimestamp__c?.value || '';
                this.CheckOutDateTime = node.O_MCheckOutTimestamp__c?.value || '';

                this.setButtonsState();
            }
        }
    }

    // 2. Wire Work Order
    @wire(graphql, { query: WO_QUERY, variables: '$gqlVars' })
    wiredWO({ data }) {
        if (!navigator.onLine && data) {
            this._offlineWO = data.uiapi?.query?.WorkOrder?.edges?.[0]?.node;
        }
    }

    // 3. Wire Work Steps
    @wire(graphql, { query: WS_QUERY, variables: '$gqlVars' })
    wiredWS({ data }) {
        if (!navigator.onLine && data) {
            this._offlineWorkSteps = (data.uiapi?.query?.WorkStep?.edges || []).map(edge => edge.node);
        }
    }

    /* ================================================================================= */

    // Logic to set button visibility
    setButtonsState() {
        if (this.CheckOutLocation && this.CheckInLocation && this.CheckOutDateTime && this.CheckINDateTime) {
            this.checkOut = false;
            this.checkIn = false;
            this.showEnableMessage = true;
            this.showMap = false;
            this.handleCancel();
            this.showtoast('warning', 'Already Checked In', 'warning');
        } else if ((this.CheckInLocation || this.CheckINDateTime) && (!this.CheckOutLocation || !this.CheckOutDateTime)) {
            this.checkIn = false;
            this.checkOut = true;
        } else {
            this.checkIn = true;
            this.checkOut = false;
        }
    }

    // Online Apex Call
    checkWorkStep() {
        checkWorkStep({ recordId: this.recordId })
            .then(result => {
                if (result == 'showWarning' || result == 'riserPainting') {
                    this.showtoast('Warning', 'Please Complete Service Report Task', 'warning');
                    this.handleCancel();
                }
            })
            .catch(error => {
                console.log('Error getting approval ::', error);
            });
    }

    // Online Apex Call
    getCheckInStatus() {
        getCheckInStatus({ recordId: this.recordId })
            .then(result => {
                this.CheckOutLocation = result.Check_Out_Lat_Long__c ? String(result.Check_Out_Lat_Long__c) : '';
                this.CheckInLocation = result.Check_In_Lat_Long__c ? String(result.Check_In_Lat_Long__c) : '';
                this.CheckINDateTime = result.O_MCheckInTimestamp__c ? result.O_MCheckInTimestamp__c : '';
                this.CheckOutDateTime = result.O_MCheckOutTimestamp__c ? result.O_MCheckOutTimestamp__c : '';
                this.setButtonsState();
                this.handleGetLocation();
            })
            .catch(error => {
                this.showtoast('Error', error, 'Error');
                this.handleCancel();
            });
    }

    handleCheckIn() {
        this.checkIn = true;
        this.checkOut = false;
        this.handleCheckInCheckOut();
    }

    handleCancel() {
        if (FORM_FACTOR === 'Large') {
            const closeQA = new CustomEvent('close');
            this.dispatchEvent(closeQA);
        } else {
            setTimeout(() => {
                history.back();
            }, 1000);
        }
    }

    handleCheckOut() {
        this.checkIn = false;
        this.checkOut = true;
        this.handleCheckInCheckOut();
    }

    handleGetLocation() {
        if (FORM_FACTOR === 'Large') {
            this.getBrowserLocation();
        } else {
            this.getMobileLocation();
        }
    }

    getBrowserLocation() {
        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition(
                (position) => {
                    this.lat = position.coords.latitude;
                    this.long = position.coords.longitude;
                    this.lstMarkers = [{
                        location: { Latitude: this.lat, Longitude: this.long },
                        title: "Your Current Location"
                    }];
                    this.zoomlevel = "10";
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

    getMobileLocation() {
        const locationService = getLocationService();
        if (!locationService || !locationService.isAvailable()) {
            this.showtoast('LocationService Not Available', 'Please use a GPS-enabled mobile device.', 'error');
            this.checkIn = false;
            this.checkOut = false;
            this.showMap = true;
            return;
        }

        const options = { enableHighAccuracy: true };
        locationService.getCurrentPosition(options)
            .then(result => {
                this.lat = result.coords.latitude;
                this.long = result.coords.longitude;
                this.lstMarkers = [{
                    location: { Latitude: this.lat, Longitude: this.long },
                    title: "Your Current Location"
                }];
                this.zoomlevel = "15";
            })
            .catch(error => {
                console.error('Location error:', error);
                this.showtoast('Warning', 'Please enable your device location.', 'Warning');
                this.checkIn = false;
                this.checkOut = false;
            });
    }

    // MAIN ACTION HANDLER
    async handleCheckInCheckOut() {
        this.requestInProgress = true;
        this.currentDateTime = new Date().toISOString();

        /* ==================== OFFLINE LOGIC ==================== */
        if (!navigator.onLine) {
            try {
                // 1. Validation: Work Steps
                if (this._offlineWO && this._offlineWorkSteps.length > 0) {
                    const isRiser = this._offlineWO.WorkType?.Name?.value === 'Riser Painting';
                    
                    const stepsMap = {};
                    this._offlineWorkSteps.forEach(s => stepsMap[s.Name.value] = s.Status.value);

                    const secondaryTask = isRiser ? 'CO Execution Detail' : 'Service Report';
                    const secondaryStatus = stepsMap[secondaryTask];
                    
                    if (secondaryStatus && secondaryStatus !== 'Completed') {
                         this.showtoast('Warning', 'Please Complete Service Report Task', 'warning');
                         this.handleCancel();
                         this.requestInProgress = false;
                         return;
                    }
                }

                // 2. Validation: Distance (Haversine)
                if (this._offlineSA) {
                    // Uses Fixed Casing
                    const schedLat = this._offlineSA.Scheduled_Location__Latitude__s?.value;
                    const schedLon = this._offlineSA.Scheduled_Location__Longitude__s?.value;
                    
                    if (schedLat && schedLon) {
                        const distMeters = this.calculateHaversineDistance(schedLat, schedLon, this.lat, this.long);
                        if (distMeters > 1000.0) { // 1000m radius
                            this.showtoast('Warning', 'TOO FAR FROM LOCATION', 'Warning');
                            this.requestInProgress = false;
                            return;
                        }
                    }
                }

                // 3. Perform Updates (LDS Queue)
                const saId = this._offlineSA?.Id || this.recordId;
                
                // A. Update Service Appointment
                const saFields = { Id: saId };
                if (this.checkIn) {
                    saFields[SA_STATUS_FIELD.fieldApiName] = 'In Progress';
                    saFields[SA_CHECKIN_TIME_FIELD.fieldApiName] = this.currentDateTime;
                    saFields[SA_CHECKIN_LAT_FIELD.fieldApiName] = this.lat;
                    saFields[SA_CHECKIN_LONG_FIELD.fieldApiName] = this.long;
                } else {
                    saFields[SA_STATUS_FIELD.fieldApiName] = 'Completed';
                    saFields[SA_CHECKOUT_TIME_FIELD.fieldApiName] = this.currentDateTime;
                    saFields[SA_CHECKOUT_LAT_FIELD.fieldApiName] = this.lat;
                    saFields[SA_CHECKOUT_LONG_FIELD.fieldApiName] = this.long;
                }
                
                await updateRecord({ fields: saFields });

                // B. Update Work Step (Check In / Check Out)
                const targetStepName = this.checkIn ? 'Check In' : 'Check Out';
                const stepToUpdate = this._offlineWorkSteps.find(s => s.Name.value === targetStepName);
                
                if (stepToUpdate) {
                    const wsFields = {
                        [WS_ID_FIELD.fieldApiName]: stepToUpdate.Id,
                        [WS_STATUS_FIELD.fieldApiName]: 'Completed'
                    };
                    await updateRecord({ fields: wsFields });
                }

                // 4. Success UI
                const msg = this.checkIn ? 'Check In Successfully' : 'Check Out Successfully';
                this.showtoast('Success', msg + ' (Offline)', 'success');
                this.handleCancel();

            } catch (error) {
                this.showtoast('Error', 'Offline Update Failed: ' + (error.body?.message || error.message), 'Error');
            } finally {
                this.requestInProgress = false;
            }
            return;
        }

        /* ==================== ONLINE LOGIC ==================== */
        updateServiceAppoinment({
            recordId: this.recordId,
            lat: this.lat,
            lon: this.long,
            checkIn: this.checkIn,
            currentDateTime: this.currentDateTime
        })
        .then(result => {
            this.requestInProgress = false;
            if (result == 'Check In Successfully') {
                this.showtoast('Success', 'Check In Successfully', 'success');
            } else if (result == 'Check Out Successfully') {
                this.showtoast('Success', 'Check Out Successfully', 'success');
            } else if (result === 'TOO_FAR_FROM_LOCATION') {
                this.showtoast('Warning', 'TOO FAR FROM LOCATION', 'Warning');
                return;
            }
            this.handleCancel();
        })
        .catch(error => {
            this.requestInProgress = false;
            this.showtoast('Error', error, 'Error');
            this.handleCancel();
        });
    }

    // Helper: Haversine Formula for Offline Distance
    calculateHaversineDistance(lat1, lon1, lat2, lon2) {
        const R = 6371e3; // metres
        const φ1 = lat1 * Math.PI / 180;
        const φ2 = lat2 * Math.PI / 180;
        const Δφ = (lat2 - lat1) * Math.PI / 180;
        const Δλ = (lon2 - lon1) * Math.PI / 180;

        const a = Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
                  Math.cos(φ1) * Math.cos(φ2) *
                  Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

        return R * c;
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