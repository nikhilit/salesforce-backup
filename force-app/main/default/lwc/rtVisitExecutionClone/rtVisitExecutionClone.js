import { LightningElement, api, track, wire } from 'lwc';
import { gql, graphql } from 'lightning/uiGraphQLApi'; 
import getAccountInfoFromSA from '@salesforce/apex/RTVisitExecutionController.getAccountInfoFromSA';
import saveChequeDetails from '@salesforce/apex/RTVisitExecutionController.saveChequeDetails';
import updateGeoLocation from '@salesforce/apex/RTVisitExecutionController.updateGeoLocation';
import savePdfFiles from '@salesforce/apex/RTVisitExecutionController.savePdfFiles';
import getBankDetailsByMicr from '@salesforce/apex/RTVisitExecutionController.getBankDetailsByMicr';
import getReceivables from '@salesforce/apex/RTVisitExecutionController.getReceivables';
import savePdfFile from '@salesforce/apex/RTVisitExecutionController.savePdfFile';
import getPreferencePicklistValues from '@salesforce/apex/RTVisitExecutionController.getPreferencePicklistValues';
import asGoCollectFlowLabel from "@salesforce/label/c.AS_GoCollectFlowLabel";
import asFieldSenseFlowLabel from "@salesforce/label/c.AS_FieldSenseFlowLabel";
import { NavigationMixin } from 'lightning/navigation';
import { getLocationService } from 'lightning/mobileCapabilities';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import FORM_FACTOR from '@salesforce/client/formFactor';
import fetchPaymentByBP from '@salesforce/apex/RTVisitExecutionController.fetchPaymentByBP';
import fetchBillByBP from '@salesforce/apex/RTVisitExecutionController.fetchBillByBP';
import fetchChequeBounceByBP from '@salesforce/apex/RTVisitExecutionController.fetchChequeBounceByBP'
import sendSMS from '@salesforce/apex/AS_PaymentModuleHandler.sendSms';
import sendSmsCheque from '@salesforce/apex/AsPdcRequestedController.sendSms';
import asReceiptLabel from "@salesforce/label/c.AS_ReceiptLabel";

import WORKTYPE_NAME_FIELD from '@salesforce/schema/WorkOrder.WorkType.Name';
import CHECK_IN_DATE_FIELD from "@salesforce/schema/WorkOrder.Check_In_Date_Time__c";
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { createRecord, updateRecord } from 'lightning/uiRecordApi';
import userId from '@salesforce/user/Id';
import userNameField from '@salesforce/schema/User.Name';

// Schema Imports for Offline Saving
import PAYMENT_OBJECT from '@salesforce/schema/Payment__c';
import PAY_WORK_ORDER_FIELD from '@salesforce/schema/Payment__c.Work_Order__c';
import PAY_BP_FIELD from '@salesforce/schema/Payment__c.Business_Partner__c';
import PAY_AMOUNT_FIELD from '@salesforce/schema/Payment__c.Cheque_Amount__c';
import PAY_DATE_FIELD from '@salesforce/schema/Payment__c.Cheque_Date__c';
import PAY_MODE_FIELD from '@salesforce/schema/Payment__c.Payment_Mode__c';
import PAY_CHEQUE_NO_FIELD from '@salesforce/schema/Payment__c.Cheque_Number__c';
import PAY_BANK_FIELD from '@salesforce/schema/Payment__c.Bank_Name__c';
import PAY_BRANCH_FIELD from '@salesforce/schema/Payment__c.Branch_Name__c';
import PAY_MICR_FIELD from '@salesforce/schema/Payment__c.MICR_Code__c';
import PAY_CA_FIELD from '@salesforce/schema/Payment__c.CA_Number__c';

import WO_ID_FIELD from '@salesforce/schema/WorkOrder.Id';
import WO_AMOUNT_REC_FIELD from '@salesforce/schema/WorkOrder.Amount_Received__c';
import WO_STATUS_FIELD from '@salesforce/schema/WorkOrder.Status';
import WO_CHECKOUT_TIME_FIELD from '@salesforce/schema/WorkOrder.Check_Out_Date_Time__c';

// Schema for Files
import CV_OBJECT from '@salesforce/schema/ContentVersion';
import CV_TITLE_FIELD from '@salesforce/schema/ContentVersion.Title';
import CV_PATH_FIELD from '@salesforce/schema/ContentVersion.PathOnClient';
import CV_DATA_FIELD from '@salesforce/schema/ContentVersion.VersionData'; // Base64 field
import CV_BP_FIELD from '@salesforce/schema/ContentVersion.BP_Number__c';

