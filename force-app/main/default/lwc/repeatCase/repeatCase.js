import { LightningElement, api, track, wire } from 'lwc';
import handleRepeatCase from '@salesforce/apex/RepeatCaseController.handleRepeatCase';
import getContactDirectionPicklistValues from '@salesforce/apex/RepeatCaseController.getContactDirectionPicklistValues';
import getRepeatOriginPicklistValues from '@salesforce/apex/RepeatCaseController.getRepeatOriginPicklistValues';
import getRepeatPicklistDetails from '@salesforce/apex/RepeatCaseController.getRepeatPicklistDetails';
import getAttendanceStatus from '@salesforce/apex/AgentAttendanceController.getAttendanceStatus';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import IS_CLOSED from '@salesforce/schema/Case.IsClosed';
import { getRecord } from 'lightning/uiRecordApi';

export default class RepeatCase extends LightningElement {
    @api recordId;
    internalComment = '';
    selectedOrigin = '';
    selectedContactDirection = '';
    contactedBy = ''; 
    relationshipToOwner = ''; 
    originOptions = [];
    contactDirectionOptions = [];
    isClosed;
    isLoading = false;
    attendanceStatus = '';
    callReceivedFrom = '';

    @wire(getRecord, { recordId: '$recordId', fields: [IS_CLOSED] })
    wiredCase({ data, error }) {
        if (data) {
            this.isClosed = data.fields.IsClosed.value;
            console.log('Case IsClosed:', this.isClosed);
        } else if (error) {
            console.error('Error fetching IsClosed:', error);
        }
    }

    connectedCallback() {
        console.log('ConnectedCallback fired');
        
        // Load REPEAT ORIGIN picklist values (NOT Case Origin)
        // getRepeatOriginPicklistValues()
        //     .then(data => {
        //         console.log('Repeat Origin picklist values:', data);
        //         this.originOptions = data.map(val => ({
        //             label: val,
        //             value: val
        //         }));
        //         console.log('Origin options set:', this.originOptions);
        //     })
        //     .catch(error => {
        //         console.error('Error fetching repeat origin picklist:', error);
        //         this.showToast('Error', 'Failed to load origin options: ' + error.body?.message, 'error');
        //     });

        getRepeatPicklistDetails()
        .then(result => {
            // result.repeatOriginDetails = [{ label, value, apiValue }, ...]
            if (result && result.repeatOriginDetails) {
                this.originOptions = result.repeatOriginDetails.map(d => ({
                    label: d.label,
                    value: d.apiValue  // <-- IMPORTANT: value is API value now
                }));
                console.log('Origin options with API values set:', JSON.stringify(this.originOptions));
            } else {
                console.warn('No repeatOriginDetails returned from Apex', result);
            }
        })
        .catch(error => {
            console.error('Error fetching repeat origin picklist details:', error);
            this.showToast('Error', 'Failed to load origin options: ' + (error.body?.message || error.message), 'error');
        });

        getContactDirectionPicklistValues()
            .then(data => {
                console.log('Contact Direction picklist values:', data);
                this.contactDirectionOptions = data.map(val => ({
                    label: val,
                    value: val
                }));
                console.log('Contact Direction options set:', this.contactDirectionOptions);
            })
            .catch(error => {
                console.error('Error fetching contact direction picklist:', error);
                this.showToast('Error', 'Failed to load contact direction options', 'error');
            });

        getAttendanceStatus()
            .then(status => {
                console.log('Attendance Status:', status);
                this.attendanceStatus = status;
            })
            .catch(error => {
                console.error('Error fetching attendance status:', error);
            });
    }

    get showCallReceivedFrom() {
        const o = String(this.selectedOrigin || '');
        // set of API values that should show the field
        const telephoneApiValues = new Set(['1','12','13','14','15','20','21']);
        const result = telephoneApiValues.has(o);
        console.log('showCallReceivedFrom -> selectedOrigin =', o, ', show =', result);
        return result;
    }



    validateContactNumber(contactNumber) {
        contactNumber = contactNumber ? contactNumber.replace(/[\s\-()]/g, '') : '';
        const phoneRegex = /^[6-9]\d{9}$/; // indian 10-digit starting 6-9

        if (!contactNumber) {
            return { isValid: false, message: 'Contact number is required.' };
        } else if (!phoneRegex.test(contactNumber)) {
            return { isValid: false, message: 'Please enter a valid 10-digit mobile number.' };
        } else {
            return { isValid: true, message: '' };
        }
    }



