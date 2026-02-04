import { LightningElement,api,track,wire } from 'lwc';
import getAccountInfoFromSA from '@salesforce/apex/RubberHoseReplacementExecutionDetaContr.getAccountInfoFromSA';
import updateServiceAppoinment from '@salesforce/apex/CheckInController.updateServiceAppoinment';
import { getLocationService } from 'lightning/mobileCapabilities';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import FORM_FACTOR from '@salesforce/client/formFactor';
import getCheckInStatus from '@salesforce/apex/RubberHoseReplacementExecutionDetaContr.getCheckInStatus';
//import fieldPicklistValue from '@salesforce/apex/RubberHoseReplacementExecutionDetaContr.fieldPicklistValue';
import saveImage from '@salesforce/apex/RubberHoseReplacementExecutionDetaContr.saveImage';
 
 
 
export default class RubberHoseReplacementExecutionOffline extends LightningElement {
 
 //@api recordId;
//     account;
//     error;
 
//   @track accountView = true;
_recordId;
 
@api
set recordId(value) {
    this._recordId = value;
    if (this._recordId) {
        console.log('✅ recordId is now set:', this._recordId);
        this.tryInitializeComponent(); // new init flow
    } else {
        console.warn('⚠️ recordId is null or undefined in Quick Action context');
    }
}
 
get recordId() {
    return this._recordId;
}
 
@track isOffline = !navigator.onLine;
@track requestInProgress = false; 
 
  @track load=false;
 @track serviceAppointmentId;
  @track showCheckBox=true;
 
  get availabilityOptions() {
        return [
            { label: 'Yes', value: 'Yes' },
            { label: 'No', value: 'No' }
        ];
    }
 
            @track customerAvailability='';
 
 
           @track showNext=false;
 
 
      @track checkIn = true;;
 
 
  @track showRubberHose=false;
 
   @track lat;
   @track long;
 
   @track currentDateTime;
 
   @track ReasonForUnavailability=false;
 
   @track ishandleCaptureRiserDisabled=false;
 
   // @track reasonUnavailability = [];
 
     @track otherRemarkValue='';
 
     @track otherRemarkSelected = false;
 
     @track showChildWOStartEndDate=false;
 
     @track imageUploadPage=false;
 
         @track photoUploadSlots = [];
             noOfPhotos = 2;
 
 
        // @track rMCloserRemark ='';
 
          selectedDateTime;
      //selectedEndDateTime;
 
 
    reasonUnavailability = [
  { label: 'Customer will call later', value: 'Customer will call later' },
  { label: 'House locked', value: 'House locked' },
  { label: 'CUSTOMER NOT ALLOWED', value: 'CUSTOMER NOT ALLOWED' },
  { label: 'FALSE COMPLAINT', value: 'FALSE COMPLAINT' },
  { label: 'Building Demolished', value: 'Building Demolished' },
  { label: 'Customer call not responding', value: 'Customer call not responding' },
  { label: 'Customer call not reachable', value: 'Customer call not reachable' },
  { label: 'Address not found', value: 'Address not found' },
//   { label: 'Customer Not Available', value: 'Customer Not Available' },
  { label: 'Other', value: 'Other'}
 
];
 
 
 
 
    //   @track objectName='WorkOrder';
    //   @track fieldName='Reason_for_Unavailability__c';
 
          @track unavailability;
 
 
    //   fieldPicklistValue(){
    //     fieldPicklistValue({objectName:this.objectName, fieldName:this.fieldName})
    //     .then( result => {
    //         console.log('Rsult of picklist ::', result);
    //         this.reasonUnavailability=result;
    //         })
    //     .catch(error => {
    //             console.error('Error loading picklist values:', error);
    //         });
    // }
 
 
   connectedCallback() {

    // Add offline/online event listeners
    window.addEventListener('online', () => {
        this.isOffline = false;
        console.log('🌐 Online - syncing offline data');
        this.handleSyncOfflineData();
    });
    window.addEventListener('offline', () => {
        this.isOffline = true;
        this.showtoast('Info', 'You are offline - data will be saved locally', 'info');
    });
    
    // Sync any offline data if we're online
    if (navigator.onLine) {
        this.handleSyncOfflineData();
    }
 
 
       // this.handleGetLocation();
      //  this.getCheckInStatus();
       // this.fieldPicklistValue();
 
   
     // this.getMobileLocation();
 
   }
 
