import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import FORM_FACTOR from '@salesforce/client/formFactor';

import asFieldSenseFlowLabel from "@salesforce/label/c.AS_FieldSenseFlowLabel";
import getAccountByBPNumber from '@salesforce/apex/RandomVisitlWCController.getAccountByBPNumber';
import createRandomPaymentWorkOrder from '@salesforce/apex/RandomVisitlWCController.createRandomPaymentWorkOrder';

import R_T_Flow from "@salesforce/label/c.R_T_Flow";
import { getRecord } from 'lightning/uiRecordApi';
import Id from '@salesforce/user/Id';
import ProfileName from '@salesforce/schema/User.Profile.Name';

export default class RandomVisitComponent extends NavigationMixin(LightningElement) {

    @track formData = {};
    @track load = false;

    userId = Id;
    userProfileName;
    error;
    label = { R_T_Flow };

    @api recordId;
    isCaNumber = false;
    isAccountName = false;
    isFieldSense = false;

    workTypeValue = '';
    workTypeOptions = [];

    @wire(getRecord, { recordId: Id, fields: [ProfileName] })
    userDetails({ error, data }) {
        if (error) {
            this.error = "Unknown error";
            if (Array.isArray(error.body)) {
                this.error = error.body.map((e) => e.message).join(", ");
            } else if (typeof error.body.message === "string") {
                this.error = error.body.message;
            }
            this.showToast('Error', this.error, 'error');
        } else if (data) {
            console.log('data: ' + JSON.stringify(data));

            if (data?.fields?.Profile?.value != null) {
                this.userProfileName = data.fields.Profile.value?.fields?.Name?.value;
                if (this.userProfileName == R_T_Flow) {
                    this.isFieldSense = true;
                }
            }
        }
    }

    capitalizeLabel(str) {
        return str
            .split(' ')
            .map(word => word.charAt(0).toUpperCase() + word.slice(1))
            .join(' ');
    }

    connectedCallback() {

        const labelValues = asFieldSenseFlowLabel
            .toLowerCase()
            .split(',')
            .map(item => item.trim());

        // Build combobox options using label values
        this.workTypeOptions = labelValues.map(val => {
            return {
                label: this.capitalizeLabel(val),
                value: val
            };
        });
    }

    handleBPNumberChange(event) {
        const bp = event.target.value;
        this.formData.BPNumber = bp;

        // In FieldSense mode — do not auto-fetch Account/CA
        if (this.isFieldSense) {
            return;
        }
        console.log('BP Number: ' + bp + ' length: ' + bp.length + ' isFieldSense: ' + this.isFieldSense + ' isCaNumber:')

        if (bp && bp.length >= 3) {
            getAccountByBPNumber({ bpNumber: bp })
                .then(result => {
                    if (result) {
                        this.formData.AccountId = result.Id;
                        this.formData.AccountName = result.Name;
                        this.formData.CANumber = result.CA_Number__c;

                        this.isCaNumber = true;
                        this.isAccountName = true;
                    } else {
                        this.resetAccountFields();
                    }
                })
                .catch(error => {
                    const errorMessage = error?.message || error?.body?.errorMessage || 'Error Fetching Account Details';
                    this.showToast('Error', `Error: ${errorMessage}`, 'error');
                    console.error('BP Lookup error:', JSON.stringify(error));
                    this.resetAccountFields();
                });
        } else {
            this.resetAccountFields();
        }
    }

    resetAccountFields() {
        this.formData.AccountId = null;
        this.formData.AccountName = null;
        this.formData.CANumber = null;
        this.isCaNumber = false;
        this.isAccountName = false;
    }

    handleInput(event) {
        this.formData[event.target.name] = event.target.value;
    }

