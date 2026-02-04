import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
//import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getLocationService } from 'lightning/mobileCapabilities';
import FORM_FACTOR from '@salesforce/client/formFactor';
import updateServiceAppoinment from '@salesforce/apex/CheckInController.updateServiceAppoinment';
import getCheckInStatus from '@salesforce/apex/CheckInController.getCheckInStatus';
import { getRelatedListRecords } from "lightning/uiRelatedListApi";
//import LightningAlert from 'lightning/alert';
 
import USER_ID from '@salesforce/user/Id';
import USERNAME_FIELD from '@salesforce/schema/User.Username';
import PROFILE_NAME_FIELD from '@salesforce/schema/User.Profile.Name';
import SERVICE_APPOINTMENT_FIELD from '@salesforce/schema/WorkOrder.Service_Appointment__c';
import { getListUi } from 'lightning/uiListApi';
import DOCUMENT_OBJECT from '@salesforce/schema/Document__c';
 
 
export default class CheckInComponentOffline extends LightningElement {
    // ---------------- RECORD ID HANDLING ----------------
    _recordId;
    @api
    set recordId(value) {
        this._recordId = value;
        if (this._recordId) {
            console.log('✅ recordId is now set:', this._recordId);
            this.initializeComponent();
        }
    }
    get recordId() {
        return this._recordId;
    }
 
    // ---------------- TRACKED PROPERTIES ----------------
   // @track showModal = true;
    @track checkIn = true;
    @track checkOut = false;
    @track lat;
    @track long;
    @track lstMarkers = [];
    @track requestInProgress = false;
    @track currentDateTime;
    @track CheckInLocation = '';
    @track CheckOutLocation = '';
    @track CheckINDateTime = '';
    @track CheckOutDateTime = '';
    @track userName;
    @track profileName;
    @track approvalStatus = '';
    @track documentRecord;
    @track siteDocumentApproved = false;
    @track submitDisabled = true;
    @track serviceAppointmentId;
    @track tbtApproved = false;
    @track tbtApprovalStatus = '';
    tbtToastShown = false;
    @track riserExecutionCompleted = false;
    riserToastShown = false;
   // disconnected = false;
 
     
 
 
 
    toastShown = false;
    skipAlreadyCheckedToast = false;
 
    workStepConfig = {
        'Riser Painting': ['Check-in', 'CO Execution Detail'],
        'Riser Maintenance': ['Check-in', 'CO Execution Detail'],
        'Riser Replacement': ['Check-in', 'CO Execution Detail'],
        'Domestic Meter Checking': ['Check-in', 'Site Details'],
        'Default': ['Check-in', 'CO Execution Detail']
    };
 
    // ---------------- CONNECTED CALLBACK ----------------
    connectedCallback() {
      //  window.addEventListener('online', () => this.handleGetLocation());
      // Sync offline data when connection restores
 
      // 🟢 Migrate any old offline keys saved before userName was known
    const oldKey = `checkInStatus_undefined_${this.recordId}`;
    const newKey = `checkInStatus_${this.userName || 'fallback'}_${this.recordId}`;
    if (sessionStorage.getItem(oldKey) && !sessionStorage.getItem(newKey)) {
        sessionStorage.setItem(newKey, sessionStorage.getItem(oldKey));
        sessionStorage.removeItem(oldKey);
    }
        window.addEventListener('online', () => {
            console.log('🌐 Connection restored — syncing offline data...');
            this.handleSyncOfflineData();
            this.handleGetLocation();
        });
        window.addEventListener('offline', () => this.showToast('Info', 'You are offline', 'info'));
         // Try syncing immediately if online
        if (navigator.onLine) {
            this.handleSyncOfflineData();
        }
    }
 
    // ---------------- INITIALIZATION ----------------
    initializeComponent() {
        if (!this.recordId) {
            console.warn('initializeComponent called but recordId is not yet available');
            return;
        }
 
        console.log('🧩 Initializing component for recordId:', this.recordId);
       // this.getOfflineApprovalStatus();
       // this.checkUploadSiteDocumentApprovedOffline();
        this.tbtToastShown = false;
       
        this.checkTbtDocumentApprovedHybrid();
        this.checkUploadSiteDocumentApprovedHybrid();
        this.checkRiserExecutionStatusHybrid();
        this.validateWorkSteps();
    //     if (!navigator.onLine) {
    //     const cachedRiserStatus = sessionStorage.getItem(`riserStatus_${this.recordId}`);
    //     if (cachedRiserStatus && cachedRiserStatus !== 'Completed') {
    //         this.showToast('Warning', 'Please complete Riser Execution Details before ending the job', 'warning');
    //         this.disableCheckOutOnly();
    //     }
    // }
        this.handleGetLocation();
        this.getOfflineCheckInStatus();
    }
 
//  disconnectedCallback() {
//     console.log('🧹 Component is disconnected — canceling pending alerts.');
//     this.disconnected = true;
// }
 