   tryInitializeComponent() {
    if (!this._recordId) {
        console.warn('❌ No recordId yet, skipping initialization');
        return;
    }
 
    console.log('🚀 Initializing component for record:', this._recordId);
    this.handleGetLocation();
    this.fetchServiceAppointmentFallback();
    this.getCheckInStatus(); // fetches check-in data
     // gets GPS
}
 
 
 
 
 
   handleDateTimeChange(event) {
        this.selectedDateTime = event.target.value;
        console.log('Selected DateTime:', this.selectedDateTime);
    }
 
    // handleEndDateTimeChange(event) {
    //     this.selectedEndDateTime = event.target.value;
    //     console.log('Selected End DateTime:', this.selectedEndDateTime);
    // }


// Add this method for offline ServiceAppointmentId fallback
fetchServiceAppointmentFallback() {
    if (!this.recordId) return;

    // Only call Apex if online
    if (navigator.onLine) {
        getCheckInStatus({ recordId: this.recordId })
            .then(sa => {
                if (sa) {
                    this.serviceAppointmentId = sa.Id;
                    console.log('✅ Fallback ServiceAppointmentId:', this.serviceAppointmentId);
                    // Cache it for offline use
                    sessionStorage.setItem(`serviceAppointment_${this.recordId}`, this.serviceAppointmentId);
                } else {
                    console.warn('⚠️ No ServiceAppointment found via fallback');
                }
            })
            .catch(err => console.error('❌ Fallback fetch error:', err));
    } else {
        // Try to get from cache when offline
        this.serviceAppointmentId = sessionStorage.getItem(`serviceAppointment_${this.recordId}`) || this.recordId;
        console.log('📴 Using cached ServiceAppointmentId for offline:', this.serviceAppointmentId);
    }
}
 
 
 
   @wire(getAccountInfoFromSA, { workOrderId: '$recordId' })
    wiredAccountInfo({ error, data }) {
        if (data) {
            console.log('Account data received:', data);
            this.account = data.acc;
            this.error = undefined;
 
let dateStr = data.acc.RH_Due_Date__c;
 
let dateObj = new Date(dateStr);
 
let day = String(dateObj.getDate()).padStart(2, '0');
let month = String(dateObj.getMonth() + 1).padStart(2, '0');
let year = dateObj.getFullYear();
 
    this.dueDate = `${day}-${month}-${year}`;
 
 
 
        } else if (error) {
            console.error('Error fetching account:', error);
            this.account = undefined;
            this.error = error;
        }
    }
 
 
      handleAvailabilityChange(event) {
        if(event.target.value == 'Yes'){
 
            this.showCheckBox=false;
        this.customerAvailability = event.target.value;
        // this.customerAvilable=true;
        // this.customerNotAvilable = false;
        // this.customerNotAvilableRemark='';
        this.showRubberHose=true;
        this.ReasonForUnavailability=false;
            this.showNext=false;
 
 
 
        }
        if(event.target.value == 'No'){
 
         this.showCheckBox=false;
 
        this.customerAvailability = event.target.value;
            this.ReasonForUnavailability=true;
            this.showNext=true;
            this.showRubberHose=false;
 
           //  this.fieldPicklistValue();
 
 
        }
      }
 
      handleImageCapturePage() {
 
     if(!this.otherRemarkValue && this.otherRemarkSelected){
 
  this.showtoast('Warning', 'Remark is required.', 'warning');
 
    return;
    }
 
      if(!this.selectedDateTime && this.showChildWOStartEndDate){
 
  this.showtoast('Warning', 'Please Enter Start Date.', 'warning');
 
    return;
    }
       
       // this.formSecondPage = false;
        this.setPhotoUploadSlots();
        this.imageUploadPage = true;
        this.showNext=false;
        console.log('show next ::'+ this.showNext);
    }
 
