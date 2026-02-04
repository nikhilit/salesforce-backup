/**
 * @description       : Customer Meter Number Update (Online=Apex | Offline=LDS)
 * @author            : Kartik Patkar / Prasanth
 * @last modified on  : 29-09-2025
 */

import { api, LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { RefreshEvent } from 'lightning/refresh';
import { CloseActionScreenEvent } from 'lightning/actions';
import FORM_FACTOR from '@salesforce/client/formFactor';

// -------- APEX (ONLINE) ----------
import getAccountRecordDetails from '@salesforce/apex/UpdateCustomerController.getAccountRecordDetails';
import updateCustomerMeterNumber from '@salesforce/apex/UpdateCustomerController.updateCustomerMeterNumber';

// -------- Labels (for WorkStep name parity) ----------
import Update_Meter_Number_Step_Name from '@salesforce/label/c.Update_Meter_Number_Step_Name';

// -------- LDS (OFFLINE) ----------
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';

// WorkOrder fields we need
import WO_ID from '@salesforce/schema/WorkOrder.Id';
import WO_ACCOUNTID from '@salesforce/schema/WorkOrder.AccountId';
import WO_OLD_METER from '@salesforce/schema/WorkOrder.Old_Meter_Number__c';
import WO_NEW_METER from '@salesforce/schema/WorkOrder.New_Meter_Number__c';
import WO_UPDATE_METER_REMARK from '@salesforce/schema/WorkOrder.Update_Meter_Number_Remark__c';

// Account fields
import ACC_ID from '@salesforce/schema/Account.Id';
import ACC_METER from '@salesforce/schema/Account.Meter_Number__c';

export default class CustomerMeterNumberUpdateComponent extends NavigationMixin(LightningElement) {
  // recordId wiring
  _recordId;
  @api set recordId(value) {
    this._recordId = value;
    this.init(); // keep online behavior unchanged
  }
  get recordId() { return this._recordId; }

  // Optional override; if not provided we use the custom label
  @api workStepNameToComplete;

  // UI state
  load = false;

  // Inputs
  oldMeterNumber = '';
  newMeterNumber = '';
  remarks = '';

  // From Apex/Account
  accountId;

  // ------------- ONLINE (Apex) -------------
  init() {
    // keep calling Apex (don’t gate on navigator.onLine)
    this.load = true;
    getAccountRecordDetails({ recordId: this._recordId })
      .then(result => {
        // result is a Map with keys: workOrder, accRec
        console.log('The Result is-->',result);
       const acc = result && result.accRec;
       console.log('The acc is-->',acc);
        if (acc) {
          this.accountId = acc.Id || this.accountId;
          this.oldMeterNumber = acc.Meter_Number__c || '';
          console.log('his.accountId',this.accountId);
          console.log('this.oldMeterNumber',this.oldMeterNumber);
        }
        this.load = false;
      })
      .catch(err => {
        this.load = false;
      });
  }

  // ------------- OFFLINE DATA (LDS wires) -------------
  @wire(getRecord, {
    recordId: '$recordId',
    fields: [WO_ID, WO_ACCOUNTID]
  }) workOrderRec;

  get wiredAccountId() {
    return getFieldValue(this.workOrderRec?.data, WO_ACCOUNTID);
  }

  // Account → hydrate oldMeterNumber / accountId if Apex didn’t
  @wire(getRecord, {
    recordId: '$wiredAccountId',
    fields: [ACC_ID, ACC_METER]
  }) accountRecWire({ data, error }) {
    if (data) {
      if (!this.accountId) this.accountId = getFieldValue(data, ACC_ID);
      if (!this.oldMeterNumber) this.oldMeterNumber = getFieldValue(data, ACC_METER) || '';
    }
    // ignore error; might not be in briefcase
  }

  // WorkSteps list (for offline completion)
  @wire(getRelatedListRecords, {
    parentRecordId: '$recordId',
    relatedListId: 'WorkSteps',
    fields: ['WorkStep.Id', 'WorkStep.Name', 'WorkStep.Status', 'WorkStep.ParentRecordId'],
    pageSize: 50
  }) workStepsList;

  // ------------- Handlers -------------
  handleFieldChange(e) {
    const name = e.currentTarget.dataset.fieldName;
    const val = e.detail?.value;
    if (name === 'newMeterNumber') this.newMeterNumber = val;
    if (name === 'remarks') this.remarks = val;
  }

  validate() {
    if (!this.newMeterNumber) {
      this.toast('Error', 'New Meter Number is required.', 'error');
      return false;
    }
    return true;
  }

  async handleSave() {
    this.load = true;
    try {
      if (!this.validate()) { this.load = false; return; }

      if (navigator.onLine) {
        // -------- ONLINE: Apex unchanged --------
        await updateCustomerMeterNumber({
          meterNumber: this.newMeterNumber,
          remark: this.remarks,
          recordId: this.recordId,
          accountId: this.accountId
        });
        this.toast('Success', 'Customer meter number updated successfully.', 'success');

      } else {
        // -------- OFFLINE: LDS parity --------
        //const accMeter = getFieldValue(this.accountRecWire?.data, ACC_METER) || this.oldMeterNumber || '';
        const accMeter = this.oldMeterNumber || '';

        // 1) Update WorkOrder Old/New/Remark
        await updateRecord({
          fields: {
            Id: this.recordId,
            [WO_OLD_METER.fieldApiName]: accMeter,
            [WO_NEW_METER.fieldApiName]: this.newMeterNumber,
            [WO_UPDATE_METER_REMARK.fieldApiName]: this.remarks || ''
          }
        });

        // 2) Complete WorkStep (match Apex updateWorkStepStatus)
        await this.offlineCompleteWorkStep(
          (this.workStepNameToComplete && this.workStepNameToComplete.trim()) || Update_Meter_Number_Step_Name
        );

        this.toast('Success', 'Saved offline. Will sync when online.', 'success');
      }

      this.resetFields();
      this.handleCancel(); // close/navigate like your current flow
    } catch (e) {
      this.toast('Error', e?.body?.message || e?.message || 'Update failed', 'error');
    } finally {
      this.load = false;
    }
  }

  handleCancel() {
    this.dispatchEvent(new RefreshEvent());
    if (FORM_FACTOR === 'Small' || FORM_FACTOR === 'Medium') {
      this.dispatchEvent(new CloseActionScreenEvent());
    } else {
      this[NavigationMixin.Navigate]({
        type: 'standard__recordPage',
        attributes: { recordId: this.recordId, actionName: 'view' }
      });
    }
  }

  resetFields() {
    this.newMeterNumber = '';
    this.remarks = '';
  }

  async offlineCompleteWorkStep(targetName) {
    try {
      const rows = this.workStepsList?.data?.records || [];
      const match = rows.find(r => (r?.fields?.Name?.value || '').toLowerCase() === (targetName || '').toLowerCase());
      if (!match) return;
      const wsId = match.fields?.Id?.value;
      if (!wsId) return;
      await updateRecord({ fields: { Id: wsId, Status: 'Completed' } });
    } catch {
      // offline queue will sync later or no step cached—safe to ignore
    }
  }

  toast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant, mode: 'dismissable' }));
  }
}