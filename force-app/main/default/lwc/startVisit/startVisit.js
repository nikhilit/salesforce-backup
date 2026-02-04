/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 22-01-2026
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   08-08-2025   Kartik Patkar, Appstrail   Initial Version
 * 1.1   31-10-2025   Kartik Patkar, Appstrail   Offline parity (LDS + GraphQL wire) w/o affecting online
**/
import { LightningElement, api, track, wire } from 'lwc';
import { getLocationService } from 'lightning/mobileCapabilities';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getDispenserPoints from '@salesforce/apex/WorkOrderVisitController.getDispenserPoints';
import saveVisitDetails from '@salesforce/apex/WorkOrderVisitController.saveVisitDetails';
import getPicklistValuesApex from '@salesforce/apex/WorkOrderVisitController.getPicklistValues';
import insertDispenserPoint from '@salesforce/apex/WorkOrderVisitController.insertDispenserPoint';
import deleteDispenserPoints from '@salesforce/apex/WorkOrderVisitController.deleteDispenserPoints';
import uploadImage from '@salesforce/apex/WorkOrderVisitController.uploadImage';
import uploadSelfie from '@salesforce/apex/WorkOrderVisitController.uploadSelfieImage';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';

const SUMMARY_COLUMNS = [
	{ label: 'Dispenser Point', fieldName: 'Name' },
	{ label: 'Opening Reading', fieldName: 'Opening_Reading__c', type: 'number' },
	{ label: 'Closing Reading', fieldName: 'Closing_Reading__c', type: 'number' },
];

const NEGETIVE_DIFF_STYLE = 'color: #ff0000;';

import SIGNATURE_FILE_NAME from '@salesforce/label/c.CNG_PDF_Signature_File_Name';
import DEFAULT_REMARKS from '@salesforce/label/c.Metering_CNG_JT_Default_Remarks';

/* ===================== OFFLINE ADDITIONS (LDS + GraphQL wire) ===================== */
import { getRecord, updateRecord, createRecord } from 'lightning/uiRecordApi';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { graphql, gql } from 'lightning/uiGraphQLApi';

/* Objects/Fields for LDS */
import WO_OBJECT from '@salesforce/schema/WorkOrder';
import CV_OBJECT from '@salesforce/schema/ContentVersion';

import WO_ID from '@salesforce/schema/WorkOrder.Id';
import WO_STATUS from '@salesforce/schema/WorkOrder.Status';
import WO_APPT_STATUS from '@salesforce/schema/WorkOrder.Appointment_Status__c';
import WO_REMARKS from '@salesforce/schema/WorkOrder.Remarks__c';
import WO_CHECKOUT from '@salesforce/schema/WorkOrder.Check_Out__c';
import WO_CHECKOUT_DT from '@salesforce/schema/WorkOrder.Check_Out_Date_Time__c';
import WO_CHKOUT_LAT from '@salesforce/schema/WorkOrder.Check_Out_Location__c';
import WO_CHKOUT_LNG from '@salesforce/schema/WorkOrder.Check_Out_Location__c';
import WO_FROM from '@salesforce/schema/WorkOrder.From_Date__c';
import WO_TO from '@salesforce/schema/WorkOrder.To_Date__c';
import WO_ACCOUNT from '@salesforce/schema/WorkOrder.AccountId';
import WO_CNG_REMARK from '@salesforce/schema/WorkOrder.CNG_Remark__c';

/* GraphQL wires (no imperative calls) */
const DP_BY_WO = gql`
query dpByWO($woId: ID) {
  uiapi {
    query {
      Dispenser_Point__c(
        where: { WorkOrderID__c: { eq: $woId } }
        orderBy: { Dispenser_Number_Value__c: { order: ASC } }
      ) {
        edges {
          node {
            Id
            Name { value }
            Dispenser_Name__c { value }
            Opening_Reading__c { value }
            Closing_Reading__c { value }
            Difference_Of_Open_and_Close_Reading__c { value }
            Remark__c { value }
            Calibration_Qty__c { value }
            Calibration_Reason__c { value }
            Jumping_Qty__c { value }
            Jumping_Reason__c { value }
            Other_Qty__c { value }
            Other_Reason__c { value }
            Dispenser_Number_Value__c { value }
          }
        }
      }
      WorkStep(where: { ParentRecordId: { eq: $woId }, Name: { eq: "Start Metering" } }, first: 1) {
        edges { node { Id Status { value } } }
      }
      ServiceAppointment(where: { ParentRecordId: { eq: $woId } }, first: 1) {
        edges { node { Id Status { value } } }
      }
    }
  }
}`;

/* ================================== Component ================================== */
export default class StartVisit extends NavigationMixin(LightningElement) {
	@api workOrder;
	@api profileData;
	@api workOrderId;
	@api latitude;
	@api longitude;

	@track lstMarkers = [];
	@track isLoading = true;
	@track identificationOptions = [];
	wiredApexResult;
	imageCaptured = false;
	@track dispenserPoints = [];
	@track error;