    //  handleRMCloserRemark(event){
 
    //     this.rMCloserRemark = event.target.value;
    // }
 
 
     setPhotoUploadSlots() {
        this.photoUploadSlots = Array.from({ length: this.noOfPhotos }, (_, index) => ({
            id: index + 1,
            index: index + 1,
            label: `Photo ${index + 1}`,
            name: `fileUploader${index + 1}`,
            fileName: '',
            uploaded: false,
            previewUrl: '',
            base64Data: ''
        }));
    }
 
 
    // handleCaptureRiser() {
    //    // this.showCheckBox = true;
    //    // this.accountView = false;
    //    // this.showRubberHose=true;
    //     this.handleCheckInCheckOut();
    // }
 
     handleGetLocation() {
        if (FORM_FACTOR === 'Large') {
            this.getBrowserLocation();
        } else {
            this.getMobileLocation();
        }
    }
 
    handleCancel() {
 
        this.handleCheckInCheckOut();
        if (FORM_FACTOR === 'Large') {
            const closeQA = new CustomEvent('close');
            this.dispatchEvent(closeQA);
        } else {
             
           setTimeout(() => {
            history.back();
        }, 1000);
     
        }
    }

    // NEW: Sync offline data when connection is restored
// NEW: Sync offline data when connection is restored
handleSyncOfflineData() {
    if (!navigator.onLine) return;
    
    try {
        // Sync check-in data
        const checkInKey = `offlineCheckIn_${this.recordId}`;
        const checkInData = JSON.parse(sessionStorage.getItem(checkInKey));
        
        if (checkInData) {
            updateServiceAppoinment({
                recordId: checkInData.recordId,
                lat: checkInData.lat,
                lon: checkInData.lon,
                checkIn: checkInData.checkIn,
                currentDateTime: checkInData.currentDateTime
            })
            .then(() => {
                console.log('✅ Synced offline check-in data');
                sessionStorage.removeItem(checkInKey);
            })
            .catch(error => {
                console.error('❌ Failed to sync check-in:', error);
                // Keep the data in storage if sync fails
            });
        }
        
        // Sync check-out data
        const checkOutKey = `offlineCheckOut_${this.recordId}`;
        const checkOutData = JSON.parse(sessionStorage.getItem(checkOutKey));
        
        if (checkOutData) {
            updateServiceAppoinment({
                recordId: checkOutData.recordId,
                lat: checkOutData.lat,
                lon: checkOutData.lon,
                checkIn: checkOutData.checkIn,
                currentDateTime: checkOutData.currentDateTime
            })
            .then(() => {
                console.log('✅ Synced offline check-out data');
                sessionStorage.removeItem(checkOutKey);
            })
            .catch(error => {
                console.error('❌ Failed to sync check-out:', error);
                // Keep the data in storage if sync fails
            });
        }
    } catch (error) {
        console.error('Error syncing offline data:', error);
    }
}
 