    // ---------------- USER INFO ----------------
    @wire(getRecord, { recordId: USER_ID, fields: [USERNAME_FIELD, PROFILE_NAME_FIELD] })
    wiredUser({ data, error }) {
        if (data) {
            this.userName = data.fields.Username.value;
            this.profileName = data.fields.Profile.value.fields.Name.value;
            // 🟢 ADD HERE — Refresh offline check-in status after username is available
            this.getOfflineCheckInStatus();
            // 🟢 Now that userName is available, recheck TBT document status
            setTimeout(() => {
            console.log('🔁 Rechecking TBT document after userName loaded:', this.userName);
            this.checkTbtDocumentApprovedHybrid(); // Re-evaluate cached/online data
            }, 500);
 
            console.log('👤 User:', this.userName, 'Profile:', this.profileName);
        } else if (error) {
            console.error('Error fetching user info:', error);
        }
    }
 
    // 🟢 NEW — Fetch TBT Document list (Online Mode)
@wire(getListUi, {
    objectApiName: DOCUMENT_OBJECT,
    listViewApiName: 'O_M_TBT_Documents',
    pageSize: 200
})
wiredTbtDocuments(result) {
    const { data, error } = result;
 
    if (data && this.userName) {
        const records = data.records.records;
        const match = records.find(
            rec => rec.fields.Submitted_Agent_Name__c.value === this.userName
        );
 
        if (match) {
            const apprStatus = match.fields.Approval_Status_O_M__c.value;
            this.tbtApprovalStatus = apprStatus;
 
            // Cache offline
            const cacheKey = `tbtDoc_${this.userName}`;
            sessionStorage.setItem(cacheKey, JSON.stringify({ Approval_Status_O_M__c: apprStatus }));
 
            if (apprStatus === 'Approved') {
                this.tbtApproved = true;
                this.enableCheckInOut();
            } else {
                this.tbtApproved = false;
                //this.showToast('Warning', 'TBT Document not approved yet', 'warning');
                if (!this.tbtToastShown) {
                this.showToast('Warning', 'Please upload and get TBT document approved', 'warning');
                this.tbtToastShown = true;
                }
 
                this.disableCheckInOut();
            }
        }
    } else if (error) {
        console.error('Error fetching TBT documents:', error);
    }
 
    // Always re-check hybrid logic
    this.checkTbtDocumentApprovedHybrid();
}
 
 
    // ---------------- SITE DOCUMENT APPROVAL (WIRE FOR HYBRID MODE) ----------------
@wire(getRecord, { recordId: '$recordId', fields: ['WorkOrder.Approval_Status__c'] })
wiredSiteDocument({ data, error }) {
    if (data) {
        const approvalStatus = data.fields.Approval_Status__c?.value || '';
        console.log('📄 Site Document Approval Status (Online):', approvalStatus);
 
        // 🟢 Cache it in sessionStorage for offline reuse
        const siteDoc = { Approval_Status__c: approvalStatus };
        sessionStorage.setItem(`siteDoc_${this.recordId}`, JSON.stringify(siteDoc));
 
        // 🟡 Re-run hybrid validation whenever fetched online
        this.checkUploadSiteDocumentApprovedHybrid();
    } else if (error) {
        console.error('Error fetching site document status:', error);
    }
}
 
 
    // ---------------- FETCH SERVICE APPOINTMENT ----------------
    @wire(getRecord, { recordId: '$recordId', fields: [SERVICE_APPOINTMENT_FIELD] })
    wiredWorkOrder({ data, error }) {
        if (data) {
            // ✅ Try to get related ServiceAppointment Id
            this.serviceAppointmentId = data.fields.Service_Appointment__c?.value || null;
            console.log('ServiceAppointmentId →', this.serviceAppointmentId);
 
            if (this.serviceAppointmentId) {
                this.fetchServiceAppointmentStatus();
            } else {
                console.warn('⚠️ No ServiceAppointment on WorkOrder — trying fallback');
                this.fetchServiceAppointmentFallback();
            }
        } else if (error) {
            console.error('Error fetching WorkOrder:', error);
            this.fetchServiceAppointmentFallback();
        }
    }
 
