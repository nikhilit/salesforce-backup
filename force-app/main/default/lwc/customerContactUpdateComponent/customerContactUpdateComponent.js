/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 07-08-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   08-05-2025   Kartik Patkar, Appstrail   Initial Version
**/
/**
 * Customer Contact Update (Online = Apex | Offline = LDS)
 */

import { api, LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { CloseActionScreenEvent } from 'lightning/actions';

// ONLINE (Apex)
import getAccountRecordDetails from '@salesforce/apex/UpdateCustomerController.getAccountRecordDetails';
import updateCustomerContact from '@salesforce/apex/UpdateCustomerController.updateCustomerContact';

// OFFLINE (LDS/UI API)
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';

// WorkOrder fields
import WO_ID from '@salesforce/schema/WorkOrder.Id';
import WO_ACCOUNTID from '@salesforce/schema/WorkOrder.AccountId';

import WO_NEW_MOBILE from '@salesforce/schema/WorkOrder.New_Mobile_Number__c';
import WO_NEW_RES from '@salesforce/schema/WorkOrder.New_Residence_Telephone__c';
import WO_NEW_OFF from '@salesforce/schema/WorkOrder.New_Office_Telephone__c';
import WO_NEW_EMAIL from '@salesforce/schema/WorkOrder.New_Email__c';

import WO_OLD_MOBILE from '@salesforce/schema/WorkOrder.Old_Mobile_Number__c';
import WO_OLD_RES from '@salesforce/schema/WorkOrder.Old_Residence_Telephone__c';
import WO_OLD_OFF from '@salesforce/schema/WorkOrder.Old_Office_Telephone__c';

import WO_CONTACT_REMARK from '@salesforce/schema/WorkOrder.Update_Contact_Remark__c';

// Account fields
import ACC_ID from '@salesforce/schema/Account.Id';
import ACC_PHONE from '@salesforce/schema/Account.Phone';
import ACC_OTHER from '@salesforce/schema/Account.PersonOtherPhone';
import ACC_SECONDARY from '@salesforce/schema/Account.Secondary_Telephone__c';
import ACC_EMAIL from '@salesforce/schema/Account.Account_Email__c';

import Update_Customer_Contact_Step_Name from '@salesforce/label/c.Update_Customer_Contact_Step_Name';

export default class CustomerContactUpdateComponent extends NavigationMixin(LightningElement) {
  _workOrderId;
  @api set recordId(value) {
    this._workOrderId = value;
    this.init(); // online path only (Apex); offline uses wires
  }
  get recordId() {
    return this._workOrderId;
  }

  // ---------- UI state ----------
  load = false;

  // ---------- values (Old + New + remark) ----------
  // Old (read-only)
  oldMobileNumber = '';
  oldResidenceTelephone = '';
  oldOfficeTelephone = '';
  oldEmail = '';

  // New (editable)
  newMobileNumber = '';
  newResidenceTelephone = '';
  newOfficeTelephone = '';
  newEmail = '';
  remarks = '';

  // Context
  accountId;

  woData; // WorkOrder wire data
  accData; // Account wire data

  // Online/Offline toggle
  get isOnline() {
    return navigator.onLine;
  }

  // ---------- ONLINE INIT  ----------
  init() {
    if (!this.isOnline || !this._workOrderId) return; 
    getAccountRecordDetails({ recordId: this._workOrderId })
      .then((result) => {
        const acc = result?.accRec;
        const wo = result?.workOrder;

        if (acc) {
          this.accountId = acc.Id;
          this.oldMobileNumber = acc.Phone || '';
          this.oldResidenceTelephone = acc.Secondary_Telephone__c || '';
          this.oldOfficeTelephone = acc.PersonOtherPhone || '';
          this.oldEmail = acc.Account_Email__c || '';
        }

        if (wo) {
          this.newMobileNumber = wo.New_Mobile_Number__c || '';
          this.newOfficeTelephone = wo.New_Office_Telephone__c || '';
          this.newResidenceTelephone = wo.New_Residence_Telephone__c || '';
          this.newEmail = wo.New_Email__c || '';
          this.remarks = wo.Update_Contact_Remark__c || '';
        }
      })
      .catch(() => {
      });
  }

  // ---------- WIRES (offline + parity with online cache) ----------

  @wire(getRecord, {
    recordId: '$recordId',
    fields: [
      WO_ID,
      WO_ACCOUNTID,
      // new values
      WO_NEW_MOBILE,
      WO_NEW_RES,
      WO_NEW_OFF,
      WO_NEW_EMAIL,
      WO_CONTACT_REMARK,
      // old values (fallback if Account not cached)
      WO_OLD_MOBILE,
      WO_OLD_RES,
      WO_OLD_OFF
    ]
  })
  woWire({ data, error }) {
    if (error) {
      return;
    }
    if (!data) {
      return;
    }

    // Persist WorkOrder data for reactive use elsewhere
    this.woData = data;

    // keep account id around for Apex call, if not already from online init
    const accId = getFieldValue(data, WO_ACCOUNTID);
    if (accId) this.accountId = accId;

    // pre-fill NEW values (so previously saved entries show up offline too)
    if (!this.newMobileNumber) this.newMobileNumber = getFieldValue(data, WO_NEW_MOBILE) || '';
    if (!this.newResidenceTelephone) this.newResidenceTelephone = getFieldValue(data, WO_NEW_RES) || '';
    if (!this.newOfficeTelephone) this.newOfficeTelephone = getFieldValue(data, WO_NEW_OFF) || '';
    if (!this.newEmail) this.newEmail = getFieldValue(data, WO_NEW_EMAIL) || '';
    if (!this.remarks) this.remarks = getFieldValue(data, WO_CONTACT_REMARK) || '';

    // Fallback Old values from WorkOrder immediately
    const woOldMobile = getFieldValue(data, WO_OLD_MOBILE) || '';
    const woOldRes = getFieldValue(data, WO_OLD_RES) || '';
    const woOldOff = getFieldValue(data, WO_OLD_OFF) || '';
    if (!this.oldMobileNumber) this.oldMobileNumber = woOldMobile;
    if (!this.oldResidenceTelephone) this.oldResidenceTelephone = woOldRes;
    if (!this.oldOfficeTelephone) this.oldOfficeTelephone = woOldOff;
    // Note: if WorkOrder has Old Email field, import and hydrate similarly.
  }

  // Account snapshot (authoritative source for "Old" values offline)
  get wiredAccountId() {
    return this.woData ? getFieldValue(this.woData, WO_ACCOUNTID) : undefined;
  }

  @wire(getRecord, {
    recordId: '$wiredAccountId',
    fields: [ACC_ID, ACC_PHONE, ACC_OTHER, ACC_SECONDARY, ACC_EMAIL]
  })
  accWire({ data, error }) {
    if (error) {
      return;
    }
    if (!data) {
      return;
    }

    // persist for later safe reads
    this.accData = data;

    const aId = getFieldValue(data, ACC_ID);
    if (aId) this.accountId = aId;

    // Overwrite with Account values if available; keep WO fallback otherwise
    const accPhone = getFieldValue(data, ACC_PHONE) || '';
    const accSecondary = getFieldValue(data, ACC_SECONDARY) || '';
    const accOther = getFieldValue(data, ACC_OTHER) || '';
    const accEmail = getFieldValue(data, ACC_EMAIL) || '';

    if (accPhone) this.oldMobileNumber = accPhone;
    if (accSecondary) this.oldResidenceTelephone = accSecondary;
    if (accOther) this.oldOfficeTelephone = accOther;
    if (accEmail) this.oldEmail = accEmail;
  }

  // WorkSteps (for offline completion)
  @wire(getRelatedListRecords, {
    parentRecordId: '$recordId',
    relatedListId: 'WorkSteps',
    fields: ['WorkStep.Id', 'WorkStep.Name', 'WorkStep.Status', 'WorkStep.ParentRecordId'],
    pageSize: 50
  })
  stepsWire;

  // ---------- INPUT HANDLERS ----------
  handleFieldChange(e) {
    const name = e.currentTarget?.dataset?.fieldName;
    const val = e.detail?.value;
    if (name === 'newMobileNumber') this.newMobileNumber = val;
    if (name === 'newResidenceTelephone') this.newResidenceTelephone = val;
    if (name === 'newOfficeTelephone') this.newOfficeTelephone = val;
    if (name === 'newEmail') this.newEmail = val;
    if (name === 'remarks') this.remarks = val;
  }

  // ---------- VALIDATION ----------
  handleValidation() {
    const emptyAll =
      !this.newMobileNumber && !this.newResidenceTelephone && !this.newOfficeTelephone && !this.newEmail;
    if (emptyAll) {
      this.toast('Error', 'Please enter at least one field to update.', 'error');
      return false;
    }

    const badPhone =
      (this.newMobileNumber && this.newMobileNumber.length !== 10) ||
      (this.newResidenceTelephone && this.newResidenceTelephone.length !== 10) ||
      (this.newOfficeTelephone && this.newOfficeTelephone.length !== 10);
    if (badPhone) {
      this.toast('Error', 'Please enter valid Contact Number.', 'error');
      return false;
    }

    if (this.newEmail && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(this.newEmail)) {
      this.toast('Error', 'Please enter valid Email Address.', 'error');
      return false;
    }
    return true;
  }

  // ---------- SAVE ----------
  async handleSave() {
    if (!this.handleValidation()) return;

    this.load = true;
    try {
      if (this.isOnline) {
        // ONLINE: keep original Apex call unchanged
        await updateCustomerContact({
          phone: this.newMobileNumber,
          secondaryPhone: this.newResidenceTelephone,
          otherPhone: this.newOfficeTelephone,
          remarks: this.remarks,
          recordId: this.recordId,
          accountId: this.accountId,
          newEmail: this.newEmail
        });

        this.toast('Success', 'Customer Contact updated successfully.', 'success');
        this.init(); // rehydrate from server
        this.handleCancel();
        return;
      }

      // OFFLINE: LDS — write to WorkOrder (mirror your Apex behaviour)
      const oldFromAcc = {
        phone: (this.accData && getFieldValue(this.accData, ACC_PHONE)) || this.oldMobileNumber || '',
        secondary: (this.accData && getFieldValue(this.accData, ACC_SECONDARY)) || this.oldResidenceTelephone || '',
        other: (this.accData && getFieldValue(this.accData, ACC_OTHER)) || this.oldOfficeTelephone || ''
      };

      const fields = {
        Id: this.recordId,
        [WO_OLD_MOBILE.fieldApiName]: oldFromAcc.phone,
        [WO_OLD_RES.fieldApiName]: oldFromAcc.secondary,
        [WO_OLD_OFF.fieldApiName]: oldFromAcc.other,

        [WO_NEW_MOBILE.fieldApiName]: this.newMobileNumber || '',
        [WO_NEW_RES.fieldApiName]: this.newResidenceTelephone || '',
        [WO_NEW_OFF.fieldApiName]: this.newOfficeTelephone || '',
        [WO_NEW_EMAIL.fieldApiName]: this.newEmail || '',
        [WO_CONTACT_REMARK.fieldApiName]: this.remarks || ''
      };

      await updateRecord({ fields });

      // Complete the matching WorkStep offline (same as Apex updateWorkStepStatus)
      await this.offlineCompleteWorkStep(Update_Customer_Contact_Step_Name);

      this.toast('Success', 'Saved offline. Will sync when online.', 'success');
      this.handleCancel();
    } catch (e) {
      this.toast('Error', e?.body?.message || e?.message || 'Update failed', 'error');
    } finally {
      this.load = false;
    }
  }

  async offlineCompleteWorkStep(stepName) {
    try {
      const rows = this.stepsWire?.data?.records || [];
      const match = rows.find(
        (r) => (r?.fields?.Name?.value || '').toLowerCase() === (stepName || '').toLowerCase()
      );
      if (!match) return;
      const wsId = match?.fields?.Id?.value;
      if (!wsId) return;
      await updateRecord({ fields: { Id: wsId, Status: 'Completed' } });
    } catch {
      // if not cached, it will sync later or be skipped — acceptable offline
    }
  }

  // ---------- CANCEL / NAV ----------
  handleCancel() {
    this.load = false;
    this.resetFields();
    const id = this.recordId;

    if (FORM_FACTOR === 'Small') {
      this.dispatchEvent(new CloseActionScreenEvent());
    } else {
      this[NavigationMixin.Navigate]({
        type: 'standard__recordPage',
        attributes: { recordId: id, actionName: 'view' }
      });
    }
  }

  resetFields() {
    this.newMobileNumber = '';
    this.newResidenceTelephone = '';
    this.newOfficeTelephone = '';
    this.newEmail = '';
    this.remarks = '';
  }

  // ---------- Toast ----------
  toast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant, mode: 'dismissable' }));
  }
}