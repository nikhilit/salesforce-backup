/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 10-09-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   17-03-2025   Kartik Patkar, Appstrail   Initial Version
 * 2.0   06-06-2025   Shruthi                    Changed the handleChange function and added handleLookup Selection from line 429
**/
import {
    api,
    LightningElement,
    track
} from 'lwc';

// import verifiedIcon from '@salesforce/resourceUrl/verifiedIcon';

/* These are constants that are used to add or remove classes from the input box. */
const INPUT_BOX_CLASS = 'input-box';
const ACTIVE_GREY_CLASS = 'active-grey';
const ACTIVE_CLASS = 'active';
const ERROR_CLASS = 'error';
const FOCUS_CLASS = 'focus';

export default class CustomInputFieldComponent extends LightningElement {

    @api inputLabel = '';
    @api inputType = 'text';
    @api inputActive = false;
    // @api inputError = false;
    // @api inputValue = '';
    @track inputValueTemp = '';
    // @api options = [];
    // @api disabled = false;
    @api verified = false;
    @api required = false;
    @track inputValueLabel = '';
    @track inputErrorTemp = false;
    @api showInActive = false;
    @api placeholder = '';
    //
    @api row = 3;
    @api minDate;
    @api maxDate;
    @api suffixLabel;

    _focus = false;
    _disabled = false;
    _options = [];

    @api
    get options() {
        return this._options;
    }

    set options(value) {
        this._options = value;
        if (this.inputValueTemp && this.inputValueTemp != '') {
            if (this.showInActive) {
                this.inputValueLabel = this.inputValueTemp;
            } else {
                console.log('inputLabel::' + this.inputLabel);
                console.log('options::' + JSON.stringify(this._options));
                const found = this._options.find(element => element.value == this.inputValueTemp);
                if (found) {
                    // console.log('found::' + JSON.stringify(found));
                    this.inputValueLabel = found.label;
                }
            }
        } else {
            this.inputValueTemp = '';
            this.inputValueLabel = '';
        }
    }

    @api
    get disabled() {
        return this._disabled;
    }

    set disabled(value) {
        // console.log('disabled(value)::'+value);
        this._disabled = this.normalizeBoolean(value);
        // if(value=='true'){
        //     this._disabled=true;
        // }else{
        //     this._disabled=false;
        // }
        // console.log('this.inputLabel::'+this.inputLabel);
        // console.log('this._disabled::'+this._disabled);
    }

    @api
    disabledTrue() {
        this._disabled = true;
    }


    normalizeBoolean(value) {
        return typeof value === 'string' || !!value;
    }

    @api
    get inputValue() {
        return this.inputValueTemp;
    }

    set inputValue(value) {
        this.load = true;
        // console.log('inputValue::' + value);
        if (value == null || value == '') {
            this.inputValueTemp = '';
            this.inputValueLabel = '';
        } else {
            this.inputValueTemp = value;
            if (this.inputType == 'option') {
                this.comboBox = true;
                this.text = false;
                if (this.inputValueTemp && this.inputValueTemp != '') {
                    if (this.showInActive) {
                        this.inputValueLabel = this.inputValueTemp;
                    } else {
                        console.log('inputLabel::' + this.inputLabel);
                        console.log('options::' + JSON.stringify(this.options));
                        const found = this.options.find(element => element.value == this.inputValueTemp);
                        if (found) {
                            // console.log('found::' + JSON.stringify(found));
                            this.inputValueLabel = found.label;
                        }
                    }
                } else {
                    this.inputValueTemp = '';
                    this.inputValueLabel = '';
                }
            }
        }
    }

    @api
    get inputError() {
        return this.inputErrorTemp;
    }

    set inputError(value) {
        this.inputErrorTemp = value;
        this.setFieldError(value);
    }

    /* These are variables that are used to control the display of the input box. */
    comboBox = false;
    currency = false;
    showOptions = false;
    textarea = false;
    text = true;
    number = false;
    search = false;
    verifiedIcon = '';

    connectedCallback() {
        try {
            this.init();
        } catch (error) {
            console.log('error:::' + JSON.stringify(error));
        }

    }