    // ✅ Fallback (offline or missing lookup)
    fetchServiceAppointmentFallback() {
        if (!this.recordId) return;
 
        getCheckInStatus({ recordId: this.recordId })
            .then(sa => {
                if (sa) {
                    this.serviceAppointmentId = sa.Id;
                    console.log('✅ Fallback ServiceAppointmentId:', this.serviceAppointmentId);
                    this.fetchServiceAppointmentStatus();
                } else {
                    console.warn('⚠️ No ServiceAppointment found via fallback');
                }
            })
            .catch(err => console.error('❌ Fallback fetch error:', err));
    }
 
    fetchServiceAppointmentStatus() {
        if (!this.serviceAppointmentId) return;
        getCheckInStatus({ recordId: this.serviceAppointmentId })
            .then(sa => {
                console.log('📦 ServiceAppointment fetched:', sa);
 
                const checkInTime = sa.O_MCheckInTimestamp__c;
                const checkOutTime = sa.O_MCheckOutTimestamp__c;
 
                sessionStorage.setItem(`checkInStatus_${this.userName}_${this.recordId}`, JSON.stringify({
                    CheckINDateTime: checkInTime,
                    CheckOutDateTime: checkOutTime,
                    CheckInLocation: sa.Check_In_Lat_Long__c || '',
                    CheckOutLocation: sa.Check_Out_Lat_Long__c || ''
                }));
 
                this.updateCheckInOutStatus(checkInTime, checkOutTime);
            })
            .catch(err => console.error('Error fetching ServiceAppointment:', err));
    }
 
    @wire(getRelatedListRecords, {
    parentRecordId: '$recordId',
    relatedListId: 'WorkSteps',
    fields: ['WorkStep.Name', 'WorkStep.Status'],
    sortBy: ['CreatedDate DESC'],
    pageSize: 200
})
 
wiredWorkSteps({ data, error }) {
    if (data) {
        const records = data.records || [];
        console.log('WorkSteps:', records);
 
        const riserInStep = records.find(r => r.fields.Name.value === 'Riser Execution Details');
 
        this.riserInStatus = riserInStep ? riserInStep.fields.Status.value : 'Not Found';
 
        console.log('Riser Execution Status:', this.riserInStatus);
        sessionStorage.setItem(`riserStatus_${this.recordId}`, this.riserInStatus);
          setTimeout(() => {
            this.checkRiserExecutionStatusHybrid();
        }, 300);
 
    }else if (error) {
        console.error('Error fetching work steps:', error);
    }
       
}
 
    // ---------------- CHECK-IN / CHECK-OUT UI ----------------
    updateCheckInOutStatus(checkInTime, checkOutTime) {
        console.log('🔍 updateCheckInOutStatus →', { checkInTime, checkOutTime });
        const hasCheckedIn = !!checkInTime;
        const hasCheckedOut = !!checkOutTime;
 
        if (hasCheckedIn && hasCheckedOut) {
            this.checkIn = false;
            this.checkOut = false;
            if (!this.toastShown) {
                //this.showToast('Info', 'You have already checked in and checked out.', 'info');
                this.toastShown = true;
            }
        } else if (hasCheckedIn && !hasCheckedOut) {
            this.checkIn = false;
            this.checkOut = true;
 
            setTimeout(() => {
            this.checkRiserExecutionStatusHybrid();
            }, 100);
 
 
        } else {
            this.checkIn = true;
            this.checkOut = false;
        }
    }
 