	columns = SUMMARY_COLUMNS;
	@track dispenserPointsSummary = [];
	@track Total_Dispensing_Sale;

	@track images = {};
	acceptedFormats = ['image/jpeg', 'image/png', 'image/jpg'];

	openRemark = false;
	cngRemark = '';
	remarkRequired = false;
	calibReasonRequired = false;
	jumpReasonRequired = false;
	otherReasonRequired = false;

	@track isEditMode = false;
	@track isReplaceMode = false;
	@track isReplaceModeClick = true;
	@track selectedDispenser = {};
	@track showDeleteConfirmation = false;
	@track recordToDeleteId = null;
  _queuedTitles = new Set();


	@track photoUploadSlots = [];
	@track summary = {
		calibrationQty: 0,
		calibrationReason: new Set(),
		jumpingQty: 0,
		jumpingReason: new Set(),
		otherQty: 0,
		otherReason: new Set(),
		totalReadingB: 0,
		totalGasConsumption: 0
	};

	fromDate = '';
	toDate = '';

	get yesterdayDate() {
		const today = new Date();
		const year = today.getFullYear();
		const month = String(today.getMonth() + 1).padStart(2, '0');
		const day = String(today.getDate()).padStart(2, '0');
		return `${year}-${month}-${day}`;
	}

get inputVariables() {
    if (!this.workOrderId) return [];
    return [
        {
            name: 'workOrderId',
            type: 'String',
            value: this.workOrderId
        },
        {
            name: 'profileData',
            type: 'String',
            value: JSON.stringify(this.profileData || {})
        }
    ];
}


startFlow() {
        var url = 'com.salesforce.fieldservice://v1/sObject/'+this.workOrderId+'/quickaction/Capture_Photo';
        // window.open(url, '_self');
        this[NavigationMixin.Navigate]({
            "type": "standard__webPage",
            "attributes": {
                "url": url
            }
        });
    }


	/* ------------------- LDS metadata for picklist (offline friendly) ------------------- */
	@wire(getObjectInfo, { objectApiName: WO_OBJECT }) woInfo;

	@wire(getPicklistValues, {
		recordTypeId: '$woInfo.data.defaultRecordTypeId',
		fieldApiName: WO_CNG_REMARK
	})
	cngPicklist({ data, error }) {
		if (data) {
			this.identificationOptions = data.values.map(v => ({ label: v.label, value: v.value }));
		} else if (error && navigator.onLine) {
			// Online fallback to existing Apex
			getPicklistValuesApex()
				.then((result) => {
					if (result?.remarkTypes) {
						this.identificationOptions = result.remarkTypes.map(type => ({ label: type, value: type }));
					}
				})
				.catch(() => {});
		}
	}

	/* ------------------- LDS record (WO) for offline saves ------------------- */
	@wire(getRecord, { recordId: '$workOrderId', fields: [WO_ID, WO_STATUS, WO_APPT_STATUS, WO_ACCOUNT] })
	woRec;

	/* ------------------- GraphQL wires for offline read ------------------- */
	get gVars() { return { woId: this.workOrderId }; }

	@wire(graphql, { query: DP_BY_WO, variables: '$gVars' })
	dpWire({ data, errors }) {
		if (!data || navigator.onLine) return; // Use only while offline
		const edges = data?.uiapi?.query?.Dispenser_Point__c?.edges || [];
		const list = edges.map(e => mapGraphqlDP(e.node));
		this.hydratePoints(list);
		this.wsEdge = data?.uiapi?.query?.WorkStep?.edges?.[0] || null;
		this.saEdge = data?.uiapi?.query?.ServiceAppointment?.edges?.[0] || null;
	}

	/* =============================== Existing logic =============================== */
	handleEdit(event) {
		const recordId = event.currentTarget.dataset.id;
		const selected = this.dispenserPoints.find(item => item.Id === recordId);
		if (selected) {
			this.selectedDispenser = { ...selected };
			this.isEditMode = true;
			this.isReplaceMode = false;
		}
	}
	
	handleDelete(event) {
		const recordId = event.currentTarget.dataset.id;
		
		// Only allow deletion of the latest _New_ variant
		const recordToDelete = this.dispenserPoints.find(item => item.Id === recordId);
		
		if (!recordToDelete || !recordToDelete.showDelete) {
			this.showToast('Error', 'Can only delete the latest replacement dispenser point', 'error');
			return;
		}
		
		// Show confirmation modal
		this.recordToDeleteId = recordId;
		this.showDeleteConfirmation = true;
	}
	
