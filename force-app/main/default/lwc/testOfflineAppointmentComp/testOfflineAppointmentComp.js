import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue, updateRecord, createRecord, refreshApex, generateRecordInputForCreate, generateRecordInputForUpdate } from 'lightning/uiRecordApi';
import WORKTYPE_NAME_FIELD from '@salesforce/schema/WorkOrder.WorkType.Name';
import WORK_ORDER_OBJECT from '@salesforce/schema/WorkOrder';
import SERVICE_APPOINTMENT_OBJECT from '@salesforce/schema/ServiceAppointment';
import ASSIGNED_RESOURCE_OBJECT from '@salesforce/schema/AssignedResource';
// Work Order Fields
const WORK_ORDER_FIELDS = [
    'WorkOrder.Id',
    'WorkOrder.Status',
    'WorkOrder.Appointment_Status__c',
    'WorkOrder.Follow_up_Date__c',
    'WorkOrder.Follow_up_Remarks__c',
    'WorkOrder.Other_Follow_Up_Remark__c',
    'WorkOrder.New_Remark__c',
    'WorkOrder.Check_In_Location__Latitude__s',
    'WorkOrder.Check_In_Location__Longitude__s',
    'WorkOrder.Check_In_Date_Time__c',
    'WorkOrder.Check_Out_Date_Time__c',
    'WorkOrder.Check_Out_Location__Latitude__s',
    'WorkOrder.Check_Out_Location__Longitude__s',
    'WorkOrder.ServiceAppointmentCount__c',
    'WorkOrder.ServiceTerritoryId',
    'WorkOrder.WorkTypeId',
    'WorkOrder.Due_Amount__c',
    'WorkOrder.ContactId',
    'WorkOrder.AccountId',
    'WorkOrder.Subject',
    'WorkOrder.Description',
    'WorkOrder.ParentWorkOrderId',
    'WorkOrder.Invoice__c',
    'WorkOrder.RecordTypeId',
    'WorkOrder.Agent__c',
    'WorkOrder.R_T_Agency__c',
    'WorkOrder.WorkOrderNumber',
    'WorkOrder.Amount_Received__c',
    'WorkOrder.Payment_Mode__c',
    'WorkOrder.TodayDate__c',
    'WorkOrder.NOTDUE__c',
    'WorkOrder.B4DUE__c',
    'WorkOrder.X0_30__c',
    'WorkOrder.X31_60__c',
    'WorkOrder.X61_90__c',
    'WorkOrder.X91_180__c',
    'WorkOrder.X181_365__c',
    'WorkOrder.X1_2YR__c',
    'WorkOrder.X2_3YR__c',
    'WorkOrder.GR3YR__c'
];

// Service Appointment Fields
const SERVICE_APPOINTMENT_FIELDS = [
    'ServiceAppointment.Id',
    'ServiceAppointment.ParentRecordId',
    'ServiceAppointment.SchedStartTime',
    'ServiceAppointment.SchedEndTime',
    'ServiceAppointment.Subject',
    'ServiceAppointment.Description',
    'ServiceAppointment.Meter_Number__c',
    'ServiceAppointment.Customer_Address__c',
    'ServiceAppointment.Status',
    'ServiceAppointment.Appointment_Type__c',
    'ServiceAppointment.ContactId',
    'ServiceAppointment.Address',
    'ServiceAppointment.ServiceTerritoryId',
    'ServiceAppointment.WorkTypeId',
    'ServiceAppointment.Check_In_Location__latitude__s',
    'ServiceAppointment.Check_In_Location__longitude__s',
    'ServiceAppointment.Check_Out_Location__latitude__s',
    'ServiceAppointment.Check_Out_Location__longitude__s',
    'ServiceAppointment.Check_Out_Timestamp__c',
    'ServiceAppointment.FollowUpRemarks__c',
    'ServiceAppointment.Other_Follow_Up_Remark__c',
    'ServiceAppointment.Follow_Up_Visit_Date__c',
    'ServiceAppointment.Due_Amount__c'
];

