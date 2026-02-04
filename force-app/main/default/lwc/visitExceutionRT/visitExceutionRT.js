import { LightningElement, api, track, wire } from 'lwc';

import getAccountInfoFromSA from '@salesforce/apex/RTPaymentHistoryClass.getAccountInfoFromSA';
import saveChequeDetails from '@salesforce/apex/RTPaymentHistoryClass.saveChequeDetails';
import updateGeoLocation from '@salesforce/apex/RTPaymentHistoryClass.updateGeoLocation';
import savePdfFiles from '@salesforce/apex/RTPaymentHistoryClass.savePdfFiles';
import getBankDetailsByMicr from '@salesforce/apex/RTPaymentHistoryClass.getBankDetailsByMicr';
import getReceivables from '@salesforce/apex/RTPaymentHistoryClass.getReceivables';
import savePdfFile from '@salesforce/apex/RTPaymentHistoryClass.savePdfFile';
import getPreferencePicklistValues from '@salesforce/apex/RTPaymentHistoryClass.getPreferencePicklistValues';
import asGoCollectFlowLabel from "@salesforce/label/c.AS_GoCollectFlowLabel";
import asFieldSenseFlowLabel from "@salesforce/label/c.AS_FieldSenseFlowLabel";
import fetchBillingByBP from '@salesforce/apex/RTPaymentHistoryClass.fetchBillingByBP'; 
import { NavigationMixin } from 'lightning/navigation';
import { getLocationService } from 'lightning/mobileCapabilities';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import FORM_FACTOR from '@salesforce/client/formFactor';

import WORKTYPE_NAME_FIELD from '@salesforce/schema/WorkOrder.WorkType.Name';
import CHECK_IN_DATE_FIELD from "@salesforce/schema/WorkOrder.Check_In_Date_Time__c";

import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import userId from '@salesforce/user/Id';
import userNameField from '@salesforce/schema/User.Name';
  
export default class RTVisitExecution extends NavigationMixin(LightningElement) {
    @api recordId;
    @track account; 
    @track serviceAppointment;
    @track error; 
    @track accountView = true;
    @track workOrder;
    @track load = false;
    @track showPdc = false;
    @track accountDetails = false;
    showPaymentRequestPOS = false;
    showPaymentRequestQRcode = false;
    showChequeChoiceScreen = false;
    @track showSelectPaymentMethodScreen = false;
    @track micrCode;
    @track bankName;
    @track branchName;
    @track Ifsc;
    @track chequeNumber = '';
    @track chequeDate = '';
    @track caNumber = '';
    @track chequeAmount = '';
    @track showChequeForm = false;
    @track photoUploadSlots = [];
    @track accountPhone='';
    accountAlternatePhone;
    @track billingHistory = [];
    @track ifChecked=false;
    @track isLoading=false;
    noOfPhotos = 1;

    isCheckInDateAvailable = false;

    label = { asGoCollectFlowLabel, asFieldSenseFlowLabel };
    isGoCollect = false;
    isFieldSense = false;

    isOpenDueAmt = false;
    chevronClassDueAmt = 'slds-accordion__section slds-is-open';
    isOpenLastPay = false;
    chevronClassLastPay = 'slds-accordion__section slds-is-open';
    isOpenLastBill = false;
    chevronClassLastBill = 'slds-accordion__section slds-is-open';

    billing = [];
    payment = [];

    workOrderType = '';
    currentUserName
    textToAddTop = '';
    lat = '';
    long = '';

    @wire(getRecord, { recordId: userId, fields: [userNameField] })
    wiredUser({ error, data }) {
        if (data) {
            this.currentUserName = data.fields.Name.value;
        } else if (error) {
            this.error = error;
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: [WORKTYPE_NAME_FIELD, CHECK_IN_DATE_FIELD] })
    wiredWorkOrder({ error, data }) {
        if (data) {
            this.workOrderType = data.fields.WorkType.displayValue;
        } else if (error) {
            console.error('Error fetching Work Order:', error);
        }
    }