 handleCheckInCheckOut() {
    console.log('inside handle check in out method');
    
    // Validate location
    if (!this.lat || !this.long) {
        this.showtoast('Warning', 'Location not available. Please enable GPS and try again.', 'warning');
        return;
    }

    this.load = true;
    console.log('Latitude handleCheckIn: ' + this.lat);
    console.log('Longitude handleCheckIn: ' + this.long);
    this.currentDateTime = new Date().toISOString();
    console.log('time: ' + this.currentDateTime);

    // NEW: Handle offline mode - FIXED
    if (!navigator.onLine) {
        console.log('📴 Offline mode - saving check-in data locally');
        
        // Save to sessionStorage for offline persistence
        const offlineData = {
            recordId: this.serviceAppointmentId || this.recordId, // Use serviceAppointmentId if available
            lat: this.lat,
            lon: this.long,
            checkIn: this.checkIn,
            currentDateTime: this.currentDateTime,
            timestamp: new Date().getTime()
        };
        
        sessionStorage.setItem(`offlineCheckIn_${this.recordId}`, JSON.stringify(offlineData));
        
        // Also update local check-in status
        const checkInStatus = {
            Check_In_Lat_Long__c: `${this.lat},${this.long}`,
            O_MCheckInTimestamp__c: this.currentDateTime,
            Check_Out_Lat_Long__c: this.CheckOutLocation,
            O_MCheckOutTimestamp__c: this.CheckOutDateTime
        };
        sessionStorage.setItem(`checkInStatus_${this.recordId}`, JSON.stringify(checkInStatus));
        
        this.showtoast('Info', 'Check-in saved offline. Will sync when back online.', 'info');
        this.load = false;
        
        // Update UI state
        if (this.checkIn) {
            this.checkIn = false;
            this.checkOut = true;
            // Update local properties for immediate UI reflection
            this.CheckInLocation = `${this.lat},${this.long}`;
            this.CheckINDateTime = this.currentDateTime;
        }
        return;
    }

    // Online mode - proceed with Apex call
    updateServiceAppoinment({ 
        recordId: this.serviceAppointmentId || this.recordId, // Use serviceAppointmentId if available
        lat: this.lat, 
        lon: this.long, 
        checkIn: this.checkIn, 
        currentDateTime: this.currentDateTime 
    })
    .then(result => {
        this.load = false;
        console.log('inside success result');
        console.log('result:::>>', result);

        if (result == 'Check In Successfully') {
            console.log('inside check in success');
            this.checkIn = false;
            this.checkOut = true;
        }
    })
    .catch(error => {
        this.load = false;
        this.showtoast('Error', error.body?.message || error.message || 'Check-in failed', 'error');
        console.log('inside catch');
        console.log('error::' + JSON.stringify(error));
    });
}
 
    
 