export default class FollowUpAppointment extends NavigationMixin(LightningElement) {
    @api recordId;
    followUpDate;
    followUpRemarks;
    @track isLoading = false;
    followUpOption = []; 
    showOtherRemark = false;
    otherFollowUpRemarks;
    @track photoUploadSlots = [];
    @track noOfPhotos;
    doorLocked = false;
    isGoCollect = false;
    isFollowUpRequired = false;
    @track isOnline = true;

    followUpScreen = true;
    openMainPage = false;
    openDomesticHome = false;

    imageOptional = false;
    @track followUpMetadata = [];
    @track reasonOptions = [];
    @track showEnableMessage = false;
    @track message = '';
    fileDate = [];
    @track currentWorkOrderData = null;
    @track currentServiceAppointments = [];

    // Wire services
    @wire(getRecord, { recordId: '$recordId', fields: WORK_ORDER_FIELDS })
    wiredWorkOrder({ error, data }) {
        if (data) {
            this.currentWorkOrderData = data;
            this.storeOfflineWorkOrderData(data);
            this.processWorkOrderDetailsFromLDS();
        } else if (error) {
            console.error('Error loading work order:', error);
            this.loadOfflineWorkOrderDetails();
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: [WORKTYPE_NAME_FIELD] })
    wiredWorkOrderType({ error, data }) {
        if (data) {
            const workOrderType = getFieldValue(data, WORKTYPE_NAME_FIELD);
            // Your GoCollect logic here
        } else if (error) {
            console.error('Error fetching Work Order type:', error);
        }
    }

    connectedCallback() {
        this.checkOnlineStatus();
        this.isLoading = true;

        // Set up network listeners
        window.addEventListener('online', () => this.handleOnlineStatusChange(true));
        window.addEventListener('offline', () => this.handleOnlineStatusChange(false));

        if (this.isOnline) {
            this.handleOnlineInitialization();
        } else {
            this.handleOfflineInitialization();
        }
    }

    // ========== ONLINE/OFFLINE HANDLING ==========
    checkOnlineStatus() {
        this.isOnline = navigator.onLine;
    }

    handleOnlineStatusChange(online) {
        this.isOnline = online;
        if (online) {
            this.checkAndSyncOfflineData();
        } else {
            this.showToast('Info', 'You are now offline. Working in offline mode.', 'info');
        }
    }

    async handleOnlineInitialization() {
        try {
            // Load picklist values
            await this.loadPicklistValues();
            
            // Load work order details
            await this.loadWorkOrderDetails();
            
            // Load service appointments
            await this.loadServiceAppointments();

        } catch (error) {
            console.error('Online initialization failed:', error);
            await this.handleOfflineInitialization();
        } finally {
            this.isLoading = false;
        }
    }

    async handleOfflineInitialization() {
        try {
            await this.loadOfflinePicklistValues();
            await this.loadOfflineWorkOrderDetails();
            await this.loadOfflineServiceAppointments();
            await this.checkOfflinePendingData();
        } catch (error) {
            console.error('Offline initialization failed:', error);
            this.showToast('Warning', 'Working in offline mode with limited data.', 'warning');
        } finally {
            this.isLoading = false;
        }
    }

    // ========== DATA LOADING METHODS ==========
    async loadPicklistValues() {
        try {
            // For offline, we'll use default values
            this.followUpOption = [
                { label: 'Customer Not Available', value: 'Customer Not Available' },
                { label: 'Door Locked', value: 'Door Locked' },
                { label: 'Security Issues', value: 'Security Issues' },
                { label: 'Other', value: 'Other' }
            ];
            this.storeOfflinePicklistValues(this.followUpOption);
        } catch (error) {
            console.error('Error loading picklist values:', error);
        }
    }

    async loadWorkOrderDetails() {
        try {
            if (this.currentWorkOrderData) {
                this.processWorkOrderDetailsFromLDS();
            }
        } catch (error) {
            console.error('Error loading work order details:', error);
        }
    }

    async loadServiceAppointments() {
        // In offline mode, we'll work with the data we have from LDS
        // For full implementation, you might want to cache related SAs
    }