    connectedCallback() {
        this.setPhotoUploadSlots();
        this.fetchPreferences();
        if (this.recordId) {
            this.fetchAccountInfo();
        }
        this.textToAddTop = `${this.currentUserName}\n${this.formatDateTime(new Date())}`;
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
        hours = hours ? hours : 12; // convert 0 to 12
        const formattedHours = String(hours).padStart(2, '0');

        return `${day} ${month} ${year} ${formattedHours}:${minutes} ${ampm}`;
    }

    toggleSection(event) {
        const sectionName = event.currentTarget.dataset.id;
        if(sectionName == 'DueAmount'){
            this.isOpenDueAmt = !this.isOpenDueAmt;
            this.chevronClassDueAmt = this.isOpenDueAmt ? 'slds-accordion__section slds-is-open' : 'slds-accordion__section slds-is-close bottom';
        }else if(sectionName == 'Last3Payment'){
            this.isOpenLastPay = !this.isOpenLastPay;
            this.chevronClassLastPay = this.isOpenLastPay ? 'slds-accordion__section slds-is-open' : 'slds-accordion__section slds-is-close bottom';
        }else if(sectionName == 'Last3Bill'){
            this.isOpenLastBill = !this.isOpenLastBill;
            this.chevronClassLastBill = this.isOpenLastBill ? 'slds-accordion__section slds-is-open' : 'slds-accordion__section slds-is-close bottom';
        }else if (sectionName === 'Last3Receivables') {   // ✅ missing case
        this.isOpenLastReceivable = !this.isOpenLastReceivable;
        this.chevronClassLastReceivable = this.isOpenLastReceivable
            ? 'slds-accordion__section slds-is-open'
            : 'slds-accordion__section slds-is-close bottom';
    }
    }

    get maskedPhNo(){
        return this.maskNumber(this.accountPhone);
    }

    maskNumber(value) {
        if(value){  
            const unmaskedDigits = 4; 
            const maskedPart = '*'.repeat(value.length - unmaskedDigits);
            const unmaskedPart = value.slice(-unmaskedDigits);
            return (maskedPart + unmaskedPart);
        }
    }

    renderedCallback() {}

    fetchAccountInfo() {

        this.isLoading = true;

        getAccountInfoFromSA({ workOrderId: this.recordId })
            .then((data) => { 

                console.log('========data=======>', JSON.stringify(data));

                this.account = data.acc;
                this.accountId = data.acc.Id;

                this.accountPhone = data.workOrder && data.workOrder.New_Mobile_Number__c != null ? data.workOrder.New_Mobile_Number__c : this.account.Phone;

                this.account.BP_Number__c = data.workOrder && data.workOrder.BP_Number__c != null ? data.workOrder.BP_Number__c : this.account.BP_Number__c;
                this.account.CA_Number__c = data.workOrder && data.workOrder.CA_Number__c != null ? data.workOrder.CA_Number__c : this.account.CA_Number__c;
                this.account.Building_name__c = data.workOrder && data.workOrder.Building_Name__c != null ? data.workOrder.Building_Name__c : this.account.Building_name__c;
                this.account.Floor__c = data.workOrder && data.workOrder.New_Floor__c != null ? data.workOrder.New_Floor__c : this.account.Floor__c;
                this.account.Room__c = data.workOrder && data.workOrder.New_Flat__c != null ? data.workOrder.New_Flat__c : this.account.Room__c;
                this.account.Wing__c = data.workOrder && data.workOrder.New_Wing__c != null ? data.workOrder.New_Wing__c : this.account.Wing__c;
                this.account.Colony__c = data.workOrder && data.workOrder.New_Colony__c != null ? data.workOrder.New_Colony__c : this.account.Colony__c;
                 this.fetchBillingHistory(this.account.BP_Number__c);

                this.accountDetails = true;
                if (data.serviceAppointments && data.serviceAppointments.length > 0) {
                    this.serviceAppointment = data.serviceAppointments[0];
                }
                this.workOrder = data.workOrder;
                


                const isCheckInDateAvailable = this.workOrder.Check_In_Date_Time__c != null;
                const isWorkOrderCompleted = this.workOrder.Status == 'Completed';
                const isCheckOutDateAvailable = this.workOrder.Check_Out_Date_Time__c != null;
                
                if(isCheckInDateAvailable && isWorkOrderCompleted && isCheckOutDateAvailable){
                    this.showEnableMessage = true;
                    this.message = 'Task is already completed. Please refresh the WorkOrder page to continue.';
                }else if(!isCheckInDateAvailable && !isWorkOrderCompleted){
                    this.showEnableMessage = true;
                    this.message = 'Check-In is required. Please Check-In and refresh the WorkOrder page to continue.';
                }else{
                    this.showEnableMessage = false;
                }


                this.billing = data.billing;
                this.billing.filter(el=>{
                    el.checked=false;
                    el.disabled=false;
                    return el;
                })
                this.payment = data.payment;

                if(data.workOrder.WorkType && data.workOrder.WorkType.Name){
                    this.isGoCollect = this.label.asGoCollectFlowLabel.split(',').indexOf(data.workOrder.WorkType.Name.toLowerCase()) !== -1;
                    this.isFieldSense = this.label.asFieldSenseFlowLabel.split(',').indexOf(data.workOrder.WorkType.Name.toLowerCase()) !== -1;
                }

                this.error = null;

                this.caNumber = this.workOrder.Customer_CA_Number__c;
                this.chequeAmount = this.workOrder.Due_Amount__c;

                this.isLoading = false;
            })
        .catch(error => {
            this.isLoading = false;
            this.showToast('Error', error?.body?.message || 'Failed to get account details.', 'error');
        });
    }
    
