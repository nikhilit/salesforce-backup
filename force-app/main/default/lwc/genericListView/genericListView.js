import { LightningElement, api, track } from 'lwc';
import getListViewConfig from '@salesforce/apex/GenericListViewController.getListViewConfig';
import getRecords from '@salesforce/apex/GenericListViewController.getRecords';

export default class GenericListView extends LightningElement {
    @api objectApiName = 'WorkOrder';
    @track columns = [];
    @track filterFields = [];
    @track filters = {};
    @track records = [];

    connectedCallback() {
        this.loadConfig();
    }

    loadConfig() {
        getListViewConfig({ objectName: this.objectApiName })
            .then((result) => {
                this.columns = [];
                this.filterFields = [];

                result.forEach((cfg) => {
                    if (cfg.Show_in_List__c) {
                        this.columns.push({
                            label: cfg.Field_Label__c,
                            fieldName: cfg.Field_API_Name__c,
                            type: 'text'
                        });
                    }

                    if (cfg.Use_in_Filter__c) {
                        this.filterFields.push({
                            label: cfg.Field_Label__c,
                            apiName: cfg.Field_API_Name__c,
                            isText: cfg.Filter_Type__c === 'Text',
                            isPicklist: cfg.Filter_Type__c === 'Picklist',
                            isDate: cfg.Filter_Type__c === 'Date',
                            isLookup: cfg.Filter_Type__c === 'Lookup',
                            picklistValues: [] // Add support later
                        });
                    }
                });
            })
            .catch((error) => {
                console.error('Error loading config:', error);
            });
    }

    handleFilterChange(event) {
        const key = event.target.dataset.id;
        const range = event.target.dataset.range;

        if (range) {
            const compoundKey = `${key}_${range}`;
            this.filters[compoundKey] = event.target.value;
        } else {
            this.filters[key] = event.target.value;
        }
    }

    handleGlobalSearch(event) {
        this.filters['globalSearch'] = event.target.value;
    }

    searchRecords() {
        const fieldList = this.columns.map((c) => c.fieldName);
        const queryFilters = {};

        Object.keys(this.filters).forEach((key) => {
            if (key.endsWith('_from') || key.endsWith('_to')) {
                const base = key.replace(/_(from|to)/, '');
                queryFilters[base] = queryFilters[base] || {};
                queryFilters[base][key.endsWith('_from') ? 'from' : 'to'] = this.filters[key];
            } else if (key !== 'globalSearch') {
                queryFilters[key] = this.filters[key];
            }
        });

        getRecords({
            objectName: this.objectApiName,
            filters: queryFilters,
            fields: fieldList
        })
            .then((result) => {
                console.log('📦 Records Loaded:', result); // 🐞 Debug line
                this.records = result;
            })
            .catch((error) => {
                console.error('Error loading records:', error);
            });
    }
}