import { LightningElement, api, wire,track } from 'lwc';
import getBPDetails from '@salesforce/apex/BpDetailsBasedOnConnectionContr.getBPDetails';
import { NavigationMixin } from 'lightning/navigation';
import saveBPFoundDetails from '@salesforce/apex/BpDetailsBasedOnConnectionContr.saveBPFoundDetails';
import getWorkOrder from '@salesforce/apex/BpDetailsBasedOnConnectionContr.getWorkOrder';
import LightningAlert from 'lightning/alert';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class BpDetailsBasedOnConnectionComp extends NavigationMixin(LightningElement) {
  
    @api recordId; // Work Order Id

    @track showCOAccountPage = true;
   // @api accountBPNumber='';
    @api accountId;

    @track load=false;

    @track showBPPage=true;

        @track havingBPValue;

      @track customerDetails='';

    @track showEnterCustomerDetails=false;

         @track showSaveButton=true;

    
    bpDetail = [];

    @track showEnterBPDetails=false;
   // openModal=false;
    error;

    havingBPOptions = [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' }
    ];

    connectedCallback() {
        
            console.log('record id workorder inside bp details query ::', this.recordId);
                    this.getWorkOrder();


    }

     getWorkOrder(){

        getWorkOrder({recordId : this.recordId})

        .then( result => {

            console.log('Result getWorkOrder ::', JSON.stringify(result));
          

                 this.havingBPValue = result.Any_customer_using_gas_but_not_having_bp__c;
                if(this.havingBPValue=='Yes'){
                    this.showEnterCustomerDetails=true;
				this.customerDetails = result.Customer_Details_Using_Gas_Not_Having_BP__c;
                }
       
        })
        .catch(Error => {

            console.log('Error ::', Error);
        })
    }


    @wire(getBPDetails, { workOrderId: '$recordId' })
    bpDetails({ data, error }) {
        if (data) {
            this.bpDetail = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.bpDetail = [];
        }
    }
    handleOpenModal(event){

     this.accountId = event.currentTarget.dataset.id; // Capture clicked Id
     console.log('account name::',event.currentTarget.dataset.name);
          console.log('accountId::',event.currentTarget.dataset.id);

   // this.accountBPNumber=event.currentTarget.dataset.name;
       this.showEnterBPDetails=true;
        this.showBPPage=false;
     // this.openModal=true;
    }
    handleCancel(){
       this.showEnterBPDetails=false;
       this.showBPPage=true;
    //   this.showCOAccountPage=true;
    }

     handleHavingBPChange(event) {

        console.log('handle having bp list value ::', event.target.value);
        this.havingBPValue = event.target.value;

        if(this.havingBPValue =='Yes'){

            this.showEnterCustomerDetails=true;

            }
            else{

              this.showEnterCustomerDetails=false;

            }

    }

     handleCustomerDetailChange(event) {

        console.log('handle customer detail change ::', event.target.value);
        this.customerDetails = event.target.value;

    }

     handleSave(){

        this.load=true;

          if (!this.havingBPValue || (this.havingBPValue =='Yes' && !this.customerDetails)) {
            // this.showtoast('Warning', 'Please Enter All Required Fields', 'Warning');
            // this.load=false;
             LightningAlert.open({
            message: 'Please Enter All Required Fields',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        }).then(() => {
                    this.load=false;
         });
            return;
        }

       
        saveBPFoundDetails({recordId : this.recordId, havingBPValue : this.havingBPValue, customerDetails : this.customerDetails})
    
        .then(result => {

            //  this.showtoast('Success', 'Details Saved Successfully', 'success');
            // console.log('Result savecodetails::', result);
            //  this.load=false;
             LightningAlert.open({
            message: 'Details Saved Successfully',
            theme: 'success',   // red error dialog
            label: 'Success'    // header text
        }).then(() => {
                    this.load=false;
         });
            // this.handleCancel();
          //  this.dispatchEvent(new CustomEvent ('cancel'));



        })
        .catch(Error => {

            console.log('Error savecodetails::', Error);
          this.load=false;

        })
    }


     showtoast(title, msg, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant
        });
        this.dispatchEvent(event);
    }


    handleNavigate(event) {
        const recordId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: 'WorkOrderLineItem',
                actionName: 'view'
            }
        });
    }
}