import CDL_OBJECT from '@salesforce/schema/ContentDocumentLink';
import CDL_LINKED_ENTITY_FIELD from '@salesforce/schema/ContentDocumentLink.LinkedEntityId';
import CDL_CONTENT_DOC_FIELD from '@salesforce/schema/ContentDocumentLink.ContentDocumentId';
import CDL_SHARE_TYPE_FIELD from '@salesforce/schema/ContentDocumentLink.ShareType';
import CDL_VISIBILITY_FIELD from '@salesforce/schema/ContentDocumentLink.Visibility';

export default class RTVisitExecutionClone extends NavigationMixin(LightningElement) {
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
    @track paymentHistory = []; 
    @track accountPhone='';
    accountAlternatePhone;

    @track ifChecked=false;
    @track isLoading=false;
    noOfPhotos = 1;

    isCheckInDateAvailable = false;

    label = { asGoCollectFlowLabel, asFieldSenseFlowLabel, asReceiptLabel };
    isGoCollect = false;
    isFieldSense = false;
    isRandomVisit = false;

    isOpenDueAmt = false;
    chevronClassDueAmt = 'slds-accordion__section slds-is-open';
    isOpenLastPay = false;
    chevronClassLastPay = 'slds-accordion__section slds-is-open';
    isOpenLastBill = false;
    chevronClassLastBill = 'slds-accordion__section slds-is-open';
    isLastChequeBounce = false;
    chevronClassLastBill = 'slds-accordion__section slds-is-open';
    
    billing = [];
    payment = [];

    workOrderType = '';
    currentUserName
    textToAddTop = '';
    lat = '';
    long = '';

    remarks = '';
    otherRemarks = '';
    pdfReceiptUrl = '';
    showPaidMessage = false;

    // OFFLINE STATE TRACKING
    isOnline = navigator.onLine;

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

    // =========================================================================
    // GRAPHQL QUERY FOR OFFLINE DATA
    // =========================================================================
    get graphQLQuery() {
        if (!this.recordId) return undefined;
        return gql`
            query getOfflineData($recordId: ID) {
                uiapi {
                    query {
                        WorkOrder(where: { Id: { eq: $recordId } }) {
                            edges {
                                node {
                                    Id
                                    WorkType { Name { value } }
                                    Customer_Full_Name__c { value }
                                    Due_Amount__c { value }
                                    Customer_CA_Number__c { value }
                                    X0_30__c { value }
                                    X31_60__c { value }
                                    X61_90__c { value }
                                    X91_180__c { value }
                                    X181_365__c { value }
                                    X1_2YR__c { value }
                                    X2_3YR__c { value }
                                    B4DUE__c { value }
                                    NOTDUE__c { value }
                                    New_Mobile_Number__c { value }
                                    Customer_BP_Number__c { value }
                                    CA_Number__c { value }
                                    Building_Name__c { value }
                                    New_Floor__c { value }
                                    New_Flat__c { value }
                                    New_Wing__c { value }
                                    New_Colony__c { value }
                                    Check_In_Date_Time__c { value }
                                    Status { value }
                                    Check_Out_Date_Time__c { value }
                                    Follow_up_Date__c { value }
                                    Amount_Received__c { value }
                                    Payment_Mode__c { value }
                                    Disconnection_Notice_No__c { value }
                                    Disconnection_Notice_Date__c { value }
                                    Follow_up_Remarks__c { value }
                                    Account {
                                        Id
                                        Name { value }
                                        Phone { value }
                                        Secondary_Telephone__c { value }
                                        Account_Email__c { value }
                                        Account_Type__c { value }
                                        Type { value }
                                        MRU_Code__c { value }
                                        BP_Number__c { value }
                                        CA_Number__c { value }
                                        Building_name__c { value }
                                        Street__c { value }
                                        Colony__c { value }
                                        Wing__c { value }
                                        Floor__c { value }
                                        Flat__c { value }
                                        Road_name__c { value }
                                        Inv_No__c { value }
                                        Portion__c { value }
                                        BillingPostalCode { value }
                                        Location__c { value }
                                        Email_Id__c { value }
                                        Full_Name__c { value }
                                        Room__c { value }
                                    }
                                }
                            }
                        }
                        ServiceAppointment(where: { ParentRecordId: { eq: $recordId } }, orderBy: { CreatedDate: { order: DESC } }, first: 5) {
                            edges {
                                node {
                                    Id
                                    SchedStartTime { value }
                                    SchedEndTime { value }
                                    FollowUpRemarks__c { value }
                                    Appointment_Type__c { value }
                                    Status { value }
                                    Other_Follow_Up_Remark__c { value }
                                    Random_Visit_Date__c { value }
                                }
                            }
                        }
                        Payment__c(where: { Work_Order__c: { eq: $recordId } }, orderBy: { Payment_Date__c: { order: DESC } }, first: 3) {
                            edges {
                                node {
                                    Id
                                    Transaction_Id__c { value }
                                    Amount_Paid__c { value }
                                    Payment_Mode__c { value }
                                    Bank_Name__c { value }
                                    Payment_Date__c { value }
                                }
                            }
                        }
                    }
                }
            }
        `;
    }