    handleCallReceivedFromChange(event) {
        const newVal = (event.detail && event.detail.inputValue) ? event.detail.inputValue : event.target.value;
        console.log('handleCallReceivedFromChange ->', newVal);
        this.callReceivedFrom = newVal;
    }


    handleCommentChange(event) {
        this.internalComment = event.target.value;
    }

    handleOriginChange(event) {
        // const val = event.detail.value;
        // console.log('handleOriginChange -> selected value:', val);

        // // keep the combobox value
        // this.selectedOrigin = val;

        const apiVal = event.detail.value;
        console.log('handleOriginChange -> selected API value:', apiVal);

        // Keep combobox visible selection
        this.selectedOrigin = apiVal;

        // Also store a label if you want (for debug)
        const selectedOption = this.originOptions.find(o => o.value === apiVal);
        const label = selectedOption ? selectedOption.label : null;
        console.log('handleOriginChange -> selected label:', label);

        // keep old form compatibility (if some code still reads this.form)
        this.form = {
            ...this.form,
            Origin: apiVal
        };

        // debug
        console.log('this.selectedOrigin set to:', this.selectedOrigin);
        console.log('this.form.Origin set to (API value):', this.form.Origin);

    }


    handleContactDirectionChange(event) {
        this.selectedContactDirection = event.detail.value;
        console.log('Selected Contact Direction:', this.selectedContactDirection);
    }

    handleContactedByChange(event) {
        this.contactedBy = event.target.value;
    }

    handleRelationshipToOwnerChange(event) {
        this.relationshipToOwner = event.target.value;
    }

    handleSubmit() {
        console.log('Submit button clicked');
        console.log('Selected Origin:', this.selectedOrigin);
        console.log('Selected Contact Direction:', this.selectedContactDirection);

        if (this.attendanceStatus === 'Checked Out') {
            this.showToast('Warning', 'You are checked out. Please check in to create a repeat case.', 'warning');
            return;
        }

        if (this.attendanceStatus === 'On Break') {
            this.showToast('Warning', 'You are currently on a break. Please end your break before creating a repeat case.', 'warning');
            return;
        }

        if (!this.selectedOrigin) {
            this.showToast('Error', 'Please select an Origin.', 'error');
            return;
        }

        // ----- Call Received From validation when Origin is in list -----
        if (this.showCallReceivedFrom) {
            const callFrom = (this.callReceivedFrom || '').trim();
            console.log('Validating Call Received From ->', callFrom);
            if (!callFrom) {
                this.showToast('Error', 'Call Received From cannot be blank.', 'error');
                this.isLoading = false;
                return;
            }
            const cv = this.validateContactNumber(callFrom);
            if (!cv.isValid) {
                this.showToast('Error', cv.message, 'error');
                this.isLoading = false;
                return;
            }
        }


        if (this.isClosed) {
            this.showToast('Error', 'You cannot tag a repeat case on a resolved case.', 'error');
            return;
        }

        this.isLoading = true;

        handleRepeatCase({
            currentCaseId: this.recordId,
            internalComment: this.internalComment,
            origin: this.selectedOrigin,
            contactedBy: this.contactedBy,
            relationshipToOwner: this.relationshipToOwner,
            contactDirection: this.selectedContactDirection,
            callReceivedFrom: this.callReceivedFrom
        })
        .then(result => {
            this.isLoading = false;
            console.log('Repeat case created successfully:', result);
            this.showToast('Success', 'Repeat case created successfully.', 'success');
            this.resetForm();
            
            setTimeout(() => {
                eval("$A.get('e.force:refreshView').fire();");
            }, 1000);
        })
        .catch(error => {
            this.isLoading = false;
            console.error('Full error:', JSON.stringify(error, null, 2));
            
            let errorMessage = 'An error occurred while creating the repeat case.';
            if (error && error.body) {
                errorMessage = error.body.message || errorMessage;
            }
            
            this.showToast('Error', errorMessage, 'error');
        });
    }

    resetForm() {
        this.internalComment = '';
        this.selectedOrigin = '';
        this.selectedContactDirection = '';
        this.contactedBy = ''; 
        this.relationshipToOwner = ''; 
        this.callReceivedFrom = '';
        
        // Reset form elements
        const inputs = this.template.querySelectorAll('lightning-input, lightning-textarea, lightning-combobox');
        inputs.forEach(input => {
            if (input.type === 'combobox') {
                input.value = '';
            } else {
                input.value = '';
            }
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ 
            title, 
            message, 
            variant 
        }));
    }
}