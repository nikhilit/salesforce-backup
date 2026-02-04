import { LightningElement, api, track,wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import FORM_FACTOR from '@salesforce/client/formFactor';

import getFlatAppointments from '@salesforce/apex/IcDashboardController.getFlatAppointmentsByStatus';
import getWorkOrderIdFromSA from '@salesforce/apex/IcDashboardController.getWorkOrderIdFromSA';


// --- OFFLINE GRAPHQL IMPORTS ---
import { gql, graphql } from 'lightning/uiGraphQLApi';
//import USER_ID from '@salesforce/user/Id';

// --- GRAPHQL QUERY ---
const USER_ID = '005fs0000001xfZAAQ';

const GET_OFFLINE_DATA = gql`

query getOfflineAppointments($userId: ID!) {
  uiapi {
    query {
      AssignedResource(
        where: { ServiceResource: { RelatedRecordId: { eq: $userId } } }
        first: 1000
      ) {
        edges {
          node {
            Id
            ServiceAppointment {
              Id
              Status { value }
              Subject { value }
              SchedEndTime { value }
              Visit_Status__c { value }
              Due_Amount__c { value }
              Appointment_Type__c { value }
              Random_Visit_Date__c { value }
              Follow_Up_Visit_Date__c { value }

              Account {
                Id
                Name { value }
                BP_Number__c { value }
                CA_Number__c { value }
                Street__c { value }
                Street_Line_2__c { value }
                Street_Line_3__c { value }
                Street_Line_5__c { value }
                Road_name__c { value }
                Room__c { value }
                Floor__c { value }
                Wing__c { value }
                Colony__c { value }
                Other_City__c { value }
              }

              ParentRecord {
                ... on WorkOrder {
                  Id
                  Status { value }
                  Payment_Mode__c { value }
                  Follow_up_Date__c { value }
                  Follow_up_Remarks__c { value }
                  New_Flat__c { value }
                  New_Floor__c { value }
                  New_Wing__c { value }
                  New_Plot__c { value }
                  New_Road_Name__c { value }
                  New_Landmark__c { value }
                  New_Colony__c { value }
                  New_Location__c { value }
                  City__c { value }
                  DISTRICT__c { value }

                  Customer_BP_Number__c { value }
                  CA_Number__c { value }
                  Customer_Name__c { value }

                  WorkType {
                    Id
                    Name { value }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
`;

export default class IcAppointmentListViewClone extends NavigationMixin(LightningElement) {

    _selectedStatus;
    userId = USER_ID;

    @api
    get selectedStatus() {
        return this._selectedStatus;
    }

    set selectedStatus(value) {
        this._selectedStatus = value;

        // Only react when coming from second page
        if (!this.secondPage) {
            return;
        }

        if (this.isOnline) {
            // ONLINE → Apex
            this.fetchAppointments();
        } else {
            // OFFLINE → Use Wire
            if (!this.offlineDataLoaded) {
                this.offlineKey++; // force wire to execute
            }
        }
    }

    @api selectedType;
    @api secondPage;
    @track appointmentsList = [];
    allAppointmentList = [];

    workTypeSearchToggle = false;

    @track hasAppointments = false;
    appointmentSearchToggle = false;

    isOnline = navigator.onLine;
    isOfflineMode = false;

    offlineKey = 0;
    offlineDataLoaded = false;

    @track workTypeList = [];
    @track allWorkType = [];
    @track hasWorkType = false;
    @track isLoading = true;
    @track error;

    
    connectedCallback() {
        window.addEventListener('online', this.handleNetworkChange);
        window.addEventListener('offline', this.handleNetworkChange);
        console.log('Offline ServiceResourceId used:', this.userId);
        console.log('========this.selectedStatus======>>>>', this.selectedStatus);
        console.log('========this.selectedType======>>>>', this.selectedType);

        if(this.isOnline){
            this.fetchAppointments();
        }
    }

    disconnectedCallback() {
        window.removeEventListener('online', this.handleNetworkChange);
        window.removeEventListener('offline', this.handleNetworkChange);
    }

    handleNetworkChange = () => {
        const wasOnline = this.isOnline;
        this.isOnline = navigator.onLine;

        // Online → Offline transition
        if (wasOnline && !this.isOnline) {
            this.offlineDataLoaded = false;
            this.offlineKey++;
        }

        // Offline → Online
        if (!wasOnline && this.isOnline) {
            this.offlineDataLoaded = false;
            this.fetchAppointments();
        }
    }

    //Debug Helper
      debugToast(title, message) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: 'info',
                mode: 'dismissable'
            })
        );
    }

