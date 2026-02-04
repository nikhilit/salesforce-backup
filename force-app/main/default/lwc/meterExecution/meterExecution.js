import { LightningElement, api, track, wire } from 'lwc';
import { updateRecord, createRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

import METER_NUMBER from '@salesforce/schema/WorkOrder.Meter_Number__c';
import METER_READING from '@salesforce/schema/WorkOrder.Meter_Reading__c';
import REMARKS from '@salesforce/schema/WorkOrder.Remarks__c';
import getSubTypeForWorkOrder from '@salesforce/apex/MeterExecutionController.getSubTypeForWorkOrder';

import ID_FIELD from '@salesforce/schema/WorkStep.Id';
import STATUS_FIELD from '@salesforce/schema/WorkStep.Status';

import { getRelatedListRecords } from 'lightning/uiRelatedListApi';

export default class MeterExecution extends NavigationMixin(LightningElement) {
    @api recordId;

    @track workStepId = '';

    @track meterNumber = '';
    @track meterReading = '';
    @track reasonOtherRemark = '';
    @track showPreviewModal = false;
@track previewUrl = '';
@track previewFileName = '';

@track subTypeValue = '';
@track showRemoveMeterReasons = false;
@track showEntireConnectionUpReasons = false;
@track showInstallMeterReasons = false;
@track showTemporaryDisconnectionReasons = false;
@track showReconnectionTemporaryDisconnectionReasons = false;
@track showCopperPipeRelatedReasons = false;
@track showESCNCopyReasons = false;
@track showGIPipeReasons = false;
@track showGIPipeSocietyReasons = false;
@track showGasGeyserReasons = false;
@track showMeterBracketReasons = false;
@track showMeterLostReasons = false;
@track showPipeWorkSocietyReasons = false;
@track showPVCClampingReasons = false;
@track showRegulatorReplacementReasons = false;
@track showRemoveGasGeyserReasons = false;
@track showReticulatedCaseReasons = false;
@track showTConnectionReasons = false;
@track showUnsafeInstallationReasons = false;


















@track selectedReason = '';

    noOfPhotosBeforeWork = 3;
    noOfPhotosAfterWork = 3;
    noOfPhotosMeterWork = 3;
    noOfPhotosAddPhotos = 3;

    noOfPhotosHIRA = 1;
    noOfPhotosPNGNote = 1;

    @track photoUploadSlotsBeforeWork = [];
    @track photoUploadSlotsAfterWork = [];
    @track photoUploadSlotsAddPhotos = [];

    @track photoUploadSlotsMeterWork = [];
    @track photoUploadSlotsHIRA = [];
    @track photoUploadSlotsPNGNote = [];


   removeMeterReasons = [
    { label: '--- Work Done ---', value: 'WD_Header', disabled: true },
    { label: 'Meter removed successfully', value: 'Meter removed successfully' },

    { label: '--- Work Not Done ---', value: 'WND_Header', disabled: true },
    { label: 'Address not found', value: 'Address not found' },
    { label: 'Connection not traceable', value: 'Connection not traceable' },
    { label: 'Customer asked to reschedule', value: 'Customer asked to reschedule' },
    { label: 'Customer not responding to calls', value: 'Customer not responding to calls' },
    { label: 'Customer out of station', value: 'Customer out of station' },
    { label: 'Customer refused the work', value: 'Customer refused the work' },
    { label: 'Customer wants only guidelines', value: 'Customer wants only guidelines' },
    { label: 'Future date given beyond benchmark', value: 'Future date given beyond benchmark' },
    { label: 'Gas leakage detected - Supply cut off', value: 'Gas leakage detected - Supply cut off' },
    { label: 'House locked', value: 'House locked' },
    { label: 'Meter jammed / Rusted bolts', value: 'Meter jammed / Rusted bolts' },
    { label: 'Meter location not accessible', value: 'Meter location not accessible' },
    { label: 'Quotation provided but customer not agreeing', value: 'Quotation provided but customer not agreeing' },
    { label: 'Society not allowing entry', value: 'Society not allowing entry' },
    { label: 'Unsafe installation – removal not possible', value: 'Unsafe installation – removal not possible' },
    { label: 'Other', value: 'Other' },

    { label: '--- Request Closed – Customer Side ---', value: 'RCCS_Header', disabled: true },
    { label: 'Customer cancelled the complaint', value: 'Customer cancelled the complaint' },
    { label: 'Customer fixed issue privately', value: 'Customer fixed issue privately' },
    { label: 'Customer not interested', value: 'Customer not interested' },
    { label: 'Customer said he will call later', value: 'Customer said he will call later' },
    { label: 'Customer wants only guidelines', value: 'Customer wants only guidelines' },
    { label: 'Customer wants to close without visit', value: 'Customer wants to close without visit' },
    { label: 'Future date given beyond benchmark', value: 'Future date given beyond benchmark' }
];

entireConnectionCheckReasons = [
    { label: '--- Work Done ---', value: 'WD_Header', disabled: true },
    { label: 'Entire connection check completed', value: 'Entire connection check completed' },

    { label: '--- Work Not Done ---', value: 'WND_Header', disabled: true },
    { label: 'Access Not Provided by Security / Society', value: 'Access Not Provided by Security / Society' },
    { label: 'Address not found', value: 'Address not found' },
    { label: 'Concealed piping not accessible', value: 'Concealed piping not accessible' },
    { label: 'Customer asked to reschedule', value: 'Customer asked to reschedule' },
    { label: 'Customer not available', value: 'Customer not available' },
    { label: 'Customer out of station', value: 'Customer out of station' },
    { label: 'Customer refused safety check charges', value: 'Customer refused safety check charges' },
    { label: 'Customer unreachable', value: 'Customer unreachable' },
    { label: 'House locked', value: 'House locked' },
    { label: 'Kitchen under renovation', value: 'Kitchen under renovation' },
    { label: 'Unsafe installation', value: 'Unsafe installation' },
    { label: 'Other', value: 'Other' },

    { label: '--- Request Closed – Customer Side ---', value: 'RCCS_Header', disabled: true },
    { label: 'Customer cancelled the complaint', value: 'Customer cancelled the complaint' },
    { label: 'Customer fixed issue privately', value: 'Customer fixed issue privately' },
    { label: 'Customer not interested', value: 'Customer not interested' },
    { label: 'Customer said he will call later', value: 'Customer said he will call later' },
    { label: 'Customer wants only guidelines', value: 'Customer wants only guidelines' },
    { label: 'Customer wants to close without visit', value: 'Customer wants to close without visit' },
    { label: 'Future date given beyond benchmark', value: 'Future date given beyond benchmark' }
];

installMeterReasons = [
    { label: '--- Work Done ---', value: 'WD_Header', disabled: true },
    { label: 'Meter installed successfully', value: 'Meter installed successfully' },

    { label: '--- Work Not Done ---', value: 'WND_Header', disabled: true },
    { label: 'Address incorrect', value: 'Address incorrect' },
    { label: 'Customer asked to reschedule', value: 'Customer asked to reschedule' },
    { label: 'Customer refused installation', value: 'Customer refused installation' },
    { label: 'Customer unavailable / No response', value: 'Customer unavailable / No response' },
    { label: 'Customer wants only guidelines', value: 'Customer wants only guidelines' },
    { label: 'House locked', value: 'House locked' },
    { label: 'Installation unsafe / Site not ready', value: 'Installation unsafe / Site not ready' },
    { label: 'Internal piping not ready', value: 'Internal piping not ready' },
    { label: 'Meter location not accessible', value: 'Meter location not accessible' },
    { label: 'Payment not ready', value: 'Payment not ready' },
    { label: 'Quotation provided but customer not agreeing', value: 'Quotation provided but customer not agreeing' },
    { label: 'Society not allowing entry', value: 'Society not allowing entry' },
    { label: 'Other', value: 'Other' },

    { label: '--- Request Closed – Customer Side ---', value: 'RCCS_Header', disabled: true },
    { label: 'Customer cancelled the complaint', value: 'Customer cancelled the complaint' },
    { label: 'Customer fixed issue privately', value: 'Customer fixed issue privately' },
    { label: 'Customer not interested', value: 'Customer not interested' },
    { label: 'Customer said he will call later', value: 'Customer said he will call later' },
    { label: 'Customer wants only guidelines', value: 'Customer wants only guidelines' },
    { label: 'Customer wants to close without visit', value: 'Customer wants to close without visit' },
    { label: 'Future date given beyond benchmark', value: 'Future date given beyond benchmark' }
];

temporaryDisconnectionReasons = [
    { label: '--- Work Done ---', value: 'WD_Header', disabled: true },
    { label: 'Temporary disconnection completed', value: 'Temporary disconnection completed' },

    { label: '--- Work Not Done ---', value: 'WND_Header', disabled: true },
    { label: 'Address not found', value: 'Address not found' },
    { label: 'Customer asked to reschedule', value: 'Customer asked to reschedule' },
    { label: 'Customer not available', value: 'Customer not available' },
    { label: 'Customer refused disconnection charges', value: 'Customer refused disconnection charges' },
    { label: 'Customer wants only guidelines', value: 'Customer wants only guidelines' },
    { label: 'House locked', value: 'House locked' },
    { label: 'Meter location not accessible', value: 'Meter location not accessible' },
    { label: 'Outstanding dues pending', value: 'Outstanding dues pending' },
    { label: 'Society not allowing entry', value: 'Society not allowing entry' },
    { label: 'Tenant/Owner dispute', value: 'Tenant/Owner dispute' },
    { label: 'Unsafe installation', value: 'Unsafe installation' },
    { label: 'Other', value: 'Other' },

    { label: '--- Request Closed – Customer Side ---', value: 'RCCS_Header', disabled: true },
    { label: 'Customer cancelled the complaint', value: 'Customer cancelled the complaint' },
    { label: 'Customer fixed issue privately', value: 'Customer fixed issue privately' },
    { label: 'Customer not interested', value: 'Customer not interested' },
    { label: 'Customer said he will call later', value: 'Customer said he will call later' },
    { label: 'Customer wants only guidelines', value: 'Customer wants only guidelines' },
    { label: 'Customer wants to close without visit', value: 'Customer wants to close without visit' },
    { label: 'Future date given beyond benchmark', value: 'Future date given beyond benchmark' }
];

reconnectionTemporaryDisconnectionReasons = [
    { label: '--- Work Done ---', value: 'WD_Header', disabled: true },
    { label: 'Reconnection completed', value: 'Reconnection completed' },

    { label: '--- Work Not Done ---', value: 'WND_Header', disabled: true },
    { label: 'Address incorrect', value: 'Address incorrect' },
    { label: 'Customer asked to reschedule', value: 'Customer asked to reschedule' },
    { label: 'Customer not responding', value: 'Customer not responding' },
    { label: 'Customer out of station', value: 'Customer out of station' },
    { label: 'Customer refused charges', value: 'Customer refused charges' },
    { label: 'House locked', value: 'House locked' },
    { label: 'Internal piping damaged', value: 'Internal piping damaged' },
    { label: 'Previous dues not cleared', value: 'Previous dues not cleared' },
    { label: 'Society not allowing entry', value: 'Society not allowing entry' },
    { label: 'Unsafe installation', value: 'Unsafe installation' },
    { label: 'Other', value: 'Other' },

    { label: '--- Request Closed – Customer Side ---', value: 'RCCS_Header', disabled: true },
    { label: 'Customer cancelled the complaint', value: 'Customer cancelled the complaint' },
    { label: 'Customer fixed issue privately', value: 'Customer fixed issue privately' },
    { label: 'Customer not interested', value: 'Customer not interested' },
    { label: 'Customer said he will call later', value: 'Customer said he will call later' },
    { label: 'Customer wants only guidelines', value: 'Customer wants only guidelines' },
    { label: 'Customer wants to close without visit', value: 'Customer wants to close without visit' },
    { label: 'Future date given beyond benchmark', value: 'Future date given beyond benchmark' }
];

copperPipeRelatedReasons = [
    { label: '--- Work Done ---', value: 'WD_Header', disabled: true },
    { label: 'Copper pipe work completed', value: 'Copper pipe work completed' },

    { label: '--- Work Not Done ---', value: 'WND_Header', disabled: true },
    { label: 'Access not allowed', value: 'Access not allowed' },
    { label: 'Address not found', value: 'Address not found' },
    { label: 'Concealed piping not accessible', value: 'Concealed piping not accessible' },
    { label: 'Customer asked to reschedule', value: 'Customer asked to reschedule' },
    { label: 'Customer refused charges', value: 'Customer refused charges' },
    { label: 'Customer refused the work', value: 'Customer refused the work' },
    { label: 'Customer unavailable', value: 'Customer unavailable' },
    { label: 'House locked', value: 'House locked' },
    { label: 'Quotation given but rejected', value: 'Quotation given but rejected' },
    { label: 'Unsafe installation', value: 'Unsafe installation' },
    { label: 'Other', value: 'Other' },

    { label: '--- Request Closed – Customer Side ---', value: 'RCCS_Header', disabled: true },
    { label: 'Customer cancelled the complaint', value: 'Customer cancelled the complaint' },
    { label: 'Customer fixed issue privately', value: 'Customer fixed issue privately' },
    { label: 'Customer not interested', value: 'Customer not interested' },
    { label: 'Customer said he will call later', value: 'Customer said he will call later' },
    { label: 'Customer wants only guidelines', value: 'Customer wants only guidelines' },
    { label: 'Customer wants to close without visit', value: 'Customer wants to close without visit' },
    { label: 'Future date given beyond benchmark', value: 'Future date given beyond benchmark' }
];

escnCopyReasons = [
    { label: '--- Work Done ---', value: 'WD_Header', disabled: true },
    { label: 'ESCN copy provided', value: 'ESCN copy provided' },

    { label: '--- Work Not Done ---', value: 'WND_Header', disabled: true },
    { label: 'Address incorrect', value: 'Address incorrect' },
    { label: 'Customer asked to reschedule', value: 'Customer asked to reschedule' },
    { label: 'Customer not available', value: 'Customer not available' },
    { label: 'House locked', value: 'House locked' },
    { label: 'Society not allowing entry', value: 'Society not allowing entry' },
    { label: 'Other', value: 'Other' },

    { label: '--- Request Closed – Customer Side ---', value: 'RCCS_Header', disabled: true },
    { label: 'Customer cancelled the complaint', value: 'Customer cancelled the complaint' },
    { label: 'Customer found original copy', value: 'Customer found original copy' },
    { label: 'Customer not interested', value: 'Customer not interested' },
    { label: 'Customer said he will call later', value: 'Customer said he will call later' }
];

giPipeRelatedReasons = [
    { label: '--- Work Done ---', value: 'WD_Header', disabled: true },
    { label: 'GI pipe work completed', value: 'GI pipe work completed' },

    { label: '--- Work Not Done ---', value: 'WND_Header', disabled: true },
    { label: 'Address not found', value: 'Address not found' },
    { label: 'Customer asked to reschedule', value: 'Customer asked to reschedule' },
    { label: 'Customer refused', value: 'Customer refused' },
    { label: 'Customer refused charges', value: 'Customer refused charges' },
    { label: 'Customer unavailable / No response', value: 'Customer unavailable / No response' },
    { label: 'Due to scaffolding presence work cant be done', value: 'Due to scaffolding presence work cant be done' },
    { label: 'House locked', value: 'House locked' },
    { label: 'Painting/Civil work pending', value: 'Painting/Civil work pending' },
    { label: 'Quotation provided but customer not agreeing', value: 'Quotation provided but customer not agreeing' },
    { label: 'Society not allowing entry', value: 'Society not allowing entry' },
    { label: 'Unsafe installation', value: 'Unsafe installation' },
    { label: 'Other', value: 'Other' },

    { label: '--- Request Closed – Customer Side ---', value: 'RCCS_Header', disabled: true },
    { label: 'Customer cancelled the complaint', value: 'Customer cancelled the complaint' },
    { label: 'Customer fixed issue privately', value: 'Customer fixed issue privately' },
    { label: 'Customer not interested', value: 'Customer not interested' },
    { label: 'Customer said he will call later', value: 'Customer said he will call later' },
    { label: 'Customer wants only guidelines', value: 'Customer wants only guidelines' },
    { label: 'Customer wants to close without visit', value: 'Customer wants to close without visit' },
    { label: 'Future date given beyond benchmark', value: 'Future date given beyond benchmark' }
];

giPipeRelatedSocietyReasons = [
    { label: '--- Work Done ---', value: 'WD_Header', disabled: true },
    { label: 'GI pipe rectification completed', value: 'GI pipe rectification completed' },

    { label: '--- Work Not Done ---', value: 'WND_Header', disabled: true },
    { label: 'Area not accessible', value: 'Area not accessible' },
    { label: 'Customer/Society asked to reschedule', value: 'Customer/Society asked to reschedule' },
    { label: 'Due to scaffolding presence work cant be done', value: 'Due to scaffolding presence work cant be done' },
    { label: 'Excavation required but not allowed', value: 'Excavation required but not allowed' },
    { label: 'Quotation provided - Approval pending', value: 'Quotation provided - Approval pending' },
    { label: 'Rains/Weather interrupting work', value: 'Rains/Weather interrupting work' },
    { label: 'Secretary/Chairman not available', value: 'Secretary/Chairman not available' },
    { label: 'Society not permitting work', value: 'Society not permitting work' },
    { label: 'Society refused charges', value: 'Society refused charges' },
    { label: 'Unsafe conditions', value: 'Unsafe conditions' },
    { label: 'Other', value: 'Other' },

    { label: '--- Request Closed – Customer Side ---', value: 'RCCS_Header', disabled: true },
    { label: 'Customer cancelled the complaint', value: 'Customer cancelled the complaint' },
    { label: 'Customer fixed issue privately', value: 'Customer fixed issue privately' },
    { label: 'Customer not interested', value: 'Customer not interested' },
    { label: 'Customer said he will call later', value: 'Customer said he will call later' },
    { label: 'Customer wants only guidelines', value: 'Customer wants only guidelines' },
    { label: 'Customer wants to close without visit', value: 'Customer wants to close without visit' },
    { label: 'Future date given beyond benchmark', value: 'Future date given beyond benchmark' }
];

installationGasGeyserReasons = [
    { label: '--- Work Done ---', value: 'WD_Header', disabled: true },
    { label: 'Gas geyser installed', value: 'Gas geyser installed' },

    { label: '--- Work Not Done ---', value: 'WND_Header', disabled: true },
    { label: 'Address not found', value: 'Address not found' },
    { label: 'Customer asked to reschedule', value: 'Customer asked to reschedule' },
    { label: 'Customer not available', value: 'Customer not available' },
    { label: 'Customer refused charges', value: 'Customer refused charges' },
    { label: 'House locked', value: 'House locked' },
    { label: 'Payment not ready', value: 'Payment not ready' },
    { label: 'Quotation provided but customer not agreeing', value: 'Quotation provided but customer not agreeing' },
    { label: 'Society not allowing entry', value: 'Society not allowing entry' },
    { label: 'Other', value: 'Other' },
    { label: 'Unsafe installation (Ventilation)', value: 'Unsafe installation (Ventilation)' },

    { label: '--- Request Closed – Customer Side ---', value: 'RCCS_Header', disabled: true },
    { label: 'Customer cancelled the complaint', value: 'Customer cancelled the complaint' },
    { label: 'Customer fixed issue privately', value: 'Customer fixed issue privately' },
    { label: 'Customer not interested', value: 'Customer not interested' },
    { label: 'Customer said he will call later', value: 'Customer said he will call later' },
    { label: 'Customer wants only guidelines', value: 'Customer wants only guidelines' },
    { label: 'Customer wants to close without visit', value: 'Customer wants to close without visit' },
    { label: 'Future date given beyond benchmark', value: 'Future date given beyond benchmark' }
];

meterBracketReasons = [
    { label: '--- Work Done ---', value: 'WD_Header', disabled: true },
    { label: 'Meter bracket fixed/replaced', value: 'Meter bracket fixed/replaced' },

    { label: '--- Work Not Done ---', value: 'WND_Header', disabled: true },
    { label: 'Address not found', value: 'Address not found' },
    { label: 'Customer asked to reschedule', value: 'Customer asked to reschedule' },
    { label: 'Customer refused bracket work', value: 'Customer refused bracket work' },
    { label: 'Customer refused charges', value: 'Customer refused charges' },
    { label: 'Customer unavailable', value: 'Customer unavailable' },
    { label: 'House locked', value: 'House locked' },
    { label: 'Meter location not accessible', value: 'Meter location not accessible' },
    { label: 'Quotation provided but customer not agreeing', value: 'Quotation provided but customer not agreeing' },
    { label: 'Society not allowing entry', value: 'Society not allowing entry' },
    { label: 'Unsafe installation', value: 'Unsafe installation' },
    { label: 'Other', value: 'Other' },
    { label: 'Wall condition poor (Civil work needed)', value: 'Wall condition poor (Civil work needed)' },

    { label: '--- Request Closed – Customer Side ---', value: 'RCCS_Header', disabled: true },
    { label: 'Customer cancelled the complaint', value: 'Customer cancelled the complaint' },
    { label: 'Customer fixed issue privately', value: 'Customer fixed issue privately' },
    { label: 'Customer not interested', value: 'Customer not interested' },
    { label: 'Customer said he will call later', value: 'Customer said he will call later' },
    { label: 'Customer wants only guidelines', value: 'Customer wants only guidelines' },
    { label: 'Customer wants to close without visit', value: 'Customer wants to close without visit' },
    { label: 'Future date given beyond benchmark', value: 'Future date given beyond benchmark' }
];

meterLostReasons = [
    { label: '--- Work Done ---', value: 'WD_Header', disabled: true },
    { label: 'Case processed as per meter lost protocol', value: 'Case processed as per meter lost protocol' },

    { label: '--- Work Not Done ---', value: 'WND_Header', disabled: true },
    { label: 'Address incorrect', value: 'Address incorrect' },
    { label: 'Customer asked to reschedule', value: 'Customer asked to reschedule' },
    { label: 'Customer refused replacement charges', value: 'Customer refused replacement charges' },
    { label: 'Customer refused to proceed', value: 'Customer refused to proceed' },
    { label: 'Customer unable to provide required documents', value: 'Customer unable to provide required documents' },
    { label: 'Customer unavailable', value: 'Customer unavailable' },
    { label: 'House locked', value: 'House locked' },
    { label: 'Meter found during visit (Not lost)', value: 'Meter found during visit (Not lost)' },
    { label: 'Police NC copy not available', value: 'Police NC copy not available' },
    { label: 'Society not allowing entry', value: 'Society not allowing entry' },
    { label: 'Other', value: 'Other' },

    { label: '--- Request Closed – Customer Side ---', value: 'RCCS_Header', disabled: true },
    { label: 'Customer cancelled the complaint', value: 'Customer cancelled the complaint' },
    { label: 'Customer fixed issue privately', value: 'Customer fixed issue privately' },
    { label: 'Customer not interested', value: 'Customer not interested' },
    { label: 'Customer said he will call later', value: 'Customer said he will call later' },
    { label: 'Customer wants only guidelines', value: 'Customer wants only guidelines' },
    { label: 'Customer wants to close without visit', value: 'Customer wants to close without visit' },
    { label: 'Future date given beyond benchmark', value: 'Future date given beyond benchmark' }
];

pipeWorkSocietyRequestReasons = [
    // --- Work Done ---
    { label: '--- Work Done ---', value: 'WD_Header', disabled: true },
    { label: 'Society pipe work completed', value: 'Society pipe work completed' },

    // --- Work Not Done ---
    { label: '--- Work Not Done ---', value: 'WND_Header', disabled: true },
    { label: 'Due to scaffolding presence work cant be done', value: 'Due to scaffolding presence work cant be done' },
    { label: 'Gate locked / No access', value: 'Gate locked / No access' },
    { label: 'Quotation submitted - Waiting approval', value: 'Quotation submitted - Waiting approval' },
    { label: 'Reschedule requested by Society', value: 'Reschedule requested by Society' },
    { label: 'Secretary/Chairman not available', value: 'Secretary/Chairman not available' },
    { label: 'Society approval pending', value: 'Society approval pending' },
    { label: 'Society not permitting work', value: 'Society not permitting work' },
    { label: 'Society refused charges', value: 'Society refused charges' },
    { label: 'Unsafe conditions', value: 'Unsafe conditions' },
    { label: 'Other', value: 'Other' },
    { label: 'Weather/Rain interruption', value: 'Weather/Rain interruption' },

    // --- Request Closed – Customer Side ---
    { label: '--- Request Closed – Customer Side ---', value: 'RCCS_Header', disabled: true },
    { label: 'Society not interested', value: 'Society not interested' },
    { label: 'Society cancelled the complaint', value: 'Society cancelled the complaint' },
    { label: 'Society said he will call later', value: 'Society said he will call later' },
    { label: 'Society wants to close without visit', value: 'Society wants to close without visit' },
    { label: 'Society wants only guidelines', value: 'Society wants only guidelines' },
    { label: 'Society wants future date', value: 'Society wants future date' },
    { label: 'Society fixed issue privately', value: 'Society fixed issue privately' }
];

pvcClampingReasons = [
    // --- Work Done ---
    { label: '--- Work Done ---', value: 'WD_Header', disabled: true },
    { label: 'PVC clamping completed', value: 'PVC clamping completed' },

    // --- Work Not Done ---
    { label: '--- Work Not Done ---', value: 'WND_Header', disabled: true },
    { label: 'Address not found', value: 'Address not found' },
    { label: 'Customer asked to reschedule', value: 'Customer asked to reschedule' },
    { label: 'Customer refused charges', value: 'Customer refused charges' },
    { label: 'Customer refused the work', value: 'Customer refused the work' },
    { label: 'Customer unavailable', value: 'Customer unavailable' },
    { label: 'House locked', value: 'House locked' },
    { label: 'Pipe concealed - Clamping not possible', value: 'Pipe concealed - Clamping not possible' },
    { label: 'Quotation given but rejected', value: 'Quotation given but rejected' },
    { label: 'Society not allowing entry', value: 'Society not allowing entry' },
    { label: 'Unsafe installation', value: 'Unsafe installation' },
    { label: 'Wall condition too weak for clamps', value: 'Wall condition too weak for clamps' },
    { label: 'Other', value: 'Other' },

    // --- Request Closed – Customer Side ---
    { label: '--- Request Closed – Customer Side ---', value: 'RCCS_Header', disabled: true },
    { label: 'Customer cancelled the complaint', value: 'Customer cancelled the complaint' },
    { label: 'Customer fixed issue privately', value: 'Customer fixed issue privately' },
    { label: 'Customer not interested', value: 'Customer not interested' },
    { label: 'Customer said he will call later', value: 'Customer said he will call later' },
    { label: 'Customer wants only guidelines', value: 'Customer wants only guidelines' },
    { label: 'Customer wants to close without visit', value: 'Customer wants to close without visit' },
    { label: 'Future date given beyond benchmark', value: 'Future date given beyond benchmark' }
];

regulatorReplacementReasons = [
    // --- Work Done ---
    { label: '--- Work Done ---', value: 'WD_Header', disabled: true },
    { label: 'Regulator replaced successfully', value: 'Regulator replaced successfully' },

    // --- Work Not Done ---
    { label: '--- Work Not Done ---', value: 'WND_Header', disabled: true },
    { label: 'Address not found', value: 'Address not found' },
    { label: 'Customer refused charges', value: 'Customer refused charges' },
    { label: 'Customer refused replacement', value: 'Customer refused replacement' },
    { label: 'Customer requested reschedule', value: 'Customer requested reschedule' },
    { label: 'Customer unavailable', value: 'Customer unavailable' },
    { label: 'Hose pipe damaged', value: 'Hose pipe damaged' },
    { label: 'House locked', value: 'House locked' },
    { label: 'Problem in Gas Stove (Not Regulator)', value: 'Problem in Gas Stove (Not Regulator)' },
    { label: 'Quotation provided but customer not agreeing', value: 'Quotation provided but customer not agreeing' },
    { label: 'Unsafe installation', value: 'Unsafe installation' },
    { label: 'Other', value: 'Other' },

    // --- Request Closed – Customer Side ---
    { label: '--- Request Closed – Customer Side ---', value: 'RCCS_Header', disabled: true },
    { label: 'Customer cancelled the complaint', value: 'Customer cancelled the complaint' },
    { label: 'Customer fixed issue privately', value: 'Customer fixed issue privately' },
    { label: 'Customer not interested', value: 'Customer not interested' },
    { label: 'Customer said he will call later', value: 'Customer said he will call later' },
    { label: 'Customer wants only guidelines', value: 'Customer wants only guidelines' },
    { label: 'Customer wants to close without visit', value: 'Customer wants to close without visit' },
    { label: 'Future date given beyond benchmark', value: 'Future date given beyond benchmark' }
];

removalGasGeyserReasons = [
    { label: '--- Work Done ---', value: 'WD_Header', disabled: true },
    { label: 'Gas geyser removed', value: 'Gas geyser removed' },

    { label: '--- Work Not Done ---', value: 'WND_Header', disabled: true },
    { label: 'Address not found', value: 'Address not found' },
    { label: 'Customer asked to reschedule', value: 'Customer asked to reschedule' },
    { label: 'Customer changed mind (Refused)', value: 'Customer changed mind (Refused)' },
    { label: 'Customer refused removal charges', value: 'Customer refused removal charges' },
    { label: 'Customer unavailable', value: 'Customer unavailable' },
    { label: 'Customer wants only guidelines', value: 'Customer wants only guidelines' },
    { label: 'House locked', value: 'House locked' },
    { label: 'Quotation given but rejected', value: 'Quotation given but rejected' },
    { label: 'Society not allowing entry', value: 'Society not allowing entry' },
    { label: 'Unsafe installation', value: 'Unsafe installation' },
    { label: 'Other', value: 'Other' },

    { label: '--- Request Closed – Customer Side ---', value: 'RCCS_Header', disabled: true },
    { label: 'Customer cancelled the complaint', value: 'Customer cancelled the complaint' },
    { label: 'Customer fixed issue privately', value: 'Customer fixed issue privately' },
    { label: 'Customer not interested', value: 'Customer not interested' },
    { label: 'Customer said he will call later', value: 'Customer said he will call later' },
    { label: 'Customer wants only guidelines', value: 'Customer wants only guidelines' },
    { label: 'Customer wants to close without visit', value: 'Customer wants to close without visit' },
    { label: 'Future date given beyond benchmark', value: 'Future date given beyond benchmark' }
];

reticulatedCaseReasons = [
    { label: '--- Work Done ---', value: 'WD_Header', disabled: true },
    { label: 'Reticulated system check completed', value: 'Reticulated system check completed' },

    { label: '--- Work Not Done ---', value: 'WND_Header', disabled: true },
    { label: 'Access not available', value: 'Access not available' },
    { label: 'Address not found', value: 'Address not found' },
    { label: 'Customer refused charges', value: 'Customer refused charges' },
    { label: 'Customer unavailable', value: 'Customer unavailable' },
    { label: 'House locked', value: 'House locked' },
    { label: 'Quotation given but rejected', value: 'Quotation given but rejected' },
    { label: 'Society not permitting work', value: 'Society not permitting work' },
    { label: 'Unsafe installation', value: 'Unsafe installation' },
    { label: 'Other', value: 'Other' },

    { label: '--- Request Closed – Customer Side ---', value: 'RCCS_Header', disabled: true },
    { label: 'Customer cancelled the complaint', value: 'Customer cancelled the complaint' },
    { label: 'Customer fixed issue privately', value: 'Customer fixed issue privately' },
    { label: 'Customer not interested', value: 'Customer not interested' },
    { label: 'Customer said he will call later', value: 'Customer said he will call later' },
    { label: 'Customer wants only guidelines', value: 'Customer wants only guidelines' },
    { label: 'Customer wants to close without visit', value: 'Customer wants to close without visit' },
    { label: 'Future date given beyond benchmark', value: 'Future date given beyond benchmark' }
];

tConnectionReasons = [
    { label: '--- Work Done ---', value: 'WD_Header', disabled: true },
    { label: 'T connection installed', value: 'T connection installed' },

    { label: '--- Work Not Done ---', value: 'WND_Header', disabled: true },
    { label: 'Address not found', value: 'Address not found' },
    { label: 'Customer asked to reschedule', value: 'Customer asked to reschedule' },
    { label: 'Customer refused charges', value: 'Customer refused charges' },
    { label: 'Customer unavailable', value: 'Customer unavailable' },
    { label: 'Customer wants only guidelines', value: 'Customer wants only guidelines' },
    { label: 'House locked', value: 'House locked' },
    { label: 'Kitchen platform work pending', value: 'Kitchen platform work pending' },
    { label: 'Quotation provided but customer not agreeing', value: 'Quotation provided but customer not agreeing' },
    { label: 'Society not allowing entry', value: 'Society not allowing entry' },
    { label: 'Unsafe installation', value: 'Unsafe installation' },
    { label: 'Other', value: 'Other' },

    { label: '--- Request Closed – Customer Side ---', value: 'RCCS_Header', disabled: true },
    { label: 'Customer cancelled the complaint', value: 'Customer cancelled the complaint' },
    { label: 'Customer fixed issue privately', value: 'Customer fixed issue privately' },
    { label: 'Customer not interested', value: 'Customer not interested' },
    { label: 'Customer said he will call later', value: 'Customer said he will call later' },
    { label: 'Customer wants only guidelines', value: 'Customer wants only guidelines' },
    { label: 'Customer wants to close without visit', value: 'Customer wants to close without visit' },
    { label: 'Future date given beyond benchmark', value: 'Future date given beyond benchmark' }
];

unsafeInstallationReasons = [
    { label: '--- Work Done ---', value: 'WD_Header', disabled: true },
    { label: 'Unsafe installation corrected', value: 'Unsafe installation corrected' },

    { label: '--- Work Not Done ---', value: 'WND_Header', disabled: true },
    { label: 'Access not available / House Locked', value: 'Access not available / House Locked' },
    { label: 'Address not found', value: 'Address not found' },
    { label: 'Customer asked to reschedule', value: 'Customer asked to reschedule' },
    { label: 'Customer not responding', value: 'Customer not responding' },
    { label: 'Customer refused charges', value: 'Customer refused charges' },
    { label: 'Major unsafe condition', value: 'Major unsafe condition' },
    { label: 'Quotation given but rejected', value: 'Quotation given but rejected' },
    { label: 'Society not allowing entry', value: 'Society not allowing entry' },
    { label: 'Wall/Ceiling too weak for repair', value: 'Wall/Ceiling too weak for repair' },
    { label: 'Other', value: 'Other' },

    { label: '--- Request Closed – Customer Side ---', value: 'RCCS_Header', disabled: true },
    { label: 'Customer cancelled the complaint', value: 'Customer cancelled the complaint' },
    { label: 'Customer fixed issue privately', value: 'Customer fixed issue privately' },
    { label: 'Customer not interested', value: 'Customer not interested' },
    { label: 'Customer said he will call later', value: 'Customer said he will call later' },
    { label: 'Customer wants only guidelines', value: 'Customer wants only guidelines' },
    { label: 'Customer wants to close without visit', value: 'Customer wants to close without visit' },
    { label: 'Future date given beyond benchmark', value: 'Future date given beyond benchmark' }
];











    connectedCallback() {
        this.initSlots();
         getSubTypeForWorkOrder({ workOrderId: this.recordId })
    .then(result => {
        this.subTypeValue = result;
        this.showRemoveMeterReasons = (this.subTypeValue === 'Remove Meter');
        this.showEntireConnectionUpReasons = (this.subTypeValue === 'Entire Connection Check - UP');
        this.showInstallMeterReasons = (this.subTypeValue === 'Install Meter');
        this.showTemporaryDisconnectionReasons = (this.subTypeValue === 'Temporary Disconnection');
        this.showReconnectionTemporaryDisconnectionReasons = (this.subTypeValue === 'Reconnection Temporary Disconnection');
        this.showCopperPipeRelatedReasons = (this.subTypeValue === 'Copper Pipe Related');
        this.showESCNCopyReasons = (this.subTypeValue === 'ESCN Copy');
        this.showGIPipeReasons = (this.subTypeValue === 'GI Pipe Related');
        this.showGIPipeSocietyReasons = (this.subTypeValue === 'GI Pipe Related - Entire Society');
        this.showGasGeyserReasons = (this.subTypeValue === 'Installation of Gas Geyser');
        this.showMeterBracketReasons = (this.subTypeValue === 'Meter Bracket');
        this.showMeterLostReasons = (this.subTypeValue === 'Meter Lost');
        this.showPipeWorkSocietyReasons = (this.subTypeValue === 'Pipe Work - Society Request');
        this.showPVCClampingReasons = (this.subTypeValue === 'PVC Clamping');
        this.showRegulatorReplacementReasons = (this.subTypeValue === 'Regulator Replacement');
        this.showRemoveGasGeyserReasons = (this.subTypeValue === 'Removal of Gas Geyser');
        this.showReticulatedCaseReasons = (this.subTypeValue === 'Reticulated Case');
        this.showTConnectionReasons = (this.subTypeValue === 'T Connection');
        this.showUnsafeInstallationReasons = (this.subTypeValue === 'Unsafe Installation');




    })
    .catch(error => console.error('Error fetching subtype', error));
    }

    initSlots() {
        this.photoUploadSlotsBeforeWork = this.createSlots(this.noOfPhotosBeforeWork, 'Before Work');
        this.photoUploadSlotsAfterWork = this.createSlots(this.noOfPhotosAfterWork, 'After Work');
        this.photoUploadSlotsAddPhotos = this.createSlots(this.noOfPhotosAddPhotos, 'Add Photos');
        this.photoUploadSlotsMeterWork = this.createSlots(this.noOfPhotosMeterWork, 'Meter Counter');
        this.photoUploadSlotsHIRA = this.createSlots(this.noOfPhotosHIRA, 'HIRA');
        this.photoUploadSlotsPNGNote = this.createSlots(this.noOfPhotosPNGNote, 'PNG Service Note');
    }


//     handleReasonChange(e) {
//     this.selectedReason = e.detail.value;
//     this.reasonOtherRemark = this.selectedReason; // mapping to Remarks field
// }

get reasonOptions() {
    if (this.subTypeValue === 'Remove Meter') {
        return this.removeMeterReasons;
    }
    if (this.subTypeValue === 'Entire Connection Check - UP') {
        return this.entireConnectionCheckReasons;
    }
    if (this.subTypeValue === 'Install Meter') {
    return this.installMeterReasons;
    }
    if (this.subTypeValue === 'Temporary Disconnection') {
    return this.temporaryDisconnectionReasons;
    }
    if (this.subTypeValue === 'Reconnection Temporary Disconnection') {
    return this.reconnectionTemporaryDisconnectionReasons;
    }
    if (this.subTypeValue === 'Copper Pipe Related') {
    return this.copperPipeRelatedReasons;
    }
    if (this.subTypeValue === 'ESCN Copy') {
    return this.escnCopyReasons;
    }
    if (this.subTypeValue === 'GI Pipe Related') {
    return this.giPipeRelatedReasons;
    }
    if (this.subTypeValue === 'GI Pipe Related - Entire Society') {
    return this.giPipeRelatedSocietyReasons;
    }
    if (this.subTypeValue === 'Installation of Gas Geyser') {
    return this.installationGasGeyserReasons;
    }
     if (this.subTypeValue === 'Meter Bracket') {
    return this.meterBracketReasons;
    }
     if (this.subTypeValue === 'Meter Lost') {
    return this.meterLostReasons;
   }
    if (this.subTypeValue === 'Pipe Work - Society Request') {
    return this.showPipeWorkSocietyReasons = true;
   }
    if (this.subTypeValue === 'PVC Clamping') {
    return this.pvcClampingReasons;
  }
  if(this.subTypeValue === 'Regulator Replacement') {
    return this.showRegulatorReplacementReasons;
  }
  if(this.subTypeValue === 'Removal of Gas Geyser'){
   return this.removalGasGeyserReasons;
  }
   if (this.subTypeValue === 'Reticulated Case') {
    return this.showReticulatedCaseReasons;
  }
  if (this.subTypeValue === 'T Connection') {
   return this.showTConnectionReasons;
 }
   if (this.subTypeValue === 'Unsafe Installation') {
   return this.showUnsafeInstallationReasons;
 }
















    return [];
}


handleReasonChange(e) {
    const val = e.detail.value;

    // Ignore disabled category headers
    if (val.endsWith('_Header')) {
        this.selectedReason = '';
        return;
    }

    this.selectedReason = val;
    this.reasonOtherRemark = val;
}


    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'WorkSteps',
        fields: ['WorkStep.Id', 'WorkStep.Name', 'WorkStep.Status']
    })
    wiredWorkStep({ data, error }) {
        if (data) {
            const step = data.records.find(r => r.fields.Name.value === 'Data Capture Details');
            if (step) {
                this.workStepId = step.id;
            }
        }
    }

    createSlots(count, label) {
        return Array.from({ length: count }, (_, i) => ({
            id: i + 1,
            index: i + 1,
            label,
            fileName: '',
            uploaded: false,
            base64Data: null,
            previewUrl: ''
        }));
    }

    async handleFileBeforeWork(e) { this.photoUploadSlotsBeforeWork = await this.processImageUpload(e.detail.steps); }
    async handleFileAfterWork(e) { this.photoUploadSlotsAfterWork = await this.processImageUpload(e.detail.steps); }
    async handleFileAddPhotos(e) { this.photoUploadSlotsAddPhotos = await this.processImageUpload(e.detail.steps); }
    async handleFileMeterWork(e) { this.photoUploadSlotsMeterWork = await this.processImageUpload(e.detail.steps); }
    async handleFileHIRA(e) { this.photoUploadSlotsHIRA = await this.processImageUpload(e.detail.steps); }
    async handleFilePNGNote(e) { this.photoUploadSlotsPNGNote = await this.processImageUpload(e.detail.steps); }

    async processImageUpload(newSlots) {
        for (let slot of newSlots) {
            if (!slot.base64Data) continue;

            const detectedMime = slot.base64Data.startsWith('data:')
                ? slot.base64Data.split(';')[0].replace('data:', '')
                : 'image/jpeg';

            const wrapper = slot.base64Data.startsWith('data:')
                ? slot.base64Data
                : `data:${detectedMime};base64,${slot.base64Data}`;

            slot.base64Data = wrapper;
            slot.uploaded = true;
        }
        return [...newSlots];
    }

    handleMeterNumberChange(e) { this.meterNumber = e.detail.value; }
    handleMeterReadingChange(e) { this.meterReading = e.detail.value; }
    handleReasonOtherRemarkChange(e) { this.reasonOtherRemark = e.detail.value; }

    handleSubmit() {
        this.updateWorkOrderFields()
            .then(() => this.uploadAllPhotos())
            .then(() => this.updateWorkStepDataCapture())
            .then(() => {
                this.showToast('Saved successfully', 'success');
               // this.navigateToRecord();
                this.handleCancel();
            })
            .catch(err => this.showToast(this.getError(err), 'error'));
    }

    updateWorkOrderFields() {
        const fields = {
            Id: this.recordId,
            [METER_NUMBER.fieldApiName]: this.meterNumber,
            [METER_READING.fieldApiName]: this.meterReading,
            [REMARKS.fieldApiName]: this.reasonOtherRemark
        };
        return updateRecord({ fields });
    }

    handleDelete(event) {
    const label = event.currentTarget.dataset.label;
    const index = event.currentTarget.dataset.index;

    let list;
    switch (label) {
        case 'Before Work': list = [...this.photoUploadSlotsBeforeWork]; break;
        case 'After Work': list = [...this.photoUploadSlotsAfterWork]; break;
        case 'Meter Counter': list = [...this.photoUploadSlotsMeterWork]; break;
        case 'Add Photos': list = [...this.photoUploadSlotsAddPhotos]; break;
        case 'HIRA': list = [...this.photoUploadSlotsHIRA]; break;
        case 'PNG Service Note': list = [...this.photoUploadSlotsPNGNote]; break;
    }

    list[index - 1].uploaded = false;
    list[index - 1].fileName = '';
    list[index - 1].previewUrl = '';
    list[index - 1].base64Data = null;

    if (label === 'Before Work') this.photoUploadSlotsBeforeWork = list;
    if (label === 'After Work') this.photoUploadSlotsAfterWork = list;
    if (label === 'Meter Counter') this.photoUploadSlotsMeterWork = list;
    if (label === 'Add Photos') this.photoUploadSlotsAddPhotos = list;
    if (label === 'HIRA') this.photoUploadSlotsHIRA = list;
    if (label === 'PNG Service Note') this.photoUploadSlotsPNGNote = list;

}

    async uploadAllPhotos() {
        const allSlots = [
            ...this.photoUploadSlotsBeforeWork,
            ...this.photoUploadSlotsAfterWork,
            ...this.photoUploadSlotsAddPhotos,
            ...this.photoUploadSlotsMeterWork,
            ...this.photoUploadSlotsHIRA,
            ...this.photoUploadSlotsPNGNote
        ];

        const uploads = allSlots
            .filter(s => s.uploaded && s.base64Data)
            .map(s => this.uploadFileToRecord(s));

        await Promise.all(uploads);
        return true;
    }

    async uploadFileToRecord(slot) {
        let mime = 'image/jpeg';
        if (slot.base64Data.startsWith('data:')) {
            mime = slot.base64Data.substring(5, slot.base64Data.indexOf(';'));
        }

        const extension = mime === 'application/pdf' ? 'pdf' : 'jpg';
        const fileName = `${slot.label.replace(/\s/g, '')}_${Date.now()}.${extension}`;

        const base64Body = slot.base64Data.includes(',')
            ? slot.base64Data.split(',')[1]
            : slot.base64Data;

        const contentVersionRecord = {
            apiName: 'ContentVersion',
            fields: {
                Title: fileName,
                PathOnClient: fileName,
                VersionData: base64Body,
                FirstPublishLocationId: this.recordId
            }
        };

        return createRecord(contentVersionRecord);
    }

    async compressImage(base64String, maxWidth = 1024, quality = 0.6) {
    return new Promise((resolve, reject) => {
        const img = new Image();
        img.onload = () => {
            // Calculate new dimensions
            const scale = maxWidth / img.width;
            const newWidth = img.width > maxWidth ? maxWidth : img.width;
            const newHeight = img.width > maxWidth ? img.height * scale : img.height;

            const canvas = document.createElement('canvas');
            canvas.width = newWidth;
            canvas.height = newHeight;

            const ctx = canvas.getContext('2d');
            ctx.drawImage(img, 0, 0, newWidth, newHeight);

            // Convert to compressed Base64
            const compressedBase64 = canvas.toDataURL('image/jpeg', quality);
            resolve(compressedBase64);
        };
        img.onerror = (e) => reject(e);
        img.src = base64String;
    });
}

