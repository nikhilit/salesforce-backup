import { LightningElement,api,track } from 'lwc';
import getServiceTerritories from '@salesforce/apex/CreateWOFromConnectionContr.getServiceTerritories';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import createWorkOrder from '@salesforce/apex/CreateWOFromConnectionContr.createWorkOrder';
import getLatestRiserMaintenanceWO from '@salesforce/apex/CreateWOFromConnectionContr.getLatestRiserMaintenanceWO';

export default class CreateWOFromConnectionComp extends NavigationMixin (LightningElement) {


@api recordId;

@track selectedActivity ='';

@track selectedDateTime;
@track selectedTerritory;
@track contractorWorkOrderNumber;


@track workOrderId;

@track supervisorName='';
@track plumberName='';


@track isLoading=false;

    @track territoryOptions = [];

    @track woNumberOptions=[];


connectedCallback() {
    this.getServiceTerritories();

}




activityOptions = [
      { label: 'Riser Maintenance', value: 'Riser Maintenance' },
        { label: 'Riser Painting', value: 'Riser Painting' },
        {label : 'Riser Replacement', value : 'Riser Replacement'}
];

get isWorkOrderDisabled() {
    return this.woNumberOptions.length === 0;
}

getLatestRiserMaintenanceWO(){

    console.log('record id inside method ::', this.recordId);

    getLatestRiserMaintenanceWO({recordId : this.recordId})

    .then(result => {

        console.log('result ::', JSON.stringify(result));

         let options = [
                { label: 'Riser Maintenance', value: 'Riser Maintenance' },
                { label: 'Riser Painting', value: 'Riser Painting' },
                { label: 'Riser Replacement', value: 'Riser Replacement' }
            ];

          if (result && result.CreatedDate) {
    const createdDate = new Date(result.CreatedDate);
    const today = new Date();

    const createdUTC = Date.UTC(createdDate.getUTCFullYear(), createdDate.getUTCMonth(), createdDate.getUTCDate());
    const todayUTC = Date.UTC(today.getUTCFullYear(), today.getUTCMonth(), today.getUTCDate());

    const diffDays = Math.floor((todayUTC - createdUTC) / (1000 * 60 * 60 * 24));
    console.log('Days since last Riser Maintenance:', diffDays);

    if (diffDays < 365) {
        options = options.filter(opt => opt.value !== 'Riser Maintenance');
    }
            }

            this.activityOptions = options;

    })
    .catch(Error => {
        console.log('Error ::', error);
    })
}



// woNumberOptions = [
//   { label: '4100012396', value: '4100012396' },
//   { label: '4100012878', value: '4100012878' },
//   { label: '4100012879', value: '4100012879' },
//   { label: '4100012880', value: '4100012880' },
//   { label: '4100011139', value: '4100011139' },
//   { label: '4100013387', value: '4100013387' },
//   { label: '4100013388', value: '4100013388' },
//   { label: '4100012563', value: '4100012563' },
//   { label: '4100012411', value: '4100012411' },
//   { label: '4100012888', value: '4100012888' },
//   { label: '4100012889', value: '4100012889' },
//   { label: '4100012890', value: '4100012890' },
//   { label: '4100011140', value: '4100011140' },
//   { label: '4100012562', value: '4100012562' },
//   { label: '4100012400', value: '4100012400' },
//   { label: '4100012885', value: '4100012885' },
//   { label: '4100012886', value: '4100012886' },
//   { label: '4100012887', value: '4100012887' }
// ];

woMapping = {
    'Jangid Engineering': ['4100012396'],
    'DG Enterprises': ['4100012878'],
    'Sky Blue Infra Project': ['4100012879'],
    'MS Enterprises': ['4100012880'],
    'Shreeram Enterprises': ['4100011139', '4100012400'],
    'Marc Engineering': ['4100013387'],
    'Kohinoor Infra Project': ['4100013388'],
    'Preet Engineering': ['4100012563'],
    'Swaara Enterprises': ['4100012411'],
    'Deepa Enterprises': ['4100012888'],
    'Preet Engg Works': ['4100012889'],
    'Fixo Fit Well': ['4100012890'],
    'Dinesh Enterprises': ['4100011140'],
    'Aarti Enterprises': ['4100012562'],
    'Chauhan Engineering': ['4100012885'],
    'Singh Services': ['4100012886'],
    'Sainvesta Enterprises': ['4100012887']
};

handleActivityChange(event){

     console.log('selected activity::', event.target.value);


    this.selectedActivity = event.target.value;


}