    getOfflineCheckInStatus() {
       // const status = JSON.parse(sessionStorage.getItem(`checkInStatus_${this.recordId}`)) || {};
       // const key = `checkInStatus_${this.userName}_${this.recordId}`;//commentedout
       // const status = JSON.parse(sessionStorage.getItem(key)) || {};//commenteout
       // 🟢 Use fallback if userName not yet loaded (offline mode)
    //    const effectiveUser = this.userName || 'fallback';
    //    const key = `checkInStatus_${effectiveUser}_${this.recordId}`;
    //    const status = JSON.parse(sessionStorage.getItem(key)) || {};
 
    //     console.log('💾 From sessionStorage:', status);
    //     this.updateCheckInOutStatus(status.CheckINDateTime, status.CheckOutDateTime);
 
    // 🟢 Try both user-specific and fallback keys
    const userKey = `checkInStatus_${this.userName}_${this.recordId}`;
    const fallbackKey = `checkInStatus_fallback_${this.recordId}`;
 
    let status = JSON.parse(sessionStorage.getItem(userKey))
              || JSON.parse(sessionStorage.getItem(fallbackKey))
              || {};
 
    console.log('💾 Offline check-in status:', status);
 
    // 🟢 If fallback found, migrate it once username is available
    if (this.userName && sessionStorage.getItem(fallbackKey)) {
        sessionStorage.setItem(userKey, JSON.stringify(status));
        sessionStorage.removeItem(fallbackKey);
    }
 
    this.updateCheckInOutStatus(status.CheckINDateTime, status.CheckOutDateTime);
 
 
 
    }
 
    // ---------------- SYNC OFFLINE DATA ----------------
    handleSyncOfflineData() {
        if (!this.userName || !navigator.onLine) return;
 
        try {
           // const keys = Object.keys(sessionStorage).filter(k => k.startsWith(`checkInStatus_${this.userName}_`));
           // 🟢 Include fallback keys (for cases where userName wasn’t known offline)
        const keys = Object.keys(sessionStorage).filter(k => k.startsWith('checkInStatus_'));
 
 
            keys.forEach(key => {
                const recordId = key.split(`${this.userName}_`)[1];
                const data = JSON.parse(sessionStorage.getItem(key));
                if (!data || !recordId) return;
 
                if (data.CheckINDateTime || data.CheckOutDateTime) {
                    updateServiceAppoinment({
                        recordId: this.serviceAppointmentId || recordId,
                        lat: data.CheckOutLocation
                            ? data.CheckOutLocation.split(',')[0]
                            : data.CheckInLocation?.split(',')[0],
                        lon: data.CheckOutLocation
                            ? data.CheckOutLocation.split(',')[1]
                            : data.CheckInLocation?.split(',')[1],
                        checkIn: !data.CheckOutDateTime,
                        currentDateTime: data.CheckOutDateTime || data.CheckINDateTime
                    })
                        .then(() => {
                            console.log(`✅ Synced check-in/out for ${recordId}`);
                            sessionStorage.removeItem(key);
                        })
                        .catch(err => console.error('❌ Sync failed:', err));
                }
            });
        } catch (err) {
            console.error('Error syncing offline data:', err);
        }
    }
 
    // ---------------- DOCUMENT APPROVAL ----------------
    // getOfflineApprovalStatus() {
    //     try {
    //         const documentRecord = JSON.parse(sessionStorage.getItem(`document_${this.userName}`)) || null;
    //         const approvalStatus = documentRecord?.Approval_Status_O_M__c || '';
    //         this.documentRecord = documentRecord;
    //         this.approvalStatus = approvalStatus;
 
    //         if (
    //             [
    //                 'Domestic Meter Checking Field Agent',
    //                 'O&M Field Agent DOMESTIC METER CHECKING',
    //                 'O&M Supervisor DOMESTIC METER CHECKING',
    //                 'Rubber Hose Field Agent',
    //                 'O&M Rubber Hose Supervisor',
    //                 'O&M Rubber Hose Field Agent'
    //             ].includes(this.profileName)
    //         ) {
    //             console.log('Profile matched - skipping approval check');
    //         } else if (
    //             approvalStatus !== 'Approved' &&
    //             ['O&M Field Agent Riser Activity', 'O&M Field Agent IPD', 'O&M Supervisor IPD'].includes(this.profileName)
    //         ) {
    //             this.showToast('Warning', 'Please Upload TBT Documents', 'warning');
    //             this.disableCheckInOut();
    //         } else {
    //             this.enableCheckInOut();
    //         }
    //     } catch (error) {
    //         console.error('Error getting offline approval status', error);
    //     }
    // }
 
