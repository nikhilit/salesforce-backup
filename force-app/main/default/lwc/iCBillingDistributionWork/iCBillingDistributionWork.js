import { LightningElement, track, api, wire } from 'lwc';

import saveImage from '@salesforce/apex/ICImageRemarkComponentHandler.saveImage';
import updateGeoLocation from '@salesforce/apex/ICImageRemarkComponentHandler.updateGeoLocation';
import getServiceAppoinment from '@salesforce/apex/ICImageRemarkComponentHandler.getServiceAppoinment';
import getGeoConfig from '@salesforce/apex/ICImageRemarkComponentHandler.getGeoConfig';
import getLocationFromCoOrdinates from '@salesforce/apex/GeoServiceHandler.getLocationFromCoOrdinates'

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { getLocationService } from 'lightning/mobileCapabilities';
import { getRecord } from 'lightning/uiRecordApi';
import userId from '@salesforce/user/Id';
import userNameField from '@salesforce/schema/User.Name';
import WORKORDER_LAT from '@salesforce/schema/WorkOrder.Latitude';
import WORKORDER_LONG from '@salesforce/schema/WorkOrder.Longitude';
import { getFieldValue } from 'lightning/uiRecordApi';

import WORKORDER_ACCOUNT from '@salesforce/schema/WorkOrder.AccountId';
import getAccountGeoCoordinates from '@salesforce/apex/ICImageRemarkComponentHandler.getAccountGeoCoordinates';
import checkAllocation from '@salesforce/apex/ICImageRemarkComponentHandler.checkAllocation';

export default class ICBillingDistributionWork extends LightningElement {

    @track remarks = '';
    @track photoUploadSlots = [];
    noOfPhotos = 2;
    @track load = false;
    @api recordId;

    currentUserName;
    textToAddTop = '';
    lat = null;
    long = null;

    showFollowUpScreen = false;
    showEnableMessage = false;

    mobileNumber = '';
    secondaryNumber = '';
    emailId = '';

    geoEnabled = false;
    geoRadius = 300; // default (meters)
    isOutOfFence = false;
    geofenceId = 'wo-fence';
    accountId = null;
    fenceLat = null;
    fenceLon = null;
    error;
    showCustomToast = false;
    customToastMessage = null;
    distance = null;
    locationText = ''

    // Fetch the logged-in user details to display the agent name and timestamp
    // on top of the images captured during the activity
    @wire(getRecord, { recordId: userId, fields: [userNameField] })
    wiredUser({ error, data }) {
        if (data) {
            this.currentUserName = data.fields.Name.value;
            this.textToAddTop = `${this.currentUserName}\n${this.formatDateTime(new Date())}`;
        } else if (error) {
            this.error = error;
        }
    }

    // Fetching Current Record (WorkOrder) Details
    @wire(getRecord, { recordId: '$recordId', fields: [WORKORDER_ACCOUNT] })
    wiredWO({ error, data }) {
        if (data) {
            this.accountId = getFieldValue(data, WORKORDER_ACCOUNT);
            if (this.accountId) {
                this.fetchAccountGeo();
            }
        } else if (error) {
            this.error = error;
            // don't block existing behaviour: log silently
            console.error('Error wiring WorkOrder location', error);
        }
    }

    // Fetch geolocation (latitude and longitude) for the account
    fetchAccountGeo() {
        getAccountGeoCoordinates({ accountId: this.accountId })
            .then(result => {
                this.fenceLat = result?.lat ?? null;
                this.fenceLon = result?.lon ?? null;
            })
            .catch(error => {
                this.error = error;
                console.error(error);
            });
    }

    // Get geo-fencing settings including enablement status and configured radius
    @wire(getGeoConfig)
    wiredGeoConfig({ error, data }) {
        if (data) {
            this.geoEnabled = data?.geoEnabled;
            this.geoRadius = data?.geoRadius;
        } else if (error) {
            console.error('Error fetching geo config', error);
            // default off
            this.geoEnabled = false;
            this.geoRadius = 300;
        }
    }