	handleConfirmDelete() {
		this.showDeleteConfirmation = false;
		this.spinner = true;
		
		// Call Apex to delete and update previous record's Live__c
		deleteDispenserPoints({ recordId: this.recordToDeleteId })
			.then((result) => {
				console.log('Delete result:', result);
				// Remove from the list
				this.dispenserPoints = this.dispenserPoints.filter(dp => dp.Id !== this.recordToDeleteId);
				
				// Recalculate totals
				this.Total_Dispensing_Sale = this.dispenserPoints.reduce((sum, dp) => 
					sum + (dp.Difference_Of_Open_and_Close_Reading__c || 0), 0);
				
				this.disPensorSummary();
				
				// Refresh data to get updated Live__c value
				this.getDispensorRecordFunc();
				
				this.showToast('Success', 'Dispenser point deleted successfully', 'success');
				this.recordToDeleteId = null;
				this.spinner = false;
			})
			.catch(error => {
				this.showToast('Error', error.body?.message || 'Error deleting dispenser point', 'error');
				this.recordToDeleteId = null;
				this.spinner = false;
			});
	}
	
	handleCancelDelete() {
		this.showDeleteConfirmation = false;
		this.recordToDeleteId = null;
	}

	fetchPicklistData() {
		// Kept for online usage; offline handled by LDS wire above
		getPicklistValuesApex()
			.then((result) => {
				if (result?.remarkTypes) {
					this.identificationOptions = result.remarkTypes.map(type => ({ label: type, value: type }));
				}
			})
			.catch(() => {});
	}

	handleCngRemarkChange(event) {
		const value = event.target.value;
		this.cngRemark = value;
		this.openRemark = (value === 'Others');
	}

	handleRemarkChange(event) {
		this.remarks = event.detail.value;
	}

	handleSingleFieldChange(event) {
		const field = event.target.name;
		this.selectedDispenser[field] = event.target.value;

		if (field === 'Closing_Reading__c') {
			if (this.selectedDispenser.oldClosingReading != this.selectedDispenser.Closing_Reading__c) {
				this.remarkRequired = true;
				this.selectedDispenser.Remark__c = DEFAULT_REMARKS;
			} else {
				this.remarkRequired = false;
				this.selectedDispenser.Remark__c = '';
			}
			this.selectedDispenser.Closing_Reading__c = parseFloat(this.selectedDispenser.Closing_Reading__c);
		}

		if (field === 'Opening_Reading__c') {
			if (this.selectedDispenser.oldOpeningReading != this.selectedDispenser.Opening_Reading__c) {
				this.remarkRequired = true;
				this.selectedDispenser.Remark__c = DEFAULT_REMARKS;
			} else {
				this.remarkRequired = false;
				this.selectedDispenser.Remark__c = '';
			}
			this.selectedDispenser.Opening_Reading__c = parseFloat(this.selectedDispenser.Opening_Reading__c);
		}

		if (field === 'Calibration_Qty__c') this.selectedDispenser.Calibration_Qty__c = parseFloat(this.selectedDispenser.Calibration_Qty__c);
		if (field === 'Jumping_Qty__c') this.selectedDispenser.Jumping_Qty__c = parseFloat(this.selectedDispenser.Jumping_Qty__c);
		if (field === 'Other_Qty__c') this.selectedDispenser.Other_Qty__c = parseFloat(this.selectedDispenser.Other_Qty__c);

		this.selectedDispenser.Difference_Of_Open_and_Close_Reading__c =
			parseFloat(this.selectedDispenser.Closing_Reading__c || 0) -
			parseFloat(this.selectedDispenser.Opening_Reading__c || 0);

		Object.keys(this.selectedDispenser).forEach(key => {
			const value = this.selectedDispenser[key];
			if (typeof value === 'number' && !isNaN(value) && !Number.isInteger(value)) {
				this.selectedDispenser[key] = Math.floor(value);
			}
		});
	}

	uploadedFiles = '';
	handleUploadImageFinished(event) {
		this.uploadedFiles = event.detail.files[0];
		if (this.uploadedFiles) this.imageCaptured = true;
	}

	showOkModal = false;
	showAlertScreen = false;
	spinner = false;
	alertMessage='Are you sure you want to delete this record?';

	handleSaveAlert(event){
		this.spinner = true;
		var recordId = event.currentTarget.dataset.id;
	}

	handleCloseAlert(){
		this.showAlertScreen = false;
	}