async readFileAsBase64(file) {
    return new Promise((resolve, reject) => {
        const reader = new FileReader();

        reader.onload = async () => {
            let base64 = reader.result;

            // If PDF, return as-is
            if (file.type === 'application/pdf') {
                return resolve(base64);
            }

            // ---- COMPRESS IMAGES HERE ----
            try {
                const compressed = await this.compressImage(base64, 1024, 0.6);
                resolve(compressed);
            } catch (err) {
                console.error('Compression failed, using original:', err);
                resolve(base64); // fallback
            }
        };

        reader.onerror = () => reject(reader.error);
        reader.readAsDataURL(file);
    });
}

    


    async processSelectedFiles(files, label) {
    if (!files || files.length === 0) {
        return;
    }

    let targetSlots;

    switch (label) {
        case 'Before Work':
            targetSlots = this.photoUploadSlotsBeforeWork;
            break;
        case 'After Work':
            targetSlots = this.photoUploadSlotsAfterWork;
            break;
        case 'Add Photos':
            targetSlots = this.photoUploadSlotsAddPhotos;
            break;
        case 'Meter Counter':
            targetSlots = this.photoUploadSlotsMeterWork;
            break;
        case 'HIRA':
            targetSlots = this.photoUploadSlotsHIRA;
            break;
        case 'PNG Service Note':
            targetSlots = this.photoUploadSlotsPNGNote;
            break;
        default:
            return;
    }

     // LIMIT: Only 1 photo for these specific sections
    const singleUploadSections = ['Before Work', 'After Work', 'Meter Counter', 'HIRA', 'PNG Service Note' ];
    if (singleUploadSections.includes(label)) {
        if (files.length > 1) {
            this.showToast('Only 1 photo allowed', 'warning');
            return;
        }
        // If one already uploaded → replace it
        targetSlots.forEach(s => {
            s.uploaded = false;
            s.fileName = '';
            s.previewUrl = '';
            s.base64Data = null;
        });
    }


    let slotIndex = 0;

    for (let file of files) {
        if (slotIndex >= targetSlots.length) break;

        const base64 = await this.readFileAsBase64(file);

        targetSlots[slotIndex].fileName = file.name;
        targetSlots[slotIndex].base64Data = base64;
        targetSlots[slotIndex].uploaded = true;
        targetSlots[slotIndex].previewUrl = base64;

        slotIndex++;
    }

    // Reassign tracked values so UI refreshes
    if (label === 'Before Work') this.photoUploadSlotsBeforeWork = [...targetSlots];
    if (label === 'After Work') this.photoUploadSlotsAfterWork = [...targetSlots];
    if (label === 'Add Photos') this.photoUploadSlotsAddPhotos = [...targetSlots];
    if (label === 'Meter Counter') this.photoUploadSlotsMeterWork = [...targetSlots];
    if (label === 'HIRA') this.photoUploadSlotsHIRA = [...targetSlots];
    if (label === 'PNG Service Note') this.photoUploadSlotsPNGNote = [...targetSlots];
}


