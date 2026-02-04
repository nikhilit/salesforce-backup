import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import replaceDispenserPoint from '@salesforce/apex/WorkOrderVisitController.replaceDispenserPoint';

export default class DispenserReplace extends LightningElement {
    @api recordId;

    isLoading = false;
    openingReading = '';
    closingReading = '';
    difference = 0;
    dispenserNameDisplay = 'Create Dispenser: Point_1_New_1';

    connectedCallback() {
        console.log('=== Dispenser Replace Component ===');
        console.log('recordId received:', this.recordId);
        
        if (!this.recordId) {
            console.warn('WARNING: recordId is undefined!');
            console.log('Component properties:', this);
        }
    }

    handleOpeningReadingChange(event) {
        this.openingReading = event.target.value;
        this.calculateDifference();
    }

    handleClosingReadingChange(event) {
        this.closingReading = event.target.value;
        this.calculateDifference();
    }

    calculateDifference() {
        const opening = parseFloat(this.openingReading) || 0;
        const closing = parseFloat(this.closingReading) || 0;
        this.difference = closing - opening;
    }

    handleSave() {
        if (!this.openingReading || !this.closingReading) {
            this.showToast('Warning', 'Please enter both Opening and Closing readings', 'warning');
            return;
        }

        const opening = parseFloat(this.openingReading);
        const closing = parseFloat(this.closingReading);

        if (closing < opening) {
            this.showToast('Warning', 'Closing Reading should be equal or greater than Opening Reading', 'warning');
            return;
        }

        if (!navigator.onLine) {
            this.showToast('Info', 'Replace requires online connection.', 'info');
            return;
        }

        if (!this.recordId) {
            this.showToast('Error', 'Record ID is missing. Please try again.', 'error');
            return;
        }

        this.isLoading = true;

        const newDispenser = {
            Opening_Reading__c: opening,
            Closing_Reading__c: closing,
            Live__c: true
        };

        console.log('Calling Apex with:', {
            newDispenser: newDispenser,
            oldDispenserId: this.recordId
        });

        replaceDispenserPoint({ newDispenser: newDispenser, oldDispenserId: this.recordId })
            .then(() => {
                console.log('Apex call successful');
                this.showToast('Success', 'New dispenser record created successfully!', 'success');
                this.isLoading = false;

                setTimeout(() => {
                    this.closeIfQuickAction();
                    location.reload();
                }, 1000);
            })
            .catch(error => {
                this.isLoading = false;
                console.error('Apex error:', error);
                const errorMessage = error?.body?.message || 'An error occurred while creating the dispenser';
                this.showToast('Error', errorMessage, 'error');
            });
    }

    handleCancel() {
        this.closeIfQuickAction();
    }

    closeIfQuickAction() {
        try {
            this.dispatchEvent(new CloseActionScreenEvent());
            console.log('Quick Action context - modal closed');
        } catch (e) {
            console.log('Not in quick action context - may be in flow');
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
                mode: 'dismissable'
            })
        );
    }
}