    connectedCallback() {
        this.checkAllocation();
        this.setPhotoUploadSlots();
        this.getServiceAppoinment();

        // if (FORM_FACTOR !== 'Large') {
        //     this.getMobileLocation('');
        //     if (this.geoEnabled && this.lat != null && this.long != null && this.fenceLat != null && this.fenceLon != null) {
        //         const inside = this._isInsideFence(
        //             this.fenceLat,
        //             this.fenceLon,
        //             Number(this.lat),
        //             Number(this.long),
        //             this.geoRadius
        //         );

        //         if (!inside) {
        //             this.isOutOfFence = true;
        //             this.load = false;
        //             this.showCustomToast = true;
        //             this.customToastMessage = 'You are outside the permitted GeoFence.'
        //             return;
        //         } else {
        //             this.isOutOfFence = false;
        //         }
        //     }
        // }
    }

    // Check whether the current Work Order is Withdrawn from logged-in user
    checkAllocation() {
        this.load = true;
        checkAllocation({ recordId: this.recordId })
            .then(result => {
                this.load = false;
                if (result !== null && result !== undefined && result === false) {
                    this.showEnableMessage = true;
                    this.message = 'This case is no longer assigned to you.';
                }
            })
            .catch(error => {
                this.load = false;
                this.showtoast('Error', error, 'JError');
            });
    }

    handleChange(e) {
        const name = e.target.dataset.name;
        if (name === 'mobileNumber') this.mobileNumber = e.target.value;
        if (name === 'secondaryNumber') this.secondaryNumber = e.target.value;
        if (name === 'emailId') this.emailId = e.target.value;
        if (name === 'remarks') this.remarks = e.target.value;
    }

    getServiceAppoinment() {

        getServiceAppoinment({ recordId: this.recordId })
            .then(result => {
                console.log('=====result===>', JSON.stringify(result));

                if (result) {
                    //const followUpDate = result.followUpDate ? result.followUpDate : '';
                    const status = result.status ? result.status : '';
                    const checkOutLocation = result.checkOutLocation ? String(result.checkOutLocation) : '';
                    const checkInLocation = result.checkInLocation ? String(result.checkInLocation) : '';
                    const checkOutDateTime = result.checkOutDateTime ? result.checkOutDateTime : '';
                    const checkINDateTime = result.checkInDateTime ? result.checkInDateTime : '';

                    this.remarks = result.remarks ? result.remarks : '';
                    this.mobileNumber = result.mobileNumber ? result.mobileNumber : '';
                    this.secondaryNumber = result.secondaryNumber ? result.secondaryNumber : '';
                    this.emailId = result.emailId ? result.emailId : '';

                    if (checkOutLocation != '' && checkInLocation != '' && checkOutDateTime != '' && checkINDateTime != '' && status == 'Completed') {
                        this.showEnableMessage = true;
                        this.message = 'Task is already completed. Please refresh the WorkOrder page and continue.';
                    }

                    if ((checkInLocation == '' || checkINDateTime == '') && (checkOutLocation == '' || checkOutDateTime == '') && status == 'Follow Up') {
                        this.showtoast('Warning', 'This is a Follow-Up task. If you want to attempt follow-up task today then continue else go back to Home screen.', 'warning');
                    }
                }

            })
            .catch(error => {
                this.showtoast('Error', error, 'Error');
            })
    }

    setPhotoUploadSlots() {
        this.photoUploadSlots = Array.from({ length: this.noOfPhotos }, (_, index) => ({
            id: index + 1,
            index: index + 1,
            label: `Photo ${index + 1}`,
            name: `fileUploader${index + 1}`,
            fileName: '',
            uploaded: false,
            previewUrl: '',
            base64Data: ''
        }));
    }

    saveChildRecord() {
        const childComponent = this.template.querySelector('c-ic-account-update');
        if (childComponent) {
            childComponent.submitForm();
        }
    }

    handleFollowUp() {
        this.showFollowUpScreen = true;
    }

    handleCloseToast() {
        this.showCustomToast = false;
        this.customToastMessage = null;
    }