  handleCheckOut() {
    console.log('🚀 Starting Check-Out process...');
    
    // Validate GPS coordinates
    if (!this.lat || !this.long) {
        this.showtoast('Warning', 'Unable to get location. Please enable GPS and retry.', 'warning');
        return;
    }

    this.load = true;
    this.currentDateTime = new Date().toISOString();

    // NEW: Handle offline mode for check-out - FIXED
    if (!navigator.onLine) {
        console.log('📴 Offline mode - saving check-out data locally');
        
        const offlineData = {
            recordId: this.serviceAppointmentId || this.recordId, // Use serviceAppointmentId if available
            lat: this.lat,
            lon: this.long,
            checkIn: false, // This is check-out
            currentDateTime: this.currentDateTime,
            timestamp: new Date().getTime()
        };
        
        sessionStorage.setItem(`offlineCheckOut_${this.recordId}`, JSON.stringify(offlineData));
        
        // Also update local check-out status
        const checkInStatus = JSON.parse(sessionStorage.getItem(`checkInStatus_${this.recordId}`)) || {};
        checkInStatus.Check_Out_Lat_Long__c = `${this.lat},${this.long}`;
        checkInStatus.O_MCheckOutTimestamp__c = this.currentDateTime;
        sessionStorage.setItem(`checkInStatus_${this.recordId}`, JSON.stringify(checkInStatus));
        
        this.showtoast('Info', 'Check-out saved offline. Will sync when back online.', 'info');
        this.load = false;
        
        // Update UI state
        this.checkIn = false;
        this.checkOut = false;
        // Update local properties for immediate UI reflection
        this.CheckOutLocation = `${this.lat},${this.long}`;
        this.CheckOutDateTime = this.currentDateTime;
        
        // Optionally close the action after delay
        setTimeout(() => {
            const closeEvent = new CustomEvent('close');
            this.dispatchEvent(closeEvent);
        }, 1500);
        
        return;
    }

    // Online mode - proceed with Apex call
    console.log('Calling updateServiceAppoinment for Check-Out with params:', {
        recordId: this.serviceAppointmentId || this.recordId,
        lat: this.lat,
        lon: this.long,
        checkIn: false,
        currentDateTime: this.currentDateTime
    });

    updateServiceAppoinment({
        recordId: this.serviceAppointmentId || this.recordId,
        lat: this.lat,
        lon: this.long,
        checkIn: false,
        currentDateTime: this.currentDateTime
    })
    .then((result) => {
        console.log('✅ Check-Out result:', result);
        if (result === 'MISSING_VALUES') {
            this.showtoast('Error', 'Missing data. Please try again.', 'error');
        } else {
            this.showtoast('Success', 'Check-Out completed successfully.', 'success');
        }

        // Refresh UI state
        this.getCheckInStatus();

        // Close quick action after success
        setTimeout(() => {
            const closeEvent = new CustomEvent('close');
            this.dispatchEvent(closeEvent);
        }, 1000);
    })
    .catch((error) => {
        console.error('❌ Check-Out error:', error);
        this.showtoast('Error', 'Error during Check-Out: ' + (error.body?.message || error.message), 'error');
    })
    .finally(() => {
        this.load = false;
    });
}
 
getBrowserLocation() {
    if (!navigator.geolocation) {
        this.showtoast('Warning', 'Geolocation not supported by your browser', 'warning');
        return;
    }
    navigator.geolocation.getCurrentPosition(
        position => this.updateLocation(position.coords),
        () => this.showtoast('Warning', 'Please enable your device location', 'warning'),
        { enableHighAccuracy: true }
    );
}

getMobileLocation() {
    const locationService = getLocationService();
    if (!locationService || !locationService.isAvailable()) {
        this.showtoast('Error', 'Location service not available on this device', 'error');
        return;
    }
    locationService.getCurrentPosition({ enableHighAccuracy: true })
        .then(pos => this.updateLocation(pos.coords))
        .catch(() => this.showtoast('Warning', 'Please enable your device location', 'warning'));
}

updateLocation(coords) {
    this.lat = coords.latitude;
    this.long = coords.longitude;
    this.lstMarkers = [
        { location: { Latitude: this.lat, Longitude: this.long }, title: 'Current Location' }
    ];
    
    // 🚀 ADD THIS LINE - Trigger auto check-in after location is captured
    this.triggerAutoCheckIn();
}

// ADD THIS NEW METHOD
triggerAutoCheckIn() {
    console.log('📍 Location captured, checking if auto check-in needed...');
    
    // Only auto check-in if:
    // 1. We're in check-in mode (this.checkIn = true)
    // 2. We don't already have check-in data
    if (this.checkIn && (!this.CheckInLocation || !this.CheckINDateTime)) {
        console.log('🚀 Auto-triggering check-in');
        this.handleCheckInCheckOut();
    } else {
        console.log('⏸️ Auto check-in skipped - already checked in or not needed');
    }
}
 
 
 
 
 
 
 
 
 
 
    // @track reasonUnavailability = [];
 
 
    //   @track objectName='WorkOrder';
    //   @track fieldName='Reason_for_Unavailability__c';
 
    //       @track unavailability;
 
 
    //   fieldPicklistValue(){
    //     fieldPicklistValue({objectName:this.objectName, fieldName:this.fieldName})
    //     .then( result => {
    //         console.log('Rsult of picklist ::', result);
    //         this.reasonUnavailability=result;
    //         })
    //     .catch(error => {
    //             console.error('Error loading picklist values:', error);
    //         });
    // }
 
