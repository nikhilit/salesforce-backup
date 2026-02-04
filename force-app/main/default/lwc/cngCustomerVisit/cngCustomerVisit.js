/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 19-01-2026
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   22-12-2025   Kartik Patkar, Appstrail   Initial Version
**/
import { LightningElement, wire, api, track } from 'lwc';
import getCustomerProfile from '@salesforce/apex/CustomerProfileController.getCustomerProfile';
import getLocationInfo from '@salesforce/apex/CustomerProfileController.getLocationInfo';
import checkInWorkOrder from '@salesforce/apex/WorkOrderVisitController.checkInWorkOrder';
import { getLocationService } from 'lightning/mobileCapabilities';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { CloseActionScreenEvent } from 'lightning/actions';
import LightningAlert from 'lightning/alert';

import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';

// Work Order fields (LDS, offline-capable)
import WO_ACCOUNTID from '@salesforce/schema/WorkOrder.AccountId';
import WO_STATUS from '@salesforce/schema/WorkOrder.Status';
import WO_CHECKIN from '@salesforce/schema/WorkOrder.Check_In__c';
import WO_CHECKIN_DT from '@salesforce/schema/WorkOrder.Check_In_Date_Time__c';
// Use the compound geolocation that matches Apex
import WO_CHECKIN_GEO from '@salesforce/schema/WorkOrder.Check_In_Location__c';

// Account header fields
import ACC_NAME from '@salesforce/schema/Account.Name';
import ACC_PHONE from '@salesforce/schema/Account.Phone';
import ACC_ZONE from '@salesforce/schema/Account.Zone__c';
import ACC_LOCATION from '@salesforce/schema/Account.Location__c';
import ACC_REPCOMP from '@salesforce/schema/Account.Representative_Company__c';

export default class CngCustomerVisit extends LightningElement {
	@track profileData;
	@track startVisit = false;
	@track lat;
	@track long;
	@track isLoading = true;

	workOrderHeader = {};
	wiredProfileResult;
	fallbackLat;
	fallbackLong;
	geoFenceConfig;
    geoFence = false;
    geoDistance;
    actualCoords;
	account;

	_recordId;
	@api set recordId(v) { 
		this._recordId = v; 
		if (v) this.init(); 
		getLocationInfo({ workOrderId: v })
		.then(result => {
			console.log('Location info result::' + JSON.stringify(result));
			if (result.geoFenceConfig) {
				this.geoFenceConfig = result.geoFenceConfig;
				this.geoFence = this.geoFenceConfig.For_CNG__c;
				this.geoDistance = this.geoFenceConfig.For_CNG_Distance_in_Meter__c;
			}
			this.account = result.account;
			console.log('Account from wrapper::' + JSON.stringify(this.account));
			// this.actualCoords = { latitude: result.actualLatitude, longitude: result.data.actualLongitude };
			if (this.account && this.account.Geolocation__c) {
				this.actualCoords = this.account.Geolocation__c;
			}
			console.log('Actual coords::' + JSON.stringify(this.actualCoords));
		})
		.catch(error => {
			console.error('Error fetching location info::' + JSON.stringify(error));
		});
	}
	get recordId() { return this._recordId; }

	// Online enrichment (optional offline)
	@wire(getCustomerProfile, { workOrderId: '$recordId' })
	wiredProfile(result) {
		this.wiredProfileResult = result;
		var { data, error } = result;
		// if(data){
		// 	console.log('Wired profile result::' + JSON.stringify(result));
		// 	if (result.data.geoFenceConfig) {
		// 		this.geoFenceConfig = result.data.geoFenceConfig;
		// 		this.geoFence = this.geoFenceConfig.For_CNG__c;
		// 		this.geoDistance = this.geoFenceConfig.For_CNG_Distance_in_Meter__c;
		// 	}
		// 	this.account = result.data.account;
		// 	console.log('Account from wrapper::' + JSON.stringify(this.account));
		// 	// this.actualCoords = { latitude: result.actualLatitude, longitude: result.data.actualLongitude };
		// 	if (this.account && this.account.Geolocation__c) {
		// 		this.actualCoords = this.account.Geolocation__c;
		// 	}
		// 	console.log('Actual coords::' + JSON.stringify(this.actualCoords));
		// }
		// if (result?.data) this.profileData = result.data;
	}

	// Work Order cached fields for offline
	@wire(getRecord, { recordId: '$recordId', fields: [WO_ACCOUNTID, WO_CHECKIN, WO_CHECKIN_GEO] })
	woWire({ data }) {
		if (!data) return;
		if (getFieldValue(data, WO_CHECKIN) && !this.startVisit) this.startVisit = true;

		// Read child coords from the compound geolocation
		const geo = data.fields?.[WO_CHECKIN_GEO.fieldApiName]?.value;
		this.fallbackLat = geo?.latitude ?? null;
		this.fallbackLong = geo?.longitude ?? null;
	}

	@wire(getRecord, { recordId: '$recordId', fields: [WO_ACCOUNTID] }) woForAccountId;

