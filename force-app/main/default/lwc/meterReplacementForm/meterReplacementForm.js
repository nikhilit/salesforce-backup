import { LightningElement, api, wire, track } from 'lwc';
import getWorkOrderDetails from '@salesforce/apex/MeterReplacementController.getWorkOrderDetails';
import savePhotoUploadsMeter from '@salesforce/apex/MeterReplacementController.savePhotoUploadsMeter';
import savePhotoUploadsFinal from '@salesforce/apex/MeterReplacementController.savePhotoUploadsFinal';
import savePhotoUploadsLPG from '@salesforce/apex/MeterReplacementController.savePhotoUploadsLPG';
import savePhotoUploadsReversal from '@salesforce/apex/MeterReplacementController.savePhotoUploadsReversal';
import saveMeterReplDetails from '@salesforce/apex/MeterReplacementController.saveMeterReplDetails';
import createCRMCaseAndReturnBP from '@salesforce/apex/MeterReplacementController.createCRMCaseAndReturnBP';
import uploadFileUnsafeLetter from '@salesforce/apex/MeterReplacementController.uploadFileUnsafeLetter';
import saveFinalRemark from '@salesforce/apex/MeterReplacementController.saveFinalRemark';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import FORM_FACTOR from '@salesforce/client/formFactor';

// ---------- OFFLINE IMPORTS ----------
import { graphql, gql } from 'lightning/uiGraphQLApi';
import { createRecord, updateRecord } from 'lightning/uiRecordApi';

// ---------- SCHEMA IMPORTS FOR OFFLINE ----------
// WorkOrder
import WO_OBJECT from '@salesforce/schema/WorkOrder';
import WO_ID_FIELD from '@salesforce/schema/WorkOrder.Id';
import WO_OLD_METER_NUM from '@salesforce/schema/WorkOrder.Old_Meter_Number__c';
import WO_NEW_METER_NUM from '@salesforce/schema/WorkOrder.New_Meter_Number__c';
import WO_PREV_READING from '@salesforce/schema/WorkOrder.Previous_Meter_Reading__c';
import WO_OLD_READING from '@salesforce/schema/WorkOrder.Old_Meter_Reading__c';
import WO_NEW_READING from '@salesforce/schema/WorkOrder.New_Meter_Reading__c';
import WO_METER_REPLACED from '@salesforce/schema/WorkOrder.Meter_replaced__c';
import WO_METER_ALREADY_REPLACED from '@salesforce/schema/WorkOrder.Meter_already_replaced__c';
import WO_METER_NOT_REPLACED from '@salesforce/schema/WorkOrder.Meter_not_replaced__c';
import WO_LEAKAGE_OBSERVED from '@salesforce/schema/WorkOrder.Gas_Leakage_Observed__c';
import WO_LEAKAGE_LOCATION from '@salesforce/schema/WorkOrder.Leakage_Location__c';
import WO_MCV_STATUS from '@salesforce/schema/WorkOrder.MCV_Status__c';
import WO_GAS_DETECTOR from '@salesforce/schema/WorkOrder.First_Reading_of_the_gas_detector__c';
import WO_RIV_CLOSED from '@salesforce/schema/WorkOrder.RIV_closed_checkbox__c';
import WO_CASE_REMARK from '@salesforce/schema/WorkOrder.Case_Remark__c';
import WO_INLET_OUTLET_REV from '@salesforce/schema/WorkOrder.Inlet_Outlet_Reversal_Needed__c';
import WO_REV_CORRECTION from '@salesforce/schema/WorkOrder.Reversal_Correction_Details__c';
import WO_DISCONNECT_REQ from '@salesforce/schema/WorkOrder.Disconnection_Required__c';
import WO_DISCONNECT_REMARK from '@salesforce/schema/WorkOrder.Disconnection_from_Outside_Remark__c';
import WO_MCV_PLUG_REQ from '@salesforce/schema/WorkOrder.MCV_Plugging_Required__c';
import WO_MCV_PLUG_REMARK from '@salesforce/schema/WorkOrder.MCV_Plugging_Remark__c';
import WO_COUNTER_REMARKS from '@salesforce/schema/WorkOrder.Meter_Counter_Remarks__c';
import WO_METER_SOUND from '@salesforce/schema/WorkOrder.Add_Meter_Sound__c';
import WO_OLD_RUSTED from '@salesforce/schema/WorkOrder.Old_Meter_Rusted__c';
import WO_COUNTER_SMOKEY from '@salesforce/schema/WorkOrder.Counter_defective_smokey__c';
import WO_METER_FAULTY from '@salesforce/schema/WorkOrder.Meter_Faulty__c';
import WO_METER_NOT_RUNNING from '@salesforce/schema/WorkOrder.Meter_Not_Running__c';
import WO_RUBBER_HOSE from '@salesforce/schema/WorkOrder.Rubber_Hose_Condition__c';
import WO_FINAL_REMARK from '@salesforce/schema/WorkOrder.Final_Remark__c';
import WO_GAS_TYPE from '@salesforce/schema/WorkOrder.Gas_Type__c';


// WorkStep (for offline completion of "Data Captures Detail")
import WS_ID_FIELD from '@salesforce/schema/WorkStep.Id';
import WS_STATUS_FIELD from '@salesforce/schema/WorkStep.Status';


// ServiceAppointment
import SA_OBJECT from '@salesforce/schema/ServiceAppointment';
import SA_METER_UNSAFE from '@salesforce/schema/ServiceAppointment.Meter_Unsafe__c';
import SA_METER_INACCESSIBLE from '@salesforce/schema/ServiceAppointment.Meter_Inaccessible__c';
import SA_CUST_READY_SHIFT from '@salesforce/schema/ServiceAppointment.Customer_Ready_To_Shift__c';
import SA_ALT_PHONE from '@salesforce/schema/ServiceAppointment.Alternate_Phone__c';
import SA_CORRECT_ADDR from '@salesforce/schema/ServiceAppointment.Correct_Address__c';
// Tenant fields may or may not exist in your org – if not, comment them out
// import SA_TENANT_NAME from '@salesforce/schema/ServiceAppointment.Tenant_Name__c';
// import SA_TENANT_MOBILE from '@salesforce/schema/ServiceAppointment.Tenant_Mobile__c';

// Case
import CASE_OBJECT from '@salesforce/schema/Case';
import CASE_SUBJECT from '@salesforce/schema/Case.Subject';
import CASE_ORIGIN from '@salesforce/schema/Case.Origin';
import CASE_STATUS from '@salesforce/schema/Case.Status';
import CASE_WO from '@salesforce/schema/Case.Work_Order__c';
import CASE_DESC from '@salesforce/schema/Case.Description';

// ContentVersion (for offline file/image creation)
import CV_OBJECT from '@salesforce/schema/ContentVersion';
import CV_TITLE from '@salesforce/schema/ContentVersion.Title';
import CV_PATH from '@salesforce/schema/ContentVersion.PathOnClient';
import CV_DATA from '@salesforce/schema/ContentVersion.VersionData';
import CV_LINK_ID from '@salesforce/schema/ContentVersion.FirstPublishLocationId';

// ---------- GraphQL for OFFLINE WorkOrder fetch ----------
const WO_OFFLINE_QUERY = gql`
  query getWODetails($recordId: ID) {
    uiapi {
      query {
        WorkOrder(where: { Id: { eq: $recordId } }) {
          edges {
            node {
              Id
              WorkOrderNumber { value }
              BP_Number__c { value }
              Old_Meter_Number__c { value }
              Is_The_Customer_Available_Meter_Repl__c { value }
              Account {
                Previous_Meter_Reading__c { value }
              }
              ServiceAppointments {
                edges {
                  node {
                    Id
                    Meter_Unsafe__c { value }
                    Meter_Inaccessible__c { value }
                    Customer_Ready_To_Shift__c { value }
                    Alternate_Phone__c { value }
                    Correct_Address__c { value }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
`;