    get formattedVisitDateTime() {
        if (this.serviceAppointment?.SchedEndTime) {
            const dt = new Date(this.serviceAppointment.SchedEndTime);
            const date = dt.toLocaleDateString('en-GB');
            const time = dt.toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit' });
            return `${date}, ${time}`;
        }
        return '';
    }


    handleTakeReading() {
        if(this.workOrderType.toLowerCase() === 'payment collection(i&c)' || this.workOrderType.toLowerCase() === 'payment collection(r&t)'){ 
            if (FORM_FACTOR !== 'Large') {
                this.getMobileLocation('Check In');
            }else{
                this.showSelectPaymentMethodScreen = true;
                this.accountDetails = false;
            }
        }else{
            this.showSelectPaymentMethodScreen = true;
            this.accountDetails = false;
        } 
    }

    handleCashPayment() {
        console.log('Selected Cash Payment');
    }

    handleCardPayment() {
        this.showPayModeScreen = true;
        this.showPaymentRequestPOS = true;
        this.showSelectPaymentMethodScreen = false;
        this.accountDetails = false;
    }

    handleBackFromPaymentMethod() {
        this.showSelectPaymentMethodScreen = false;
        this.accountDetails = true;
    }

    handleBackFromPayMode() {
        this.showSelectPaymentMethodScreen = true;
        this.showPayModeScreen = false;

        this.showPaymentRequestPOS = false;
        this.showPaymentRequestQRcode = false;
        this.accountDetails = false;
    }

    handleUpiPayment() {
        this.showPayModeScreen = true;
        this.showPaymentRequestQRcode = true;
        this.showSelectPaymentMethodScreen = false;
        this.accountDetails = false;
    }

    handleChequePayment() {
        this.showPdc = true;
        this.showChequeChoiceScreen = false;
        this.showSelectPaymentMethodScreen = false;
        this.accountDetails = false;
    }

    handleCheque(){
        this.showChequeForm = true;
        this.showChequeChoiceScreen = false;
        this.showSelectPaymentMethodScreen = false;
    }

    handlePostDatedCheque() {
        this.showPdc = true;
        this.showChequeChoiceScreen = false;
        this.showSelectPaymentMethodScreen = false;
	}

    handleChequeInputChange(event) {
        const field = event.target.dataset.id;
        this[field] = event.target.value;
    }