    handleSubmit(event) {
        event.preventDefault();

        if (!this.isFieldSense && !this.formData.BPNumber) {
            this.showToast('Error', 'BP Number is required.', 'error');
            return;
        }
        if (!this.isFieldSense && !this.formData.AccountId) {
            this.showToast('Error', 'Enter valid BP Number.', 'error');
            return;
        }

        if (this.isFieldSense && !this.formData.CANumber) {
            this.showToast('Error', 'CANumber is required.', 'error');
            return;
        }

        if (this.isFieldSense && !this.formData.AccountName) {
            this.showToast('Error', 'Customer Name is required.', 'error');
            return;
        }

        if (this.isFieldSense && !this.formData.WorkType) {
            this.showToast('Error', 'Work Type is required.', 'error');
            return;
        }

        if (!this.isFieldSense && !this.formData.PaymentAmount) {
            this.showToast('Error', 'Payment is required.', 'error');
            return;
        }

        this.load = true;

        createRandomPaymentWorkOrder({ formData: this.formData, isFieldSense: this.isFieldSense })
            .then(result => {
                this.load = false;
                // // If Apex returned an error
                if (result?.status == 'error') {
                    this.showToast('Error', result.message || 'An error occurred.', 'error');
                    return;
                }

                if (result?.status == 'success') {
                    this.showToast('Success', `Random Payment Work Order created successfully. ${result.workOrderId}`, 'success');
                    this.navigateToWorkOrder(result.workOrderId);
                }
            })
            .catch(error => {
                this.load = false;

                // Extract apex error message safely
                let errorMessage =
                    error?.message ||
                    error?.body?.message ||
                    error?.body?.errorMessage ||
                    'Unexpected error occurred. Please contact your administrator.';

                this.showToast('Error', errorMessage, 'error');
            });

    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    navigateToWorkOrder(workOrderId) {
        if (FORM_FACTOR === 'Large') {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: workOrderId,
                    actionName: 'view',
                },
            });
        } else {
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: `com.salesforce.fieldservice://v1/sObject/${workOrderId}/overview`
                }
            });
        }
    }
}

// import { LightningElement, track, api, wire } from 'lwc';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import { NavigationMixin } from 'lightning/navigation';
// import FORM_FACTOR from '@salesforce/client/formFactor';

// import asFieldSenseFlowLabel from "@salesforce/label/c.AS_FieldSenseFlowLabel";
// import getAccountByBPNumber from '@salesforce/apex/RandomVisitlWCController.getAccountByBPNumber';
// import createRandomPaymentWorkOrder from '@salesforce/apex/RandomVisitlWCController.createRandomPaymentWorkOrder';

// import R_T_Flow from "@salesforce/label/c.R_T_Flow";
// import { getRecord } from 'lightning/uiRecordApi';
// import Id from '@salesforce/user/Id';
// import ProfileName from '@salesforce/schema/User.Profile.Name';

// export default class RandomVisitComponent extends NavigationMixin(LightningElement) {

//     @track formData = {};
//     @track load = false;

//     userId = Id;
//     userProfileName;
//     error;
//     label = { R_T_Flow };

//     @api recordId;
//     isCaNumber = false;
//     isAccountName = false;
//     isFieldSense = false;

//     workTypeValue = '';
//     workTypeOptions = [];

//     @wire(getRecord, { recordId: Id, fields: [ProfileName] })
//     userDetails({ error, data }) {
//         if (error) {
//             this.error = "Unknown error";
//             if (Array.isArray(error.body)) {
//                 this.error = error.body.map((e) => e.message).join(", ");
//             } else if (typeof error.body.message === "string") {
//                 this.error = error.body.message;
//             }
//             this.showToast('Error', this.error, 'error');
//         } else if (data) {
//             console.log('data: ' + JSON.stringify(data));

//             if (data?.fields?.Profile?.value != null) {
//                 this.userProfileName = data.fields.Profile.value?.fields?.Name?.value;
//                 if (this.userProfileName == R_T_Flow) {
//                     this.isFieldSense = true;
//                     this.showToast('Info', 'User Profile Name: ' + this.userProfileName, 'info');
//                 }
//             }
//         }
//     }

//     capitalizeLabel(str) {
//         return str
//             .split(' ')
//             .map(word => word.charAt(0).toUpperCase() + word.slice(1))
//             .join(' ');
//     }

//     connectedCallback() {

//         const labelValues = asFieldSenseFlowLabel
//             .toLowerCase()
//             .split(',')
//             .map(item => item.trim());