	get accountId() {
		try { return getFieldValue(this.woForAccountId?.data, WO_ACCOUNTID); }
		catch { return undefined; }
	}

	// Account header via LDS for offline rendering
	@wire(getRecord, {
		recordId: '$accountId',
		fields: [ACC_NAME, ACC_PHONE, ACC_ZONE, ACC_LOCATION, ACC_REPCOMP]
	})
	accWire({ data }) {
		if (!data) return;
		this.workOrderHeader = {
			customerName: getFieldValue(data, ACC_NAME),
			phone: getFieldValue(data, ACC_PHONE),
			zone: getFieldValue(data, ACC_ZONE),
			location: getFieldValue(data, ACC_LOCATION),
			repComp: getFieldValue(data, ACC_REPCOMP)
		};
	}

	// -------- Start Visit flow --------
	handleStartVisit() {
		this.isLoading = true;
		if (FORM_FACTOR === 'Large') this.getBrowserLocation();
		else this.getMobileLocation();
	}

	errorCallback(error, stack) {
		console.error('Error in cngCustomerVisit:', error, stack);
		this.showToast('Error', 'An unexpected error occurred.', 'error');
		this.isLoading = false;
	}

	getBrowserLocation() {
		if (!navigator.geolocation) return this.proceedWithoutGPS();
		navigator.geolocation.getCurrentPosition(
			pos => { 
				this.lat = pos.coords.latitude; 
				this.long = pos.coords.longitude; 
				console.log('actualCoords::' + JSON.stringify(this.actualCoords));
                if (this.geoFence && (this.actualCoords == null || this.actualCoords.latitude == null || this.actualCoords.longitude == null)) {
					console.log('Account geolocation not available.');
                    this.showToastMessage('Error', 'Account geolocation not available.', 'error');
                    this.handleActionClick('Error', 'Account geolocation not available.', 'error');
                    this.isLoading = false;
                    return;
                }
                else if (this.geoFence) {
					console.log('Geo fence is enabled.');
                    var result = this.checkGeoFence(this.actualCoords.latitude, this.actualCoords.longitude, this.lat, this.long, this.geoDistance);
                    console.log('Geo fence result::' + JSON.stringify(result));
                    if (result.isOutOfBoundary) {
                        if (result.actualDistance == null) {
                            this.showToastMessage('Error', 'You are not in the geo fence.', 'error');
                            this.handleActionClick('Error', 'You are not in the geo fence.', 'error');
                        } else {
                            this.showToastMessage('Error', 'You are not in the geo fence. Distance: ' + result.actualDistance + 'm.', 'error');
                            this.handleActionClick('Error', 'You are not in the geo fence. Distance: ' + result.actualDistance + 'm.', 'error');
                        }
                        this.isLoading = false;
                        return;
                    }else{
						this.handleCheckIn(); 
					}
                }else{
                    // result = this.updateCheckInDetails();
					this.handleCheckIn(); 
                }
				console.log('Proceeding with check-in.');
			},
			() => { 
				this.proceedWithoutGPS(); 
			}
		);
	}

	getMobileLocation() {
		const svc = (window && window.lightning && window.lightning.getLocationService)
					? window.lightning.getLocationService()
					: getLocationService?.();
		if (!svc || !svc.isAvailable || !svc.isAvailable()) return this.proceedWithoutGPS();
		svc.getCurrentPosition({ enableHighAccuracy: true })
		.then(r => { 
			this.lat = r.coords.latitude; 
			this.long = r.coords.longitude; 
			console.log('actualCoords::' + JSON.stringify(this.actualCoords));
                if (this.geoFence && (this.actualCoords == null || this.actualCoords.latitude == null || this.actualCoords.longitude == null)) {
					console.log('Account geolocation not available.');
                    this.showToastMessage('Error', 'Account geolocation not available.', 'error');
                    this.handleActionClick('Error', 'Account geolocation not available.', 'error');
                    this.isLoading = false;
                    return;
                }
                else if (this.geoFence) {
					console.log('Geo fence is enabled.');
                    var result = this.checkGeoFence(this.actualCoords.latitude, this.actualCoords.longitude, this.lat, this.long, this.geoDistance);
                    console.log('Geo fence result::' + JSON.stringify(result));
                    if (result.isOutOfBoundary) {
                        if (result.actualDistance == null) {
                            this.showToastMessage('Error', 'You are not in the geo fence.', 'error');
                            this.handleActionClick('Error', 'You are not in the geo fence.', 'error');
                        } else {
                            this.showToastMessage('Error', 'You are not in the geo fence. Distance: ' + result.actualDistance + 'm.', 'error');
                            this.handleActionClick('Error', 'You are not in the geo fence. Distance: ' + result.actualDistance + 'm.', 'error');
                        }
                        this.isLoading = false;
                        return;
                    }else{
						this.handleCheckIn(); 
					}
                }else{
                    // result = this.updateCheckInDetails();
					this.handleCheckIn(); 
                }
			// this.handleCheckIn(); 
		})
		.catch(() => this.proceedWithoutGPS());
	}