    handleMicrChange(event) {
        this.micrCode = event.target.value;

        if (this.micrCode && this.micrCode.length >= 8) {
            getBankDetailsByMicr({ micrCode: this.micrCode })
                .then(result => {
                    this.bankName = result.BANK__c;
                    this.branchName = result.BRANCH__c;
                    this.Ifsc = result.IFSC__c;
                })
                .catch(error => {
                    this.bankName = '';
                    this.branchName = '';
                    this.Ifsc = '';
                    console.error('Error fetching bank details: ', error);
                });
        } else {
            this.bankName = '';
            this.branchName = '';
            this.Ifsc = '';
        }
    }


    handleChequeSubmit() {
        // Basic validation
        if (!this.micrCode || !this.chequeNumber || !this.chequeDate) {
            alert('Please fill all required fields.');
            return;
        }

        const allFilesSelected = this.photoUploadSlots.length === this.noOfPhotos &&
            this.photoUploadSlots.every(slot => slot.fileName && slot.base64Data);

        if (!allFilesSelected) {
            this.load = false;
            this.showToast('Warning', `Please capture ${this.noOfPhotos} photo(s).`, 'warning');
            return;
        }
        this.load = true;

        const chequeData = {
            micrCode: this.micrCode,
            bankName: this.bankName,
            branchName: this.branchName,
            ModeofPayment: 'Cheque',
            chequeNumber: this.chequeNumber,
            chequeDate: this.chequeDate,
            caNumber: this.caNumber,
            chequeAmount: this.chequeAmount
        };

        console.log('Submitting Cheque Payment:', chequeData);

        saveChequeDetails({
            workOrderId: this.recordId,
            workStepName: 'Payment Capture',
            ...chequeData,
            base64Images: this.photoUploadSlots.map(slot => slot.base64Data),
            signatureBase64: this.signatureBase64
        })
        .then((paymentId) => {
            this.load = false;
            if(FORM_FACTOR !== 'Large'){
                this.getMobileLocation('Check Out');
            }else{
                this.showToast('Success', 'Cheque payment details saved.', 'success');
                console.log('Payment ID:', paymentId);
            }
            history.back();
        })
        .catch(error => {
            this.load = false;
            console.error('Error saving cheque details:', JSON.stringify(error, null, 2));
            this.showToast('Error', error?.body?.message || 'Failed to save cheque details.', 'error');
        });
    }


