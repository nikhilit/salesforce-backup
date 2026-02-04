import { LightningElement, track,api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// import getAllAgencies from '@salesforce/apex/CallAssignServiceAgentContr.getAllAgencies';
// import getAllAgents from '@salesforce/apex/CallAssignServiceAgentContr.getAllAgents';
// import getAgentsByAgency from '@salesforce/apex/CallAssignServiceAgentContr.getAgentsByAgency';
// import getAgenciesByAgent from '@salesforce/apex/CallAssignServiceAgentContr.getAgenciesByAgent';

//import getWorkTypes from '@salesforce/apex/CallAssignServiceAgentContr.getWorkTypes';
import getFilteredWorkOrders from '@salesforce/apex/CallAssignServiceAgentContr.getFilteredWorkOrders';
//import assignAgency from '@salesforce/apex/CallAssignServiceAgentContr.assignAgency';

export default class O_mCallAssignServiceAgentComp extends LightningElement {
    // Filters
   // @track accountName;
  //  @track attendedDate;
 //   @track assignedDate;
  //  @track appointmentStatus;
    @track pinCode;
    @track location;
    @track roadName;
    @track buildingName;

   // @track selectedAgencyFilter;
   // @track activityType;
  //  @track selectedAgentFilter;

    // lists
    @track agencies = [];
    @track agents = [];
    @track workTypes = [];

    // datatable / pagination
    @track workOrders = [];
    @track pagedData = [];
    @track pageSize = 10;
    @track pageNumber = 1;
    @track totalSize = 0;
    @track totalPages = 1;
    @track isLoading = false;
    selectedCount = 0;
    

    // columns
    columns = [
        { label: 'Work Order Number', fieldName: 'WorkOrderNumber' },
        { label: 'Business Partner', fieldName: 'AccountName', type: 'text' },
        { label: 'Agent', fieldName: 'AgentName' },
        { label: 'Location', fieldName: 'Location' },
        { label: 'Pin', fieldName: 'PostalCode' },
        { label: 'Road Name', fieldName: 'RoadName' },
        { label: 'Building Name', fieldName: 'BuildingName' },



      //  { label: 'Agency', fieldName: 'AgencyName', type: 'text' },
       // { label: 'Assigned Date', fieldName: 'Location' },
       // { label: 'Attended Date', fieldName: 'PostalCode' },
        { label: 'Appointment Status', fieldName: 'Appointment_Status__c' },
        { label: 'Work Type', fieldName: 'WorkTypeName' }    ];

    // selection
    @track selectedWorkOrderIds = [];

    @track showAssignToAgentPage=true;

    @track isAssignDisabled=true;

    @track showWorkOrderData=true;

    @api selectedWorkOrderId=[];

    // assign panel values
    @track selectedAgencyForAssign;
    @track selectedAgentForAssign;
    @track selectedWorkTypeForAssign;
    @track startDateForAssign;
    @track endDateForAssign;

    // assign lists for assignment panel (mutual filtering)
    @track agentOptionsForAssign = [];
    @track agencyOptions = [];
    @track agentOptions = []; // for filters area
    @track workTypeOptions = [];

    statusOptions = [
        {label: 'Unattempted', value: 'Unattempted'},
        {label: 'Completed', value: 'Completed'},
        {label: 'Incomplete', value: 'Incomplete'},
        {label: 'In Progress', value: 'In Progress'}
    ];

    // loading/assigning flags
    @track isAssignLoading = false;

    // @track pageNumber = 1;
    // @track totalPages = 1;

    get isFirstPage() {
        return this.pageNumber === 1;
    }

    get isLastPage() {
        return this.pageNumber === this.totalPages;
    }

    get isPrevDisabled() {
        return this.isLoading || this.pageNumber <= 1;
    }

    get isNextDisabled() {
        return this.isLoading || this.pageNumber >= this.totalPages || this.totalPages === 0;
    }


    handlePrevPage() {
        if (this.isLoading) return;        
        if (this.pageNumber > 1) {
            this.pageNumber--;
            this.loadWorkOrders();
        }
    }

    handleNextPage() {
        if (this.isLoading) return;    
        if (this.pageNumber < this.totalPages) {
            this.pageNumber++;
            this.loadWorkOrders();
        }
    }

    connectedCallback() {
      //  this.loadInitialPicklists();
        this.loadWorkOrders(); // loads page 1
    }

    // --------- initial data
  //  loadInitialPicklists() {
     /*   getAllAgencies()
        .then(data => {
            this.agencies = data;
            this.agencyOptions = data.map(a => ({ label: a.Name, value: a.Id }));
        })
        .catch(err => console.error(err));

        getAllAgents()
        .then(data => {
            this.agents = data;
            this.agentOptions = data.map(a => ({ label: a.ServiceResource.RelatedRecord.Name, value: a.ServiceResourceId }));
        })
        .catch(err => console.error(err)); 
        
        */

    //     getWorkTypes()
    //     .then(data => {
    //         this.workTypes = data;
    //         this.workTypeOptions = data.map(w => ({ label: w.Name, value: w.Id }));
    //     })
    //     .catch(err => console.error(err));
    // }

    // --------- filters handlers
   /* handleFilterChange(e) {
        const name = e.target.dataset.name;
        if (name === 'invoiceFrom') this.invoiceFrom = e.target.value;
        if (name === 'invoiceTo') this.invoiceTo = e.target.value;
        if (name === 'location') this.location = e.target.value;
        if (name === 'status') this.status = e.target.value;
        if (name === 'pinCode') this.pinCode = e.target.value;
        if (name === 'agency') {
            this.selectedAgencyFilter = e.target.value;
            // load agent options for that agency in filter area
            if (this.selectedAgencyFilter) {
                getAgentsByAgency({ agencyId: this.selectedAgencyFilter })
                    .then(res => {
                        this.agentOptions = res.map(a => ({ label: a.ServiceResource.RelatedRecord.Name, value: a.ServiceResourceId }));
                    })
                    .catch(err => console.error(err));
            } else {
                // reload full agents
                getAllAgents().then(res => this.agentOptions = res.map(a => ({ label: a.ServiceResource.RelatedRecord.Name, value: a.ServiceResourceId }))).catch(err=>console.error(err));
            }
        }
        if (name === 'activityType') this.activityType = e.target.value;
        if (name === 'agent') {
            this.selectedAgentFilter = e.target.value;
            // load agencies for filter if agent selected
            if (this.selectedAgentFilter) {
                getAgenciesByAgent({ agentServiceResourceId: this.selectedAgentFilter }).then(res => {
                    this.agencyOptions = res.map(a => ({ label: a.Name, value: a.Id }));
                }).catch(err => console.error(err));
            } else {
                getAllAgencies().then(res => this.agencyOptions = res.map(a => ({ label: a.Name, value: a.Id }))).catch(err => console.error(err));
            }
        }
    } */

     handleFilterChange(e) {
        const name = e.target.dataset.name;
        // if (name === 'invoiceFrom') this.invoiceFrom = e.target.value;
        // if (name === 'invoiceTo') this.invoiceTo = e.target.value;
        if (name === 'location') this.location = e.target.value;
      // if (name === 'status') this.status = e.target.value;
        if (name === 'pinCode') this.pinCode = e.target.value;
        if (name === 'roadName') this.roadName = e.target.value;
         if (name === 'buildingName') this.buildingName = e.target.value;


        // if (name === 'agency') {
        //     this.selectedAgencyFilter = e.target.value;
        //     // load agent options for that agency in filter area
        //     if (this.selectedAgencyFilter) {
        //         getAgentsByAgency({ agencyId: this.selectedAgencyFilter })
        //             .then(res => {
        //                 this.agentOptions = res.map(a => ({ label: a.ServiceResource.RelatedRecord.Name, value: a.ServiceResourceId }));
        //             })
        //             .catch(err => console.error(err));
        //     } else {
        //         // reload full agents
        //         getAllAgents().then(res => this.agentOptions = res.map(a => ({ label: a.ServiceResource.RelatedRecord.Name, value: a.ServiceResourceId }))).catch(err=>console.error(err));
        //     }
        // }
        // if (name === 'activityType') this.activityType = e.target.value;
        // if (name === 'agent') {
        //     this.selectedAgentFilter = e.target.value;
        //     // load agencies for filter if agent selected
        //     if (this.selectedAgentFilter) {
        //         getAgenciesByAgent({ agentServiceResourceId: this.selectedAgentFilter }).then(res => {
        //             this.agencyOptions = res.map(a => ({ label: a.Name, value: a.Id }));
        //         }).catch(err => console.error(err));
        //     } else {
        //         getAllAgencies().then(res => this.agencyOptions = res.map(a => ({ label: a.Name, value: a.Id }))).catch(err => console.error(err));
        //     }
        // }
    } 

    applyFilters() {
        this.pageNumber = 1;
        this.loadWorkOrders();
    }

    clearFilters() {

        console.log('clear filtters');
       
        this.location = null;
        this.pinCode = null;
        this.roadName=null;
        this.buildingName=null;
        this.loadInitialPicklists();
        this.pageNumber = 1;
        this.loadWorkOrders();
    } 

   /* clearFilters() {
        this.invoiceFrom = null;
        this.invoiceTo = null;
        this.location = null;
        this.status = null;
        this.pinCode = null;
        this.selectedAgencyFilter = null;
        this.activityType = null;
        this.selectedAgentFilter = null;
        // reload picklists
        this.loadInitialPicklists();
        this.pageNumber = 1;
        this.loadWorkOrders();
    } */

    // --------- load paged workorders
    loadWorkOrders() {
        this.isLoading = true;

        console.log('selected pincode::', this.pinCode);
        console.log('selected location ::', this.location);
        console.log('selected roadName::', this.roadName);
        console.log('selected buildingName ::', this.buildingName);
        getFilteredWorkOrders({
            pageSize: this.pageSize,
            pageNumber: this.pageNumber,
            //  accountName : this.accountName,
            //  assignedDate : this.assignedDate,
            //  attendedDate : this.attendedDate,
            //  appointmentStatus : this.appointmentStatus,
        //    invoiceFrom: this.invoiceFrom ? parseFloat(this.invoiceFrom) : null,
        //    invoiceTo: this.invoiceTo ? parseFloat(this.invoiceTo) : null,
           location: this.location,
           // status: this.status,
            pinCode: this.pinCode,
            roadName : this.roadName,
            buildingName : this.buildingName
            // agencyId: this.selectedAgencyFilter,
            // agentServiceResourceId: this.selectedAgentFilter,
            // activityType: this.activityType
        })
        .then(result => {
            console.log('=======result=======>', JSON.stringify(result));

            // flatten WorkType.Name so datatable can read it
            this.workOrders = result.records.map(row => ({
                ...row,
                WorkTypeName: row.WorkType?.Name || '—',
                AgencyName: row.ServiceTerritory?.Name || '-',
                AgentName: row.Agent__r?.Name  || '-',
                AccountName: row.Account?.Name  || '-',
                Location: row.Account?.Location__c || '-',
                PostalCode: row.Account?.Postal_Code__c || '-',
                BuildingName: row.Account?.Building_name__c || '-',
                RoadName: row.Account?.Road_Name__c || '-'

              // PostalCode: row.Account?.Postal_Code__c || '-',
             //  Work Type: row.Account?.Location__c || '-',


             //   Work Type: row.Account?.Location__c || '-',
                //Status: row?.Status || '-',
              //  PostalCode: row.Account?.Postal_Code__c || '-',
              //  Invoice: row.Account?.Inv_No__c || '-'
            }));

            this.totalSize = result.totalSize || 0;
            this.totalPages = Math.ceil(this.totalSize / this.pageSize) || 1;
            this.pagedData = this.workOrders; // already paged on server
            this.selectedWorkOrderIds = []; // reset selection on new load
        })
        .catch(error => {
            console.error('Failed to load workorders', error);
            this.showToast('Error', 'Failed to load workorders', 'error');
        })
        .finally(() => this.isLoading = false);
    }

    // row selection
    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedWorkOrderIds = selectedRows.map(r => r.Id);
        this.selectedCount = selectedRows.length;
        console.log('selected workorder ids::', JSON.stringify(this.selectedWorkOrderIds));
        if(this.selectedWorkOrderIds){

            console.log('inside if workorder ids');

         this.selectedWorkOrderId = this.selectedWorkOrderIds;


          //  this.isAssignDisabled=true;
        }
        if(!this.selectedWorkOrderIds){

            console.log('inside workorder id empty');

           // this.isAssignDisabled=false;
        }
    }

    // handleAssign(){

    //     if(this.selectedWorkOrderIds){

    //   this.selectedWorkOrderId = this.selectedWorkOrderIds;

    //   console.log('inside handle assign::', JSON.stringify(this.selectedWorkOrderId));

    //     this.showAssignToAgentPage=true;
    //     this.showWorkOrderData=false;

    //     }


    // }

    handleCancel() {
   // this.showAssignToAgentPage = false;
    this.showWorkOrderData = false;
            this.dispatchEvent(new CustomEvent('cancel'));

    this.loadWorkOrders();
    this.selectedWorkOrderIds=[];
    this.selectedWorkOrderId=[];
    this.selectedCount='';
}



    // --------- Assignment panel - mutual filtering & handlers
   /* handleAgencyAssignChange(e) {
        this.selectedAgencyForAssign = e.detail.value;

        console.log('===========this.selectedAgencyForAssign==========>', JSON.stringify(this.selectedAgencyForAssign));

        //fetch agents for this agency to show in assign agent dropdown
        if (this.selectedAgencyForAssign) {
            getAgentsByAgency({ agencyId: this.selectedAgencyForAssign })
                .then(res => {
                    this.agentOptionsForAssign = res.map(a => ({ label: a.ServiceResource.RelatedRecord.Name, value: a.ServiceResourceId }));
                    // If currently selected agent is not in list, clear it
                    const ids = this.agentOptionsForAssign.map(x => x.value);
                    if (!ids.includes(this.selectedAgentForAssign)) this.selectedAgentForAssign = null;
                })
                .catch(err => console.error(err));
        } else {
            // reload all agents
            getAllAgents().then(res => this.agentOptionsForAssign = res.map(a => ({ label: a.ServiceResource.RelatedRecord.Name, value: a.ServiceResourceId }))).catch(err=>console.error(err));
        }
    } 

    handleAgentAssignChange(e) {
        this.selectedAgentForAssign = e.detail.value;
        // fetch agencies for selected agent
        if (this.selectedAgentForAssign) {
            getAgenciesByAgent({ agentServiceResourceId: this.selectedAgentForAssign })
                .then(res => {
                    this.agencyOptions = res.map(a => ({ label: a.Name, value: a.Id }));

                    console.log('===========this.agencyOptions==========>', JSON.stringify(this.agencyOptions));
                    if(this.agencyOptions){
                        this.selectedAgencyForAssign = this.agencyOptions[0].value;
                    }

                    // If currently selected agency is not in list, clear it
                    const ids = this.agencyOptions.map(x => x.value);
                    if (!ids.includes(this.selectedAgencyForAssign)) this.selectedAgencyForAssign = null;
                })
                .catch(err => console.error(err));
        } else {
            getAllAgencies().then(res => this.agencyOptions = res.map(a => ({ label: a.Name, value: a.Id }))).catch(err=>console.error(err));
        }
    }

    handleWorkTypeChange(e) {
        this.selectedWorkTypeForAssign = e.detail.value;
    }
    handleStartDateChange(e) {
        this.startDateForAssign = e.target.value;
    }
    handleEndDateChange(e) {
        this.endDateForAssign = e.target.value;
    } 

    // reset assign panel
    handleResetAssign() {
        this.selectedAgencyForAssign = null;
        this.selectedAgentForAssign = null;
        this.selectedWorkTypeForAssign = null;
        this.startDateForAssign = null;
        this.endDateForAssign = null;
        this.loadInitialPicklists();
    } */

    // assign button state
    // get isAssignDisabled() {
    //     const allFields = this.selectedAgencyForAssign && this.selectedAgentForAssign && this.selectedWorkTypeForAssign && this.startDateForAssign && this.endDateForAssign && (this.selectedWorkOrderIds && this.selectedWorkOrderIds.length > 0);
    //     if (!allFields) return true;
    //     // check date validity
    //     // startDateForAssign and endDateForAssign are strings 'YYYY-MM-DD'
    //     return (this.startDateForAssign > this.endDateForAssign);
    // }
    // get isAssignDisabled() {
    //     const allFieldsFilled = this.selectedAgencyForAssign 
    //         && this.selectedAgentForAssign 
    //         && this.selectedWorkTypeForAssign 
    //         && this.startDateForAssign 
    //         && this.endDateForAssign 
    //         && (this.selectedWorkOrderIds && this.selectedWorkOrderIds.length > 0);

    //     if (!allFieldsFilled) return true;

    //     return new Date(this.startDateForAssign) > new Date(this.endDateForAssign);
    // }


    // assign action
  /*  handleAssign() {
        if (this.isAssignDisabled) {
            if (this.startDateForAssign && this.endDateForAssign && this.startDateForAssign > this.endDateForAssign) {
                this.showToast('Error', 'End Date cannot be earlier than Start Date', 'error');
            } else {
                this.showToast('Error', 'Please fill all required fields and select Work Orders.', 'error');
            }
            return;
        }

        console.log('=======this.selectedWorkOrderIds=======>', JSON.stringify(this.selectedWorkOrderIds) );
        console.log('=======this.selectedAgencyForAssign=======>', JSON.stringify(this.selectedAgencyForAssign) );
        console.log('=======this.selectedAgentForAssign=======>', JSON.stringify(this.selectedAgentForAssign) );
        console.log('=======this.selectedWorkTypeForAssign=======>', JSON.stringify(this.selectedWorkTypeForAssign) );
        console.log('=======this.startDateForAssign=======>', JSON.stringify(this.startDateForAssign) );
        console.log('=======this.endDateForAssign=======>', JSON.stringify(this.endDateForAssign) );

        this.isAssignLoading = true;
        //Call Apex
        assignAgency({
            workOrderIds: this.selectedWorkOrderIds,
            agencyId: this.selectedAgencyForAssign,
            agentId: this.selectedAgentForAssign,
            workTypeId: this.selectedWorkTypeForAssign,
            startDate: this.startDateForAssign,
            endDate: this.endDateForAssign
        })
        .then(()=> {
            this.showToast('Success', 'Assigned successfully', 'success');
            // reload table (page)
            this.loadWorkOrders();
            // reset assign panel if desired
            // this.handleResetAssign();
        })
        .catch(error => {
            console.error('Assign failed', error);
            const msg = (error?.body?.message) ? error.body.message : 'Assignment failed';
            this.showToast('Error', msg, 'error');
        })
        .finally(()=> {
            this.isAssignLoading = false;
        });
    }  */

    // utilities
    showToast(title, msg, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message: msg, variant }));
    } 

    // helper to compute pagedData if needed (server already returns paged, but keep for safety)
    // get pagedData() {
    //     return this.workOrders;
    // }

    // computed totalPages
    // get totalPages() {
    //     return Math.max(1, Math.ceil((this.totalSize || 0) / this.pageSize));
    // }
}