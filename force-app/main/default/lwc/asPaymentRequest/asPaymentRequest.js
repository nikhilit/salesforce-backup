import { LightningElement, api } from 'lwc';

import getWorkOrderPaymentState from '@salesforce/apex/AS_PaymentModuleHandler.getWorkOrderPaymentState';
import payRequest from '@salesforce/apex/AS_PaymentModuleHandler.payRequest';
import checkStatus from '@salesforce/apex/AS_PaymentModuleHandler.checkStatus';
import cancelRequest from '@salesforce/apex/AS_PaymentModuleHandler.cancelRequest';
import updateGeoLocation from '@salesforce/apex/AS_PaymentModuleHandler.updateGeoLocation';
import sendSMS from '@salesforce/apex/AS_PaymentModuleHandler.sendSms';
import asReceiptLabel from "@salesforce/label/c.AS_ReceiptLabel";

import asGoCollectFlowLabel from "@salesforce/label/c.AS_GoCollectFlowLabel";
import asFieldSenseFlowLabel from "@salesforce/label/c.AS_FieldSenseFlowLabel";
import asStaticQrCode from "@salesforce/label/c.AS_StaticQrCode";
import asMaxPolling from "@salesforce/label/c.AS_PaymentPolling";

import mglLogo from '@salesforce/resourceUrl/MglLogo'; 

import qrcode from './qrCode.js'; 

import { NavigationMixin } from 'lightning/navigation';
import { getLocationService } from 'lightning/mobileCapabilities';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import FORM_FACTOR from '@salesforce/client/formFactor'; 
 
export default class AsPaymentRequest extends NavigationMixin (LightningElement) {

    @api recordId;
    @api payType = '';

    isLoading = false;
    showPayButton = false;
    showCheckStatusButton = false; 
    showPaidMessage = false;
    showQRcode = false;
    isPolling = false;
    showReceipt = false;
    isGoCollect = false;
    isFieldSense = false;
    isRandomVisit = false;
    isPaymentValidationDisabled = false;

    logo = mglLogo;

    transactionId = '';
    pdfReceiptUrl = '';
    invNumber = '';
    caNumber = '';
    bpNumber = '';
    amountPaid = 0;
    amountTotal = 0;
    customerName = '';
    qrCodeURI = '';
    
    lat = '';
    long = '';

    payTypeSelectedValue = ''; 
    payRemark = '';
    accountAlternatePhone = '';

    payTypeOptions = [
        { label: 'Full Payment', value: 'Full Payment' },
        { label: 'Partial Payment', value: 'Partial Payment' }
    ];

    label = { asReceiptLabel, asGoCollectFlowLabel, asFieldSenseFlowLabel, asStaticQrCode, asMaxPolling };
    
    connectedCallback() {
        this.initializeState();
    }

    initializeState() {

        console.log('=====initializeState===payType========>', this.payType);

        getWorkOrderPaymentState({ workOrderId: this.recordId })
        .then(result => {
            
            console.log('=====getWorkOrderPaymentState===result========>', result);

            if(result.workType){
                this.isGoCollect = this.label.asGoCollectFlowLabel.split(',').indexOf(result.workType.toLowerCase()) !== -1;
                this.isFieldSense = this.label.asFieldSenseFlowLabel.split(',').indexOf(result.workType.toLowerCase()) !== -1;
                this.caNumber = result.caNumber;
                this.bpNumber = result.bpNumber;
                this.invNumber = result.invNumber; 
                this.amountTotal = result.amountTotal;
                this.amountToBePaid = result.amountTotal;
                this.customerName = result.customerName;
                this.isRandomVisit = result.isRandomVisit;
                this.isPaymentValidationDisabled = result.isPaymentValidationDisabled;
            }

            if(this.isGoCollect){
                if (result.hasTransaction && result.hasP2PRequest) { // POS - Success

                    this.showPaidMessage = true;
                    this.transactionId = result.transactionId;
                    this.amountPaid = result.amountPaid;

                } else if (!result.hasTransaction && result.hasP2PRequest && result.qrCodeURI == '' && result.transactionId != null) { // POS - Status Check

                    this.showCheckStatusButton = true;

                } else if (!result.hasP2PRequest && result.qrCodeURI != '' && !result.hasTransaction) { // QR Code - Status Check

                    //this.generateQRCode(result.qrCodeURI);
                    this.qrCodeURI = 'data:image/png;base64,' + result.qrCodeURI;
                    console.log('=====this.qrCodeURI===result========>', this.qrCodeURI);

                    this.showQRcode = true;
                    this.showCheckStatusButton = true;

                } else if(!result.hasP2PRequest && result.qrCodeURI != '' && result.hasTransaction) { // QR Code - Success

                    this.showQRcode = false;
                    this.showCheckStatusButton = false;

                    this.showPaidMessage = true;
                    this.transactionId = result.transactionId;
                    this.amountPaid = result.amountPaid;

                } else { // Show Pay Button

                    this.showPayButton = true;
                    this.amountTotal = result.amountTotal;
                    this.amountToBePaid = result.amountTotal;

                }
            }else if(this.isFieldSense){
                if(FORM_FACTOR !== 'Large'){
                    this.isLoading = true;
                    this.getMobileLocation('Check In', '');
                }
                // this.showQRcode = true;
                // this.generateQRCode(this.generateQrCodeURI());
                // this.showPaidMessage = false;
            }

            if(this.showPaidMessage){
                this.pdfReceiptUrl = this.label.asReceiptLabel + this.recordId;
            }
        })
        .catch(error => {
            console.log('=====getWorkOrderPaymentState===error========>', JSON.stringify(error));
            this.showToast('Error', 'Failed to load payment state.', 'error');
        });
    }