    async handleFile(event) {
        console.log('📥 inside handleFile');
        let newSlots = event.detail.steps;

        for (let i = 0; i < newSlots.length; i++) {
        let slot = newSlots[i];
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
                //console.error(`Compression failed for Photo ${i + 1}:`, error);

                // Only show toast if compressed base64 is not usable
                if (!slot.base64Data || slot.base64Data.length < 100) {
                console.error(`Compression failed for Photo ${i + 1}:`, error?.message || JSON.stringify(error) || 'Unknown error');
                } else {
                    console.warn(`⚠️ Compression threw error but base64 still present for Photo ${i + 1}`);
                }
            }

            } else {
                console.warn(`⚠️ Skipped Photo ${i + 1}: base64Data missing.`);
            }
        }

        this.photoUploadSlots = newSlots;
        console.log('✅ Final photoUploadSlots set');
   }

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
                    const topLineHeight = 12;
                    const topTextPadding = topLines.length * topLineHeight + 5;

                    const bottomTextPadding = 10;
                    const totalPadding = topTextPadding + bottomTextPadding;

                    canvas.width = width;
                    canvas.height = height + totalPadding;

                    ctx.fillStyle = "#ffffff";
                    ctx.fillRect(0, 0, canvas.width, canvas.height);

                    // ✍️ Top-left (User + Timestamp)
                    ctx.font = '12px Arial';
                    ctx.fillStyle = 'blue';
                    ctx.textAlign = 'left';

                    topLines.forEach((line, index) => {
                        ctx.fillText(line.trim(), 2, 10 + index * topLineHeight);
                    });

                    // 🖼 Draw the image below top text
                    ctx.drawImage(img, 0, topTextPadding, width, height);

                    // ✍️ Bottom-center (Address)
                    ctx.font = '12px Arial';
                    ctx.fillStyle = 'blue';
                    ctx.textAlign = 'center';
                    const bottomTextY = canvas.height - 2;
                    ctx.fillText(this.currentLocationAsString(), canvas.width / 2, bottomTextY);

                    // 📦 Convert to Blob
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
    async convertBlobToBase64(blob) {
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

    getMobileLocation(type) {

        const locationService = getLocationService();

        if (!locationService || !locationService.isAvailable()) {
            this.showtoast('LocationService Not Available', 'Please use a GPS-enabled mobile device and ensure location is turned on.', 'error');
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

            this.address = result?.address;

            updateGeoLocation({ workOrderId: this.recordId, latitude: this.lat, longitude: this.long, activityType: type})
            .then(result => {
                console.log('======updateGeoLocation======>', result);

                if(type === 'Check Out'){
                    this.showToast('Success', 'Cheque payment details saved.', 'success');
                    console.log('Payment ID:', paymentId);
                    history.back();
                }else{
                    this.showSelectPaymentMethodScreen = true;
                    this.accountDetails = false;
                }
            })
            .catch(error => {
                this.showtoast('Error', error, 'Error');
            })

        }).catch(error => {
            console.error('Location error:', error);
            this.showtoast('Warning', 'Please enable your device location.', 'Warning');
        }).finally(() => {
            
        });
    }

    currentLocationAsString() {
       return `Lat: ${this.lat}, Long: ${this.long}`;
    }

    @track accountId;
    error;
    @track isLoading = false;
    @track showPdfPage = false;
    @track pdfUrl = '';

    get last3Billings() {
        return this.billing || [];
    }

    get hasNoBillings() {
        return !this.billing || this.billing.length === 0;
    }
    getPdf(event) {
        const printDocNum = event.currentTarget.dataset.printdoc;
        this.isLoading = true;
        
        console.log('Fetching PDF for:', printDocNum, 'WorkOrder:', this.recordId);
        
        // Change from @wire to imperative call
        savePdfFile({ billPrintNumber: printDocNum, workOrderId: this.recordId })
        .then((publicUrl) => {
            this.isLoading = false;
            console.log('PDF URL received:', publicUrl);
            if (publicUrl) {
                this.pdfUrl = publicUrl;
                this.showPdfPage = true;
            } else {
                this.showToast('No PDF file created or available', 'warning');
            }
        })
        .catch((err) => {
            this.isLoading = false;
            console.error('Error fetching PDF:', err);
            const errorMsg = err.body?.message || err.message || 'Unknown error';
            this.showToast('Error fetching PDF: ' + errorMsg, 'error');
        });
    }
    printDocNum=null;
    handleCheckBoxChange(event) {
        const value = event.target.value;
            console.log('value::'+value);
            this.printDocNum = value;
            if(!value){
                this.printDocNum = null;
            }
            
        this.ifChecked = this.printDocNum !== null;

    }

// updateProcessedBills() {
//     // fallback to empty array if billing is undefined
//     const sourceBills = this.billing || [];

//     const updatedBills = sourceBills.map(bill => {
//         return {
//             ...bill,
//             checked: this.printDocNum === bill.Print_Doc_Number__c,
//             disabled: this.printDocNum && this.printDocNum !== bill.Print_Doc_Number__c
//         };
//     });