    // ========== OFFLINE STORAGE METHODS ==========
    storeOfflinePicklistValues(picklistValues) {
        try {
            localStorage.setItem('offlineFollowUpPicklists', JSON.stringify(picklistValues));
        } catch (error) {
            console.error('Error storing offline picklist values:', error);
        }
    }

    async loadOfflinePicklistValues() {
        try {
            const storedPicklists = localStorage.getItem('offlineFollowUpPicklists');
            if (storedPicklists) {
                this.followUpOption = JSON.parse(storedPicklists);
            } else {
                this.followUpOption = [
                    { label: 'Customer Not Available', value: 'Customer Not Available' },
                    { label: 'Door Locked', value: 'Door Locked' },
                    { label: 'Security Issues', value: 'Security Issues' },
                    { label: 'Other', value: 'Other' }
                ];
            }
        } catch (error) {
            console.error('Error loading offline picklist values:', error);
            this.followUpOption = [];
        }
    }

    storeOfflineWorkOrderData(workOrderData) {
        try {
            const storedWorkOrders = localStorage.getItem('offlineWorkOrders') || '{}';
            const workOrders = JSON.parse(storedWorkOrders);
            workOrders[this.recordId] = {
                ...workOrderData,
                lastSynced: new Date().toISOString()
            };
            localStorage.setItem('offlineWorkOrders', JSON.stringify(workOrders));
        } catch (error) {
            console.error('Error storing offline work order data:', error);
        }
    }

    async loadOfflineWorkOrderDetails() {
        try {
            const storedWorkOrders = localStorage.getItem('offlineWorkOrders');
            if (storedWorkOrders) {
                const workOrders = JSON.parse(storedWorkOrders);
                const workOrderData = workOrders[this.recordId];
                if (workOrderData) {
                    this.processWorkOrderDetails(workOrderData);
                }
            }
        } catch (error) {
            console.error('Error loading offline work order details:', error);
        }
    }

    async loadOfflineServiceAppointments() {
        // Load any cached service appointments
        try {
            const storedSAs = localStorage.getItem(`offlineServiceAppointments_${this.recordId}`);
            if (storedSAs) {
                this.currentServiceAppointments = JSON.parse(storedSAs);
            }
        } catch (error) {
            console.error('Error loading offline service appointments:', error);
        }
    }

    // ========== MAIN SAVE METHOD ==========
    async handleSave() {  
        console.log('Inside save - Online:', this.isOnline);

        if (!this.followUpRemarks) {
            this.showToast('Error', 'Please enter the remarks.', 'error');
            return;
        }

        if(this.isFollowUpRequired && !this.followUpDate){
            this.showToast('Error', 'Please enter follow-up date.', 'error');
            return;
        }

        this.isLoading = true;

        try {
            if (this.isOnline) {
                await this.handleOnlineSave();
            } else {
                await this.handleOfflineSave();
            }
        } catch (error) {
            console.error('Save operation failed:', error);
            this.showToast('Error', 'Failed to save: ' + error.message, 'error');
            this.isLoading = false;
        }
    }

    async handleOnlineSave() {
        // Use your existing Apex logic for online
        if (this.doorLocked) {
            const base64ImagesToSend = this.photoUploadSlots.map(slot => slot.base64Data);
            const selectedMetadata = this.followUpMetadata.find(item => item.Label === this.followUpRemarks);
            const smsRequired = selectedMetadata?.SMS_requried__c || false;

            // Call your existing Apex method
            const result = await this.callApexMethod('createFollowUpWithImages', {
                parentRecordId: this.recordId,
                followUpDate: this.followUpDate,
                followUpRemarks: this.followUpRemarks,
                otherRemark: this.otherFollowUpRemarks,
                smsRequired: smsRequired,
                base64Images: base64ImagesToSend
            });

            this.handleSaveResponse(result);
        } else {
            // Call your existing Apex method
            const result = await this.callApexMethod('createFollowUp', {
                ParentRecordId: this.recordId,
                followUpDate: this.followUpDate,
                followUpRemarks: this.followUpRemarks,
                otherRemarks: this.otherFollowUpRemarks
            });

            this.handleSaveResponse(result);
        }
    }