handleFilesInputChange(event) {
    const files = event.target.files;
    const label = event.target.dataset.label;

    this.processSelectedFiles(files, label);
}

triggerFileUpload(event) {
    const inputName = event.currentTarget.dataset.input;
    const fileInput = this.template.querySelector(`input[data-input="${inputName}"]`);

    if (fileInput) {
        fileInput.click();
    }
}


    async updateWorkStepDataCapture() {
        if (!this.workStepId) return;

        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.workStepId;
        fields[STATUS_FIELD.fieldApiName] = 'Completed';

        return updateRecord({ fields });
    }

    get isPdfPreview() {
    return this.previewUrl?.startsWith('data:application/pdf');
   }

    get isImagePreview() {
    return !this.isPdfPreview;
   }

   handlePreview(event) {
    this.previewUrl = event.currentTarget.dataset.url;
    this.previewFileName = event.currentTarget.dataset.name;
    this.showPreviewModal = true;
}

closePreview() {
    this.showPreviewModal = false;
    this.previewUrl = '';
    this.previewFileName = '';
}


    navigateToRecord() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'WorkOrder',
                actionName: 'view'
            }
        });
    }

    handleCancel() {
         setTimeout(() => {
            history.back();
        }, 1000); 
      
        
      }


    getError(err) {
        return err?.body?.message || err.message || JSON.stringify(err);
    }

    showToast(msg, variant) {
        this.dispatchEvent(new ShowToastEvent({ title: msg, variant }));
    }
}