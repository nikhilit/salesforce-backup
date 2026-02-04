/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 20-01-2026
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   08-08-2025   Kartik Patkar, Appstrail   Initial Version
 * 1.1   03-11-2025   Appstrail                  Offline parity (GraphQL + LDS) w/o affecting online
**/
import { LightningElement, api, track, wire } from 'lwc';
import { getLocationService } from 'lightning/mobileCapabilities';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getWorkOrder from '@salesforce/apex/WorkOrderVisitController.getWorkOrder';
import getDispenserPoints from '@salesforce/apex/WorkOrderVisitController.getDispenserPoints';
import saveVisitDetails from '@salesforce/apex/WorkOrderVisitController.updateLiveDetails';
import uploadImage from '@salesforce/apex/WorkOrderVisitController.uploadImage';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import CNG_LIVE_READING_TO_6AM_ALERT from '@salesforce/label/c.CNG_Live_Reading_alert_message';
import START_METERING_NOT_COMPLETED from '@salesforce/label/c.CNG_Alert_Message_Not_Done_Start_Metering';

/* =============== OFFLINE ADDITIONS (LDS + GraphQL; no change to online) =============== */
import { getRecord, updateRecord, createRecord } from 'lightning/uiRecordApi';
import { graphql, gql } from 'lightning/uiGraphQLApi';

import WO_OBJECT from '@salesforce/schema/WorkOrder';
import CV_OBJECT from '@salesforce/schema/ContentVersion';


import WO_ID from '@salesforce/schema/WorkOrder.Id';
import WO_REMARKS from '@salesforce/schema/WorkOrder.Remarks__c';
import WO_STATUS from '@salesforce/schema/WorkOrder.Status';
import WO_APPT_STATUS from '@salesforce/schema/WorkOrder.Appointment_Status__c';
import WO_LIVE_DT from '@salesforce/schema/WorkOrder.Live_Reading_Date_Time__c';
// import WO_LIVE_LAT from '@salesforce/schema/WorkOrder.Live_Reading_Location__c';
// import WO_LIVE_LNG from '@salesforce/schema/WorkOrder.Live_Reading_Location__c';




// Dispenser Point fields used in LDS updates (Id is implied)
import DP_ID from '@salesforce/schema/Dispenser_Point__c.Id';
import DP_LIVE from '@salesforce/schema/Dispenser_Point__c.Live_Reading__c';
import DP_CLOSE from '@salesforce/schema/Dispenser_Point__c.Closing_Reading__c';
import DP_REMARK from '@salesforce/schema/Dispenser_Point__c.Progressive_Remark__c';
import DP_CAL_QTY from '@salesforce/schema/Dispenser_Point__c.Calibration_Qty__c';
import DP_JUMP_QTY from '@salesforce/schema/Dispenser_Point__c.Jumping_Qty__c';
import DP_OTHER_QTY from '@salesforce/schema/Dispenser_Point__c.Other_Qty__c';
import DP_CAL_REASON from '@salesforce/schema/Dispenser_Point__c.Calibration_Reason__c';
import DP_JUMP_REASON from '@salesforce/schema/Dispenser_Point__c.Jumping_Reason__c';
import DP_OTHER_REASON from '@salesforce/schema/Dispenser_Point__c.Other_Reason__c';
import DP_LIVE_FLAG from '@salesforce/schema/Dispenser_Point__c.Live__c';

