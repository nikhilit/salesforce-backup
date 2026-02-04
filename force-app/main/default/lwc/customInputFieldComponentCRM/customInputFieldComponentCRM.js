import { api, LightningElement, track } from 'lwc';

const INPUT_BOX_CLASS = 'input-box';
const ACTIVE_GREY_CLASS = 'active-grey';
const ERROR_CLASS = 'error';
const FOCUS_CLASS = 'focus';

export default class CustomInputFieldComponentCRM extends LightningElement {
    @api inputLabel = '';
    @api inputType = 'text';
    @api inputActive = false;
    @api options = [];
    @api verified = false;
    @api required = false;
    @api showInActive = false;
    @api placeholder = '';
    @api row = 3;
    @api name;
    @api value;

    @track inputValueTemp = '';
    @track inputValueLabel = '';
    @track inputErrorTemp = false;
    @track filteredOptions = [];
    @track showOptions = false;
    @track isMouseOverDropdown = false;

    comboBox = false;
    currency = false;
    textarea = false;
    text = true;
    number = false;
    search = false;
    verifiedIcon = '';
    scrollHandlerBound = null;
    _disabled = false;
    _focus = false;
    load = false;
    blurTimeout = null;

    connectedCallback() {
        try {
            this.filteredOptions = [...(this.options || [])];
            this.init();
            this.setupEventListeners();
            window.addEventListener('keydown', this._handleGlobalKeyDown,true);
        } catch (error) {
            console.error('connectedCallback error:', error);
        }
    }

    disconnectedCallback() {
        this.removeEventListeners();
        window.removeEventListener('keydown', this._handleGlobalKeyDown);
        if (this.blurTimeout) {
            clearTimeout(this.blurTimeout);
        }
    }

    setupEventListeners() {
        // Add mouseenter/mouseleave for dropdown hover detection
        this.template.addEventListener('mouseenter', this.handleMouseEnter.bind(this), true);
        this.template.addEventListener('mouseleave', this.handleMouseLeave.bind(this), true);
        
        // Add scroll listener
        this.scrollHandlerBound = this.handleWindowScroll.bind(this);
        window.addEventListener('scroll', this.scrollHandlerBound, true);
    }

    removeEventListeners() {
        this.template.removeEventListener('mouseenter', this.handleMouseEnter.bind(this), true);
        this.template.removeEventListener('mouseleave', this.handleMouseLeave.bind(this), true);
        
        if (this.scrollHandlerBound) {
            window.removeEventListener('scroll', this.scrollHandlerBound, true);
            this.scrollHandlerBound = null;
        }
    }

    handleMouseEnter() {
        this.isMouseOverDropdown = true;
    }

    handleMouseLeave() {
        this.isMouseOverDropdown = false;
    }

    handleWindowScroll() {
        if (this.showOptions) {
            this.closeDropdown();
        }
    }

   /* renderedCallback() {
        try {
            this.checkInputValue();
            this.setFieldGreyActive(this.inputActive);
            this.setFieldError(this.inputError);
            if (this.showOptions) {
                this.applyFocus();
            }
            this.load = false;
        } catch (error) {
            console.error('renderedCallback error:', error);
        }
          try {
        this.checkInputValue();
        this.setFieldGreyActive(this.inputActive);
        this.setFieldError(this.inputError);
        if (this.showOptions) {
            this.applyFocus();
        }

        // Prevent key shortcuts (e.g. 1, 2, e, etc.) from propagating
        const dropdown = this.template.querySelector('.slds-dropdown');
        const button = this.template.querySelector('button.combo-box');

        [dropdown, button].forEach(el => {
            if (el && !el.hasKeydownFix) {
                el.addEventListener('keydown', e => {
                    e.preventDefault();
                    e.stopPropagation();
                });
                el.hasKeydownFix = true;
            }
        });

        this.load = false;
    } catch (error) {
        console.error('renderedCallback error:', error);
    }
    }*/
    renderedCallback() {
    try {
        this.checkInputValue();
        this.setFieldGreyActive(this.inputActive);
        this.setFieldError(this.inputError);
        if (this.showOptions) {
            this.applyFocus();
        }

        // 🔒 Prevent key events (like 'e') from triggering Salesforce global shortcuts
        const dropdown = this.template.querySelector('.slds-dropdown');
        const button = this.template.querySelector('button.combo-box');
        const field = this.template.querySelector('.field'); // This is the actual input element

        // Block key events for dropdown and combo-box button
        [dropdown, button].forEach(el => {
            if (el && !el.hasKeydownFix) {
                el.addEventListener('keydown', e => {
                    e.preventDefault();
                    e.stopPropagation();
                });
                el.hasKeydownFix = true;
            }
        });

        // Block key events in input field to prevent 'e' triggering Edit mode
        if (field && !field.hasKeydownFix) {
            field.addEventListener('keydown', e => {
                if (e.key === 'e' || e.key === 'E') {
                   // e.preventDefault();
                  //  e.stopPropagation();
                    console.log('Blocked E key in input field');
                }
            });
            field.hasKeydownFix = true;
        }

        this.load = false;
    } catch (error) {
        console.error('renderedCallback error:', error);
    }
}