// =================================================================
// ONLINE LOGIC 
// =================================================================

//Online Logic, fetching Appointments from Apex    

    fetchAppointments() {
        // Start loading and clear previous data
        this.isLoading = true;
        this.error = undefined;

        getFlatAppointments({ status: this.selectedStatus, type: this.selectedType })
        .then((result) => {

            console.log('======getFlatAppointments=========>', JSON.stringify(result));


            if (result && result.length > 0) {
                this.workTypeList = result;
                this.allWorkType = result;
                this.hasWorkType = true;
            }else{
                this.hasWorkType = true;
            }
            
            this.isLoading = false;
        })
        .catch((error) => {
            console.error('Error fetching appointments:', error);
            this.error = error?.body?.message || error?.message || 'Unknown error occurred while fetching appointments.';
            this.isLoading = false;
        });
    }


//Get Appointments based on WorkType for both Online and Offline

    getAppointments(workType){

        if(this.allWorkType && workType){

            let appointments = this.allWorkType.filter(wrk => wrk.name === workType).map(wT => wT.appointments);
            appointments = appointments[0];

            this.appointmentsList = appointments.map(item => ({
                ...item,
                formattedSchedEndDate: item.SchedEndTime
                    ? new Date(item.SchedEndTime).toLocaleDateString('en-IN', {
                        day: '2-digit',
                        month: 'short',
                        year: 'numeric'
                    })
                    : '',
                formattedDueAmount: item.DueAmount ? `₹${item.DueAmount}` : '₹0',
                label: item.appointmentType || '',
                accountName: item.accountName || '',
                // DetailAccountSummary: item.buildingStreet || ''
            }));

            this.allAppointmentList = JSON.parse(JSON.stringify(this.appointmentsList));

            this.hasAppointments = true;
            
            this.isLoading = false;

        }else {
            this.appointmentsList = [];
            this.allAppointmentList = [];
        }
    }

//Handle WorkType click

    handleWorkTypeClick(event){ 
        this.isLoading = true;
        this.hasWorkType = false;
        const workTypeName = event.currentTarget.dataset.name;
        this.getAppointments(workTypeName);
    }

//Handle Back click

    handleBackToAppointment(){
        this.hasWorkType = true;
        this.hasAppointments = false;
    }

