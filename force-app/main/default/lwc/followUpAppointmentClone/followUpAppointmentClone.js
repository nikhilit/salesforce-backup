import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getLocationService } from 'lightning/mobileCapabilities';
import FORM_FACTOR from '@salesforce/client/formFactor';

import { getRecord, updateRecord, createRecord, getFieldValue } from 'lightning/uiRecordApi';
import { getObjectInfo, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';

import { graphql, gql } from 'lightning/uiGraphQLApi';

// Schema Imports
import WORKTYPE_NAME_FIELD from '@salesforce/schema/WorkOrder.WorkType.Name';

import WO_APPT_STATUS_FIELD from '@salesforce/schema/WorkOrder.Appointment_Status__c';
import WO_NEW_REMARK_FIELD from '@salesforce/schema/WorkOrder.New_Remark__c';
import WO_CHECKIN_DT_FIELD from '@salesforce/schema/WorkOrder.Check_In_Date_Time__c';
import WO_CHECKIN_LAT_FIELD from '@salesforce/schema/WorkOrder.Check_In_Location__c';
import WO_CHECKIN_LONG_FIELD from '@salesforce/schema/WorkOrder.Check_In_Location__c';
import WO_CHECKOUT_LAT_FIELD from '@salesforce/schema/WorkOrder.Check_Out_Location__c';
import WO_CHECKOUT_LONG_FIELD from '@salesforce/schema/WorkOrder.Check_Out_Location__c';
import WO_STATUS_FIELD from '@salesforce/schema/WorkOrder.Status';
import WO_CHECKOUT_DT_FIELD from '@salesforce/schema/WorkOrder.Check_Out_Date_Time__c';
import WO_FOLLOWUP_DATE_FIELD from '@salesforce/schema/WorkOrder.Follow_up_Date__c';
import WO_PAYMENT_REMARK_FIELD from '@salesforce/schema/WorkOrder.Payment_Remark__c';

import WO_SA_COUNT_FIELD from '@salesforce/schema/WorkOrder.ServiceAppointmentCount__c';

// Picklist object/field
import SERVICE_APPOINTMENT_OBJECT from '@salesforce/schema/ServiceAppointment';
import SA_FOLLOWUP_REMARKS_FIELD from '@salesforce/schema/ServiceAppointment.FollowUpRemarks__c';

// WorkOrder fields for offline updates
import WO_FOLLOWUP_REMARKS_FIELD from '@salesforce/schema/WorkOrder.Follow_up_Remarks__c';
import WO_OTHER_FOLLOWUP_REMARK_FIELD from '@salesforce/schema/WorkOrder.Other_Follow_Up_Remark__c';

// ServiceAppointment fields
import SA_OBJECT from '@salesforce/schema/ServiceAppointment';
import SA_PARENT_FIELD from '@salesforce/schema/ServiceAppointment.ParentRecordId';
import SA_STATUS_FIELD from '@salesforce/schema/ServiceAppointment.Status';
import SA_APPT_TYPE_FIELD from '@salesforce/schema/ServiceAppointment.Appointment_Type__c';
import SA_OTHER_REMARK_FIELD from '@salesforce/schema/ServiceAppointment.Other_Follow_Up_Remark__c';
import SA_FOLLOWUP_VISIT_DATE_FIELD from '@salesforce/schema/ServiceAppointment.Follow_Up_Visit_Date__c';
import SA_CHECKOUT_TS_FIELD from '@salesforce/schema/ServiceAppointment.Check_Out_Timestamp__c';
import SA_CONTACT_FIELD from '@salesforce/schema/ServiceAppointment.ContactId';
import SA_SERVICE_TERR_FIELD from '@salesforce/schema/ServiceAppointment.ServiceTerritoryId';
import SA_WORKTYPE_FIELD from '@salesforce/schema/ServiceAppointment.WorkTypeId';

// --- SA extra fields for OFFLINE parity (checkout location copy) ---
import SA_CHECKIN_LAT_FIELD from '@salesforce/schema/ServiceAppointment.Check_In_Location__c';
import SA_CHECKIN_LONG_FIELD from '@salesforce/schema/ServiceAppointment.Check_In_Location__c';
import SA_CHECKOUT_LAT_FIELD from '@salesforce/schema/ServiceAppointment.Check_Out_Location__c';
import SA_CHECKOUT_LONG_FIELD from '@salesforce/schema/ServiceAppointment.Check_Out_Location__c';


// AssignedResource
import AR_OBJECT from '@salesforce/schema/AssignedResource';
import AR_SA_FIELD from '@salesforce/schema/AssignedResource.ServiceAppointmentId';
import AR_SR_FIELD from '@salesforce/schema/AssignedResource.ServiceResourceId';

// WorkStep 
import WS_STATUS_FIELD from '@salesforce/schema/WorkStep.Status';

// Apex 
import getWorkOrderDetail from '@salesforce/apex/FollowUpAppointmentController.getWorkOrderDetail';
import asGoCollectFlowLabel from '@salesforce/label/c.AS_GoCollectFlowLabel';
import getPicklistValuesApex from '@salesforce/apex/FollowUpAppointmentController.getPicklistValues';
import createFollowUp from '@salesforce/apex/FollowUpAppointmentController.createFollowUp';
import createFollowUpWithImages from '@salesforce/apex/FollowUpAppointmentController.createFollowUpWithImages';
import getFollowUpReasonsFromMetadata from '@salesforce/apex/FollowUpAppointmentController.getFollowUpReasonsFromMetadata';
import updateGeoLocation from '@salesforce/apex/FollowUpAppointmentController.updateGeoLocation';

const LATEST_SA_QUERY = gql`
query LatestSA($woId: ID!) {
  uiapi {
    query {
      ServiceAppointment(
        first: 1,
        where: { ParentRecordId: { eq: $woId } },
        orderBy: { CreatedDate: { order: DESC } }
      ) {
        edges {
          node {
            Id
            RecordTypeId { value }
            Status { value }
            Appointment_Type__c { value }
            ContactId { value }
            ServiceTerritoryId { value }
            WorkTypeId { value }
            Check_In_Location__Latitude__s { value }
            Check_In_Location__Longitude__s { value }
          }
        }
      }
    }
  }
}
`;

const AR_FOR_SA_QUERY = gql`
query ARForSA($saId: ID!) {
  uiapi {
    query {
      AssignedResource(
        first: 200,
        where: { ServiceAppointmentId: { eq: $saId } }
      ) {
        edges {
          node {
            ServiceResourceId { value }
          }
        }
      }
    }
  }
}
`;

const WORKSTEP_FOR_WO_QUERY = gql`
query WorkStepsForWO($woId: ID!) {
  uiapi {
    query {
      WorkStep(first: 200, where: { ParentRecordId: { eq: $woId } }) {
        edges {
          node {
            Id
            Name { value }
            Status { value }
          }
        }
      }
    }
  }
}
`;

    // New Consolidated Query: Fetches WO fields AND Parent WorkType Name together
const WO_CONSOLIDATED_QUERY = gql`
  query WOConsolidated($woId: ID!) {
    uiapi {
      query {
        WorkOrder(where: { Id: { eq: $woId } }) {
          edges {
            node {
              Id
              Status { value }
              Check_In_Date_Time__c { value }
              Check_Out_Date_Time__c { value }
              Follow_up_Date__c { value }
              Payment_Remark__c { value }
              Check_In_Location__Latitude__s { value }
              Check_In_Location__Longitude__s { value }
              ServiceAppointmentCount__c { value }
              WorkType {
                Name { value }
              }
            }
          }
        }
      }
    }
  }
`;

export default class FollowUpAppointmentClone extends NavigationMixin(LightningElement) {
  @api recordId;

  followUpDate;
  followUpRemarks;
  @track isLoading = false;
  @track followUpOption = [];
  showOtherRemark = false;
  otherFollowUpRemarks;

  @track photoUploadSlots = [];
  @track noOfPhotos;

  doorLocked = false;
  isGoCollect = false;
  isFollowUpRequired = false;
  label = { asGoCollectFlowLabel };

  followUpScreen = true;
  openMainPage = false;
  openDomesticHome = false;
  imageOptional = false;

  isDomestic = false;
  showEnableMessage = false;
  message;

  followUpMetadata;
  reasonOptions;

  lat;
  long;

  @track isAppOffline = !navigator.onLine;

  // Internal cache (memory only)
  _cachedPicklistValues = [];

  // ------------------------------
  // DEBUG TOAST
  // ------------------------------
  debugToast(title, msg, variant = 'info') {
    this.dispatchEvent(new ShowToastEvent({ title, message: msg, variant }));
  }

  // ------------------------------
  // LIFECYCLE HOOKS
  // ------------------------------
  connectedCallback() {
    this.isLoading = true;
    this.debugToast('Debug', `Init. Offline: ${this.isAppOffline}`, 'info');

    window.addEventListener('online', this.handleNetworkChange);
    window.addEventListener('offline', this.handleNetworkChange);

    if (!this.isAppOffline) {
      this.fetchDataOnline();
    } else {
      this.isLoading = false;
    }
  }

  disconnectedCallback() {
    window.removeEventListener('online', this.handleNetworkChange);
    window.removeEventListener('offline', this.handleNetworkChange);
  }

  handleNetworkChange = () => {
    this.isAppOffline = !navigator.onLine;
    if (this.isAppOffline) {
      this.debugToast('Offline', 'Switched to Offline Mode', 'warning');
      if (this._cachedPicklistValues.length) {
        this.followUpOption = [...this._cachedPicklistValues];
      }
    } else {
      this.debugToast('Online', 'Switched to Online Mode', 'success');
      this.fetchDataOnline();
    }
  };

  // ------------------------------
  // ONLINE DATA FETCHING (APEX)
  // ------------------------------
  fetchDataOnline() {
    getPicklistValuesApex({ objectName: 'ServiceAppointment', fieldName: 'FollowUpRemarks__c' })
      .then((result) => {
        this.followUpOption = result;
        this._cachedPicklistValues = result;
      })
      .catch((error) => {
        this.debugToast('Debug', 'Apex picklist failed: ' + (error?.body?.message || error?.message || JSON.stringify(error)), 'error');
        if (this._cachedPicklistValues.length) this.followUpOption = [...this._cachedPicklistValues];
      });

    getWorkOrderDetail({ recId: this.recordId })
      .then((result) => {
        this.processWorkOrderLogic(result);
        this.isLoading = false;
      })
      .catch((error) => {
        this.isLoading = false;
        this.debugToast('Error', error?.body?.message || 'Unknown error', 'error');
      });
  }

  processWorkOrderLogic(result) {
    if (!result) return;
    const isCheckInDateAvailable = result.Check_In_Date_Time__c != null;
    const isWorkOrderCompleted = result.Status === 'Completed';
    const isCheckOutDateAvailable = result.Check_Out_Date_Time__c != null;
    const isFollowUp = result.Follow_up_Date__c != null;
    const isRandomVisit = result.Payment_Remark__c === 'Random Payment';

    if (isRandomVisit) {
      this.showEnableMessage = true;
      this.message = 'Random visit case, this task is not allowed.';
    }

    if (this.isGoCollect) {
      if (isCheckInDateAvailable && isWorkOrderCompleted && isCheckOutDateAvailable) {
        this.showEnableMessage = true;
        this.message = 'Task is already completed. Please refresh the WorkOrder page to continue.';
      } else if (!isCheckInDateAvailable && !isFollowUp) {
        this.showEnableMessage = true;
        this.message = 'Check-In is required. Please Check-In and refresh the WorkOrder page to continue.';
      } else if (isFollowUp) {
        this.showEnableMessage = false;
        this.debugToast(
          'Warning',
          'This is already a Follow-Up task. If you still want to create another follow-up then continue else go back to Home screen.',
          'warning'
        );
        if (!isCheckInDateAvailable && isFollowUp) {
          this.showEnableMessage = true;
          this.message = 'Check-In is required. Please Check-In and refresh the WorkOrder page to continue.';
        } else {
          this.showEnableMessage = false;
        }
      }
    }
  }

  // ------------------------------
  // OFFLINE: PICKLIST (LDS UI API)
  // ------------------------------
//   @wire(getObjectInfo, { objectApiName: SERVICE_APPOINTMENT_OBJECT })
//   saObjectInfo;

//   get saRtId() {
//     return this.saObjectInfo?.data?.defaultRecordTypeId;
//   }

//   @wire(getPicklistValuesByRecordType, {
//     objectApiName: SERVICE_APPOINTMENT_OBJECT,
//     recordTypeId: '$saRtId'
//   })
//   wiredPicklistsByRt({ data, error }) {
//     if (data?.picklistFieldValues?.FollowUpRemarks__c?.values) {
//       const vals = data.picklistFieldValues.FollowUpRemarks__c.values;
//       const mapped = vals.map((v) => ({ label: v.label, value: v.value }));
//       this._cachedPicklistValues = mapped;

//       // only overwrite UI if offline OR nothing loaded yet
//       if (this.isAppOffline || !this.followUpOption?.length) {
//         this.followUpOption = mapped;
//       }

//       this.debugToast('Debug', `Picklist Loaded (LDS): ${mapped.length}`, 'success');
//     } else if (error) {
//       const msg = error?.body?.message || error?.message || JSON.stringify(error);
//       this.debugToast('Debug', `Picklist LDS error: ${msg}`, 'error');
//     }
//   }

  // ------------------------------
  // OFFLINE: WORK ORDER CACHED DATA
  // ------------------------------

    // @wire(getRecord, {
    // recordId: '$recordId',
    // fields: [
    //     WO_CHECKIN_DT_FIELD,
    //     WO_STATUS_FIELD,
    //     WO_CHECKOUT_DT_FIELD,
    //     WO_FOLLOWUP_DATE_FIELD,
    //     WO_PAYMENT_REMARK_FIELD
    // ]
    // })
    // wiredWorkOrderLogic({ data, error }) {
    // if (data) {
    //     // Build the same "result" shape your method expects
    //     const result = {
    //     Check_In_Date_Time__c: getFieldValue(data, WO_CHECKIN_DT_FIELD),
    //     Status: getFieldValue(data, WO_STATUS_FIELD),
    //     Check_Out_Date_Time__c: getFieldValue(data, WO_CHECKOUT_DT_FIELD),
    //     Follow_up_Date__c: getFieldValue(data, WO_FOLLOWUP_DATE_FIELD),
    //     Payment_Remark__c: getFieldValue(data, WO_PAYMENT_REMARK_FIELD)
    //     };

    //     this.processWorkOrderLogic(result);

    //     // Debug
    //     this.showToast(
    //     'Debug',
    //     `WO Logic (LDS) applied. Status=${result.Status}, FollowUp=${!!result.Follow_up_Date__c}`,
    //     'info'
    //     );
    // } else if (error) {
    //     this.showToast(
    //     'Debug',
    //     'WO Logic LDS error: ' + (error?.body?.message || error?.message || JSON.stringify(error)),
    //     'error'
    //     );
    // }
    // }

  
    

    // ------------------------------
    // OFFLINE: WORK ORDER DATA (Consolidated via GraphQL)
    // ------------------------------
    get gqlWOConsolidatedVars() {
        return this.recordId ? { woId: this.recordId } : undefined;
    }

    @wire(graphql, { query: WO_CONSOLIDATED_QUERY, variables: '$gqlWOConsolidatedVars' })
    wiredWorkOrderLogic({ data, errors }) {
        if (data) {
            const node = data.uiapi?.query?.WorkOrder?.edges?.[0]?.node;
            
            if (node) {
                const workTypeName = node.WorkType?.Name?.value || ''; 
                
                const allowed = (this.label.asGoCollectFlowLabel || '')
                    .split(',')
                    .map(s => (s || '').trim().toLowerCase());
                
                this.isGoCollect = allowed.indexOf(workTypeName.toLowerCase()) !== -1;

                // 2. Prepare the result object (Child Fields)
                // Mapping GraphQL node structure to the flat object your logic expects
                const result = {
                    Check_In_Date_Time__c: node.Check_In_Date_Time__c?.value,
                    Status: node.Status?.value,
                    Check_Out_Date_Time__c: node.Check_Out_Date_Time__c?.value,
                    Follow_up_Date__c: node.Follow_up_Date__c?.value,
                    Payment_Remark__c: node.Payment_Remark__c?.value
                };
                this._cachedWO = {
                                  status: node.Status?.value,
                                  checkInLat: node.Check_In_Location__Latitude__s?.value,
                                  checkInLong: node.Check_In_Location__Longitude__s?.value,
                                  saCount: node.ServiceAppointmentCount__c?.value
                                };


                // 3. Run the logic (Now guaranteed to have correct isGoCollect value)
                this.processWorkOrderLogic(result);

                // Debug
                this.debugToast(
                    'Debug', 
                    `Offline Logic Run. isGoCollect=${this.isGoCollect}, Status=${result.Status}`, 
                    'success'
                );
            }
        } else if (errors) {
            this.debugToast(
                'Debug', 
                'WO GraphQL Error: ' + JSON.stringify(errors), 
                'error'
            );
        }
    }


  // ------------------------------
  // Metadata (Apex cacheable)
  // ------------------------------
  @wire(getFollowUpReasonsFromMetadata)
  wiredFollowUpMetadata({ error, data }) {
    if (data) {
        this.followUpMetadata = data;

        // keep dropdown source ready from metadata
        const metaOptions = data.map(r => ({
        label: r.Label,
        value: r.Label
        }));

        this.reasonOptions = metaOptions;

        if (this.isAppOffline) {
        this.followUpOption = metaOptions;
        this._cachedPicklistValues = metaOptions;
        this.showToast('Debug', `Offline Picklist from Metadata: ${metaOptions.length}`, 'success');
        }
    } else if (error) {
      console.error('Metadata load error', error);
    }
  }

  // ------------------------------
  // GRAPHQL WIRES (READ ONLY)
  // ------------------------------
  get gqlLatestSAVariables() {
    return this.recordId ? { woId: this.recordId } : undefined;
  }

  @wire(graphql, { query: LATEST_SA_QUERY, variables: '$gqlLatestSAVariables' })
  wiredLatestSA(resp) {
    this._latestSAResp = resp;
  }

  get latestSAId() {
    const edges = this._latestSAResp?.data?.uiapi?.query?.ServiceAppointment?.edges || [];
    return edges?.[0]?.node?.Id;
  }

  get latestSANode() {
    const edges = this._latestSAResp?.data?.uiapi?.query?.ServiceAppointment?.edges || [];
    return edges?.[0]?.node || null;
  }

  get gqlARVariables() {
    return this.latestSAId ? { saId: this.latestSAId } : undefined;
  }

  @wire(graphql, { query: AR_FOR_SA_QUERY, variables: '$gqlARVariables' })
  wiredAssignedResources(resp) {
    this._arResp = resp;
  }

  get assignedServiceResourceIds() {
    const edges = this._arResp?.data?.uiapi?.query?.AssignedResource?.edges || [];
    return edges
      .map((e) => e?.node?.ServiceResourceId?.value)
      .filter(Boolean);
  }

  get gqlWorkStepVars() {
    return this.recordId ? { woId: this.recordId } : undefined;
  }

  @wire(graphql, { query: WORKSTEP_FOR_WO_QUERY, variables: '$gqlWorkStepVars' })
  wiredWorkSteps(resp) {
    this._wsResp = resp;
  }

  get workStepsForWO() {
    const edges = this._wsResp?.data?.uiapi?.query?.WorkStep?.edges || [];
    return edges.map((e) => ({
      id: e?.node?.Id,
      name: e?.node?.Name?.value,
      status: e?.node?.Status?.value
    })).filter((x) => x.id);
  }

  // ------------------------------
  // EVENT HANDLERS
  // ------------------------------
  handleDateChange(event) { this.followUpDate = event.detail.value; }
  handleOtherRemarksChange(event) { this.otherFollowUpRemarks = event.detail.value; }

  handleRemarksChange(event) {
    this.followUpRemarks = event.detail.value;
    this.showOtherRemark = (this.followUpRemarks?.toLowerCase() === 'other');

    const selectedValue = this.followUpRemarks?.toLowerCase();
    const selectedMetadata = this.followUpMetadata?.find(meta => meta.Label?.toLowerCase() === selectedValue);

    if (selectedMetadata) {
      const imageRequired = selectedMetadata.Image_Required__c;
      const imageCount = selectedMetadata.Image_count__c;
      this.isFollowUpRequired = selectedMetadata.Follow_Up_Required__c;

      if (imageRequired) {
        this.noOfPhotos = imageCount;
        this.imageOptional = selectedMetadata.Image_Optional__c;
        this.setPhotoUploadSlots();
        this.doorLocked = true;
      } else {
        this.doorLocked = false;
        this.noOfPhotos = 0;
        this.imageOptional = false;
        this.photoUploadSlots = [];
      }
    } else {
      this.doorLocked = false;
      this.noOfPhotos = 0;
      this.photoUploadSlots = [];
      this.imageOptional = false;
      this.isFollowUpRequired = false;
    }
  }

  // ------------------------------
  // SAVE LOGIC
  // ------------------------------
  async handleSave() {
    if (!this.followUpRemarks) {
      this.debugToast('Error', 'Please enter the remarks.', 'error');
      return;
    }
    if (this.isFollowUpRequired && !this.followUpDate) {
      this.debugToast('Error', 'Please enter follow-up date.', 'error');
      return;
    }

    if (!this.isGoCollect && FORM_FACTOR !== 'Large') {
      if (this.doorLocked) {
        const allFilesSelected =
          this.photoUploadSlots.length === this.noOfPhotos &&
          this.photoUploadSlots.every(slot => slot.fileName && slot.base64Data);

        if (!allFilesSelected && !this.imageOptional) {
          this.debugToast('Warning', 'Please capture the photos', 'warning');
          return;
        }
        this.getMobileLocation();
      } else {
        this.saveData();
      }
    } else {
      this.saveData();
    }
  }

  saveData() {
    const payload = {
      parentRecordId: this.recordId,
      followUpDate: this.followUpDate,
      followUpRemarks: this.followUpRemarks,
      otherRemark: this.otherFollowUpRemarks,
      hasImages: this.doorLocked,
      base64Images: []
    };

    if (this.doorLocked) {
      const allFilesSelected =
        this.photoUploadSlots.length === this.noOfPhotos &&
        this.photoUploadSlots.every(slot => slot.fileName && slot.base64Data);

      const selectedMetadata = this.followUpMetadata?.find(item => item.Label === this.followUpRemarks);
      const smsRequired = selectedMetadata?.SMS_requried__c || false;

      if (!allFilesSelected && !this.imageOptional) {
        this.debugToast('Warning', 'Please capture the photos', 'warning');
        return;
      }

      payload.base64Images = this.photoUploadSlots.map(slot => slot.base64Data);
      payload.smsRequired = smsRequired;
    }

    if (this.isAppOffline) this.saveFollowUpOffline(payload);
    else this.saveFollowUpOnline(payload);
  }

  async saveFollowUpOnline(payload) {
    this.isLoading = true;
    const isWithImages = payload.hasImages;
    try {
      let result;
      if (isWithImages) result = await createFollowUpWithImages(payload);
      else result = await createFollowUp(payload);

      if (result?.success) {
        this.debugToast('Success', result.message, 'success');
        if (result.message === 'Work Order updated.') history.back();
        else this.navigateToWorkOrderInFSL(this.recordId);
      } else {
        this.debugToast('Error', result?.message || 'Unknown error', 'error');
      }
    } catch (error) {
      console.error('Save online failed', error);
      this.debugToast('Error', error?.body?.message || 'Save failed', 'error');
    } finally {
      this.isLoading = false;
    }
  }

  // ------------------------------
  // OFFLINE SAVE LOGIC
  // ------------------------------
  async saveFollowUpOffline(payload) {
    this.isLoading = true;
    let step = 'START';

    try {
      this.debugToast('Offline Debug', 'Offline save started', 'info');

      // STEP 1: cached SA
      step = 'FETCH_SA';
      const saNode = this.latestSANode;
      const currentSAId = saNode?.Id;

      if (!currentSAId) {
        this.debugToast('Offline Debug', 'FAILED at FETCH_SA → Service Appointment not cached', 'error');
        return;
      }
      this.debugToast('Offline Debug', `SA cached: ${currentSAId}`, 'success');

      // cached WO values needed for parity
      // const woCheckInLat = getFieldValue(this.wiredWorkOrder?.data, WO_CHECKIN_LAT_FIELD);
      // const woCheckInLong = getFieldValue(this.wiredWorkOrder?.data, WO_CHECKIN_LONG_FIELD);
      // const woSaCount = getFieldValue(this.wiredWorkOrder?.data, WO_SA_COUNT_FIELD);

      if (!this._cachedWO) {
        this.debugToast(
          'Offline Debug',
          'WorkOrder data not cached yet. Please open the WO once and try again.',
          'error'
        );
        return;
      }

      const woCheckInLat = this._cachedWO?.checkInLat;
      const woCheckInLong = this._cachedWO?.checkInLong;
      const woSaCount = this._cachedWO?.saCount;


      const nowIso = new Date().toISOString();
      const saCheckInLat = saNode?.Check_In_Location__Latitude__s?.value;
      const saCheckInLong = saNode?.Check_In_Location__Longitude__s?.value;

      // STEP 2: Update current SA (Completed) + checkout parity
      step = 'UPDATE_SA';
      const saFields = {
        Id: currentSAId,
        [SA_STATUS_FIELD.fieldApiName]: 'Completed',
        [SA_APPT_TYPE_FIELD.fieldApiName]: 'Completed',
        [SA_FOLLOWUP_REMARKS_FIELD.fieldApiName]: payload.followUpRemarks,
        [SA_OTHER_REMARK_FIELD.fieldApiName]: payload.otherRemark,
        [SA_CHECKOUT_TS_FIELD.fieldApiName]: nowIso
      };

      // if (saCheckInLat != null) saFields[SA_CHECKOUT_LAT_FIELD.fieldApiName] = saCheckInLat;
      // if (saCheckInLong != null) saFields[SA_CHECKOUT_LONG_FIELD.fieldApiName] = saCheckInLong;

      if (payload.followUpDate) {
        saFields[SA_FOLLOWUP_VISIT_DATE_FIELD.fieldApiName] = payload.followUpDate?.slice(0, 10);
      }

      await updateRecord({ fields: saFields });
      this.debugToast('Offline Debug', 'Service Appointment updated', 'success');

      let followUpSAId = null;

      // STEP 3: Follow-up branch
      if (payload.followUpDate) {
        step = 'UPDATE_WO_FOLLOWUP';

        const newCount = (woSaCount == null ? 0 : Number(woSaCount)) + 1;

        await updateRecord({
          fields: {
            Id: payload.parentRecordId,
            [WO_STATUS_FIELD.fieldApiName]: 'Follow Up',
            [WO_APPT_STATUS_FIELD.fieldApiName]: 'Follow Up',
            [WO_FOLLOWUP_DATE_FIELD.fieldApiName]: payload.followUpDate?.slice(0, 10),
            [WO_FOLLOWUP_REMARKS_FIELD.fieldApiName]: payload.followUpRemarks,
            [WO_OTHER_FOLLOWUP_REMARK_FIELD.fieldApiName]: payload.otherRemark,
            [WO_NEW_REMARK_FIELD.fieldApiName]: payload.followUpRemarks,

            // clear check-in 
            [WO_CHECKIN_DT_FIELD.fieldApiName]: null,
            [WO_CHECKIN_LAT_FIELD.fieldApiName]: null,
            [WO_CHECKIN_LONG_FIELD.fieldApiName]: null,

            // increment count
            [WO_SA_COUNT_FIELD.fieldApiName]: newCount
          }
        });

        this.debugToast('Offline Debug', 'Work Order updated for Follow-Up', 'success');

        // 3B: Create follow-up SA (In Progress)
        step = 'CREATE_FOLLOWUP_SA';

        const fields = {};
        fields[SA_PARENT_FIELD.fieldApiName] = payload.parentRecordId;
        fields[SA_STATUS_FIELD.fieldApiName] = 'In Progress';
        fields[SA_APPT_TYPE_FIELD.fieldApiName] = 'Follow Up';
        fields[SA_FOLLOWUP_VISIT_DATE_FIELD.fieldApiName] = payload.followUpDate?.slice(0, 10);

        // copy from cached SA
        const contactId = saNode?.ContactId?.value;
        const terrId = saNode?.ServiceTerritoryId?.value;
        const wtId = saNode?.WorkTypeId?.value;

        if (contactId) fields[SA_CONTACT_FIELD.fieldApiName] = contactId;
        if (terrId) fields[SA_SERVICE_TERR_FIELD.fieldApiName] = terrId;
        if (wtId) fields[SA_WORKTYPE_FIELD.fieldApiName] = wtId;

        const created = await createRecord({ apiName: SA_OBJECT.objectApiName, fields });
        followUpSAId = created?.id;

        this.debugToast('Offline Debug', `Follow-Up SA created: ${followUpSAId}`, 'success');

        step = 'COPY_AR';
        try {
          const srIds = this.assignedServiceResourceIds;
          if (followUpSAId && Array.isArray(srIds) && srIds.length) {
            for (const srId of srIds) {
              await createRecord({
                apiName: AR_OBJECT.objectApiName,
                fields: {
                  [AR_SA_FIELD.fieldApiName]: followUpSAId,
                  [AR_SR_FIELD.fieldApiName]: srId
                }
              });
            }
          }
          this.debugToast('Offline Debug', 'Assigned Resources copied', 'success');
        } catch (e) {
          this.debugToast('Offline Debug', 'AssignedResource copy failed (skipped)', 'warning');
        }

        // 3D: WorkStep parity (clearWorkStepStatus → set ALL to New)
        step = 'WORKSTEP_CLEAR';
        await this._setAllWorkStepsStatus('New');

        this.debugToast('Offline Debug', 'WorkSteps cleared to New', 'success');
      } else {
        // STEP 4: No follow-up -> Complete WO 
        step = 'COMPLETE_WO';

        const woFields = {
                  Id: payload.parentRecordId,
                  [WO_STATUS_FIELD.fieldApiName]: 'Completed',
                  [WO_APPT_STATUS_FIELD.fieldApiName]: 'Completed',
                  [WO_CHECKOUT_DT_FIELD.fieldApiName]: nowIso,
                  [WO_FOLLOWUP_REMARKS_FIELD.fieldApiName]: payload.followUpRemarks,
                  [WO_OTHER_FOLLOWUP_REMARK_FIELD.fieldApiName]: payload.otherRemark,
                  [WO_NEW_REMARK_FIELD.fieldApiName]: payload.followUpRemarks   
                };

                // parity: checkout location = checkin location (WO)
                // if (woCheckInLat != null) woFields[WO_CHECKOUT_LAT_FIELD.fieldApiName] = woCheckInLat;
                // if (woCheckInLong != null) woFields[WO_CHECKOUT_LONG_FIELD.fieldApiName] = woCheckInLong;

                await updateRecord({ fields: woFields });


        // ensure SA has checkout timestamp already (set above) - done

        this.debugToast('Offline Debug', 'Work Order & SA completed', 'success');

        // WorkStep parity (updateWorkStepStatuses list)
        step = 'WORKSTEP_COMPLETE';
        await this._completeSelectedWorkSteps([
          'Follow Up Visit',
          'Check Out',
          'Disconnection Activity',
          'Disconnection Notice',
          'Billing Distribution',
          'Reconnection Activity',
          'Payment Capture'
        ]);

        this.debugToast('Offline Debug', 'WorkSteps completed (selected)', 'success');
      }

      // STEP 5: Offline image staging
      if (payload.hasImages && this.photoUploadSlots?.length) {
        step = 'IMAGE_STAGE';
        const targetId = followUpSAId || currentSAId;
        await this._stageImagesOfflineToTarget(targetId);
        this.debugToast('Offline Debug', 'Images staged offline', 'success');
      }

      // DONE
      this.debugToast('Success', 'Saved offline. Changes will sync when connectivity returns.', 'success');

      if (!payload.followUpDate) history.back();
      else this.navigateToWorkOrderInFSL(this.recordId);
    } catch (e) {
      this.debugToast('Offline Debug', `FAILED at step: ${step}`, 'error');
      if (e?.body?.message) this.debugToast('Offline Debug', e.body.message, 'error');
      // eslint-disable-next-line no-console
      console.error('Offline save failed:', e);
    } finally {
      this.isLoading = false;
    }
  }

  // ------------------------------
  // WorkStep helpers 
  // ------------------------------
  async _setAllWorkStepsStatus(statusValue) {
    const steps = this.workStepsForWO || [];
    if (!steps.length) {
      this.debugToast('Offline Debug', 'No WorkSteps cached. Skipping WorkStep parity.', 'warning');
      return;
    }

    for (const ws of steps) {
      try {
        await updateRecord({
          fields: {
            Id: ws.id,
            [WS_STATUS_FIELD.fieldApiName]: statusValue
          }
        });
      } catch (e) {
      }
    }
  }

  async _completeSelectedWorkSteps(namesToComplete) {
    const steps = this.workStepsForWO || [];
    if (!steps.length) {
      this.debugToast('Offline Debug', 'No WorkSteps cached. Skipping WorkStep parity.', 'warning');
      return;
    }

    const setNames = new Set((namesToComplete || []).map((n) => (n || '').toLowerCase()));

    for (const ws of steps) {
      const nm = (ws.name || '').toLowerCase();
      if (!setNames.has(nm)) continue;

      try {
        await updateRecord({
          fields: {
            Id: ws.id,
            [WS_STATUS_FIELD.fieldApiName]: 'Completed'
          }
        });
      } catch (e) {
      }
    }
  }

  // ------------------------------
  // Offline image staging
  // ------------------------------
  async _stageImagesOfflineToTarget(targetId) {
    const slots = Array.isArray(this.photoUploadSlots) ? this.photoUploadSlots : [];
    const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

    for (const slot of slots) {
      try {
        const title = slot.label || 'Photo';
        const path = `${title}.jpg`;
        const base64 = slot.base64Data ? this._stripDataUrl(slot.base64Data) : null;

        if (base64 && base64.length > 0) {
          await createRecord({
            apiName: 'ContentVersion',
            fields: {
              Title: title,
              PathOnClient: path,
              VersionData: base64,
              FirstPublishLocationId: targetId
            }
          });
          await delay(250);
        }
      } catch (err) {
        console.error('[OfflineImageStage] error:', err);
      }
    }
  }

  _stripDataUrl(b64) {
    if (!b64) return b64;
    const idx = b64.indexOf('base64,');
    return idx >= 0 ? b64.substring(idx + 7) : b64;
  }

  // ------------------------------
  // UTILITIES
  // ------------------------------
  handleFile(event) { this.photoUploadSlots = event.detail.steps; }

  setPhotoUploadSlots() {
    const count = this.noOfPhotos || 0;
    this.photoUploadSlots = Array.from({ length: count }, (_, i) => ({
      id: i + 1,
      index: i + 1,
      label: `Photo ${i + 1}`,
      name: `fileUploader${i + 1}`,
      fileName: '',
      uploaded: false,
      previewUrl: '',
      base64Data: ''
    }));
  }

  handleCancel() { history.back(); }
  handleChildEvent() { this.openMainPage = true; }

  getMobileLocation() {
    this.isLoading = true;
    const locationService = getLocationService();

    if (!locationService || !locationService.isAvailable()) {
      this.debugToast('LocationService Not Available', 'Please use a GPS-enabled mobile device.', 'error');
      this.isLoading = false;
      return;
    }

    locationService.getCurrentPosition({ enableHighAccuracy: true })
      .then((result) => {
        this.lat = result.coords.latitude;
        this.long = result.coords.longitude;

        if (this.isAppOffline) {
          this.saveData();
          return;
        }

        updateGeoLocation({ workOrderId: this.recordId, latitude: this.lat, longitude: this.long })
          .then(() => this.saveData())
          .catch((error) => {
            this.debugToast('Error', error?.body?.message || JSON.stringify(error), 'error');
            this.saveData();
          });
      })
      .catch(() => {
        this.debugToast('Warning', 'Please enable your device location.', 'warning');
      })
      .finally(() => {
        this.isLoading = false;
      });
  }

  navigateToWorkOrderInFSL(workOrderId) {
    this[NavigationMixin.Navigate]({
      type: 'standard__webPage',
      attributes: { url: `com.salesforce.fieldservice://v1/sObject/${workOrderId}/overview` }
    });
  }
}