// ---------- GraphQL for OFFLINE WorkStep fetch ----------
const WS_OFFLINE_QUERY = gql`
  query getDataCaptureStep($recordId: ID, $stepName: String) {
    uiapi {
      query {
        WorkStep(
          where: {
            ParentRecordId: { eq: $recordId }
            Name: { eq: $stepName }
          }
          first: 1
        ) {
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


export default class MeterReplacementForm extends NavigationMixin(LightningElement) {
  @api recordId;

  /* ---------- tracked model variables ---------- */
  @track workOrder;
  @track serviceAppointmentId;

  @track load = false;
  @track isload = false;
  @track isCustomerAvailable = true;
  @track FirstPage = true;
  @track finalSlotsCount = 0;
  @track finalUploadedCount = 0;
  @track isFinalSubmit = false;

  /* ---------- photo slots arrays ---------- */
  @track reversalPhotoUploadSlots = [];
  @track lpgPhotoUploadSlots = [];
  @track photoUploadSlots = [];
  @track meterImageUploadSlots = [];
  @track newMeterPhotoSlots = [];
  @track oldMeterPhotoSlots = [];
  @track mcvClosedPhotoSlots = [];
  @track meterUnsafePhotoSlots = [];
  @track meterInaccessiblePhotoSlots = [];

  @track meterSoundPhotoSlots = [];
  @track oldMeterRustedPhotoSlots = [];
  @track counterDefectivePhotoSlots = [];
  @track meterFaultyPhotoSlots = [];
  @track meterNotRunningPhotoSlots = [];

  @track mcvPluggingPhotoSlots = [];
  @track mcvPluggingPhotoUploaded = false;
  @track mcvPluggingPhotoMissing = false;

  @track rivClosedPhotoSlots = [];
  @track rivClosedPhotoUploaded = false;
  @track rivClosedPhotoMissing = false;

  // Inlet/Outlet rectification
  @track inletOutletValue = ''; // 'Yes' | 'No'
  inletOutletOptions = [
    { label: 'Yes', value: 'Yes' },
    { label: 'No', value: 'No' }
  ];

  @track showInletOutletRectification = false;

  // Leakage Case Number field
  @track leakageCaseNumber = '';
  @track showLeakageCaseNumber = false;

  // Old meter working + rectification remark
  @track oldMeterWorking = false;
  @track showRectificationRemarkDropdown = false;
  @track rectificationRemark = '';
  rectificationRemarkOptions = [
    { label: 'Rectification done on-site', value: 'Rectification done on-site' },
    { label: 'Old meter OK', value: 'Old meter OK' },
    { label: 'Meter replacement not required', value: 'Meter replacement not required' }
  ];
  @track showProceedReplacementFromInletOutlet = false;

  noOfPhotosFinal = 8;
  noOfPhotos = 2;
  noOfPhotosMeter = 2;
  noOfPhotosLpg = 1;
  uploadedFinalImageKeys = new Set();


  /* ---------- page flags ---------- */
  @track showFinalPage = false;
  @track showReversalImages = false;
  @track imageUploadPage = true;
  @track showBeforeAfterMeterUpload = false;

  /* ---------- primary meter fields ---------- */
  @track previousMeterNumber = '';
  @track previousMeterReading = '';

  @track newMeterNumber = '';
  @track newMeterReading = '';
  @track oldMeterReadingCaptured = '';

  /* ---------- meter condition flags ---------- */
  @track addMeterSound = false;
  @track meterSoundRemarks = '';

  @track oldMeterRusted = false;
  @track oldMeterRustedRemarks = '';

  @track counterDefectiveSmoke = false;
  @track counterDefectiveRemarks = '';

  @track meterFaulty = false;
  @track meterFaultyRemarks = '';

  @track meterNotRunning = false;
  @track meterNotRunningRemarks = '';

  // Storage dropdown
  @track storageLocation = '';
  storageLocationOptions = [
    { label: 'Projects', value: 'Projects' },
    { label: 'Emergency', value: 'Emergency' },
    { label: 'Other WO', value: 'Other WO' }
  ];

  // visibility flags
  @track showAfterValidation = false;
  @track showMeterNotReplacedDisplay = false;
  @track showMeterAlreadyReplacedDisplay = false;

  /* ---------- accessibility flags ---------- */
  @track meterUnsafe = false;
  @track meterUnsafeRemarks = '';
  @track meterUnsafeReadyToShift = false;

  @track meterInaccessible = false;
  @track meterInaccessibleRemarks = '';
  @track meterInaccessibleReadyToShift = false;

  /* ---------- recurring steps ---------- */
  @track isDisconnectionRequired = false;
  @track showDisconnectionRemark = false;
  @track disconnectionRemark = '';

  @track rivClosed = false;

  @track isMCVPluggingRequired = false;
  @track mcvPluggingRemark = '';

  @track gasLeakageObserved = '';
  gasLeakageOptions = [
    { label: 'Yes', value: 'Yes' },
    { label: 'No', value: 'No' }
  ];

  @track rubberHoseCondition = '';
  rubberHoseOptions = [
    { label: 'Yes', value: 'Yes' },
    { label: 'No', value: 'No' }
  ];

  /* ---------- replacement flow flags ---------- */
  @track showNewMeterReading = false;

  /* ---------- other flags & fields ---------- */
  @track showCounterStatus = false;
  @track meterCounterStatus = '';
  @track meterCounterRemarks = '';

  @track showReversal = false;
  @track reversalCorrectionDetails = '';

  @track showGasType = true;
  @track gasType = '';

  @track showGasLeakage = true;
  @track showMCVStatus = false;
  @track mcvStatus = '';
  @track showGasDetectorReading = false;
  @track gasDetectorReading = '';
  @track showMCVClosed = false;
  @track showMCVClosedPhotoUpload = false;
  @track mcvClosedPhotoUploaded = false;
  @track mcvClosedPhotoMissing = false;

  @track showBPNumber = false;
  @track bpNumber = '';

  @track remarks = '';
  @track remarksPostMCV = '';

  @track showRemarksAfterUploadOrMCV = false;

  @track showUnsafeLetterUpload = false;
  @track unsafeLetterFile;
  @track unsafeLetterFileName = '';

  @track showSubmit = false;
  @track dataCaptureWorkStepId;


  // compression tuning
  IMG_MAX_WIDTH = 1024;
  IMG_QUALITY = 0.65;
  MIN_BASE64_LENGTH = 60;
  UPLOAD_CHUNK_SIZE = 2;
  UPLOAD_RETRY_COUNT = 1;

  /* ---------- contacts / tenant ---------- */
  @track alternatePhone = '';
  @track correctAddress = '';
  @track customerOrTenant = 'Customer';
  customerTenantOptions = [
    { label: 'Customer', value: 'Customer' },
    { label: 'Tenant', value: 'Tenant' }
  ];
  get isTenant() { return this.customerOrTenant === 'Tenant'; }
  @track tenantName = '';
  @track tenantMobile = '';

  get showLeakageBeforeMCV() {
    return this.gasLeakageObserved === 'Yes';
  }

  /* ---------- final page options ---------- */
  @track finalRemark = '';
  finalRemarksOptions = [
    { label: 'MR done', value: 'MR done' },
    { label: 'Meter found Ok', value: 'Meter found Ok' },
    { label: 'House lock', value: 'House lock' },
    { label: 'Customer not allowed', value: 'Customer not allowed' },
    { label: 'Customer gave Follow-up date', value: 'Customer gave Follow-up date' },
    { label: 'Reverse rectification Done', value: 'Reverse rectification Done' },
    { label: 'Done by other/emergency', value: 'Done by other/emergency' },
    { label: 'Customer cancelled complaint', value: 'Customer cancelled complaint' },
    { label: 'Building demolition', value: 'Building demolition' },
    { label: 'Flat under renovation', value: 'Flat under renovation' },
    { label: 'Supply disconnected- outside', value: 'Supply disconnected- outside' },
    { label: 'Supply disconnected from inside- MCV Plugged', value: 'Supply disconnected from inside- MCV Plugged' }
  ];

  acceptedFormats = ['.pdf', '.png', '.jpg', '.jpeg'];

  /* ---------- lifecycle ---------- */
  connectedCallback() {
    this.setreversalPhotoUploadSlots();
    this.setlpgPhotoUploadSlots();
    this.setmeterImageUploadSlots();
    this.setMeterUnsafePhotoSlots();
    this.setMeterInaccessiblePhotoSlots();
    this.setMcvClosedPhotoSlots();
    this.setNewMeterPhotoSlots();
    this.setPhotoUploadSlots();
    this.setOldMeterPhotoSlots();

    this.setMeterSoundPhotoSlots();
    this.setOldMeterRustedPhotoSlots();
    this.setCounterDefectivePhotoSlots();
    this.setMeterFaultyPhotoSlots();
    this.setMeterNotRunningPhotoSlots();
    this.setRivClosedPhotoSlots();
    this.setMcvPluggingPhotoSlots();

    this.inletOutletValue = this.inletOutletValue || '';
    this.oldMeterWorking = false;
    this.showRectificationRemarkDropdown = false;
    this.uploadedFinalImageKeys = new Set();
  }

  /* ---------- WIRES ---------- */
  // Online Apex wire
  @wire(getWorkOrderDetails, { workOrderId: '$recordId' })
  wiredWorkOrderOnline({ error, data }) {
    if (navigator.onLine) {
      this._processWorkOrderData(error, data);
    }
  }

  get woVars() {
    return { recordId: this.recordId };
  }

  // Offline GraphQL wire
  @wire(graphql, { query: WO_OFFLINE_QUERY, variables: '$woVars' })
  wiredWorkOrderOffline({ errors, data }) {
    if (!navigator.onLine) {
      if (data) {
        const node = data.uiapi?.query?.WorkOrder?.edges?.[0]?.node;
        if (node) {
          const mapped = {
            workOrder: {
              Id: node.Id,
              Old_Meter_Number__c: node.Old_Meter_Number__c?.value,
              BP_Number__c: node.BP_Number__c?.value,
              Is_The_Customer_Available_Meter_Repl__c:
                node.Is_The_Customer_Available_Meter_Repl__c?.value
            },
            previousMeterReading: node.Account?.Previous_Meter_Reading__c?.value
          };

          const saEdges = node.ServiceAppointments?.edges || [];
          if (saEdges.length > 0) {
            const saNode = saEdges[0].node;
            mapped.serviceAppointmentId = saNode.Id;
            mapped.saMeterUnsafe = saNode.Meter_Unsafe__c?.value;
            mapped.saMeterInaccessible = saNode.Meter_Inaccessible__c?.value;
            mapped.saCustomerReadyToShift = saNode.Customer_Ready_To_Shift__c?.value;
            mapped.saAlternatePhone = saNode.Alternate_Phone__c?.value;
            mapped.saCorrectAddress = saNode.Correct_Address__c?.value;
          }
          this._processWorkOrderData(null, mapped);
        }
      } else if (errors) {
        // Offline GraphQL error – just log
        console.error('Offline GraphQL Error', error);
      }
    }
  }

  _processWorkOrderData(error, data) {
    if (data) {
      this.workOrder = data.workOrder;
      this.previousMeterReading = data.previousMeterReading ? String(data.previousMeterReading) : '';
      this.previousMeterNumber = data.workOrder?.Old_Meter_Number__c || '';
      this.bpNumber = data.workOrder?.BP_Number__c || '';

      if (data.serviceAppointmentId) {
        this.serviceAppointmentId = data.serviceAppointmentId;
        if (typeof data.saMeterUnsafe !== 'undefined') this.meterUnsafe = !!data.saMeterUnsafe;
        if (typeof data.saMeterInaccessible !== 'undefined') this.meterInaccessible = !!data.saMeterInaccessible;
        if (typeof data.saCustomerReadyToShift !== 'undefined') {
          this.meterUnsafeReadyToShift = !!data.saCustomerReadyToShift;
          this.meterInaccessibleReadyToShift = !!data.saCustomerReadyToShift;
        }
        if (data.saAlternatePhone) this.alternatePhone = data.saAlternatePhone;
        if (data.saCorrectAddress) this.correctAddress = data.saCorrectAddress;
      }
      this.showGasLeakage = true;
    } else if (error) {
      console.error('Error fetching Work Order:', JSON.stringify(error));
      this._showToast('Error', 'Failed to load WorkOrder details', 'error');
    }
  }

  /* ---------- getters ---------- */
  get previousMeterNumberDisplay() {
    return (this.previousMeterNumber && String(this.previousMeterNumber).trim() !== '')
      ? this.previousMeterNumber
      : '— Not available';
  }

  get previousMeterReadingDisplay() {
    return (this.previousMeterReading && String(this.previousMeterReading).trim() !== '')
      ? this.previousMeterReading
      : '— Not available';
  }

  /* ========== Handlers ========== */

  handleNewMeterNumberChange(event) {
    this.newMeterNumber = (event.target.value || '').trim();
  }

  handleValidateClick() {
    this._runMeterNumberValidation(true);
  }

  _runMeterNumberValidation(setAfterValidation = false) {
    const prev = (this.previousMeterNumber || '').trim();
    const next = (this.newMeterNumber || '').trim();

    if (!next) {
      this.showAfterValidation = false;
      this.showMeterAlreadyReplacedDisplay = false;
      this.showMeterNotReplacedDisplay = false;
      return;
    }

    if (prev !== '' && next === prev) {
      this.showMeterNotReplacedDisplay = true;
      this.showMeterAlreadyReplacedDisplay = false;
      this.isMeterNotReplaced = true;
      this.isMeterAlreadyReplaced = false;
      this.showNewMeterReading = false;
      if (setAfterValidation) this.showAfterValidation = true;
      this._showToast('Info', 'Meter numbers match — marking as NOT replaced.', 'info');
      return;
    }

    this.showMeterAlreadyReplacedDisplay = true;
    this.showMeterNotReplacedDisplay = false;
    this.isMeterAlreadyReplaced = true;
    this.isMeterNotReplaced = false;
    this.showNewMeterReading = true;
    if (setAfterValidation) this.showAfterValidation = true;
    this._showToast('Info', 'Meter numbers differ — proceeding with replacement flow.', 'info');
  }

  handleNewMeterReadingChange(event) { this.newMeterReading = event.target.value; }
  handleOldMeterReadingChange(event) { this.oldMeterReadingCaptured = event.target.value; }

  // Conditions
  handleMeterSound(event) {
    this.addMeterSound = event.target.checked;
    if (!this.addMeterSound) {
      this.meterSoundRemarks = '';
      this.setMeterSoundPhotoSlots();
    }
  }
  handleMeterSoundRemarks(event) { this.meterSoundRemarks = event.target.value; }

  handleOldMeterRusted(event) {
    this.oldMeterRusted = event.target.checked;
    if (!this.oldMeterRusted) {
      this.oldMeterRustedRemarks = '';
      this.setOldMeterRustedPhotoSlots();
    }
  }
  handleOldMeterRustedRemarks(event) { this.oldMeterRustedRemarks = event.target.value; }

  handleCounterDefective(event) {
    this.counterDefectiveSmoke = event.target.checked;
    if (!this.counterDefectiveSmoke) {
      this.counterDefectiveRemarks = '';
      this.setCounterDefectivePhotoSlots();
    }
  }
  handleCounterDefectiveRemarks(event) { this.counterDefectiveRemarks = event.target.value; }

  handleMeterFaulty(event) {
    this.meterFaulty = event.target.checked;
    if (!this.meterFaulty) {
      this.meterFaultyRemarks = '';
      this.setMeterFaultyPhotoSlots();
    }
  }
  handleMeterFaultyRemarks(event) { this.meterFaultyRemarks = event.target.value; }

  handleMeterNotRunning(event) {
    this.meterNotRunning = event.target.checked;
    if (!this.meterNotRunning) {
      this.meterNotRunningRemarks = '';
      this.setMeterNotRunningPhotoSlots();
    }
  }
  handleMeterNotRunningRemarks(event) { this.meterNotRunningRemarks = event.target.value; }

  // Unsafe/Inaccessible
  handleMeterUnsafe(event) {
    this.meterUnsafe = event.target.checked;
    if (!this.meterUnsafe) {
      this.meterUnsafeRemarks = '';
      this.setMeterUnsafePhotoSlots();
      this.meterUnsafeReadyToShift = false;
    }
  }
  handleMeterUnsafeRemarks(event) { this.meterUnsafeRemarks = event.target.value; }

  handleMeterInaccessible(event) {
    this.meterInaccessible = event.target.checked;
    if (!this.meterInaccessible) {
      this.meterInaccessibleRemarks = '';
      this.setMeterInaccessiblePhotoSlots();
      this.meterInaccessibleReadyToShift = false;
    }
  }
  handleMeterInaccessibleRemarks(event) { this.meterInaccessibleRemarks = event.target.value; }

  handleMeterUnsafeReadyToShift(event) {
    this.meterUnsafeReadyToShift = event.target.checked;
    if (this.meterUnsafeReadyToShift) this.showSubmit = true;
  }
  handleMeterInaccessibleReadyToShift(event) {
    this.meterInaccessibleReadyToShift = event.target.checked;
    if (this.meterInaccessibleReadyToShift) this.showSubmit = true;
  }

  handleProceedFromUnsafe() {
    this._showToast('Info', 'Proceeding after Unsafe — continue remaining steps.', 'info');
    this.showSubmit = true;
  }
  handleProceedFromInaccessible() {
    this._showToast('Info', 'Proceeding after Inaccessible — continue remaining steps.', 'info');
    this.showSubmit = true;
  }

  // Recurring steps
  handleDisconnectionChange(event) {
    this.isDisconnectionRequired = event.target.checked;
    this.showDisconnectionRemark = this.isDisconnectionRequired;
  }
  handleDisconnectionRemark(event) { this.disconnectionRemark = event.target.value; }

  handleRIVClosed(event) {
    if (this.gasLeakageObserved !== 'Yes') {
      this._showToast('Error', 'RIV Closed option is only available if leakage was found.', 'error');
      this.rivClosed = false;
      return;
    }

    this.rivClosed = event.target.checked;
    if (this.rivClosed) {
      this._showToast('Info', 'RIV closed — please capture RIV photos and create CRM case.', 'info');
      this.setRivClosedPhotoSlots();
      this.createCRMCaseAndFetchBP();
    } else {
      this.rivClosedPhotoSlots = [{
        id: 1, index: 1, label: 'RIV Closed Photo',
        name: 'rivClosedPhoto1', fileName: '', uploaded: false, previewUrl: ''
      }];
      this.rivClosedPhotoMissing = false;
    }
  }

  handleMCVChange(event) {
    this.isMCVPluggingRequired = event.target.checked;
    if (this.isMCVPluggingRequired) {
      this.setMcvPluggingPhotoSlots();
    } else {
      this.mcvPluggingPhotoSlots = [{
        id: 1, index: 1, label: 'MCV Plugged Photo',
        name: 'mcvPluggingPhoto1', fileName: '', uploaded: false, previewUrl: ''
      }];
      this.mcvPluggingPhotoMissing = false;
      this.mcvPluggingPhotoUploaded = false;
      this.mcvPluggingRemark = '';
    }
    this.updateRemarksVisibility();
  }
  handleMCVPluggingRemark(event) {
    this.mcvPluggingRemark = event.target.value;
    this.updateRemarksVisibility();
  }

  handleGasLeakageChange(event) {
    this.gasLeakageObserved = event.detail.value;

    this.showLeakageCaseNumber = (this.gasLeakageObserved === 'Yes');
    if (!this.showLeakageCaseNumber) {
      this.leakageCaseNumber = '';
    }

    this.showMCVStatus = (this.gasLeakageObserved === 'Yes');
    this.showMCVClosed = (this.gasLeakageObserved === 'No');

    if (this.gasLeakageObserved === 'Yes') {
      this._showToast('Info', 'Leakage observed — escalate to emergency team.', 'info');
      this.createCRMCaseAndFetchBP();
    }
  }

  handleLeakageCaseNumberChange(event) {
    this.leakageCaseNumber = event.target.value;
  }

  handleInletOutletChange(event) {
    this.inletOutletValue = event.detail ? event.detail.value : event.target.value;
    this.showInletOutletRectification = this.inletOutletValue === 'Yes';

    if (!this.showInletOutletRectification) {
      this.oldMeterWorking = false;
      this.showRectificationRemarkDropdown = false;
      this.rectificationRemark = '';
      this.showProceedReplacementFromInletOutlet = false;
    } else {
      this.oldMeterWorking = false;
      this.showRectificationRemarkDropdown = false;
      this.showProceedReplacementFromInletOutlet = false;
    }
  }

  handleOldMeterWorkingChange(event) {
    this.oldMeterWorking = event.target.checked === true;

    if (this.oldMeterWorking) {
      this.showRectificationRemarkDropdown = true;
      this.showProceedReplacementFromInletOutlet = false;
    } else {
      this.showRectificationRemarkDropdown = false;
      this.rectificationRemark = '';
      this.showProceedReplacementFromInletOutlet = true;
    }
  }

  handleRectificationRemarkChange(event) {
    this.rectificationRemark = event.detail ? event.detail.value : event.target.value;
  }

  handleRubberHoseCondition(event) {
    this.rubberHoseCondition = event.detail.value;
    this.showUnsafeLetterUpload = (this.rubberHoseCondition === 'Concealed');
  }

  mcvStatusOptions = [
    { label: 'Okay', value: 'Okay' },
    { label: 'Not Okay', value: 'Not Okay' }
  ];

  mcvClosedOptions = [
    { label: 'Yes:Leakage observed', value: 'Yes:Leakage observed' },
    { label: 'No', value: 'No' }
  ];

  handleMCVStatusChange(event) {
    this.mcvStatus = event.detail.value;
    this.showGasDetectorReading = (this.mcvStatus === 'Okay');
    this.showMCVClosed = (this.mcvStatus === 'Not Okay');
  }

  handleGasDetectorReadingChange(event) {
    this.gasDetectorReading = event.target.value;
    if (this.gasDetectorReading && this.gasDetectorReading.trim() !== '') {
      this.showBeforeAfterMeterUpload = true;
      this.showBPNumber = true;
    } else {
      this.showBeforeAfterMeterUpload = false;
    }
  }

  handleMCVClosedChange(event) {
    this.mcvClosed = event.detail.value;
    this.mcvClosedPhotoUploaded = false;
    this.mcvClosedPhotoMissing = false;

    if (this.mcvClosed === 'Yes:Leakage observed') {
      this.showMCVClosedPhotoUpload = true;
      this.showBPNumber = false;
      this.showBeforeAfterMeterUpload = false;
    } else if (this.mcvClosed === 'No') {
      this.showMCVClosedPhotoUpload = false;
      this.showLeakageCaseCRM = false;
      this.showBPNumber = true;
      this.showBeforeAfterMeterUpload = true;
    }
  }

  handleMcvPluggingPhotoUpload(event) {
    const files = event.detail?.steps || [];
    this.mcvPluggingPhotoSlots = files.map((f, i) => ({
      id: i + 1,
      index: i + 1,
      label: f.label || `MCV Plugged ${i + 1}`,
      fileName: f.fileName || f.name,
      uploaded: true,
      previewUrl: f.previewUrl || '',
      base64Data: f.base64Data || (f.previewUrl ? f.previewUrl.split(',')[1] : '')
    }));
    const unique = this._dedupeAndMakeBase64List(files);
    if (unique.length) {
      this.mcvPluggingPhotoUploaded = true;
      this.mcvPluggingPhotoMissing = false;
      this._uploadOrQueue(unique, savePhotoUploadsMeter)
        .catch(err => {
          console.error('MCV plugging upload error', err);
          this._showToast('Error', 'Failed to upload MCV photos', 'error');
        });
    } else {
      this.mcvPluggingPhotoUploaded = false;
    }
  }

  handleRivClosedPhotoUpload(event) {
    const files = event.detail?.steps || [];
    this.rivClosedPhotoSlots = files.map((f, i) => ({
      id: i + 1,
      index: i + 1,
      label: f.label || `RIV Closed ${i + 1}`,
      fileName: f.fileName || f.name,
      uploaded: true,
      previewUrl: f.previewUrl || '',
      base64Data: f.base64Data || (f.previewUrl ? f.previewUrl.split(',')[1] : '')
    }));
    const unique = this._dedupeAndMakeBase64List(files);
    if (unique.length) {
      this.rivClosedPhotoUploaded = true;
      this.rivClosedPhotoMissing = false;
      this._uploadOrQueue(unique, savePhotoUploadsMeter)
        .catch(err => {
          console.error('RIV closed upload error', err);
          this._showToast('Error', 'Failed to upload RIV photos', 'error');
        });
    } else {
      this.rivClosedPhotoUploaded = false;
    }
  }

  handleMCVClosedPhotoUpload(event) {
    const rawFiles = event.detail.steps || [];
    const uniqueFiles = this._dedupeAndMakeBase64List(rawFiles);

    if (!uniqueFiles.length) {
      this.mcvClosedPhotoUploaded = false;
      this.mcvClosedPhotoMissing = true;
      this._showToast('Error', 'Please capture/upload at least one photo of the plugged MCV.', 'error');
      return;
    }

    this._showToast('Info', 'Uploading MCV photo(s)...', 'info');
    this._uploadOrQueue(uniqueFiles, savePhotoUploadsMeter)
      .then(() => {
        this.mcvClosedPhotoUploaded = true;
        this.mcvClosedPhotoMissing = false;
        this.showMCVClosedPhotoUpload = false;
        this.createCRMCaseAndFetchBP();
      })
      .catch(err => {
        console.error('Error uploading MCV photos', err);
        this.mcvClosedPhotoUploaded = false;
        this.mcvClosedPhotoMissing = true;
        this._showToast('Error', 'Failed to upload MCV photo(s).', 'error');
      });
  }

  handleStorageLocationChange(event) { this.storageLocation = event.detail.value; }

  // ---------- Photo upload handlers (hybrid) ----------
  handleOldMeterPhotoUpload(event) {
    const files = event.detail?.steps || [];
    this.oldMeterPhotoSlots = files.map((f, i) => ({
      id: i + 1,
      index: i + 1,
      label: f.label || `Old Meter Photo ${i + 1}`,
      fileName: f.fileName || f.name,
      uploaded: true,
      previewUrl: f.previewUrl || '',
      base64Data: f.base64Data || f.base64 || (f.previewUrl ? f.previewUrl.split(',')[1] : '')
    }));
    const unique = this._dedupeAndMakeBase64List(files);
    if (unique.length) {
      this._uploadOrQueue(unique, savePhotoUploadsMeter)
        .catch(err => {
          console.error(err);
          this._showToast('Error', 'Failed to upload old meter photo', 'error');
        });
    }
  }

  handleNewMeterPhotoUpload(event) {
    const files = event.detail?.steps || [];
    this.newMeterPhotoSlots = files.map((f, i) => ({
      id: i + 1,
      index: i + 1,
      label: f.label || `New Meter Photo ${i + 1}`,
      fileName: f.fileName || f.name,
      uploaded: true,
      previewUrl: f.previewUrl || '',
      base64Data: f.base64Data || (f.previewUrl ? f.previewUrl.split(',')[1] : '')
    }));
    const unique = this._dedupeAndMakeBase64List(files);
    if (unique.length) {
      this._uploadOrQueue(unique, savePhotoUploadsMeter)
        .catch(err => {
          console.error(err);
          this._showToast('Error', 'Failed to upload new meter photo', 'error');
        });
    }
  }

  handleMeterSoundPhotoUpload(event) {
    const files = event.detail?.steps || [];
    this.meterSoundPhotoSlots = files.map((f, i) => ({
      id: i + 1,
      index: i + 1,
      label: f.label || `Meter Sound ${i + 1}`,
      fileName: f.fileName || f.name,
      uploaded: true,
      previewUrl: f.previewUrl || '',
      base64Data: f.base64Data || (f.previewUrl ? f.previewUrl.split(',')[1] : '')
    }));
    const unique = this._dedupeAndMakeBase64List(files);
    if (unique.length) this._uploadOrQueue(unique, savePhotoUploadsMeter).catch(e => console.error(e));
  }

  handleOldMeterRustedPhotoUpload(event) {
    const files = event.detail?.steps || [];
    this.oldMeterRustedPhotoSlots = files.map((f, i) => ({
      id: i + 1,
      index: i + 1,
      label: f.label || `Old Rusted ${i + 1}`,
      fileName: f.fileName || f.name,
      uploaded: true,
      previewUrl: f.previewUrl || '',
      base64Data: f.base64Data || (f.previewUrl ? f.previewUrl.split(',')[1] : '')
    }));
    const unique = this._dedupeAndMakeBase64List(files);
    if (unique.length) this._uploadOrQueue(unique, savePhotoUploadsMeter).catch(e => console.error(e));
  }

  handleCounterDefectivePhotoUpload(event) {
    const files = event.detail?.steps || [];
    this.counterDefectivePhotoSlots = files.map((f, i) => ({
      id: i + 1,
      index: i + 1,
      label: f.label || `Counter Defective ${i + 1}`,
      fileName: f.fileName || f.name,
      uploaded: true,
      previewUrl: f.previewUrl || '',
      base64Data: f.base64Data || (f.previewUrl ? f.previewUrl.split(',')[1] : '')
    }));
    const unique = this._dedupeAndMakeBase64List(files);
    if (unique.length) this._uploadOrQueue(unique, savePhotoUploadsMeter).catch(e => console.error(e));
  }

  handleMeterFaultyPhotoUpload(event) {
    const files = event.detail?.steps || [];
    this.meterFaultyPhotoSlots = files.map((f, i) => ({
      id: i + 1,
      index: i + 1,
      label: f.label || `Meter Faulty ${i + 1}`,
      fileName: f.fileName || f.name,
      uploaded: true,
      previewUrl: f.previewUrl || '',
      base64Data: f.base64Data || (f.previewUrl ? f.previewUrl.split(',')[1] : '')
    }));
    const unique = this._dedupeAndMakeBase64List(files);
    if (unique.length) this._uploadOrQueue(unique, savePhotoUploadsMeter).catch(e => console.error(e));
  }

  handleMeterNotRunningPhotoUpload(event) {
    const files = event.detail?.steps || [];
    this.meterNotRunningPhotoSlots = files.map((f, i) => ({
      id: i + 1,
      index: i + 1,
      label: f.label || `Not Running ${i + 1}`,
      fileName: f.fileName || f.name,
      uploaded: true,
      previewUrl: f.previewUrl || '',
      base64Data: f.base64Data || (f.previewUrl ? f.previewUrl.split(',')[1] : '')
    }));
    const unique = this._dedupeAndMakeBase64List(files);
    if (unique.length) this._uploadOrQueue(unique, savePhotoUploadsMeter).catch(e => console.error(e));
  }

  handleUnsafePhotoUpload(event) {
    const files = event.detail?.steps || [];
    this.meterUnsafePhotoSlots = files.map((f, i) => ({
      id: i + 1,
      index: i + 1,
      label: f.label || `Unsafe ${i + 1}`,
      fileName: f.fileName || f.name,
      uploaded: true,
      previewUrl: f.previewUrl || '',
      base64Data: f.base64Data || (f.previewUrl ? f.previewUrl.split(',')[1] : '')
    }));
    const unique = this._dedupeAndMakeBase64List(files);
    if (unique.length) this._uploadOrQueue(unique, savePhotoUploadsMeter).catch(e => console.error(e));
  }

  handleMeterInaccessiblePhotoUpload(event) {
    const files = event.detail?.steps || [];
    this.meterInaccessiblePhotoSlots = files.map((f, i) => ({
      id: i + 1,
      index: i + 1,
      label: f.label || `Inaccessible ${i + 1}`,
      fileName: f.fileName || f.name,
      uploaded: true,
      previewUrl: f.previewUrl || '',
      base64Data: f.base64Data || (f.previewUrl ? f.previewUrl.split(',')[1] : '')
    }));
    const unique = this._dedupeAndMakeBase64List(files);
    if (unique.length) this._uploadOrQueue(unique, savePhotoUploadsMeter).catch(e => console.error(e));
  }

  handleMeterFileUpload(event) {
    const rawFiles = event.detail.steps || [];
    const uniqueFiles = this._dedupeAndMakeBase64List(rawFiles);
    if (!uniqueFiles.length) {
      this._showToast('Warning', 'No valid meter images to upload.', 'warning');
      return;
    }
    this._uploadOrQueue(uniqueFiles, savePhotoUploadsMeter)
      .then(() => {
        this.showMeterReplacedSection = true;
      })
      .catch(err => {
        console.error('Reversal photos upload error', err);
        this._showToast('Error', 'Failed to upload meter images.', 'error');
      });
  }

  handleReversalFile(event) {
    const rawFiles = event.detail.steps || [];
    const uniqueFiles = this._dedupeAndMakeBase64List(rawFiles);
    if (!uniqueFiles.length) {
      this._showToast('Warning', 'No reversal images to upload.', 'warning');
      return;
    }
    this._uploadOrQueue(uniqueFiles, savePhotoUploadsReversal)
      .then(() => { this._showToast('Success', 'Reversal photos saved.', 'success'); })
      .catch(err => {
        console.error('savePhotoUploadsReversal error', err);
        this._showToast('Error', 'Failed to save reversal photos', 'error');
      });
  }

  handleFile(event) {
    const files = event.detail.steps || [];
    const unique = this._dedupeAndMakeBase64List(files);
    this._uploadOrQueue(unique, savePhotoUploadsLPG)
      .then(() => { this.showRemarksAfterUploadOrMCV = true; })
      .catch(err => {
        console.error('savePhotoUploadsLPG error', err);
        this._showToast('Error', 'Failed to upload LPG photos', 'error');
      });
  }

  createCRMCaseAndFetchBP() {
    if (navigator.onLine) {
      createCRMCaseAndReturnBP({ workOrderId: this.recordId })
        .then(bp => {
          this.bpNumber = bp;
          this.showBPNumber = true;
          this._showToast('Success', 'CRM case created and BP number loaded.', 'success');
          this.showBeforeAfterMeterUpload = true;
        })
        .catch(error => {
          console.error('CRM case creation failed:', error);
          this._showToast('Error', 'Failed to create CRM case or fetch BP number.', 'error');
        });
    } else {
      // Offline – draft Case locally via LDS
      const caseFields = {};
      this._safeAssign(caseFields, CASE_SUBJECT, 'Gas Leakage Detected during Meter Replacement');
      this._safeAssign(caseFields, CASE_ORIGIN, 'Field Visit');
      this._safeAssign(caseFields, CASE_STATUS, 'New');
      this._safeAssign(caseFields, CASE_WO, this.recordId);
      this._safeAssign(caseFields, CASE_DESC, 'Gas leakage observed. Please investigate.');

      const recordInput = { apiName: CASE_OBJECT.objectApiName, fields: caseFields };
      createRecord(recordInput)
        .then(() => {
          this.showBPNumber = true; // BP not known offline, but UI can still show placeholder
          this.showBeforeAfterMeterUpload = true;
          this._showToast('Success', 'CRM case drafted offline (to sync later).', 'success');
        })
        .catch(error => {
          console.error('Offline Case draft failed:', error);
          this._showToast('Error', 'Failed to draft CRM case offline.', 'error');
        });
    }
  }

  handleRectificationClose() {
    if (!this.rectificationRemark || this.rectificationRemark.trim() === '') {
      this._showToast('Error', 'Please select a rectification remark before closing.', 'error');
      return;
    }

    this.load = true;
    const payload = this._buildPayload();

    this._saveMeterReplDetailsHybrid(payload, this.photoUploadSlots)
      .then(() => {
        this._showToast('Success', 'Rectification saved and flow closed.', 'success');
        this.load = false;
        this.dispatchEvent(new CustomEvent('cancel'));
      })
      .catch(err => {
        console.error('Error saving rectification close:', err);
        this.load = false;
        this._showToast('Error', 'Failed to save rectification: ' + (err?.body?.message || err?.message || err), 'error');
      });
  }

  handleCancel() {
    if (FORM_FACTOR === 'Large') {
      const closeQA = new CustomEvent('close');
      this.dispatchEvent(closeQA);
    } else {
      history.back();
    }
  }

  // ---------- Slot initializers ----------
  setreversalPhotoUploadSlots() {
    const customLabels = ['Before Reversal', 'After Reversal'];
    this.reversalPhotoUploadSlots = Array.from({ length: this.noOfPhotos }, (_, index) => {
      const slotNum = index + 1;
      return {
        id: slotNum,
        index: slotNum,
        label: customLabels[index] || `Photo ${slotNum}`,
        name: `reversalFile${slotNum}`,
        fileName: '',
        uploaded: false,
        previewUrl: ''
      };
    });
  }

  setlpgPhotoUploadSlots() {
    const customLabels = ['Capture Installation Image'];
    this.lpgPhotoUploadSlots = Array.from({ length: this.noOfPhotosLpg }, (_, index) => {
      const slotNum = index + 1;
      return {
        id: slotNum,
        index: slotNum,
        label: customLabels[index] || `Photo ${slotNum}`,
        name: `lpgFile${slotNum}`,
        fileName: '',
        uploaded: false,
        previewUrl: ''
      };
    });
  }

  setmeterImageUploadSlots() {
    const customLabels = ['Before Meter', 'After Meter'];
    this.meterImageUploadSlots = Array.from({ length: this.noOfPhotosMeter }, (_, index) => {
      const slotNum = index + 1;
      return {
        id: slotNum,
        index: slotNum,
        label: customLabels[index] || `Photo ${slotNum}`,
        name: `meterFile${slotNum}`,
        fileName: '',
        uploaded: false,
        previewUrl: ''
      };
    });
  }

  setMeterUnsafePhotoSlots() {
    this.meterUnsafePhotoSlots = [{
      id: 1, index: 1, label: 'Unsafe Photo 1',
      name: 'unsafePhoto1', fileName: '', uploaded: false, previewUrl: ''
    }];
  }

  setMeterInaccessiblePhotoSlots() {
    this.meterInaccessiblePhotoSlots = [{
      id: 1, index: 1, label: 'Inaccessible Photo 1',
      name: 'inaccessPhoto1', fileName: '', uploaded: false, previewUrl: ''
    }];
  }

  setMcvClosedPhotoSlots() {
    this.mcvClosedPhotoSlots = [{
      id: 1, index: 1, label: 'Plugged MCV Photo',
      name: 'mcvClosedPhoto1', fileName: '', uploaded: false, previewUrl: ''
    }];
  }

  setNewMeterPhotoSlots() {
    this.newMeterPhotoSlots = [{
      id: 1, index: 1, label: 'New Meter Photo',
      name: 'newMeterPhoto1', fileName: '', uploaded: false, previewUrl: ''
    }];
  }

  setOldMeterPhotoSlots() {
    this.oldMeterPhotoSlots = [{
      id: 1, index: 1, label: 'Old Meter Photo',
      name: 'oldMeterPhoto1', fileName: '', uploaded: false, previewUrl: ''
    }];
  }

  setMeterSoundPhotoSlots() {
    this.meterSoundPhotoSlots = [{
      id: 1, index: 1, label: 'Meter Sound Photo',
      name: 'meterSoundPhoto1', fileName: '', uploaded: false, previewUrl: ''
    }];
  }

  setOldMeterRustedPhotoSlots() {
    this.oldMeterRustedPhotoSlots = [{
      id: 1, index: 1, label: 'Old Meter Rusted Photo',
      name: 'oldRustedPhoto1', fileName: '', uploaded: false, previewUrl: ''
    }];
  }

  setCounterDefectivePhotoSlots() {
    this.counterDefectivePhotoSlots = [{
      id: 1, index: 1, label: 'Counter Defective Photo',
      name: 'counterDefectivePhoto1', fileName: '', uploaded: false, previewUrl: ''
    }];
  }

  setMeterFaultyPhotoSlots() {
    this.meterFaultyPhotoSlots = [{
      id: 1, index: 1, label: 'Meter Faulty Photo',
      name: 'meterFaultyPhoto1', fileName: '', uploaded: false, previewUrl: ''
    }];
  }

  setMeterNotRunningPhotoSlots() {
    this.meterNotRunningPhotoSlots = [{
      id: 1, index: 1, label: 'Meter Not Running Photo',
      name: 'meterNotRunningPhoto1', fileName: '', uploaded: false, previewUrl: ''
    }];
  }

  setPhotoUploadSlots() {
    const customLabels = [
      'Old Meter Photo',
      'New Meter Photo',
      'MRJC Document',
      'Rubber Hose Expiry Date Photo',
      'House Lock Photo',
      'Incorrect Installation Photo',
      'Rectified Installation Photo',
      'Rubber Hose Replacement Photo'
    ];
    this.photoUploadSlots = customLabels.map((label, index) => ({
      id: index + 1,
      index: index + 1,
      label,
      name: `fileUploader${index + 1}`,
      fileName: '',
      uploaded: false,
      previewUrl: ''
    }));
  }

  setRivClosedPhotoSlots() {
    this.rivClosedPhotoSlots = [{
      id: 1, index: 1, label: 'RIV Closed Photo',
      name: 'rivClosedPhoto1', fileName: '', uploaded: false, previewUrl: ''
    }];
  }

  setMcvPluggingPhotoSlots() {
    this.mcvPluggingPhotoSlots = [{
      id: 1, index: 1, label: 'MCV Plugged Photo',
      name: 'mcvPluggingPhoto1', fileName: '', uploaded: false, previewUrl: ''
    }];
  }

  // ---------- dedupe helper ----------
  _dedupeAndMakeBase64List(rawFiles) {
    const uniqueFiles = [];
    const seen = new Set();

    for (const f of (rawFiles || [])) {
      // 1) Original device name
      const origName = f.fileName || f.name || 'image.jpg';

      // 2) Extract extension (default .jpg)
      const extMatch = origName.match(/\.[^.]+$/);
      const ext = extMatch ? extMatch[0] : '.jpg';

      // 3) Business label (what you want to see in Salesforce)
      const label =
        (f.label && f.label.trim()) ||
        origName.replace(/\.[^.]+$/, '') || // strip extension
        'Photo';

      // 4) Final fileName = "<Label>.jpg"
      const fileName = `${label}${ext}`;

      // 5) Dedupe key
      const key = `${fileName}::${label}::${f.index || ''}`;
      if (seen.has(key)) continue;

      // 6) Base64 extraction (same as before)
      let base64 =
        (typeof f.base64Data === 'string' && f.base64Data) ||
        (typeof f.base64 === 'string' && f.base64) ||
        (typeof f.fileBody === 'string' && f.fileBody) ||
        (f.previewUrl && f.previewUrl.indexOf(',') > -1
          ? f.previewUrl.split(',')[1]
          : null);

      if (!base64 || base64.length < 50) {
        seen.add(key);
        continue;
      }

      uniqueFiles.push({
        fileName,          // "Old Meter Photo.jpg"
        label,             // "Old Meter Photo"
        base64Data: base64,
        index: f.index || null
      });
      seen.add(key);
    }

    return uniqueFiles;
  }


  updateRemarksVisibility() {
    const isUploadDone = this.lpgPhotoUploadSlots?.some(file => file.uploaded && file.fileName);
    this.showRemarksAfterUploadOrMCV = this.isMCVPluggingRequired || isUploadDone;
  }

  // ---------- lightning-record-edit-form submit ----------
  handleSubmit(event) {
    event.preventDefault();

    const fields = event.detail.fields || {};

    fields.Old_Meter_Details__c = String(this.previousMeterReading || '');
    fields.New_Meter_Details__c = String(this.newMeterReading || '');
    fields.Meter_not_replaced__c = this.showMeterNotReplacedDisplay;
    fields.Meter_Counter_Remarks__c = this.meterCounterRemarks;
    fields.Gas_Type__c = this.gasType;
    fields.Inlet_Outlet_Reversal_Needed__c = this.inletOutletValue || null;
    fields.Reversal_Correction_Details__c = this.reversalCorrectionDetails;
    fields.Disconnection_Required__c = this.isDisconnectionRequired;
    fields.MCV_Plugging_Required__c = this.isMCVPluggingRequired;
    fields.Remarks_Meter_Repl__c = this.remarks;
    fields.Gas_Leakage_Observed__c = this.gasLeakageObserved;
    fields.MCV_Status__c = this.mcvStatus;
    fields.First_Reading_of_the_gas_detector__c = this.gasDetectorReading;
    fields.MCV_Closed__c = this.mcvClosed;
    fields.Meter_Sound__c = this.addMeterSound;
    fields.Old_Meter_Rusted__c = this.oldMeterRusted;
    fields.Counter_Defective_Smokey__c = this.counterDefectiveSmoke;
    fields.Meter_Faulty__c = this.meterFaulty;
    fields.Meter_Not_Running__c = this.meterNotRunning;
    fields.Disconnection_Remark__c = this.disconnectionRemark;
    fields.MCV_Plugging_Remark__c = this.mcvPluggingRemark;
    fields.Rubber_Hose_Condition__c = this.rubberHoseCondition;
    fields.Alternate_Phone__c = this.alternatePhone;
    fields.Correct_Address__c = this.correctAddress;
    fields.Meter_Unsafe__c = this.meterUnsafe;
    fields.Meter_Inaccessible__c = this.meterInaccessible;
    fields.Tenant_Name__c = this.tenantName;
    fields.Tenant_Phone__c = this.tenantMobile;
    fields.Old_Meter_Number__c = this.previousMeterNumber;
    fields.New_Meter_Number__c = this.newMeterNumber;
    fields.New_Meter_Reading__c = this.newMeterReading;
    fields.Old_Meter_Reading__c = this.oldMeterReadingCaptured;
    fields.Storage_Location__c = this.storageLocation;
    fields.Meter_already_replaced__c = this.showMeterAlreadyReplacedDisplay;
    fields.Meter_not_replaced__c = this.showMeterNotReplacedDisplay;
    fields.Case_Remark__c = this.leakageCaseNumber;

    this.template.querySelector('lightning-record-edit-form').submit(fields);
  }

  // ---------- UPDATED handleSuccess (hybrid, no double uploads in online) ----------
  async handleSuccess(event) {
    try {
      this.isload = true;

      this.imageUploadPage = false;
      this.showSubmit = false;
      this.FirstPage = false;
      this.showFinalPage = true;

      this._showToast('Success', 'Record updated successfully!', 'success');

      const payload = this._buildPayload();
      //await this._saveMeterReplDetailsHybrid(payload, this.photoUploadSlots);
        await this._saveMeterReplDetailsHybrid(payload, []);
      // Only bulk-upload from slots when OFFLINE – online already uploads per handler
      if (!navigator.onLine) {
        await this._uploadAllPhotos();
      }

      if (this.isFinalSubmit) {
        await new Promise(resolve => setTimeout(resolve, 1500));
        this._showToast('Success', 'All details & photos saved successfully.', 'success');
        this.handleCancel();
      }
    } catch (err) {
      console.error('Error in handleSuccess follow-ups:', err);
      const msg = err?.body?.message || err?.message || String(err);
      this._showToast('Error', 'Failed to finish save/upload: ' + msg, 'error');
    } finally {
      if (!this.isFinalSubmit) {
        this.isload = false;
      }
      this.isFinalSubmit = false;
    }
  }

  _buildPayload() {
    return {
      recordId: this.recordId,

      previousMeterNumber: this.previousMeterNumber || '',
      previousMeterReading: this.previousMeterReading || '',
      newMeterNumber: this.newMeterNumber || '',
      newMeterReading: this.newMeterReading || '',
      oldMeterReadingCaptured: this.oldMeterReadingCaptured || '',

      meterAlreadyReplaced: this.isMeterAlreadyReplaced || false,
      meterNotReplaced: this.isMeterNotReplaced || false,
      storageLocation: this.storageLocation || '',

      gasLeakageObserved: this.gasLeakageObserved || '',
      leakageLocation: this.leakageLocation || '',
      leakageCaseNumber: this.leakageCaseNumber || '',

      mcvStatus: this.mcvStatus || '',
      rivClosed: this.rivClosed || false,
      gasDetectorReading: this.gasDetectorReading || '',

      inletOutletReversalNeeded: this.inletOutletValue || '',
      oldMeterWorkingAfterRectification: this.oldMeterWorking || false,
      rectificationRemark: this.rectificationRemark || '',

      meterSound: this.addMeterSound || false,
      meterSoundRemarks: this.meterSoundRemarks || '',
      oldMeterRusted: this.oldMeterRusted || false,
      oldMeterRustedRemarks: this.oldMeterRustedRemarks || '',
      counterDefectiveSmoke: this.counterDefectiveSmoke || false,
      counterDefectiveRemarks: this.counterDefectiveRemarks || '',
      meterFaulty: this.meterFaulty || false,
      meterFaultyRemarks: this.meterFaultyRemarks || '',
      meterNotRunning: this.meterNotRunning || false,
      meterNotRunningRemarks: this.meterNotRunningRemarks || '',

      disconnectionRequired: this.isDisconnectionRequired || false,
      disconnectionRemark: this.disconnectionRemark || '',
      mcvPluggingRequired: this.isMCVPluggingRequired || false,
      mcvPluggingRemark: this.mcvPluggingRemark || '',

      meterUnsafe: this.meterUnsafe || false,
      meterUnsafeRemarks: this.meterUnsafeRemarks || '',
      meterUnsafeReadyToShift: this.meterUnsafeReadyToShift || false,
      meterInaccessible: this.meterInaccessible || false,
      meterInaccessibleRemarks: this.meterInaccessibleRemarks || '',
      meterInaccessibleReadyToShift: this.meterInaccessibleReadyToShift || false,
      meterCounterRemarks: this.meterCounterRemarks || '',

      serviceAppointmentId: this.serviceAppointmentId || null,
      customerReadyToShift: (this.meterUnsafeReadyToShift || this.meterInaccessibleReadyToShift) || false,
      alternatePhone: this.alternatePhone || '',
      correctAddress: this.correctAddress || '',

      occupantType: this.customerOrTenant || '',
      tenantName: this.tenantName || '',
      tenantMobile: this.tenantMobile || '',

      rubberHoseCondition: this.rubberHoseCondition || '',
      finalRemark: this.finalRemark || '',
      gasType: this.gasType || '',
      meterCounterStatus: this.meterCounterStatus || ''
    };
  }

  handleError(event) {
    event.preventDefault();
    const e = event.detail;
    console.error('Record save error', e);
    this._showToast('Error', 'Record save failed: ' + (e.message || JSON.stringify(e)), 'error');
  }

 handleSubmitClick() {
  try {
    // run validations and build field map
    const fields = this.validateAndBuildFields();

    // 🔹 OFFLINE: don't call lightning-record-edit-form at all
    if (!navigator.onLine) {
      this._saveAllOfflineAndShowFinal();
      return;
    }

    // 🔹 ONLINE: normal behaviour – use the record-edit-form
    const form =
      this.template.querySelector('[data-id="meter-form"]') ||
      this.template.querySelector('lightning-record-edit-form');

    if (!form) {
      this._showToast('Error', 'Internal error: form not found', 'error');
      return;
    }

    this.isload = true;
    form.submit(fields); // goes to handleSuccess / handleError
  } catch (err) {
    // any validation error is already toasted inside validateAndBuildFields
    console.warn('Submission aborted:', err && err.message);
  }
}



  handleFinalSubmit() {
    this.isFinalSubmit = true;
    this.load = true;
    this._saveFinalRemarkHybrid()
      .then(() => {
        this._showToast('Success', 'Details Saved Successfully.', 'success');
        this.load = false;
        this.submitFormProgrammatically();
      })
      .catch(err => {
        this._showToast('Error', 'Failed to save final remark.', 'error');
        this.load = false;
      });
  }

  validateAndBuildFields() {
    if (!this.showAfterValidation) {
      this._showToast('Error', 'Please validate the new meter number before submitting.', 'error');
      throw new Error('ValidationFailed: validate new meter number');
    }

    if (this.showMeterNotReplacedDisplay) {
      if (!this.oldMeterReadingCaptured || this.oldMeterReadingCaptured.trim() === '') {
        this._showToast('Error', 'Old Meter Reading is required when meter is not replaced.', 'error');
        throw new Error('ValidationFailed: old meter reading missing');
      }
      if (!this.oldMeterPhotoSlots || this.oldMeterPhotoSlots.length === 0 || !this.oldMeterPhotoSlots.some(s => s.uploaded || s.fileName)) {
        this._showToast('Error', 'Please capture Old Meter Photo when meter is not replaced.', 'error');
        throw new Error('ValidationFailed: old meter photo missing');
      }
    }

    if (this.showMeterAlreadyReplacedDisplay) {
      if (!this.newMeterPhotoSlots || this.newMeterPhotoSlots.length === 0 || !this.newMeterPhotoSlots.some(s => s.uploaded || s.fileName)) {
        this._showToast('Error', 'Please capture New Meter Photo when meter is replaced.', 'error');
        throw new Error('ValidationFailed: new meter photo missing');
      }
      if (!this.newMeterReading || this.newMeterReading.trim() === '') {
        this._showToast('Error', 'New Meter Reading is required when meter is replaced.', 'error');
        throw new Error('ValidationFailed: new meter reading missing');
      }
    }

    if (this.meterUnsafe) {
      if (!this.meterUnsafeRemarks || this.meterUnsafeRemarks.trim() === '') {
        this._showToast('Error', 'Please enter remarks for Meter Unsafe', 'error');
        throw new Error('ValidationFailed: meterUnsafe remarks missing');
      }
      if (!this.meterUnsafePhotoSlots || this.meterUnsafePhotoSlots.length === 0) {
        this._showToast('Error', 'Please capture/upload at least one photo for Meter Unsafe', 'error');
        throw new Error('ValidationFailed: meterUnsafe photo missing');
      }
    }

    if (this.meterInaccessible) {
      if (!this.meterInaccessibleRemarks || this.meterInaccessibleRemarks.trim() === '') {
        this._showToast('Error', 'Please enter remarks for Meter Inaccessible', 'error');
        throw new Error('ValidationFailed: meterInaccessible remarks missing');
      }
      if (!this.meterInaccessiblePhotoSlots || this.meterInaccessiblePhotoSlots.length === 0) {
        this._showToast('Error', 'Please capture/upload at least one photo for Meter Inaccessible', 'error');
        throw new Error('ValidationFailed: meterInaccessible photo missing');
      }
    }

    if (this.isDisconnectionRequired) {
      if (!this.disconnectionRemark || this.disconnectionRemark.trim() === '') {
        this._showToast('Error', 'Please enter Disconnection Remark (mandatory).', 'error');
        throw new Error('ValidationFailed: disconnection remark missing');
      }
    }

    if (this.isMCVPluggingRequired) {
      if (!this.mcvPluggingRemark || this.mcvPluggingRemark.trim() === '') {
        this._showToast('Error', 'Please enter MCV Plugging Remarks (mandatory).', 'error');
        throw new Error('ValidationFailed: mcv plugging remark missing');
      }
      const mcvPhotosPresent = this.mcvPluggingPhotoSlots && this.mcvPluggingPhotoSlots.some(s => s.uploaded || s.fileName);
      if (!mcvPhotosPresent) {
        this._showToast('Error', 'Please capture/upload at least one photo for MCV Plugged (mandatory).', 'error');
        throw new Error('ValidationFailed: mcv plugging photo missing');
      }
    }

    if (this.rivClosed) {
      const rivPhotosPresent = this.rivClosedPhotoSlots && this.rivClosedPhotoSlots.some(s => s.uploaded || s.fileName);
      if (!rivPhotosPresent) {
        this._showToast('Error', 'Please capture/upload at least one photo for RIV Closed (mandatory).', 'error');
        throw new Error('ValidationFailed: riv photo missing');
      }
    }

    if (this.inletOutletValue === 'Yes') {
      if (this.oldMeterWorking) {
        if (!this.rectificationRemark || this.rectificationRemark.trim() === '') {
          this._showToast('Error', 'Please select a rectification remark when Old Meter is working after rectification.', 'error');
          throw new Error('ValidationFailed: rectification remark missing');
        }
      } else {
        if (!this.showProceedReplacementFromInletOutlet && !this.isMeterAlreadyReplaced && !this.isMeterNotReplaced) {
          this._showToast('Error', 'Old meter not working after rectification — please proceed to replacement capture.', 'error');
          throw new Error('ValidationFailed: inlet/outlet proceed missing');
        }
      }
    }

    const fields = {};
    fields.Old_Meter_Details__c = String(this.previousMeterReading || '');
    fields.New_Meter_Details__c = String(this.newMeterReading || '');
    fields.Meter_not_replaced__c = this.showMeterNotReplacedDisplay;
    fields.Meter_Counter_Remarks__c = this.meterCounterRemarks;
    fields.Gas_Type__c = this.gasType;
    fields.Inlet_Outlet_Reversal_Needed__c = this.inletOutletValue || null;
    fields.Reversal_Correction_Details__c = this.reversalCorrectionDetails;
    fields.Disconnection_Required__c = this.isDisconnectionRequired;
    fields.MCV_Plugging_Required__c = this.isMCVPluggingRequired;
    fields.Remarks_Meter_Repl__c = this.remarks;
    fields.Gas_Leakage_Observed__c = this.gasLeakageObserved;
    fields.MCV_Status__c = this.mcvStatus;
    fields.First_Reading_of_the_gas_detector__c = this.gasDetectorReading;
    fields.MCV_Closed__c = this.mcvClosed;
    fields.Meter_Sound__c = this.addMeterSound;
    fields.Old_Meter_Rusted__c = this.oldMeterRusted;
    fields.Counter_Defective_Smokey__c = this.counterDefectiveSmoke;
    fields.Meter_Faulty__c = this.meterFaulty;
    fields.Meter_Not_Running__c = this.meterNotRunning;
    fields.Disconnection_Remark__c = this.disconnectionRemark;
    fields.MCV_Plugging_Remark__c = this.mcvPluggingRemark;
    fields.Rubber_Hose_Condition__c = this.rubberHoseCondition;
    fields.Alternate_Phone__c = this.alternatePhone;
    fields.Correct_Address__c = this.correctAddress;
    fields.Meter_Unsafe__c = this.meterUnsafe;
    fields.Meter_Inaccessible__c = this.meterInaccessible;
    fields.Tenant_Name__c = this.tenantName;
    fields.Tenant_Phone__c = this.tenantMobile;
    fields.Old_Meter_Number__c = this.previousMeterNumber;
    fields.New_Meter_Number__c = this.newMeterNumber;
    fields.New_Meter_Reading__c = this.newMeterReading;
    fields.Old_Meter_Reading__c = this.oldMeterReadingCaptured;
    fields.Storage_Location__c = this.storageLocation;
    fields.Meter_already_replaced__c = this.showMeterAlreadyReplacedDisplay;
    fields.Meter_not_replaced__c = this.showMeterNotReplacedDisplay;
    fields.Case_Remark__c = this.leakageCaseNumber;

    return fields;
  }

  submitFormProgrammatically() {
  if (this.isload) {
    console.warn('Submit suppressed: already loading');
    return;
  }

  try {
    const fields = this.validateAndBuildFields();

    // 🔹 OFFLINE: bypass lightning-record-edit-form
    if (!navigator.onLine) {
      this._saveAllOfflineAndShowFinal();
      return;
    }

    // 🔹 ONLINE
    const form =
      this.template.querySelector('[data-id="meter-form"]') ||
      this.template.querySelector('lightning-record-edit-form');

    if (!form) {
      console.error('Form not found for programmatic submit');
      this._showToast('Error', 'Internal error: form not found', 'error');
      return;
    }

    this.isload = true;
    form.submit(fields); // will trigger handleSuccess / handleError
    console.log('Programmatic submit called with fields:', JSON.stringify(fields));
  } catch (err) {
    console.warn('Submission aborted:', err && err.message);
  }
}

    // ---------- OFFLINE full save helper (no record-edit-form) ----------
async _saveAllOfflineAndShowFinal() {
  try {
    this.isload = true;

    const payload = this._buildPayload();

    // Save WO + SA via LDS (offline branch is inside this helper)
    await this._saveMeterReplDetailsHybrid(payload, this.photoUploadSlots);

    // Save all photos via LDS/ContentVersion (only does real work offline)
    await this._uploadAllPhotos();

    // Move to final page UI
    this.imageUploadPage = false;
    this.showSubmit = false;
    this.FirstPage = false;
    this.showFinalPage = true;

    if (this.isFinalSubmit) {
      this._showToast(
        'Success',
        'All details & photos saved (offline). They will sync when device is online.',
        'success'
      );
      this.handleCancel(); // close after final submit
    } else {
      this._showToast(
        'Success',
        navigator.onLine
          ? 'Details saved successfully.'
          : 'Details saved offline. They will sync when device is online.',
        'success'
      );
    }
  } catch (e) {
    const msg = e?.body?.message || e?.message || String(e);
    this._showToast('Error', 'Failed to save details: ' + msg, 'error');
  } finally {
    this.isload = false;
    this.isFinalSubmit = false;
  }
}




  _uploadAllPhotos() {
    if (navigator.onLine) {
      return Promise.resolve();
    }

    const promises = [];
    const groups = [
      this.oldMeterPhotoSlots, this.newMeterPhotoSlots, this.meterImageUploadSlots,
      this.reversalPhotoUploadSlots, this.lpgPhotoUploadSlots, this.photoUploadSlots,
      this.meterUnsafePhotoSlots, this.meterInaccessiblePhotoSlots, this.mcvClosedPhotoSlots,
      this.meterSoundPhotoSlots, this.oldMeterRustedPhotoSlots, this.counterDefectivePhotoSlots,
      this.meterFaultyPhotoSlots, this.meterNotRunningPhotoSlots,
      this.rivClosedPhotoSlots, this.mcvPluggingPhotoSlots
    ];

    groups.forEach(arr => {
      if (arr && arr.length) {
        const unique = this._dedupeAndMakeBase64List(arr);
        if (unique.length) {
          promises.push(this._uploadOrQueue(unique, savePhotoUploadsMeter, true));        }
      }
    });

    if (!promises.length) return Promise.resolve();
    return Promise.all(promises);
  }

    // ---------- Final images upload (hybrid + compression) ----------
  async handleFinalImageUpload(event) {
    const raw = event.detail?.steps || [];

    if (!raw.length) {
      this._showToast('Warning', 'No final images to upload', 'warning');
      return;
    }

    // 🔹 Count newly “visible” images in this event (for your counter)
    const newlyVisible = raw.filter(r =>
      r.uploaded || r.base64Data || r.previewUrl || r.file
    ).length;
    this.finalUploadedCount += newlyVisible;

    // 🔹 Filter out images that we have ALREADY uploaded in previous events
    const freshRaw = [];
    for (const f of raw) {
      const key = this._makeFinalImageKey(f);
      if (this.uploadedFinalImageKeys.has(key)) {
        // already uploaded in a previous call → skip
        continue;
      }
      this.uploadedFinalImageKeys.add(key);
      freshRaw.push(f);
    }

    if (!freshRaw.length) {
      this._showToast('Info', 'No new final images to upload (all already uploaded).', 'info');
      return;
    }

    // Still do per-event de-dupe for safety
    const unique = this._dedupeAndMakeBase64List(freshRaw);
    if (!unique.length) {
      this._showToast('Warning', 'No valid final images to upload.', 'warning');
      return;
    }

    const items = unique.map((f, i) => {
      const displayName =
        f.label ||           // Prefer the photo label (eg. "Old Meter Photo")
        f.fileName ||        // Fall back to fileName if present
        f.name ||            // Or original file name from device
        `Final Photo ${i + 1}`;  // Last-resort fallback

      return {
        file: f.file || null,
        previewUrl:
          f.previewUrl ||
          (f.base64Data ? 'data:image/jpeg;base64,' + f.base64Data : null),
        base64Data: f.base64Data || null,

        // 👇 BOTH are now the same human-friendly name
        fileName: displayName,
        label: displayName,

        index: f.index || (i + 1)
      };
    });


    this.isload = true;

    try {
      await this._compressAndChunkUpload(items, savePhotoUploadsFinal, this.recordId);
      this._showToast('Success', 'Final images uploaded successfully.', 'success');
    } catch (err) {
      console.error('Final upload error:', err);
      const serverMsg = err?.body?.message || err?.message || String(err);
      this._showToast('Error', 'Failed final upload: ' + serverMsg, 'error');
    } finally {
      this.isload = false;
    }
  }


  handleFinalRemarkChange(event) { this.finalRemark = event.detail.value; }

  _showToast(title, message, variant = 'info') {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }

  handleGasTypeTextChange(event) { this.gasType = event.target.value; }
  handleGasTypeChange(event) { this.gasType = event.detail.value; }

  handleAlternatePhone(event) { this.alternatePhone = event.target.value; }
  handleCorrectAddress(event) { this.correctAddress = event.target.value; }
  handleCustomerTenant(event) { this.customerOrTenant = event.detail.value; }
  handleTenantName(event) { this.tenantName = event.target.value; }
  handleTenantMobile(event) { this.tenantMobile = event.target.value; }

  handleCounterRemarksChange(event) {
    this.meterCounterRemarks = event.target.value;
    this.showReversal = true;
  }

  // ---------- Unsafe letter upload (hybrid) ----------
  handleUnsafeLetterFileChange(event) {
    const file = event.target.files[0];
    this.unsafeLetterFile = file;
    this.unsafeLetterFileName = file ? file.name : '';
    if (file) {
      const reader = new FileReader();
      reader.onload = () => {
        const base64 = reader.result.split(',')[1];
        if (navigator.onLine) {
          uploadFileUnsafeLetter({ fileName: file.name, base64Data: base64, recordId: this.recordId })
            .then(() => {
              this._showToast('Success', 'Unsafe letter uploaded.', 'success');
            })
            .catch(err => {
              console.error('uploadFileUnsafeLetter error', err);
              this._showToast('Error', 'Failed to upload unsafe letter.', 'error');
            });
        } else {
          const items = [{ fileName: file.name, base64Data: base64 }];
          this._saveImagesOffline(items)
            .then(() => { this._showToast('Success', 'Unsafe letter uploaded offline.', 'success'); })
            .catch(err => {
              console.error('Offline unsafe letter save failed', err);
              this._showToast('Error', 'Failed to upload unsafe letter.', 'error');
            });
        }
      };
      reader.readAsDataURL(file);
    }
  }

  // ---------- Hybrid helpers (Apex vs LDS offline) ----------

  async _saveMeterReplDetailsHybrid(payload, listFiles) {
    if (navigator.onLine) {
      return saveMeterReplDetails({ payload, listFiles });
    } else {
      // WorkOrder update
      const woFields = {};
      this._safeAssign(woFields, WO_ID_FIELD, payload.recordId);
      this._safeAssign(woFields, WO_OLD_METER_NUM, payload.previousMeterNumber);
      this._safeAssign(woFields, WO_NEW_METER_NUM, payload.newMeterNumber);
      this._safeAssign(woFields, WO_PREV_READING, payload.previousMeterReading);
      this._safeAssign(woFields, WO_OLD_READING, payload.oldMeterReadingCaptured);
      this._safeAssign(woFields, WO_NEW_READING, payload.newMeterReading);
      this._safeAssign(woFields, WO_METER_REPLACED, payload.meterAlreadyReplaced);
      this._safeAssign(woFields, WO_METER_ALREADY_REPLACED, payload.meterAlreadyReplaced);
      this._safeAssign(woFields, WO_METER_NOT_REPLACED, payload.meterNotReplaced);
      this._safeAssign(woFields, WO_LEAKAGE_OBSERVED, payload.gasLeakageObserved);
      this._safeAssign(woFields, WO_LEAKAGE_LOCATION, payload.leakageLocation);
      this._safeAssign(woFields, WO_MCV_STATUS, payload.mcvStatus);
      this._safeAssign(woFields, WO_GAS_DETECTOR, payload.gasDetectorReading);
      this._safeAssign(woFields, WO_RIV_CLOSED, payload.rivClosed);
      this._safeAssign(woFields, WO_CASE_REMARK, payload.leakageCaseNumber);
      this._safeAssign(woFields, WO_INLET_OUTLET_REV, payload.inletOutletReversalNeeded);
      this._safeAssign(woFields, WO_REV_CORRECTION, payload.rectificationRemark);
      this._safeAssign(woFields, WO_DISCONNECT_REQ, payload.disconnectionRequired);
      this._safeAssign(woFields, WO_DISCONNECT_REMARK, payload.disconnectionRemark);
      this._safeAssign(woFields, WO_MCV_PLUG_REQ, payload.mcvPluggingRequired);
      this._safeAssign(woFields, WO_MCV_PLUG_REMARK, payload.mcvPluggingRemark);
      this._safeAssign(woFields, WO_COUNTER_REMARKS, payload.meterCounterRemarks);
      this._safeAssign(woFields, WO_METER_SOUND, payload.meterSound);
      this._safeAssign(woFields, WO_OLD_RUSTED, payload.oldMeterRusted);
      this._safeAssign(woFields, WO_COUNTER_SMOKEY, payload.counterDefectiveSmoke);
      this._safeAssign(woFields, WO_METER_FAULTY, payload.meterFaulty);
      this._safeAssign(woFields, WO_METER_NOT_RUNNING, payload.meterNotRunning);
      this._safeAssign(woFields, WO_RUBBER_HOSE, payload.rubberHoseCondition);
      this._safeAssign(woFields, WO_FINAL_REMARK, payload.finalRemark);
      this._safeAssign(woFields, WO_GAS_TYPE, payload.gasType);

      await updateRecord({ fields: woFields });

      // ServiceAppointment update if available
      if (payload.serviceAppointmentId) {
        const saFields = {};
        saFields.Id = payload.serviceAppointmentId;
        this._safeAssign(saFields, SA_METER_UNSAFE, payload.meterUnsafe);
        this._safeAssign(saFields, SA_METER_INACCESSIBLE, payload.meterInaccessible);
        this._safeAssign(saFields, SA_CUST_READY_SHIFT, payload.customerReadyToShift);
        this._safeAssign(saFields, SA_ALT_PHONE, payload.alternatePhone);
        this._safeAssign(saFields, SA_CORRECT_ADDR, payload.correctAddress);
        // Tenant fields only if present in your org
        // this._safeAssign(saFields, SA_TENANT_NAME, payload.tenantName);
        // this._safeAssign(saFields, SA_TENANT_MOBILE, payload.tenantMobile);

        await updateRecord({ fields: saFields });
      }
    }
  }

  async _saveFinalRemarkHybrid() {
    if (navigator.onLine) {
      return saveFinalRemark({ workOrderId: this.recordId, remark: this.finalRemark });
    } else {
      const fields = {};
      this._safeAssign(fields, WO_ID_FIELD, this.recordId);
      this._safeAssign(fields, WO_FINAL_REMARK, this.finalRemark);
       await updateRecord({ fields });
        await this._completeWorkStepOffline();
    }
  }

  _safeAssign(obj, fieldImport, value) {
    if (fieldImport && fieldImport.fieldApiName) {
      obj[fieldImport.fieldApiName] = value;
    }
  }

  _uploadOrQueue(items, apexMethod,  forceOfflineSave = false) {
    if (navigator.onLine) {
      return apexMethod({ recordId: this.recordId, listFiles: items });
    } else {
        if (!forceOfflineSave) {
        return Promise.resolve();
      }
      return this._saveImagesOffline(items);
    }
  }

  async _saveImagesOffline(items) {
    const promises = items.map(item => {
      const cvFields = {};

      // Title = label (no extension) if available
      const title = item.label || item.fileName || 'Photo';

      // PathOnClient must have an extension (for image icon)
      let pathName = item.fileName || title;
      if (!/\.[A-Za-z0-9]+$/.test(pathName)) {
        pathName = `${title}.jpg`;
      }

      this._safeAssign(cvFields, CV_TITLE, title);      // e.g. "Old Meter Photo"
      this._safeAssign(cvFields, CV_PATH, pathName);    // e.g. "Old Meter Photo.jpg"
      this._safeAssign(cvFields, CV_DATA, item.base64Data);
      this._safeAssign(cvFields, CV_LINK_ID, this.recordId);

      return createRecord({ apiName: CV_OBJECT.objectApiName, fields: cvFields });
    });
    return Promise.all(promises);
  }


  // ---------- Compression helpers ----------
  compressImageToDataUrl(input, { maxWidth = this.IMG_MAX_WIDTH, quality = this.IMG_QUALITY } = {}) {
    return new Promise((resolve, reject) => {
      const img = new Image();
      img.onerror = () => reject(new Error('Image load failed during compression'));

      const doCompress = () => {
        try {
          const origW = img.width || maxWidth;
          const origH = img.height || Math.round(maxWidth * 0.75);
          let targetW = origW;
          let targetH = origH;
          if (origW > maxWidth) {
            const ratio = origW / origH;
            targetW = maxWidth;
            targetH = Math.round(maxWidth / ratio);
          }
          const canvas = document.createElement('canvas');
          canvas.width = targetW;
          canvas.height = targetH;
          const ctx = canvas.getContext('2d');
          ctx.drawImage(img, 0, 0, targetW, targetH);

          canvas.toBlob(blob => {
            if (!blob) return reject(new Error('Canvas toBlob returned null'));
            const fr = new FileReader();
            fr.onload = () => resolve(fr.result);
            fr.onerror = err => reject(err);
            fr.readAsDataURL(blob);
          }, 'image/jpeg', quality);
        } catch (err) {
          reject(err);
        }
      };

      if (typeof input === 'string' && input.indexOf('data:') === 0) {
        img.onload = doCompress;
        img.src = input;
      } else if (input instanceof File) {
        const fr = new FileReader();
        fr.onload = (e) => {
          img.onload = doCompress;
          img.src = e.target.result;
        };
        fr.onerror = (err) => reject(err);
        fr.readAsDataURL(input);
      } else {
        reject(new Error('compressImageToDataUrl expects a File or data URL string'));
      }
    });
  }

  // async _compressPayloadItem(item) {
  //   const fileObj = item.file || null;
  //   const previewUrl = item.previewUrl || (item.base64Data ? ('data:image/jpeg;base64,' + item.base64Data) : null);

  //   if (fileObj) {
  //     const dataUrl = await this.compressImageToDataUrl(fileObj);
  //     const base64 = dataUrl.split(',')[1];
  //     if (!base64 || base64.length < this.MIN_BASE64_LENGTH) throw new Error('Compressed base64 invalid for ' + (item.fileName || 'file'));
  //     return {
  //       fileName: item.fileName || fileObj.name || 'image.jpg',
  //       label: item.label || item.fileName || fileObj.name || 'image',
  //       base64Data: base64,
  //       index: item.index || null
  //     };
  //   } else if (previewUrl) {
  //     const dataUrl = await this.compressImageToDataUrl(previewUrl);
  //     const base64 = dataUrl.split(',')[1];
  //     if (!base64 || base64.length < this.MIN_BASE64_LENGTH) throw new Error('Compressed base64 invalid for ' + (item.fileName || item.label || 'preview'));
  //     return {
  //       fileName: item.fileName || item.label || 'image.jpg',
  //       label: item.label || item.fileName || 'image',
  //       base64Data: base64,
  //       index: item.index || null
  //     };
  //   } else if (item.base64Data) {
  //     const dataUrlIn = 'data:image/jpeg;base64,' + item.base64Data;
  //     const dataUrl = await this.compressImageToDataUrl(dataUrlIn);
  //     const base64 = dataUrl.split(',')[1];
  //     if (!base64 || base64.length < this.MIN_BASE64_LENGTH) throw new Error('Compressed base64 invalid for base64Data item');
  //     return {
  //       fileName: item.fileName || item.label || 'image.jpg',
  //       label: item.label || item.fileName || 'image',
  //       base64Data: base64,
  //       index: item.index || null
  //     };
  //   } else {
  //     throw new Error('No source to compress for item: ' + (item.fileName || item.label || 'unknown'));
  //   }
  // }

  async _compressPayloadItem(item) {
      const fileObj = item.file || null;
      const previewUrl =
        item.previewUrl || (item.base64Data ? 'data:image/jpeg;base64,' + item.base64Data : null);

      // 1) Decide the LABEL (no extension)
      const label =
        (item.label && item.label.trim()) ||
        (item.fileName && item.fileName.replace(/\.[^.]+$/, '')) ||
        (fileObj && fileObj.name && fileObj.name.replace(/\.[^.]+$/, '')) ||
        'Photo';

      // 2) Decide a base fileName, then ensure it has an extension
      let fileName =
        item.fileName ||
        (fileObj && fileObj.name) ||
        `${label}.jpg`;

      if (!/\.[A-Za-z0-9]+$/.test(fileName)) {
        // No extension → force .jpg
        fileName = `${label}.jpg`;
      }

      const buildResult = (base64) => {
        if (!base64 || base64.length < this.MIN_BASE64_LENGTH) {
          throw new Error('Compressed base64 invalid for ' + label);
        }
        return {
          fileName,   // "Old Meter Photo.jpg"
          label,      // "Old Meter Photo"
          base64Data: base64,
          index: item.index || null
        };
      };

      if (fileObj) {
        const dataUrl = await this.compressImageToDataUrl(fileObj);
        const base64 = dataUrl.split(',')[1];
        return buildResult(base64);
      } else if (previewUrl) {
        const dataUrl = await this.compressImageToDataUrl(previewUrl);
        const base64 = dataUrl.split(',')[1];
        return buildResult(base64);
      } else if (item.base64Data) {
        const dataUrlIn = 'data:image/jpeg;base64,' + item.base64Data;
        const dataUrl = await this.compressImageToDataUrl(dataUrlIn);
        const base64 = dataUrl.split(',')[1];
        return buildResult(base64);
      } else {
        throw new Error('No source to compress for item: ' + label);
      }
    }



  async _compressAndChunkUpload(items = [], apexUploadFn, recordId) {
    if (!items || !items.length) throw new Error('No items to upload');

    const compressedList = [];
    for (const it of items) {
      try {
        const compressed = await this._compressPayloadItem(it);
        compressedList.push({
          fileName: compressed.fileName,
          label: compressed.label,
          base64Data: compressed.base64Data,
          index: compressed.index
        });
        await new Promise(r => setTimeout(r, 20));
      } catch (err) {
        console.warn('Skipping image after compression failure:', it.fileName || it.label, err);
      }
    }

    if (!compressedList.length) throw new Error('No valid compressed images to upload');

    if (navigator.onLine) {
      for (let i = 0; i < compressedList.length; i += this.UPLOAD_CHUNK_SIZE) {
        const chunk = compressedList.slice(i, i + this.UPLOAD_CHUNK_SIZE);
        let attempt = 0;
        while (attempt <= this.UPLOAD_RETRY_COUNT) {
          try {
            await apexUploadFn({ recordId, listFiles: chunk });
            break;
          } catch (err) {
            attempt++;
            if (attempt > this.UPLOAD_RETRY_COUNT) throw err;
            await new Promise(res => setTimeout(res, 300 * attempt));
          }
        }
      }
    } else {
      await this._saveImagesOffline(compressedList);
    }
    return true;
  }

    // Build a stable key for final image de-duplication across events
  _makeFinalImageKey(fileStep) {
    const name = fileStep.fileName || fileStep.name || '';
    const label = fileStep.label || '';
    const idx = fileStep.index || '';
    return `${name}::${label}::${idx}`;
  }

    // ---------- OFFLINE WorkStep completion (mirror of Apex updateWorkStepStatus) ----------
  async _completeWorkStepOffline() {
    if (navigator.onLine) {
      return;
    }

    const STEP_NAME = 'Data Captures Detail';

    try {
      if (this.dataCaptureWorkStepId) {
        const wsFields = {};
        wsFields[WS_ID_FIELD.fieldApiName] = this.dataCaptureWorkStepId;
        wsFields[WS_STATUS_FIELD.fieldApiName] = 'Completed';
        await updateRecord({ fields: wsFields });
        return;
      }

      // Otherwise, try to find the WorkStep in the local cache via GraphQL
      const result = await graphql({
        query: WS_OFFLINE_QUERY,
        variables: { recordId: this.recordId, stepName: STEP_NAME }
      });

      const node =
        result?.uiapi?.query?.WorkStep?.edges?.[0]?.node;

      if (!node || !node.Id) {
        console.warn('No WorkStep found in offline cache for Data Captures Detail');
        return;
      }

      this.dataCaptureWorkStepId = node.Id;

      const wsFields = {};
      wsFields[WS_ID_FIELD.fieldApiName] = node.Id;
      wsFields[WS_STATUS_FIELD.fieldApiName] = 'Completed';
      await updateRecord({ fields: wsFields });
    } catch (e) {
      console.error('Offline WorkStep completion failed', e);
    }
  }



}