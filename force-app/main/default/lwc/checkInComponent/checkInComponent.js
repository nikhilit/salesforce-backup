import { LightningElement, api, track } from 'lwc';
import getCheckInStatus from '@salesforce/apex/CheckInController.getCheckInStatus';
import updateServiceAppoinment from '@salesforce/apex/CheckInController.updateServiceAppoinment';
import checkWorkStep from '@salesforce/apex/CheckInController.checkWorkStep';
import getApprovalStatus from '@salesforce/apex/CheckInController.getApprovalStatus';
import checkUploadSiteDocumentApproved from '@salesforce/apex/CheckInController.checkUploadSiteDocumentApproved';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getLocationService } from 'lightning/mobileCapabilities';
import { NavigationMixin } from 'lightning/navigation';
import FORM_FACTOR from '@salesforce/client/formFactor';
import LightningAlert from 'lightning/alert';
export default class CheckInComponent extends NavigationMixin(LightningElement) {

    

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
            this.getApprovalStatus();


          this.handleGetLocation();
         this.getCheckInStatus();

         this.checkUploadSiteDocumentApproved();


       //  this.handleCheckInCheckOut();

    }



     getApprovalStatus(){
    getApprovalStatus()
    .then( result=> {
        console.log('result of approval status', JSON.stringify(result));
       /* if(result.documentRecordDetail.Approval_Status_O_M__c !='Approved'
         && (result.profileName !='Domestic Meter Checking Field Agent' ||
          result.profileName !='O&M Field Agent DOMESTIC METER CHECKING' || result.profileName !='O&M Supervisor DOMESTIC METER CHECKING'
          || result.profileName !='Rubber Hose Field Agent' || result.profileName !='O&M Rubber Hose Supervisor' || result.profileName !='O&M Rubber Hose Field Agent')){

        this.showtoast('Warning', 'Please Upload TBT Documents', 'warning');
        this.handleCancel();
        this.checkOut = false;
        this.checkIn = false;
        

        } */

          console.log('result of approval status', JSON.stringify(result));

        if(result.profileName =='Domestic Meter Checking Field Agent' ||
          result.profileName =='O&M Field Agent DOMESTIC METER CHECKING' || result.profileName =='O&M Supervisor DOMESTIC METER CHECKING'
          || result.profileName =='Rubber Hose Field Agent' || result.profileName =='O&M Rubber Hose Supervisor' || result.profileName =='O&M Rubber Hose Field Agent'){

            console.log('inside profile matched:');
       
          }
       else if(result.documentRecordDetail.Approval_Status__c !='Approved' &&
        
       (result.profileName ='O&M Field Agent Riser Activity' ||
          result.profileName =='O&M Field Agent IPD' || result.profileName =='O&M Supervisor IPD' ||   result.profileName == 'Field Agent(O&M)- AfterSalesService'))
        {

            console.log('inside 2nd if condition');
         
       // this.showtoast('Warning', 'Please Upload TBT Documents', 'warning');
        LightningAlert.open({
            message: 'Please Upload TBT Documents',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        }).then(() => {
          //this.dispatchEvent(new CustomEvent('cancel'));
          this.handleCancel();
          this.checkOut = false;
          this.checkIn = false;
         });
        console.log('inside if condition');
        // this.handleCancel();
        // this.checkOut = false;
        // this.checkIn = false;
        

        }

    })
    .catch(error => {

        console.log('Error ::',error);
    })
     }

     checkWorkStep(){
    console.log('inside check work order step');
    checkWorkStep({recordId:this.recordId})
    .then( result => {

        console.log('Result checkworkstep :::', result);
      /*  if(result =='showWarning'){
            this.showtoast('Warning', 'Please Complete BP Execution Detail Task', 'warning');
             this.checkOut=false;
             this.checkIn=false;
            this.handleCancel();
            
        } */
        if(result =='riserPainting'){
            // this.showtoast('Warning', 'Please Complete CO Execution Detail Task', 'warning');
            //  this.checkOut=false;
            //  this.checkIn=false;
            //  this.handleCancel();
             LightningAlert.open({
            message: 'Please Complete CO Execution Detail Task',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        }).then(() => {
          //this.dispatchEvent(new CustomEvent('cancel'));
          this.handleCancel();
          this.checkOut = false;
          this.checkIn = false;
         });
            
        }
       if(result =='domesticMeterChecking'){

        //  this.showtoast('Warning', 'Please Complete Site Details Task', 'warning');

        // this.handleCancel();
        LightningAlert.open({
            message: 'Please Complete Site Details Task',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        }).then(() => {
          //this.dispatchEvent(new CustomEvent('cancel'));
          this.handleCancel();
         });
       }
    })
    .catch( error => {
        console.log('Error getting approval ::', error);
    })
  }

  checkUploadSiteDocumentApproved(){

    checkUploadSiteDocumentApproved({recordId : this.recordId})

    .then(result => {

        console.log('Result chcheckUploadSiteDocumentApproved ::', result);

        if(result &&  Object.keys(result).length > 0 && result.Approval_Status__c !='Approved' && this.CheckInLocation !='' && this.CheckINDateTime !=''){



        //   this.showtoast('Warning', 'Upload site document approval status is not approved', 'warning');
        //      this.checkOut=false;
        //      this.checkIn=false;
        //     this.handleCancel();
        LightningAlert.open({
            message: 'Upload site document approval status is not approved',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        }).then(() => {
          //this.dispatchEvent(new CustomEvent('cancel'));
          this.handleCancel();
          this.checkOut = false;
          this.checkIn = false;
         });
          
            }

    })

    .catch(Error => {

        console.log('Error checkUploadSiteDocumentApproved ::', Error);

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
                    // this.checkOut = false;
                    // this.checkIn = false;
                    // this.showEnableMessage = true;
                    // this.showMap = false;
                    // this.handleCancel();
                    //  this.showtoast('warning','Already Checked In','warning');
                    LightningAlert.open({
            message: 'Already Checked In',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        }).then(() => {
          //this.dispatchEvent(new CustomEvent('cancel'));
                    this.checkOut = false;
                    this.checkIn = false;
                    this.showEnableMessage = true;
                    this.showMap = false;
                    this.handleCancel();
         });
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
              //  this.showtoast('Error', error, 'Error');
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
                    // this.showtoast('Warning', 'Please enable your device location', 'warning');
                    // this.checkIn = false;
                    // this.checkOut = false;

                    // this.handleCancel();
                    LightningAlert.open({
            message: 'Please enable your device location',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        }).then(() => {
          this.checkOut = false;
          this.checkIn = false;
         });
                }
            );
        } else {
            // this.showtoast('Warning', 'Geolocation is not supported by this browser', 'warning');
            // this.checkIn = false;
            // this.checkOut = false;
             LightningAlert.open({
            message: 'Geolocation is not supported by this browser',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        }).then(() => {
          this.checkOut = false;
          this.checkIn = false;
         });
        }
    }
    getMobileLocation() {
        const locationService = getLocationService();

        if (!locationService || !locationService.isAvailable()) {
            // this.showtoast('LocationService Not Available', 'Please use a GPS-enabled mobile device and ensure location is turned on.', 'error');
            // this.checkIn = false;
            // this.checkOut = false;
            // this.showMap = true;
             LightningAlert.open({
            message: 'LocationService Not Available ,Please use a GPS-enabled mobile device and ensure location is turned on.',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        }).then(() => {
          this.checkOut = false;
          this.checkIn = false;
          this.showMap = true;
         });
            
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
                // this.showtoast('Warning', 'Please enable your device location.', 'Warning');
                // this.checkIn = false;
                // this.checkOut = false;
                 LightningAlert.open({
            message: 'Please enable your device location.',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        }).then(() => {
          this.checkOut = false;
          this.checkIn = false;
         });


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
                    //this.showtoast('Success', 'Check In Successfully', 'success');
                     LightningAlert.open({
            message: 'Check In Successfully',
            theme: 'success',   // red error dialog
            label: 'Success'    // header text
        }).then(() => {
       this.handleCancel();
         });
 
                }
                else if (result == 'Check Out Successfully') {
                    console.log('inside check out successfully');
                   // this.showtoast('Success', 'Check Out Successfully', 'success');
                    LightningAlert.open({
            message: 'Check Out Successfully',
            theme: 'success',   // red error dialog
            label: 'Success'    // header text
        }).then(() => {
       this.handleCancel();
         });
                }
                 else if (result === 'TOO_FAR_FROM_LOCATION') {
                     console.log('inside to far from location');
                   // this.showtoast('Warning', 'TOO FAR FROM LOCATION', 'Warning');
                    LightningAlert.open({
            message: 'TOO FAR FROM LOCATION',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        }).then(() => {
          this.handleCancel();
         });
                    return;
                }
                
               //  this.handleCancel();
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