/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 07-10-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   29-09-2025   Kartik Patkar, Appstrail   Initial Version
**/
import { api, LightningElement, track, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getMROData from '@salesforce/apex/MeteringAddMROtoMRSController.getMeterReadingOrderList';
import getCurrentMRURecord from '@salesforce/apex/MeteringAddMROtoMRSController.getCurrentMRURecord';
import addMRO from '@salesforce/apex/MeteringAddMROtoMRSController.addMRO';
export default class MeteringAddMROtoMRSComponent extends LightningElement {

    @track mRORecord = [];
    @track limitValue = 50;
    @track offset = 0;
    @track mRSRecord;
    @track isLoading = false;
    @track selectedMRORecords = [];
    allDataLoaded = false;
    _recordId;
    spinner = false;

    @api mrsDisabled = false;

    get disableLookup() {
        return !this.mrsDisabled;
    }

    @api
    set recordId(value) {
        this._recordId = value;
        this.init();
    }

    get recordId() {
        return this._recordId;
    }

    get recordCount() {
        if (this.allDataLoaded) {
            return this.mRORecord.length; // exact count
        } else {
            return `${this.mRORecord.length}+`; // show as "10+" etc.
        }
    }

    get mRSColumns() {
        return [
            {
                label: 'Name',
                fieldName: 'recordUrl',
                type: 'url',
                typeAttributes: {
                    label: { fieldName: 'Meter_Reading_Doc_Number__c' },
                    target: '_blank'
                }
            },
            { label: 'BP Number', fieldName: 'Business_Partner_Consumer_ID__c', type: 'text' },
            { label: 'MRU', fieldName: 'MRU__c', type: 'text' },
            { label: 'Meter Reader Name', fieldName: 'Meter_Reader_Name__c', type: 'text' },
            { label: 'Meter Reader Code', fieldName: 'Meter_Reader_Code__c', type: 'text' }
        ];
    }

    get showTable(){
        return (this.mRORecord!=null && this.mRORecord.length > 0);
    }

    connectedCallback() {
        this.loadData();
    }

    selectedMRSId;
    selectedMRSName;
    init() {
        getCurrentMRURecord({ recordId: this._recordId })
            .then(data => {
                this.mRSRecord = data;
                if (this.mRSRecord) {
                    this.selectedMRSId = this.mRSRecord.Id;
                    this.selectedMRSName = this.mRSRecord.MRS_Custom_Name__c;
                }
            })
            .catch(error => {
                console.error('Error:', error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    originalData = [];
    loadData() {
        // 🚫 Stop if already loading or all data loaded
        if (this.isLoading || this.allDataLoaded) {
            return;
        }

        this.isLoading = true;
        getMROData({ limitValue: this.limitValue, offset: this.offset })
            .then(data => {
                if (data && data.length > 0) {
                    const newData = data.map(record => ({
                        ...record,
                        recordUrl: '/' + record.Id
                    }));
                    this.mRORecord = [...this.mRORecord, ...newData];
                    this.originalData = JSON.parse(JSON.stringify([...this.originalData, ...newData]));
                    this.offset += this.limitValue;

                    // ✅ If fewer than limit returned → no more data left
                    if (data.length < this.limitValue) {
                        this.allDataLoaded = true;
                    }
                } else {
                    this.allDataLoaded = true;
                }
            })
            .catch(error => {
                console.error('Error:', error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleSearch(event) {
        const searchTerm = event.target.value ? event.target.value.toLowerCase() : '';

        if (!searchTerm) {
            this.mRORecord = [...this.originalData]; // reset if search is empty
            return;
        }

        this.mRORecord = this.originalData.filter(record => {
            return (
                (record.Meter_Reading_Doc_Number__c || '').toLowerCase().includes(searchTerm) ||
                (record.Business_Partner_Consumer_ID__c || '').toLowerCase().includes(searchTerm) ||
                (record.MRU__c || '').toLowerCase().includes(searchTerm) ||
                (record.Meter_Reader_Name__c || '').toLowerCase().includes(searchTerm) ||
                (record.Meter_Reader_Code__c || '').toLowerCase().includes(searchTerm)
            );
        });
    }

    handleScroll(event) {
        if (this.allDataLoaded || this.isLoading) {
            return; // 🚫 Prevent extra calls once data is exhausted
        }

        const { scrollTop, scrollHeight, offsetHeight } = event.target;
        if (Math.ceil(scrollTop) >= scrollHeight - offsetHeight) {
            this.loadData();
        }
    }

    getSelectedName(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedMRORecords = selectedRows;
    }

    get selectedMRORecCount() {
        return 'Selected Records: ' + this.selectedMRORecords.length;
    }

    handleSubmit() {
        this.spinner = true;
        if (this.selectedMRORecords.length == 0) {
            this.showToastMessage('Error', 'Please select at least one record', 'error', 'dismissable');
            this.spinner = false;
            return;
        }
        addMRO({ listMROs: this.selectedMRORecords, mruRec: this.mRSRecord })
            .then(result => {
                if (result == 'success') {
                    this.showToastMessage('Success', 'MROs added successfully', 'success', 'dismissable');
                } else {
                    this.showToastMessage('Error', 'No MROs found', 'error', 'dismissable');
                }
                this.handleCancel();
            })
            .catch(error => {
                console.error('Error:', error);
                this.showToastMessage('Error', 'Error while adding MROs', 'error', 'dismissable');
            })
            .finally(() => {
                this.spinner = false;
            });

    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
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

}