    // ---------------- SITE DOCUMENT APPROVAL ----------------
    // checkUploadSiteDocumentApprovedOffline() {
    //     try {
    //         const siteDoc = JSON.parse(sessionStorage.getItem(`siteDoc_${this.recordId}`)) || null;
    //         if (siteDoc && siteDoc.Approval_Status__c !== 'Approved') {
    //             this.showToast('Warning', 'Upload site document not approved', 'warning');
    //             this.siteDocumentApproved = false;
    //             this.disableCheckInOut();
    //         } else {
    //             this.siteDocumentApproved = true;
    //         }
    //     } catch (error) {
    //         console.error('Error checking site document approval offline', error);
    //     }
    // }
 
    // ---------------- SITE DOCUMENT APPROVAL (HYBRID: ONLINE + OFFLINE) ----------------
checkUploadSiteDocumentApprovedHybrid() {
    try {
        // Try cached approval info first (works offline)
        let siteDoc = JSON.parse(sessionStorage.getItem(`siteDoc_${this.recordId}`)) || null;
 
        // 🟢 If online, rely on latest cached or wire-updated info
        if (navigator.onLine && siteDoc) {
            console.log('✅ Using latest online approval status:', siteDoc.Approval_Status__c);
        } else if (!siteDoc) {
            console.warn('⚠️ No site document found in cache, assuming pending');
            siteDoc = { Approval_Status__c: 'Pending' };
        }
 
        // 🔍 Validation Logic
        if (siteDoc.Approval_Status__c !== 'Approved') {
            this.showToast('Warning', 'Upload site document not approved', 'warning');
            this.siteDocumentApproved = false;
            // Only disable Check-Out, not Check-In
            this.disableCheckOutOnly();
        } else {
            this.siteDocumentApproved = true;
            this.enableCheckInOut();
        }
 
    } catch (error) {
        console.error('Error checking site document approval hybrid', error);
    }
}
 
// 🟢 NEW — Riser Execution Work Step Validation (Hybrid)
checkRiserExecutionStatusHybrid() {
    try {
        const riserStatus = this.riserInStatus || 'Not Found';
 
        // 🔍 Validation Logic
        if (riserStatus == 'Completed') {
             this.riserExecutionCompleted = true;
            this.enableCheckInOut();
            this.riserToastShown = false;
        } else if (riserStatus !== 'Completed') {
            this.riserExecutionCompleted = false;
            if (this.checkOut && !this.riserToastShown) {
                this.showToast('Warning', 'Please complete Riser Execution Details before ending the job', 'warning');
                this.riserToastShown = true;
            }
            this.disableCheckOutOnly();
        } else {
            console.warn('⚠️ Riser Execution step not found or missing status');
        }
    } catch (error) {
        console.error('Error checking Riser Execution Details status:', error);
    }
}
 
 
// 🟢 NEW — TBT DOCUMENT APPROVAL (HYBRID: ONLINE + OFFLINE)
checkTbtDocumentApprovedHybrid() {
    try {
        const cacheKey = `tbtDoc_${this.userName}`;
        let tbtDoc = JSON.parse(sessionStorage.getItem(cacheKey)) || null;
 
        if (navigator.onLine && tbtDoc) {
            console.log('✅ Using latest online TBT approval:', tbtDoc.Approval_Status_O_M__c);
        } else if (!tbtDoc) {
            console.warn('⚠️ No TBT doc found in cache, assuming pending');
            tbtDoc = { Approval_Status_O_M__c: 'Pending' };
        }
 
        // 🔍 Validation Logic
        // if (tbtDoc.Approval_Status_O_M__c !== 'Approved') {
        //     this.tbtApproved = false;
        //     this.showToast('Warning', 'Please upload and get TBT document approved', 'warning');
        //     this.disableCheckInOut(); // applies to both check-in & check-out
        // } else {
        //     this.tbtApproved = true;
        //     this.enableCheckInOut();
        // }
        if (tbtDoc.Approval_Status_O_M__c === 'Approved') {
        this.tbtApproved = true;
        this.enableCheckInOut();
        console.log('✅ TBT Approved — no warning toast needed');
        this.tbtToastShown = false;
         } else {
         // Only show toast if NOT approved
         this.tbtApproved = false;
        this.disableCheckInOut();
        //this.showToast('Warning', 'Please upload and get TBT document approved', 'warning');
        if (!this.tbtToastShown) {
        this.showToast('Warning', 'Please upload and get TBT document approved', 'warning');
        this.tbtToastShown = true;
        }
 
        }
 
    } catch (error) {
        console.error('Error checking TBT document approval hybrid', error);
    }

    // 🟢 ADD: Debug toast behavior
this.debugTbtToast();
}

// 🟢 ADD - Debug method to track TBT toast behavior
debugTbtToast() {
    const cacheKey = `tbtDoc_${this.userName}`;
    const tbtDoc = JSON.parse(sessionStorage.getItem(cacheKey)) || null;
    
    console.log('🔍 TBT Toast Debug:', {
        userName: this.userName,
        tbtApproved: this.tbtApproved,
        tbtStatus: tbtDoc?.Approval_Status_O_M__c,
        tbtToastShown: this.tbtToastShown,
        isOnline: navigator.onLine,
        hasCachedData: !!tbtDoc
    });
}
 
 
 
