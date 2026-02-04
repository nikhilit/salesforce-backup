import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { getLocationService } from 'lightning/mobileCapabilities';

import WORKSTEP_NAME_FIELD from '@salesforce/schema/WorkStep.Name';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import getServiceAppoinment from '@salesforce/apex/DomesticCheckInOutController.getServiceAppoinment';
import updateServiceAppoinment from '@salesforce/apex/DomesticCheckInOutController.updateServiceAppoinment';

export default class DomesticCheckInOut extends LightningElement {
    
    @api recordId;

    @track checkIn = false;;
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

    connectedCallback() {
        this.getServiceAppoinment();
    }

    @wire(getRecord, { recordId: '$recordId', fields: [WORKSTEP_NAME_FIELD] })
    wiredWorkStep({ error, data }) {
        if (data) {

            console.log('======data====>', JSON.stringify(data));
            
            this.workStepName = getFieldValue(data, WORKSTEP_NAME_FIELD);

            alert('====this.workStepNam====>'+this.workStepNam);

        } else if (error) {
            console.error('Error fetching Work Order:', error);
        }
    }

    serviceAppointmentId;
    getServiceAppoinment() {
        this.requestInProgress = true;
        getServiceAppoinment({ recordId: this.recordId })
        .then(result => {

            console.log('=====result===>', JSON.stringify(result));


            this.serviceAppointmentId=result.serviceAppId;
            this.handleGetLocation(result);
        })
        .catch(error => {
            this.showtoast('Error', error, 'Error');
            this.handleCancel();
        })
    }

    handleCheckInCheckOut() {

        this.requestInProgress = true;

        this.currentDateTime = new Date().toISOString();
        
        updateServiceAppoinment({ 
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

            console.log('inside success');
            console.log('result::' + JSON.stringify(result));
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

            this.showtoast('Error', error, 'Error');

            this.handleCancel();
        })
    }

    handleCheckIn() {
        this.checkIn = true;
        this.checkOut = false;
        this.handleCheckInCheckOut();
    }

    handleCheckOut() {
        
        this.showtoast('Info', 'Check Out is not required.', 'info');
        return;

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

    showBtns(result){
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

            //this.showtoast('Info', 'Task is already completed. Please refresh the WorkOrder page and continue.', 'info');
            this.showEnableMessage = true;
            this.message = 'Task is already completed. Please refresh the WorkOrder page and continue.';
            return;

            this.checkIn = false;
            this.checkOut = true;
        }
        // else if ((this.CheckOutLocation != '' || this.CheckOutDateTime != '') && (this.CheckInLocation == '' || this.CheckINDateTime == '')) {
        //     this.checkIn = true;
        //     this.checkOut = false;
        // }
        // else if ((this.CheckInLocation != '' || this.CheckINDateTime != '') && (this.CheckOutLocation == '' || this.CheckOutDateTime == '')) {
        //     this.checkIn = false;
        //     this.checkOut = true;
        // }
        else if ((this.CheckInLocation == '' || this.CheckINDateTime == '') && (this.CheckOutLocation == '' || this.CheckOutDateTime == '')) {

            if(this.followUpDate != ''){
                this.showToast('Warning','This is a Follow-Up task. If you want to attempt follow-up task today then continue else go back to Home screen.','warning');
            }

            this.checkIn = true;
            this.checkOut = false;
        }
    }

    getBrowserLocation(resultBtn) {

        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition(
                (position) => {
                    
                    var latitude = position.coords.latitude;
                    var longitude = position.coords.longitude;

                    this.lat = latitude;
                    this.long = longitude;
                    
                    // this.lstMarkers = [
                    //     {
                    //         location: {
                    //             Latitude: latitude,
                    //             Longitude: longitude
                    //         },
                    //         title: "Your Current Location"
                    //     }
                    // ];
                    // this.zoomlevel = "10";

                    this.showBtns(resultBtn);
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

            // this.lstMarkers = [{
            //     location: {
            //         Latitude: this.lat,
            //         Longitude: this.long
            //     },
            //     title: "Your Current Location"
            // }];
            // this.zoomlevel = "15";

            this.showBtns(resultBtn);

        })
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