	handleSave() {
		this.spinner = true;
		if (parseFloat(this.selectedDispenser.Closing_Reading__c) < parseFloat(this.selectedDispenser.Opening_Reading__c)) {
			this.showToast('Warning', 'Closing Reading should be equal or greater than Opening Reading', 'warning');
			this.spinner = false;
			return;
		}

		if (this.isReplaceMode) {
			// Replace is online only (Apex), as per existing flow
			if (!navigator.onLine) {
				this.showToast('Info', 'Replace requires online connection.', 'info');
				this.spinner = false;
				return;
			}
			const newDispenser = { ...this.selectedDispenser };
			delete newDispenser.Id;

			insertDispenserPoint({ dispenser: newDispenser, workOrderId: this.workOrderId })
				.then((result) => {
					this.showToast('Success', 'New dispenser record added.', 'success');
					this.handleRefresh();
					this.getDispensorRecordFunc();
					this.isEditMode = false;
					this.isReplaceMode = false;
					this.selectedDispenser = {};
					this.spinner = false;
				})
				.catch(error => {
					this.showToast('Error', error?.body?.message || 'Insert failed', 'error');
					this.isEditMode = false;
					this.isReplaceMode = false;
					this.spinner = false;
				})
		} else {
			if (this.remarkRequired && !this.selectedDispenser.Remark__c) {
				this.showToast('Warning', 'Please Enter Remarks', 'warning');
				this.spinner = false;
				return;
			}

			const updatedList = this.dispenserPoints.map(dp =>
				dp.Id === this.selectedDispenser.Id
					? { ...this.selectedDispenser, dispStyle: 'border: 1px solid lightgrey;background:lightgrey' }
					: dp
			);
			this.dispenserPoints = [...updatedList];
			this.dispenserPoints.forEach(dp => {
				dp.Difference_Of_Open_and_Close_Reading__c =
					parseFloat(dp.Closing_Reading__c || 0) - parseFloat(dp.Opening_Reading__c || 0);
				dp.diffStyle = dp.Difference_Of_Open_and_Close_Reading__c < 0 ? NEGETIVE_DIFF_STYLE : '';
			});
			this.Total_Dispensing_Sale = this.dispenserPoints.reduce((sum, dp) => sum + (dp.Difference_Of_Open_and_Close_Reading__c || 0), 0);
			this.disPensorSummary();
			this.remarkRequired = false;
			this.calibReasonRequired = false;
			this.jumpReasonRequired = false;
			this.otherReasonRequired = false;
			this.isEditMode = false;
			this.spinner = false;
		}
	}

	imageUrl = [];
	steps = [];

	async handleFile(event) {
		this.photoUploadSlots = event.detail.steps;

		for (let i = 0; i < this.photoUploadSlots.length; i++) {
			const slot = this.photoUploadSlots[i];
			if (!slot.added) continue;

			if (slot.base64Data && slot.compress) {
				try {
					const fullBase64 = slot.base64Data.startsWith('data:image')
						? slot.base64Data
						: `data:image/jpeg;base64,${slot.base64Data}`;

					const blob = await this.base64ToBlob(fullBase64);
					const imageUrl = URL.createObjectURL(blob);
					const compressedBlob = await this.compressImageFromURL(imageUrl);
					const compressedBase64 = await this.convertBlobToBase64(compressedBlob);
					slot.base64Data = compressedBase64;
				} catch (error) {
					if (!slot.base64Data || slot.base64Data.length < 100) {
						// leave as is; minimal noise
					}
				}
			}
		}
	}

	async base64ToBlob(base64Data) {
		const byteString = atob(base64Data.split(',')[1]);
		const mimeString = base64Data.split(',')[0].split(':')[1].split(';')[0];
		const ab = new ArrayBuffer(byteString.length);
		const ia = new Uint8Array(ab);
		for (let i = 0; i < byteString.length; i++) ia[i] = byteString.charCodeAt(i);
		return new Blob([ab], { type: mimeString });
	}