//Handle Appointment click both online and offline

    handleAppointmentClick(event) {
        this.isLoading = true;
        const serviceAppointmentId = event.currentTarget.dataset.id;
        const workOrderIdFromDataset = event.currentTarget.dataset.workOrderId;

        console.log('SA ID:', serviceAppointmentId);
        console.log('WO ID:', workOrderIdFromDataset);

         //  OFFLINE MODE
        if (!this.isOnline) {
            if (workOrderIdFromDataset) {
                this.navigateOfflineFSL(workOrderIdFromDataset);
            } else {
                this.debugToast('Offline Error', 'Work Order not available offline');
            }
            this.isLoading = false;
            return;
        }

        //  ONLINE MODE
        getWorkOrderIdFromSA({ serviceAppointmentId })

        .then(workOrderId => {
            if (workOrderId) {
                this.navigateToWorkOrderInFSL(workOrderIdFromDataset);
            } else {
                this.showToast(
                    'Missing Work Order',
                    `No Work Order is associated with this Service Appointment.\nServiceAppointmentId: ${serviceAppointmentId}`,
                    'warning'
                );
                console.error('No Work Order ID returned from Apex.');
            }
        })
        .catch(error => {
            let errorMessage = 'An error occurred while fetching the Work Order.';
            if (error?.body?.message) {
                errorMessage = error.body.message;
            } else if (error?.message) {
                errorMessage = error.message;
            }
            this.showToast('Error', errorMessage, 'error');
            console.error('Error fetching Work Order ID:', error);
        })
        .finally(() => {
            this.isLoading = false;
        });

    }
    

    handleAppointmentSearch(){
        this.appointmentSearchToggle = !this.appointmentSearchToggle;
    }

    handleWorkTypeSearch(){
        this.workTypeSearchToggle = !this.workTypeSearchToggle;
    }

    filterAppointmentSearch(event) {
        var value = event.detail.value;
        this.appointmentsList = [];
        if (value && value != '') {
            this.appointmentsList = this.allAppointmentList.filter(group => {
                const searchValue = value.toLowerCase();
                return (
                    (group.accountName && group.accountName.toLowerCase().includes(searchValue)) ||
                    (group.DetailAccountSummary && group.DetailAccountSummary.toLowerCase().includes(searchValue)) ||
                    (group.formattedDueAmount && group.formattedDueAmount.toString().toLowerCase().includes(searchValue))
                );
            });
        } else {
            this.appointmentsList = this.allAppointmentList;
        }
    }

    filterWorkTypeSearch(event) {
        var value = event.detail.value;
        this.workTypeList = [];
        if (value && value != '') {
            this.workTypeList = this.allWorkType.filter(group => {
                const searchValue = value.toLowerCase();
                return (group.name && group.name.toLowerCase().includes(searchValue));
            });
        } else {
            this.workTypeList = this.allWorkType;
        }
    }

    navigateToWorkOrderInFSL(workOrderId) {
        if (FORM_FACTOR === 'Large') {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: workOrderId,
                    actionName: 'view',
                },
            });
        } else {
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: `com.salesforce.fieldservice://v1/sObject/${workOrderId}/overview`
                }
            });
        }
    }

    navigateOfflineFSL(workOrderId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: workOrderId,
                actionName: 'view'
            }
        });
    }

    handleBackToHome() {
        // Reset the state
        this.secondPage = false;
        this.openMainPage = true;

        // Clear appointments data so next time fetch gets fresh result
        this.appointmentsList = [];
        this.error = undefined;

        // Dispatch event to parent
        const event = new CustomEvent('childevent', {
            detail: {
                secondPage: this.secondPage,
                openMainPage: this.openMainPage
            }
        });
        this.dispatchEvent(event);
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }


// =================================================================
// OFFLINE LOGIC 
// =================================================================

//Offline Logic, fetching Appointments from graphql 

    get dataVars() {
        return {
            userId: this.userId,
            selectedStatus: this.selectedStatus,
            selectedType: this.selectedType,
            offlineKey: this.offlineKey
        };
    }

    // 🔹 WIRE GRAPHQL OFFLINE
    @wire(graphql, {
        query: GET_OFFLINE_DATA,
        variables: '$dataVars'
    })
    wiredOfflineAppointments({ data, errors }) {
        // Only process if offline
        if (this.isOnline) return;

        this.isLoading = true;
        this.error = undefined;

        if (errors) {
            console.error('Offline GraphQL error:', errors);
            this.workTypeList = [];
            this.allWorkType = [];
            this.hasWorkType = true;
            this.isLoading = false;
            return;
        }


        if (!data?.uiapi?.query?.AssignedResource) {
            this.workTypeList = [];
            this.allWorkType = [];
            this.hasWorkType = true;
            this.isLoading = false;
            return;
        }

        try {
            this.debugToast('✅ Offline GraphQL RAW DATA:',data?.length)
            this.processOfflineData(data); // Step 3: flatten & group
            this.offlineDataLoaded = true;
        } catch (e) {
            console.error('Offline flattening error:', e);
            console.error('STACK:', e?.stack);
            this.workTypeList = [];
            this.allWorkType = [];
            this.hasWorkType = true;
        }

        this.isLoading = false;
    }

