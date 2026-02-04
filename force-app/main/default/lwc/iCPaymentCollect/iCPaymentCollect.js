import { LightningElement, track, api, wire } from 'lwc';

import saveImage from '@salesforce/apex/ICImageRemarkComponentHandler.saveImage';
import updateGeoLocation from '@salesforce/apex/ICImageRemarkComponentHandler.updateGeoLocation';
import getServiceAppoinment from '@salesforce/apex/ICImageRemarkComponentHandler.getServiceAppoinment';
import paymentReceived from '@salesforce/apex/ICImageRemarkComponentHandler.paymentReceived';
import sendSMS from '@salesforce/apex/ICImageRemarkComponentHandler.sendSms';
import getLocationFromCoOrdinates from '@salesforce/apex/GeoServiceHandler.getLocationFromCoOrdinates'
import checkAllocation from '@salesforce/apex/ICImageRemarkComponentHandler.checkAllocation';
 
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { getLocationService } from 'lightning/mobileCapabilities';
import { getRecord } from 'lightning/uiRecordApi';
import userId from '@salesforce/user/Id';
import userNameField from '@salesforce/schema/User.Name';

export default class ICPaymentCollect extends LightningElement { 

    @track remarks = '';
    @track photoUploadSlots = [];
    @track modeOfPayment = '';
    @track amount = '';
    noOfPhotos = 2;
    @track load = false; 
    @api recordId;

    showPaymentRequestQRcode = false;
    showPdc = false;
    showPaymentOption = false;
    showPaymentReceived = false;
    paymentReceived = '';
    payType = '';
    dueAmt = '';
    showEnableMessage = false;

    currentUserName;
    textToAddTop = '';
    lat = '';
    long = '';
    accountAlternatePhone = '';
    locationText = ''
    
    handleRemarksChange(event) {
        this.remarks = event.target.value;
    }

    handleInputChange(event) {
        const { name, value } = event.target;

        if (name === 'amount') {
            this.amount = parseFloat(value) || 0;
        } else {
            this[name] = value;
        }
    }

    // Fetch the logged-in user details to display the agent name and timestamp
    // on top of the images captured during the activity
    @wire(getRecord, { recordId: userId, fields: [userNameField] })
    wiredUser({ error, data }) {
        if (data) {
            this.currentUserName = data.fields.Name.value;
            this.textToAddTop = `${this.currentUserName}\n${this.formatDateTime(new Date())}`;
        } else if (error) {
            this.error = error;
        }
    }

    checkAllocation() {
        checkAllocation({ recordId: this.recordId })
            .then(result => {

                // check result is not null / undefined AND is false
                if (result !== null && result !== undefined && result === false) {
                    this.showEnableMessage = true;
                    this.message = 'This case is no longer assigned to you.';
                }

            })
            .catch(error => {
                this.showtoast('Error', error, 'JError');
            });
    }

    connectedCallback() {
        this.checkAllocation();
        this.setPhotoUploadSlots();
        this.getServiceAppoinment();

        if (FORM_FACTOR !== 'Large') {
            this.getMobileLocation('');
        }
    }

    confirmQRPayment(){
        paymentReceived({ workOrderId: this.recordId, amtReceived: this.dueAmt })
        .then(result => {
            console.log('=====result===>', JSON.stringify(result));
            if(result){
                this.paymentReceived = result;
                this.payType = 'QR Code';
                this.showPaymentReceived = true;
            }
        });
    }
    
    handlePayReceived(event){
        this.paymentReceived = event.detail;
        this.payType = 'Cheque';
        this.showPaymentReceived = true;
    }

