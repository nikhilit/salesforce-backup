import { LightningElement, api, track } from 'lwc';
import getCheckInStatus from '@salesforce/apex/CheckInOutMrContr.getCheckInStatus';
import updateServiceAppoinment from '@salesforce/apex/CheckInOutMrContr.updateServiceAppoinment';
import checkWorkStep from '@salesforce/apex/CheckInOutMrContr.checkWorkStep';
import getApprovalStatus from '@salesforce/apex/CheckInOutMrContr.getApprovalStatus';
import checkUploadSiteDocumentApproved from '@salesforce/apex/CheckInOutMrContr.checkUploadSiteDocumentApproved';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getLocationService } from 'lightning/mobileCapabilities';
import { NavigationMixin } from 'lightning/navigation';
import FORM_FACTOR from '@salesforce/client/formFactor';

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
       else if(result.documentRecordDetail.Approval_Status_O_M__c !='Approved' &&
        
       (result.profileName ='O&M Field Agent Riser Activity' ||
          result.profileName =='O&M Field Agent IPD' || result.profileName =='O&M Supervisor IPD'))
        {

            console.log('inside 2nd if condition');
         
        this.showtoast('Warning', 'Please Upload TBT Documents', 'warning');
        console.log('inside if condition');
        this.handleCancel();
        this.checkOut = false;
        this.checkIn = false;
        

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
            this.showtoast('Warning', 'Please Complete CO Execution Detail Task', 'warning');
             this.checkOut=false;
             this.checkIn=false;
            this.handleCancel();
            
        }
       if(result =='domesticMeterChecking'){

         this.showtoast('Warning', 'Please Complete Site Details Task', 'warning');

        this.handleCancel();
       }

        if(result =='MeterReplacementSuccess'){

         this.showtoast('Warning', 'Please Complete Data Capture Detail Task', 'warning');

        this.handleCancel();
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



          this.showtoast('Warning', 'Upload site document approval status is not approved', 'warning');

             this.checkOut=false;
             this.checkIn=false;
            this.handleCancel();
          
            }

    })

    .catch(Error => {

        console.log('Error checkUploadSiteDocumentApproved ::', Error);

    })
  }

    serviceAppointmentId;
    // getCheckInStatus() {
    //     console.log('recordId:::' + this.recordId);
    //     getCheckInStatus({ recordId: this.recordId })
    //         .then(result => {
    //             console.log('inside success' + JSON.stringify(result));
              
    //         this.CheckOutLocation = result.Check_Out_Lat_Long__c ? String(result.Check_Out_Lat_Long__c) : '';
    //         this.CheckInLocation = result.Check_In_Lat_Long__c ? String(result.Check_In_Lat_Long__c) : '';
    //          this.CheckINDateTime = result.O_MCheckInTimestamp__c	 ? result.O_MCheckInTimestamp__c : '';
    //          this.CheckOutDateTime = result.O_MCheckOutTimestamp__c	 ? result.O_MCheckOutTimestamp__c : '';
            
    //             if(this.CheckOutLocation != '' && this.CheckInLocation != '' && this.CheckOutDateTime != '' && this.CheckINDateTime != ''){
    //                 this.checkOut = false;
    //                 this.checkIn = false;
    //                 this.showEnableMessage = true;
    //                 this.showMap = false;
    //                 this.handleCancel();
    //                 console.log('I am from First Condition');
    //                  this.showtoast('warning','Already Checked In','warning');
    //             }

    //             else if((this.CheckInLocation != '' || this.CheckINDateTime != '') && (this.CheckOutLocation == '' || this.CheckOutDateTime == '')) {
    //                  console.log('I am from Second Condition');
    //                 this.checkIn = false;
    //                 this.checkOut = true;
    //             }
    //             else if((this.CheckOutLocation != '' || this.CheckOutDateTime != '') && (this.CheckInLocation == '' || this.CheckINDateTime == '')){ 
    //                  console.log('I am from Third Condition');
    //                 this.checkIn = true;
    //                 this.checkOut = false;
    //             }
    //             else if((this.CheckInLocation != '' || this.CheckINDateTime != '') && (this.CheckOutLocation == '' || this.CheckOutDateTime == '')){
    //                  console.log('I am from Fourth Condition');
    //                 this.checkIn = true;
    //                 this.checkOut = false;
    //             }
    //             this.handleGetLocation();

    //         })
    //         .catch(error => {
    //             // this.dispatchEvent(customEvent);
    //            let message =
    //                     error?.body?.message ||
    //                     error?.body?.pageErrors?.[0]?.message ||
    //                     error?.body?.output?.errors?.[0]?.message ||
    //                     error?.body?.output?.fieldErrors &&
    //                         Object.values(error.body.output.fieldErrors)[0][0].message ||
    //                     error?.message ||
    //                     'Unknown error';

    //                 this.showtoast('Error', message, 'error');
    //             console.log('Error From getCheckInStatus' + JSON.stringify(error));
    //             this.handleCancel();
    //             console.log('inside catch');
                
    //         })

    // }

    getCheckInStatus() {
    console.log('recordId:::', this.recordId);
    getCheckInStatus({ recordId: this.recordId })
        .then(result => {
            console.log('inside success', JSON.stringify(result));

            // Normalize values to strings (and trim) so checks are consistent
            this.CheckOutLocation = result?.Check_Out_Lat_Long__c ? String(result.Check_Out_Lat_Long__c).trim() : '';
            this.CheckInLocation  = result?.Check_In_Lat_Long__c  ? String(result.Check_In_Lat_Long__c).trim()  : '';
            this.CheckINDateTime  = result?.O_MCheckInTimestamp__c ? String(result.O_MCheckInTimestamp__c).trim() : '';
            this.CheckOutDateTime = result?.O_MCheckOutTimestamp__c ? String(result.O_MCheckOutTimestamp__c).trim() : '';

            // Clear, explicit boolean flags
            const hasCheckOutLocation = this.CheckOutLocation !== '';
            const hasCheckInLocation  = this.CheckInLocation  !== '';
            const hasCheckOutTime     = this.CheckOutDateTime !== '';
            const hasCheckInTime      = this.CheckINDateTime  !== '';

            // Composite booleans used in conditions
            const fullyChecked = hasCheckOutLocation && hasCheckInLocation && hasCheckOutTime && hasCheckInTime;
            const onlyCheckedIn = (hasCheckInLocation || hasCheckInTime) && !(hasCheckOutLocation || hasCheckOutTime);
            const onlyCheckedOut = (hasCheckOutLocation || hasCheckOutTime) && !(hasCheckInLocation || hasCheckInTime);
            // Fallback / ambiguous state (both empty or mixed states not covered above)
            const ambiguous = !fullyChecked && !onlyCheckedIn && !onlyCheckedOut;

            // Log individual flags
            console.log('Flags:');
            console.log('  hasCheckOutLocation:', hasCheckOutLocation);
            console.log('  hasCheckInLocation :', hasCheckInLocation);
            console.log('  hasCheckOutTime    :', hasCheckOutTime);
            console.log('  hasCheckInTime     :', hasCheckInTime);

            // Log composite condition results
            console.log('Conditions:');
            console.log('  fullyChecked  (all present):', fullyChecked);
            console.log('  onlyCheckedIn (check-in present, checkout missing):', onlyCheckedIn);
            console.log('  onlyCheckedOut(checkout present, check-in missing):', onlyCheckedOut);
            console.log('  ambiguous (none of the above):', ambiguous);

            // Branch handling (clear, non-overlapping)
            if (fullyChecked) {
                console.log('I am from First Condition (fully checked)');
                this.checkOut = false;
                this.checkIn = false;
                this.showEnableMessage = true;
                this.showMap = false;
                this.handleCancel();
                this.showtoast('warning', 'Already Checked In', 'warning');
            } else if (onlyCheckedIn) {
                console.log('I am from Second Condition (only checked-in exists, checkout missing)');
                this.checkIn = false;
                this.checkOut = true;
            } else if (onlyCheckedOut) {
                console.log('I am from Third Condition (only checkout exists, check-in missing)');
                this.checkIn = true;
                this.checkOut = false;
            } else {
                // ambiguous or no data: default behaviour (update to what fits your app)
                console.log('I am from Fallback Condition (ambiguous or no data)');
                // Example default: allow check-in
                this.checkIn = true;
                this.checkOut = false;
            }

            // Continue with existing flow
            this.handleGetLocation();
        })
        .catch(error => {
            let message =
                error?.body?.message ||
                error?.body?.pageErrors?.[0]?.message ||
                error?.body?.output?.errors?.[0]?.message ||
                (error?.body?.output?.fieldErrors &&
                    Object.values(error.body.output.fieldErrors)[0][0].message) ||
                error?.message ||
                'Unknown error';

            this.showtoast('Error', message, 'error');
            console.log('Error From getCheckInStatus', JSON.stringify(error));
            this.handleCancel();
            console.log('inside catch');
        });
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