    get graphQLVariables() {
        return {
            recordId: this.recordId
        };
    }

    // Wire GraphQL to prime the cache and be available offline
    @wire(graphql, { query: '$graphQLQuery', variables: '$graphQLVariables' })
    wiredGraphQLData(result) {
        this.graphqlResult = result; // Store full result to access data
        const { data, errors} = result;
        if (data && !this.isOnline) {
             // If data arrived and we are offline, populate immediately
             this.handleOfflineDataLoad(data);
        } else if (errors) {
            console.error('GraphQL Error:', errors);
        }
    }

    connectedCallback() {
        // Register online/offline listeners
        window.addEventListener('online', this.handleNetworkChange);
        window.addEventListener('offline', this.handleNetworkChange);

        this.setPhotoUploadSlots();
        this.fetchPreferences();

        this.textToAddTop = `${this.currentUserName}\n${this.formatDateTime(new Date())}`;

        // HYBRID LOGIC:
        if (this.isOnline) {
             if (this.recordId) {
                this.fetchAccountInfo(); // Use Existing Apex Mechanism
            }
        } else {
             // Try to load from GraphQL Cache immediately if we already have it
             if(this.graphqlResult && this.graphqlResult.data){
                 this.handleOfflineDataLoad(this.graphqlResult.data);
             } else {
                 console.log('Offline: Waiting for GraphQL data...');
             }
        }
    }

    disconnectedCallback() {
        window.removeEventListener('online', this.handleNetworkChange);
        window.removeEventListener('offline', this.handleNetworkChange);
    }

    handleNetworkChange = () => {
        this.isOnline = navigator.onLine;
        if (this.isOnline) {
            console.log('App is Online - Switching to Live Data');
            this.fetchAccountInfo();
        } else {
            console.log('App is Offline - Switching to Cached Data');
            if(this.graphqlResult && this.graphqlResult.data){
                 this.handleOfflineDataLoad(this.graphqlResult.data);
            }
        }
    }

    // Helper to process GraphQL data into the structure your HTML expects
    handleOfflineDataLoad(data) {
        console.log('Loading Offline Data via GraphQL...');
        try {
            const woEdge = data.uiapi.query.WorkOrder.edges[0];
            if (!woEdge) return;

            const woNode = woEdge.node;
            
            // 1. Map WorkOrder and Account (Flattening structure: { value: 'x' } -> 'x')
            this.workOrder = this.flattenNode(woNode);
            this.account = this.flattenNode(woNode.Account);
            this.accountId = this.account.Id;

            this.accountPhone = this.workOrder.New_Mobile_Number__c != null ? this.workOrder.New_Mobile_Number__c : this.account.Phone;
            
            // Override fields similar to Apex logic
            this.account.BP_Number__c = this.workOrder.BP_Number__c || this.account.BP_Number__c;
            this.account.CA_Number__c = this.workOrder.CA_Number__c || this.account.CA_Number__c;
            this.account.Building_name__c = this.workOrder.Building_Name__c || this.account.Building_name__c;
            this.account.Floor__c = this.workOrder.New_Floor__c || this.account.Floor__c;
            this.account.Room__c = this.workOrder.New_Flat__c || this.account.Room__c;
            this.account.Wing__c = this.workOrder.New_Wing__c || this.account.Wing__c;
            this.account.Colony__c = this.workOrder.New_Colony__c || this.account.Colony__c;

            // 2. Map Service Appointment
            const saEdges = data.uiapi.query.ServiceAppointment.edges;
            if (saEdges.length > 0) {
                this.serviceAppointment = this.flattenNode(saEdges[0].node);
                this.isRandomVisit = this.serviceAppointment.Random_Visit_Date__c != null;

                // Handle Remarks logic
                if (saEdges.length > 1) {
                     // Simple offline logic: just check the first few available in cache
                     const val = saEdges.map(e => this.flattenNode(e.node)).filter(obj => {
                        return obj.FollowUpRemarks__c;
                     });
                     if(val.length && val[0].Appointment_Type__c == 'Completed' && val[0].Status == 'Completed'){
                        this.remarks = val[0].FollowUpRemarks__c;
                        this.otherRemarks = val[0].Other_Follow_Up_Remark__c;
                     }
                }
            }

            // 3. Map Payments
            const payEdges = data.uiapi.query.Payment__c.edges;
            this.payment = payEdges.map(edge => this.flattenNode(edge.node));
            this.paymentHistory = this.payment;

            // 4. Set Flags
            if(this.workOrder.WorkType && this.workOrder.WorkType.Name){
                this.isGoCollect = this.label.asGoCollectFlowLabel.split(',').indexOf(this.workOrder.WorkType.Name.toLowerCase()) !== -1;
                this.isFieldSense = this.label.asFieldSenseFlowLabel.split(',').indexOf(this.workOrder.WorkType.Name.toLowerCase()) !== -1;
            }

            this.caNumber = this.workOrder.Customer_CA_Number__c;
            this.chequeAmount = this.workOrder.Due_Amount__c;

            // External data (Bills, Cheque Bounce) cannot be fetched offline from SAP
            // We set them to empty arrays so the UI doesn't crash
            this.billing = []; 
            this.chequeBounceHistory = [];
            
            this.accountDetails = true;
            this.load = false; // Stop spinner
            this.isLoading = false;

        } catch(e) {
            console.error('Error parsing Offline GraphQL data', e);
        }
    }