      handlereasonForUnavailability(event) {
 
        console.log('event detail value ::', event.detail.value);
        console.log('event detail value ::', event.target.value);
 
        this.unavailability = event.detail.value;
 
        console.log('Reson unavilability ::', this.unavailability);
 
        if(this.unavailability =='Other'){
 
            console.log('reason other inside::', this.unavailability);
 
            this.otherRemarkSelected=true;
 
           console.log('reason other inside::', this.otherRemarkSelected);
 
           this.showChildWOStartEndDate=false;
 
           // this.showEnterCustomerNameFlatNumber=false;
        }
          if(this.unavailability !='Other'){
 
 
           // this.otherRemarkSelected=false;
             this.showChildWOStartEndDate=false;
 
           // this.showEnterCustomerNameFlatNumber=false;
        }
         
 
        if(event.target.value=='House locked'){
 
           // this.showEnterCustomerNameFlatNumber=true;
            this.otherRemarkSelected=false;
            this.showChildWOStartEndDate=true;
        }
         if(event.target.value!='House locked'){
 
           // this.showEnterCustomerNameFlatNumber=true;
            this.otherRemarkSelected=false;
            this.showChildWOStartEndDate=false;
        }
    }
 
    handleOtherRemark(event){
 
        this.otherRemarkValue = event.target.value;
    }
 
 
 
    // getCheckInStatus() {
    //     console.log('recordId:::' + this.recordId);
    //     getCheckInStatus({ recordId: this.recordId })
    //         .then(result => {
    //             console.log('inside success' + JSON.stringify(result));
             
    //         this.CheckOutLocation = result.Check_Out_Lat_Long__c ? String(result.Check_Out_Lat_Long__c) : '';
    //         this.CheckInLocation = result.Check_In_Lat_Long__c ? String(result.Check_In_Lat_Long__c) : '';
    //          this.CheckINDateTime = result.O_MCheckInTimestamp__c    ? result.O_MCheckInTimestamp__c : '';
    //          this.CheckOutDateTime = result.O_MCheckOutTimestamp__c  ? result.O_MCheckOutTimestamp__c : '';
           
    //             // if(this.CheckOutLocation != '' && this.CheckInLocation != '' && this.CheckOutDateTime != '' && this.CheckINDateTime != ''){
    //             //     this.checkOut = false;
    //             //     this.checkIn = false;
    //             //     this.showEnableMessage = true;
    //             //     this.showMap = false;
    //             //     this.handleCancel();
    //             //      this.showtoast('warning','Already Checked In','warning');
    //             // }
 
    //              if((this.CheckInLocation != '' || this.CheckINDateTime != '') && (this.CheckOutLocation == '' || this.CheckOutDateTime == '')) {
    //                 this.checkIn = false;
    //                 this.checkOut = true;
    //             }
    //             else if((this.CheckOutLocation != '' || this.CheckOutDateTime != '') && (this.CheckInLocation == '' || this.CheckINDateTime == '')){
    //                 this.checkIn = true;
    //                 this.checkOut = false;
    //             }
    //             // else if((this.CheckInLocation != '' || this.CheckINDateTime != '') && (this.CheckOutLocation == '' || this.CheckOutDateTime == '')){
    //             //     this.checkIn = true;
    //             //     this.checkOut = false;
    //             // }
    //             this.handleGetLocation();
 
    //         })
    //         .catch(error => {
    //             // this.dispatchEvent(customEvent);
    //             this.showtoast('Error', error, 'Error');
    //           //  this.handleCancel();
    //             console.log('inside catch');
    //             console.log('error::' + JSON.stringify(error));
    //         })
 
