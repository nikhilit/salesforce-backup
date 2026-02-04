import { LightningElement,api,track } from 'lwc';
import getContractorAgents from '@salesforce/apex/AssignServiceAppointmentToAgentContr.getContractorAgents';
import assignAgentToAssignResource from '@salesforce/apex/AssignServiceAppointmentToAgentContr.assignAgentToAssignResource';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class AssignServiceAppSupervisorComp extends LightningElement {

  //@api reactiveValue = []; 

  @api selectedWorkOrderId=[];

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
    this.getContractorAgents();
    console.log('Workorder ids inside childs :', JSON.stringify(this.selectedWorkOrderId));
}


handleDateTimeChange(event) {

       // this.selectedDateTime = event.target.value;
      //  console.log('Selected DateTime:', this.selectedDateTime);

          const selected = event.target.value;


         //    this.selectedDateTime = event.target.value;

            const now = new Date();
            const selDate = new Date(selected);

            // Normalize both to midnight to ignore time
            now.setHours(0, 0, 0, 0);
            selDate.setHours(0, 0, 0, 0);

            if (selDate < now) {

                this.showToast('Warning', 'Please Select Correct Date', 'warning');
                event.target.value = '';
                this.selectedDateTime = null;
            } else {
                this.selectedDateTime = selected;
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

                this.showtoast('Warning', 'Please Select Correct Date', 'warning');
                event.target.value = '';
                this.selectedEndDateTime = null;
            } else {
                this.selectedEndDateTime = selected;
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
        console.log('DEBUG: Agent selected:', this.selectedAgentId);
    }

    handleBack(){

        console.log('inside handle back');
        this.dispatchEvent(new CustomEvent('cancel'));

    }

       

    handleAssignAgent(){

       
        this.isLoading=true;
        console.log('inside hanlde assign agent');

        if(this.selectedWorkOrderId =='' ){

          this.showToast('Warning', 'Please Select Records To Assign Agent', 'warning');


            this.isLoading=false;
            return;
        }

         if(!this.selectedAgentId){

          this.showToast('Warning', 'Please Select Agent', 'warning');


            this.isLoading=false;
            return;
        }
            console.log('Reactive values:', JSON.stringify(this.selectedWorkOrderId));
       assignAgentToAssignResource({reactiveValue : this.selectedWorkOrderId, selectedAgentId : this.selectedAgentId, selectedDateTime : this.selectedDateTime, selectedEndDateTime : this.selectedEndDateTime})
       .then( result => {
        if(result =='Success'){
        this.isLoading=false;
        this.assignButton=false;
        this.showMessage = 'Assigned Successfully';

         this.showToast('Success', 'Agent Assigned Successfully', 'success');

        this.handleBack();
      // this.showtoast('Success', 'Assigned Successfully', 'success');
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