    // ---------------- WORK STEP VALIDATION ----------------
    validateWorkSteps() {
        if (!navigator.onLine) {
            this.getOfflineWorkStepStatus();
        } else {
            this.enableCheckInOut();
        }
    }
 
    getOfflineWorkStepStatus() {
        try {
            const workType = sessionStorage.getItem(`workType_${this.recordId}`) || 'Riser Painting';
            const completedSteps = JSON.parse(sessionStorage.getItem(`completedSteps_${this.recordId}`)) || [];
            const requiredSteps = this.workStepConfig[workType] || this.workStepConfig['Default'];
            const pendingSteps = requiredSteps.filter(step => !completedSteps.includes(step));
 
            if (pendingSteps.length > 0) {
                // let message = '';
                // if (workType.startsWith('Riser')) message = 'Please Complete CO Execution Detail Task';
                // else if (workType === 'Domestic Meter Checking') message = 'Please Complete Site Details Task';
                // else message = 'Please Complete Required Work Steps';
                // this.showToast('Warning', message, 'warning');
                // this.disableCheckInOut();
            }
        } catch (error) {
            console.error('Error checking work step offline', error);
        }
    }
 
    // ---------------- ENABLE / DISABLE BUTTONS ----------------
    enableCheckInOut() {
        this.submitDisabled = false;
    }
 
    disableCheckInOut() {
        this.submitDisabled = true;
         this.tbtApproved = false; // Explicitly enforce state
        console.warn('⚠️ Check-In disabled: TBT document not approved.');
    }
 
    disableCheckOutOnly() {
    // Only restrict the Check Out button
    this.siteDocumentApproved = false;
     this.submitDisabled = true; // Prevent any accidental submission
    if (!this.tbtApproved) {
        this.tbtApproved = false;
    }
 
    // Handle Riser Execution restriction
    if (!this.riserExecutionCompleted) {
        this.riserExecutionCompleted = false;
    }
    console.warn('⚠️ Check-Out disabled: Document(s) not approved.');
   
    }
 
 
    // ---------------- HANDLE CHECK-IN / CHECK-OUT ----------------
    handleCheckIn() {
        console.log('▶️ Start Job clicked');
        this.processCheckInOut(true);
    }
 
    handleCheckOut() {
        console.log('⏹ End Job clicked');
        this.processCheckInOut(false);
    }
 
