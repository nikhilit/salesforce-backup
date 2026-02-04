/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 22-07-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   10-11-2022   Kartik Patkar, Appstrail   Initial Version
 **/
import {
    api,
    LightningElement,
    track,
    wire
} from 'lwc';
import lookUp from '@salesforce/apex/CustomLookupController.search';

const INPUT_BOX_CLASS = 'input-box';
const ACTIVE_GREY_CLASS = 'active-grey';
const ACTIVE_CLASS = 'active';
const ERROR_CLASS = 'error';
const FOCUS_CLASS = 'focus';
export default class CustomLookupComponent extends LightningElement {
    @api objName;
    @api iconName = 'standard:record';
    @api filter = '';
    @api searchPlaceholder = 'Search';
    @api searchFieldName = 'Name';

    @api 
    get defaultName(){
        return this._defaultName;
    };

    set defaultName(value){
        if(value){
            this._defaultName=value;
            this.populateDefault();
        }
    }
    _defaultName='';

    @api inputLabel = '';
    @api uniqueId;
    @api disabled;
    @api required;
    @api inputType = 'text';

    @track selectedName;
    @track records;
    @track isValueSelected=false;
    @track blurTimeout;
    stopRecursion = false;
    @track searchTerm;
    //css
    @track boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus';
    @track inputClass = '';

    comboBox = false;
    showDropdown = false;

    @wire(lookUp, {
        searchTerm: '$searchTerm',
        myObject: '$objName',
        filter: '$filter',
        searchFieldName:'$searchFieldName'
    })
    wiredRecords({
        error,
        data
    }) {
        if (data) {
            this.error = undefined;
            this.records = data;
            console.log('this.records', this.records);
        } else if (error) {
            this.error = error;
            this.records = undefined;
        }
    }

    renderedCallback() {
        // if (!this.stopRecursion){
        //     this.populateDefault();
            this.selectedOption();
        // }

        // this.checkInputValue();
        // this.selectedOption();
    }

    connectedCallback() {
        console.log('objName= ' + this.objName);
        console.log('iconName= ' + this.iconName);
        console.log('filter= ' + this.filter);
        console.log('searchPlaceholder= ' + this.searchPlaceholder);
        console.log('defaultName= ' + this.defaultName);
    }

    populateDefault() {
        this.isValueSelected = false;
        console.log('inside populateDefault' + this.defaultName);
        console.log('filter= ' + this.filter);
        if (this.defaultName != '') {
            this.selectedName = this.defaultName;
            this.stopRecursion = true;
            this.isValueSelected = true;
            if (this.blurTimeout) {
                clearTimeout(this.blurTimeout);
            }
            this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus';
        }

    }


    handleClick() {
        this.searchTerm = '';
        this.inputClass = 'slds-has-focus';
        this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus slds-is-open';
        this.showDropdown = true;
    }

    onBlur() {
        this.blurTimeout = setTimeout(() => {
            this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus';
            this.showDropdown = false;
            // this.selectedOption();
            this.setFocus(false);
        }, 300);
    }

    onSelect(event) {
        let selectedId = event.currentTarget.dataset.id;
        let selectedName = event.currentTarget.dataset.name;
        let selectedRecord = {
            Id: selectedId,
            Name: selectedName,
            uniqueId: this.uniqueId
        }
        const valueSelectedEvent = new CustomEvent('lookupselected', {
            detail: selectedRecord
        });
        this.dispatchEvent(valueSelectedEvent);

        // var inputBox = this.template.querySelector('.input-box');
        // inputBox.classList.add(FOCUS_CLASS);

        this.isValueSelected = true;
        this.showDropdown = false;
        this.selectedName = selectedName;
        if (this.blurTimeout) {
            clearTimeout(this.blurTimeout);
        }
        this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus';
        this.selectedOption();
    }

    @api handleRemovePill() {
        this.isValueSelected = false;
        this.searchTerm='';
        this.selectedOption();
        const noValueSelectedEvent = new CustomEvent('nolookupselected', {
            detail: this.isValueSelected
        });
        this.dispatchEvent(noValueSelectedEvent);
    }

    onChange(event) {
        this.searchTerm = event.target.value;
        console.log('this.searchTerm:::' + this.searchTerm);
        this.selectedOption();
        // this.checkInputValue();
    }

    setFocusTrue() {
        this.setFocus(true);
    }

    unsetFocusFalse() {
        this.setFocus(false);
    }

    setFocus(on) {
        var element = this.template.activeElement;
        // console.log('element', element);
        // console.log('element.parentNode', element.parentNode);
        let box = this.template.querySelector(".input-box");
        if (this.inputError) {
            element.parentNode.classList.add(ERROR_CLASS);
        } else {
            if (on) {
                this.showDropdown = true;
                // element.parentNode.classList.add(FOCUS_CLASS);
                box.classList.add(FOCUS_CLASS);
            } else {
                box.classList.remove(FOCUS_CLASS);
                // this.template.querySelectorAll(".field").forEach(item => {
                //     if (item.value) {
                //         box.classList.add(FOCUS_CLASS);
                //     } else {
                //         box.classList.remove(FOCUS_CLASS);
                //     }
                // });
                // if (this.searchTerm != '') {
                //     box.classList.add(FOCUS_CLASS);
                // } else {
                //     box.classList.remove(FOCUS_CLASS);
                // }
            }
        }
    }

    checkInputValue() {
        let box = this.template.querySelector(".input-box");
        if (this.searchTerm != '') {
            box.classList.add(FOCUS_CLASS);
        } else {
            box.classList.remove(FOCUS_CLASS);
        }
    }

    selectedOption() {
        // console.log('selectedOption' + this.showOptions);
        var inputBox = this.template.querySelector('.input-box');
        // console.log('inputBox' + JSON.stringify(inputBox.classList));
        if (this.isValueSelected) {
            inputBox.classList.add(FOCUS_CLASS);
        } else {
            inputBox.classList.remove(FOCUS_CLASS);
            if (this.searchTerm) {
                inputBox.classList.add(FOCUS_CLASS);
            } else {
                inputBox.classList.remove(FOCUS_CLASS);
            }
        }
        // console.log('inputBox' + JSON.stringify(inputBox.classList));
    }
}