//Process raw data from Graphql, Map WorkType and its count

    processOfflineData(data) {
        const edges = data?.uiapi?.query?.AssignedResource?.edges || [];
        this.debugToast('Edges:',JSON.stringify(edges))
        // 1️⃣ Flatten Service Appointments

        let serviceAppointments = edges
            .map(e => e?.node?.ServiceAppointment)
            .filter(Boolean);


        // 2️⃣ STATUS FILTER (matches Apex)
        if (this.selectedStatus && this.selectedStatus !== 'Total') {
            const status = this.selectedStatus.toLowerCase();

            const statusMap = {
                completed: ['Completed'],
                incomplete: ['Cannot Complete'],
                unattempted: ['None', 'Scheduled', 'In Progress', 'Dispatched']
            };

            const allowedStatuses = statusMap[status];

            if (allowedStatuses) {
                serviceAppointments = serviceAppointments.filter(
                    sa => allowedStatuses.includes(sa?.Status?.value)
                );
            }
        }

        // 3️⃣ TYPE FILTER (matches Apex)
        if (!this.selectedStatus && this.selectedType) {
            if (this.selectedType === 'Follow Up') {
                serviceAppointments = serviceAppointments.filter(
                    sa => sa?.Appointment_Type__c?.value === 'Follow Up'
                );
            } 
            else if (this.selectedType === 'Random') {
                serviceAppointments = serviceAppointments.filter(
                    sa => sa?.Appointment_Type__c?.value === 'Random'
                );
            }
        }

        // 4️⃣ GROUP BY WORK TYPE
        const grouped = {};
        serviceAppointments.forEach(sa => {
            
            const workTypeName = sa?.ParentRecord?.WorkType?.Name?.value;
            this.debugToast('Worktype name:',workTypeName)
            
            if (!grouped[workTypeName]) {
                grouped[workTypeName] = [];
            }

            grouped[workTypeName].push(this.normalizeOfflineSA(sa));
        });

        // 5️⃣ BUILD FINAL STRUCTURE (same as Apex)
        const result = Object.keys(grouped).map(name => ({
            name,
            count: grouped[name].length,
            appointments: grouped[name]
        }));

        console.log('Result',result);
        
        // 6️⃣ ASSIGN (🔥 EXACT Apex parity)
        this.workTypeList = result;
        this.allWorkType = result;
        this.hasWorkType = true;
    }

    normalizeOfflineSA(sa) {
        const wo = sa?.ParentRecord || {};
        const acct = sa?.Account || {};

        console.log('normalizeOfflineSA', sa)

        return {
            // 🔑 REQUIRED IDS
            id: sa.Id,
            workOrderId: wo?.Id,   // 👈 CRITICAL for offline navigation

            // 🔹 BASIC INFO
            subject: sa?.Subject?.value || '',
            status: sa?.Status?.value || '',
            visitStatus: sa?.Visit_Status__c?.value || '',

            // 🔹 DATES
            SchedEndTime:
                wo?.Follow_up_Date__c?.value
                    ? wo.Follow_up_Date__c.value
                    : sa?.SchedEndTime?.value,

            // 🔹 MONEY
            DueAmount: sa?.Due_Amount__c?.value || 0,

            // 🔹 TYPE FLAGS
            appointmentType:
                sa?.Appointment_Type__c?.value || 'Scheduled',

            isRandomVisit: Boolean(sa?.Random_Visit_Date__c?.value),
            isDirectPayment:
                wo?.Status?.value === 'Completed' &&
                wo?.Payment_Mode__c?.value === 'Directly Paid by Customer',

            // 🔹 ACCOUNT
            accountName: acct?.Name?.value || '',
            bpNumber: wo?.Customer_BP_Number__c?.value || '',
            caNumber: wo?.CA_Number__c?.value || '',
            customerName: wo?.Customer_Name__c?.value || '',

            // 🔹 LOCATION (same fallback logic as Apex)
            location:
                wo?.New_Location__c?.value ||
                acct?.Other_City__c?.value ||
                'Unknown Location',

            // 🔹 ADDRESS SUMMARY (minimal but safe)
            DetailAccountSummary: [
                wo?.Building_Name__c?.value || acct?.Street_Line_2__c?.value,
                wo?.New_Flat__c?.value || acct?.Room__c?.value,
                wo?.New_Floor__c?.value || acct?.Floor__c?.value,
                wo?.New_Wing__c?.value || acct?.Wing__c?.value,
                wo?.New_Road_Name__c?.value || acct?.Street_Line_5__c?.value,
                wo?.New_Landmark__c?.value || acct?.Street_Line_3__c?.value,
                wo?.New_Location__c?.value || acct?.Other_City__c?.value
            ]
                .filter(Boolean)
                .join(', ')
        };
    }
}