    renderedCallback() {
        this.checkInputValue();
        this.setFieldGreyActive(this.inputActive);
        this.setFieldError(this.inputError);
        // this.selectedOption();
        if (this.showOptions) {
            this.applyFocus();
        }
        // this.init();
        //
        this.load = false;
    }

    /**
     * If the input type is 'option', then set the comboBox attribute to true, and if the input value
     * is not empty, then find the option with the value that matches the input value, and if found,
     * set the inputValueLabel attribute to the label of the found option
     */
    init() {
        // console.log('inputLabel::' + this.inputLabel);
        // console.log('inputValueTemp::' + this.inputValueTemp);
        console.log('inputType::' + this.inputType);
        this.search = false;
        if (this.inputType == 'option') {
            this.comboBox = true;
            this.text = false;
            this.number = false;
            if (this.inputValueTemp) {
                if (this.showInActive) {
                    this.inputValueLabel = this.inputValueTemp;
                } else {
                    const found = this.options.find(element => element.value == this.inputValueTemp);
                    if (found) {
                        // console.log('found::' + JSON.stringify(found));
                        this.inputValueLabel = found.label;
                    }
                }
            } else {
                this.inputValueTemp = '';
                this.inputValueLabel = '';
            }
        } else if (this.inputType == 'currency') {
            this.currency = true;
            this.text = false;
            this.number = false;
            // this.inputValue='';
            if (this.inputValueTemp == null) {
                this.inputValueTemp = '';
            }
        } else if (this.inputType == 'datetime-local') {
            if (this.inputValueTemp != '') {
                this.inputValueTemp = this.inputValueTemp.split('.')[0];
            }
        } else if (this.inputType == 'textarea') {
            this.textarea = true;
            this.text = false;
            this.number = false;
        } else if (this.inputType == 'number') {
            this.text = false;
            this.textarea = false;
            this.number = true;
        } else if (this.inputType == 'search') {
            this.text = false;
            this.textarea = false;
            this.number = false;
            this.search = true;
        } else {
            if (this.inputValueTemp == null) {
                this.inputValueTemp = '';
            }
        }
    }

    /**
     * If the input box has a value, add the focus class to the input box. If the input box does not
     * have a value, remove the focus class from the input box
     */
    checkInputValue() {
        let box = this.template.querySelector(".input-box");
        if (box) {
            box.classList.remove(FOCUS_CLASS);
        }
        if (this.inputType != 'option') {
            this.template.querySelectorAll(".field").forEach(item => {
                if (item.value) {
                    box.classList.add(FOCUS_CLASS);
                } else {
                    box.classList.remove(FOCUS_CLASS);
                }
            });
        } else {
            var inputBox = this.template.querySelector('.input-box');
            if ((this.inputValueTemp != '') && inputBox) {
                inputBox.classList.add(FOCUS_CLASS);
            } else {
                inputBox.classList.remove(FOCUS_CLASS);
            }
        }
    }

    /**
     * If the input is active, add the active-grey class to the input box
     * @param inputActive - Boolean. If true, the input box will be set to the active grey color.
     */
    setFieldGreyActive(inputActive) {
        if (inputActive) {
            var inputBox = this.template.querySelector('.input-box');
            if (inputBox) {
                inputBox.classList.add(ACTIVE_GREY_CLASS);
            }
        }
    }

    /**
     * If the inputError parameter is true, then add the error class to the input box
     * @param inputError - Boolean. If true, the input box will be highlighted in red.
     */
    setFieldError(inputError) {
        var inputBox = this.template.querySelector('.input-box');
        if (inputBox) {
            if (inputError) {
                inputBox.classList.add(ERROR_CLASS);
            } else {
                inputBox.classList.remove(ERROR_CLASS);
            }
        }
    }


    setFocusTrue(event) {
        this.setFocus(true, event);
    }

    unsetFocusFalse(event) {
        this.handleInputBlur(event);
        this.setFocus(false, event);
    }