    async handleOfflineSave() {
        try {
            if (this.followUpDate != null) {
                await this.handleOfflineFollowUp();
            } else {
                await this.handleOfflineCompletion();
            }

            // Store offline operation for sync
            this.storeOfflineOperation({
                type: this.followUpDate != null ? 'followUp' : 'completion',
                followUpDate: this.followUpDate,
                followUpRemarks: this.followUpRemarks,
                otherRemarks: this.otherFollowUpRemarks,
                hasImages: this.doorLocked,
                images: this.doorLocked ? this.photoUploadSlots.map(slot => slot.base64Data) : []
            });

            this.showToast('Success', 'Changes saved locally. Will sync when online.', 'success');
            this.handleNavigation();

        } catch (error) {
            console.error('Offline save failed:', error);
            throw error;
        } finally {
            this.isLoading = false;
        }
    }

    async handleOfflineFollowUp() {
        // Update current Work Order
        const workOrderFields = {
            Id: this.recordId,
            Status: 'Follow Up',
            Appointment_Status__c: 'Follow Up',
            Follow_up_Date__c: this.followUpDate,
            New_Remark__c: this.followUpRemarks,
            Check_In_Location__Latitude__s: null,
            Check_In_Location__Longitude__s: null,
            Check_In_Date_Time__c: null
        };

        // Increment count
        const currentCount = getFieldValue(this.currentWorkOrderData, 'WorkOrder.ServiceAppointmentCount__c') || 0;
        workOrderFields.ServiceAppointmentCount__c = currentCount + 1;

        await updateRecord({ fields: workOrderFields });

        // Create new Service Appointment (simulated offline)
        const newSAId = this.generateOfflineId();
        this.storeOfflineServiceAppointment(newSAId, {
            ParentRecordId: this.recordId,
            Status: 'In Progress',
            Appointment_Type__c: 'Follow Up',
            FollowUpRemarks__c: null,
            Other_Follow_Up_Remark__c: null,
            Follow_Up_Visit_Date__c: null,
            Due_Amount__c: getFieldValue(this.currentWorkOrderData, 'WorkOrder.Due_Amount__c')
        });

        // Handle images offline
        if (this.doorLocked && this.photoUploadSlots.length > 0) {
            await this.handleOfflineImageUpload();
        }
    }

    async handleOfflineCompletion() {
        const workOrderFields = {
            Id: this.recordId,
            Status: 'Completed',
            Appointment_Status__c: 'Completed',
            Check_Out_Date_Time__c: new Date().toISOString(),
            Follow_up_Remarks__c: this.followUpRemarks,
            Other_Follow_Up_Remark__c: this.otherFollowUpRemarks,
            New_Remark__c: this.followUpRemarks,
            Check_Out_Location__Latitude__s: getFieldValue(this.currentWorkOrderData, 'WorkOrder.Check_In_Location__Latitude__s'),
            Check_Out_Location__Longitude__s: getFieldValue(this.currentWorkOrderData, 'WorkOrder.Check_In_Location__Longitude__s')
        };

        await updateRecord({ fields: workOrderFields });
    }

    // ========== IMAGE HANDLING ==========
    async handleOfflineImageUpload() {
        const offlineImages = this.getOfflineImages();
        
        for (let i = 0; i < this.photoUploadSlots.length; i++) {
            const slot = this.photoUploadSlots[i];
            if (slot.base64Data) {
                const imageData = {
                    id: this.generateUniqueId(),
                    workOrderId: this.recordId,
                    fileName: slot.fileName || `FollowUp_Image_${i + 1}`,
                    base64Data: this.extractBase64Data(slot.base64Data),
                    uploadDate: new Date().toISOString(),
                    status: 'pending'
                };
                
                offlineImages.push(imageData);
            }
        }
        
        this.setOfflineImages(offlineImages);
    }

