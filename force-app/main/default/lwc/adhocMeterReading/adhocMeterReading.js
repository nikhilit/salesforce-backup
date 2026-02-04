/**
 * Ad-Hoc Appointment Component
 * Full parity online & offline
 * Online → Apex path
 * Offline → LDS: WorkOrder + ServiceAppointment + AssignedResource
 */
import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import FORM_FACTOR from '@salesforce/client/formFactor';

// LDS APIs
import { getObjectInfo, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import { createRecord, getRecords } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';

// WorkOrder fields
import WORKORDER_OBJECT from '@salesforce/schema/WorkOrder';
import WO_Subject from '@salesforce/schema/WorkOrder.Subject';
import WO_Status from '@salesforce/schema/WorkOrder.Status';
import WO_AccountId from '@salesforce/schema/WorkOrder.AccountId';
import WO_ContactId from '@salesforce/schema/WorkOrder.ContactId';
import WO_Phone__c from '@salesforce/schema/WorkOrder.Phone__c';
import WO_Customer_Identification_Type__c from '@salesforce/schema/WorkOrder.Customer_Identification_Type__c';
import WO_Customer_Identification_Value__c from '@salesforce/schema/WorkOrder.Customer_Identification_Value__c';
import WO_Customer_BP_Number__c from '@salesforce/schema/WorkOrder.Customer_BP_Number__c';
import WO_RecordTypeId from '@salesforce/schema/WorkOrder.RecordTypeId';
import WO_StartDate from '@salesforce/schema/WorkOrder.StartDate';
import WO_Scheduled_Date__c from '@salesforce/schema/WorkOrder.Scheduled_Date__c';
import WO_EndDate from '@salesforce/schema/WorkOrder.EndDate';
import WO_WorkOrderType__c from '@salesforce/schema/WorkOrder.Work_Order_Type__c';

// ServiceAppointment fields
import SA_OBJECT from '@salesforce/schema/ServiceAppointment';
import SA_ParentRecordId from '@salesforce/schema/ServiceAppointment.ParentRecordId';
import SA_Status from '@salesforce/schema/ServiceAppointment.Status';
import SA_SchedStartTime from '@salesforce/schema/ServiceAppointment.SchedStartTime';
import SA_SchedEndTime from '@salesforce/schema/ServiceAppointment.SchedEndTime';
import SA_ServiceTerritoryId from '@salesforce/schema/ServiceAppointment.ServiceTerritoryId';

// AssignedResource fields
import AR_OBJECT from '@salesforce/schema/AssignedResource';
import AR_ServiceAppointmentId from '@salesforce/schema/AssignedResource.ServiceAppointmentId';
import AR_ServiceResourceId from '@salesforce/schema/AssignedResource.ServiceResourceId';

// Briefcase objects
import SERVICERESOURCE_OBJECT from '@salesforce/schema/ServiceResource';
import SERVICETERRITORYLOCATION_OBJECT from '@salesforce/schema/ServiceTerritoryLocation';
import CONTACT_OBJECT from '@salesforce/schema/Contact';

// Apex (online path)
import getPicklistValuesApex from '@salesforce/apex/AdHocAppointmentController.getPicklistValues';
import getValidAccounts from '@salesforce/apex/AdHocAppointmentController.getValidAccounts';
import getAccountByIdentification from '@salesforce/apex/AdHocAppointmentController.getAccountByIdentification';
import createAdHocAppointmentApex from '@salesforce/apex/AdHocAppointmentController.createAdHocAppointment';

import { gql, graphql } from 'lightning/uiGraphQLApi';
const GET_SERVICE_RESOURCE = gql`
query getServiceResource($userId: ID!) {
  uiapi {
    query {
      ServiceResource(where: { RelatedRecordId: { eq: $userId } }, first: 1) {
        edges {
          node {
            Id
            Name { value }
            ServiceTerritories {
              edges {
                node {
                  ServiceTerritory {
                    Id
                    Name { value }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}`;

const isOnline = () => (typeof navigator !== 'undefined' ? navigator.onLine : true);

export default class AdHocAppointment extends NavigationMixin(LightningElement) {
    @track identificationOptions = [];
    @track selectedIdentificationType = '';
    @track identificationValue = '';
    @track phoneNumber = '';
    @track selectedAccountId = null;
    @track isLoading = false;
    @track error;
    @track successMessage;
    category;
    @track accountKey = 0;


    @track myServiceResourceId;
    @track myServiceTerritoryId;
    accountContactsMap = {};

    // ===== Picklists via LDS =====
    @wire(getObjectInfo, { objectApiName: WORKORDER_OBJECT })
    woInfo;

    @wire(getPicklistValuesByRecordType, {
        objectApiName: WORKORDER_OBJECT,
        recordTypeId: '$defaultRecordTypeId'
    })
    wiredPicklists({ data, error }) {
        if (data?.picklistFieldValues?.Customer_Identification_Type__c?.values) {
            this.identificationOptions = data.picklistFieldValues.Customer_Identification_Type__c.values.map(v => ({
                label: v.label,
                value: v.value
            }));
        } else if (error && isOnline()) {
            getPicklistValuesApex()
                .then(result => {
                    this.identificationOptions = (result?.identificationTypes || []).map(t => ({ label: t, value: t }));
                })
                .catch(() => {});
        }
    }

    get defaultRecordTypeId() {
        return this.woInfo?.data?.defaultRecordTypeId || null;
    }

    // Get SR + ST + Contacts from briefcase
    @wire(getRecords, {
        records: [
            { objectApiName: SERVICERESOURCE_OBJECT.objectApiName, fields: ['ServiceResource.Id','ServiceResource.RelatedRecordId'] },
            { objectApiName: SERVICETERRITORYLOCATION_OBJECT.objectApiName, fields: ['ServiceTerritoryLocation.Id','ServiceTerritoryLocation.ServiceResourceId','ServiceTerritoryLocation.ServiceTerritoryId'] },
            { objectApiName: CONTACT_OBJECT.objectApiName, fields: ['Contact.Id','Contact.AccountId'] }
        ]
    })
    wiredBriefcase({ data, error }) {
        if (data) {
            const srRecs = data.records.filter(r => r.apiName === 'ServiceResource');
            const stlRecs = data.records.filter(r => r.apiName === 'ServiceTerritoryLocation');
            const contactRecs = data.records.filter(r => r.apiName === 'Contact');

            const mySR = srRecs.find(r => r.fields.RelatedRecordId.value === USER_ID);
            if (mySR) {
                this.myServiceResourceId = mySR.id;
                const stl = stlRecs.find(r => r.fields.ServiceResourceId.value === mySR.id);
                if (stl) this.myServiceTerritoryId = stl.fields.ServiceTerritoryId.value;
            }

            // Build Account → Contacts map
            contactRecs.forEach(c => {
                const accId = c.fields.AccountId.value;
                if (!this.accountContactsMap[accId]) {
                    this.accountContactsMap[accId] = [];
                }
                this.accountContactsMap[accId].push({ Id: c.id });
            });
        } else if (error) {
            console.error(error);
        }
    }

    @wire(graphql, { query: GET_SERVICE_RESOURCE, variables: { userId: USER_ID } })
    wiredGraphQLSR({ data, errors }) {
    if (data && !this.myServiceResourceId) {
        const node = data.uiapi?.query?.ServiceResource?.edges?.[0]?.node;
        if (node) {
        this.myServiceResourceId = node.Id;
        const st = node.ServiceTerritories?.edges?.[0]?.node?.ServiceTerritory;
        this.myServiceTerritoryId = st?.Id;
        this.showToast('Debug', `SR (GraphQL) loaded: ${node.Id}`, 'success');
        }
    }
    }

    // Record Picker filter
    get accountFilter() {
        return this.category
            ? { criteria: [{ fieldPath: 'Category__c', operator: 'eq', value: this.category }], filterLogic: '1' }
            : null;
    }

    connectedCallback() {
        if (isOnline()) {
            getValidAccounts()
                .then(data => { if (data) this.category = data.category; })
                .catch(() => {});
        }
    }

    // Input handlers
    handleIdTypeChange(e) { this.selectedIdentificationType = e.detail.value; }
    handleInputChange(e) {
        const which = e.target.dataset.id;
        if (which === 'idValue') {
            this.identificationValue = e.target.value?.trim();
            if (isOnline() && this.selectedIdentificationType && this.identificationValue?.length > 3) {
                getAccountByIdentification({ idType: this.selectedIdentificationType, idValue: this.identificationValue })
                    .then(acc => {
                        if (acc) {
                            this.selectedAccountId = acc.Id;
                            this.phoneNumber = acc.Phone || '';
                        } else {
                            this.selectedAccountId = '';
                            this.phoneNumber = '';
                        }
                    })
                    .catch(() => {});
            }
        } else if (which === 'phone') { this.phoneNumber = e.target.value; }
    }
    handleAccountChange(e) { this.selectedAccountId = e.detail.recordId; }

    // Create Appointment
    async handleCreateAppointment() {
        this.error = undefined; this.successMessage = undefined;
        if (!this.selectedIdentificationType || !this.identificationValue) {
            this.showToast('Missing Information', 'Select Identification Type and enter a Value.', 'warning');
            return;
        }
        this.isLoading = true;
        try {
            let woId;
            if (isOnline()) {
                woId = await createAdHocAppointmentApex({
                    identificationType: this.selectedIdentificationType,
                    identificationValue: this.identificationValue,
                    accountId: this.selectedAccountId || null
                });
                this.showToast('Success', 'Ad-Hoc Appointment Created Successfully!', 'success');
            } else {
                woId = await this.createWorkOrderWithSAOffline();
                //this.showToast('Saved (Offline)', 'Appointment will sync when online.', 'info');
            }
            this.resetForm();
           if (isOnline()) {
                this.showToast('Success', 'Ad-Hoc Appointment Created Successfully!', 'success');
                await this.navigateToWorkOrder(woId);
            } else {
                this.showToast('Saved (Offline)', 'Appointment will sync when online.', 'success');
            }
            // Close the action screen (works both online/offline)
            if (!isOnline()) this.closeAfterDelay(2000);

        } catch (err) {
            const msg = this.humanizeError(err);
            this.error = msg; this.showToast('Error', msg, 'error');
        } finally { this.isLoading = false; }
    }

    // ===== Offline Full Flow: WO + SA + AR =====
    // async createWorkOrderWithSAOffline() {
    //     const now = new Date().toISOString();

    //     // 1. WorkOrder
    //     const woFields = {};
    //     woFields[WO_Subject.fieldApiName] = 'Ad-Hoc Meter Reading';
    //     woFields[WO_Status.fieldApiName] = 'New';
    //     woFields[WO_WorkOrderType__c.fieldApiName] = 'Ad-Hoc';
    //     woFields[WO_Customer_Identification_Type__c.fieldApiName] = this.selectedIdentificationType;
    //     woFields[WO_Customer_Identification_Value__c.fieldApiName] = this.identificationValue;

    //     if (this.selectedIdentificationType === 'BP Number') {
    //         woFields[WO_Customer_BP_Number__c.fieldApiName] = this.identificationValue;
    //     }
    //     if (this.selectedAccountId) {
    //         woFields[WO_AccountId.fieldApiName] = this.selectedAccountId;
    //         // Attach first contact if available
    //         const contacts = this.accountContactsMap[this.selectedAccountId];
    //         if (contacts && contacts.length) {
    //             woFields[WO_ContactId.fieldApiName] = contacts[0].Id;
    //         }
    //     }
    //     if (this.phoneNumber) { woFields[WO_Phone__c.fieldApiName] = this.phoneNumber; }

    //     woFields[WO_StartDate.fieldApiName] = now;
    //     woFields[WO_Scheduled_Date__c.fieldApiName] = now;
    //     woFields[WO_EndDate.fieldApiName] = new Date(Date.now() + 10 * 60 * 60 * 1000).toISOString();

    //     const rtInfos = this.woInfo?.data?.recordTypeInfos;
    //     if (rtInfos) {
    //         const mglRt = Object.values(rtInfos).find(rt => rt.name === 'MGL_Metering');
    //         if (mglRt) woFields[WO_RecordTypeId.fieldApiName] = mglRt.recordTypeId;
    //     }
    //     if (this.myServiceResourceId) woFields['Assigned_Meter_Reader__c'] = this.myServiceResourceId;
    //     if (this.myServiceTerritoryId) woFields['ServiceTerritoryId'] = this.myServiceTerritoryId;

    //     const woResult = await createRecord({ apiName: WORKORDER_OBJECT.objectApiName, fields: woFields });
    //     const woId = woResult?.id;

    //     // 2. ServiceAppointment
    //     const saFields = {};
    //     saFields[SA_ParentRecordId.fieldApiName] = woId;
    //     saFields[SA_Status.fieldApiName] = 'New'; // valid initial status
    //     saFields[SA_SchedStartTime.fieldApiName] = now;
    //     saFields[SA_SchedEndTime.fieldApiName] = new Date(Date.now() + 10 * 60 * 60 * 1000).toISOString();
    //     if (this.myServiceTerritoryId) saFields[SA_ServiceTerritoryId.fieldApiName] = this.myServiceTerritoryId;

    //     const saResult = await createRecord({ apiName: SA_OBJECT.objectApiName, fields: saFields });
    //     const saId = saResult?.id;

    //     // 3. AssignedResource
    //     if (saId && this.myServiceResourceId) {
    //         const arFields = {};
    //         arFields[AR_ServiceAppointmentId.fieldApiName] = saId;
    //         arFields[AR_ServiceResourceId.fieldApiName] = this.myServiceResourceId;
    //         await createRecord({ apiName: AR_OBJECT.objectApiName, fields: arFields });
    //     }

    //     return woId;
    // }

    // ===== Offline Full Flow: WO + SA + AR =====
async createWorkOrderWithSAOffline() {
    const now = new Date().toISOString();

    // 1️⃣ WorkOrder fields
    const woFields = {};
    woFields[WO_Subject.fieldApiName] = 'Ad-Hoc Meter Reading';
    woFields[WO_Status.fieldApiName] = 'New';
    woFields[WO_WorkOrderType__c.fieldApiName] = 'Ad-Hoc';
    woFields[WO_Customer_Identification_Type__c.fieldApiName] = this.selectedIdentificationType;
    woFields[WO_Customer_Identification_Value__c.fieldApiName] = this.identificationValue;

    if (this.selectedIdentificationType === 'BP Number') {
        woFields[WO_Customer_BP_Number__c.fieldApiName] = this.identificationValue;
    }
    if (this.selectedAccountId) {
        woFields[WO_AccountId.fieldApiName] = this.selectedAccountId;
        // attach first contact if available
        const contacts = this.accountContactsMap[this.selectedAccountId];
        if (contacts && contacts.length) {
            woFields[WO_ContactId.fieldApiName] = contacts[0].Id;
        }
    }
    if (this.phoneNumber) {
        woFields[WO_Phone__c.fieldApiName] = this.phoneNumber;
    }

    woFields[WO_StartDate.fieldApiName] = now;
    woFields[WO_Scheduled_Date__c.fieldApiName] = now;
    woFields[WO_EndDate.fieldApiName] = new Date(Date.now() + 10 * 60 * 60 * 1000).toISOString();

    const rtInfos = this.woInfo?.data?.recordTypeInfos;
    if (rtInfos) {
        const mglRt = Object.values(rtInfos).find(rt => rt.name === 'MGL_Metering');
        if (mglRt) woFields[WO_RecordTypeId.fieldApiName] = mglRt.recordTypeId;
    }

    // map SR + ST (from briefcase)
    if (this.myServiceResourceId) woFields['Assigned_Meter_Reader__c'] = this.myServiceResourceId;
    if (this.myServiceTerritoryId) woFields['ServiceTerritoryId'] = this.myServiceTerritoryId;

    const woResult = await createRecord({ apiName: WORKORDER_OBJECT.objectApiName, fields: woFields });
    const woId = woResult?.id;

    // Service Appointment
    const saFields = {};
    saFields[SA_ParentRecordId.fieldApiName] = woId;
    saFields[SA_Status.fieldApiName] = 'None';
    saFields[SA_SchedStartTime.fieldApiName] = now;
    saFields[SA_SchedEndTime.fieldApiName] = new Date(Date.now() + 10 * 60 * 60 * 1000).toISOString();
    if (this.myServiceTerritoryId) saFields[SA_ServiceTerritoryId.fieldApiName] = this.myServiceTerritoryId;

    const saResult = await createRecord({ apiName: SA_OBJECT.objectApiName, fields: saFields });
    const saId = saResult?.id;

    // Assigned Resource (offline parity logic)
    if (saId && this.myServiceResourceId) {
        const arFields = {};
        arFields[AR_ServiceAppointmentId.fieldApiName] = saId;
        arFields[AR_ServiceResourceId.fieldApiName] = this.myServiceResourceId;

        try {
            await createRecord({ apiName: AR_OBJECT.objectApiName, fields: arFields });
            this.showToast('Success', 'Assigned Resource linked successfully (offline)', 'success');
        } catch (e) {
            this.showToast('Error', e?.body?.message || 'Failed to create Assigned Resource offline', 'error');
        }
    } else {
        this.showToast('Warning', 'No Service Resource or SA found for Assigned Resource creation', 'warning');
    }

    return woId;
}


    // Navigation
    async navigateToWorkOrder(recordId) {
        if (!recordId) return;
        if (FORM_FACTOR === 'Large') {
            this[NavigationMixin.Navigate]({ type: 'standard__recordPage', attributes: { recordId, actionName: 'view' } });
        } else {
            this[NavigationMixin.Navigate]({ type: 'standard__webPage', attributes: { url: `com.salesforce.fieldservice://v1/sObject/${recordId}/overview` } });
        }
    }

    // Utils
    showToast(title, message, variant) { this.dispatchEvent(new ShowToastEvent({ title, message, variant })); }
    humanizeError(err) {
        if (!err) return 'Unexpected error.';
        const body = err.body;
        if (body?.message) return body.message;
        if (Array.isArray(body?.pageErrors) && body.pageErrors.length) return body.pageErrors[0].message;
        if (err.message) return err.message;
        try { return JSON.stringify(err); } catch { return 'Unexpected error.'; }
    }
    resetForm() {
        this.selectedIdentificationType = '';
        this.identificationValue = '';
        this.selectedAccountId = null;
        this.phoneNumber = '';
        this.accountKey += 1;
    }

    closeAfterDelay(ms = 1500) {
        setTimeout(() => {
            this.dispatchEvent(new CloseActionScreenEvent());
        }, ms);
    }

}