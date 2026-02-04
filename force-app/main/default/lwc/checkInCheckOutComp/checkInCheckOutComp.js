/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 05-28-2025
 * @last modified by  : Shashank.shekhar@appstrail.com
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   19-05-2025   Kartik Patkar, Appstrail   Initial Version
**/
import { LightningElement, api, track } from 'lwc';
import getCheckInStatus from '@salesforce/apex/CheckInCheckOutCompContr.getCheckInStatus';
import updateServiceAppoinment from '@salesforce/apex/CheckInCheckOutCompContr.updateServiceAppoinment';
import checkWorkStep from '@salesforce/apex/CheckInCheckOutCompContr.checkWorkStep';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getLocationService } from 'lightning/mobileCapabilities';
import { NavigationMixin } from 'lightning/navigation';
import FORM_FACTOR from '@salesforce/client/formFactor';

export default class CheckInCheckOutComp extends NavigationMixin(LightningElement) {

     @api recordId;

    @track checkIn = true;;
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

    connectedCallback() {

        this.checkWorkStep();

          this.handleGetLocation();
         this.getCheckInStatus();


       //  this.handleCheckInCheckOut();

    }

     checkWorkStep(){
    console.log('inside check work order step');
    checkWorkStep({recordId:this.recordId})
    .then( result => {

        console.log('Result checkworkstep :::', result);
        if(result =='showWarning'){
            this.showtoast('Warning', 'Please Complete Service Report Task', 'warning');
            // this.checkOut=false;
            // this.checkIn=false;
            this.handleCancel();
            
        }
        if(result =='riserPainting'){
            this.showtoast('Warning', 'Please Complete Service Report Task', 'warning');
            // this.checkOut=false;
            // this.checkIn=false;
            this.handleCancel();
            
        }
    })
    .catch( error => {
        console.log('Error getting approval ::', error);
    })
  }

    serviceAppointmentId;
    getCheckInStatus() {
        console.log('recordId:::' + this.recordId);
        getCheckInStatus({ recordId: this.recordId })
            .then(result => {
                console.log('inside success' + JSON.stringify(result));
              
            this.CheckOutLocation = result.Check_Out_Lat_Long__c ? String(result.Check_Out_Lat_Long__c) : '';
            this.CheckInLocation = result.Check_In_Lat_Long__c ? String(result.Check_In_Lat_Long__c) : '';
             this.CheckINDateTime = result.O_MCheckInTimestamp__c	 ? result.O_MCheckInTimestamp__c : '';
             this.CheckOutDateTime = result.O_MCheckOutTimestamp__c	 ? result.O_MCheckOutTimestamp__c : '';
            
                if(this.CheckOutLocation != '' && this.CheckInLocation != '' && this.CheckOutDateTime != '' && this.CheckINDateTime != ''){
                    this.checkOut = false;
                    this.checkIn = false;
                    this.showEnableMessage = true;
                    this.showMap = false;
                    this.handleCancel();
                     this.showtoast('warning','Already Checked In','warning');
                }

                else if((this.CheckInLocation != '' || this.CheckINDateTime != '') && (this.CheckOutLocation == '' || this.CheckOutDateTime == '')) {
                    this.checkIn = false;
                    this.checkOut = true;
                }
                else if((this.CheckOutLocation != '' || this.CheckOutDateTime != '') && (this.CheckInLocation == '' || this.CheckINDateTime == '')){ 
                    this.checkIn = true;
                    this.checkOut = false;
                }
                else if((this.CheckInLocation != '' || this.CheckINDateTime != '') && (this.CheckOutLocation == '' || this.CheckOutDateTime == '')){
                    this.checkIn = true;
                    this.checkOut = false;
                }
                this.handleGetLocation();

            })
            .catch(error => {
                // this.dispatchEvent(customEvent);
                this.showtoast('Error', error, 'Error');
                this.handleCancel();
                console.log('inside catch');
                console.log('error::' + JSON.stringify(error));
            })

    }
    handleCheckIn() {
        console.log('inside handle check in method');
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
                    var latitude = position.coords.latitude;
                    var longitude = position.coords.longitude;
                    this.lat = latitude;
                    this.long = longitude;
                    this.lstMarkers = [
                        {
                            location: {
                                Latitude: latitude,
                                Longitude: longitude
                            },
                            title: "Your Current Location"
                        }
                    ];
                    this.zoomlevel = "10";


                },
                (error) => {
                    this.showtoast('Warning', 'Please enable your device location', 'warning');
                    this.checkIn = false;
                    this.checkOut = false;

                    // this.handleCancel();
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
                console.log('Location result:', result);

                this.lat = result.coords.latitude;
                this.long = result.coords.longitude;

                this.lstMarkers = [{
                    location: {
                        Latitude: this.lat,
                        Longitude: this.long
                    },
                    title: "Your Current Location"
                }];
                this.zoomlevel = "15";


            })
            .catch(error => {
                console.error('Location error:', error);
                this.showtoast('Warning', 'Please enable your device location.', 'Warning');
                this.checkIn = false;
                this.checkOut = false;


            })
            .finally(() => {
                // this.requestInProgress = false;
            });
    }

    handleCheckInCheckOut() {

        console.log('inside handle check in out method');
        this.requestInProgress = true;

        console.log('Latitude handleCheckIn: ' + this.lat);
        console.log('Longitude handleCheckIn: ' + this.long);
        this.currentDateTime = new Date().toISOString();
        // Get current DateTime
        console.log('time: ' + this.currentDateTime);


        updateServiceAppoinment({ recordId: this.recordId, lat: this.lat, lon: this.long, checkIn : this.checkIn, currentDateTime : this.currentDateTime })
            .then(result => {
                this.requestInProgress = false;
                console.log('inside success result');
                 console.log('result:::>>', result);

                if (result == 'Check In Successfully') {
                    console.log('inside check in success');
                    this.showtoast('Success', 'Check In Successfully', 'success');
                }
                else if (result == 'Check Out Successfully') {
                    console.log('inside check out successfully');
                    this.showtoast('Success', 'Check Out Successfully', 'success');
                }
                 else if (result === 'TOO_FAR_FROM_LOCATION') {
                     console.log('inside to far from location');
                    this.showtoast('Warning', 'TOO FAR FROM LOCATION', 'Warning');
                    return;
                }
                
                 this.handleCancel();
            })
            .catch(error => {
                this.requestInProgress = false;

                // this.dispatchEvent(customEvent);
                this.showtoast('Error', error, 'Error');
                this.handleCancel();
                console.log('inside catch');
                console.log('error::' + JSON.stringify(error));
            })




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