    get isTypeOrSubType() {
        return ['Type__c', 'Sub_Type__c', 'Department__c', 'Category__c','Type_Of_Document__c',
        'Priority','Sub_Origin__c','Origin','Mode_Of_Payment__c','Account_Type__c','Transfer_Type__c',
        'Value_8__c','Value_7__c','Value_6__c','Value_5__c','Value_4__c','Value_3__c',
        'Value_2__c','Value_1__c'].includes(this.name);
    }

    handleFocus() {
        this.filteredOptions = [...(this.options || [])];
    this.openDropdown();

    // Focus the actual input element to prevent global shortcuts like "e"
    const inputEl = this.template.querySelector('input');
    if (inputEl) {
        inputEl.focus();
    }

    }

    // handleKeyDown(event) {
    //     if (this.isTypeOrSubType) {
    //         const inputChar = event.key.toLowerCase();
    //         if (inputChar.length === 1 && /[a-z0-9]/i.test(inputChar)) {
    //             this.filterOptions(inputChar);
    //         }
    //     }
    // }
  

    filterOptions(char) {
        this.filteredOptions = (this.options || []).filter(opt =>
            opt?.label?.toLowerCase().startsWith(char)
        );
    }

    // handleOptionSelect(event) {
    //     try {
    //         const selectedValue = event.currentTarget?.dataset?.name;
    //         const selectedLabel = event.currentTarget?.dataset?.label;

    //         if (!selectedValue || !selectedLabel) {
    //             console.warn('Invalid selection');
    //             return;
    //         }

    //         this.inputValueTemp = selectedValue;
    //         this.inputValueLabel = selectedLabel;
    //         this.closeDropdown();

    //         this.dispatchEvent(new CustomEvent('change', {
    //             detail: { 
    //                 value: selectedValue, 
    //                 label: selectedLabel,
    //                 name: this.name
    //             },
    //             bubbles: true, 
    //             composed: true
    //         }));
    //     } catch (error) {
    //         console.error('handleOptionSelect error:', error);
    //     }
    // }

