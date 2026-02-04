import { LightningElement, track } from 'lwc';
import startBatchUpdate from '@salesforce/apex/AS_UpdateWorkOrderBatchController.startBatchUpdate';

export default class AsUpdateWorkOrderEndDate extends LightningElement {
    @track batchLot = '';
    @track endDate = '';
    @track message = '';
    @track error = '';
    @track isLoading = false;

    handleBatchLotChange(event) {
        this.batchLot = event.target.value;
    }

    handleEndDateChange(event) {
        this.endDate = event.target.value;
    }

    async handleUpdateClick() {
        this.message = '';
        this.error = '';
        this.isLoading = true;

        if (!this.batchLot || !this.endDate) {
            this.error = 'Please provide both Batch Lot and End Date.';
            this.isLoading = false;
            return;
        }

        try {
            const result = await startBatchUpdate({ batchLot: this.batchLot, endDate: this.endDate });
            this.message = result;
        } catch (err) {
            this.error = err.body ? err.body.message : err.message;
        } finally {
            this.isLoading = false;
        }
    }
}