//     this.last3Billings = [...updatedBills]; // assign fresh array for reactivity
// }
@track preferenceOptions = [];
    selectedPreference = '';

    fetchPreferences() {
        getPreferencePicklistValues()
            .then(result => {
                this.preferenceOptions = result.map(value => ({
                    label: value,
                    value: value
                }));
            })
            .catch(error => {
                console.error('Error fetching picklist values:', error);
            });
    }

    handleChange(event) {
        this.selectedPreference = event.detail.value;
        console.log('Selected Preference: ', this.selectedPreference);
    }

    handlePhoneChange(event){
        let inputValue = event.target.value;
        let cleanValue = inputValue.replace(/,/g, '');
        this.accountAlternatePhone = cleanValue;
    }

    handleKeyDown(event) {
        // Allow backspace, delete, tab, escape, enter, and arrow keys
        if ([8, 9, 27, 13, 46].includes(event.keyCode) || 
            // Allow Ctrl/Cmd+A, Ctrl/Cmd+C, Ctrl/Cmd+V, Ctrl/Cmd+X
            ((event.keyCode === 65 || event.keyCode === 67 || event.keyCode === 86 || event.keyCode === 88) && (event.ctrlKey === true || event.metaKey === true)) ||
            // Allow home, end, left, right arrow keys
            (event.keyCode >= 35 && event.keyCode <= 40)) {
            return; // Let it happen, don't do anything
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
    
    getPdfList() {

        if(this.accountAlternatePhone){
            this.accountPhone = this.accountAlternatePhone;
        }
        if(this.accountPhone==''){
            this.showToast('Warning', 'Please Enter Phone Number!', 'wraning');
            return;
        }
        if(this.selectedPreference==''){
            this.showToast('Warning', 'Please Select Preference!', 'wraning');
            return;
        }
        if(this.printDocNum==null){
            this.showToast('Warning', 'Please Select Bill Number!', 'wraning');
            return;
        }
        this.isLoading = true;
        console.log('this.printDocNum::'+this.printDocNum);
        savePdfFiles({ billPrintNumbers: this.printDocNum,phoneNumber:this.accountPhone,accountName:this.account.Name,preference:this.selectedPreference,workOrderId:this.recordId })
            .then((publicUrls) => {
                this.isLoading = false;
                if (publicUrls=='Success') {
                    this.showToast('Success','PDF sent to customer', 'success');
                    console.log('PDF URLs:', publicUrls); 
                } else {
                    this.showToast('Error','PDF didn not send to customer', 'error');
                }
            })
            .catch((err) => {
                this.isLoading = false;
                console.log('error::'+JSON.stringify(err));
                const errorMsg = err.body?.message || err.message || 'Unknown error';
                this.showToast('Error fetching PDFs: ' + errorMsg, 'error');
            });
    }
    goBack() {
        this.showPdfPage = false;
        this.pdfUrl = '';
    }

// showToast(message, variant) {
//     this.dispatchEvent(
//         new ShowToastEvent({
//             title: 'PDF Viewer',
//             message: message,
//             variant: variant,
//         })
//     );
// }

    @wire(getReceivables, { accountId: '$accountId' })
    wiredReceivables({ data, error }) {
        if (data) {
            this.receivables = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.receivables = undefined;
        }
    }

    get hasNoReceivables() {
        return !this.receivables || this.receivables.length === 0;
    }
    
    @track isOpenLastReceivable = false
    chevronClassLastReceivable = 'slds-accordion__section slds-is-open';

    // Last 3 receivables by Document Date
      get last3Receivables() {
        if (this.billingHistory && this.billingHistory.length > 0) {
            return this.billingHistory.slice(0, 3).map(bill => ({
                Id: bill.id || 'temp-id-' + Math.random(),
                Doc_Number__c: bill.printDocNumber || 'N/A',
                Document_Date__c: bill.billDate || null
            }));
        }
        return [];
    }

    handleCancel() {
        history.back();
    }
    // Method to fetch billing history from API
    fetchBillingHistory(bpNumber) {
        if (!bpNumber) {
            console.log('No BP number available');
            this.billingHistory = [];
            return;
        }

        fetchBillingByBP({ bpNumber: bpNumber })
            .then(result => {
                console.log('Billing API response:', JSON.stringify(result));
                this.billingHistory = result || [];
            })
            .catch(error => {
                console.error('Error fetching billing history:', error);
                this.billingHistory = [];
                this.showToast('Warning', 'Unable to fetch payment history', 'warning');
            });
    }

}