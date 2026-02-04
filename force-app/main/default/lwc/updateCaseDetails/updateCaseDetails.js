import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import saveCaseData from '@salesforce/apex/CaseQuickActionController.saveCaseData';
import getCurrentUserProfileName from '@salesforce/apex/CaseQuickActionController.getCurrentUserProfileName';
import getCurrentUserName from '@salesforce/apex/CaseQuickActionController.getCurrentUserName';
import getCaseStatus from '@salesforce/apex/CaseQuickActionController.getCaseStatus';
import getCaseDepartmentAndType from '@salesforce/apex/CaseQuickActionController.getCaseDepartmentAndType';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
import { getRecordNotifyChange } from 'lightning/uiRecordApi'; 

export default class CaseQuickActionWithComments extends NavigationMixin(LightningElement) {
    @api recordId;
    @track status;
    @track statusOptions = [];
    @track newComment = '';
    @track isLoading = false;
    currentCaseStatus;
    caseDepartment;
    caseType;    
    currentUserName;  

    profileStatusMap = {
        'CRM Front Office TeamLead': [
            { label: 'Customer Not Responded', value: 'Customer Not Responded' },
            { label: 'Resolved', value: 'Resolved' },
            { label: 'Not Actionable', value: 'Not Actionable' },
        ],
        'CRM BackOffice Agent': [
            { label: 'Pending with Customer', value: 'On Hold' },
            { label: 'Customer Not Responded', value: 'Customer Not Responded' },
            { label: 'Resolved', value: 'Resolved' },
            { label: 'Not Actionable', value: 'Not Actionable' },
        ],
        'CRM FrontOffice Agent': [
            { label: 'Customer Not Responded', value: 'Customer Not Responded' },
            { label: 'Resolved', value: 'Resolved' },
            { label: 'Not Actionable', value: 'Not Actionable' },
        ],
        'CRM CallCenter Agent': [
            { label: 'Customer Not Responded', value: 'Customer Not Responded' },
            { label: 'Resolved', value: 'Resolved' },
            { label: 'Not Actionable', value: 'Not Actionable' },
        ],
        'CRM Back Office TeamLead': [
            { label: 'Pending with Customer', value: 'On Hold' },
            { label: 'Customer Not Responded', value: 'Customer Not Responded' },
            { label: 'Resolved', value: 'Resolved' },
            { label: 'Not Actionable', value: 'Not Actionable' },
        ],
        'CRM Call Center TeamLead': [
            { label: 'Customer Not Responded', value: 'Customer Not Responded' },
            { label: 'Resolved', value: 'Resolved' },
            { label: 'Not Actionable', value: 'Not Actionable' }
        ],
        'System Administrator': [
            { label: 'New', value: 'New' },
            { label: 'Assigned', value: 'Assigned' },
            { label: 'In-Progress', value: 'In-Progress' },
            { label: 'Pending with Customer', value: 'On Hold' },
            { label: 'Customer Responded', value: 'Customer Responded' },
            { label: 'Actioned by Department', value: 'Actioned by Department' },
            { label: 'Resolved', value: 'Resolved' },
            { label: 'Not Actionable', value: 'Not Actionable' },
            { label: 'Resolved by CRM', value: 'Resolved by CRM' },
            { label: 'Customer Not Responded', value: 'Customer Not Responded' }
        ],
        'CRM Back Office Admin': [
            { label: 'New', value: 'New' },
            { label: 'Assigned', value: 'Assigned' },
            { label: 'In-Progress', value: 'In-Progress' },
            { label: 'Pending with Customer', value: 'On Hold' },
            { label: 'Customer Responded', value: 'Customer Responded' },
            { label: 'Actioned by Department', value: 'Actioned by Department' },
            { label: 'Resolved', value: 'Resolved' },
            { label: 'Not Actionable', value: 'Not Actionable' },
            { label: 'Resolved by CRM', value: 'Resolved by CRM' },
            { label: 'Customer Not Responded', value: 'Customer Not Responded' }
        ],
        'CRM Call Center Admin': [
            { label: 'New', value: 'New' },
            { label: 'Assigned', value: 'Assigned' },
            { label: 'In-Progress', value: 'In-Progress' },
            { label: 'Pending with Customer', value: 'On Hold' },
            { label: 'Customer Responded', value: 'Customer Responded' },
            { label: 'Actioned by Department', value: 'Actioned by Department' },
            { label: 'Resolved', value: 'Resolved' },
            { label: 'Not Actionable', value: 'Not Actionable' },
            { label: 'Resolved by CRM', value: 'Resolved by CRM' },
            { label: 'Customer Not Responded', value: 'Customer Not Responded' }
        ],
        'CRM Front Office Admin': [
            { label: 'New', value: 'New' },
            { label: 'Assigned', value: 'Assigned' },
            { label: 'In-Progress', value: 'In-Progress' },
            { label: 'Pending with Customer', value: 'On Hold' },
            { label: 'Customer Responded', value: 'Customer Responded' },
            { label: 'Actioned by Department', value: 'Actioned by Department' },
            { label: 'Resolved', value: 'Resolved' },
            { label: 'Not Actionable', value: 'Not Actionable' },
            { label: 'Resolved by CRM', value: 'Resolved by CRM' },
            { label: 'Customer Not Responded', value: 'Customer Not Responded' }
        ],
        'CRM Super Admin': [
            { label: 'New', value: 'New' },
            { label: 'Assigned', value: 'Assigned' },
            { label: 'In-Progress', value: 'In-Progress' },
            { label: 'Pending with Customer', value: 'On Hold' },
            { label: 'Customer Responded', value: 'Customer Responded' },
            { label: 'Actioned by Department', value: 'Actioned by Department' },
            { label: 'Resolved', value: 'Resolved' },
            { label: 'Not Actionable', value: 'Not Actionable' },
            { label: 'Resolved by CRM', value: 'Resolved by CRM' },
            { label: 'Customer Not Responded', value: 'Customer Not Responded' }
        ]
    };