    processCheckInOut(isCheckIn) {
        if ((!this.siteDocumentApproved && !isCheckIn ) || !this.tbtApproved) {
            this.showToast('Warning', `Cannot ${isCheckIn ? 'check-in' : 'check-out'} without approved documents`, 'warning');
            return;
        }
 
        this.requestInProgress = true;
        this.currentDateTime = new Date().toISOString();
 
        if (!this.lat || !this.long) {
            this.showToast('Warning', 'Location not available. Enable GPS and try again.', 'warning');
            this.requestInProgress = false;
            return;
        }
 
        //const status = JSON.parse(sessionStorage.getItem(`checkInStatus_${this.recordId}`)) || {};
        //const key = `checkInStatus_${this.userName}_${this.recordId}`;//commentedout
        //const status = JSON.parse(sessionStorage.getItem(key)) || {};//commentedout
 
        // 🟢 Use fallback key when userName is not yet known
        const effectiveUser = this.userName || 'fallback';
        const key = `checkInStatus_${effectiveUser}_${this.recordId}`;
        const status = JSON.parse(sessionStorage.getItem(key)) || {};
 
        if (isCheckIn) {
            status.CheckInLocation = `${this.lat},${this.long}`;
            status.CheckINDateTime = this.currentDateTime;
        } else {
            status.CheckOutLocation = `${this.lat},${this.long}`;
            status.CheckOutDateTime = this.currentDateTime;
        }
        sessionStorage.setItem(key, JSON.stringify(status));
 
        // ✅ Handle Offline Mode (Skip Apex call)
    // if (!navigator.onLine) {
    //     this.showToast('Info', `${isCheckIn ? 'Check-in' : 'Check-out'} saved offline. Will sync when back online.`, 'info');
    //     this.requestInProgress = false;
    //     this.skipAlreadyCheckedToast = true;
    //     if (isCheckIn) {
    //         this.updateCheckInOutStatus(this.currentDateTime, null);
    //     } else {
    //         this.updateCheckInOutStatus(status.CheckINDateTime, this.currentDateTime);
    //     }
    //     return;
    // }
 
    if (!navigator.onLine) {
    const fallbackKey = `checkInStatus_fallback_${this.recordId}`;
    sessionStorage.setItem(fallbackKey, JSON.stringify(status));
    if (this.userName) {
        const userKey = `checkInStatus_${this.userName}_${this.recordId}`;
        sessionStorage.setItem(userKey, JSON.stringify(status));
    }
 
    this.showToast('Info', `${isCheckIn ? 'Check-in' : 'Check-out'} saved offline. Will sync when back online.`, 'info');
    this.requestInProgress = false;
    this.skipAlreadyCheckedToast = true;
 
    if (isCheckIn) {
        this.updateCheckInOutStatus(this.currentDateTime, null);
    } else {
        this.updateCheckInOutStatus(status.CheckINDateTime, this.currentDateTime);
    }
   
     setTimeout(() => {
            this.handleCancel();
        }, 1500);
 
    return;
 
   
}
 
     
 
        updateServiceAppoinment({
            recordId: this.serviceAppointmentId || this.recordId,
            lat: this.lat,
            lon: this.long,
            checkIn: isCheckIn,
            currentDateTime: this.currentDateTime
        })
            .then(result => {
                console.log('✅ Apex result:', result);
                this.showToast('Success', result, 'success');
                this.requestInProgress = false;
                this.skipAlreadyCheckedToast = true;
 
                if (isCheckIn) {
                    this.updateCheckInOutStatus(this.currentDateTime, null);
                } else {
                    const status = JSON.parse(sessionStorage.getItem(key)) || {};
                    this.updateCheckInOutStatus(status.CheckINDateTime, this.currentDateTime);
                }
 
                this.getOfflineCheckInStatus();
 
                 setTimeout(() => {
                this.handleCancel();
                }, 1500);
 
            })
            .catch(error => {
                this.requestInProgress = false;
                this.showToast('Error', 'Error during check-in/out: ' + JSON.stringify(error), 'error');
            });
    }
 
    // ---------------- LOCATION HANDLING ----------------
    handleGetLocation() {
        if (FORM_FACTOR === 'Large') this.getBrowserLocation();
        else this.getMobileLocation();
    }
 
    getBrowserLocation() {
        if (!navigator.geolocation) {
            this.showToast('Warning', 'Geolocation not supported by your browser', 'warning');
            return;
        }
        navigator.geolocation.getCurrentPosition(
            position => this.updateLocation(position.coords),
            () => this.showToast('Warning', 'Please enable your device location', 'warning'),
            { enableHighAccuracy: true }
        );
    }
 
    getMobileLocation() {
        const locationService = getLocationService();
        if (!locationService || !locationService.isAvailable()) {
            this.showToast('Error', 'Location service not available on this device', 'error');
            return;
        }
        locationService.getCurrentPosition({ enableHighAccuracy: true })
            .then(pos => this.updateLocation(pos.coords))
            .catch(() => this.showToast('Warning', 'Please enable your device location', 'warning'));
    }
 
    updateLocation(coords) {
        this.lat = coords.latitude;
        this.long = coords.longitude;
        this.lstMarkers = [
            { location: { Latitude: this.lat, Longitude: this.long }, title: 'Current Location' }
        ];
    }
 
    // ---------------- UTILITIES ----------------
    handleCancel() {
       // this.showModal = false;
        // if (FORM_FACTOR === 'Large') {
        //     const closeQA = new CustomEvent('close');
        //     this.dispatchEvent(closeQA);
        // } else {
             
        //    setTimeout(() => {
        //     history.back();
        // }, 500);
     
        // }
         setTimeout(() => {
            history.back();
        }, 1000);
    }
   
     showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
                mode: 'dismissable'
            })
        );
    }
    // showToast(title, message, variant) {
    //     this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    // }
 
    //  showToast(title, message, variant) {
    //     this.dispatchEvent(
    //         new ShowToastEvent({ title, message, variant })
    //     );
    // }
//     async showToast(title, message, variant) {
//     // If component is already closed, skip showing alerts
//     if (this.disconnected) {
//         console.warn('⚠️ Attempted to show alert after component destroyed:', title, message);
//         return;
//     }
 
//     if (FORM_FACTOR !== 'Small') {
//         // Desktop – standard toast
//         this.dispatchEvent(
//             new ShowToastEvent({
//                 title: title,
//                 message: message,
//                 variant: variant,
//                 mode: 'dismissable'
//             })
//         );
//     } else {
//         try {
//             // Mobile – async alert (safe check before open)
//             await LightningAlert.open({
//                 message: message,
//                 theme: variant,
//                 label: title
//             });
//         } catch (e) {
//             console.warn('⚠️ Alert failed or canceled', e);
//         }
//     }
// }
 
 
//     showToast(title, message, variant) {
//     try {
//         // Try standard Salesforce toast first
//         this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
 
//         // Log for debugging
//         console.log(`🔔 Toast [${variant}] — ${title}: ${message}`);
//     } catch (error) {
//         console.warn('⚠️ Standard toast failed — using mobile fallback', error);
//         this.showToastFallback(title, message, variant);
//     }
 
//     // 🟢 Also trigger fallback for Salesforce mobile or offline context
//     if (FORM_FACTOR !== 'Large') {
//         this.showToastFallback(title, message, variant);
//     }
// }
 
// showToastFallback(title, message, variant) {
//     // Dynamically inject a small toast overlay in mobile/offline mode
//     const toast = document.createElement('div');
//     toast.textContent = `${title}: ${message}`;
//     toast.className = `mobile-toast ${variant}`;
//     Object.assign(toast.style, {
//         position: 'fixed',
//         bottom: '20px',
//         left: '50%',
//         transform: 'translateX(-50%)',
//         background: variant === 'success' ? '#2e7d32' :
//                     variant === 'error' ? '#c62828' :
//                     variant === 'warning' ? '#f9a825' : '#0277bd',
//         color: '#fff',
//         padding: '12px 20px',
//         borderRadius: '8px',
//         fontSize: '14px',
//         boxShadow: '0 2px 6px rgba(0,0,0,0.3)',
//         zIndex: 9999,
//         textAlign: 'center',
//         opacity: '0',
//         transition: 'opacity 0.3s ease-in-out',
//         maxWidth: '90%',
//     });
//     document.body.appendChild(toast);
//     requestAnimationFrame(() => toast.style.opacity = '1');
//     setTimeout(() => {
//         toast.style.opacity = '0';
//         setTimeout(() => toast.remove(), 600);
//     }, 3000);
// }
 
 
    get showAlreadyCheckedInMessage() {
        return this.checkIn === false && this.checkOut === false;
    }
    get isOffline() {
        return !navigator.onLine;
    }
    get hasLocation() {
 
         if (this.checkIn === false && this.checkOut === false) {
        return false;
    }
        return this.lstMarkers && this.lstMarkers.length > 0;
    }
    get checkInDisabled() {
         // Allow offline actions
    // if (!navigator.onLine) return this.requestInProgress;
    //     return this.requestInProgress || this.submitDisabled;
 
    // Allow offline actions but still enforce TBT approval
    if (!navigator.onLine) {
        return this.requestInProgress || !this.tbtApproved;
    }
 
    // Online mode: disable if request is in progress, submit disabled, or TBT not approved
    return this.requestInProgress || this.submitDisabled || !this.tbtApproved;
 
 
    }
    get checkOutDisabled() {
        // Allow offline actions
    // if (!navigator.onLine) return this.requestInProgress;
    //     return this.requestInProgress || this.submitDisabled;
    // }
 
    // Allow offline Check-Outs only if document was approved before
    if (!navigator.onLine) {
        return this.requestInProgress || !this.siteDocumentApproved || !this.tbtApproved;
    }
    // Online mode
    return this.requestInProgress || this.submitDisabled || !this.siteDocumentApproved || !this.tbtApproved;
    }
}