    handleChildSaved() {

        const allFilesSelected = this.photoUploadSlots.find(slot => slot.fileName !== '');

        // After obtaining mobile coordinates, do immediate geofence check if geoEnabled
        if (this.geoEnabled) {

            // If WorkOrder location not present, show error
            if (this.lat == null || this.long == null) {
                this.showCustomToast = true;
                this.customToastMessage = 'Location not available for GeoFence check.'
                this.showtoast('Error', 'Location not available for GeoFence check.', 'error');
                this.load = false;
                return;
            }

            if (this.fenceLat != null && this.fenceLon != null) {
                const inside = this._isInsideFence(
                    this.fenceLat,
                    this.fenceLon,
                    Number(this.lat),
                    Number(this.long),
                    this.geoRadius
                );

                // const str = this.lat + '<->' + this.long + '<->' + Number(this.fenceLat) + '<->' + Number(this.fenceLon) + '<=>' + this.geoRadius + '<=>' + this._getDistanceMeters(this.lat, this.lat, Number(this.fenceLat), Number(this.fenceLon));

                if (!inside) {
                    this.isOutOfFence = true;
                    this.load = false;
                    this.showCustomToast = true;
                    this.customToastMessage = 'You are outside the permitted GeoFence.'
                    this.showtoast('Warning', 'You are outside the permitted GeoFence.', 'warning');
                    return;
                } else {
                    this.isOutOfFence = false;
                }
            }
        }

        if (!allFilesSelected) {
            this.load = false;
            this.showCustomToast = true;
            this.customToastMessage = 'Please Capture at least 1 photo.'
            this.showtoast('Warning', 'Please Capture at least 1 photo.', 'warning');
            return;
        }

        const signatureComp = this.template.querySelector('c-as-signature-pad');

        if (signatureComp) {

            if (signatureComp.isEmpty()) {
                this.showtoast('Warning', 'Signature is required.', 'warning');
                return;
            }

            const signatureBase64 = signatureComp.getSignatureBase64();
            this.signatureBase64 = signatureBase64;
        }

        if (FORM_FACTOR !== 'Large') {
            this.load = true;
            this.getMobileLocation('handleSave');
        } else {

            this.load = true;
            const workStepName = 'Billing Distribution';
            const photoUploadSlots = this.photoUploadSlots.filter(slot => slot.fileName !== '');

            saveImage({
                listFiles: photoUploadSlots,
                recordId: this.recordId,
                remarks: this.remarks,
                mobileNumber: this.mobileNumber,
                secondaryNumber: this.secondaryNumber,
                emailId: this.emailId,
                workStepName: workStepName,
                signatureBase64: this.signatureBase64
            })
                .then((result) => {
                    this.showtoast('Success', 'Images saved successfully!', 'success');
                    this.load = false;
                    history.back();
                    this.dispatchEvent(new CustomEvent('cancel'));
                })
                .catch(error => {
                    this.load = false;
                    const message = error?.body?.message || error?.message || 'Unknown error occurred';
                    this.showtoast('Error', message, 'error');
                });
        }
    }

    getMobileLocation(type) {
        const locationService = getLocationService();

        if (!locationService || !locationService.isAvailable()) {
            this.showtoast('LocationService Not Available', 'Please use a GPS-enabled mobile device and ensure location is turned on.', 'error');
            return;
        }

        const options = {
            enableHighAccuracy: true
        };

        locationService.getCurrentPosition(options)
            .then(result => {
                console.log('======locationService======>', result);

                this.lat = result.coords.latitude;
                this.long = result.coords.longitude;

                this.loadLocationAddress();

                if (type == 'handleSave') {
                    updateGeoLocation({ workOrderId: this.recordId, latitude: this.lat, longitude: this.long })
                        .then(result => {
                            console.log('======updateGeoLocation======>', result);

                            this.load = true;
                            const workStepName = 'Billing Distribution';

                            const photoUploadSlots = this.photoUploadSlots.filter(slot => slot.fileName !== '');

                            saveImage({
                                listFiles: photoUploadSlots,
                                recordId: this.recordId,
                                remarks: this.remarks,
                                mobileNumber: this.mobileNumber,
                                secondaryNumber: this.secondaryNumber,
                                emailId: this.emailId,
                                workStepName: workStepName,
                                signatureBase64: this.signatureBase64
                            })
                                .then((result) => {
                                    this.showtoast('Success', 'Images saved successfully!', 'success');
                                    this.load = false;
                                    history.back();
                                    this.dispatchEvent(new CustomEvent('cancel'));
                                })
                                .catch(error => {
                                    this.load = false;
                                    const message = error?.body?.message || error?.message || 'Unknown error occurred';
                                    this.showtoast('Error', message, 'error');
                                });

                        })
                        .catch(error => {
                            this.showtoast('Error', error, 'Error');
                        })
                }
            }).catch(error => {
                console.error('Location error:', error);
                this.showtoast('Warning', 'Please enable your device location.', 'Warning');
            }).finally(() => {

            });
    }