/* GraphQL (uiapi) for offline READ. Keep it wide but safe. */
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
            Live_Reading__c { value }
            Progressive_Remark__c { value }
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
      WorkStep(
        where: { ParentRecordId: { eq: $woId }, Name: { eq: "Live Reading" } }
        first: 1
      ) { edges { node { Id Status { value } } } }
      ServiceAppointment(where: { ParentRecordId: { eq: $woId } }, first: 1) {
        edges { node { Id Status { value } } }
      }
    }
  }
}`;
const SUMMARY_COLUMNS = [
	{ label: 'Dispenser Point', fieldName: 'Name' },
	{ label: 'Opening Reading', fieldName: 'Opening_Reading__c', type: 'number' },
	{ label: 'Closing Reading', fieldName: 'Closing_Reading__c', type: 'number' }
];

const WO_LIVE_LAT = { fieldApiName: 'Live_Reading_Location__Latitude__s', objectApiName: 'WorkOrder' };
const WO_LIVE_LNG = { fieldApiName: 'Live_Reading_Location__Longitude__s', objectApiName: 'WorkOrder' };

export default class DispensorPointLiveDataComponent extends NavigationMixin(LightningElement) {
	_recordId;
	geoFenceConfig;
    geoFence = false;
    geoDistance;
    actualCoords;
	account;

	@api
	get recordId() {
		return this._recordId;
	}
	set recordId(value) {
		this._recordId = value;
		// You can add any logic here to run when recordId is set
		console.log('RecordId set:', value);
		if (navigator.onLine) {
			getWorkOrder({ recordId: this._recordId })
			.then(result => {
				this.workOrder = result;
				if (!result.jointVisitDone) {
					this.alertJointVisit = true;
				}
				console.log('WorkOrder (online):', JSON.stringify(this.workOrder));
				this.getDispenserRecordFunc();
			})
			.catch(error => {
				this.error = error;
				console.error('Error fetching WorkOrder (online):', error);
				this.showToast('Error', 'Failed to load Work Order', 'error');
			});
		} else {
			this.showToast('Info', 'Offline: loading cached Dispenser Points.', 'info');
			this.getDispenserRecordFunc();
		}
	}

	alertJointVisit = false;
	alertJointVisitMessage = START_METERING_NOT_COMPLETED;

	handleGoBack() {
		this.dispatchEvent(new CloseActionScreenEvent());
	}

	@track lstMarkers = [];
	@track isLoading = false;
	wiredApexResult;

	@track dispenserPoints = [];
	@track error;

	columnsWithAction = [
		{ label: 'Name', fieldName: 'Name' },
		{ label: 'Closing Reading', fieldName: 'Closing_Reading__c', type: 'number' },
		{ label: 'Calibration Qty', fieldName: 'Calibration_Qty__c', type: 'number' },
		{
			type: 'action',
			typeAttributes: {
				rowActions: [
					{
						label: 'Edit',
						iconName: 'utility:edit',
						name: 'edit',
						title: 'Edit'
					}
				],
				menuAlignment: 'auto'
			}
		}
	];

	/* -------------------- OFFLINE WIRES (READ ONLY) -------------------- */
	get gVars() { return { woId: this._recordId }; }
	wsEdge; saEdge;

	@wire(graphql, { query: DP_BY_WO, variables: '$gVars' })
	dpWire({ data, errors }) {
		// Only use GraphQL data while offline, so we don't interfere with online Apex path.
		if (navigator.onLine) return;

		this.isLoading = false;

		if (errors && errors.length) {
			console.error('GraphQL errors:', JSON.stringify(errors));
			this.showToast('Warning', 'Offline cache not available for Dispenser Points.', 'warning');
			return;
		}
		const edges = data?.uiapi?.query?.Dispenser_Point__c?.edges || [];
		if (!edges.length) {
			this.showToast('Info', 'No cached Dispenser Points found for offline mode.', 'info');
		}
		const list = edges.map(e => mapGraphqlDP(e.node));
		this.hydrateOfflinePoints(list);

		this.wsEdge = data?.uiapi?.query?.WorkStep?.edges?.[0] || null;
		this.saEdge = data?.uiapi?.query?.ServiceAppointment?.edges?.[0] || null;
	}
	@wire(getRecord, {
		recordId: '$recordId',
		fields: [WO_NAME, WO_LIVE_LAT_FIELD, WO_LIVE_LNG_FIELD]
	})
	wiredWorkOrder({ data, error }) {
		if (data) {
			const fields = data.fields;
			const lat = fields?.Live_Reading_Location__Latitude__s?.value;
			const lng = fields?.Live_Reading_Location__Longitude__s?.value;

			console.log('Retrieved Latitude:', lat);
			console.log('Retrieved Longitude:', lng);

			// You can optionally assign these for reuse in updateRecord
			this.latitude_End_Visit = lat;
			this.longitude_End_Visit = lng;
		} else if (error) {
			console.error('Error retrieving WorkOrder geolocation:', error);
		}
	}

	// Handle button click in datatable
	handleEdit(event) {
		const recordId = event.currentTarget.dataset.id;

		// Find the clicked dispenser record from the array
		const selected = this.dispenserPoints.find(item => item.Id === recordId);

		if (selected) {
			this.selectedDispenser = { ...selected }; // clone to avoid mutation
			this.isEditMode = true;
			this.progressRequired = true; // Reset progressRequired when entering edit mode
			console.log('Edit Mode ON for:', this.selectedDispenser);
			const liveReading = parseFloat(this.selectedDispenser.Live_Reading__c);
			const closingReading = parseFloat(this.selectedDispenser.Closing_Reading__c);
			this.selectedDispenser.Difference = 0;
			this.selectedDispenser.Is_Progressive__c = 'Yes';
			if (!isNaN(liveReading) && !isNaN(closingReading)) {
				this.selectedDispenser.Difference = liveReading - closingReading;
				this.selectedDispenser.Is_Progressive__c = liveReading < closingReading ? 'No' : 'Yes';
				if (this.selectedDispenser.Is_Progressive__c == 'No') {
					this.selectedDispenser.Progressive_Remark__c = this.selectedDispenser.labelNew + ' is not Progressive.';
					this.progressRequired = true;
				} else {
					this.selectedDispenser.Progressive_Remark__c = '';
					this.progressRequired = false;
				}
			}
		}
	}

	// Single field edit handler
	get isProgressiveYes() {
		return this.selectedDispenser.Is_Progressive__c === 'Yes';
	}

	get isProgressiveNo() {
		return this.selectedDispenser.Is_Progressive__c === 'No';
	}
	progressRequired = false;
	handleSingleFieldChange(event) {
		const field = event.target.name;
		const value = event.target.value;

		this.selectedDispenser[field] = value;
		console.log('this.selectedDispenser:::' + JSON.stringify(this.selectedDispenser));
		if (field === 'Live_Reading__c') {
			const liveReading = parseFloat(value);
			const closingReading = parseFloat(this.selectedDispenser.Closing_Reading__c);

			if (!isNaN(liveReading) && !isNaN(closingReading)) {
				this.selectedDispenser.Is_Progressive__c = liveReading < closingReading ? 'No' : 'Yes';
				if (this.selectedDispenser.Is_Progressive__c == 'No') {
					this.selectedDispenser.Progressive_Remark__c = this.selectedDispenser.labelNew + ' is not Progressive.';
					this.progressRequired = true;
				} else {
					this.selectedDispenser.Progressive_Remark__c = '';
					this.progressRequired = false;
				}
			}
		}
		this.selectedDispenser.Difference = this.selectedDispenser.Live_Reading__c - this.selectedDispenser.Closing_Reading__c;

		Object.keys(this.selectedDispenser).forEach(key => {
			const value = this.selectedDispenser[key];

			// Check if the value is a number
			if (typeof value === 'number' && !isNaN(value)) {
				// Floor only if it has a decimal
				if (!Number.isInteger(value)) {
					this.selectedDispenser[key] = Math.floor(value);
				}
			}
		});
	}

	// Save changes back to list
	showProgressiveAlertScreen = false;
	showAlertScreen = false;
	alertMessage = '';

	handleCheckProgressiveAlert() {
		if (this.progressRequired && this.selectedDispenser.Progressive_Remark__c == '') {
			this.showToast('Warning', 'Please Enter Remarks', 'warning');
			return;
		}
		if (parseFloat(this.selectedDispenser.Difference) < 0) {
			this.showProgressiveAlertScreen = true;
			this.alertMessage = CNG_LIVE_READING_TO_6AM_ALERT;
			return;
		}
		this.handleSave();
	}

	handleSave() {
		this.showProgressiveAlertScreen = false;
		console.log('selectedDispenser:::' + JSON.stringify(this.selectedDispenser));
		if (!this.showAlertScreen && this.validateReading(this.selectedDispenser.Difference, this.selectedDispenser.averageConsumption)) {
			this.alertMessage = 'Difference is high between 06 AM reading & live meter reading. Confirm and proceed?';
			this.showAlertScreen = true;
			return;
		}
		this.showAlertScreen = false;

		const updatedList = this.dispenserPoints.map(dp =>
			dp.Id === this.selectedDispenser.Id ? {
				...this.selectedDispenser,
				dispStyle: 'border: 1px solid lightgrey;background:lightgrey'
			} : dp
		);
		this.dispenserPoints = [...updatedList];
		this.Total_Dispensing_Sale = this.dispenserPoints.reduce((sum, dp) => sum + (dp.Difference || 0), 0);
		this.isEditMode = false;
	}

	handleCloseAlert() {
		this.showAlertScreen = false;
		this.showProgressiveAlertScreen = false;
	}

	validateReading(diff, avgConsumption) {
		if (!avgConsumption || avgConsumption <= 0) {
			avgConsumption = 0; // no validation if avg is 0 or missing
		}
		// allowed max = 125% of average
		const minAllowed = avgConsumption * 0.25;
		console.log('diff::' + diff + '::avgConsumption::' + avgConsumption + '::minAllowed::' + minAllowed);
		if (Number(diff) > minAllowed) {
			return true; // invalid
		}
		return false;
	}

	// Cancel edit
	cancelEdit() {
		this.isEditMode = false;
	}
	columns = SUMMARY_COLUMNS;
	@track dispenserPointsSummary = [];
	@track Total_Dispensing_Sale;

	@track images = [];
	acceptedFormats = ['image/jpeg', 'image/png', 'image/jpg'];

	handleInputChange(event) {
		const { dataset, name, value } = event.target;
		const index = dataset.index;
		this.dispenserPoints[index][name] = value;
	}

	handleRemarkChange(event) {
		this.remarks = event.detail.value;
	}

	/* ================== Image Upload (online unchanged, offline queues CV) ================== */
	// For this component we are using a plain input[type=file] pattern.
	// If offline, we queue a ContentVersion instead of calling Apex.
	_queuedTitles = new Set();
	async handleImageUpload(event) {
		const files = event.target.files;
		if (files.length === 0 || !this.recordId) return;

		for (const file of Array.from(files)) {
			const reader = new FileReader();
			reader.onload = async () => {
				const base64Url = reader.result; // data:*/*;base64,xxxx
				const base64 = base64Url.split(',')[1];

				if (navigator.onLine) {
					uploadImage({ fileName: file.name, base64Data: base64, recordId: this.recordId })
						.then(() => {
							const newImage = { fileName: file.name, previewUrl: reader.result };
							this.images = [...this.images, newImage];
							this.showToast('Success', `${file.name} uploaded`, 'success');
						})
						.catch(error => {
							console.error('Upload failed:', error);
							this.showToast('Error', `Failed to upload ${file.name}`, 'error');
						});
				} else {
					try {
						await this.queueContentVersion(file.name, base64, this.recordId);
						const newImage = { fileName: file.name, previewUrl: reader.result };
						this.images = [...this.images, newImage];
						this.showToast('Success', `${file.name} queued (offline)`, 'success');
					} catch (e) {
						console.error('Queue CV failed:', e);
						this.showToast('Error', `Failed to queue ${file.name}`, 'error');
					}
				}
			};
			reader.readAsDataURL(file);
		}
	}

	removeImage(event) {
		const index = Number(event.target.dataset.index);
		this.images = this.images.filter((_, i) => i !== index);
	}

	handleEndVisit() {
		console.log("End visit::" + JSON.stringify(this.dispenserPoints));
		// NOTE: Your original validation is commented out; we keep it exactly as-is.
		this.handleGetLocation();
	}

	handleGetLocation() {
		this.isLoading = true;
		if (FORM_FACTOR === 'Large') {
			this.getBrowserLocation();
		} else {
			this.getMobileLocation();
		}
	}

	getBrowserLocation() {
		console.log("browser location");
		if (navigator.geolocation) {
			navigator.geolocation.getCurrentPosition((position) => {
				this.latitude_End_Visit = position.coords.latitude;
				this.longitude_End_Visit = position.coords.longitude;

				this.handleCheckOut();
			},
				(error) => {
					this.isLoading = false;
					this.showtoast('Warning', 'Please enable your device location', 'warning');
				});
		} else {
			this.showtoast('Warning', 'Geolocation is not supported by this browser', 'warning');
			this.isLoading = false;
		}
	}
	fromDate = new Date().toISOString().split('T')[0];
	toDate = '';

	handleDateChange(event) {
		const field = event.target.name;
		const value = event.target.value;

		if (field === 'fromDate') {
			this.fromDate = value;
		} else if (field === 'toDate') {
			this.toDate = value;
		}
	}
	getMobileLocation() {
		const locationService = getLocationService();

		if (!locationService || !locationService.isAvailable()) {
			this.showtoast('LocationService Not Available', 'Please use a GPS-enabled mobile device and ensure location is turned on.', 'error');
			this.isLoading = false;
			return;
		}

		const options = { enableHighAccuracy: true };

		locationService.getCurrentPosition(options)
			.then(result => {
				console.log('Location result:', result);
				this.latitude_End_Visit = result.coords.latitude;
				this.longitude_End_Visit = result.coords.longitude;

				this.handleCheckOut();
			})
			.catch(error => {
				console.error('Location error:', error);
				this.showtoast('Warning', 'Please enable your device location.', 'Warning');
				this.isLoading = false;
			});
	}

	/* ==================== Save (ONLINE via Apex, OFFLINE via LDS mirror) ==================== */
	async handleCheckOut() {
		console.log("Check out");
		// Maintain original client-side mark
		this.dispenserPoints.forEach(dp => { dp.Live__c = true; });

		try {
			if (navigator.onLine) {
				// === ONLINE: original Apex call, unchanged ===
				await saveVisitDetails({
					updates: this.dispenserPoints,
					workOrderId: this._recordId,
					latitude: this.latitude_End_Visit,
					longitude: this.longitude_End_Visit,
					remarks: this.remarks,
					fromDate: this.fromDate,
					toDate: this.toDate
				});
			} else {
				// === OFFLINE: LDS mirror of updateLiveDetails ===
				// 1) Update each Dispenser Point locally
				for (const dp of this.dispenserPoints) {
					const fields = {};
					fields[DP_ID.fieldApiName] = dp.Id;
  					fields[DP_LIVE_FLAG.fieldApiName] = true;
					if (typeof dp.Live_Reading__c !== 'undefined') fields[DP_LIVE.fieldApiName] = dp.Live_Reading__c;
					if (typeof dp.Closing_Reading__c !== 'undefined') fields[DP_CLOSE.fieldApiName] = dp.Closing_Reading__c;
					if (typeof dp.Progressive_Remark__c !== 'undefined') fields[DP_REMARK.fieldApiName] = dp.Progressive_Remark__c;
					if (typeof dp.Calibration_Qty__c !== 'undefined') fields[DP_CAL_QTY.fieldApiName] = dp.Calibration_Qty__c;
					if (typeof dp.Jumping_Qty__c !== 'undefined') fields[DP_JUMP_QTY.fieldApiName] = dp.Jumping_Qty__c;
					if (typeof dp.Other_Qty__c !== 'undefined') fields[DP_OTHER_QTY.fieldApiName] = dp.Other_Qty__c;
					if (typeof dp.Calibration_Reason__c !== 'undefined') fields[DP_CAL_REASON.fieldApiName] = dp.Calibration_Reason__c;
					if (typeof dp.Jumping_Reason__c !== 'undefined') fields[DP_JUMP_REASON.fieldApiName] = dp.Jumping_Reason__c;
					if (typeof dp.Other_Reason__c !== 'undefined') fields[DP_OTHER_REASON.fieldApiName] = dp.Other_Reason__c;

					await updateRecord({ fields });
				}

				// 2) Update WorkOrder live reading fields (mirrors Apex updateLiveDetails)
				// Live_Reading_Date_Time__c = Date(fromDate) + current time if fromDate present
				let liveDateTimeIso = null;
					if (this.fromDate) {
					const [y, m, d] = this.fromDate.split('-').map(Number);
					const now = new Date();
					const dt = new Date(y, m - 1, d, now.getHours(), now.getMinutes(), now.getSeconds());
					liveDateTimeIso = dt.toISOString();
					}
				await updateRecord({
					fields: {
						[WO_ID.fieldApiName]: this._recordId,
						[WO_REMARKS.fieldApiName]: this.remarks || '',
						[WO_LIVE_DT.fieldApiName]: liveDateTimeIso,
						[WO_LIVE_LAT.fieldApiName]: this.latitude_End_Visit,
						[WO_LIVE_LNG.fieldApiName]: this.longitude_End_Visit,
						[WO_STATUS.fieldApiName]: 'Completed',
						[WO_APPT_STATUS.fieldApiName]: 'Completed'
					}
				});
				// 3) Update ServiceAppointment (Completed) if we have it from GraphQL
				const saId = this.saEdge?.node?.Id;
				if (saId) {
					await updateRecord({ fields: { Id: saId, Status: 'Completed' } });
				}

				// 4) Complete WorkStep 'Live Reading' if we have it from GraphQL
				const wsId = this.wsEdge?.node?.Id;
				if (wsId) {
					await updateRecord({ fields: { Id: wsId, Status: 'Completed' } });
				}
			}

			this.showToast('Success', 'Dispenser Point saved successfully.', 'success');
			this.handleRefresh();
			this.isLoading = false;
			console.log("Checked out");
		} catch (error) {
			console.error('Error updating WorkOrder:', JSON.stringify(error));
			this.showToast('Error updating record', (error?.body?.message || error?.message || 'Update failed'), 'error');
			this.isLoading = false;
		}
	}

	handleRefresh() {
		this.navigateToRecord(this._recordId);
	}
	navigateToRecord(recordId) {
		if (FORM_FACTOR == 'Large') {
			this[NavigationMixin.Navigate]({
				type: 'standard__recordPage',
				attributes: {
					recordId: recordId,
					actionName: 'view',
				},
			});
		} else {
			this.dispatchEvent(new CloseActionScreenEvent());
		}
	}
	@track isEditMode = false;
	@track selectedDispenser = {};

	getDispenserRecordFunc() {
		console.log('this.recordId::' + this._recordId);

		if (navigator.onLine) {
			getDispenserPoints({ workOrderId: this._recordId })
				.then(result => {
					this.isLoading = true;
					this.wiredApexResult = result;
					console.log('result::' + JSON.stringify(result));
					const today = new Date();
					this.fromDate = today.toISOString().split('T')[0]; // Format: 'YYYY-MM-DD'
					console.log('fromDate::' + this.fromDate);
					if (result) {
						this.dispenserPoints = result.map(dp => ({
							...dp,
							Closing_Reading__c: dp.Closing_Reading__c || 0,
							Progressive_Remark__c: dp.Progressive_Remark__c || '',
							Calibration_Qty__c: dp.Calibration_Qty__c || 0,
							Calibration_Reason__c: dp.Calibration_Reason__c || '',
							Jumping_Qty__c: dp.Jumping_Qty__c || 0,
							Jumping_Reason__c: dp.Jumping_Reason__c || '',
							Other_Qty__c: dp.Other_Qty__c || 0,
							Other_Reason__c: dp.Other_Reason__c || '',
							Live_Reading__c: dp.Live_Reading__c || 0,
							Is_Progressive__c: '',
							Progressive_Progressive_Remark__c: dp.Progressive_Progressive_Remark__c || '',
							dispStyle: 'border: 1px solid lightgrey;',
							Difference: (Number(dp.Live_Reading__c) || 0) - (Number(dp.Closing_Reading__c) || 0),
							averageConsumption: (dp?.Account_Dispensor__r?.Average_Consumption__c || 0)
						}));
						this.dispenserPoints.forEach(dp => {
							let liveReading = parseFloat(dp.Live_Reading__c);
							let closingReading = parseFloat(dp.Closing_Reading__c);
							dp.labelNew = this.getBaseLabel(dp.Dispenser_Name__c);
							dp.Difference = (isNaN(liveReading) ? 0 : liveReading) - (isNaN(closingReading) ? 0 : closingReading);
							if (!isNaN(liveReading) && !isNaN(closingReading)) {
								dp.Is_Progressive__c = liveReading < closingReading ? 'No' : 'Yes';
								dp.Progressive_Remark__c = dp.Is_Progressive__c == 'No' ? (dp.labelNew + ' is not Progressive.') : '';
							}
						});
						this.dispenserPoints = this.getLatestLabels(this.dispenserPoints);
						this.dispenserPointsSummary = result.map(dp => ({ ...dp }));
						this.Total_Dispensing_Sale = this.dispenserPoints.reduce((sum, dp) => sum + (dp.Difference || 0), 0);
						this.isLoading = false;
					}
					else {
						this.isLoading = false;
					}
				})
				.catch(error => {
					console.log('error::' + JSON.stringify(error));
					this.isLoading = false;
					this.showToast('Error', 'Failed to load Dispenser Points (online).', 'error');
				});
		} else {
			// Offline path: GraphQL wire will populate if cached; show a quick hint toast here.
			this.isLoading = false;
			this.showToast('Info', 'Offline: showing cached Dispenser Points (if available).', 'info');
		}
		console.log('workOrderId::' + this.recordId);
	}

	// Function to extract base label and version number
	parseLabel(label) {
		const match = label?.match?.(/(Point_\d+)(?:_New_(\d+))?/);
		if (match) {
			const base = match[1];
			const version = match[2] ? parseInt(match[2], 10) : 0;
			return { base, version };
		}
		return { base: label, version: 0 };
	}

	// Filter the latest version
	getLatestLabels(points) {
		const latestMap = new Map();

		points.forEach(point => {
			const { base, version } = this.parseLabel(point.Dispenser_Name__c);
			if (!latestMap.has(base) || latestMap.get(base).version < version) {
				latestMap.set(base, { ...point, version });
			}
		});

		// Return only the values
		return Array.from(latestMap.values()).map(item => {
			delete item.version; // remove helper property
			return item;
		});
	}

	getBaseLabel(label) {
		const match = label?.match?.(/(Point_\d+)(?:_New_\d+)?/);
		if (match) {
			return match[1];
		}
		return label; // fallback if pattern doesn't match
	}

	showToast(title, message, variant) {
		this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
	}

	/* ======================= Offline helpers (hydrate + queue CV) ======================= */
	hydrateOfflinePoints(list) {
		// Merge into the same shape your UI expects
		const merged = list.map(dp => {
			const base = {
				...dp,
				Closing_Reading__c: dp.Closing_Reading__c || 0,
				Progressive_Remark__c: dp.Progressive_Remark__c || '',
				Calibration_Qty__c: dp.Calibration_Qty__c || 0,
				Calibration_Reason__c: dp.Calibration_Reason__c || '',
				Jumping_Qty__c: dp.Jumping_Qty__c || 0,
				Jumping_Reason__c: dp.Jumping_Reason__c || '',
				Other_Qty__c: dp.Other_Qty__c || 0,
				Other_Reason__c: dp.Other_Reason__c || '',
				Live_Reading__c: dp.Live_Reading__c || 0,
				Is_Progressive__c: '',
				dispStyle: 'border: 1px solid lightgrey;',
				Difference: (Number(dp.Live_Reading__c) || 0) - (Number(dp.Closing_Reading__c) || 0),
				averageConsumption: (dp.averageConsumption || 0)
			};
			// progressive calc
			const live = Number(base.Live_Reading__c) || 0;
			const close = Number(base.Closing_Reading__c) || 0;
			base.labelNew = this.getBaseLabel(base.Dispenser_Name__c);
			base.Is_Progressive__c = live < close ? 'No' : 'Yes';
			base.Progressive_Remark__c = base.Is_Progressive__c == 'No' ? (base.labelNew + ' is not Progressive.') : '';
			return base;
		});
		const latestOnly = this.getLatestLabels(merged);
		this.dispenserPoints = latestOnly;
		this.dispenserPointsSummary = latestOnly.map(dp => ({ ...dp }));
		this.Total_Dispensing_Sale = latestOnly.reduce((sum, dp) => sum + (dp.Difference || 0), 0);
	}

	async queueContentVersion(fileName, base64Data, publishLocationId) {
		// Avoid duplicate CV titles in one session
		const title = (fileName || 'Image').replace(/\.[^.]+$/, '');
		if (this._queuedTitles.has(title)) return;
		this._queuedTitles.add(title);

		const cleanBase64 = base64Data.includes(',') ? base64Data.split(',')[1] : base64Data;
		await createRecord({
			apiName: CV_OBJECT.objectApiName,
			fields: {
				Title: title,
				PathOnClient: fileName || 'Image.jpg',
				VersionData: cleanBase64,
				FirstPublishLocationId: publishLocationId
			}
		});
	}
}

/* ===== util mapper for GraphQL -> JS shape ===== */
function mapGraphqlDP(n) {
	const num = (v) => { const x = Number(v); return isNaN(x) ? 0 : x; };
	return {
		Id: n.Id,
		Name: n.Name?.value,
		Dispenser_Name__c: n.Dispenser_Name__c?.value,
		Opening_Reading__c: num(n.Opening_Reading__c?.value),
		Closing_Reading__c: num(n.Closing_Reading__c?.value),
		 Live_Reading__c: num(n.Live_Reading__c?.value),
    	Progressive_Remark__c: n.Progressive_Remark__c?.value,
		Difference_Of_Open_and_Close_Reading__c: num(n.Difference_Of_Open_and_Close_Reading__c?.value),
		Remark__c: n.Remark__c?.value,
		Calibration_Qty__c: num(n.Calibration_Qty__c?.value),
		Calibration_Reason__c: n.Calibration_Reason__c?.value,
		Jumping_Qty__c: num(n.Jumping_Qty__c?.value),
		Jumping_Reason__c: n.Jumping_Reason__c?.value,
		Other_Qty__c: num(n.Other_Qty__c?.value),
		Other_Reason__c: n.Other_Reason__c?.value,
		Dispenser_Number_Value__c: num(n.Dispenser_Number_Value__c?.value),
		averageConsumption: num(n?.Account_Dispensor__r?.Average_Consumption__c?.value),
		dispStyle: 'border: 1px solid lightgrey;'
	};
}