    // Utility to flatten GraphQL result { Field: { value: "val" } } -> { Field: "val" }
    flattenNode(node) {
        if (!node) return null;
        let flat = {};
        for (let key in node) {
            if (node[key] && typeof node[key] === 'object' && 'value' in node[key]) {
                flat[key] = node[key].value;
            } else if (key === 'WorkType' && node[key]) {
                 flat[key] = { Name: node[key].Name.value, displayValue: node[key].Name.value }; // Handle Relation manually if needed
            } else if (key !== 'Account') {
                flat[key] = node[key];
            }
        }
        return flat;
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
        }else if (sectionName === 'Last3ChequeBounce'){
            this.isLastChequeBounce = !this.isLastChequeBounce;
            this.chevronClassCheque = this.isLastChequeBounce ? 'slds-accordion__section slds-is-open' : 'slds-accordion__section slds-is-close bottom';
        }
        else if (sectionName === 'Last3Receivables') {   // ✅ missing case
        this.isOpenLastReceivable = !this.isOpenLastReceivable;
            this.chevronClassLastReceivable = this.isOpenLastReceivable
            ? 'slds-accordion__section slds-is-open'
            : 'slds-accordion__section slds-is-close bottom';
        }
    }

    get maskedPhNo(){
        return this.accountPhone != null && this.accountPhone != '' && this.accountPhone != 0 ? this.maskNumber(this.accountPhone) : '';
    }

    maskNumber(value) {
        if(value){  
            const unmaskedDigits = 4;
            const maskedPart = '*'.repeat(value.length - unmaskedDigits);
            const unmaskedPart = value.slice(-unmaskedDigits);
            return (maskedPart + unmaskedPart);
        }
    }

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
                
               this.fetchPaymentHistory(data.workOrder.Customer_BP_Number__c);
                this.fetchChequeBounceHistory(data.workOrder.Customer_BP_Number__c);

                this.accountDetails = true;

                console.log('========this.data.serviceAppointments=======>', data.serviceAppointments);
                if (data.serviceAppointments && data.serviceAppointments.length > 0) {
                    this.serviceAppointment = data.serviceAppointments[0];
                    this.isRandomVisit = this.serviceAppointment.Random_Visit_Date__c != null;
                }
                console.log('========this.isRandomVisit=======>', this.isRandomVisit);
                this.workOrder = data.workOrder;

                //this.billing = data.billing;

                //this.fetchBillHistory(data.workOrder.Customer_BP_Number__c, this.getPreviousThreeMonthsRange().startDate, this.getPreviousThreeMonthsRange().endDate);
                this.fetchBillHistory(data.workOrder.Customer_BP_Number__c, '20091101', this.getTodayAsYYYYMMDD());
                this.billing.filter(el=>{
                    el.checked=false;
                    el.disabled=false;
                    return el;
                })
                this.payment = data.payment;
                this.paymentHistory = this.payment

                console.log('Payment history ===> ',this.payment);
                if(data.workOrder.WorkType && data.workOrder.WorkType.Name){
                    this.isGoCollect = this.label.asGoCollectFlowLabel.split(',').indexOf(data.workOrder.WorkType.Name.toLowerCase()) !== -1;
                    this.isFieldSense = this.label.asFieldSenseFlowLabel.split(',').indexOf(data.workOrder.WorkType.Name.toLowerCase()) !== -1;
                }

                this.error = null;
                this.caNumber = this.workOrder.Customer_CA_Number__c;
                this.chequeAmount = this.workOrder.Due_Amount__c;

                const serviceAppointments = data.serviceAppointments;
                if(serviceAppointments.length > 1){
                    const keyToCheck = "FollowUpRemarks__c";
                    const val = serviceAppointments.filter(obj => {
                        const value = obj[keyToCheck];
                        return value !== null && value !== undefined && value !== "";
                    });
                    if(val.length && val[0].FollowUpRemarks__c != null && val[0].Appointment_Type__c == 'Completed' && val[0].Status == 'Completed'){
                        this.remarks = val[0].FollowUpRemarks__c;
                        this.otherRemarks = val[0].Other_Follow_Up_Remark__c;
                    }
                }

                this.isLoading = false;
            })
        .catch(error => {
            this.isLoading = false;
            console.log('error::'+JSON.stringify(error));
            this.showToast('Error', error?.body?.message || 'Failed to get account details.', 'error');
        });
    }
    
    get formattedVisitDateTime() {
        if (this.serviceAppointment?.SchedEndTime) {
            const dt = new Date(this.serviceAppointment.SchedEndTime);
            const date = dt.toLocaleDateString('en-GB');
            const time = dt.toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit' });
            return `${date}`;
        }
        return '';
    }

    get formattedFollowUpDate() {
        if (this.workOrder?.Follow_up_Date__c) {
            const dt = new Date(this.workOrder.Follow_up_Date__c);
            const date = dt.toLocaleDateString('en-GB');
            return `${date}`;
        }
        return '';
    }

    get formattedDisconnectionDate() {
        if (this.workOrder?.Disconnection_Notice_Date__c) {
            const dt = new Date(this.workOrder.Disconnection_Notice_Date__c);
            const date = dt.toLocaleDateString('en-GB');
            return `${date}`;
        }
        return '';
    }

    handleTakeReading() {
        if(this.workOrderType.toLowerCase() === 'payment collection(i&c)' || this.workOrderType.toLowerCase() === 'payment collection(r&t)'){ 
            if (FORM_FACTOR !== 'Large') {
                this.getMobileLocation('Check In');
            }else{
                // this.showSelectPaymentMethodScreen = true;
                // this.accountDetails = false;
                this.validation();
            }
        }else{
            // this.showSelectPaymentMethodScreen = true;
            // this.accountDetails = false;
            this.validation();
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

        if (!this.isOnline) {
            this.handleOfflineSubmit();
            return;
        }

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

    handleOfflineSubmit() {
        console.log('Submitting Cheque Payment & Images (Offline Mode)...');

        // 1. Prepare Payment Record
        const paymentFields = {};
        paymentFields[PAY_WORK_ORDER_FIELD.fieldApiName] = this.recordId;
        paymentFields[PAY_BP_FIELD.fieldApiName] = this.accountId;
        paymentFields[PAY_AMOUNT_FIELD.fieldApiName] = this.chequeAmount;
        paymentFields[PAY_DATE_FIELD.fieldApiName] = this.chequeDate;
        paymentFields[PAY_MODE_FIELD.fieldApiName] = 'Cheque';
        paymentFields[PAY_CHEQUE_NO_FIELD.fieldApiName] = this.chequeNumber;
        paymentFields[PAY_BANK_FIELD.fieldApiName] = this.bankName;
        paymentFields[PAY_BRANCH_FIELD.fieldApiName] = this.branchName;
        paymentFields[PAY_MICR_FIELD.fieldApiName] = this.micrCode;
        paymentFields[PAY_CA_FIELD.fieldApiName] = this.caNumber;

        const recordInput = { apiName: PAYMENT_OBJECT.objectApiName, fields: paymentFields };

        // 2. Create Payment__c
        createRecord(recordInput)
            .then(payment => {
                console.log('Offline Payment Draft Created:', payment.id);

                // 3. Create ContentVersions (Images)
                // We use Promise.all to ensure all images are queued before moving on
                const imagePromises = this.photoUploadSlots.map((slot, index) => {
                    if (!slot.base64Data) return Promise.resolve();

                    const cvFields = {};
                    cvFields[CV_TITLE_FIELD.fieldApiName] = `Cheque_Image_${this.chequeNumber}_${index + 1}`;
                    cvFields[CV_PATH_FIELD.fieldApiName] = `Cheque_Image_${this.chequeNumber}_${index + 1}.jpg`;
                    cvFields[CV_DATA_FIELD.fieldApiName] = slot.base64Data; // Base64 string
                    cvFields[CV_BP_FIELD.fieldApiName] = this.account.BP_Number__c; 
                    // Note: In offline mode, FirstPublishLocationId is often used to link immediately. 
                    // If not supported, we rely on server-side triggers or CDL creation below.
                    // For SFS Offline, linking to WorkOrder (recordId) is the most robust method.
                    cvFields['FirstPublishLocationId'] = this.recordId; 

                    const cvRecordInput = { apiName: CV_OBJECT.objectApiName, fields: cvFields };
                    return createRecord(cvRecordInput);
                });

                return Promise.all(imagePromises);
            })
            .then((results) => {
                console.log('Offline Images Queued:', results.length);

                // 4. Update WorkOrder Status and Amount
                const woFields = {};
                woFields[WO_ID_FIELD.fieldApiName] = this.recordId;
                woFields[WO_STATUS_FIELD.fieldApiName] = 'Completed';
                woFields[WO_CHECKOUT_TIME_FIELD.fieldApiName] = new Date().toISOString();
                
                const currentAmount = this.workOrder.Amount_Received__c ? parseFloat(this.workOrder.Amount_Received__c) : 0;
                const newAmount = parseFloat(this.chequeAmount);
                woFields[WO_AMOUNT_REC_FIELD.fieldApiName] = currentAmount + newAmount;

                const woRecordInput = { fields: woFields };

                return updateRecord(woRecordInput);
            })
            .then(() => {
                this.load = false;
                this.showToast('Success', 'Payment & Images saved to offline queue.', 'success');
                history.back();
            })
            .catch(error => {
                this.load = false;
                console.error('Offline Submit Error:', error);
                this.showToast('Error', 'Failed to save offline data: ' + (error.body?.message || error.message), 'error');
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
            .then(result => 
            {
                console.log('======updateGeoLocation======>', result);

                if(type === 'Check Out'){
                    this.showToast('Success', 'Cheque payment details saved.', 'success');
                    console.log('Payment ID:', paymentId);
                    history.back();
                }else{

                    this.validation();
                    
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

    validation(){ 
        const isCheckInDateAvailable = this.workOrder.Check_In_Date_Time__c != null;
        const isWorkOrderCompleted = this.workOrder.Status == 'Completed';
        const isCheckOutDateAvailable = this.workOrder.Check_Out_Date_Time__c != null;

        const isFollowUp = this.workOrder.Follow_up_Remarks__c != null;
        const isPaymentReceived = this.workOrder.Amount_Received__c != null;
        this.paymentMode = this.workOrder.Payment_Mode__c;
        
        if(!isFollowUp && (isCheckInDateAvailable && isWorkOrderCompleted && isCheckOutDateAvailable) || (isWorkOrderCompleted && this.paymentMode == 'Directly Paid by Customer')){
            this.showEnableMessage = true;
            this.message = 'Task is already completed. Please refresh the WorkOrder page to continue.';
            if(isPaymentReceived){
                if(this.paymentMode == 'Cheque'){
                    this.pdfReceiptUrl = this.label.asReceiptLabel + this.recordId + '&mode=' + this.paymentMode;
                }else if(this.paymentMode == 'QR Code' || this.paymentMode == 'M-POS'){
                    this.pdfReceiptUrl = this.label.asReceiptLabel + this.recordId;
                }
                this.showPaidMessage = true;
            }else{
                this.showPaidMessage = false;
            }
        }else if(!isCheckInDateAvailable && !isWorkOrderCompleted){
            this.showEnableMessage = true;
            this.message = 'Check-In is required. Please Check-In and refresh the WorkOrder page to continue.';
        }else{
            this.showEnableMessage = false;

            this.showSelectPaymentMethodScreen = true;
        }
        this.accountDetails = false;
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
            } 
            else {
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

        const billDate = this.getFormattedBLDAT(this.printDocNum);
        savePdfFiles({		
            billPrintNumbers: this.printDocNum,		
            billDate: billDate,		
            phoneNumber:this.accountPhone,		
            accountName:this.account.Name,		
            preference:this.selectedPreference,		
            workOrderId:this.recordId })
        .then((publicUrls) => {
            this.isLoading = false;
 
            if (publicUrls=='Success') {
                this.showToast('Success','PDF sent to customer', 'success');
                console.log('PDF URLs:', publicUrls); 
            } 
            else if(publicUrls=='Error'){
                this.showToast('Error','No Pdf found for this Bill Number', 'error');
            }
            else {
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
        return this.paymentHistory || [];
    }

    get last3ChequeBounce(){
        return this.chequeBounceHistory || [];
    }

    handleCancel() {
        history.back();
    }

    fetchPaymentHistory(bpNumber) {
        if (!bpNumber) {
            console.log('No BP number available');
            this.paymentHistory = [];
            return;
        }

        fetchPaymentByBP({ bpNumber: bpNumber })
        .then(result => {
            console.log('Payment API response:', JSON.stringify(result));
            this.paymentHistory = result || [];
        })
        .catch(error => {
            console.error('Error fetching payment history:', error);
          
            this.paymentHistory = [];
            //const errorMessage = error?.body?.errorMessage || 'Unknown Error';
            //this.showToast('Error', `Error: ${errorMessage}` , 'error');
            this.showToast('Warning', 'Unable to fetch payment history', 'warning');
        });
    }

    //Fetch cheque bounce history
    fetchChequeBounceHistory(bpNumber) {
        
        if (!bpNumber) {
            console.log('No BP number available');
            this.chequeBounceHistory = [];
            return;
        }
        
        fetchChequeBounceByBP({ bpNumber: bpNumber })
          .then(result => {
            console.log('ChequeBounce response:', JSON.stringify(result));

            // Format date values
            this.chequeBounceHistory = result.map(record => {
                let formattedRecord = { ...record }; 

                Object.keys(formattedRecord).forEach(key => {
                    if (key.toLowerCase().includes('date')) {
                        formattedRecord[key] = this.formatToDDMMYYYY(formattedRecord[key]);
                    }
            
                });

                return formattedRecord;
            });
        })
        .catch(error => {
            console.error('Error fetching history:', JSON.stringify(error));
            this.chequeBounceHistory = [];
            this.showToast('Warning', 'Unable to fetch cheque bounce history', 'warning');
 
       });
    }
    
    fetchBillHistory(bpNumber, fromDate, toDate) {
        console.log('fetchBillHistory');
        console.log('bpNumber: '+bpNumber);
        console.log('fromDate: '+fromDate);
        console.log('toDate: '+toDate);

        if (!bpNumber) {
            console.log('No BP number available');
            this.billing = [];
            return;
        }

        fetchBillByBP({ bpNumber: bpNumber, fromDate: fromDate, toDate: toDate })
        .then(result => {

            result.sapData = result.sapData.map(item => {
                return {
                    ...item,
                  
                    BLDAT: this.formatToDDMMYYYY(item.BLDAT)
                };
            });

            // Sort sapData by BUDATE
            this.billing = (result.sapData || []).sort((a, b) => {
                const dateA = new Date(a.BUDAT.replace(/-/g, '/')); 
            
                const dateB = new Date(b.BUDAT.replace(/-/g, '/')); 
                return dateB - dateA; // ascending (earliest first)
            });

            this.billing = this.billing.slice(0, 3);
        })
        .catch(error => {
            console.error('Error fetching billing history:', JSON.stringify(error));
      
            this.billing = [];
            this.showToast('Warning', 'Unable to fetch bill history', 'warning');
        });
    }

    cleanAmount(value) {
        if (!value) return '';
        // Remove any leading '-' and trim spaces
        return value.replace(/^-+\s*/, '').trim();
    }

    getFormattedBLDAT(opbelValue) {
        if (!this.billing || !Array.isArray(this.billing)) return '';
        const record = this.billing.find(item => item.OPBEL === opbelValue);
        if (!record || !record.BLDAT) return '';
        return record.BLDAT;
    }

    formatToDDMMYYYY(dateStr) {
        if (!dateStr) return '';
        const date = new Date(dateStr);
        const day = String(date.getDate()).padStart(2, '0');
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const year = date.getFullYear();
        return `${day}/${month}/${year}`;
    }

    getTodayAsYYYYMMDD() {
        const today = new Date();
        const yyyy = today.getFullYear();
        const mm = String(today.getMonth() + 1).padStart(2, '0');
        const dd = String(today.getDate()).padStart(2, '0');
        return `${yyyy}${mm}${dd}`;
    }

    zoomLevel = 1;
    minZoom = 0.5;
    maxZoom = 3;
    offsetX = 0;
    offsetY = 0;
    // pinch start bookkeeping
    startDistance = 0;
    startZoom = 1;
    startOffsetX = 0;
    startOffsetY = 0;
    // pan start bookkeeping
    isDragging = false;
    startPanClientX = 0;
    startPanClientY = 0;

    listenersAttached = false;
    container;
    wrapper;

    renderedCallback() {
        // If PDF section isn't shown, skip
        if (!this.showPdfPage) return;
        this.container = this.template.querySelector('.pdf-scroll-container');
        this.wrapper = this.template.querySelector('.pdf-zoom-wrapper');

        if (!this.container || !this.wrapper) return;
        // Always clean old listeners before reattaching
        this.container.ontouchstart = null;
        this.container.ontouchmove = null;
        this.container.ontouchend = null;

        // Re-attach listeners freshly each time
        this.container.addEventListener('touchstart', this.handleTouchStart.bind(this), { passive: false });
        this.container.addEventListener('touchmove', this.handleTouchMove.bind(this), { passive: false });
        this.container.addEventListener('touchend', this.handleTouchEnd.bind(this));

        // Reset transform state each time the PDF opens
        this.resetTransform();
    }

    resetTransform() {
        this.zoomLevel = 1;
        this.offsetX = 0;
        this.offsetY = 0;
        this.applyTransform();
    }

    goBack() {
        this.resetTransform();
        this.showPdfPage = false;
        this.pdfUrl = '';
    }

    getDistance(touches) {
        const dx = touches[0].clientX - touches[1].clientX;
        const dy = touches[0].clientY - touches[1].clientY;
        return Math.sqrt(dx * dx + dy * dy);
    }

    getTouchCenter(touches) {
        const rect = this.container.getBoundingClientRect();
        const x = (touches[0].clientX + touches[1].clientX) / 2 - rect.left;
        const y = (touches[0].clientY + touches[1].clientY) / 2 - rect.top;
        return { x, y };
    }

    clamp(v, a, b) {
        return Math.min(Math.max(v, a), b);
    }

    handleTouchStart(event) {
        if (event.touches.length === 2) {
            // Start pinch
            event.preventDefault();
            this.startDistance = this.getDistance(event.touches);
            this.startZoom = this.zoomLevel;
            this.startOffsetX = this.offsetX;
            this.startOffsetY = this.offsetY;
            // store pinch center at start (relative to container)
            const center = this.getTouchCenter(event.touches);
            this.startPinchCenterX = center.x;
            this.startPinchCenterY = center.y;
        } else if (event.touches.length === 1 && this.zoomLevel > 1) {
            // Start pan (only allow panning when zoomed > 1)
            event.preventDefault();
            this.isDragging = true;
            this.startPanClientX = event.touches[0].clientX - this.offsetX;
            this.startPanClientY = event.touches[0].clientY - this.offsetY;
        }
    }

    handleTouchMove(event) {
        // Pinch-to-zoom
        if (event.touches.length === 2) {
            event.preventDefault();
            const newDistance = this.getDistance(event.touches);
            if (this.startDistance === 0) return;

            const scale = newDistance / this.startDistance;
            let newZoom = this.startZoom * scale;
            newZoom = this.clamp(newZoom, this.minZoom, this.maxZoom);
            // Use current pinch center (so it tracks fingers)
            const center = this.getTouchCenter(event.touches);
            // Adjust offsets so zoom centers around the pinch point using startOffset values
            // formula: offset = center - (center - startOffset) * (newZoom / startZoom)
            this.offsetX = center.x - (center.x - this.startOffsetX) * (newZoom / this.startZoom);
            this.offsetY = center.y - (center.y - this.startOffsetY) * (newZoom / this.startZoom);

            this.zoomLevel = newZoom;
            this.applyTransform();
            return;
        }

        // Pan when single touch and dragging enabled
        if (this.isDragging && event.touches.length === 1) {
            event.preventDefault();
            this.offsetX = event.touches[0].clientX - this.startPanClientX;
            this.offsetY = event.touches[0].clientY - this.startPanClientY;
            this.applyTransform();
        }
    }

    handleTouchEnd(event) {
        // Reset pinch bookkeeping if less than 2 touches remain
        if (event.touches.length < 2) {
            this.startDistance = 0;
        }
        if (event.touches.length === 0) {
            this.isDragging = false;
        }

        // Optional: clamp offsets here to keep content reasonably in view - add if needed
    }

    applyTransform() {
        if (!this.wrapper || !this.container) return;
        const containerRect = this.container.getBoundingClientRect();
        const contentWidth = containerRect.width * this.zoomLevel;
        const contentHeight = containerRect.height * this.zoomLevel;
        // --- Auto-recenter when near 1x zoom ---
        const NEAR_ONE = 0.99;
        // threshold for “almost original size”
        if (this.zoomLevel <= 1 && this.zoomLevel > NEAR_ONE) {
            this.offsetX = 0;
            this.offsetY = 0;
        } else {
            // --- Clamp offsets so content never leaves view ---
            const minX = containerRect.width - contentWidth;
            const minY = containerRect.height - contentHeight;

            // When content smaller than container, keep it centered
            if (contentWidth < containerRect.width) {
                this.offsetX = (containerRect.width - contentWidth) / 2;
            } else {
                this.offsetX = Math.min(0, Math.max(this.offsetX, minX));
            }

            if (contentHeight < containerRect.height) {
                this.offsetY = (containerRect.height - contentHeight) / 2;
            } else {
                this.offsetY = Math.min(0, Math.max(this.offsetY, minY));
            }
        }

        // --- Apply transform ---
        this.wrapper.style.transformOrigin = '0 0';
        this.wrapper.style.transform =
            `translate(${this.offsetX}px, ${this.offsetY}px) scale(${this.zoomLevel})`;
        this.wrapper.style.willChange = 'transform';
    }

    sendPayMsg() {
        
        if(this.accountAlternatePhone == ''){
            this.showToast('Warning', 'Please Enter Phone Number!', 'wraning');
            return;
        }
        
        this.isLoading = true;
        if(this.paymentMode == 'Cheque'){
            sendSmsCheque({ phoneNumber:this.accountAlternatePhone, workOrderId:this.recordId })
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
        }else{
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
}