    async loadLocationAddress() {
        if (this.lat == null || this.long == null) {
            this.locationText = '';
            return;
        }
        try {
            this.locationText = await getLocationFromCoOrdinates({
                lat: Number(this.lat), 
                lng: Number(this.long)
            });
            if(this.locationText == null){
                this.locationText = '';
            }
            console.log('Location text = ',this.locationText);
            
        } catch (error) {
            console.error('Reverse geocode failed', error);
            this.locationText = '';
        }
    }


    handleFinalSave() {

        const allFilesSelected = this.photoUploadSlots.find(slot => slot.fileName !== '');

        if (!allFilesSelected) {
            this.load = false;
            this.showtoast('Warning', 'Please Capture at least 1 photo.', 'warning');
            return;
        }

        const signatureComp = this.template.querySelector('c-as-signature-pad');

        if (signatureComp) {

            if (signatureComp.isEmpty()) {
                this.showtoast('Warning', 'Signature is required.', 'warning');
                return;
            }

            const signatureBase64 = signatureComp.getSignatureBase64();
            this.signatureBase64 = signatureBase64;
        }

        this.saveChildRecord();
    }

    async handleFile(event) {

        let newSlots = event.detail.steps;
        console.log('========newSlots======>>>>', newSlots);

        for (let i = 0; i < newSlots.length; i++) {
            let slot = newSlots[i];

            console.log(`🔄 Processing Photo ${i + 1}`);
            console.log('========slot======>>>>', slot);

            // 🔥 Ensure we always work from ORIGINAL IMAGE (never the modified one)
            const rawBase64 = slot.originalBase64Data || slot.base64Data;

            if (!rawBase64) {
                console.warn(`⚠️ Skipped Photo ${i + 1}: base64Data missing.`);
                continue;
            }

            // Store raw base64 permanently
            slot.originalBase64Data = rawBase64;

            try {
                const fullBase64 = rawBase64.startsWith('data:image')
                    ? rawBase64
                    : `data:image/jpeg;base64,${rawBase64}`;

                // Original size
                const originalBytes = atob(fullBase64.split(',')[1]).length;
                console.log(`📷 Original Size Photo ${i + 1}: ${(originalBytes / 1024 / 1024).toFixed(2)} MB`);

                const blob = this.base64ToBlob(fullBase64);
                const imageUrl = URL.createObjectURL(blob);

                const compressedBlob = await this.compressImageFromURL(imageUrl);

                const compressedBase64 = await this.convertBlobToBase64(compressedBlob);

                const compressedBytes = atob(compressedBase64).length;
                console.log(`📉 Compressed Size Photo ${i + 1}: ${(compressedBytes / 1024 / 1024).toFixed(2)} MB`);

                // Store NEW image (with text)
                slot.base64Data = compressedBase64;

            } catch (error) {
                console.error(`❌ Compression failed for Photo ${i + 1}`, error);
            }
        }

        this.photoUploadSlots = newSlots;
        console.log('✅ Final photoUploadSlots set', this.photoUploadSlots);
    }


    // =========================================================================================
    // Helper Functions
    // =========================================================================================

