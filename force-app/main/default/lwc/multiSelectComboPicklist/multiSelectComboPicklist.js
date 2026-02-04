import { LightningElement, track, wire, api } from 'lwc';

export default class MultiSelectComboPicklist extends LightningElement {
    @api label;
    @api placeholder = 'Select Options';
    @api options = [];
    
    @track isOpen = false;
    @track searchTerm = '';
    @track _selectedValues = [];

    // Use getter/setter for selectedValues to track changes
    @api 
    get selectedValues() {
        return this._selectedValues;
    }

    set selectedValues(value) {
        this._selectedValues = value || [];
    }

    get comboBoxClass() {
        return `slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click ${this.isOpen ? 'slds-is-open' : ''}`;
    }

    // REMOVED outside click handler temporarily

    get hasOptions() {
        const hasOpts = this.options && this.options.length > 0;
        return hasOpts;
    }

    get hasNoOptions() {
        return !this.hasOptions;
    }

    get filteredOptions() {
        if (!this.hasOptions) {
            return [];
        }
        
        if (!this.searchTerm) {
            return this.options;
        }
        
        const searchLower = this.searchTerm.toLowerCase();
        return this.options.filter(option => 
            option.label.toLowerCase().includes(searchLower)
        );
    }

    get filteredOptionsWithSelection() {
        const filtered = this.filteredOptions;
        return filtered.map(option => ({
            ...option,
            selected: this._selectedValues.includes(option.value)
        }));
    }

    get selectedOptions() {
        if (!this.hasOptions || !this._selectedValues) return [];
        return this.options.filter(option => 
            this._selectedValues.includes(option.value)
        );
    }

    get displayValue() {
        if (!this._selectedValues || this._selectedValues.length === 0) {
            return this.placeholder;
        }
        
        const selectedLabels = this.selectedOptions.map(option => option.label);
        return selectedLabels.length > 2 
            ? `${selectedLabels.length} options selected`
            : selectedLabels.join(', ');
    }

    get allSelected() {
        return this.filteredOptions.length > 0 && 
               this.filteredOptions.every(option => this._selectedValues.includes(option.value));
    }

    get noResults() {
        return this.filteredOptions.length === 0;
    }

    toggleDropdown(event) {
        event.preventDefault();
        event.stopPropagation();
        
        if (!this.hasOptions) {
            return;
        }
        
        this.isOpen = !this.isOpen;
        this.searchTerm = '';
    }

    handleSearch(event) {
        this.searchTerm = event.target.value;
    }

    handleSelectAll(event) {
        const isChecked = event.target.checked;
        
        if (isChecked) {
            // Add all filtered options
            const filteredValues = this.filteredOptions.map(option => option.value);
            const newSelectedValues = [...new Set([...this._selectedValues, ...filteredValues])];
            this.updateSelectedValues(newSelectedValues);
        } else {
            // Remove all filtered options
            const filteredValues = this.filteredOptions.map(option => option.value);
            const newSelectedValues = this._selectedValues.filter(value => !filteredValues.includes(value));
            this.updateSelectedValues(newSelectedValues);
        }
    }

    handleCheckboxChange(event) {
        const value = event.target.dataset.value;
        const isChecked = event.target.checked;
        
        let newSelectedValues = [...this._selectedValues];
        
        if (isChecked) {
            if (!newSelectedValues.includes(value)) {
                newSelectedValues.push(value);
            }
        } else {
            newSelectedValues = newSelectedValues.filter(item => item !== value);
        }
        
        this.updateSelectedValues(newSelectedValues);
    }

    handleRemovePill(event) {
        const value = event.detail.name;
        
        const newSelectedValues = this._selectedValues.filter(item => item !== value);
        this.updateSelectedValues(newSelectedValues);
    }

    updateSelectedValues(newSelectedValues) {
        this._selectedValues = newSelectedValues;
        
        // Dispatch event to parent
        this.dispatchEvent(new CustomEvent('change', {
            detail: {
                selectedValues: newSelectedValues
            }
        }));
    }

    @api
    clearSelection() {
        this._selectedValues = [];
        this.searchTerm = '';
        this.isOpen = false;
        this.dispatchEvent(new CustomEvent('change', {
            detail: {
                selectedValues: []
            }
        }));
    }
}