    /**
     * If the input is in error, add the error class to the parent node. If the input is not in error,
     * add the focus class to the parent node if the input is in focus. If the input is not in focus,
     * remove the focus class from the parent node if the input is empty. If the input is not empty,
     * add the focus class to the parent node
     * @param on - Boolean - true if the input is focused, false if it's not
     * @param event - The event that triggered the action.
     */
    setFocus(on, event) {
        var element = this.template.activeElement;
        // console.log('element', element);
        if (this.inputError) {
            element.parentNode.classList.add(ERROR_CLASS);
        } else {
            if (on) {
                element.parentNode.classList.add(FOCUS_CLASS);
            } else {
                let box = this.template.querySelector(".input-box");
                box.classList.remove(FOCUS_CLASS);
                this.template.querySelectorAll(".field").forEach(item => {
                    if (item.value) {
                        box.classList.add(FOCUS_CLASS);
                    } else {
                        box.classList.remove(FOCUS_CLASS);
                    }
                });
            }
        }
    }

    //COMBO BOX FUNCTIONS

    /**
     * It takes the value of the selected option and sets the inputValue to the value of the selected
     * option
     * @param event - The event object that is passed to the event handler.
     */
    handleOptionSelect(event) {
        var labelValue = event.currentTarget.dataset.label;
        var nameValue = event.currentTarget.dataset.name;
        this.inputValueTemp = nameValue;
        if (this.inputValueTemp != '') {
            const found = this.options.find(element => element.value == this.inputValueTemp);
            // console.log('found::' + JSON.stringify(found));
            this.inputValueLabel = found.label;
            this.showOptions = false;
        }
        this.selectedOption();
        // console.log('inputValue::' + this.inputValue);
    }

    /**
     * If the showOptions variable is true, then add the focus class to the input box. If the
     * showOptions variable is false, then remove the focus class from the input box
     * @param event - The event object that is passed to the event handler.
     */
    handleShowOption(event) {
        this.showOptions = !this.showOptions;
        var inputBox = this.template.querySelector('.input-box');
        // console.log('inputBox', inputBox);
        if (this.showOptions) {
            inputBox.classList.add(FOCUS_CLASS);
        } else {
            inputBox.classList.remove(FOCUS_CLASS);
        }
    }

    /**
     * If the input value is not empty, add the focus class to the input box. If the input value is
     * empty, remove the focus class from the input box
     */
    selectedOption(event) {
        if (this.inputType == 'option') {
            var inputBox = this.template.querySelector('.input-box');
            if (this.inputValueTemp != '') {
                inputBox.classList.add(FOCUS_CLASS);
            } else {
                inputBox.classList.remove(FOCUS_CLASS);
            }
            var value = {
                value: this.inputValueTemp
            };
            const valueSelectedEvent = new CustomEvent('change', {
                event,
                detail: value
            });
            this.dispatchEvent(valueSelectedEvent);
        }
    }

    /**
     * When the user clicks away from the dropdown, the dropdown will close after 300 milliseconds
     */
    onBlur() {
        this.blurTimeout = setTimeout(() => {
            this.showOptions = false;
            // this.selectedOption();
        }, 300);
    }

    applyFocus() {
        var optionBox = this.template.querySelector('.slds-dropdown');
        if (optionBox) {
            optionBox.focus();
        }
    }

    handleBlur() {
        // const valueSelectedEvent = new CustomEvent('blur', {});
        // this.dispatchEvent(valueSelectedEvent);
        this.blurTimeout = setTimeout(() => {
            this.showOptions = false;
            // this.selectedOption();
        }, 300);
    }

    handleInputBlur(event) {
        var value = {
            value: this.inputValueTemp
        };
        const valueSelectedEvent = new CustomEvent('blur', {
            event,
            detail: value
        });
        this.dispatchEvent(valueSelectedEvent);
    }


    /**
     * The function takes the value of the input field and creates a custom event with the value as the
     * detail
     * @param event - The event object that was fired.
     */
    handleChange(event) {
        // var value=event.target.value;
        var value = {
            value: event.target.value
        };
        // if(event.target.value!='' || event.target.value){
        //     value={value:event.target.value};
        // }else{
        //     value={value:null};
        // }
        // console.log('value::' + value);
        const valueSelectedEvent = new CustomEvent('change', {
            event,
            detail: value
        });
        this.dispatchEvent(valueSelectedEvent);
    }



}