/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 21-01-2026
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   17-06-2025   Kartik Patkar, Appstrail   Initial Version
 * 1.1   27-10-2025   Kartik Patkar, Appstrail   Offline parity (GraphQL wire + LDS) without affecting online
**/
import { api, LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { getLocationService } from 'lightning/mobileCapabilities';
import LightningAlert from 'lightning/alert';
import { refreshApex } from '@salesforce/apex';

import FORM_FACTOR from '@salesforce/client/formFactor';

import getAccountInfoFromSA from '@salesforce/apex/MRSMeterReadingController.getAccountInfoFromSA';
import updateWorkOrder from '@salesforce/apex/MRSMeterReadingController.updateWorkOrder';
import saveImage from '@salesforce/apex/MRSMeterReadingController.saveImage';
import workOrderCheckIn from '@salesforce/apex/MRSMeterReadingController.workOrderCheckIn';
import getGeoFenceData from '@salesforce/apex/MRSMeterReadingController.getGeoFenceData';
import { CloseActionScreenEvent } from 'lightning/actions';

/* ---------- Added for OFFLINE parity (LDS + GraphQL wire) ---------- */
import { getRecord, updateRecord, createRecord, deleteRecord } from 'lightning/uiRecordApi';
import { graphql, gql } from 'lightning/uiGraphQLApi';

/* WorkOrder fields for LDS */
import WO_ID from '@salesforce/schema/WorkOrder.Id';
import WO_ACCOUNT from '@salesforce/schema/WorkOrder.AccountId';
import WO_APPT_STATUS from '@salesforce/schema/WorkOrder.Appointment_Status__c';
import WO_TURBINE from '@salesforce/schema/WorkOrder.Turbine_Meter_Reading__c';
import WO_PRESSURE from '@salesforce/schema/WorkOrder.Pressure__c';
import WO_TEMP from '@salesforce/schema/WorkOrder.Temperature__c';
import WO_UV from '@salesforce/schema/WorkOrder.Uncorrected_Volume__c';
import WO_CV from '@salesforce/schema/WorkOrder.Corrected_Volume__c';
import WO_CF from '@salesforce/schema/WorkOrder.Correction_Factor__c';
import WO_REMARKS from '@salesforce/schema/WorkOrder.Meter_Image_Remark__c';
import WO_CHECKIN from '@salesforce/schema/WorkOrder.Check_In__c';
import WO_CHECKIN_DT from '@salesforce/schema/WorkOrder.Check_In_Date_Time__c';
import WO_CHECKIN_LAT from '@salesforce/schema/WorkOrder.Check_In_Location__c';
import WO_CHECKIN_LNG from '@salesforce/schema/WorkOrder.Check_In_Location__c';
import WO_CHECKOUT from '@salesforce/schema/WorkOrder.Check_Out__c';
import WO_CHECKOUT_DT from '@salesforce/schema/WorkOrder.Check_Out_Date_Time__c';
import WO_CHECKOUT_LAT from '@salesforce/schema/WorkOrder.Check_Out_Location__c';
import WO_CHECKOUT_LNG from '@salesforce/schema/WorkOrder.Check_Out_Location__c';
import WO_APPROVAL_STATUS from '@salesforce/schema/WorkOrder.Approval_Status__c';

/* Account fields for LDS */
import ACC_NAME from '@salesforce/schema/Account.Name';
import ACC_PHONE from '@salesforce/schema/Account.Phone';
import ACC_BP from '@salesforce/schema/Account.BP_Number__c';
import ACC_CA from '@salesforce/schema/Account.CA_Number__c';
import ACC_METER from '@salesforce/schema/Account.Meter_Number__c';
import ACC_ADDR1 from '@salesforce/schema/Account.Building_name__c';
import ACC_ADDR2 from '@salesforce/schema/Account.Road_name__c';
import ACC_CITY from '@salesforce/schema/Account.City__c';
import ACC_POSTAL from '@salesforce/schema/Account.Postal_Code__c';

/* For offline image creation */
import CV_OBJECT from '@salesforce/schema/ContentVersion';
import DOC_OBJECT from '@salesforce/schema/Document__c';

// WorkStep fields for LDS update
import WS_ID from '@salesforce/schema/WorkStep.Id';
import WS_STATUS from '@salesforce/schema/WorkStep.Status';

// Custom Label for the WorkStep name (parity with Apex using System.label.Start_Metering_Step_Name)
import START_STEP_NAME from '@salesforce/label/c.Start_Metering_Step_Name';


/* ---------------- GraphQL Queries (wire adapters) ---------------- */

const SERVICE_APPT_QUERY = gql`
  query saByWO($woId: ID) {
    uiapi {
      query {
        ServiceAppointment(where: { ParentRecordId: { eq: $woId } }, first: 1) {
          edges { node { Id Status { value } } }
        }
      }
    }
  }
`;

const ATTACHED_DOC_QUERY = gql`
  query contentDocs($woId: ID) {
    uiapi {
      query {
        ContentDocumentLink(where: { LinkedEntityId: { eq: $woId } }) {
          edges { node { ContentDocumentId { value } } }
        }
      }
    }
  }
`;

// const DOC_MASTER_QUERY = gql`
//   query docMasters($type: Picklist) {
//     uiapi {
//       query {
//         Document_Master__c(
//           where: { Active__c: { eq: true }, Type__c: { eq: $type } },
//           orderBy: { Order__c: { order: ASC } }
//         ) {
//           edges {
//             node {
//               Id
//               Document_Name__c { value }
//               Compress_Image__c { value }
//             }
//           }
//         }
//       }
//     }
//   }
// `;

const DOC_MASTER_QUERY = gql`
  query docMasters($type: Picklist!) {
    uiapi {
      query {
        Document_Master__c(
          where: {
            Active__c: { eq: true },
            Type__c: { eq: $type }
          },
          orderBy: { Order__c: { order: ASC } },
          first: 50
        ) {
          edges {
            node {
              Id
              Document_Name__c { value }
              Order__c { value }
              Compress_Image__c { value }
              Type__c { value }
            }
          }
        }
      }
    }
  }
`;



const WS_STEP_QUERY = gql`
  query wsByWO($woId: ID, $stepName: String) {
    uiapi {
      query {
        WorkStep(
          where: { ParentRecordId: { eq: $woId }, Name: { eq: $stepName } }
          first: 1
        ) {
          edges { node { Id Status { value } } }
        }
      }
    }
  }
`;

export default class MrsMeterReadingComponent extends NavigationMixin(LightningElement) {

    error = false;
    errorMessage = '';
    workStepId;
    accountView = true;
    meterReadingPage = false;
    listPhotos = [];
    load = true;
    _recordId;
    @api get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;
        this.refreshWired();
    }

    @track wrapperData = {
        turbineMeterReading: null,
        pressure: null,
        correctedVolume: null,
        uncorrectedVolume: null,
        correctionFactor: null,
        temperature: null,
        meterImageRemark: '',
        latitude: null,
        longitude: null
    }

    account;
    customerCategory;
    workOrderCompleted = false;
    geoFenceConfig;
    geoFence = false;
    geoDistance;
    actualCoords;
    getAccountInfoFromSAData;
    refreshTrigger=true;

    @wire(getAccountInfoFromSA, { workOrderId: '$recordId',refresh: '$refreshTrigger' })
    wiredAccountInfo(result) {
        const { error, data } = result;
        // this.refreshWired();
        this.getAccountInfoFromSAData = result;
        if (!navigator.onLine) {
            this.load = false; // Stop spinner
            return;
        }
        if (data) {
            console.log('Account data received:', data);
            // this.account = data.acc;
            // if (this.account && this.account.Geolocation__c) {
            //     this.actualCoords = this.account.Geolocation__c;
            // }
            // this.listPhotos = data.listImages;
            // if (data.geoFenceConfig) {
            //     this.geoFenceConfig = data.geoFenceConfig;
            //     this.geoFence = this.geoFenceConfig.For_MRS__c;
            //     this.geoDistance = this.geoFenceConfig.For_MRS_Distance_in_Meter__c;
            // }
            if (data.workOrder != null) {

                if (data.workOrder.Customer_Category__c != null && data.workOrder.Customer_Category__c == 'Non-MRS Commercial') {
                    this.customerCategory = 'Non-MRS';
                    this.nonMRS = true;
                } else {
                    this.customerCategory = 'Domestic';
                }
                console.log('wiredAccountInfo this.customerCategory::' + this.customerCategory);
                // console.log('this.groupMessageValue::'+this.groupMessageValue);
                // this.getGroupCodeOptionsFunc();
                if (data.workOrder.Appointment_Status__c == 'Completed') {
                    this.workOrderCompleted = true;
                    this.showPreviewPage = true;
                    this.formFirstPage = false;
                    this.accountView = false;
                    this.wrapperData.turbineMeterReading = data.workOrder.Turbine_Meter_Reading__c;
                    this.wrapperData.pressure = data.workOrder.Pressure__c;
                    this.wrapperData.temperature = data.workOrder.Temperature__c;
                    this.wrapperData.meterImageRemark = data.workOrder.Meter_Reading_Remarks__c;
                    this.wrapperData.uncorrectedVolume = data.workOrder.Uncorrected_Volume__c;
                    this.wrapperData.correctedVolume = data.workOrder.Corrected_Volume__c;
                    this.wrapperData.correctionFactor = data.workOrder.Correction_Factor__c;
                }
            }
            this.error = undefined;
            this.error = false;
            this.errorMessage = '';
        } else if (error) {
            console.error('Error fetching account:', error);
            this.account = undefined;
            //this.error = error;
            this.error = true;
            this.errorMessage = this.normalizeWireError(error);
        }
        this.load = false;
    }

    refreshWired(){
        getGeoFenceData({ workOrderId: this._recordId })
        .then(result => {
            console.log('refreshWired getGeoFenceData result:', JSON.stringify(result));
            this.account = result.acc;
            if (this.account && this.account.Geolocation__c) {
                this.actualCoords = this.account.Geolocation__c;
            }
            if (result.geoFenceConfig) {
                this.geoFenceConfig = result.geoFenceConfig;
                this.geoFence = this.geoFenceConfig.For_MRS__c;
                this.geoDistance = this.geoFenceConfig.For_MRS_Distance_in_Meter__c;
            }
        })
        .catch(error => {
            console.error('Error in refreshWired getGeoFenceData:', JSON.stringify(error));
        });
        // return refreshApex(this.getAccountInfoFromSAData);
    }

    @track showOkModal = false;
    handleSaveClick() {
        this.handleRedirect(this.recordId);
    }
    handleFieldChange(event) {
        var fieldName = event.currentTarget.dataset.fieldName;
        var value = event.detail.value;
        this.wrapperData[fieldName] = value;
    }

    handleStartMetering() {
        this.accountView = false;
        this.meterReadingPage = true;
        this.load = false;
    }

    captureImagePage = false;
    handleStartMeteringNext() {
        this.meterReadingPage = false;
        this.captureImagePage = true;
    }

    handleStartMeteringBack() {
        this.checkOut = false;
        this.accountView = true;
        this.meterReadingPage = false;
    }

    handleCaptureMeterBack() {
        this.captureImagePage = false;
        this.meterReadingPage = true;
    }

    validateField() {
        if (this.wrapperData.turbineMeterReading == null || this.wrapperData.pressure == null
            || this.wrapperData.correctedVolume == null || this.wrapperData.uncorrectedVolume == null
            || this.wrapperData.correctionFactor == null || this.wrapperData.temperature == null) {

            this.showToastMessage('Error', 'Please enter all required field', 'error', 'dismissable');
            return true;
        }

        var image = 0;
        console.log('this.listPhotos::' + JSON.stringify(this.listPhotos));
        this.listPhotos.forEach(item => {
            if (item.uploaded) {
                image++;
            }
        })
        if (image != this.listPhotos.length) {
            this.showToastMessage('Error', 'Please upload all the photos', 'error');
            return true;
        }
        return false;
    }

    showPreviewPage = false;
    handleCaptureMeterNext() {
        if (this.validateField()) {
            return;
        }
        this.showPreviewPage = true;
        this.captureImagePage = false;
        this.meterReadingPage = false;
    }

    handlePreviewBack() {
        this.showPreviewPage = false;
        this.meterReadingPage = true;
    }

    async handleFile(event) {
        this.listPhotos = event.detail.steps;

        // for (let i = 0; i < this.listPhotos.length; i++) {
        //     var slot = this.listPhotos[i];
        //     if (!slot.added) {
        //         continue;
        //     }
        //     console.log('Slot:::' + JSON.stringify(slot.base64Data));
        //     if (slot.base64Data) {
        //         try {
        //             // Add prefix if missing
        //             const fullBase64 = slot.base64Data.startsWith('data:image')
        //                 ? slot.base64Data
        //                 : `data:image/jpeg;base64,${slot.base64Data}`;

        //             // Original size in MB
        //             const originalBytes = atob(fullBase64.split(',')[1]).length;
        //             const originalMB = (originalBytes / (1024 * 1024)).toFixed(2);
        //             console.log(`Original Size of Photo ${i + 1}: ${originalMB} MB`);

        //             // Convert to blob and compress
        //             const blob = await this.base64ToBlob(fullBase64);
        //             const imageUrl = URL.createObjectURL(blob);
        //             const compressedBlob = await this.compressImageFromURL(imageUrl);

        //             // Convert compressed Blob back to base64
        //             const compressedBase64 = await this.convertBlobToBase64(compressedBlob);
        //             const compressedBytes = atob(compressedBase64).length;
        //             const compressedMB = (compressedBytes / (1024 * 1024)).toFixed(2);
        //             console.log(`Compressed Size of Photo ${i + 1}: ${compressedMB} MB`);

        //             // Store compressed result
        //             slot.base64Data = compressedBase64;

        //         } catch (error) {
        //             //console.error(`Compression failed for Photo ${i + 1}:`, error);

        //             // Only show toast if compressed base64 is not usable
        //             if (!slot.base64Data || slot.base64Data.length < 100) {
        //                 console.error(`Compression failed for Photo ${i + 1}:`, error?.message || JSON.stringify(error) || 'Unknown error');
        //             } else {
        //                 console.warn(`Compression threw error but base64 still present for Photo ${i + 1}`);
        //             }
        //         }


        //     } else {
        //         console.warn(`Skipped Photo ${i + 1}: base64Data missing.`);
        //     }
        // }
        console.log('handleFile this.listPhotos::' + JSON.stringify(this.listPhotos));
    }

    async base64ToBlob(base64Data) {
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
                    const maxWidth = 2400;
                    const maxHeight = 2400;
                    let width = img.width;
                    let height = img.height;

                    const ratio = Math.min(maxWidth / width, maxHeight / height);
                    width *= ratio;
                    height *= ratio;

                    canvas.width = width;
                    canvas.height = height;
                    ctx.drawImage(img, 0, 0, width, height);

                    try {
                        canvas.toBlob(
                            (blob) => {
                                if (blob) {
                                    resolve(blob);
                                } else {
                                    console.warn('toBlob returned null. Possibly tainted canvas or unsupported format.');
                                    reject(new Error('Canvas compression failed. Blob was null.'));
                                }
                            },
                            'image/jpeg',
                            9.1
                        );
                    } catch (err) {
                        console.error(' Error during canvas.toBlob execution:', err);
                        reject(new Error('Exception during canvas.toBlob: ' + err.message));
                    }
                } catch (error) {
                    reject(new Error('Error during image compression: ' + error.message));
                }
            };

            img.onerror = () => {
                reject(new Error('Error loading image.'));
            };

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

    // async handleSave() {
    //     this.load = true;
    //     try {
    //         const result = await updateWorkOrder({
    //             dataRec: this.wrapperData,
    //             recordId: this.recordId,
    //         });

    //         console.log('updateWorkOrder result::', result);

    //         if (result === 'success') {
    //             // await this.uploadImage(); // Wait for image upload
    //             var images = [];
    //             // var images=[];
    //             this.listPhotos.forEach(item => {
    //                 if (item.uploaded) {
    //                     var image = {
    //                         base64Data: item.base64Data,
    //                         fileName: item.fileName,
    //                         label: item.label
    //                     };
    //                     images.push(image);
    //                 }
    //             })

    //             saveImage({ listFiles: images, recordId: this.recordId })
    //                 .then(result => {
    //                     // console.log('saveImage result::' + JSON.stringify(result));
    //                     this.showToastMessage('Success', 'Meter Reading Saved Successfully', 'success');

    //                     if (this.recordId) {
    //                         this.load = false;
    //                         this.showOkModal = true;
    //                         //await this.handleRedirect(this.recordId);
    //                     } else {
    //                         console.error('recordId is undefined, cannot navigate.');
    //                     }
    //                 })
    //                 .catch(error => {
    //                     console.log('saveImage Error:' + JSON.stringify(error));
    //                     this.showToastMessage('Error', 'Something went wrong.', 'error', 'dismissable');
    //                     this.load = false;
    //                 });
    //             // this.listPhotos.forEach(item => {
    //             //     if (item.uploaded) {
    //             //         var image = {
    //             //             base64Data: item.base64Data,
    //             //             fileName: item.fileName,
    //             //             label: item.label
    //             //         };
    //             //         images.push(image);

    //             //         if(images.length==2){
    //             //             var result= this.saveImageFunc(images);
    //             //             images=[];
    //             //         }
    //             //     }
    //             // })
    //         } else {
    //             this.showToastMessage('Error', 'Error while saving meter reading', 'error', 'dismissable');
    //         }
    //         this.load = false;
    //     } catch (error) {
    //         this.load = false;
    //         console.error('updateWorkOrder error::', JSON.stringify(error));
    //         this.showToastMessage('Error', 'Unexpected error occurred', 'error', 'dismissable');
    //     }
    // }

    async handleSave() {
        this.load = true;

        try {
            if (!navigator.onLine) {
                /* ---------------- OFFLINE PARITY (LDS) ---------------- */
                await this.updateWorkOrderOffline();      // mirror Apex field updates on WO + SA
                await this.uploadImagesOffline();         // create ContentVersion + Document__c
                this.showToastMessage('Success', 'Meter Reading queued to sync', 'success');
                this.load = false;
                this.showOkModal = true;
                return;
            }

            /* ---------------- ONLINE (UNCHANGED) ---------------- */
            // Update Work Order record first
            const result = await updateWorkOrder({
                dataRec: this.wrapperData,
                recordId: this.recordId,
            });

            console.log('updateWorkOrder result::', result);

            if (result === 'success') {
                // Filter uploaded images
                const allImages = this.listPhotos
                    .filter(item => item.uploaded)
                    .map(item => ({
                        base64Data: item.base64Data,
                        fileName: item.fileName,
                        label: item.label
                    }));

                // Split into batches of 4 (or smaller if needed)
                const batchSize = 1;
                const batches = [];
                for (let i = 0; i < allImages.length; i += batchSize) {
                    batches.push(allImages.slice(i, i + batchSize));
                }

                var spinnerText = this.template.querySelector('.spinner-message');

                // Sequentially upload each batch
                for (let i = 0; i < batches.length; i++) {
                    console.log(`Uploading batch ${i + 1}/${batches.length}`);
                    if (spinnerText) {
                        spinnerText.style.setProperty('--spinner-text', `'Uploading Image (${i + 1}/${batches.length})'`);

                    }
                    await saveImage({ listFiles: batches[i], recordId: this.recordId });
                }

                //All done
                this.showToastMessage('Success', 'Meter Reading Saved Successfully', 'success');
                this.load = false;
                this.showOkModal = true;

            } else {
                this.showToastMessage('Error', 'Error while saving meter reading', 'error', 'dismissable');
                this.load = false;
            }

        } catch (error) {
            console.error('handleSave Error:', JSON.stringify(error));
            this.showToastMessage('Error', 'Unexpected error occurred', 'error', 'dismissable');
            this.load = false;
        }
    }

    async handleRedirect(recordId) {
        if (FORM_FACTOR === 'Large') {
            this.navigateToRecord(recordId);
        } else {
            this.navigateToWorkOrderInFSL(recordId);
        }
    }

    navigateToWorkOrderInFSL(recordId) {
        // this[NavigationMixin.Navigate]({
        //     type: 'standard__webPage',
        //     attributes: {
        //         // url: `com.salesforce.fieldservice://v1/customTab/Metering_Home`
        //         // url: 'com.salesforce.fieldservice://v1/home'
        //         url: `com.salesforce.fieldservice://v1/sObject/${recordId}/overview`
        //     }
        // });
        // setTimeout(() => {
        this.dispatchEvent(new CloseActionScreenEvent());
        // }, 500); // 300–500ms is usually sufficient

        // this[NavigationMixin.Navigate]({
        //     type: 'standard__webPage',
        //     attributes: {
        //         url: `com.salesforce.fieldservice://v1/sObject/${recordId}/overview`
        //     }
        // });
    }

    navigateToRecord(recordId) {
        if (navigator.onLine) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: recordId,
                    actionName: 'view',
                },
            });
        }

    }

    async uploadImage() {
        this.listPhotos.forEach(item => {
            if (item.uploaded) {
                var image = {
                    base64Data: item.base64Data,
                    fileName: item.fileName,
                    label: item.label
                };
                saveImage({ listFiles: [image], recordId: this.recordId })
            }
        })
    }

    async saveImageFunc(images) {
        await saveImage({ listFiles: images, recordId: this.recordId })
    }

    checkOut = false;
    handleGetLocation() {
        this.refreshWired();
        if (FORM_FACTOR === 'Large') {
            var result = this.getBrowserLocation();
        } else {
            var result = this.getMobileLocation();
        }
    }

    lat;
    long;
    getBrowserLocation() {
        this.load = true;
        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition(
                (position) => {
                    var latitude = position.coords.latitude;
                    var longitude = position.coords.longitude;
                    this.lat = latitude;
                    this.long = longitude;

                    console.log('actualCoords::' + JSON.stringify(this.actualCoords));
                    if (this.actualCoords == null && this.geoFence) {
                        this.showToastMessage('Error', 'Account geolocation not available.', 'error');
                        this.load = false;
                        return;
                    }
                    if (this.geoFence) {
                        var result = this.checkGeoFence(this.actualCoords.latitude, this.actualCoords.longitude, this.lat, this.long, this.geoDistance);
                        console.log('Geo fence result::' + JSON.stringify(result));
                        if (result.isOutOfBoundary) {
                            if (result.actualDistance == null) {
                                this.showToastMessage('Error', 'You are not in the geo fence.', 'error');
                            } else {
                                this.showToastMessage('Error', 'You are not in the geo fence. Distance: ' + result.actualDistance + 'm.', 'error');
                            }
                            this.load = false;
                            return;
                        }
                    }
                    this.updateCheckInDetails();
                    // this.load = false;
                },
                (error) => {
                    this.showToastMessage('Error', 'Please enable your device location', 'error');
                    this.load = false;
                }
            );
        } else {
            this.showToastMessage('Error', 'Geolocation is not supported by this browser', 'error');
            this.load = false;
        }
    }
    getMobileLocation() {
        this.load = true;
        const locationService = getLocationService();
        if (!locationService || !locationService.isAvailable()) {
            this.showToastMessage('LocationService Not Available', 'Please use a GPS-enabled mobile device and ensure location is turned on.', 'error');
            return;
        }
        const options = {
            enableHighAccuracy: true
        };
        locationService.getCurrentPosition(options)
            .then(result => {
                console.log('Location result:', result);
                this.lat = result.coords.latitude;
                this.long = result.coords.longitude;
                console.log('actualCoords::' + JSON.stringify(this.actualCoords));
                if (this.actualCoords == null && this.geoFence) {
                    this.showToastMessage('Error', 'Account geolocation not available.', 'error');
                    this.handleActionClick('Error', 'Account geolocation not available.', 'error');
                    this.load = false;
                    return;
                }
                else if (this.geoFence) {
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
                        this.load = false;
                        return;
                    }
                    else{
                        result = this.updateCheckInDetails();
                    }
                }else{
                    result = this.updateCheckInDetails();
                }
                // this.load = false;
            })
            .catch(error => {
                console.error('Location error:', error);
                this.showToastMessage('Error', 'Please enable your device location.', 'error');
                this.load = false;
            })
    }

    updateCheckInDetails() {
        this.load = true;
        console.log(' this.workOrderId::' + this.workOrderId);

        /* ONLINE (unchanged) */
        if (navigator.onLine) {
            workOrderCheckIn({
                workOrderId: this._recordId,
                latitude: this.lat,
                longitude: this.long
            })
                .then(result => {
                    console.log('updateCheckInDetails result::' + JSON.stringify(result));
                    // this.showToastMessage('Success', 'Record updated successfully!', 'success');
                    if (!this.checkOut) {
                        this.handleStartMetering();
                        this.checkOut = true;
                    } else {
                        this.wrapperData.latitude = this.lat;
                        this.wrapperData.longitude = this.long;
                        this.handleSave();
                    }
                })
                .catch(error => {
                    this.load = false;
                    console.log('updateCheckInDetails error::' + JSON.stringify(error));
                    this.showToastMessage('Error', 'Something went wrong.', 'error');
                });
            return;
        }

        /* OFFLINE: mark check-in on WO + SA via LDS */
        updateRecord({
            fields: {
                Id: this._recordId,
                Check_In__c: true,
                Check_In_Date_Time__c: new Date().toISOString(),
                Check_In_Location__Latitude__s: this.lat,
                Check_In_Location__Longitude__s: this.long
            }
        })
            .then(async () => {
                // If we have an SA (via GraphQL wire), mark it In Progress
                if (this.serviceAppointmentId) {
                    // try {
                    //     await updateRecord({ fields: { Id: this.serviceAppointmentId, Status: 'In Progress' } });
                    // } catch (e) { /* ignore queue errors */ }
                }
                if (!this.checkOut) {
                    this.handleStartMetering();
                    this.checkOut = true;
                } else {
                    this.wrapperData.latitude = this.lat;
                    this.wrapperData.longitude = this.long;
                    this.handleSave();
                }
            })
            .catch(() => {
                this.load = false;
                this.showToastMessage('Error', 'Offline check-in failed', 'error');
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

    /* -------------------- ADDED: LDS/GraphQL OFFLINE HELPERS -------------------- */

    /* LDS: get WO and Account (for offline hydration) */
    @wire(getRecord, {
        recordId: '$_recordId', fields: [
            WO_ID, WO_ACCOUNT, WO_APPT_STATUS, WO_TURBINE, WO_PRESSURE, WO_TEMP, WO_UV, WO_CV, WO_CF, WO_REMARKS
        ]
    }) woRec;

    get accountId() {
        return this.woRec?.data?.fields?.AccountId?.value || null;
    }

    @wire(getRecord, {
        recordId: '$accountId', fields: [
            ACC_NAME, ACC_PHONE, ACC_BP, ACC_CA, ACC_METER, ACC_ADDR1, ACC_ADDR2, ACC_CITY, ACC_POSTAL
        ]
    }) accRec({ data }) {
        if (data && !this.account) {
            const f = data.fields;
            this.account = {
                Id: data.id,
                Name: f.Name?.value,
                Phone: f.Phone?.value,
                BP_Number__c: f.BP_Number__c?.value,
                CA_Number__c: f.CA_Number__c?.value,
                Meter_Number__c: f.Meter_Number__c?.value,
                Building_name__c: f.Building_name__c?.value,
                Road_name__c: f.Road_name__c?.value,
                City__c: f.City__c?.value,
                Postal_Code__c: f.Postal_Code__c?.value
            };
            this.error = false;
            this.errorMessage = '';
        }
    }

    /* GraphQL: ServiceAppointment under WorkOrder (first SA id) */
    get relatedVars() { return { woId: this._recordId }; }

    @wire(graphql, { query: SERVICE_APPT_QUERY, variables: '$relatedVars' })
    saWire({ data, errors }) {
        if (data) {
            this.serviceAppointmentId = data?.uiapi?.query?.ServiceAppointment?.edges?.[0]?.node?.Id || null;
        }
    }

    /* GraphQL: Attached ContentDocuments (to mirror Apex delete in offline save) */
    @wire(graphql, { query: ATTACHED_DOC_QUERY, variables: '$relatedVars' })
    docWire({ data }) {
        this.relatedDocs = (data?.uiapi?.query?.ContentDocumentLink?.edges || []).map(e => e.node.ContentDocumentId.value);
    }

    get docMasterVars() { return { type: 'MRS Start Metering' }; }
    @wire(graphql, { query: DOC_MASTER_QUERY, variables: '$docMasterVars' })
    docMasterWire({ data }) {
        if (data && (!this.listPhotos || this.listPhotos.length === 0)) {
            const edges = data.uiapi.query.Document_Master__c.edges || [];
            const sorted = [...edges].sort((a, b) => {
                const av = a?.node?.Order__c?.value ?? 0;
                const bv = b?.node?.Order__c?.value ?? 0;
                return av - bv;
            });
            this.listPhotos = sorted.map(e => ({
                label: e.node.Document_Name__c.value,
                id: e.node.Id,
                name: e.node.Document_Name__c.value,
                uploaded: false,
                previewUrl: '',
                fileName: '',
                compress: e.node.Compress_Image__c.value
            }));
        }
    }

    //     @wire(graphql, { query: DOC_MASTER_QUERY, variables: '$docMasterVars' })
    // docMasterWire({ data, errors }) {
    //     if (errors && errors.length) {
    //         console.error('GraphQL Errors:', JSON.stringify(errors));
    //         this.showToastMessage('Error', 'GraphQL failed to load templates', 'error', 'dismissable');
    //         return;
    //     }

    //     if (data) {
    //         const edges = data.uiapi.query.Document_Master__c.edges || [];
    //         const docs = edges.map(e => ({
    //             id: e.node.Id,
    //             name: e.node.Document_Name__c?.value || '',
    //             order: e.node.Order__c?.value,
    //             type: e.node.Type__c?.value,
    //             compress: e.node.Compress_Image__c?.value
    //         }));

    //         console.log('⚡ Offline GraphQL Records:', docs);
    //         console.log(`⚡ Total from GraphQL: ${docs.length}`);

    //         // Expected total (based on your metadata setup)
    //         const EXPECTED_COUNT = 11;

    //         if (docs.length < EXPECTED_COUNT) {
    //             // Step 1: identify which record is missing (compare to known list)
    //             const expectedNames = [
    //                 'MRS Front Image',
    //                 'MRS Back Image',
    //                 'MRS Left Side Image',
    //                 'MRS Right Side Image', // 👈 this one suspected missing
    //                 'MRS Top Image',
    //                 'MRS Bottom Image',
    //                 'Meter Display Closeup',
    //                 'Meter Number Plate',
    //                 'Customer Premise Photo',
    //                 'Pipeline Connection',
    //                 'Meter Surrounding'
    //             ];

    //             const presentNames = docs.map(d => d.name);
    //             const missingNames = expectedNames.filter(n => !presentNames.includes(n));

    //             // Step 2: detect possible skip reason
    //             let skipReason = 'Unknown (record not found in offline cache)';
    //             if (missingNames.length) {
    //                 skipReason =
    //                     'Likely missing from offline cache or filtered by GraphQL (check Type__c, Active__c, Order__c, or briefcase sync).';
    //             } else if (docs.some(d => d.order == null)) {
    //                 skipReason = 'Record(s) with null Order__c are skipped by GraphQL orderBy.';
    //             }

    //             // Step 3: show diagnostic toast
    //             this.showToastMessage(
    //                 'Warning',
    //                 `Only ${docs.length} of ${EXPECTED_COUNT} templates found offline. Missing: ${missingNames.join(', ') || 'unknown'}. Possible reason: ${skipReason}`,
    //                 'warning',
    //                 'sticky'
    //             );
    //         }

    //         // Continue normal mapping for LWC display
    //         const sorted = [...edges].sort((a, b) => {
    //             const av = a?.node?.Order__c?.value ?? 0;
    //             const bv = b?.node?.Order__c?.value ?? 0;
    //             return av - bv;
    //         });

    //         this.listPhotos = sorted.map(e => ({
    //             label: e.node.Document_Name__c.value,
    //             id: e.node.Id,
    //             name: e.node.Document_Name__c.value,
    //             uploaded: false,
    //             previewUrl: '',
    //             fileName: '',
    //             compress: e.node.Compress_Image__c.value
    //         }));
    //     }
    // }


    get wsVars() {
        return { woId: this._recordId, stepName: START_STEP_NAME };
    }

    @wire(graphql, { query: WS_STEP_QUERY, variables: '$wsVars' })
    wsWire({ data, errors }) {
        this.workStepId = data?.uiapi?.query?.WorkStep?.edges?.[0]?.node?.Id || null;
    }


    async updateWorkOrderOffline() {
        await updateRecord({
            fields: {
                Id: this.recordId,
                Turbine_Meter_Reading__c: this.wrapperData.turbineMeterReading,
                Pressure__c: this.wrapperData.pressure,
                Temperature__c: this.wrapperData.temperature,
                Uncorrected_Volume__c: this.wrapperData.uncorrectedVolume,
                Corrected_Volume__c: this.wrapperData.correctedVolume,
                Correction_Factor__c: this.wrapperData.correctionFactor,
                Meter_Image_Remark__c: this.wrapperData.meterImageRemark,
                Check_Out__c: true,
                Check_Out_Date_Time__c: new Date().toISOString(),
                Check_Out_Location__Latitude__s: this.wrapperData.latitude,
                Check_Out_Location__Longitude__s: this.wrapperData.longitude,
                Approval_Status__c: 'Submitted For Approval',
                Appointment_Status__c: 'Completed'
            }
        });

        if (this.serviceAppointmentId) {
            try {
                await updateRecord({ fields: { Id: this.serviceAppointmentId, Status: 'Completed' } });
            } catch (e) { }
        }

        if (this.workStepId) {
            try {
                await updateRecord({ fields: { Id: this.workStepId, Status: 'Completed' } });
            } catch (e) { }
        }

        for (const docId of this.relatedDocs || []) {
            try { await deleteRecord(docId); } catch (e) { }
        }
    }

    async uploadImagesOffline() {
        const toUpload = (this.listPhotos || []).filter(p => p.uploaded);
        const spinnerText = this.template.querySelector('.spinner-message');

        const wo = this.woRec?.data;
        const acc = this.account || {};
        const saId = this.serviceAppointmentId;
        const recId = wo?.id;


        for (let i = 0; i < toUpload.length; i++) {
            const p = toUpload[i];
            if (spinnerText) spinnerText.style.setProperty('--spinner-text', `'Queuing Image (${i + 1}/${toUpload.length})'`);

            const title = p.label || (p.fileName ? p.fileName.replace(/\.[^.]+$/, '') : 'Image');
            const path = p.fileName || `${title}.jpg`;

            await createRecord({
                apiName: CV_OBJECT.objectApiName,
                fields: {
                    Title: title,
                    PathOnClient: path,
                    VersionData: p.base64Data,
                    FirstPublishLocationId: recId
                }
            });




            await createRecord({
                apiName: DOC_OBJECT.objectApiName,
                fields: {
                    File_Name__c: path,
                    File_Type__c: p.label,
                    Work_Order__c: recId,
                    Type__c: 'Metering'
                }
            });
        }
    }

    normalizeWireError(err) {
        if (!err) return 'Unknown error';
        if (Array.isArray(err.body) && err.body.length) return err.body.map(e => e.message).join('; ');
        if (err.body && typeof err.body.message === 'string') return err.body.message;
        if (typeof err.message === 'string') return err.message;
        try { return JSON.stringify(err); } catch { return 'Unknown error'; }
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

    async handleActionClick(label,message, variant ) {
        await LightningAlert.open({
            message: message,
            theme: variant,
            label: label,
        });
    }
}