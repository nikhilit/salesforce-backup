// locationServiceExample.js
import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getLocationService } from 'lightning/mobileCapabilities';
import getTodayAttendance from '@salesforce/apex/AttendanceController.getTodayAttendance';
import markAttendance from '@salesforce/apex/AttendanceController.markAttendance';
import markDayOut from '@salesforce/apex/AttendanceController.markDayOut';
import createAbsenceRecord from '@salesforce/apex/AttendanceController.createAbsenceRecord';
import FORM_FACTOR from '@salesforce/client/formFactor';
 
export default class LocationService extends LightningElement {
 
   // Internal component state
   myLocationService;
   currentLocation;
   locationButtonDisabled = false;
   requestInProgress = false;
   @track openPopup = false;
   @track openConfirmPopup = false


   //mark attendance
    @track status = '';
    @track dayInDone = false;
    @track dayOutDone = false;
    @track showSubmit = true;
    @track showDayOut = false;
    @track isSubmitted = false;
    @track canViewVisits = false;
    @track serviceAppointments = [];

 
   // When component is initialized, detect whether to enable Location button
   connectedCallback() {
       this.myLocationService = getLocationService();
       if (this.myLocationService == null || !this.myLocationService.isAvailable()) {
           this.locationButtonDisabled = true;
       }
        this.loadAttendance();

  // Refresh attendance every 10 seconds
    this.intervalId = setInterval(() => {
        this.loadAttendance();
    }, 10000);

   }
  
   handleGetCurrentLocationClick(event) {
        this.loadAttendance();
       // Reset current location
       this.currentLocation = null;
       this.locationButtonDisabled = true;
 
       if(this.myLocationService != null && this.myLocationService.isAvailable()) {
 
           // Configure options for location request
           const locationOptions = {
               enableHighAccuracy: true
           }
 
           // Show an "indeterminate progress" spinner before we start the request
           this.requestInProgress = true;
 
           this.myLocationService
               .getCurrentPosition(locationOptions)
               .then((result)  => {
                   this.currentLocation = result;
                   console.log(JSON.stringify(result));
               })
               .catch((error) => {
                   // Handle errors here
                   console.error(error);
 
                   // Inform the user we ran into something unexpected
                   this.dispatchEvent(
                       new ShowToastEvent({
                           title: 'LocationService Error',
                           message:
                               'There was a problem locating you: ' +
                               ' Please try again.',
                           variant: 'error'
                       })
                   );
               })
               .finally(() => {
                   console.log('#finally');
                   // Remove the spinner
                   
                    setTimeout(() => {
                        this.requestInProgress = false;
                        this.openPopup = true;
                        }, 3000);
               });
       } else {
           // LocationService is not available
           console.log('Get Location button should be disabled and unclickable. ');
           console.log('Somehow it got clicked: ');
           console.log(event);

           this.locationButtonDisabled = false;
 
           // Let user know they need to use a mobile phone with a GPS
           this.dispatchEvent(
               new ShowToastEvent({
                   title: 'LocationService Is Not Available',
                   message: 'Try again, and check your Internet Connection.',
                   variant: 'error'
               })
           );
       }
   }
 
   // Format LocationService result Location object as a simple string
   get currentLocationAsString() {
       return `Lat: ${this.currentLocation.coords.latitude}, Long: ${this.currentLocation.coords.longitude}`;
   }
 
   // Format Location object for use with lightning-map base component
   get currentLocationAsMarker() {
       return [{
           location: {
               Latitude: this.currentLocation.coords.latitude,
               Longitude: this.currentLocation.coords.longitude
           },
           title: 'My Location'
       }]
   }



   //Attendence JS
       loadAttendance() {
           getTodayAttendance()
               .then((wrapper) => {
                   if (wrapper && wrapper.attendance) {
                       let record = wrapper.attendance;
                       this.status = record.Status__c;
                       this.isSubmitted = true;
                       this.dayInDone = record.Status__c === 'Present' && record.Day_In_Timestamp__c != null;
                       this.showSubmit = !this.dayInDone;
                       this.showDayOut = this.dayInDone && !record.Day_Out_Timestamp__c;
                   }
               })
               .catch((error) => {
                   console.error('Error loading attendance', error);
               });
       }


