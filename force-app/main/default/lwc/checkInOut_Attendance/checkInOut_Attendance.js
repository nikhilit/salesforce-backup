import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import { getLocationService } from 'lightning/mobileCapabilities';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { refreshApex } from '@salesforce/apex';

import Check_In_Timestamp from '@salesforce/schema/WorkOrder.Check_In_Date_Time__c';
import Check_Out_Timestamp from '@salesforce/schema/WorkOrder.Check_Out_Date_Time__c';
import Attendance_Status from '@salesforce/schema/WorkOrder.Attendance_Status__c';
import Absence_or_Leave_Reason from '@salesforce/schema/WorkOrder.Absence_Leave_Reason__c';

// import Check_In_Lat_Long from '@salesforce/schema/WorkOrder.Check_In_Location__c';
// import Check_Out_Lat_Long from '@salesforce/schema/WorkOrder.Check_Out_Location__c';

// import CheckInLat from '@salesforce/schema/WorkOrder.Check_In_Location__Latitude__s';
// import CheckInLong from '@salesforce/schema/WorkOrder.Check_In_Location__Longitude__s';
// import CheckOutLat from '@salesforce/schema/WorkOrder.Check_Out_Location__Latitude__s';
// import CheckOutLong from '@salesforce/schema/WorkOrder.Check_Out_Location__Longitude__s';


const FIELDS = [
    Check_In_Timestamp,
    Check_Out_Timestamp,
    Attendance_Status,
    Absence_or_Leave_Reason,
    'WorkOrder.Check_In_Location__Latitude__s',
    'WorkOrder.Check_In_Location__Longitude__s',
    'WorkOrder.Check_Out_Location__Latitude__s',
    'WorkOrder.Check_Out_Location__Longitude__s'
];

export default class CheckInOut_Attendance extends LightningElement {
    @api recordId;
    checkInTime;
    checkOutTime;
    absenceOrLeaveReason;
    status;
    selectedStatus;
    latitude;
    longitude;
    locationCaptured = false;
    isLoading;
    wiredResult;

    
    @track lat;
    @track long;
    @track lat2;
    @track long2;
    @track lstMarkers = [];
    @track showMap = true;

    statusOptions = [
        { label: 'Present', value: 'Present' },
        { label: 'On Leave', value: 'On Leave' }
    ];

    today = new Date().toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' });

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord(result) {
        this.isLoading = true;
        this.wiredResult = result;
        const { data, error } = result;
        if (data) {
            this.checkInTime = data.fields.Check_In_Date_Time__c?.value;
            this.checkOutTime = data.fields.Check_Out_Date_Time__c?.value;
            this.status = data.fields.Attendance_Status__c?.value;
            this.absenceOrLeaveReason = data.fields.Absence_Leave_Reason__c?.value;
            this.lat = data.fields.Check_In_Location__Latitude__s?.value;
            this.long = data.fields.Check_In_Location__Longitude__s?.value;
            this.lat2 = data.fields.Check_Out_Location__Latitude__s?.value;
            this.long2 = data.fields.Check_Out_Location__Longitude__s?.value;
            this.isLoading = false;
        } else if (error) {
            this.isLoading = false;
            console.error('Wire error:', JSON.stringify(error, null, 2));
        }
    }

    
    get isCheckedIn() {
        return this.status === 'Present' && this.checkInTime;
    }
    get hasCheckedIn() {
        return (this.status === 'Present' || this.status === 'On Leave' || this.status === 'Day Out') && this.checkInTime;
    }

    get isOnLeave() {
        return this.selectedStatus === 'On Leave';
    }
    
    get onLeave(){
        return this.status === 'On Leave';
    }

    get isCheckedOut() {
        return this.status === 'Day Out' && this.checkOutTime && this.status === 'Present' && this.checkInTime;
    }
    