     // Haversine formula: returns distance in meters
    _getDistanceMeters(lat1, lon1, lat2, lon2) {
        const R = 6371000; // Earth radius meters
        const toRad = (deg) => deg * Math.PI / 180;

        const dLat = toRad(lat2 - lat1);
        const dLon = toRad(lon2 - lon1);

        const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
            Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) *
            Math.sin(dLon / 2) * Math.sin(dLon / 2);

        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    }

    // boolean check convenience
    _isInsideFence(fenceLat, fenceLon, pointLat, pointLon, radiusMeters) {
        try {
            this.distance = this._getDistanceMeters(Number(fenceLat), Number(fenceLon), Number(pointLat), Number(pointLon));

            return this.distance <= Number(radiusMeters);
        } catch (error) {
            console.error('Error computing distance', error);
            return false;
        }
    }

    base64ToBlob(base64Data) {
        const byteString = atob(base64Data.split(',')[1]);
        const mimeString = base64Data.split(',')[0].split(':')[1].split(';')[0];

        const ab = new ArrayBuffer(byteString.length);
        const ia = new Uint8Array(ab);

        for (let i = 0; i < byteString.length; i++) {
            ia[i] = byteString.charCodeAt(i);
        }

        return new Blob([ab], { type: mimeString });
    }


    async compressImageFromURL(imageUrl) {
        return new Promise((resolve, reject) => {
            const img = new Image();

            img.onload = () => {
                try {
                    const canvas = document.createElement('canvas');
                    const ctx = canvas.getContext('2d');

                    const maxWidth = 1200;
                    const maxHeight = 1200;

                    let width = img.width;
                    let height = img.height;

                    const ratio = Math.min(maxWidth / width, maxHeight / height);
                    width *= ratio;
                    height *= ratio;

                    canvas.width = width;
                    canvas.height = height;

                    // Draw image
                    ctx.drawImage(img, 0, 0, width, height);

                    // Set font and style BEFORE drawing text
                    ctx.font = '30px Arial';
                    ctx.fillStyle = 'blue'; 
                    ctx.textAlign = 'left';

                    const paddingLeft = 10; // distance from left edge

                    // Top text
                    const topLines = this.textToAddTop.split('\n');
                    topLines.forEach((line, index) => {
                        ctx.fillText(line.trim(), paddingLeft, 35 + index * 34);
                    });

                    // Bottom text (fixed size, wrap to next line if too long)
                    ctx.font = '30px Arial';  // keep desired font size
                    ctx.fillStyle = 'blue';
                    ctx.textAlign = 'left';

                    const maxTextWidth = width - paddingLeft * 2;
                    const words = this.locationText.split(' ');
                    let line = '';
                    let y = height - 17; // start from bottom

                    for (let i = 0; i < words.length; i++) {
                        const testLine = line + words[i] + ' ';
                        if (ctx.measureText(testLine).width > maxTextWidth) {
                            ctx.fillText(line, paddingLeft, y);
                            line = words[i] + ' ';
                            y -= 34; // move up by font size + padding
                        } else {
                            line = testLine;
                        }
                    }
                    ctx.fillText(line, paddingLeft, y); // draw remaining text

                    canvas.toBlob(
                        (blob) => {
                            if (blob) resolve(blob);
                            else reject(new Error('Canvas produced null blob'));
                        },
                        'image/jpeg',
                        0.6
                    );

                } catch (err) {
                    reject(err);
                }
            };

            img.onerror = () => reject('Error loading image');
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


    formatDateTime(date) {
        const day = String(date.getDate()).padStart(2, '0');

        const monthNames = [
            'January', 'February', 'March', 'April', 'May', 'June',
            'July', 'August', 'September', 'October', 'November', 'December'
        ];
        const month = monthNames[date.getMonth()];

        const year = date.getFullYear();

        let hours = date.getHours();
        const minutes = String(date.getMinutes()).padStart(2, '0');
        const ampm = hours >= 12 ? 'PM' : 'AM';

        hours = hours % 12;
        hours = hours ? hours : 12; // convert 0 to 12
        const formattedHours = String(hours).padStart(2, '0');

        return `${day} ${month} ${year} ${formattedHours}:${minutes} ${ampm}`;
    }

    showtoast(title, msg, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}