    handlePay() {

        if(this.amountTotal == 0 || this.amountTotal === undefined){
            this.showToast('Error', 'Due amount is not available', 'error');
            return;
        }

        if(this.payTypeSelectedValue == '' || this.payTypeSelectedValue === undefined){
            this.showToast('Error', 'Payment Type is required', 'error');
            return;
        }

        this.isLoading = true;

        if(this.isGoCollect){

            this.amountTotal = this.amountToBePaid;

            payRequest({ 
                workOrderId: this.recordId, 
                payMode: this.payType, 
                amtToPay: parseFloat(this.amountToBePaid), 
                payType: this.payTypeSelectedValue,
                payRemark: this.payRemark })
            .then(result => {

                if (result.success) {

                    if(result.qrCodeUri != null){
                        this.qrCodeURI = 'data:image/png;base64,' + result.qrCodeUri;
                        this.showQRcode = true;
                    }else{
                        this.showToast('Success', result.message, 'success');
                    }

                    this.showPayButton = false;

                    this.showCheckStatusButton = false; 
                    this.startPollingStatus();
                } else {
                    this.showToast('Error', result.message, 'error');
                }
            })
            .catch(error => {

                console.log('=====payRequest===error========>', JSON.stringify(error));

                this.showToast('Error', error?.body?.message || 'Unexpected error.', 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
        }else{

            if(FORM_FACTOR !== 'Large'){
                this.isLoading = true;
                this.getMobileLocation('Check In', '');
            }
        }
    }

    handleCheckStatus() {
        this.isLoading = true;

        checkStatus({ workOrderId: this.recordId, payMode: this.payType })
        .then(result => {

            console.log('=====checkStatus===result========>', JSON.stringify(result));

            if (result.success) {

                if(result.customerReceiptUrl != ''){
                    this.showQRcode = false;
                }else{
                    this.showToast('Success', 'Payment Status: ' + result.message, 'success');
                }

                this.showCheckStatusButton = false;
                this.showPaidMessage = true;
                this.transactionId = result.txnId;
                this.amountPaid = result.amount;

                this.pdfReceiptUrl = this.label.asReceiptLabel + this.recordId;
                
            } else {
                this.showToast('Error', result.message, 'error');
            }
        })
        .catch(error => {

            console.log('=====checkStatus===error========>', JSON.stringify(error));

            this.showToast('Error', error?.body?.message || 'Failed to check status.', 'error');
        })
        .finally(() => {
            this.isLoading = false;
        });
    }

    handleResetPayment() {
        this.isLoading = true;

        cancelRequest({ workOrderId: this.recordId })
        .then(result => {

            console.log('=====cancelRequest===result========>', JSON.stringify(result));

            if (result) {
                this.showCheckStatusButton = false;
                this.showQRcode = false;
                this.showPayButton = true;
            } else {
                this.showToast('Error', 'Failed to reset payment: '+result, 'error');
            }
        })
        .catch(error => {

            console.log('=====cancelRequest===error========>', JSON.stringify(error));

            this.showToast('Error', error?.body?.message || 'Failed to reset payment.', 'error');
        })
        .finally(() => {
            this.isLoading = false;
        });
    }

    generateQRCode(result) {

        console.log('======generateQRCode=====result========>', result);

        setTimeout(() => {
            const qrCodeGenerated = new qrcode(0, 'H');
            qrCodeGenerated.addData(result);
            qrCodeGenerated.make();

            const element = this.template.querySelector(".qrcode2");

            console.log('======generateQRCode=====element========>', element);

            element.innerHTML = qrCodeGenerated.createSvgTag({
                scalable: false,
                cellSize: 2
            });
            if (element) {
                element.innerHTML = qrCodeGenerated.createSvgTag({});
            } else {
                console.error('Still no .qrcode2 element found in template!');
            }
        }, 0);
    }

    handlePayTypeChange(event) {
        this.payTypeSelectedValue = event.detail.value;
    }

    handlePayRemark(event){
        this.payRemark = event.detail.value;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant,
                mode: 'dismissable'
            })
        );
    }