    handleDateTimeChange(event){

        console.log('date time::', event.target.value);

          const selected = event.target.value;


         //    this.selectedDateTime = event.target.value;

const now = new Date();
  const selDate = new Date(selected);

  // Normalize both to midnight to ignore time
  now.setHours(0, 0, 0, 0);
  selDate.setHours(0, 0, 0, 0);

  if (selDate < now) {

    this.showtoast('Warning', 'Please Select Correct Date', 'warning');
    event.target.value = '';
    this.selectedDateTime = null;
  } else {
    this.selectedDateTime = selected;
  }

    }

     handleTerritoryChange(event) {
        this.selectedTerritory = event.detail.value;

         const selectedTerritoryObj = this.territoryOptions.find(
        terr => terr.value === this.selectedTerritory
    );

    const territoryName = selectedTerritoryObj ? selectedTerritoryObj.label : null;

    const woList = territoryName ? this.woMapping[territoryName] || [] : [];

    this.woNumberOptions = woList.map(wo => ({ label: wo, value: wo }));
    this.contractorWorkOrderNumber = ''; 
    }

     handleWONumberChange(event) {
        this.contractorWorkOrderNumber = event.detail.value;
    }



    getServiceTerritories(){

        getServiceTerritories ()

        .then(result => {

            console.log('result serviceterritory ::', result);
             this.territoryOptions = result.map(terr => ({
                label: terr.Name,
                value: terr.Id
            }));

                    this.getLatestRiserMaintenanceWO();

        })
        .catch(error => {

            console.log('error ::', error);
        })
    }

    handleSupervisorName(event){

        console.log('supervisor name ::', event.target.value);

        this.supervisorName=event.target.value;
    }

     handlePlumberName(event){

        console.log('plumber name ::', event.target.value);

        this.plumberName=event.target.value;
    }


 handleCreateWo(){

       
        this.isLoading=true;
        console.log('inside hanlde create wo');


        if(!this.selectedActivity || !this.selectedDateTime || !this.selectedTerritory || !this.supervisorName || !this.plumberName || !this.contractorWorkOrderNumber){

        this.showtoast('Warning', 'Please Enter All Required Fields', 'warning');
        this.isLoading=false;
        return;

        }

        console.log('Serviceterritory::', this.selectedTerritory);

       createWorkOrder({recordId : this.recordId, selectedActivity : this.selectedActivity, selectedDateTime : this.selectedDateTime,
        selectedTerritory : this.selectedTerritory, supervisorName: this.supervisorName, plumberName : this.plumberName, contractorWorkOrderNumber : this.contractorWorkOrderNumber})
       .then( result => {

        console.log('Result ::',result);
        this.isLoading=false;
       this.showtoast('Success', 'Work Order Created Successfully', 'success');

       this.workOrderId=result;

        //     this[NavigationMixin.Navigate]({
        //     type: 'standard__recordPage',
        //     attributes: {
        //         recordId: result,
        //         objectApiName: 'WorkOrder',
        //         actionName: 'view'
        //     }
        // });

        this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: `com.salesforce.fieldservice://v1/sObject/${this.workOrderId}/overview`
                }
            });

        

       })
       .catch(error => {
        this.isLoading=false;
        console.log('Error ::', error);
       })


    }

    //  handleNavigate(event) {
    //     const recordId = event.currentTarget.dataset.id;
    //     this[NavigationMixin.Navigate]({
    //         type: 'standard__recordPage',
    //         attributes: {
    //             recordId: recordId,
    //             objectApiName: 'WorkOrder',
    //             actionName: 'view'
    //         }
    //     });
    // }

     showtoast(title, msg, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant
        });
        this.dispatchEvent(event);
    }


}