    // handleBlur() {
    //     this.blurTimeout = setTimeout(() => {
    //         if (!this.isMouseOverDropdown) {
    //             this.closeDropdown();
    //         }
    //     }, 200);
    // }
    
@track searchKeyword = ''; // Store what the user types

// 🔁 Open/Close Dropdown
handleShowOption(event) {
    event.stopPropagation();
    this.toggleDropdown();

    // ⌨️ Focus the dropdown div for key events
    setTimeout(() => {
        const dropdown = this.template.querySelector('.slds-dropdown');
        if (dropdown) {
            dropdown.focus();
        }
    }, 0);
}

handleKeyDown(event) {
    if (!this.isTypeOrSubType) return;
    const key = event.key;
     console.log('bsnxbbsjxaksj',key);
 if (key == 'e') {
    console.log('bsnxbbsjxaksj',key);
        event.preventDefault();
        event.stopPropagation();
    }
    // Allow letters, numbers, symbols
    if (/^[a-zA-Z0-9&@().\-_ ]$/.test(key)) {
        this.searchKeyword += key;
    } else if (key === 'Backspace') {
        this.searchKeyword = this.searchKeyword.slice(0, -1);
    } else if (key === 'Escape') {
        this.searchKeyword = '';
        this.closeDropdown();
        return;
    } else {
        return;
    }

    // Show the typed value in the button label
  //  this.inputValueLabel = this.searchKeyword;

    // 🟡 Float the label up when typing starts
    const box = this.template.querySelector('.input-box');
    if (box) {
        if (this.searchKeyword && this.searchKeyword.length > 0) {
            box.classList.add('focus');
        } else {
            box.classList.remove('focus');
        }
    }

    // 🔍 Filter dropdown options
    this.filteredOptions = (this.options || []).filter(opt =>
        opt?.label?.toLowerCase().includes(this.searchKeyword.toLowerCase())
    );
}
_handleGlobalKeyDown = (event) => {
    const isInside = this.template.contains(document.activeElement);

    if (isInside && (event.key === 'e' || event.key === 'E')) {
        event.preventDefault();
        event.stopPropagation();
        console.log('Blocked global E shortcut inside component');
    }
};




// ✅ Handle selection from dropdown
handleOptionSelect(event) {
    const selectedValue = event.currentTarget?.dataset?.name;
    const selectedLabel = event.currentTarget?.dataset?.label;

    if (!selectedValue || !selectedLabel) return;

    this.inputValueTemp = selectedValue;
    this.inputValueLabel = selectedLabel;
    this.searchKeyword = ''; // 🔁 Reset typed keyword
    this.closeDropdown();

    this.dispatchEvent(new CustomEvent('change', {
        detail: {
            value: selectedValue,
            label: selectedLabel,
            name: this.name
        },
        bubbles: true,
        composed: true
    }));
}

// 🔚 Close dropdown on blur
handleBlur() {
    this.blurTimeout = setTimeout(() => {
        if (!this.isMouseOverDropdown) {
            this.closeDropdown();
            this.searchKeyword = ''; // Clear typed search
        }
    }, 200);
}

    toggleDropdown() {
        if (this.showOptions) {
            this.closeDropdown();
        } else {
            this.openDropdown();
        }
    }

    openDropdown() {
        if (this.showOptions || this._disabled) return;
        
        // Clear any pending blur timeout
        if (this.blurTimeout) {
            clearTimeout(this.blurTimeout);
            this.blurTimeout = null;
        }

        this.showOptions = true;
        const inputBox = this.template.querySelector('.input-box');
        if (inputBox) {
            inputBox.classList.add(FOCUS_CLASS);
        }
        
        // Refresh filtered options
        this.filteredOptions = [...(this.options || [])];
    }

    closeDropdown() {
        if (!this.showOptions) return;
        
        this.showOptions = false;
        const inputBox = this.template.querySelector('.input-box');
        if (inputBox && !this.inputValueTemp) {
            inputBox.classList.remove(FOCUS_CLASS);
        }
    }

    // handleShowOption(event) {
    //     event.stopPropagation();
    //     this.toggleDropdown();
    // }

    @api
    get disabled() {
        return this._disabled;
    }

    set disabled(value) {
        this._disabled = typeof value === 'string' || !!value;
        if (this._disabled && this.showOptions) {
            this.closeDropdown();
        }
    }

    @api
    disabledTrue() {
        this._disabled = true;
        if (this.showOptions) {
            this.closeDropdown();
        }
    }

    @api
    get inputValue() {
        return this.inputValueTemp;
    }

