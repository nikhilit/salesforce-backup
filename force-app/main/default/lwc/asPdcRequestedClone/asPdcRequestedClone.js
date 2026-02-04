import { LightningElement, api, track, wire } from 'lwc';

import { createRecord, updateRecord, getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi'; 
import { gql, graphql } from 'lightning/uiGraphQLApi';

import PAYMENT_OBJECT from '@salesforce/schema/Payment__c';
import CONTENT_VERSION_OBJECT from '@salesforce/schema/ContentVersion';
import SERVICE_APPOINTMENT_OBJECT from '@salesforce/schema/ServiceAppointment';
import WORK_ORDER_OBJECT from '@salesforce/schema/WorkOrder'; 
import WORK_STEP_OBJECT from '@salesforce/schema/WorkStep';
// --------------------------------------------------

import saveChequeDetails from '@salesforce/apex/AsPdcRequestedController.saveChequeDetails';
import getBankDetailsByMicr from '@salesforce/apex/RTVisitExecutionController.getBankDetailsByMicr';
import updateGeoLocation from '@salesforce/apex/RTVisitExecutionController.updateGeoLocation';
import sendSMS from '@salesforce/apex/AsPdcRequestedController.sendSms';

import { ShowToastEvent } from 'lightning/platformShowToastEvent'; 
import { getLocationService } from 'lightning/mobileCapabilities';
import FORM_FACTOR from '@salesforce/client/formFactor'; 
import asReceiptLabel from "@salesforce/label/c.AS_ReceiptLabel";

import userId from '@salesforce/user/Id';
import userNameField from '@salesforce/schema/User.Name';
import DUE_AMOUNT_FIELD from "@salesforce/schema/WorkOrder.Due_Amount__c";
import PAID_AMOUNT_FIELD from "@salesforce/schema/WorkOrder.Amount_Received__c";
import PAY_MODE_FIELD from "@salesforce/schema/WorkOrder.Payment_Mode__c";
import TXN_Id_FIELD from "@salesforce/schema/WorkOrder.Transaction_Id__c";
import ACCOUNT_ID_FIELD from "@salesforce/schema/WorkOrder.AccountId"; 
import CHECK_IN_LAT_FIELD from "@salesforce/schema/WorkOrder.Check_In_Location__c";
import CHECK_IN_LONG_FIELD from "@salesforce/schema/WorkOrder.Check_In_Location__c";

export default class AsPdcRequested extends LightningElement { 

    @api payType = '';
    @api isFieldSense;

    @api recordId;
    // Cheque fields
    @track bankName = '';
    @track branchName = '';
    @track chequeNumber = '';
    @track chequeDate = '';
    @track caNumber = '';
    @track chequeAmount = '';
    @track showChequeForm = false;
    @track photoUploadSlots = [];
    noOfPhotos;
    @track numberOfCheques = '';
    @track chequeList = [];
    @track micrCode;
    @track Ifsc;
    @track load = false;

    // --- NEW VARIABLES FOR OFFLINE ---
    @track micrSearchTerm = '';
    @track activeMicrIndex = -1;
    relatedServiceAppointmentId = null;
    relatedWorkStepIds = []; 
    
    woAccountId; 
    woCheckInLat;
    woCheckInLong;
    // ---------------------------------
    // ---------------------------------

    showPaidMessage = false;
    pdfReceiptUrl = '';
    dueAmount;
    paidAmt;
    paymentMode;
    txnId;
    currentUserName
    textToAddTop = '';
    lat = '';
    long = '';

    payTypeSelectedValue = ''; 
    payRemark = '';
    
    accountAlternatePhone = ''; 

    payTypeOptions = [
        { label: 'Full Payment', value: 'Full Payment' },
        { label: 'Partial Payment', value: 'Partial Payment' }
    ];

    handlePayTypeChange(event) {
        this.payTypeSelectedValue = event.detail.value;
    }

    handlePayRemark(event){
        this.payRemark = event.detail.value;
    }

    label = { asReceiptLabel };

    // --- EXISTING WIRE ---
    @wire(getRecord, {
        recordId: '$recordId',
        fields: [
                DUE_AMOUNT_FIELD, PAID_AMOUNT_FIELD, PAY_MODE_FIELD, TXN_Id_FIELD,
                ACCOUNT_ID_FIELD, CHECK_IN_LAT_FIELD, CHECK_IN_LONG_FIELD // Patch: Fetch extra fields
            ]
    })
    workOrderData({ error, data }) {
        if (data) {
            this.dueAmount = getFieldValue(data, DUE_AMOUNT_FIELD);
            this.paidAmt = getFieldValue(data, PAID_AMOUNT_FIELD);
            this.paymentMode = getFieldValue(data, PAY_MODE_FIELD);
            this.txnId = getFieldValue(data, TXN_Id_FIELD);

            this.woAccountId = getFieldValue(data, ACCOUNT_ID_FIELD);
            this.woCheckInLat = getFieldValue(data, CHECK_IN_LAT_FIELD);
            this.woCheckInLong = getFieldValue(data, CHECK_IN_LONG_FIELD);
            this.showPaymentMessage();
        } else if (error) {
            this.error = error;
        }
    }

    showPaymentMessage(){
        if(this.paidAmt && this.paymentMode === 'Cheque' && !this.txnId){
            this.pdfReceiptUrl = this.label.asReceiptLabel + this.recordId + '&mode=' + this.paymentMode;
            this.showPaidMessage = true;
        }
    }

    @wire(getRecord, { recordId: userId, fields: [userNameField] })
    wiredUser({ error, data }) {
        if (data) {
            this.currentUserName = data.fields.Name.value;
            this.textToAddTop = `${this.currentUserName}\n${this.formatDateTime(new Date())}`;
        } else if (error) {
            this.error = error;
        }
    }


    @wire(getObjectInfo, { objectApiName: PAYMENT_OBJECT })
    paymentObjectInfo;

    @wire(getObjectInfo, { objectApiName: CONTENT_VERSION_OBJECT })
    cvObjectInfo;

    @wire(getObjectInfo, { objectApiName: SERVICE_APPOINTMENT_OBJECT })
    saObjectInfo;

    @wire(getObjectInfo, { objectApiName: WORK_ORDER_OBJECT })
    woObjectInfo;

    @wire(getObjectInfo, { objectApiName: WORK_STEP_OBJECT })
    wsObjectInfo;
    // --------------------------------------------------------


    @wire(graphql, {
        query: gql`
            query getRelatedRecords($parentId: ID) {
                uiapi {
                    query {
                        ServiceAppointment(where: { ParentRecordId: { eq: $parentId } }, first: 1, orderBy: { CreatedDate: { order: DESC } }) {
                            edges {
                                node {
                                    Id
                                    Status {value}
                                }
                            }
                        }
                        WorkStep(where: { 
                            and: [
                                { ParentRecordId: { eq: $parentId } },
                                { or: [{ Name: { eq: "Collect Payment" } }, { Name: { eq: "Check Out" } }] }
                            ]
                        }) {
                            edges {
                                node {
                                    Id
                                    Name { value }
                                }
                            }
                        }
                    }
                }
            }`,
        variables: '$relatedGraphQLVariables'
    })
    wiredRelatedRecords({ data, errors }) {
        if (data) {
            // Get SA ID
            if (data.uiapi.query.ServiceAppointment.edges.length > 0) {
                this.relatedServiceAppointmentId = data.uiapi.query.ServiceAppointment.edges[0].node.Id;
            }
            // Get WorkStep IDs
            this.relatedWorkStepIds = data.uiapi.query.WorkStep.edges.map(edge => edge.node.Id);
        }
    }

    get relatedGraphQLVariables() {
        return { parentId: this.recordId };
    }

    // --- 3. NEW: GRAPHQL WIRE FOR BANK DETAILS (Offline Compatible) ---
    @wire(graphql, {
        query: gql`
            query getBankDetails($micr: String) {
                uiapi {
                    query {
                        Bank_Detail__c(where: { Name: { eq: $micr } }, first: 1) {
                            edges {
                                node {
                                    BANK__c { value }
                                    BRANCH__c { value }
                                    IFSC__c { value }
                                }
                            }
                        }
                    }
                }
            }`,
        variables: '$bankGraphQLVariables'
    })
    wiredBankDetails({ data, errors }) {
        if (data) {
            const edges = data.uiapi.query.Bank_Detail__c.edges;
            if (edges.length > 0 && this.activeMicrIndex >= 0) {
                const node = edges[0].node;
                this.updateChequeListWithBankDetails(this.activeMicrIndex, {
                    bank: node.BANK__c.value,
                    branch: node.BRANCH__c.value,
                    ifsc: node.IFSC__c.value,
                    found: true
                });
            } else if (this.activeMicrIndex >= 0) {
                this.updateChequeListWithBankDetails(this.activeMicrIndex, { found: false });
            }
        }
    }

    get bankGraphQLVariables() {
        return { micr: this.micrSearchTerm };
    }

    updateChequeListWithBankDetails(index, data) {
        if (!this.chequeList[index]) return;
        
        if (data.found) {
            this.chequeList[index].bankName = data.bank;
            this.chequeList[index].branchName = data.branch;
            this.chequeList[index].Ifsc = data.ifsc;
            this.chequeList[index].micrFound = true;
        } else {
            this.chequeList[index].bankName = '';
            this.chequeList[index].branchName = '';
            this.chequeList[index].Ifsc = '';
            this.chequeList[index].micrFound = false;
        }
        this.chequeList = [...this.chequeList]; // Force re-render
    }

    connectedCallback() {
        if (FORM_FACTOR !== 'Large' && this.isFieldSense) {
            this.load = true;
            this.getMobileLocation('Check In'); 
        }
        this.chequeList = [this.createEmptyCheque(1)];        
    }


    formatDateTime(date) {
        const day = String(date.getDate()).padStart(2, '0');
        const monthNames = [
            'January', 'February', 'March', 'April', 'May', 'June',
            'July', 'August', 'September', 'October', 'November', 'December'
        ];
        const month = monthNames[date.getMonth()];

        const year = date.getFullYear();

        let hours = date.getHours();
        const minutes = String(date.getMinutes()).padStart(2, '0');
        const ampm = hours >= 12 ? 'PM' : 'AM';

        hours = hours % 12;
        hours = hours ? hours : 12;
        const formattedHours = String(hours).padStart(2, '0');

        return `${day} ${month} ${year} ${formattedHours}:${minutes} ${ampm}`;
    }

    handleMicrChange(event) {
        const index = event.target.dataset.index;
        const value = event.target.value;

        this.chequeList[index].micrCode = value;

        if (value && value.length >= 8) {
            if (navigator.onLine) {
                getBankDetailsByMicr({ micrCode: value })
                    .then(result => {
                        this.updateChequeListWithBankDetails(index, {
                            bank: result.BANK__c,
                            branch: result.BRANCH__c,
                            ifsc: result.IFSC__c,
                            found: true
                        });
                    })
                    .catch(error => {
                        console.error('Apex Bank Fetch Failed', error);
                        // Fallback to GraphQL/LDS if online check fails or returns nothing
                        this.activeMicrIndex = index;
                        this.micrSearchTerm = value;
                    });
            } else {
                // Offline: Trigger GraphQL wire
                this.activeMicrIndex = index;
                this.micrSearchTerm = value;
            }
        } else {
            this.updateChequeListWithBankDetails(index, { found: false });
        }
    }


    createEmptyCheque(index) {
        return {
            id: Date.now() + index,
            displayIndex: index,
            micrCode: '',
            bankName: '',
            branchName: '',
            chequeNumber: '',
            chequeDate: '',
            chequeAmount: '',
            Ifsc: '', // Added initialization
            micrFound: false, // Added initialization
            photoUploadSlots: this.createEmptySlot()
        };
    }


    createEmptySlot() {
        return [
            {
                id: 1,
                label: 'Cheque Photo',
                fileName: '',
                uploaded: false,
                previewUrl: '',
                base64Data: '',
                added: false
            }
        ];
    }

    addAnotherCheque() {
        const newIndex = this.chequeList.length + 1;
        this.chequeList = [...this.chequeList, this.createEmptyCheque(newIndex)];
    }

    handleRemoveCheque(event) {
        const idToRemove = event.currentTarget.dataset.id;
        this.chequeList = this.chequeList.filter(cheque => cheque.id != idToRemove);

        this.chequeList = this.chequeList.map((chq, idx) => ({
            ...chq,
            displayIndex: idx + 1
        }));
    }

    get chequeCountOptions() {
        return Array.from({ length: 10 }, (_, i) => ({ label: `${i + 1}`, value: `${i + 1}` }));
    }

    handleChequeCountChange(event) {
        this.numberOfCheques = event.detail.value;
        this.chequeList = [];
        for (let i = 0; i < this.numberOfCheques; i++) {
            this.chequeList.push({
                id: i + 1,
                displayIndex: i + 1,
                micrCode: '',
                bankName: '',
                branchName: '',
                chequeNumber: '',
                chequeDate: '',
                chequeAmount: '',
                photoUploadSlots: this.createEmptySlot()
            });
        }
    }

    handleDynamicInput(event) {
        const index = event.target.dataset.index;
        const field = event.target.dataset.id;
        this.chequeList[index][field] = event.target.value;
    }

    async handleAllChequeSubmit() {

        try {
            let payloadList = [];
            var totalAmt = 0;
            for (let cheque of this.chequeList) {
                const imageSlot = cheque.photoUploadSlots?.find(s => s.uploaded);
                var isValid = this.isFieldSense ? (!cheque.chequeNumber || !cheque.chequeDate ||
                    !cheque.chequeAmount || !imageSlot?.base64Data || !cheque.bankName ||
                    !cheque.branchName) : (!cheque.micrCode || !cheque.chequeNumber || !cheque.chequeDate ||
                    !cheque.chequeAmount || !imageSlot?.base64Data || !cheque.bankName ||
                    !cheque.branchName);

                if (isValid) {
                    
                    let missingFields = [];
                    if (!cheque.micrCode && !this.isFieldSense) missingFields.push('MICR Code');
                    if (!cheque.chequeNumber) missingFields.push('Cheque Number');
                    if (!cheque.chequeDate) missingFields.push('Cheque Date');
                    if (!cheque.chequeAmount) missingFields.push('Cheque Amount');
                    if (!imageSlot?.base64Data) missingFields.push('Cheque Image');

                    if (!cheque.bankName) missingFields.push('Bank Name');
                    if (!cheque.branchName) missingFields.push('Branch Name');

                    throw new Error(`Cheque ${cheque.displayIndex}: Missing ${missingFields.join(', ')}`);
                }

                const amount = parseFloat(
                    String(cheque.chequeAmount).replace(/,/g, '') 
                );
                if (!isNaN(amount)) {
                    totalAmt += amount;
                }

                payloadList.push({
                    micrCode: cheque.micrCode,
                    bankName: cheque.bankName,
                    branchName: cheque.branchName,
                    chequeNumber: cheque.chequeNumber,
                    chequeDate: cheque.chequeDate,
                    chequeAmount: cheque.chequeAmount,
                    ifscCode: cheque.Ifsc,
                    recordId: this.recordId,
                    paymentMode: 'Post-Dated Cheque',
                    workStepName: 'Payment Capture',
                    base64Image: imageSlot.base64Data,
                    micrFound: cheque.micrFound
                });
            }

            // if(totalAmt > this.dueAmount){
            //     this.showToast('Error', 'Total cheque amount should not be greater than Total Due Amount!', 'error');
            //     return;
            // }

            if(!this.isFieldSense && (this.payTypeSelectedValue == '' || this.payTypeSelectedValue === undefined)){
                this.showToast('Error', 'Payment Type is required', 'error');
                return;
            }

            this.load = true;

            
            if (navigator.onLine) {
                // --- ONLINE: EXISTING LOGIC ---
                const result = await saveChequeDetails({ chequeData: payloadList, 
                        payType: this.payTypeSelectedValue, 
                        payRemark: this.payRemark });
                if (result === 'Success') {
                    this.handleSuccessResponse(totalAmt);
                } else { 
                    throw new Error('Something went wrong while saving.');
                }
            } else {
                // --- OFFLINE: LDS LOGIC ---
                await this.processOfflineLDS(payloadList, totalAmt);
            }

        } catch (error) {
            console.error('Submission Error:', error);
            let msg = error?.body?.message || error?.message || 'Unexpected error occurred.';
            this.showToast('Error from Save', msg, 'error');
        } finally {
            this.load = false;
        }
    }

    // --- 6. OFFLINE SUBMISSION HANDLER ---
    async processOfflineLDS(payloadList, totalAmt) {
        try {
            // A. Create Payment Records & Files
            for (let cheque of payloadList) {
                
                // 1. Create Payment__c
              const paymentFields = {
                    Name: 'Payment - ' + cheque.chequeNumber, // Patch: Match Apex naming convention
                    Work_Order__c: this.recordId,
                    Cheque_Amount__c: cheque.chequeAmount,
                    Cheque_Date__c: cheque.chequeDate,
                    Payment_Mode__c: cheque.paymentMode, // Patch: Use dynamic mode from payload
                    Cheque_Number__c: cheque.chequeNumber,
                    Branch_Name__c: cheque.branchName,
                    Bank_Name__c: cheque.bankName,
                    IFSC_Code__c: cheque.ifscCode,
                    Business_Partner__c: this.woAccountId // Patch: Link Business Partner
                };
                
                if (!this.isFieldSense) {
                    paymentFields.MICR_Code__c = cheque.micrCode;
                    paymentFields.MICR_Found__c = cheque.micrFound;
                }
                
                const paymentRecord = await createRecord({ apiName: PAYMENT_OBJECT.objectApiName, fields: paymentFields });
                const paymentId = paymentRecord.id;

                // 2. Create ContentVersion (Image)
                const cvFields = {
                    Title: 'Cheque_Image_' + cheque.chequeNumber,
                    PathOnClient: 'Cheque_Image_' + cheque.chequeNumber + '.jpg',
                    VersionData: cheque.base64Image, 
                    FirstPublishLocationId: paymentId 
                };
                await createRecord({ apiName: CONTENT_VERSION_OBJECT.objectApiName, fields: cvFields });
            }

            // B. Update Work Order (Amount & Status)
            const woFields = {
                Id: this.recordId,
                Amount_Received__c: (this.paidAmt ? parseFloat(this.paidAmt) : 0) + totalAmt,
                Payment_Mode__c: 'Cheque',
                Payment_Type__c: this.payTypeSelectedValue,
                Pay_Remark__c: this.payRemark
            };

            if (!this.isFieldSense) {
                woFields.Status = 'Completed'; 
                woFields.Appointment_Status__c = 'Completed';
                
                // Patch: Copy Check-In Location to Check-Out (Parity with Apex)
                if (this.woCheckInLat && this.woCheckInLong) {
                    woFields.Check_Out_Location__Latitude__s = this.woCheckInLat;
                    woFields.Check_Out_Location__Longitude__s = this.woCheckInLong;
                }
            }

            await updateRecord({ fields: woFields });

            // C. Update Service Appointment (Parity)
            if (!this.isFieldSense && this.relatedServiceAppointmentId) {
                const saFields = {
                    Id: this.relatedServiceAppointmentId,
                    Status: 'Completed',
                    Appointment_Type__c: 'Completed'
                };
                await updateRecord({ fields: saFields });
            }

            // D. Update WorkSteps 
            if (!this.isFieldSense && this.relatedWorkStepIds.length > 0) {
                const wsPromises = this.relatedWorkStepIds.map(stepId => {
                    return updateRecord({
                        fields: {
                            Id: stepId,
                            Status: 'Completed'
                        }
                    });
                });
                await Promise.all(wsPromises);
            }

            this.showToast('Info', 'Cheques saved to offline queue.', 'info');
            this.handleSuccessResponse(totalAmt);

        } catch (error) {
            console.error('Offline LDS Error', error);
            throw error;
        }
    }

    // Helper to consolidate success logic for both Online and Offline paths
    handleSuccessResponse(totalAmt) {
        this.paidAmt = totalAmt;
        this.paymentMode = 'Cheque';

        if (FORM_FACTOR !== 'Large' && this.isFieldSense) {
            //this.getMobileLocation('Check Out');
            this.load = false;
            this.chequeList = [];
            this.addAnotherCheque();
            this.showPaymentMessage();
            this.dispatchEvent(new CustomEvent("payreceived", { detail: this.paidAmt }));
        } else if (FORM_FACTOR !== 'Large' && !this.isFieldSense) {
            this.chequeList = [];
            this.addAnotherCheque();
            this.showPaymentMessage();
            this.load = false;
            //this.getMobileLocation('Collect Payment');
        } else {
            this.showToast('Success', 'Cheques saved successfully!', 'success');
            this.resetForm();
            //history.back();
            this.showPaymentMessage();
        }
    }

    resetForm() {
        this.chequeList = [];
        this.addAnotherCheque();
    }

    handleBackFromPayment(){
        this.dispatchEvent(new CustomEvent('showparent'));
    }

    getMobileLocation(type) {

        const locationService = getLocationService();
        if (!locationService || !locationService.isAvailable()) {
            this.showToast('LocationService Not Available', 'Please use a GPS-enabled mobile device and ensure location is turned on.', 'error');
            return;
        }

        const options = {
            enableHighAccuracy: true
        };
        locationService.getCurrentPosition(options)
        .then(result => {
            console.log('======locationService======>', result);

            this.lat = result.coords.latitude;
            this.long = result.coords.longitude;

            if(type){
                updateGeoLocation({ workOrderId: this.recordId, latitude: this.lat, longitude: this.long, activityType: type})
                .then(result => {
                    console.log('======updateGeoLocation======>', result);

                    if(type === 'Check Out' || type ===  'Collect Payment'){
                        //this.showToast('Success', 'Cheques saved successfully!', 'success');
                        this.chequeList = [];
                        this.addAnotherCheque();
                        //history.back();
                        this.showPaymentMessage();
                    }
                    this.load = false;
                })
                .catch(error => {
                    this.showToast('Error', error, 'Error');
                })
            }

        }).catch(error => {
            console.error('Location error:', error);
            this.showToast('Warning', 'Please enable your device location.', 'Warning');
        }).finally(() => {
            
        });
    }

    async handleFile(event) {
        const index = event.target.dataset.index;
        const newSlots = event.detail.steps;

        for (let i = 0; i < newSlots.length; i++) {
            let slot = newSlots[i];
            if (slot.base64Data) {
                try {
                    const fullBase64 = slot.base64Data.startsWith('data:image')
                        ? slot.base64Data
                        : `data:image/jpeg;base64,${slot.base64Data}`;
                    const blob = this.base64ToBlob(fullBase64);
                    const imageUrl = URL.createObjectURL(blob);
                    const compressedBlob = await this.compressImageFromURL(imageUrl);
                    const compressedBase64 = await this.convertBlobToBase64(compressedBlob);
                    slot.base64Data = compressedBase64;
                    const previewBlob = this.base64ToBlob(`data:image/jpeg;base64,${compressedBase64}`);
                    slot.previewUrl = URL.createObjectURL(previewBlob);
                } catch (error) {
                    if (!slot.base64Data || slot.base64Data.length < 100) {
                        console.error(`Compression failed for cheque ${index + 1}`, error);
                    }
                }
            }
        }

        this.chequeList[index].photoUploadSlots = newSlots;
    }

    
    base64ToBlob(base64Data) {
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

                    const maxWidth = 1200;
                    const maxHeight = 1200;

                    let width = img.width;
                    let height = img.height;

                    const ratio = Math.min(maxWidth / width, maxHeight / height);
                    width *= ratio;
                    height *= ratio;

                    // Split top text into lines
                    const topLines = this.textToAddTop.split('\n');
                    const topLineHeight = 11;
                    const topTextPadding = topLines.length * topLineHeight + 5;

                    const bottomTextPadding = 12;
                    const totalPadding = topTextPadding + bottomTextPadding;
                    canvas.width = width;
                    canvas.height = height + totalPadding;

                    ctx.fillStyle = "#ffffff";
                    ctx.fillRect(0, 0, canvas.width, canvas.height);
                    //  Top-left (User + Timestamp)
                    ctx.font = '12px Arial';
                    ctx.fillStyle = 'blue';
                    ctx.textAlign = 'left';

                    topLines.forEach((line, index) => {
                        ctx.fillText(line.trim(), 2, 10 + index * topLineHeight);
                    });
                    // 🖼 Draw the image below top text
                    ctx.drawImage(img, 0, topTextPadding, width, height);
                    //  Bottom-center (Address)
                    ctx.font = '12px Arial';
                    ctx.fillStyle = 'blue';
                    ctx.textAlign = 'center';
                    const bottomTextY = canvas.height - 2;
                    ctx.fillText(this.currentLocationAsString(), canvas.width / 2, bottomTextY);
                    //  Convert to Blob
                    canvas.toBlob(
                        (blob) => {
                            if (blob) {
                                resolve(blob);
                            } else {
                                reject(new Error('Canvas compression failed. Blob was null.'));
                            }
                        },
                        'image/jpeg',
                        0.6
                    );
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

    convertBlobToBase64(blob) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = () => resolve(reader.result.split(',')[1]);
            reader.onerror = reject;
            reader.readAsDataURL(blob);
        });
    }
    
    showToast(title, msg, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    currentLocationAsString() {
       return `Lat: ${this.lat}, Long: ${this.long}`;
    }

    handleChequeDateChange(event) {

        const index = event.target.dataset.index;
        const field = event.target.dataset.id;

        const enteredDate = new Date(event.target.value);
        const today = new Date();
        // Calculate difference in days
        const diffTime = enteredDate.getTime() - today.getTime();
        const diffDays = diffTime / (1000 * 60 * 60 * 24);
        if (diffDays > 3) {
            this.showToast('Error', 'Cheque date cannot be more than 3 days from today.', 'error');
            event.target.value = '';
            this.chequeList[index][field] = null; // clear invalid date
        }else{
            this.chequeList[index][field] = event.target.value;
        }
    }

    handleKeyDown(event) {
        // Allow backspace, delete, tab, escape, enter, and arrow keys
        if ([8, 9, 27, 13, 46].includes(event.keyCode) || 
            // Allow Ctrl/Cmd+A, Ctrl/Cmd+C, Ctrl/Cmd+V, Ctrl/Cmd+X
            ((event.keyCode === 65 || event.keyCode === 67 || event.keyCode === 86 || event.keyCode === 88) && (event.ctrlKey === true || event.metaKey === true)) ||
            // Allow home, end, left, right arrow keys
            (event.keyCode >= 35 && event.keyCode <= 40)) {
            return;
            // Let it happen, don't do anything
        }
        // Ensure that it is a number and stop the keypress
        if ((event.shiftKey || (event.keyCode < 48 || event.keyCode > 57)) && (event.keyCode < 96 || event.keyCode > 105)) {
            event.preventDefault();
        }
    }

    handleInput(event) {
        // Optional: Further refinement to remove non-numeric characters if pasted
        const inputValue = event.target.value;
        this.accountAlternatePhone = inputValue.replace(/[^0-9]/g, '');
    }

    sendPayMsg() {
        
        if(this.accountAlternatePhone == ''){
            this.showToast('Warning', 'Please Enter Phone Number!', 'wraning');
            return;
        }
        
        this.isLoading = true; // Use this.load instead? Keeping isLoading as per original
        sendSMS({ phoneNumber:this.accountAlternatePhone, workOrderId:this.recordId })
        .then((result) => {
            this.isLoading = false;
            if (result == 'Success') {
                this.showToast('Success','Payment SMS sent to customer', 'success');
            } 
            else if(result == 'Error'){
                this.showToast('Error','No Payment SMS sent to customer', 'error');
            }
            else {
                this.showToast('Error','No Payment SMS sent to customer', 'error');
            }
        })
        .catch((err) => {
            this.isLoading = false;
            const errorMsg = err.body?.message || err.message || 'Unknown error';
            this.showToast('Error sending SMS: ' + errorMsg, 'error');
        });
    }
}