import { LightningElement,api,track } from 'lwc';
import assignWorkTypeToWorkOrder from '@salesforce/apex/CreateWorkOrderFromCaseContr.assignWorkTypeToWorkOrder';
import getlstWorkType from '@salesforce/apex/CreateWorkOrderFromCaseContr.getlstWorkType';


export default class CreateWorkOrdersFromCase extends LightningElement {


  @api reactiveValue = []; 

    @api selectedIds = [];


  @track worktypeOptions =[];

    @track selectedWorkTypeId;

    //bd
    @track showDemolitionComponent = false;
@track demolitionCaseIds = [];
//bd

    
  @track showMessage;
  @track isLoading=false;
  @track assignButton=true;
  // bd
// @track showDemolitionComponent = false;
// @track demolitionCaseIds = [];

//bd


  connectedCallback() {

     if (this.reactiveValue?.length > 0) {
            this.selectedIds = this.reactiveValue;
        console.log('inside connectedcallback selected ids values:', JSON.stringify(this.selectedIds));
        console.log('inside connectedcallback reactiveValue ids values:', JSON.stringify(this.reactiveValue));


        }
    
    this.getlstWorkType();
    console.log('Reactive values::', this.reactiveValue);
  }
//bd
//   get primaryCaseId() {
//     return this.demolitionCaseIds && this.demolitionCaseIds.length > 0
//         ? this.demolitionCaseIds[0]
//         : null;
// }
//bd

   handleWorkTypeChange(event) {
        this.selectedWorkTypeId = event.detail.value;
        console.log('selected worktype id:', this.selectedWorkTypeId);

         // Find selected WorkType name
    let selectedWT = this.worktypeOptions.find(w => w.value === this.selectedWorkTypeId);

    // When Building Demolition is selected → show child component immediately
    if (selectedWT && selectedWT.label === 'Building Demolition') {
        this.showDemolitionComponent = true;
        this.assignButton = true;     // Hide WorkOrder button
        this.showMessage = '';         // Clear message
        this.demolitionCaseIds = [...this.reactiveValue];
        return;
    }

    // For all other work types → restore normal flow
    this.showDemolitionComponent = false;
    this.assignButton = true;

    }

     handleAssignWorkType(){

       if (this.showDemolitionComponent) {
        // User selected Demolition — WO button MUST NOT do anything
        return;
    }


       
        this.isLoading=true;
        console.log('inside hanlde assign worktype');
            console.log('Reactive values:', JSON.stringify(this.reactiveValue));
       assignWorkTypeToWorkOrder({reactiveValue : this.reactiveValue, selectedWorkTypeId : this.selectedWorkTypeId})
       .then( result => {

        if(result =='Success'){
        this.isLoading=false;
        this.assignButton=false;
        this.showMessage = 'Work Order Created Successfully';
      //this.showtoast('Success', 'Assigned Successfully', 'success');
        }

        
        

       })
       .catch(error => {
        this.isLoading=false;
        console.log('Error ::', error);
       })


    }

  getlstWorkType(){
    getlstWorkType()
    .then(result => {
                console.log('Get WorkType:', result);
                this.worktypeOptions = result.map(worktype => ({
                    label: worktype.Name,
                    value: worktype.Id
                }));
                //this.setCriteria();
            })
            .catch(error => {
                console.error('Error in getNormalAgents:', error);
            })
}


 

}