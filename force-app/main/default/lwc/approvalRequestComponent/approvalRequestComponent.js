import { LightningElement, wire,track } from 'lwc';
import getApprovalRequests from '@salesforce/apex/ApprovalController.getApprovalRequests';
import handleApproval from '@salesforce/apex/ApprovalController.handleApproval';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

export default class ApprovalRequestComponent extends LightningElement {

    @track approvalRequests = [];
    @track allApprovalRequests = [];
    error;
    wiredResult;
    hideCheckbox = false;

    @track isSpinner = false;

    @track approvedModalHeader='';

    
    // @track indentOrderLength;
    // @track blockedOrderLength;
    // @track prospectLength;
    // @track quoteLength;
    // @track pjpLength;


    columns = [
    { label: 'Record Name', fieldName: 'recordLink', type: 'url', 
      typeAttributes: { label: { fieldName: 'ProcessInstanceTargetObjectName' }, target: '_blank' } },
    { label: 'Created By', fieldName: 'ProcessInstanceCreatedBy' },
    { label: 'Created Date', fieldName: 'SubmittedDate', type: 'date' }
    ];

   // @track tabName='IndentOrder';

    connectedCallback() {
        this.handleGetApprovals();
    }

    // Updated handleCard function with the correct logic
    // handleCardChange(event) {
    //     this.tabName = event.currentTarget.dataset.tab; // Get the status of the clicked tab

    //     this.approvalRequests = this.allApprovalRequests.filter(ele=>ele.TabName==this.tabName) 
    // }

    handleGetApprovals() {
        console.log('Fetching PJP Plan Approvals');
        getApprovalRequests()
            .then((result) => {
                console.log('result approval requests::',result);
               // this.allApprovalRequests = result;
                this.approvalRequests = result;

                console.log('result approval requests::',result.length);

              //  this.completedDataLength = result.length;

                // this.approvalRequests = result;
              //  this.approvalRequests = this.allApprovalRequests.filter(ele=>ele.TabName==this.tabName) 

                // this.pjpLength = this.allApprovalRequests.filter(ele=>ele.TabName=='PJPPlan').length;
                // this.quoteLength = this.allApprovalRequests.filter(ele=>ele.TabName=='Quote').length;

                // this.prospectLength = this.allApprovalRequests.filter(ele=>ele.TabName=='Prospect').length;

                // this.blockedOrderLength = this.allApprovalRequests.filter(ele=>ele.TabName=='BlockedOrder').length;
                // this.indentOrderLength = this.allApprovalRequests.filter(ele=>ele.TabName=='IndentOrder').length;



            })
            .catch((error) => {
                this.error = error;
                this.approvalRequests = []; // Clear data on error
            });

 }


    handleBulkApprove() {
        this.handleBulkAction('Approve');
    }

    handleBulkReject() {
        this.handleBulkAction('Reject');
    }


    handleBulkAction(action) {
        const selectedRows = this.template.querySelector('lightning-datatable').getSelectedRows();
        console.log('selectedRows::',JSON.stringify(selectedRows));
        this.selectedApprovals = selectedRows;
        console.log('selected items for approval 1::',JSON.stringify(this.selectedApprovals));

        if (selectedRows.length === 0) {
            this.showToast('Error', 'No records selected', 'error');
            return;
        }



        const workItemIds = selectedRows.map((row) => row.id);
        console.log('workItemIds::',JSON.stringify(workItemIds));
        handleApproval({ workItemIds, action })
            .then(() => {
                this.showToast('Success', `Requests ${action}d successfully`, 'success');
                //return refreshApex(this.approvalRequests);
                

            })
            .catch((error) => {
                this.showToast('Error', `Failed to ${action} requests: ${error.body.message}`, 'error');
            });
    }

    showToastMessage(title, message, variant) {
        const evt = new ShowToastEvent
            ({
                title : title,
                message : message,
                variant : variant,
            });
        this.dispatchEvent(evt);
    }
    @track selectedApprovals = []; // List of selected approvals
    @track isModalOpen = false;
    @track commentsMap = new Map(); // Comments keyed by approval ID
    @track commonComments=''
    @track approvalAction=''

    openApproveModal() {

        this.approvalHeader= 'Approval Details';
       // const selectedRows = this.template.querySelector('lightning-datatable').getSelectedRows();
       // console.log('selectedRows::',JSON.stringify(selectedRows));
       const selectedRows = this.template.querySelector('lightning-datatable').getSelectedRows();
        console.log('selectedRows::',JSON.stringify(selectedRows));
        if (selectedRows.length === 0) {
            this.showToast('Error', 'No records selected', 'error');
            return; 
        }
        this.selectedApprovals = selectedRows;
        if (this.selectedApprovals) {
            console.log('selected items for approval 2::',JSON.stringify(this.selectedApprovals));
            this.isModalOpen = true;
        } else {
            // Handle case where no rows are selected
            alert('Please select at least one approval.');
        }
        this.approvalAction = 'Approve'
    }
    openRejectModal() {

        this.approvalHeader = 'Rejected Details';
       // const selectedRows = this.template.querySelector('lightning-datatable').getSelectedRows();
       // console.log('selectedRows::',JSON.stringify(selectedRows));
       const selectedRows = this.template.querySelector('lightning-datatable').getSelectedRows();
        console.log('selectedRows::',JSON.stringify(selectedRows));
        if (selectedRows.length === 0) {
            this.showToast('Error', 'No records selected', 'error');
            return; 
        }
        this.selectedApprovals = selectedRows;
        if (this.selectedApprovals) {
            console.log('selected items for approval 2::',JSON.stringify(this.selectedApprovals));
            this.isModalOpen = true;
        } else {
            // Handle case where no rows are selected
            alert('Please select at least one approval.');
        }
         this.approvalAction = 'Reject'
    }

    closeModal() {
        this.isModalOpen = false;
    }

    handleCommonComment(event){

        console.log('common comment:', event.target.value);
        this.commonComments = event.target.value;
    }

    handleCommentChange(event) {

        const approvalId = event.currentTarget.dataset.id;
        this.selectedApprovals.map(ele=>{
            if(ele.workItemIds==approvalId){
                ele.comment = event.target.value
            }
        })

        console.log('Current target id', event.currentTarget.dataset.id);
        console.log('approval comment ::', event.target.value);
  
    }

    // handleSubmit() {
    //     const approvalsWithComments = this.selectedApprovals.map(approval => ({
    //         ...approval,
    //         comment: this.commentsMap.get(approval.id) || ''
    //     }));

    //     console.log('Approvals with comments:', approvalsWithComments);

    //     // Perform the necessary action, e.g., server call
    //     this.closeModal();
    // }

    handleSubmit() {
    // Convert Map to JSON-compatible object
        
    console.log('inside handle submit for approval');
   /* if (this.commentsMap == null) {
        this.isSpinner=false;
            this.showToast('Error', 'No records selected', 'error');
            return;
        }
        */

        this.isSpinner = true;
   
    // Call Apex method
    handleApproval({payload : this.selectedApprovals,
         action: this.approvalAction,
         commonComments: this.commonComments
    })
        .then(result => {
            console.log('Approval processed successfully:', result);
            this.showToastMessage('success','Approved Successfully','success');
            this.isSpinner = false;
            this.closeModal();
            window.location.reload();
        })
        .catch(error => {
            this.isSpinner=false;
            this.showToastMessage('error','Getting error to approve','error');
            console.error('Error processing approval:', error);
        });
}


}