    // ========== SYNC METHODS ==========
    async checkAndSyncOfflineData() {
        if (!this.isOnline) return;

        try {
            const offlineData = this.getOfflineData();
            const pendingOperations = offlineData.filter(op => op.status === 'pending');

            if (pendingOperations.length > 0) {
                this.showToast('Info', 'Syncing offline data...', 'info');
                
                for (const operation of pendingOperations) {
                    await this.syncSingleOperation(operation);
                }
                
                this.showToast('Success', 'Offline data synced successfully', 'success');
            }
        } catch (error) {
            console.error('Sync failed:', error);
            this.showToast('Error', 'Failed to sync offline data: ' + error.message, 'error');
        }
    }

    async syncSingleOperation(operation) {
        try {
            if (operation.data.hasImages) {
                // Call Apex method with images
                const result = await this.callApexMethod('createFollowUpWithImages', {
                    parentRecordId: this.recordId,
                    followUpDate: operation.data.followUpDate,
                    followUpRemarks: operation.data.followUpRemarks,
                    otherRemark: operation.data.otherRemarks,
                    smsRequired: false, // You might want to store this in offline data
                    base64Images: operation.data.images
                });

                if (result.success) {
                    operation.status = 'synced';
                }
            } else {
                // Call Apex method without images
                const result = await this.callApexMethod('createFollowUp', {
                    ParentRecordId: this.recordId,
                    followUpDate: operation.data.followUpDate,
                    followUpRemarks: operation.data.followUpRemarks,
                    otherRemarks: operation.data.otherRemarks
                });

                if (result.success) {
                    operation.status = 'synced';
                }
            }

            this.updateOfflineData();
        } catch (error) {
            console.error('Failed to sync operation:', error);
        }
    }

    // ========== UTILITY METHODS ==========
    handleSaveResponse(result) {
        if (result.success) {
            this.showToast('Success', result.message, 'success');
            if (result.message === 'Work Order updated.') {
                if (!this.isGoCollect) {
                    this.followUpScreen = false;
                } else {
                    history.back();
                }
            } else {
                this.navigateToWorkOrderInFSL(this.recordId);
            }
        } else {
            this.showToast('Error', result.message, 'error');
        }
        this.isLoading = false;
    }

    storeOfflineOperation(data) {
        const offlineData = this.getOfflineData();
        offlineData.push({
            id: this.generateUniqueId(),
            data: data,
            timestamp: new Date().toISOString(),
            status: 'pending'
        });
        localStorage.setItem(`offlineData_${this.recordId}`, JSON.stringify(offlineData));
    }

    getOfflineData() {
        try {
            const stored = localStorage.getItem(`offlineData_${this.recordId}`);
            return stored ? JSON.parse(stored) : [];
        } catch (error) {
            return [];
        }
    }

    updateOfflineData() {
        const offlineData = this.getOfflineData();
        localStorage.setItem(`offlineData_${this.recordId}`, JSON.stringify(offlineData));
    }

    getOfflineImages() {
        try {
            const stored = localStorage.getItem(`offlineImages_${this.recordId}`);
            return stored ? JSON.parse(stored) : [];
        } catch (error) {
            return [];
        }
    }

    setOfflineImages(images) {
        localStorage.setItem(`offlineImages_${this.recordId}`, JSON.stringify(images));
    }

    storeOfflineServiceAppointment(saId, saData) {
        const storedSAs = localStorage.getItem(`offlineServiceAppointments_${this.recordId}`) || '[]';
        const serviceAppointments = JSON.parse(storedSAs);
        serviceAppointments.push({ id: saId, ...saData });
        localStorage.setItem(`offlineServiceAppointments_${this.recordId}`, JSON.stringify(serviceAppointments));
    }

    extractBase64Data(base64String) {
        return base64String.includes(',') ? base64String.split(',')[1] : base64String;
    }