    getServiceAppoinment() {   

        getServiceAppoinment({ recordId: this.recordId })
        .then(result => {
            console.log('=====result===>', JSON.stringify(result));

            if(result){
                //const followUpDate = result.followUpDate ? result.followUpDate : '';
                const status = result.status ? result.status : '';
                const checkOutLocation = result.checkOutLocation ? String(result.checkOutLocation) : '';
                const checkInLocation = result.checkInLocation ? String(result.checkInLocation) : '';
                const checkOutDateTime = result.checkOutDateTime ? result.checkOutDateTime : '';
                const checkINDateTime = result.checkInDateTime ? result.checkInDateTime : '';

                this.paymentReceived = result.amountReceived ? result.amountReceived : '';
                this.payType = result.payType ? result.payType : '';
                this.dueAmt = result.dueAmt ? result.dueAmt : '';
                this.remarks = result.remarks ? result.remarks : '';

                if (checkOutLocation != '' && checkInLocation != '' && checkOutDateTime != '' && checkINDateTime != '' && status == 'Completed') {
                    this.showEnableMessage = true;
                    this.message = 'Task is already completed. Please refresh the WorkOrder page and continue.';
                }

                if ((checkInLocation == '' || checkINDateTime == '') && (checkOutLocation == '' || checkOutDateTime == '') && status == 'Follow Up') {
                    this.showtoast('Warning','This is a Follow-Up task. If you want to attempt follow-up task today then continue else go back to Home screen.','warning');
                }
            }
            
        })
        .catch(error => {
            this.showtoast('Error', error, 'Error');
        })
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

    sendPayMsg() {
        
        if(this.accountAlternatePhone == ''){
            this.showtoast('Warning', 'Please Enter Phone Number!', 'wraning');
            return;
        }
        
        this.isLoading = true;

        sendSMS({ phoneNumber:this.accountAlternatePhone, workOrderId:this.recordId })
        .then((result) => {
            this.isLoading = false;
            if (result == 'Success') {
                this.showtoast('Success','Payment SMS sent to customer', 'success');
            } 
            else if(result == 'Error'){
                this.showtoast('Error','No Payment SMS sent to customer', 'error');
            }
            else {
                this.showtoast('Error','No Payment SMS sent to customer', 'error');
            }
        })
        .catch((err) => {
            this.isLoading = false;
            const errorMsg = err.body?.message || err.message || 'Unknown error';
            this.showtoast('Error sending SMS: ' + errorMsg, 'error');
        });
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

    saveChildRecord(){
        const childComponent = this.template.querySelector('c-ic-account-update');
        if (childComponent) {
            childComponent.submitForm();
        }
    }

    handleChildSaved(){

        const allFilesSelected = this.photoUploadSlots.find(slot => slot.fileName !== '');

        if (!allFilesSelected) {
            this.load = false;
            this.showtoast('Warning', 'Please Capture at least 1 photo.', 'warning');
            return;
        }

        const signatureComp = this.template.querySelector('c-as-signature-pad');
        if (signatureComp) {
            if (signatureComp.isEmpty()) {
                this.showtoast('Warning', 'Signature is required.', 'warning');
                return;
            }
            const signatureBase64 = signatureComp.getSignatureBase64();
            this.signatureBase64 = signatureBase64;
        }

        this.load = true;
        const workStepName = 'Payment Capture';
        const photoUploadSlots = this.photoUploadSlots.filter(slot => slot.fileName !== '');

        saveImage({
            listFiles: photoUploadSlots,
            recordId: this.recordId,
            remarks: this.remarks,
            mobileNumber: null,
            secondaryNumber: null,
            emailId: null,
            workStepName: workStepName,
            signatureBase64: this.signatureBase64
        })
        .then((result) => {
            this.showtoast('Success', 'Images and payment details saved successfully!', 'success');
            this.load = false;
            history.back();
            this.dispatchEvent(new CustomEvent('cancel'));
        })
        .catch(error => {
            this.load = false;
            const message = error?.body?.message || error?.message || 'Unknown error occurred';
            this.showtoast('Error', message, 'error');
        });
    }


    handleFinalSave() {
        const allFilesSelected = this.photoUploadSlots.find(slot => slot.fileName !== '');

        if (!allFilesSelected) {
            this.load = false;
            this.showtoast('Warning', 'Please Capture at least 1 photo.', 'warning');
            return;
        }

        // if (!this.modeOfPayment || !this.amount) {
        //     this.load = false;
        //     this.showtoast('Warning', 'Please fill Mode of Payment and Amount.', 'warning');
        //     return;
        // }

        const signatureComp = this.template.querySelector('c-as-signature-pad');
        if (signatureComp) {
            const signatureBase64 = signatureComp.getSignatureBase64();
            this.signatureBase64 = signatureBase64;
        }

        this.saveChildRecord();
    }

    handleUpiPayment(){
        console.log('======this.paymentReceived====>>', this.paymentReceived);
        console.log('======this.payType====>>', this.payType);
        if(this.paymentReceived && this.payType){
            this.showPaymentReceived = true;
        }else{
            this.showPaymentReceived = false;
            this.showPaymentRequestQRcode = true;
            this.showPaymentOption = true;
        }
    }

    handleChequePayment(){
        console.log('======this.paymentReceived====>>', this.paymentReceived);
        console.log('======this.payType====>>', this.payType);
        if(this.paymentReceived && this.payType){
            this.showPaymentReceived = true;
        }else{
            this.showPaymentReceived = false;
            this.showPdc = true;
            this.showPaymentOption = true;
        }
    }

    handleBackFromPayment(){
        this.showPaymentReceived = false;
        this.showPaymentRequestQRcode = false;
        this.showPdc = false;
        this.showPaymentOption = false;
    }

    handleShowParent(){
        this.handleBackFromPayment();
    }

    async handleFile(event) {

        let newSlots = event.detail.steps;
        console.log('========newSlots======>>>>', newSlots);

        for (let i = 0; i < newSlots.length; i++) {
            let slot = newSlots[i];

            console.log(`🔄 Processing Photo ${i + 1}`);
            console.log('========slot======>>>>', slot);

            // 🔥 Ensure we always work from ORIGINAL IMAGE (never the modified one)
            const rawBase64 = slot.originalBase64Data || slot.base64Data;

            if (!rawBase64) {
                console.warn(`⚠️ Skipped Photo ${i + 1}: base64Data missing.`);
                continue;
            }

            // Store raw base64 permanently
            slot.originalBase64Data = rawBase64;

            try {
                const fullBase64 = rawBase64.startsWith('data:image')
                    ? rawBase64
                    : `data:image/jpeg;base64,${rawBase64}`;

                // Original size
                const originalBytes = atob(fullBase64.split(',')[1]).length;
                console.log(`📷 Original Size Photo ${i + 1}: ${(originalBytes / 1024 / 1024).toFixed(2)} MB`);

                const blob = this.base64ToBlob(fullBase64);
                const imageUrl = URL.createObjectURL(blob);

                const compressedBlob = await this.compressImageFromURL(imageUrl);

                const compressedBase64 = await this.convertBlobToBase64(compressedBlob);

                const compressedBytes = atob(compressedBase64).length;
                console.log(`📉 Compressed Size Photo ${i + 1}: ${(compressedBytes / 1024 / 1024).toFixed(2)} MB`);

                // Store NEW image (with text)
                slot.base64Data = compressedBase64;

            } catch (error) {
                console.error(`❌ Compression failed for Photo ${i + 1}`, error);
            }
        }

        this.photoUploadSlots = newSlots;
        console.log('✅ Final photoUploadSlots set', this.photoUploadSlots);
    }


    // =========================================================================================
    // Helper Functions
    // =========================================================================================

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

                    canvas.width = width;
                    canvas.height = height;

                    // Draw image
                    ctx.drawImage(img, 0, 0, width, height);

                    // Set font and style BEFORE drawing text
                    ctx.font = '30px Arial';
                    ctx.fillStyle = 'blue'; 
                    ctx.textAlign = 'left';

                    const paddingLeft = 10; // distance from left edge

                    // Top text
                    const topLines = this.textToAddTop.split('\n');
                    topLines.forEach((line, index) => {
                        ctx.fillText(line.trim(), paddingLeft, 35 + index * 34);
                    });

                    // Bottom text (fixed size, wrap to next line if too long)
                    ctx.font = '30px Arial';  // keep desired font size
                    ctx.fillStyle = 'blue';
                    ctx.textAlign = 'left';

                    const maxTextWidth = width - paddingLeft * 2;
                    const words = this.locationText.split(' ');
                    let line = '';
                    let y = height - 17; // start from bottom

                    for (let i = 0; i < words.length; i++) {
                        const testLine = line + words[i] + ' ';
                        if (ctx.measureText(testLine).width > maxTextWidth) {
                            ctx.fillText(line, paddingLeft, y);
                            line = words[i] + ' ';
                            y -= 34; // move up by font size + padding
                        } else {
                            line = testLine;
                        }
                    }
                    ctx.fillText(line, paddingLeft, y); // draw remaining text

                    canvas.toBlob(
                        (blob) => {
                            if (blob) resolve(blob);
                            else reject(new Error('Canvas produced null blob'));
                        },
                        'image/jpeg',
                        0.6
                    );

                } catch (err) {
                    reject(err);
                }
            };

            img.onerror = () => reject('Error loading image');
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

            this.loadLocationAddress();

            if(type){
                updateGeoLocation({ workOrderId: this.recordId, latitude: this.lat, longitude: this.long, activityType: type})
                .then(result => {
                    console.log('======updateGeoLocation======>', result);
                    if(type === 'Check Out'){
                        this.showtoast('Success', 'Images and payment details saved successfully!', 'success');
                        this.load = false;
                        history.back();
                        this.dispatchEvent(new CustomEvent('cancel'));
                    }
                })
                .catch(error => {
                    this.showtoast('Error', error, 'Error');
                })
            }

        }).catch(error => {
            console.error('Location error:', error);
            this.showtoast('Warning', 'Please enable your device location.', 'Warning');
        }).finally(() => {
            
        });
    }

    async loadLocationAddress() {
        if (this.lat == null || this.long == null) {
            this.locationText = '';
            return;
        }
        try {
            this.locationText = await getLocationFromCoOrdinates({
                lat: Number(this.lat), 
                lng: Number(this.long)
            });
            if(this.locationText == null){
                this.locationText = '';
            }
            console.log('Location text = ',this.locationText);
            
        } catch (error) {
            console.error('Reverse geocode failed', error);
            this.locationText = '';
        }
    }
}