    // }
    getCheckInStatus() {
    console.log('recordId:::' + this.recordId);
    
    // Handle offline mode
    if (!navigator.onLine) {
        console.log('📴 Offline mode - using cached check-in status');
        const cachedStatus = sessionStorage.getItem(`checkInStatus_${this.recordId}`);
        if (cachedStatus) {
            const result = JSON.parse(cachedStatus);
            this.updateCheckInStatusUI(result);
        } else {
            console.log('No cached status found for offline mode');
        }
        return;
    }

    // Online mode - call Apex
    getCheckInStatus({ recordId: this.recordId })
        .then(result => {
            console.log('inside success' + JSON.stringify(result));
            
            // Cache the result for offline use
            sessionStorage.setItem(`checkInStatus_${this.recordId}`, JSON.stringify(result));
            
            this.updateCheckInStatusUI(result);
            this.handleGetLocation();
        })
        .catch(error => {
            // Only show error if online, silent fail for offline
            if (navigator.onLine) {
                this.showtoast('Error', error, 'Error');
            }
            console.log('inside catch');
            console.log('error::' + JSON.stringify(error));
        });
}

// Add this helper method to update UI
updateCheckInStatusUI(result) {
    this.CheckOutLocation = result.Check_Out_Lat_Long__c ? String(result.Check_Out_Lat_Long__c) : '';
    this.CheckInLocation = result.Check_In_Lat_Long__c ? String(result.Check_In_Lat_Long__c) : '';
    this.CheckINDateTime = result.O_MCheckInTimestamp__c ? result.O_MCheckInTimestamp__c : '';
    this.CheckOutDateTime = result.O_MCheckOutTimestamp__c ? result.O_MCheckOutTimestamp__c : '';

    if ((this.CheckInLocation != '' || this.CheckINDateTime != '') && (this.CheckOutLocation == '' || this.CheckOutDateTime == '')) {
        this.checkIn = false;
        this.checkOut = true;
    } else if ((this.CheckOutLocation != '' || this.CheckOutDateTime != '') && (this.CheckInLocation == '' || this.CheckINDateTime == '')) {
        this.checkIn = true;
        this.checkOut = false;
    }
}
 
 
     async handleFile(event) {
        console.log('📥 inside handleFile');
       // let newSlots = event.detail.steps;
        this.photoUploadSlots =event.detail.steps;
 
        for (let i = 0; i < photoUploadSlots.length; i++) {
        let slot = photoUploadSlots[i];
            console.log(`🔄 Processing Photo ${i + 1}`);
 
            if (slot.base64Data) {
                try {
                    // Add prefix if missing
                    const fullBase64 = slot.base64Data.startsWith('data:image')
                        ? slot.base64Data
                        : `data:image/jpeg;base64,${slot.base64Data}`;
 
                    // 🔍 Original size in MB
                    const originalBytes = atob(fullBase64.split(',')[1]).length;
                    const originalMB = (originalBytes / (1024 * 1024)).toFixed(2);
                    console.log(`📷 Original Size of Photo ${i + 1}: ${originalMB} MB`);
 
                    // Convert to blob and compress
                    const blob = this.base64ToBlob(fullBase64);
                    const imageUrl = URL.createObjectURL(blob);
                    const compressedBlob = await this.compressImageFromURL(imageUrl);
 
                    // Convert compressed Blob back to base64
                    const compressedBase64 = await this.convertBlobToBase64(compressedBlob);
                    const compressedBytes = atob(compressedBase64).length;
                    const compressedMB = (compressedBytes / (1024 * 1024)).toFixed(2);
                    console.log(`📉 Compressed Size of Photo ${i + 1}: ${compressedMB} MB`);
 
                    // Store compressed result
                    slot.base64Data = compressedBase64;
 
                } catch (error) {
                //console.error(`❌ Compression failed for Photo ${i + 1}:`, error);
 
                // Only show toast if compressed base64 is not usable
                if (!slot.base64Data || slot.base64Data.length < 100) {
                console.error(`❌ Compression failed for Photo ${i + 1}:`, error?.message || JSON.stringify(error) || 'Unknown error');
                } else {
                    console.warn(`⚠️ Compression threw error but base64 still present for Photo ${i + 1}`);
                }
            }
 
 
            } else {
                console.warn(`⚠️ Skipped Photo ${i + 1}: base64Data missing.`);
            }
        }
 
       // this.photoUploadSlots = newSlots;
        console.log('✅ Final photoUploadSlots set');
    }
 
 
 
   
   async handleFinalSave() {
 
    this.getCheckInStatus();
       // const workStepName = 'Letters/Notices';
        const allFilesSelected = this.photoUploadSlots.length === 2 &&
            this.photoUploadSlots.every(slot => slot.fileName && slot.base64Data);
 
        if (!allFilesSelected) {
            this.load = false;
            //console.log('📸 Final slot data before save:', JSON.stringify(this.photoUploadSlots, null, 2));
            this.showtoast('Warning', 'Please Capture 2 photos.', 'warning');
            return;
        }
 
        // if(!this.rMCloserRemark){
 
        //  this.showtoast('Warning', 'Please Enter Closer Remark.', 'warning');
        // return;
        // }
 
         if(!this.otherRemarkValue && this.otherRemarkSelected){
 
  this.showtoast('Warning', 'Please Enter Remark.', 'warning');
 
    return;
    }
 
         if(!this.selectedDateTime && this.showChildWOStartEndDate){
 
  this.showtoast('Warning', 'Please Enter Start Date.', 'warning');
 
    return;
    }
 
        this.load = true;
 
         var imagesList = [];
                this.photoUploadSlots.forEach(item => {
                    imagesList.push({
                        base64Data: item.base64Data,
                        fileName: item.fileName,
                        label: item.label
                    })
                })
 
                var temp = this.uploadFile(imagesList);
 
        saveImage({
            listFiles: imagesList,
            recordId: this.recordId,
            reasonUnavailability : this.unavailability,
            otherRemarkValue : this.otherRemarkValue,
           // rMCloserRemark : this.rMCloserRemark,
            selectedDateTime : this.selectedDateTime
          //  selectedEndDateTime : this.selectedEndDateTime
           
        })
        .then((result) => {
            this.showtoast('Success', 'Details saved successfully!', 'success');
            this.load = false;
 
           // this.handleCheckInCheckOut();
 
            //this.handleCancel();
             setTimeout(() => {
            history.back();
        }, 1000);
         //  history.back();
 
         //   this.dispatchEvent(new CustomEvent('cancel'));
        })
        .catch(error => {
            this.load = false;
            //console.error('❌ Save error:', JSON.stringify(error, null, 2));
            const message = error?.body?.message || error?.message || 'Unknown error occurred';
            this.showtoast('Error', message, 'error');
        });
    }
 