//         // Build combobox options using label values
//         this.workTypeOptions = labelValues.map(val => {
//             return {
//                 label: this.capitalizeLabel(val),
//                 value: val
//             };
//         });
//     }

//     handleBPNumberChange(event) {
//         const bp = event.target.value;
//         this.formData.BPNumber = bp;

//         // In FieldSense mode — do not auto-fetch Account/CA
//         if (this.isFieldSense) {
//             return;
//         }
//         console.log('BP Number: ' + bp + ' length: ' + bp.length + ' isFieldSense: ' + this.isFieldSense + ' isCaNumber:')

//         if (bp && bp.length >= 3) {
//             getAccountByBPNumber({ bpNumber: bp })
//                 .then(result => {
//                     if (result) {
//                         this.formData.AccountId = result.Id;
//                         this.formData.AccountName = result.Name;
//                         this.formData.CANumber = result.CA_Number__c;

//                         this.isCaNumber = true;
//                         this.isAccountName = true;
//                         this.showToast('Info', 'Account Details: ' + result.Name, 'info');
//                     } else {
//                         this.resetAccountFields();
//                     }
//                 })
//                 .catch(error => {
//                     const errorMessage = error?.message || error?.body?.errorMessage || 'Error Fetching Account Details';
//                     this.showToast('Error', `Error: ${errorMessage}`, 'error');
//                     console.error('BP Lookup error:', JSON.stringify(error));
//                     this.resetAccountFields();
//                 });
//         } else {
//             this.resetAccountFields();
//         }
//     }

//     resetAccountFields() {
//         this.formData.AccountId = null;
//         this.formData.AccountName = null;
//         this.formData.CANumber = null;
//         this.isCaNumber = false;
//         this.isAccountName = false;
//     }

//     handleInput(event) {
//         this.formData[event.target.name] = event.target.value;
//     }

//     handleSubmit(event) {
//         event.preventDefault();

//         if (!this.isFieldSense && !this.formData.BPNumber) {
//             this.showToast('Error', 'BP Number is required.', 'error');
//             return;
//         }
//         if (!this.isFieldSense && !this.formData.AccountId) {
//             this.showToast('Error', 'Enter valid BP Number.', 'error');
//             return;
//         }

//         if (this.isFieldSense && !this.formData.CANumber) {
//             this.showToast('Error', 'CANumber is required.', 'error');
//             return;
//         }

//         if (this.isFieldSense && !this.formData.AccountName) {
//             this.showToast('Error', 'Customer Name is required.', 'error');
//             return;
//         }

//         if (this.isFieldSense && !this.formData.WorkType) {
//             this.showToast('Error', 'Work Type is required.', 'error');
//             return;
//         }

//         this.load = true;

//         createRandomPaymentWorkOrder({ formData: this.formData, isFieldSense: this.isFieldSense })
//             .then(result => {
//                 this.load = false;
//                 // // If Apex returned an error
//                 if (result?.status == 'error') {
//                     this.showToast('Error', result.message || 'An error occurred.', 'error');
//                     return;
//                 }

//                 if (result?.status == 'success') {
//                     this.showToast('Success', 'Random Payment Work Order created successfully.', 'success');
//                     this.navigateToWorkOrder(result.workOrderId);
//                 }
//             })
//             .catch(error => {
//                 this.load = false;

//                 // Extract apex error message safely
//                 let errorMessage =
//                     error?.message ||
//                     error?.body?.message || 
//                     error?.body?.errorMessage || 
//                     'Unexpected error occurred. Please contact your administrator.';

//                 this.showToast('Error', errorMessage, 'error');
//             });

//     }

//     showToast(title, message, variant) {
//         this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
//     }

//     navigateToWorkOrder(workOrderId) {
//         if (FORM_FACTOR === 'Large') {
//             this[NavigationMixin.Navigate]({
//                 type: 'standard__recordPage',
//                 attributes: {
//                     recordId: workOrderId,
//                     actionName: 'view',
//                 },
//             });
//         } else {
//             this[NavigationMixin.Navigate]({
//                 type: 'standard__webPage',
//                 attributes: {
//                     url: `com.salesforce.fieldservice://v1/sObject/${workOrderId}/overview`
//                 }
//             });
//         }
//     }
// }