    handleGetLocation() {
        this.isLoading = true;
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

                    if(this.status === 'Present'){
                        this.lat2 = latitude;
                        this.long2 = longitude;
                    } else {
                        this.lat = latitude;
                        this.long = longitude;
                    }

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
                }
            );
            this.isLoading = false;
        } else {
            this.showtoast('Warning', 'Geolocation is not supported by this browser', 'warning');
            this.isLoading = false;
        }
        
    }
    getMobileLocation() {
        const locationService = getLocationService();

        if (!locationService || !locationService.isAvailable()) {
            this.showtoast('LocationService Not Available', 'Please use a GPS-enabled mobile device and ensure location is turned on.', 'error');
            this.showMap = true;
            this.isLoading = false;
            return;
        }

        const options = {
            enableHighAccuracy: true
        };

        locationService.getCurrentPosition(options)
            .then(result => {
                console.log('Location result:', result);
                var latitude = result.coords.latitude;
                var longitude = result.coords.longitude;

                if(this.status === 'Present'){
                    this.lat2 = latitude;
                    this.long2 = longitude;
                } else {
                    this.lat = latitude;
                    this.long = longitude;
                }

                this.lstMarkers = [{
                    location: {
                        Latitude: latitude,
                        Longitude: longitude
                    },
                    title: "Your Current Location"
                }];
                this.zoomlevel = "15";
            })
            .catch(error => {
                console.error('Location error:', error);
                this.showtoast('Warning', 'Please enable your device location.', 'Warning');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleReasonChange(event) {
        this.absenceOrLeaveReason = event.detail.value;
    }
    
    handleStatusChange(event) {
        this.selectedStatus = event.detail.value;
    }

    handleCheckIn() {
        this.isLoading = true;
        const now = new Date().toISOString();
        this.storeLocally({ checkIn: now, status: this.selectedStatus, absenceOrLeaveReason: this.absenceOrLeaveReason, lat: this.lat, long: this.long });

        this.updateSARecord({
            [Check_In_Timestamp.fieldApiName]: now,
            [Attendance_Status.fieldApiName]: this.selectedStatus,
            [Absence_or_Leave_Reason.fieldApiName]: this.absenceOrLeaveReason,
            Check_In_Location__Latitude__s: this.lat,
            Check_In_Location__Longitude__s: this.long
        });

        this.absenceOrLeaveReason = this.absenceOrLeaveReason;
        this.status = this.selectedStatus;
        this.checkInTime = now;
        this.selectedStatus = "";
        this.isLoading = false;
    }

    handleCheckOut() {
        this.isLoading = true;
        const now = new Date().toISOString();
        this.storeLocally({ checkOut: now, status: 'Day Out', lat2: this.lat2, long2: this.long2 });

        this.updateSARecord({
            [Check_Out_Timestamp.fieldApiName]: now,
            [Attendance_Status.fieldApiName]: 'Day out',
            Check_Out_Location__Latitude__s: this.lat2,
            Check_Out_Location__Longitude__s : this.long2
        });

        this.status = 'Day Out';
        this.checkOutTime = now;
        this.selectedStatus = "";
        this.isLoading = false;
    }

    updateSARecord(fieldValues) {
        this.isLoading = true;
        const fields = {
            Id: this.recordId,
            ...fieldValues
        };

        const recordInput = { fields };

        updateRecord(recordInput)
            .then(() => {
                this.showToast('Success', 'Record updated', 'success');
            })
            .catch(error => {
                this.showToast('Error updating record', error.body.message, 'error');
                console.error(error);
            });
    }

    storeLocally(dataObj) {
        try {
            if (typeof localStorage !== 'undefined') {
                const localData = JSON.parse(localStorage.getItem('saCheckinData')) || {};
                localData[this.recordId] = {
                    ...localData[this.recordId],
                    ...dataObj
                };
                localStorage.setItem('saCheckinData', JSON.stringify(localData));
            }
        } catch (e) {
            console.warn('localStorage not available in this environment', e);
        }
    }

    getStoredValue(key) {
        try {
            const localData = JSON.parse(localStorage.getItem('saCheckinData')) || {};
            const saData = localData[this.recordId] || {};
            return saData[key];
        } catch (e) {
            console.warn('localStorage not available in this environment', e);
            return null;
        }
    }

    handleRefresh() {
        this.isLoading = true;
        if (this.wiredResult) {
        refreshApex(this.wiredResult);
        this.isLoading = false;
        }
    }
    
    connectedCallback() {
        this.handleRefresh();
        this.isLoading = true;
        this.status = this.getStoredValue('status') || this.status;
        this.absenceOrLeaveReason = this.getStoredValue('absenceOrLeaveReason') || this.absenceOrLeaveReason;
        this.checkInTime = this.getStoredValue('checkIn') || this.checkInTime;
        this.checkOutTime = this.getStoredValue('checkOut') || this.checkOutTime;
        this.lat = this.getStoredValue('lat') || this.lat;
        this.long = this.getStoredValue('long') || this.long;
        this.lat2 = this.getStoredValue('lat2') || this.lat2;
        this.long2 = this.getStoredValue('long2') || this.long2;

        this.lstMarkers = [
            {
                location: {
                    Latitude: this.lat2 || this.lat,
                    Longitude: this.long2  || this.long
                },
                title: this.lat2 ? "Check out location" : "Check in location"
            }
        ];
        this.isLoading = false;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}