	proceedWithoutGPS() {
		this.lat = this.fallbackLat ?? null;
		this.long = this.fallbackLong ?? null;
		console.log('actualCoords::' + JSON.stringify(this.actualCoords));
                if (this.actualCoords == null || this.actualCoords.latitude == null || this.actualCoords.longitude == null) {
					console.log('Account geolocation not available.');
                    this.showToastMessage('Error', 'Account geolocation not available.', 'error');
                    this.handleActionClick('Error', 'Account geolocation not available.', 'error');
                    this.isLoading = false;
                    return;
                }
                else if (this.geoFence) {
					console.log('Geo fence is enabled.');
                    var result = this.checkGeoFence(this.actualCoords.latitude, this.actualCoords.longitude, this.lat, this.long, this.geoDistance);
                    console.log('Geo fence result::' + JSON.stringify(result));
                    if (result.isOutOfBoundary) {
                        if (result.actualDistance == null) {
                            this.showToastMessage('Error', 'You are not in the geo fence.', 'error');
                            this.handleActionClick('Error', 'You are not in the geo fence.', 'error');
                        } else {
                            this.showToastMessage('Error', 'You are not in the geo fence. Distance: ' + result.actualDistance + 'm.', 'error');
                            this.handleActionClick('Error', 'You are not in the geo fence. Distance: ' + result.actualDistance + 'm.', 'error');
                        }
                        this.isLoading = false;
                        return;
                    }else{
						this.handleCheckIn(); 
					}
                }else{
                    // result = this.updateCheckInDetails();
					this.handleCheckIn(); 
                }
		// this.handleCheckIn();
	}

	async handleCheckIn() {
		if (!this.recordId) {
			this.showToast('Error', 'Invalid Work Order', 'error');
			this.isLoading = false;
			return;
		}

		// Online: Apex mutation (Apex expects lat/long doubles and writes __Latitude__s / __Longitude__s)
		if (navigator.onLine) {
			try {
				await checkInWorkOrder({ workOrderId: this.recordId, latitude: this.lat, longitude: this.long });
				this.startVisit = true;
			} catch (e) {
				this.showToast('Error updating record', e?.body?.message || 'Check-in failed', 'error');
			} finally { this.isLoading = false; }
			return;
		}

		// Offline: LDS draft, using compound geolocation value
		try {
			const fields = { Id: this.recordId, [WO_CHECKIN.fieldApiName]: true };
			if (WO_STATUS?.fieldApiName) fields[WO_STATUS.fieldApiName] = 'In Progress';
			if (this.lat != null && this.long != null) {
				fields[WO_CHECKIN_GEO.fieldApiName] = { latitude: this.lat, longitude: this.long };
			}
			fields[WO_CHECKIN_DT.fieldApiName] = new Date().toISOString();
			await updateRecord({ fields });
			this.startVisit = true;
		} catch (e) {
			this.showToast('Error', e?.body?.message || e?.message || 'Offline check-in failed', 'error');
		} finally { this.isLoading = false; }
	}

	init() {
		this.isLoading = true;
		if (this.wiredProfileResult) refreshApex(this.wiredProfileResult);
		this.isLoading = false;
	}

	showToast(title, message, variant) { this.dispatchEvent(new ShowToastEvent({ title, message, variant })); }
	handleClose() { this.dispatchEvent(new CloseActionScreenEvent()); }

	async handleActionClick(label,message, variant ) {
        await LightningAlert.open({
            message: message,
            theme: variant,
            label: label,
        });
    }

	/**
     * This function creates a new ShowToastEvent, sets the title, message, variant, and mode, and then
     * dispatches the event
     * @param title - The title of the toast message.
     * @param message - The message you want to display in the toast.
     * @param variant - The type of toast message. Valid values are error, warning, success, and info.
     * @param mode - This is the mode of the toast. It can be either 'dismissable','pester' or 'sticky'.
     */
    showToastMessage(title, message, variant, mode) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);
    }

	checkGeoFence(actualLat, actualLon, currentLat, currentLon, allowedDistanceMeters = 50) {
        if (!actualLat || !actualLon || !currentLat || !currentLon) {
            return {
                isOutOfBoundary: true,
                actualDistance: null,
                error: 'Invalid latitude/longitude input'
            };
        }

        const R = 6371000; // earth radius in meters
        const toRad = (deg) => deg * (Math.PI / 180);

        const lat1 = toRad(actualLat);
        const lat2 = toRad(currentLat);
        const dLat = toRad(currentLat - actualLat);
        const dLon = toRad(currentLon - actualLon);

        // Haversine formula
        const a =
            Math.sin(dLat / 2) * Math.sin(dLat / 2) +
            Math.cos(lat1) * Math.cos(lat2) *
            Math.sin(dLon / 2) * Math.sin(dLon / 2);

        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        const actualDistance = R * c; // in meters

        // geofence result
        const isOutOfBoundary = actualDistance > allowedDistanceMeters;

        return {
            isOutOfBoundary,
            actualDistance: Math.round(actualDistance) // in meters
        };
    }
}