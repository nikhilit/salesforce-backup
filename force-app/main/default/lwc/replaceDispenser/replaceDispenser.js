/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 29-01-2026
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   28-01-2026   Kartik Patkar, Appstrail   Initial Version
**/
import { LightningElement, api, wire } from 'lwc';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { getRecord } from 'lightning/uiRecordApi';

import replaceDispenserPoint from '@salesforce/apex/WorkOrderVisitController.replaceDispenserPoint';
import canReplaceDispenser from '@salesforce/apex/WorkOrderVisitController.canReplaceDispenser';
import getDispenserPoints from '@salesforce/apex/WorkOrderVisitController.getDispenserPoints';

import DISPENSER_NAME_FIELD from '@salesforce/schema/Dispenser_Point__c.Dispenser_Name__c';
import WORKORDER_FIELD from '@salesforce/schema/Dispenser_Point__c.WorkOrderID__c';

const FIELDS = [DISPENSER_NAME_FIELD, WORKORDER_FIELD];

export default class ReplaceDispenser extends LightningElement {

    @api reactiveValue = [];
    @api selectedIds = [];

    showModal = false;
    isLoading = false;
    formReady = false;

    openingReading = '';
    closingReading = '';
    difference = 0;
    actualRecordId;
    oldDispenserName = '';
    newDispenserName = '';
    workOrderId;

    @wire(getRecord, { recordId: '$actualRecordId', fields: FIELDS })
    wiredDispenser({ error, data }) {
        if (data) {
            this.oldDispenserName = data.fields.Dispenser_Name__c.value;
            this.workOrderId = data.fields.WorkOrderID__c.value;
            
            // After getting dispenser details, fetch all dispensers for calculation
            if (this.workOrderId) {
                this.fetchAllDispensers();
            }
        } else if (error) {
            console.error('Error fetching dispenser:', error);
        }
    }

    // Modal properties
    modalTitle = '';
    modalMessage = '';
    modalVariant = 'info'; // 'success', 'error', 'warning', 'info'
    modalCallback = null;
    primaryButtonLabel = 'OK';
    primaryButtonVariant = 'brand';
    secondaryButtonLabel = '';
    showSecondaryButton = false;

    connectedCallback() {
        if (this.reactiveValue?.length > 0) {
            this.selectedIds = this.reactiveValue;
        }

        const validIds = this.cleanAndValidateIds(
            this.selectedIds.length > 0 ? this.selectedIds : this.reactiveValue
        );

        if (validIds.length > 0) {
            this.actualRecordId = validIds[0];

            if (validIds.length > 1) {
                this.showNotification('Info', 'Multiple records selected. Select one to continue.', 'info', () => {
                    //this.checkIfCanReplace();
                    this.goBack();
                });
            } else {
                this.checkIfCanReplace();
            }
        } else {
            this.showNotification('Error', 'No valid record selected.', 'error', () => {
                setTimeout(() => this.goBack(), 400);
            });
        }
    }

    checkIfCanReplace() {
        this.isLoading = true;

        canReplaceDispenser({ dispenserId: this.actualRecordId })
            .then(result => {
                this.isLoading = false;

                if (result === false) {
                    this.showNotification(
                        'Cannot Replace Dispenser',
                        'This dispenser is already replaced. Please select another dispenser to continue.',
                        'error',
                        () => setTimeout(() => this.goBack(), 400)
                    );
                } else {
                    this.formReady = true;
                }
            })
            .catch(error => {
                this.isLoading = false;
                this.showNotification(
                    'Validation Failed',
                    error?.body?.message || 'Unable to validate the dispenser. Please try again.',
                    'error',
                    () => setTimeout(() => this.goBack(), 400)
                );
            });
    }

    fetchAllDispensers() {
        if (!this.workOrderId) return;

        getDispenserPoints({ workOrderId: this.workOrderId })
            .then(dispensers => {
                this.calculateNewDispenserName(dispensers);
            })
            .catch(error => {
                console.error('Error fetching dispensers:', error);
                this.newDispenserName = 'Unable to calculate';
            });
    }