    set inputValue(value) {
        try {
            this.load = true;
            if (value == null || value === '') {
                this.inputValueTemp = '';
                this.inputValueLabel = '';
                return;
            }

            this.inputValueTemp = value;

            if (this.inputType === 'option') {
                const found = (this.options || []).find(o => o.value == value);
                this.inputValueLabel = found?.label || (this.showInActive ? value : '');
            } else {
                this.inputValueLabel = value;
            }
        } catch (error) {
            console.error('inputValue setter error:', error);
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

    checkInputValue() {
        const box = this.template.querySelector('.input-box');
        if (!box) return;

        box.classList.remove(FOCUS_CLASS);

        if (this.inputType !== 'option') {
            const fields = this.template.querySelectorAll('.field');
            fields.forEach(item => {
                if (item?.value) {
                    box.classList.add(FOCUS_CLASS);
                }
            });
        } else if (this.inputValueTemp) {
            box.classList.add(FOCUS_CLASS);
        }
    }

    setFieldGreyActive(active) {
        const box = this.template.querySelector('.input-box');
        if (box) {
            box.classList.toggle(ACTIVE_GREY_CLASS, active);
        }
    }

    setFieldError(isError) {
        const box = this.template.querySelector('.input-box');
        if (box) {
            box.classList.toggle(ERROR_CLASS, isError);
        }
    }

    setFocus(on) {
        const element = this.template.activeElement;
        if (!element || !element.parentNode) return;

        if (this.inputError) {
            element.parentNode.classList.add(ERROR_CLASS);
        } else {
            element.parentNode.classList.toggle(FOCUS_CLASS, on);
        }
    }

    handleInputBlur() {
        this.dispatchEvent(new CustomEvent('blur', {
            detail: { 
                value: this.inputValueTemp,
                name: this.name
            },
            bubbles: true,
            composed: true
        }));
    }

    @api
    reset() {
        this.inputValue = '';
        this.inputValueLabel = '';
        this.filteredOptions = [...(this.options || [])];
        this.inputError = false;

        const inputElm = this.template.querySelector('.field');
        if (inputElm) inputElm.value = '';

        const box = this.template.querySelector('.input-box');
        if (box) {
            box.classList.remove(FOCUS_CLASS, ACTIVE_GREY_CLASS, ERROR_CLASS);
        }

        this.init();
    }

    init() {
        try {
            // Reset all type flags
            this.comboBox = false;
            this.currency = false;
            this.textarea = false;
            this.number = false;
            this.search = false;
            this.text = true; // Default to true unless another type is specified

            // Set the appropriate type flag
            switch (this.inputType) {
                case 'option':
                    this.comboBox = true;
                    this.text = false;
                    break;
                case 'currency':
                    this.currency = true;
                    this.text = false;
                    break;
                case 'textarea':
                    this.textarea = true;
                    this.text = false;
                    break;
                case 'number':
                    this.number = true;
                    this.text = false;
                    break;
                case 'search':
                    this.search = true;
                    this.text = false;
                    break;
                default:
                    this.text = true;
            }

            // Special handling for datetime-local
            if (this.inputType === 'datetime-local' && this.inputValueTemp) {
                this.inputValueTemp = this.inputValueTemp.split('.')[0];
            }

            // Handle combo box initialization
            if (this.comboBox && this.inputValueTemp) {
                const found = (this.options || []).find(el => el.value == this.inputValueTemp);
                this.inputValueLabel = found?.label || (this.showInActive ? this.inputValueTemp : '');
            }

            // Initialize empty values
            if (this.inputValueTemp == null) {
                this.inputValueTemp = '';
                this.inputValueLabel = '';
            }
        } catch (error) {
            console.error('init() error:', error);
        }
    }

    applyFocus() {
        // Small delay to ensure dropdown is rendered
        setTimeout(() => {
            const optionBox = this.template.querySelector('.slds-dropdown');
            if (optionBox) optionBox.focus();
        }, 50);
    }

    handleChange(event) {
        // event.preventDefault();
        //event.stopPropagation();
        const fieldName = this.name;
        const value = event.target.value;
        this.inputValueTemp = value;
        
        this.dispatchEvent(new CustomEvent('change', {
            detail: { 
                name: fieldName, 
                inputValue: value,
                label: this.inputType === 'option' ? this.inputValueLabel : value
            },
            bubbles: true,
            composed: true
        }));
    }

    setFocusTrue(event) {
        this.setFocus(true, event);
    }

    unsetFocusFalse(event) {
        this.handleInputBlur(event);
        this.setFocus(false, event);
    }
}