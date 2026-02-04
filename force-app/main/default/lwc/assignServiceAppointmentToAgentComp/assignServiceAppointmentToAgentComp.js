import { LightningElement,api,track } from 'lwc';
import getContractorAgents from '@salesforce/apex/AssignServiceAppointmentToAgentContr.getContractorAgents';
import assignAgentToAssignResource from '@salesforce/apex/AssignServiceAppointmentToAgentContr.assignAgentToAssignResource';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class AssignServiceAppointmentToAgentComp extends LightningElement {

  @api reactiveValue = []; 

  @api selectedIds = [];


  @track selectedAgentId;
  @track agentFilter=[];

  @track agentOptions=[];

  @track showMessage;
  @track isLoading=false;
  @track assignButton=true;

      selectedDateTime;
      selectedEndDateTime;

    


   // @track selectedAgentId;
connectedCallback() {
     if (this.reactiveValue?.length > 0) {
            this.selectedIds = this.reactiveValue;
        console.log('inside connectedcallback selected ids values:', JSON.stringify(this.selectedIds));
        console.log('inside connectedcallback reactiveValue ids values:', JSON.stringify(this.reactiveValue));


        }
    this.getContractorAgents();
    console.log('Reactive values:', JSON.stringify(this.reactiveValue));
}


handleDateTimeChange(event) {
        // this.selectedDateTime = event.target.value;
        // console.log('Selected DateTime:', this.selectedDateTime);

          const selected = event.target.value;


         //    this.selectedDateTime = event.target.value;

            const now = new Date();
            const selDate = new Date(selected);

            // Normalize both to midnight to ignore time
            now.setHours(0, 0, 0, 0);
            selDate.setHours(0, 0, 0, 0);

            if (selDate < now) {

               // this.showToast('Warning', 'Please Select Correct Date', 'warning');
                event.target.value = '';
                this.selectedDateTime = null;
                this.showMessage='Please Select Correct Date';
                this.assignButton=false;
            } else {
                this.selectedDateTime = selected;
                this.assignButton=true;
                this.showMessage='';
                // this.showMessage='Please Select Correct Date';

            }
    }

    handleEndDateTimeChange(event) {
        // this.selectedEndDateTime = event.target.value;
        // console.log('Selected End DateTime:', this.selectedEndDateTime);
          const selected = event.target.value;



            const now = new Date();
            const selDate = new Date(selected);

            // Normalize both to midnight to ignore time
            now.setHours(0, 0, 0, 0);
            selDate.setHours(0, 0, 0, 0);

            if (selDate < now) {

               // this.showtoast('Warning', 'Please Select Correct Date', 'warning');
                event.target.value = '';
                this.selectedEndDateTime = null;
                this.showMessage='Please Select Correct Date';
                this.assignButton=false;

            } else {
                this.selectedEndDateTime = selected;
                this.assignButton=true;
                this.showMessage='';
            }
    }

getContractorAgents(){
    getContractorAgents()
    .then(result => {
                console.log('DEBUG: getNormalAgents result:', result);
                this.agentOptions = result.map(agent => ({
                    label: agent.Name,
                    value: agent.Id
                }));
                //this.setCriteria();
            })
            .catch(error => {
                
                console.error('DEBUG: Error in getNormalAgents:', error);
            })
}

 
    //Set Filter Criteria
//     setCriteria() {

//     console.log('apply filter');

//     // Extract only the list of IDs from agentOptions
//     const agentName = this.agentOptions.map(agent => agent.label);

//     if (agentName.length > 0) {
//         this.agentFilter = {
//             criteria: [
//                 {
//                     fieldPath: 'ServiceResource.Name', 
//                     operator: 'in',
//                     value: agentName
//                 }
//             ]
//         };
//     }

//     console.log('Agent filter criteria:', JSON.stringify(this.agentFilter));
// }

// matchingInfo = {
//     primaryField: { fieldPath: 'ServiceResource.Name' }
// };
// displayInfo = {
//     primaryField: { fieldPath: 'ServiceResourceName__c' } // ✅ Enforce display of Name
// };
 
 

 handleAgentChange(event) {
        this.selectedAgentId = event.detail.value;

        if(!this.selectedAgentId){

            this.showMessage='Please Select Agent';
            this.assignButton=false;
        }
        if(this.selectedAgentId){
            this.showMessage='';
            this.assignButton=true;
        }
        console.log('DEBUG: Agent selected:', this.selectedAgentId);
    }

       

    handleAssignAgent(){

       

         if(!this.selectedAgentId){

         // this.showToast('Warning', 'Please Select Agent', 'warning');
            this.showMessage='Plese Select Agent';
            this.assignButton=false;
            this.isLoading=false;
            return;
        }

        if(!this.selectedDateTime || !this.selectedEndDateTime){

            this.isLoading=false;
            this.assignButton=false;
            this.showMessage='Plese Select Correct Date';
            return;
        }
       
        this.isLoading=true;
        console.log('inside hanlde assign agent');
            console.log('Reactive values:', JSON.stringify(this.reactiveValue));
       assignAgentToAssignResource({reactiveValue : this.reactiveValue, selectedAgentId : this.selectedAgentId, selectedDateTime : this.selectedDateTime, selectedEndDateTime : this.selectedEndDateTime})
       .then( result => {
        if(result =='Success'){
        this.isLoading=false;
        this.assignButton=false;
        this.showMessage = 'Assigned Successfully';
      // this.showtoast('Success', 'Assigned Successfully', 'success');
        }

       })
       .catch(error => {
        // this.isLoading=false;
        // console.log('Error ::', error);
         this.isLoading = false;
    console.log('Error Full Details:', JSON.stringify(error));

    if (error.body && error.body.message) {
        console.log('Apex Error:', error.body.message);
    } else {
        console.log('Unknown Error:', error);
    }
       })


    }

     showToast(title, msg, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message: msg, variant }));
    } 
    

}