           get statusOptions() {
               return [
                   { label: 'Present', value: 'Present' },
                   { label: 'On Leave', value: 'On Leave' }
               ];
           }
       
           handleStatusChange(event) {
               if (!this.isSubmitted) {
                   this.status = event.detail.value;
               }
           }
       
           handleSubmit() {
            this.openPopup = false;
           if (!this.status) {
               alert('Please select a status before submitting.');
               this.locationButtonDisabled = false;
               return;
           }
           let locationPromise = FORM_FACTOR === 'Large' ? this.getLocation() : this.getMobileLocation();
       
           locationPromise
               .then((position) => {
                   return markAttendance({
                       status: this.status,
                       lat: position.coords.latitude,
                       lon: position.coords.longitude
                   });
               })
               .then((result) => {
                   if (result === 'ALREADY_MARKED') {
                       this.showToast('Info', 'Attendance already marked for the day.', 'info');
       
                       if (this.status === 'Present') {
                           this.showToast('Info', 'Attendance marked.', 'info');
                       } else {
                           this.loadAttendance();
                           //location.reload(); // fallback refresh
                       }
       
                       throw new Error('Attendance already marked.');
                   }
       
                   if (this.status === 'On Leave') {
                       return createAbsenceRecord();
                   }
               })
               .then(() => {
                    if (this.status === 'Present') {
                        this.showToast('Success', 'Attendance marked.', 'success');
                        this.loadAttendance();
                        this.locationButtonDisabled = false;
                    } else {
                        this.loadAttendance();
                        //location.reload();
                    }
               })
               .catch((error) => {
                   console.error('Error in handleSubmit:', error);
                   alert(error.body?.message || error.message || 'Unexpected error occurred.');
               });
       }

       handleOpenDayOutConfirm() {
            this.openPopup = false;        
            this.openConfirmPopup = true;  
        }

        handleCancelDayOut() {
            this.openConfirmPopup = false;
            this.locationButtonDisabled = false;
        }
           
        handleDayOut() {
            this.openConfirmPopup = false;
            let locationPromise = this.myLocationService?.isAvailable()
                ? this.myLocationService.getCurrentPosition({ enableHighAccuracy: true })
                : this.getLocation();

            locationPromise
                .then((position) => {
                    return markDayOut({
                        lat: position.coords.latitude,
                        lon: position.coords.longitude
                    });
                })
                .then(() => {
                    this.showToast('Success', 'Day-Out marked successfully.', 'success');
                    this.loadAttendance();
                    this.showDayOut = false;
                    // history.back();

                })
                .catch((error) => {
                    console.error('Day-Out Error:', JSON.stringify(error));
                    this.showToast('Error', error.message || 'Error marking Day-Out', 'error');
                });
        }

       
           getLocation() {
               return new Promise((resolve, reject) => {
                   if (navigator.geolocation) {
                       navigator.geolocation.getCurrentPosition(resolve, reject);
                   } else {
                       reject(new Error('Geolocation not supported'));
                   }
               });
           }
       
           getMobileLocation() {
               return new Promise((resolve, reject) => {
                   const locationService = getLocationService();
       
                   if (!locationService || !locationService.isAvailable()) {
                       this.showToast('Location Error', 'Enable GPS on your mobile device.', 'error');
                       reject(new Error('LocationService not available'));
                       return;
                   }
       
                   const options = { enableHighAccuracy: true };
       
                   locationService.getCurrentPosition(options)
                       .then((result) => {
                           resolve(result);
                       })
                       .catch((error) => {
                           this.showToast('Warning', 'Please enable your device location.', 'warning');
                           reject(error);
                       });
               });
           }
       
           showToast(title, message, variant) {
               const event = new ShowToastEvent({
                   title: title,
                   message: message,
                   variant: variant
               });
               this.dispatchEvent(event);
           }

    handleClose() {
        this.openPopup = false;
        this.locationButtonDisabled = false;
     }
}