    generateUniqueId() {
        return `offline_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    }

    generateOfflineId() {
        return 'OFFLINE_' + this.generateUniqueId();
    }

    async checkOfflinePendingData() {
        const offlineData = this.getOfflineData();
        const pendingData = offlineData.filter(item => item.status === 'pending');
        
        if (pendingData.length > 0) {
            this.showToast('Info', `You have ${pendingData.length} pending offline changes.`, 'info');
        }
    }

    // ========== APEX METHOD CALL WRAPPER ==========
    async callApexMethod(methodName, params) {
        // This would be your actual Apex method call
        // For now, returning a mock response
        return new Promise((resolve) => {
            setTimeout(() => {
                resolve({
                    success: true,
                    message: 'Operation completed successfully'
                });
            }, 1000);
        });
    }

    // ========== EXISTING UI METHODS (keep as is) ==========
    processWorkOrderDetailsFromLDS() {
        if (!this.currentWorkOrderData) return;

        const isCheckInDateAvailable = getFieldValue(this.currentWorkOrderData, 'WorkOrder.Check_In_Date_Time__c') != null;
        const isWorkOrderCompleted = getFieldValue(this.currentWorkOrderData, 'WorkOrder.Status') == 'Completed';
        const isCheckOutDateAvailable = getFieldValue(this.currentWorkOrderData, 'WorkOrder.Check_Out_Date_Time__c') != null;
        const isFollowUp = getFieldValue(this.currentWorkOrderData, 'WorkOrder.Follow_up_Date__c') != null;
        
        if(isCheckInDateAvailable && isWorkOrderCompleted && isCheckOutDateAvailable){
            this.showEnableMessage = true;
            this.message = 'Task is already completed. Please refresh the WorkOrder page to continue.';
        }else if((!isCheckInDateAvailable && !isFollowUp)){
            this.showEnableMessage = true;
            this.message = 'Check-In is required. Please Check-In and refresh the WorkOrder page to continue.';
        }else if(isFollowUp){
            this.showEnableMessage = false;
            this.showToast('Warning','This is already a Follow-Up task. If you still want to create another follow-up then continue else go back to Home screen.','warning');
            if((!isCheckInDateAvailable && isFollowUp)){
                this.showEnableMessage = true;
                this.message = 'Check-In is required. Please Check-In and refresh the WorkOrder page to continue.';
            }else{
                this.showEnableMessage = false;
            }
        }
    }

    handleDateChange(event) {
        this.followUpDate = event.detail.value;
    }

    handleRemarksChange(event) {
        this.followUpRemarks = event.detail.value;
        this.showOtherRemark = (this.followUpRemarks.toLowerCase() === 'other');
        
        // Your existing metadata logic here
        this.doorLocked = (this.followUpRemarks === 'Door Locked');
        this.isFollowUpRequired = (this.followUpRemarks !== 'Other');
        
        if (this.doorLocked) {
            this.noOfPhotos = 3; // Default for door locked
            this.setPhotoUploadSlots();
        } else {
            this.doorLocked = false;
            this.noOfPhotos = 0;
            this.photoUploadSlots = [];
        }
    }

    handleOtherRemarksChange(event) {
        this.otherFollowUpRemarks = event.detail.value;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    navigateToWorkOrderInFSL(workOrderId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: `com.salesforce.fieldservice://v1/sObject/${workOrderId}/overview`
            }
        });
    }

    handleNavigation() {
        if (!this.isGoCollect) {
            this.followUpScreen = false;
        } else {
            history.back();
        }
    }

    setPhotoUploadSlots() {
        const count = this.noOfPhotos || 0;
        this.photoUploadSlots = Array.from({ length: count }, (_, index) => ({
            id: index + 1,
            index: index + 1,
            label: `Photo ${index + 1}`,
            fileName: '',
            uploaded: false,
            previewUrl: '',
            base64Data: ''
        }));
    }

    handleFile(event) {
        this.photoUploadSlots = event.detail.steps;
    }

    handleCancel() {
        history.back();
    }

    handleChildEvent(event) {
        this.openMainPage = true;
    }

    processWorkOrderDetails(workOrderData) {
        // Process work order details for offline mode
        // Similar to processWorkOrderDetailsFromLDS but using the provided data
    }
}