	@track photoUploadSlots = [];
	async compressImageFromURL(imageUrl) {
		return new Promise((resolve, reject) => {
			const img = new Image();
			img.onload = () => {
				try {
					const canvas = document.createElement('canvas');
					const ctx = canvas.getContext('2d');
					const maxWidth = 2400;
					const maxHeight = 2400;
					let width = img.width;
					let height = img.height;

					const ratio = Math.min(maxWidth / width, maxHeight / height);
					width *= ratio; height *= ratio;

					canvas.width = width; canvas.height = height;
					ctx.drawImage(img, 0, 0, width, height);

					try {
						canvas.toBlob(
							(blob) => blob ? resolve(blob) : reject(new Error('Canvas compression failed.')),
							'image/jpeg',
							0.91
						);
					} catch (err) { reject(new Error('Exception during canvas.toBlob: ' + err.message)); }
				} catch (error) { reject(new Error('Error during image compression: ' + error.message)); }
			};
			img.onerror = () => reject(new Error('Error loading image.'));
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

	handleImageChange(event) {
		this.imageUrl = event.detail;
	}

	handleSaveClick() {
		if (!this.photoUploadSlots?.length || this.photoUploadSlots[0].base64Data == '') {
			this.showToast('Warning', 'Please Upload Your Image', 'warning');
			return;
		}
		this.handleRedirect(this.workOrderId);
	}

	handleRedirect(recordId) {
		this.navigateToRecord(recordId);
	}

	navigateToRecord(recordId) {
		if (FORM_FACTOR == 'Large') {
			this[NavigationMixin.Navigate]({ type: 'standard__recordPage', attributes: { recordId, actionName: 'view' } });
		} else {
			const valueSelectedEvent = new CustomEvent("close", {});
			this.dispatchEvent(valueSelectedEvent);
		}
	}

	cancelEdit() {
		this.isEditMode = false;
		this.isReplaceMode = false;
		this.isReplaceModeClick = true;
		this.selectedDispenser = {};
	}

	// unchanged cols already set above

	// Upload via Apex (online) or queue CV (offline)
	handleSignatureUpload(event) {
		this.photoUploadSlots = event.detail.steps;
		const imagesList = this.photoUploadSlots.map(i => ({
			base64Data: i.base64Data, fileName: i.fileName, label: i.label, ocr: i.ocr
		}));
		if (!imagesList.length) return;

		if (navigator.onLine) {
			this.isLoading = true;
			uploadImage({ fileName: imagesList[0].fileName, base64Data: imagesList[0].base64Data, recordId: this.workOrderId })
				.then((result) => {
					this.images = { fileName: imagesList[0].fileName, previewUrl: result };
					this.showToast('Success', `${imagesList[0].fileName} uploaded`, 'success');
				})
				.catch(() => this.showToast('Error', `Failed to upload ${imagesList[0].fileName}`, 'error'))
				.finally(() => { this.isLoading = false; });
			return;
		}

		// OFFLINE: queue CV
		//this.queueContentVersion(imagesList[0].fileName || SIGNATURE_FILE_NAME, imagesList[0].base64Data, this.workOrderId)
    this.queueContentVersion('RO Stamp & Signature.png', imagesList[0].base64Data, this.workOrderId)
			.then(() => {
				this.images = { fileName: imagesList[0].fileName, previewUrl: '' };
				this.showToast('Success', `RO Stamp & Signature is queued`, 'success');
			})
			.catch(() => this.showToast('Error', `Failed to queue ${imagesList[0].fileName}`, 'error'));
	}

	handleSelfieUpload(event) {
		this.isLoading = true;
		this.photoUploadSlots = event.detail.steps;
		const imagesList = this.photoUploadSlots.map(i => ({
			base64Data: i.base64Data, fileName: i.fileName, label: i.label, ocr: i.ocr
		}));
		if (!imagesList.length) { this.isLoading = false; return; }

		if (navigator.onLine) {
			uploadSelfie({ fileName: imagesList[0].fileName, base64Data: imagesList[0].base64Data, recordId: this.workOrderId })
				.then((result) => {
					this.images = { fileName: imagesList[0].fileName, previewUrl: result };
					this.showToast('Success', `${imagesList[0].fileName} uploaded`, 'success');
				})
				.catch(() => this.showToast('Error', `Failed to upload ${imagesList[0].fileName}`, 'error'))
				.finally(() => { this.isLoading = false; });
			return;
		}

		this.queueContentVersion('SelfieImage.png', imagesList[0].base64Data, this.workOrderId)
			.then(() => {
				this.images = { fileName: imagesList[0].fileName, previewUrl: '' };
				this.showToast('Success', `SelfieImage is queued`, 'success');
			})
			.catch(() => this.showToast('Error', `Failed to queue ${imagesList[0].fileName}`, 'error'))
			.finally(() => { this.isLoading = false; });
	}

	removeImage() { /* no-op for single image preview */ }

	normalizeDate(dateStr) {
		if (!dateStr) return null;
		const [year, month, day] = dateStr.split('-').map(Number);
		return new Date(year, month - 1, day);
	}

	handleEndVisit() {
		if (this.fromDate == '' || this.toDate == '') {
			this.showToast('Validation Error', 'Please enter From and To Date', 'error');
			return;
		}
		const today = new Date(); today.setHours(0, 0, 0, 0);
		const from = this.normalizeDate(this.fromDate);
		const to = this.normalizeDate(this.toDate);
		if (from > today || to > today) {
			this.showToast('Validation Error', 'Dates cannot be in the future.', 'error');
			return;
		}
		if (new Date(this.toDate) < new Date(this.fromDate)) {
			this.showToast('Validation Error', 'To Date must be greater than or equal to From Date.', 'error');
			return;
		}
		const hasInvalid = this.dispenserPoints.some(dp => dp.Closing_Reading__c < dp.Opening_Reading__c);
		if (hasInvalid) {
			this.showToast('Validation Error', 'Closing Reading should be equal or greater than opening reading', 'error');
			return;
		}
		if (!this.photoUploadSlots?.length || this.photoUploadSlots[0].base64Data == '') {
			this.showToast('Validation Error', `Please upload ${SIGNATURE_FILE_NAME}`, 'error');
			return;
		}
		this.handleGetLocation();
	}

	handleGetLocation() {
		this.isLoading = true;
		if (FORM_FACTOR === 'Large') this.getBrowserLocation();
		else this.getMobileLocation();
	}

	getBrowserLocation() {
		if (navigator.geolocation) {
			navigator.geolocation.getCurrentPosition(
				(position) => {
					this.latitude_End_Visit = position.coords.latitude;
					this.longitude_End_Visit = position.coords.longitude;
					this.handleCheckOut();
				},
				() => {
					this.isLoading = false;
					this.showToast('Warning', 'Please enable your device location', 'warning');
				}
			);
		} else {
			this.showToast('Warning', 'Geolocation is not supported by this browser', 'warning');
			this.isLoading = false;
		}
	}

	getMobileLocation() {
		const locationService = getLocationService();
		if (!locationService || !locationService.isAvailable()) {
			this.showToast('Error', 'Please use a GPS-enabled mobile device and ensure location is turned on.', 'error');
			this.isLoading = false;
			return;
		}
		locationService.getCurrentPosition({ enableHighAccuracy: true })
			.then(result => {
				this.latitude_End_Visit = result.coords.latitude;
				this.longitude_End_Visit = result.coords.longitude;
				this.handleCheckOut();
			})
			.catch(() => {
				this.showToast('Warning', 'Please enable your device location.', 'warning');
				this.isLoading = false;
			});
	}

	handleDateChange(event) {
		const field = event.target.name;
		const value = event.target.value;
		if (field === 'fromDate') this.fromDate = value;
		else if (field === 'toDate') this.toDate = value;

		if (this.toDate && this.fromDate && new Date(this.toDate) < new Date(this.fromDate)) {
			this.showToast('Validation Error', 'To Date must be greater than or equal to From Date.', 'error');
		}
	}

	async handleCheckOut() {
		try {
			if (navigator.onLine) {
				// ONLINE: unchanged Apex save
				await saveVisitDetails({
					updates: this.dispenserPoints,
					workOrderId: this.workOrderId,
					latitude: this.latitude_End_Visit,
					longitude: this.longitude_End_Visit,
					remarks: this.remarks,
					fromDate: this.fromDate,
					toDate: this.toDate
				});
			} else {
				// OFFLINE: mirror Apex with LDS updates

				// 1) Update each Dispenser Point locally
				for (const dp of this.dispenserPoints) {
					await updateRecord({
						fields: {
							Id: dp.Id,
							Opening_Reading__c: dp.Opening_Reading__c,
							Closing_Reading__c: dp.Closing_Reading__c,
							//Difference_Of_Open_and_Close_Reading__c: dp.Difference_Of_Open_and_Close_Reading__c,
							Remark__c: dp.Remark__c,
							Calibration_Qty__c: dp.Calibration_Qty__c,
							Calibration_Reason__c: dp.Calibration_Reason__c,
							Jumping_Qty__c: dp.Jumping_Qty__c,
							Jumping_Reason__c: dp.Jumping_Reason__c,
							Other_Qty__c: dp.Other_Qty__c,
							Other_Reason__c: dp.Other_Reason__c
						}
					});
				}

				// 2) Update WorkOrder (remarks, dates, checkout + location)
				await updateRecord({
					fields: {
						Id: this.workOrderId,
						Remarks__c: this.remarks,
						From_Date__c: this.fromDate || null,
						To_Date__c: this.toDate || null,
						Check_Out__c: true,
						Check_Out_Date_Time__c: new Date().toISOString(),
						Check_Out_Location__Latitude__s: this.latitude_End_Visit,
						Check_Out_Location__Longitude__s: this.longitude_End_Visit
					}
				});

				// 3) Complete WorkStep 'Start Metering' if wired ID exists
				const wsId = this.wsEdge?.node?.Id;
				if (wsId) {
					await updateRecord({ fields: { Id: wsId, Status: 'Completed' } });
				}

				// 4) Queue signature CV (already validated)
				const sig = this.photoUploadSlots?.[0];
        if (sig?.base64Data) {
            await this.queueContentVersion('RO Stamp & Signature.png', sig.base64Data, this.workOrderId);
        }


			}

			this.photoUploadSlots = [{
				label: 'Take Selfie',
				previewUrl: '',
				fileName: '',
				base64Data: '',
				uploaded: false,
				index: null,
				compress: false,
				ocr: false
			}];

			this.showToast('Success', 'Visit saved successfully.', 'success');
			this.showOkModal = true;
		} catch (error) {
			this.showToast('Error', error?.body?.message || error?.message || 'Update failed', 'error');
		} finally {
			this.isLoading = false;
		}
	}

	handleRefresh() {
		if (this.wiredApexResult) refreshApex(this.wiredApexResult);
	}

	@track selectedDispenser = {};
	handleReplaceInEdit() {
		this.isReplaceMode = true;
		this.isReplaceModeClick = false;
		const copy = { ...this.selectedDispenser };
		delete copy.Id;
		this.selectedDispenser = {
			...copy,
			Closing_Reading__c: 0,
			Opening_Reading__c: 0,
			Difference_Of_Open_and_Close_Reading__c: 0,
			Remark__c: '',
			Calibration_Qty__c: 0,
			Calibration_Reason__c: '',
			Jumping_Qty__c: 0,
			Jumping_Reason__c: '',
			Other_Qty__c: 0,
			Other_Reason__c: '',
			dispStyle: 'border: 1px solid lightgrey;background:lightgrey',
			displayTitle: this.getNextPoint(this.selectedDispenser.Dispenser_Name__c)
		};
	}

	getNextPoint(input) {
		const newPattern = /(.*)_New_(\d+)$/;
		const match = input?.match?.(newPattern);
		if (match) {
			const base = match[1];
			const number = parseInt(match[2], 10);
			return `${base}_New_${number + 1}`;
		}
		return `${input}_New_1`;
	}

	disPensorSummary() {
		this.summary.calibrationQty = 0;
		this.summary.calibrationReason = new Set();
		this.summary.jumpingQty = 0;
		this.summary.jumpingReason = new Set();
		this.summary.otherQty = 0;
		this.summary.otherReason = new Set();

		if (!this.dispenserPoints) return;

		this.dispenserPoints.forEach(dp => {
			this.summary.calibrationQty += parseFloat(dp.Calibration_Qty__c) || 0;
			if (dp.Calibration_Reason__c) this.summary.calibrationReason.add(dp.Calibration_Reason__c.trim());

			this.summary.jumpingQty += parseFloat(dp.Jumping_Qty__c) || 0;
			if (dp.Jumping_Reason__c) this.summary.jumpingReason.add(dp.Jumping_Reason__c.trim());

			this.summary.otherQty += parseFloat(dp.Other_Qty__c) || 0;
			if (dp.Other_Reason__c) this.summary.otherReason.add(dp.Other_Reason__c.trim());
		});

		this.summary.totalReadingB = this.summary.calibrationQty + this.summary.jumpingQty + this.summary.otherQty;
		this.summary.totalGasConsumption = (this.Total_Dispensing_Sale || 0) - this.summary.totalReadingB;

		this.summary.calibrationReason = [...this.summary.calibrationReason].join(', ');
		this.summary.jumpingReason = [...this.summary.jumpingReason].join(', ');
		this.summary.otherReason = [...this.summary.otherReason].join(', ');
	}

	getDispensorRecordFunc() {
		if (navigator.onLine) {
			getDispenserPoints({ workOrderId: this.workOrderId })
				.then(result => {
					this.isLoading = true;
					this.wiredApexResult = result;

					const updatedPoints = result.map(dp => {
						const existing = this.dispenserPoints?.find(p => p.Id === dp.Id);
						return existing ? {
							...dp,
							Closing_Reading__c: existing.Closing_Reading__c,
							oldClosingReading: existing.oldClosingReading,
							Remark__c: existing.Remark__c,
							Calibration_Qty__c: existing.Calibration_Qty__c,
							Calibration_Reason__c: existing.Calibration_Reason__c,
							Jumping_Qty__c: existing.Jumping_Qty__c,
							Jumping_Reason__c: existing.Jumping_Reason__c,
							Opening_Reading__c: existing.Opening_Reading__c,
							oldOpeningReading: existing.oldOpeningReading,
							Other_Qty__c: existing.Other_Qty__c,
							Other_Reason__c: existing.Other_Reason__c,
							dispStyle: existing.dispStyle || 'border: 1px solid lightgrey;'
						} : {
							...dp,
							Closing_Reading__c: dp.Closing_Reading__c || 0,
							oldClosingReading: dp.Closing_Reading__c || 0,
							Remark__c: dp.Remark__c || '',
							Calibration_Qty__c: dp.Calibration_Qty__c || 0,
							Calibration_Reason__c: dp.Calibration_Reason__c || '',
							Jumping_Qty__c: dp.Jumping_Qty__c || 0,
							Jumping_Reason__c: dp.Jumping_Reason__c || '',
							Opening_Reading__c: dp.Opening_Reading__c || 0,
							oldOpeningReading: dp.Opening_Reading__c || 0,
							Other_Qty__c: dp.Other_Qty__c || 0,
							Other_Reason__c: dp.Other_Reason__c || '',
							dispStyle: 'border: 1px solid lightgrey;'
						};
					});

					this.hydratePoints(updatedPoints);
					this.isLoading = false;
				});
		}
		// Offline: dpWire will populate via GraphQL automatically
	}

	remarks = '';
	connectedCallback() {
		this.handleRefresh();
		this.getDispensorRecordFunc();
		this.fetchPicklistData();
		this.lstMarkers = [{
			location: { Latitude: this.latitude, Longitude: this.longitude },
			title: 'Current Location'
		}];
		this.photoUploadSlots.push({
			previewUrl: '',
			fileName: '',
			label: SIGNATURE_FILE_NAME,
			base64Data: '',
			uploaded: false,
			index: null,
			compress: false,
			ocr: false
		});
		this.zoomlevel = '15';
		this.isLoading = false;
	}

	showToast(title, message, variant) {
		this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
	}

	/* ---------------- helpers ---------------- */
	hydratePoints(list) {
		const merged = list.map(dp => {
			const existing = this.dispenserPoints?.find(p => p.Id === dp.Id);
			const base = existing ? { ...existing, ...dp } : dp;
			return {
				...base,
				oldClosingReading: base.Closing_Reading__c || 0,
				oldOpeningReading: base.Opening_Reading__c || 0,
				Remark__c: base.Remark__c || '',
				Calibration_Qty__c: base.Calibration_Qty__c || 0,
				Calibration_Reason__c: base.Calibration_Reason__c || '',
				Jumping_Qty__c: base.Jumping_Qty__c || 0,
				Jumping_Reason__c: base.Jumping_Reason__c || '',
				Opening_Reading__c: base.Opening_Reading__c || 0,
				Other_Qty__c: base.Other_Qty__c || 0,
				Other_Reason__c: base.Other_Reason__c || '',
				dispStyle: base.dispStyle || 'border: 1px solid lightgrey;',
				showDelete: false // Will be calculated below
			};
		});

		// Calculate showDelete: only show for the latest _New_ variant of each base point
		const pointGroups = {};
		merged.forEach(dp => {
			if (!dp.Dispenser_Name__c) return;
			
			// Parse name: Point_1_New_2 -> baseName: Point_1, newNumber: 2
			const match = dp.Dispenser_Name__c.match(/^(.+)_New_(\d+)$/);
			if (match) {
				const baseName = match[1];
				const newNumber = parseInt(match[2], 10);
				
				if (!pointGroups[baseName]) {
					pointGroups[baseName] = [];
				}
				pointGroups[baseName].push({ id: dp.Id, newNumber });
			}
		});

		// Find the highest _New_ number for each base and mark it for delete
		Object.keys(pointGroups).forEach(baseName => {
			const group = pointGroups[baseName];
			const maxNewNumber = Math.max(...group.map(g => g.newNumber));
			const latestId = group.find(g => g.newNumber === maxNewNumber)?.id;
			
			if (latestId) {
				const record = merged.find(dp => dp.Id === latestId);
				if (record) {
					record.showDelete = true;
				}
			}
		});

		this.dispenserPoints = merged;
		this.dispenserPoints.forEach(dp => {
			dp.Difference_Of_Open_and_Close_Reading__c =
				parseFloat(dp.Closing_Reading__c || 0) - parseFloat(dp.Opening_Reading__c || 0);
			dp.diffStyle = dp.Difference_Of_Open_and_Close_Reading__c < 0 ? NEGETIVE_DIFF_STYLE : '';
		});
		this.dispenserPointsSummary = merged.map(dp => ({ ...dp }));
		this.Total_Dispensing_Sale =
			merged.reduce((sum, dp) => sum + (dp.Difference_Of_Open_and_Close_Reading__c || 0), 0);
		this.disPensorSummary();
	}

	async queueContentVersion(fileName, base64Data, publishLocationId) {
    // Ensure same behavior as Apex titles
    const title = fileName.replace(/\.[^.]+$/, '');
    if (this._queuedTitles.has(title)) {
        console.log(`Skipped duplicate ContentVersion for title: ${title}`);
        return;
    }
    this._queuedTitles.add(title);

    // Strip any data URL prefix if present
    const cleanBase64 = base64Data.includes(',') ? base64Data.split(',')[1] : base64Data;

    await createRecord({
        apiName: CV_OBJECT.objectApiName,
        fields: {
            Title: title,
            PathOnClient: fileName,
            VersionData: cleanBase64,
            FirstPublishLocationId: publishLocationId
        }
    });
    console.log(`Queued ContentVersion offline for ${title}`);
}


}

/* ===== small util mapper ===== */
function mapGraphqlDP(n) {
	const num = (v) => { const x = Number(v); return isNaN(x) ? 0 : x; };
	return {
		Id: n.Id,
		Name: n.Name,
		Dispenser_Name__c: n.Dispenser_Name__c?.value,
		Opening_Reading__c: num(n.Opening_Reading__c?.value),
		Closing_Reading__c: num(n.Closing_Reading__c?.value),
		Difference_Of_Open_and_Close_Reading__c: num(n.Difference_Of_Open_and_Close_Reading__c?.value),
		Remark__c: n.Remark__c?.value,
		Calibration_Qty__c: num(n.Calibration_Qty__c?.value),
		Calibration_Reason__c: n.Calibration_Reason__c?.value,
		Jumping_Qty__c: num(n.Jumping_Qty__c?.value),
		Jumping_Reason__c: n.Jumping_Reason__c?.value,
		Other_Qty__c: num(n.Other_Qty__c?.value),
		Other_Reason__c: n.Other_Reason__c?.value,
		Dispenser_Number_Value__c: num(n.Dispenser_Number_Value__c?.value),
		dispStyle: 'border: 1px solid lightgrey;'
	};
}