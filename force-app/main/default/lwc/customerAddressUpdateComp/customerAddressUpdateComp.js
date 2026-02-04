/**
 * @description       : Customer Address Update Component (Online: Apex | Offline: LDS)
 * @author            : Kartik Patkar / Prasanth G
 * @last modified on  : 28-09-2025
 */

import { api, LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import FORM_FACTOR from '@salesforce/client/formFactor';

// ------------------ APEX (ONLINE) ------------------
import getBusinessPartner from '@salesforce/apex/CustomerAddressUpdateContr.getBusinessPartner';
import fieldPicklistValue from '@salesforce/apex/CustomerAddressUpdateContr.fieldPicklistValue';
import uploadFiles from '@salesforce/apex/CustomerAddressUpdateContr.uploadFiles';

// ------------------ LDS (OFFLINE) ------------------
import {getRecord,getFieldValue,createRecord,updateRecord} from 'lightning/uiRecordApi';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';

// ---- WorkOrder fields (Old_* and New_* + AccountId) ----
import WO_ID from '@salesforce/schema/WorkOrder.Id';
import WO_ACCOUNTID from '@salesforce/schema/WorkOrder.AccountId';

import WO_OLD_FLAT from '@salesforce/schema/WorkOrder.Old_Flat__c';
import WO_OLD_FLOOR from '@salesforce/schema/WorkOrder.Old_Floor__c';
import WO_OLD_WING from '@salesforce/schema/WorkOrder.Old_Wing__c';
import WO_OLD_PLOT from '@salesforce/schema/WorkOrder.Old_Plot__c';
import WO_OLD_COLONY from '@salesforce/schema/WorkOrder.Old_Colony__c';
import WO_OLD_ROAD from '@salesforce/schema/WorkOrder.Old_Road_Name__c';
import WO_OLD_LOCATION from '@salesforce/schema/WorkOrder.Old_Location__c';
import WO_OLD_BUILDING from '@salesforce/schema/WorkOrder.Old_Building_Name_Prem__c';
import WO_OLD_SOCIETY from '@salesforce/schema/WorkOrder.Old_Society_Name__c';

import WO_NEW_FLAT from '@salesforce/schema/WorkOrder.New_Flat__c';
import WO_NEW_FLOOR from '@salesforce/schema/WorkOrder.New_Floor__c';
import WO_NEW_WING from '@salesforce/schema/WorkOrder.New_Wing__c';
import WO_NEW_PLOT from '@salesforce/schema/WorkOrder.New_Plot__c';
import WO_NEW_COLONY from '@salesforce/schema/WorkOrder.New_Colony__c';
import WO_NEW_ROAD from '@salesforce/schema/WorkOrder.New_Road_Name__c';
import WO_NEW_LOCATION from '@salesforce/schema/WorkOrder.New_Location__c';
import WO_NEW_BUILDING from '@salesforce/schema/WorkOrder.New_Building_Name_Prem__c';
import WO_NEW_SOCIETY from '@salesforce/schema/WorkOrder.New_Society_Name__c';
import WO_NEW_CUSTNAME from '@salesforce/schema/WorkOrder.New_Customer_Name__c';
import WO_NEIGHBOUR_BP from '@salesforce/schema/WorkOrder.Neighbour_BP_Number__c';
import WO_REMARK from '@salesforce/schema/WorkOrder.Remarks__c';

// ---- Account fields (to copy into Old_* when offline) ----
import ACC_ID from '@salesforce/schema/Account.Id';
import ACC_FLAT from '@salesforce/schema/Account.Flat__c';
import ACC_FLOOR from '@salesforce/schema/Account.Floor__c';
import ACC_WING from '@salesforce/schema/Account.Wing__c';
import ACC_PLOT from '@salesforce/schema/Account.Plot__c';
import ACC_COLONY from '@salesforce/schema/Account.Colony__c';
import ACC_ROAD from '@salesforce/schema/Account.Road_name__c';
import ACC_LOCATION from '@salesforce/schema/Account.Location__c';
import ACC_BUILDING from '@salesforce/schema/Account.Building_name__c';
import ACC_SOCIETY from '@salesforce/schema/Account.Society_Name__c';
import ACC_FIRSTNAME from '@salesforce/schema/Account.FirstName__c';
import ACC_LASTNAME from '@salesforce/schema/Account.LastName__c';
import ACC_BPNUM from '@salesforce/schema/Account.BP_Number__c';

// ---- ContentVersion (Document Type picklist) ----
import CV_OBJ from '@salesforce/schema/ContentVersion';
import CV_TITLE from '@salesforce/schema/ContentVersion.Title';
import CV_PATH from '@salesforce/schema/ContentVersion.PathOnClient';
import CV_DATA from '@salesforce/schema/ContentVersion.VersionData';
import CV_FIRSTPUBLISH from '@salesforce/schema/ContentVersion.FirstPublishLocationId';
import CV_DOC_TYPE from '@salesforce/schema/ContentVersion.Document_Type__c';

// ------------------ Component ------------------
export default class CustomerAddressUpdateComp extends NavigationMixin(LightningElement) {
  // Record / WorkStep
  _recordId;
  @api set recordId(v) {
    this._recordId = v; 
    this.getBusinessPartnerDetails(); 
  }
  get recordId() {
     return this._recordId; 
    }

  /** Name of the Work Step to complete (optional) */
  @api workStepNameToComplete = 'Customer Address Update';

  // UI state
  @track showFieldUpdate = true;
  @track showFileUpload = false;
  @track isLoading = false;

  // Input state (New_* + remark)
  @track newFlat;
  @track newFloor;
  @track newWing;
  @track newPlot;
  @track newColony;
  @track newRoadName;
  @track newLocation;
  @track newBuildName;
  @track newSocietyName;
  @track newCustomerName;
  @track newBPNumber;
  @track remarks;

  // Files: [{filename, base64, documentType}]
  @track fileData = [];
  @track documentTypes = []; // [{label, value, fileName, base64}]

  // From Apex (online)
  //@track businessPartnerRecord = '';
  @track businessPartnerRecord = {};
  accountId;
  

  // ------------------ ONLINE (Apex) ------------------
  getBusinessPartnerDetails() {
    // Online-only helper; if offline, LDS wires below will supply data.
    if (!navigator.onLine) { return; }
    getBusinessPartner({ recordId: this._recordId })
      .then(data => {
        //this.businessPartnerRecord = data;
        this.businessPartnerRecord = data || {};
        this.accountId = data?.Id;
      })
      .catch(() => {
         console.warn('getBusinessPartner failed:', err);
        // Fallback hydrate for display only
        const a = this.accountRec?.data;
        if (a) {
          this.businessPartnerRecord = {
            Flat__c:        getFieldValue(a, ACC_FLAT) || '',
            Floor__c:       getFieldValue(a, ACC_FLOOR) || '',
            Wing__c:        getFieldValue(a, ACC_WING) || '',
            Plot__c:        getFieldValue(a, ACC_PLOT) || '',
            Colony__c:      getFieldValue(a, ACC_COLONY) || '',
            Road_name__c:   getFieldValue(a, ACC_ROAD) || '',
            Location__c:    getFieldValue(a, ACC_LOCATION) || '',
            Building_name__c: getFieldValue(a, ACC_BUILDING) || '',
            Society_Name__c:  getFieldValue(a, ACC_SOCIETY) || '',
            FirstName__c:   getFieldValue(a, ACC_FIRSTNAME) || '',
            LastName__c:    getFieldValue(a, ACC_LASTNAME) || '',
            BP_Number__c:   getFieldValue(a, ACC_BPNUM) || ''
          };
          this.accountId = getFieldValue(a, ACC_ID);
        }
      });
  }

  connectedCallback() {
    // Try Apex for doc types (online)
    fieldPicklistValue({ objectName: 'ContentVersion', fieldName: 'Document_Type__c' })
      .then(data => {
        this.documentTypes = data.map(item => ({ ...item, fileName: '', base64: '' }));
      })
      .catch(() => {
        // no-op; UI API fallback below
      });
  }

  // ------------------ OFFLINE data via LDS wires ------------------

  // WorkOrder (Id + AccountId; Old_* available if already set)
  @wire(getRecord, {
    recordId: '$_recordId',
    fields: [
      WO_ID, WO_ACCOUNTID,
      WO_OLD_FLAT, WO_OLD_FLOOR, WO_OLD_WING, WO_OLD_PLOT, WO_OLD_COLONY, WO_OLD_ROAD,
      WO_OLD_LOCATION, WO_OLD_BUILDING, WO_OLD_SOCIETY
    ]
  }) workOrderRec;

  get wiredAccountId() { return getFieldValue(this.workOrderRec?.data, WO_ACCOUNTID); }

  // Account (source of "Old_*" values for offline copy)
  @wire(getRecord, {
    recordId: '$wiredAccountId',
    fields: [
      ACC_ID, ACC_FLAT, ACC_FLOOR, ACC_WING, ACC_PLOT, ACC_COLONY, ACC_ROAD,
      ACC_LOCATION, ACC_BUILDING, ACC_SOCIETY, ACC_FIRSTNAME, ACC_LASTNAME, ACC_BPNUM
    ]
  }) accountRec;

  // WorkSteps related list (to flip status offline)
  // relatedListId must be the API name of the related list from WorkOrder -> WorkStep.
  // Standard is typically 'WorkSteps'.
  @wire(getRelatedListRecords, {
    parentRecordId: '$_recordId',
    relatedListId: 'WorkSteps',
    fields: ['WorkStep.Id', 'WorkStep.Name', 'WorkStep.Status', 'WorkStep.ParentRecordId'],
    pageSize: 50
  }) workStepsList;

  // UI API fallback for Doc Type picklist (offline support)
  @wire(getObjectInfo, { objectApiName: CV_OBJ }) cvInfo;
  @wire(getPicklistValues, {
    recordTypeId: '$cvDefaultRt',
    fieldApiName: CV_DOC_TYPE
  }) cvDocTypePicklist({ data }) {
    if (data && (!this.documentTypes || this.documentTypes.length === 0)) {
      this.documentTypes = data.values.map(v => ({ label: v.label, value: v.value, fileName: '', base64: '' }));
    }
  }
  get cvDefaultRt() { return this.cvInfo?.data?.defaultRecordTypeId; }

    get flat() {
      return this.businessPartnerRecord?.Flat__c
        || getFieldValue(this.accountRec?.data, ACC_FLAT)
        || getFieldValue(this.workOrderRec?.data, WO_OLD_FLAT)
        || '';
    }
    get floor() {
      return this.businessPartnerRecord?.Floor__c
        || getFieldValue(this.accountRec?.data, ACC_FLOOR)
        || getFieldValue(this.workOrderRec?.data, WO_OLD_FLOOR)
        || '';
    }
    get wing() {
      return this.businessPartnerRecord?.Wing__c
        || getFieldValue(this.accountRec?.data, ACC_WING)
        || getFieldValue(this.workOrderRec?.data, WO_OLD_WING)
        || '';
    }
    get plot() {
      return this.businessPartnerRecord?.Plot__c
        || getFieldValue(this.accountRec?.data, ACC_PLOT)
        || getFieldValue(this.workOrderRec?.data, WO_OLD_PLOT)
        || '';
    }
    get colony() {
      return this.businessPartnerRecord?.Colony__c
        || getFieldValue(this.accountRec?.data, ACC_COLONY)
        || getFieldValue(this.workOrderRec?.data, WO_OLD_COLONY)
        || '';
    }
    get roadName() {
      return this.businessPartnerRecord?.Road_name__c
        || getFieldValue(this.accountRec?.data, ACC_ROAD)
        || getFieldValue(this.workOrderRec?.data, WO_OLD_ROAD)
        || '';
    }
    get location() {
      return this.businessPartnerRecord?.Location__c
        || getFieldValue(this.accountRec?.data, ACC_LOCATION)
        || getFieldValue(this.workOrderRec?.data, WO_OLD_LOCATION)
        || '';
    }
    get building() {
      return this.businessPartnerRecord?.Building_name__c
        || getFieldValue(this.accountRec?.data, ACC_BUILDING)
        || getFieldValue(this.workOrderRec?.data, WO_OLD_BUILDING)
        || '';
    }
    get society() {
      return this.businessPartnerRecord?.Society_Name__c
        || getFieldValue(this.accountRec?.data, ACC_SOCIETY)
        || getFieldValue(this.workOrderRec?.data, WO_OLD_SOCIETY)
        || '';
    }
    get customerName() {
      // Account stores first/last separately in your Apex query
      const fApex  = this.businessPartnerRecord?.FirstName__c || '';
      const lApex  = this.businessPartnerRecord?.LastName__c || '';
      const fWire  = getFieldValue(this.accountRec?.data, ACC_FIRSTNAME) || '';
      const lWire  = getFieldValue(this.accountRec?.data, ACC_LASTNAME) || '';
      const fromApex = `${fApex} ${lApex}`.trim();
      const fromWire = `${fWire} ${lWire}`.trim();
      return fromApex || fromWire || '';
    }
    get bpNumber() {
      return this.businessPartnerRecord?.BP_Number__c
        || getFieldValue(this.accountRec?.data, ACC_BPNUM)
        || '';
    }

  // ------------------ UI NAV ------------------
  handleNext() { 
    this.showFieldUpdate = false; this.showFileUpload = true; 
  }
  handlePrevious() { 
    this.showFileUpload = false; this.showFieldUpdate = true; 
  }

  handleCancel() {
    this.resetForm();
    if (FORM_FACTOR === 'Small' || FORM_FACTOR === 'Medium') {
      this.dispatchEvent(new CloseActionScreenEvent());
    } else {
      this[NavigationMixin.Navigate]({
        type: 'standard__recordPage',
        attributes: { recordId: this.recordId, actionName: 'view' }
      });
    }
  }

  // ------------------ INPUT / FILES ------------------
  handleInputChange(e) {
    const api = e.currentTarget?.dataset?.fieldName;
    const val = e.detail?.value;
    if (!api) return;
    this[api] = val;
  }

  handleFileChange(event) {
    const file = event.target.files?.[0];
    const label = event.target.dataset.label;
    if (!file || !label) return;

    const reader = new FileReader();
    reader.onload = () => {
      const base64 = reader.result.split(',')[1];
      this.fileData = [
        ...this.fileData.filter(f => f.documentType !== label),
        { filename: file.name, base64, documentType: label }
      ];
      this.documentTypes = this.documentTypes.map(dt =>
        dt.label === label ? { ...dt, fileName: file.name, base64 } : dt
      );
    };
    reader.readAsDataURL(file);
  }

  handleClearFile(event) {
    const label = event.target.dataset.label;
    this.fileData = this.fileData.filter(f => f.documentType !== label);
    this.documentTypes = this.documentTypes.map(dt =>
      dt.label === label ? { ...dt, fileName: '', base64: '' } : dt
    );
  }

  // ------------------ SAVE (ONLINE vs OFFLINE) ------------------
  async handleUpload() {
    this.isLoading = true;
    try {
      // Enforcement parity: need at least 3 files (same as online flow)
      if (!this.fileData || this.fileData.length < 3) {
        this.toast('Warning', 'Please upload at least 3 documents.', 'warning');
        return;
      }

      if (navigator.onLine) {
        await uploadFiles({
          recordId: this.accountId || this.wiredAccountId,        // Account Id
          fileName: this.fileData.map(f => f.filename),           // List<String>
          base64Data: this.fileData.map(f => f.base64),           // List<String>
          flat: this.newFlat,
          floor: this.newFloor,
          wing: this.newWing,
          plot: this.newPlot,
          colony: this.newColony,
          roadName: this.newRoadName,
          location: this.newLocation,
          buildName: this.newBuildName,
          societyName: this.newSocietyName,
          customerName: this.newCustomerName,
          bpNumber: this.newBPNumber,
          remark: this.remarks,
          workOrderId: this.recordId
        });

        this.toast('Success', 'Data & files uploaded successfully (Online).', 'success');

      } else {
        // -------- OFFLINE: LDS (full parity) --------

        // 1) Build Old_* from Account (cached offline)
        const a = this.accountRec?.data;
        const acc = {
          Flat__c: getFieldValue(a, ACC_FLAT) ?? '',
          Floor__c: getFieldValue(a, ACC_FLOOR) ?? '',
          Wing__c: getFieldValue(a, ACC_WING) ?? '',
          Plot__c: getFieldValue(a, ACC_PLOT) ?? '',
          Colony__c: getFieldValue(a, ACC_COLONY) ?? '',
          Road_name__c: getFieldValue(a, ACC_ROAD) ?? '',
          Location__c: getFieldValue(a, ACC_LOCATION) ?? '',
          Building_name__c: getFieldValue(a, ACC_BUILDING) ?? '',
          Society_Name__c: getFieldValue(a, ACC_SOCIETY) ?? '',
          FirstName__c: getFieldValue(a, ACC_FIRSTNAME) ?? '',
          LastName__c: getFieldValue(a, ACC_LASTNAME) ?? '',
          BP_Number__c: getFieldValue(a, ACC_BPNUM) ?? ''
        };

        // 2) Update WorkOrder with Old_* and New_* and Remark__c
        const woUpdate = {
          fields: {
            Id: this.recordId,
            // Old_* snapshot from Account
            [WO_OLD_FLAT.fieldApiName]: acc.Flat__c,
            [WO_OLD_FLOOR.fieldApiName]: acc.Floor__c,
            [WO_OLD_WING.fieldApiName]: acc.Wing__c,
            [WO_OLD_PLOT.fieldApiName]: acc.Plot__c,
            [WO_OLD_COLONY.fieldApiName]: acc.Colony__c,
            [WO_OLD_ROAD.fieldApiName]: acc.Road_name__c,
            [WO_OLD_LOCATION.fieldApiName]: acc.Location__c,
            [WO_OLD_BUILDING.fieldApiName]: acc.Building_name__c,
            [WO_OLD_SOCIETY.fieldApiName]: acc.Society_Name__c,

            // New_*
            [WO_NEW_FLAT.fieldApiName]: this.newFlat || '',
            [WO_NEW_FLOOR.fieldApiName]: this.newFloor || '',
            [WO_NEW_WING.fieldApiName]: this.newWing || '',
            [WO_NEW_PLOT.fieldApiName]: this.newPlot || '',
            [WO_NEW_COLONY.fieldApiName]: this.newColony || '',
            [WO_NEW_ROAD.fieldApiName]: this.newRoadName || '',
            [WO_NEW_LOCATION.fieldApiName]: this.newLocation || '',
            [WO_NEW_BUILDING.fieldApiName]: this.newBuildName || '',
            [WO_NEW_SOCIETY.fieldApiName]: this.newSocietyName || '',
            [WO_NEW_CUSTNAME.fieldApiName]: this.newCustomerName || '',
            [WO_NEIGHBOUR_BP.fieldApiName]: this.newBPNumber || '',

            // Remarks
            [WO_REMARK.fieldApiName]: this.remarks || ''
          }
        };
        await updateRecord(woUpdate);

        // 3) ContentVersion for each file (use FirstPublishLocationId to auto-link to WorkOrder)
        for (const f of this.fileData) {
          const fields = {};
          fields[CV_TITLE.fieldApiName] = f.filename;
          fields[CV_PATH.fieldApiName] = f.filename;
          fields[CV_DATA.fieldApiName] = f.base64;
          fields[CV_FIRSTPUBLISH.fieldApiName] = this.recordId; // auto-CDL on sync
          fields[CV_DOC_TYPE.fieldApiName] = this.findDocTypeValue(f.documentType) || f.documentType || null;
          await createRecord({ apiName: CV_OBJ.objectApiName, fields });
        }

        // 4) Update WorkStep status to 'Completed' (parity with Apex updateWorkStepStatus)
        await this.offlineCompleteWorkStep(this.workStepNameToComplete);

        this.toast('Success', 'Saved offline. Will sync when online.', 'success');
      }

      this.resetForm();
      this.handleCancel();

    } catch (e) {
      console.error(e);
      this.toast('Error', e?.body?.message || e?.message || 'Save failed', 'error');
    } finally {
      this.isLoading = false;
    }
  }

  // ------------------ Helpers ------------------

  async offlineCompleteWorkStep(targetName) {
    try {
      const recs = this.workStepsList?.data?.records || [];
      const found = recs.find(r => {
        const name = r?.fields?.Name?.value;
        return name && name.trim().toLowerCase() === (targetName || '').trim().toLowerCase();
      });

      if (!found) return; // nothing to do

      const wsId = found.fields?.Id?.value;
      if (!wsId) return;

      await updateRecord({
        fields: {
          Id: wsId,
          Status: 'Completed'
        }
      });
    } catch {
      // Offline queue will handle later or skip if not present
    }
  }

  findDocTypeValue(labelOrValue) {
    if (!labelOrValue) return null;
    const byLabel = this.documentTypes?.find(d => d.label === labelOrValue)?.value;
    const byValue = this.documentTypes?.find(d => d.value === labelOrValue)?.value;
    return byLabel || byValue || null;
  }

  resetForm() {
    this.newFlat = '';
    this.newFloor = '';
    this.newWing = '';
    this.newPlot = '';
    this.newColony = '';
    this.newRoadName = '';
    this.newLocation = '';
    this.newBuildName = '';
    this.newSocietyName = '';
    this.newCustomerName = '';
    this.newBPNumber = '';
    this.remarks = '';
    this.fileData = [];
    this.documentTypes = (this.documentTypes || []).map(d => ({ ...d, fileName: '', base64: '' }));
  }

  toast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }
}