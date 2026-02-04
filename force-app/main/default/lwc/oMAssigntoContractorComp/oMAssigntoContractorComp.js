import { LightningElement,api,track } from 'lwc';
import getContractors from '@salesforce/apex/AssignWorkOrderstoContractorsComp.getContractors';
import assignAgentToAssignContractors from '@salesforce/apex/AssignWorkOrderstoContractorsComp.assignAgentToAssignContractors';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class OMAssigntoContractorComp extends LightningElement {

  @api reactiveValue = []; 

  @api selectedIds = [];


  @track selectedAgentId;
  @track agentFilter=[];

  @track agentOptions=[];

  @track showMessage;
  @track isLoading=false;
  @track assignButton=true;

   
connectedCallback() {
     if (this.reactiveValue?.length > 0) {
            this.selectedIds = this.reactiveValue;
        console.log('inside connectedcallback selected ids values:', JSON.stringify(this.selectedIds));
        console.log('inside connectedcallback reactiveValue ids values:', JSON.stringify(this.reactiveValue));


        }
    this.getContractors();
    console.log('Reactive values:', JSON.stringify(this.reactiveValue));
}

getContractors(){
    getContractors()
    .then(result => {
                console.log('DEBUG: getNormalAgents result:', result);
                this.agentOptions = result.map(agent => ({
                    label: agent.Name,
                    value: agent.Id
                }));
                //this.setCriteria();
            })
            .catch(error => {
                
                console.error('DEBUG: Error in getcontractors:', error);
            })
}


 handleAgentChange(event) {
        this.selectedAgentId = event.detail.value;

        if(!this.selectedAgentId){

            this.showMessage='Please Select Contractor';
            this.assignButton=false;
        }
        if(this.selectedAgentId){
            this.showMessage='';
            this.assignButton=true;
        }
        console.log('DEBUG: Contractor selected:', this.selectedAgentId);
    }

       

    handleAssignAgent(){

       

         if(!this.selectedAgentId){

            this.showMessage='Plese Select Contractor';
            this.assignButton=false;
            this.isLoading=false;
            return;
        }

       
        this.isLoading=true;
        console.log('inside hanlde assign contractor');
        console.log('Reactive values:', JSON.stringify(this.reactiveValue));
       assignAgentToAssignContractors({reactiveValue : this.reactiveValue, selectedContractorid : this.selectedAgentId})
       .then( result => {
        if(result =='Success'){
        this.isLoading=false;
        this.assignButton=false;
        this.showMessage = 'Contractor Assigned Successfully';
        }

       })
       .catch(error => {
        this.isLoading=false;
        console.log('Error ::', error);
       })


    }

     showToast(title, msg, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message: msg, variant }));
    } 
    

}