    calculateNewDispenserName(dispensers) {
        // Extract base name from old dispenser (e.g., "Point_1" from "Point_1_New_2")
        const baseMatch = this.oldDispenserName.match(/^(Point_\d+)(?:_New_\d+)?$/);
        if (!baseMatch) {
            this.newDispenserName = 'Unknown';
            return;
        }
        
        const baseName = baseMatch[1];
        
        // Count how many _New_ versions already exist for this base
        const existingNewVersions = dispensers.filter(d => 
            d.Dispenser_Name__c && d.Dispenser_Name__c.startsWith(baseName + '_New_')
        );
        
        const nextNumber = existingNewVersions.length + 1;
        this.newDispenserName = `${baseName}_New_${nextNumber}`;
    }

    handleSave() {
        if (!this.formReady) return;

        if (!this.openingReading || !this.closingReading) {
            this.showNotification(
                'Missing Readings',
                'Please enter both Opening and Closing readings to proceed.',
                'warning'
            );
            return;
        }

        const opening = parseFloat(this.openingReading);
        const closing = parseFloat(this.closingReading);

        if (closing < opening) {
            this.showNotification(
                'Invalid Readings',
                'The Closing reading must be greater than or equal to the Opening reading.',
                'warning'
            );
            return;
        }

        this.isLoading = true;

        replaceDispenserPoint({
            newDispenser: {
                Opening_Reading__c: opening,
                Closing_Reading__c: closing,
                Live__c: true
            },
            oldDispenserId: this.actualRecordId
        })
        .then(() => {
            this.isLoading = false;

            this.showNotification(
                'Success',
                'Dispenser replaced successfully!',
                'success',
                () => {
                    // 🔥 Force Salesforce refresh
                    notifyRecordUpdateAvailable([{ recordId: this.actualRecordId }]);
                    setTimeout(() => this.goBack(), 400);
                }
            );
        })
        .catch(error => {
            this.isLoading = false;
            this.showNotification(
                'Save Failed',
                error?.body?.message || 'Unable to save the dispenser replacement. Please try again.',
                'error'
            );
        });
    }


    handleCancel() {
        this.goBack();
    }

    handlePrimaryAction() {
        this.showModal = false;
        if (this.modalCallback) {
            this.modalCallback();
        }
    }

    handleSecondaryAction() {
        this.showModal = false;
    }

    goBack() {
        window.history.back();
        setTimeout(() => window.location.reload(), 800);
    }

    cleanAndValidateIds(ids) {
        if (!ids || ids.length === 0) return [];

        return ids.filter(id =>
            typeof id === 'string' &&
            /^[a-zA-Z0-9]{15}$|^[a-zA-Z0-9]{18}$/.test(id)
        );
    }

    calculateDifference() {
        const opening = parseFloat(this.openingReading) || 0;
        const closing = parseFloat(this.closingReading) || 0;
        this.difference = closing - opening;
    }

    handleOpeningReadingChange(event) {
        this.openingReading = event.target.value;
        this.calculateDifference();
    }

    handleClosingReadingChange(event) {
        this.closingReading = event.target.value;
        this.calculateDifference();
    }

    showNotification(title, message, variant = 'info', callback = null) {
        this.modalTitle = title;
        this.modalMessage = message;
        this.modalVariant = variant;
        this.modalCallback = callback;
        this.primaryButtonLabel = 'OK';
        this.showSecondaryButton = false;

        // Set styling based on variant
        switch (variant) {
            case 'success':
                this.primaryButtonVariant = 'success';
                break;
            case 'error':
                this.primaryButtonVariant = 'destructive';
                break;
            case 'warning':
                this.primaryButtonVariant = 'destructive';
                break;
            default:
                this.primaryButtonVariant = 'brand';
        }

        this.showModal = true;
    }

    get modalHeaderClass() {
        const baseClass = 'slds-modal__header';
        const themeMap = {
            success: 'slds-theme_success',
            error: 'slds-theme_error',
            warning: 'slds-theme_warning',
            info: 'slds-theme_info'
        };
        return `${baseClass} ${themeMap[this.modalVariant] || themeMap.info}`;
    }

    get modalIconName() {
        const iconMap = {
            success: 'utility:success',
            error: 'utility:error',
            warning: 'utility:warning',
            info: 'utility:info'
        };
        return iconMap[this.modalVariant] || iconMap.info;
    }

    get modalIconVariant() {
        const variantMap = {
            success: 'success',
            error: 'error',
            warning: 'warning',
            info: 'info'
        };
        return variantMap[this.modalVariant] || variantMap.info;
    }

    get modalIconClass() {
        return 'slds-align_absolute-center';
    }

    get showForm() {
        return this.formReady && !this.isLoading;
    }
}