    getMobileLocation(type, method) {

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

            updateGeoLocation({ workOrderId: this.recordId, latitude: this.lat, longitude: this.long, activityType: type})
            .then(result => {
                console.log('======updateGeoLocation======>', result);


                if(type === 'Check In' && this.isFieldSense){
                    this.showQRcode = true;
                    this.generateQRCode(this.generateQrCodeURI());
                    this.showPaidMessage = false;

                    this.isLoading = false;
                }

                if(method === 'handleCheckStatus'){
                    if(type === 'Check Out'){
                        if(result.customerReceiptUrl != ''){
                            this.showQRcode = false;
                        }else{
                            this.showToast('Success', 'Payment Status: ' + result.message, 'success');
                        }

                        this.showCheckStatusButton = false;
                        this.showPaidMessage = true;
                        this.transactionId = result.txnId;
                        this.amountPaid = result.amount;

                        this.pdfReceiptUrl = this.label.asReceiptLabel + this.recordId;
                    }
                }else if(method === 'startPollingStatus'){
                    if(type === 'Check Out'){
                        

                        clearInterval(this.pollingInterval);
                        this.pollingInterval = null;
                        this.isPolling = false; 

                        this.transactionId = result.txnId;
                        this.amountPaid = result.amount;
                        this.showQRcode = false;
                        this.showPaidMessage = true;
                        this.showCheckStatusButton = false;

                        this.pdfReceiptUrl = this.label.asReceiptLabel + this.recordId;
                        
                        this.showToast('Success', 'Payment confirmed automatically.', 'success');
                    }
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

    pollingInterval = null;
    pollingAttempts = 0;
    maxPollingAttempts = parseInt(this.label.asMaxPolling);

    startPollingStatus() {

        console.log('=====startPollingStatus===2========>');

        if (this.pollingInterval) {
            clearInterval(this.pollingInterval);
        }

        if(this.payType == 'M-POS') this.isPolling = true;
        
        this.pollingAttempts = 0;

        this.pollingInterval = setInterval(() => {
            this.pollingAttempts++;

            checkStatus({ workOrderId: this.recordId, payMode: this.payType })
            .then(result => {

                console.log('=====startPollingStatus===started========>');

                if (result.success) {

                    // if (FORM_FACTOR !== 'Large') {
                    //     this.getMobileLocation('Check Out', 'startPollingStatus');
                    // }else{
                        clearInterval(this.pollingInterval);
                        this.pollingInterval = null;
                        this.isPolling = false; 

                        this.transactionId = result.txnId;
                        this.amountPaid = result.amount;
                        this.showQRcode = false;
                        this.showPaidMessage = true;
                        this.showCheckStatusButton = false;

                        this.pdfReceiptUrl = this.label.asReceiptLabel + this.recordId;
                        
                        this.showToast('Success', 'Payment confirmed automatically.', 'success');
                    //}
                }
            })
            .catch(error => {
                clearInterval(this.pollingInterval);
                this.pollingInterval = null;
                this.isPolling = false;
                this.showToast('Error', 'Polling stopped due to an error.', 'error');
            });

            if (this.pollingAttempts >= this.maxPollingAttempts) {
                clearInterval(this.pollingInterval);
                this.pollingInterval = null;
                this.isPolling = false;
                this.showToast('Info', 'Payment not confirmed after waiting. You may check status manually.', 'info');
                this.showCheckStatusButton = true;
            }

        }, 10000); //  if 10s interval, poll for 1.5 minutes
    }

    disconnectedCallback() {
        if (this.pollingInterval) {
            clearInterval(this.pollingInterval);
            this.pollingInterval = null;
        }
    }

    generateQrCodeURI(){
        let uri = this.label.asStaticQrCode;
        
        uri = uri.replace('<CA_NUMBER>', this.caNumber);
        uri = uri.replaceAll('<INVOICE_NO>', this.invNumber);
        uri = uri.replace('<AMT>', this.amountTotal);

        return uri;
    }

    get isValidationDisabled(){
        return (this.isRandomVisit || this.isPaymentValidationDisabled);
    }

    isPayDisabled = false;

    handleAmountChange(event) {

        const input = event.target;
        const enteredValue = parseFloat(input.value);

        this.amountToBePaid = this.amountTotal;

        if(this.isRandomVisit || this.isPaymentValidationDisabled){
            input.setCustomValidity('');
            this.isPayDisabled = false;  // keep Pay button enabled
            this.amountToBePaid = enteredValue || 0; // just update input value
        }else{
            if (enteredValue) {
                if (enteredValue < this.amountToBePaid) {
                    input.setCustomValidity(`Amount must be at least ${this.amountToBePaid}`);
                    this.isPayDisabled = true;
                } else {
                    input.setCustomValidity('');
                    this.isPayDisabled = false;
                    this.amountToBePaid = enteredValue;
                }
            } else {
                input.setCustomValidity(`Amount must be at least ${this.amountToBePaid}`);
                this.isPayDisabled = true;
            }
        }
        
        input.reportValidity();
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
            this.showToast('Warning', 'Please Enter Phone Number!', 'wraning');
            return;
        }
        
        this.isLoading = true;

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