    connectedCallback() {
        this.loadProfileAndCaseStatus();
    }

    async loadProfileAndCaseStatus() {
        try {
            const profileName = await getCurrentUserProfileName();
            const userName = await getCurrentUserName();
            this.currentUserName = userName;

            this.currentCaseStatus = await getCaseStatus({ caseId: this.recordId });

            // Get department & type for the case
            const caseData = await getCaseDepartmentAndType({ caseId: this.recordId });
            this.caseDepartment = caseData.Department__c;
            this.caseType = caseData.Type__c;
            

            // Use profile map OR default
            let options = this.profileStatusMap[profileName] || [
                { label: 'Actioned by Department', value: 'Actioned by Department' }
            ];

            // Special rule: Front Office Agent can see "Actioned by Department" 
            if (
                profileName === 'CRM FrontOffice Agent' &&
                this.caseDepartment === 'CRM' &&
                (
                    this.caseType === 'Permanent Disconnection & Refund Process' ||
                    this.caseType === 'CNI-Refund' ||
                    this.caseType === 'CNI- Refund'
                )
            ) {
                options = [
                    ...options,
                    { label: 'Actioned by Department', value: 'Actioned by Department' }
                ];
            }

            // For Escalation 1 and Escalation 2
            if (
                (this.currentUserName === 'Escalation 1' ||
                this.currentUserName === 'Escalation 2') &&
                this.caseDepartment === 'CRM' &&
                this.caseType === 'Escalation related'
            ) {
                options = [
                    ...options,
                    { label: 'Actioned by Department', value: 'Actioned by Department' }
                ];
            }

            // Restrict On Hold for BackOffice when not New/Assigned
            if (
                (profileName === 'CRM BackOffice Agent' || profileName === 'CRM Back Office TeamLead') &&
                !(this.currentCaseStatus === 'New' || this.currentCaseStatus === 'Assigned')
            ) {
                options = options.filter(opt => opt.value !== 'On Hold');
            }

            this.statusOptions = options;
        } catch (error) {
            this.showToast('Error', this.reduceError(error), 'error');
        }
    }

    handleStatusChange(event) {
        this.status = event.detail.value;
    }

    handleCommentChange(event) {
        this.newComment = event.target.value;
    }

    handleSave() {
        // Validate required fields
        if (!this.status) {
            this.showToast('Error', 'Please select a status', 'error');
            return;
        }

        if (!this.newComment || this.newComment.trim() === '') {
            this.showToast('Error', 'Please enter a comment', 'error');
            return;
        }

        this.isLoading = true;

        saveCaseData({
            caseId: this.recordId,
            newStatus: this.status,
            commentBody: this.newComment
        })
            .then((result) => {
                if (result === 'SUCCESS') {
                    this.showToast('Success', 'Case updated successfully', 'success');
                    getRecordNotifyChange([{ recordId: this.recordId }]);
                    this.dispatchEvent(new CloseActionScreenEvent());
                } else {
                    this.showToast('Info', result, 'info');
                }
            })
            .catch((error) => {
                this.showToast('Error saving data', this.reduceError(error), 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    reduceError(error) {
        let message = 'Unknown error';

        if (Array.isArray(error.body)) {
            message = error.body.map(e => e.message).join(', ');
        } else if (error.body && typeof error.body.message === 'string') {
            message = error.body.message;
        } else if (typeof error.message === 'string') {
            message = error.message;
        }

        // Handle Field Validation Exceptions
        const fieldValidationMatch = message.match(/FIELD_CUSTOM_VALIDATION_EXCEPTION,\s*(.*?): \[/);
        if (fieldValidationMatch && fieldValidationMatch[1]) {
            message = fieldValidationMatch[1];
        }

        // Handle insufficient access
        if (message.includes('INSUFFICIENT_ACCESS_OR_READONLY')) {
            message = 'You don\'t have permission to update this record.';
        }

        return message;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}