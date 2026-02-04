import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import WORK_ORDER_TYPE_FIELD from '@salesforce/schema/WorkOrder.Work_Order_Type__c';

export default class WorkOrderExecutionParent extends LightningElement {
    @api recordId;
    @track workOrderType;
    @track isLoading = true;
    @track hasError = false;
    @track errorMessage = '';

    // Fetch Work Order Type dynamically
    @wire(getRecord, { recordId: '$recordId', fields: [WORK_ORDER_TYPE_FIELD] })
    wiredWorkOrder({ error, data }) {
        this.isLoading = false;
        if (data) {
            this.workOrderType = data.fields.Work_Order_Type__c.value;
            console.log('✅ Work Order Type:', this.workOrderType);
        } else if (error) {
            this.hasError = true;
            this.errorMessage = error.body?.message || 'Error loading Work Order Type';
            console.error('❌ Error loading Work Order Type:', error);
        }
    }

    // Show the appropriate child component
    get isAfterSalesService() {
        return this.workOrderType === 'After Sales Service';
    }

    get isAFSReconnectionDisconnection() {
        return this.workOrderType === 'AFS Reconnection Disconnection';
    }

    get isUnknownType() {
        return (
            this.workOrderType &&
            !this.isAfterSalesService &&
            !this.isAFSReconnectionDisconnection
        );
    }
}