     uploadFile(imagesList) {
 
    }
 
    async base64ToBlob(base64Data) {
        const byteString = atob(base64Data.split(',')[1]);
        const mimeString = base64Data.split(',')[0].split(':')[1].split(';')[0];
        const ab = new ArrayBuffer(byteString.length);
        const ia = new Uint8Array(ab);
        for (let i = 0; i < byteString.length; i++) {
            ia[i] = byteString.charCodeAt(i);
        }
        return new Blob([ab], { type: mimeString });
    }
 
    async compressImageFromURL(imageUrl) {
        return new Promise((resolve, reject) => {
            const img = new Image();
 
            img.onload = () => {
                try {
                    const canvas = document.createElement('canvas');
                    const ctx = canvas.getContext('2d');
                    const maxWidth = 1600;
                    const maxHeight = 1600;
                    let width = img.width;
                    let height = img.height;
 
                    const ratio = Math.min(maxWidth / width, maxHeight / height);
                    width *= ratio;
                    height *= ratio;
 
                    canvas.width = width;
                    canvas.height = height;
                    ctx.drawImage(img, 0, 0, width, height);
 
                        try {
                            canvas.toBlob(
                                (blob) => {
                                    if (blob) {
                                        resolve(blob);
                                    } else {
                                        console.warn('⚠️ toBlob returned null. Possibly tainted canvas or unsupported format.');
                                        reject(new Error('Canvas compression failed. Blob was null.'));
                                    }
                                },
                                'image/jpeg',
                                9.1
                            );
                        } catch (err) {
                            console.error('❌ Error during canvas.toBlob execution:', err);
                            reject(new Error('Exception during canvas.toBlob: ' + err.message));
                        }
                } catch (error) {
                    reject(new Error('Error during image compression: ' + error.message));
                }
            };
 
            img.onerror = () => {
                reject(new Error('Error loading image.'));
            };
 
            img.crossOrigin = 'anonymous';
            img.src = imageUrl;
        });
    }
 
    async convertBlobToBase64(blob) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = () => resolve(reader.result.split(',')[1]);
            reader.onerror = reject;
            reader.readAsDataURL(blob);
        });
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