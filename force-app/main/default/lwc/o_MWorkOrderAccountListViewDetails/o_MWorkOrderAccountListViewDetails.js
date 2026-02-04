/**
 * @description       : O&M Work Order Account List View – Full Online + Offline Parity
 * @author            : Appstrail
 * @last modified on  : 07-11-2025
 * @last modified by  : Appstrail
 */
import { LightningElement, track, api, wire } from 'lwc';
import getAppointmentByStatus from '@salesforce/apex/O_MWorkOrderAccountListViewDetailsContr.getAppointmentByStatus';
import { NavigationMixin } from 'lightning/navigation';
import getWorkOrderIdFromSA from '@salesforce/apex/O_MWorkOrderAccountListViewDetailsContr.getWorkOrderIdFromSA';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import FORM_FACTOR from '@salesforce/client/formFactor';

// ====== GraphQL (offline only) ======
import { gql, graphql } from 'lightning/uiGraphQLApi';
import userId from '@salesforce/user/Id';
import { getRecord } from 'lightning/uiRecordApi';

// ====== Constants ======
const RECORDTYPE_DEVNAME_OM = 'MGL_O_M';
const ENABLE_OFFLINE = true;
const FIELDS = ['ServiceAppointment.ParentRecordId'];


// GraphQL query to mirror Apex WHERE
const GQL_OFFLINE = gql`
  query OfflineOandMAppointments($userId: ID!) {
    uiapi {
      query {
        AssignedResource(
          where: { ServiceResource: { RelatedRecordId: { eq: $userId } } }
          first: 2000
        ) {
          edges {
            node {
              Id
              ServiceAppointment {
                Id
                Status { value }
                Appointment_Type__c { value }
                SchedStartTime { value }
                SchedEndTime { value }
                Schedule_Start_Date__c { value }
                Schedule_End_Date__c { value }
                Account {
                  Id
                  Name { value }
                  BP_Number__c { value }
                  Street__c { value }
                  Colony__c { value }
                  Wing__c { value }
                  Floor__c { value }
                  Flat__c { value }
                  Road_name__c { value }
                  FirstName__c { value }
                  LastName__c { value }
                }
                ParentRecord {
                  ... on WorkOrder {
                    Id
                    RecordType { DeveloperName { value } }
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

export default class O_MWorkOrderAccountListViewDetails extends NavigationMixin(LightningElement) {
  // ====== Existing properties ======
  @track appointmentGroups = [];
  @track error;
  @track flag = true;
  @track isLoading = false;
  @api openMainPage;
  @api showDashboard;
  @track openAcc360 = false;
  @track selectedServiceAppointmentId;
  @track groupSelected = false;
  @track hasAppointments = false;

  @track appointmentResult = [];
  @track allAppointmentsList = [];
  @api selectedType;
  @api secondPage;
  searchToggle = false;
  @api showAppointmentScreen;
  @track appointmentsList = [];
  appointmentsListMain = [];
  allAppointments = [];
  statusMap;
  appointmentSearchToggle = false;
  @track isOnline = navigator.onLine;

  // ====== Accessors ======
  _selectedStatus;
  @api
  get selectedStatus() {
    return this._selectedStatus;
  }
  set selectedStatus(value) {
    this._selectedStatus = value;
    if (this.secondPage) {
      this.getAppointmentByStatus();
    }
  }

  @track selectedAppointment;
_serviceAppointmentIdForWire;


    get serviceAppointmentIdForWire() 
    { 
        return this._serviceAppointmentIdForWire; 
    }

  // ====== Connected Callbacks ======
  connectedCallback() {
    if (navigator.onLine) {
      this.getAppointmentByStatus();
    }
  }

  disconnectedCallback() {
    clearInterval(this.pollingInterval);
  }

  // ====== ONLINE (Apex) ======
  getAppointmentByStatus() {
    if (!this.isOnline) return; // skip if offline

    this.isLoading = true;
    this.hasAppointments = false;
    this.appointmentsList = [];

    getAppointmentByStatus({ status: this.selectedStatus, type: this.selectedType })
      .then(result => {
        this.appointmentResult = result.map(sa => {
          let formattedDate = '';
          if (sa.SchedStartTime) {
            let dateObj = new Date(sa.SchedStartTime);
            let day = String(dateObj.getDate()).padStart(2, '0');
            let month = String(dateObj.getMonth() + 1).padStart(2, '0');
            let year = dateObj.getFullYear();
            formattedDate = `${day}-${month}-${year}`;
          }
          return { ...sa, formattedSchedStartTime: formattedDate };
        });
        this.allAppointmentsList = [...this.appointmentResult];
        this.isLoading = false;
      })
      .catch(error => {
        this.isLoading = false;
        console.error('Online error:', error);
        this.showToast('Error', 'Failed to load appointments (online).', 'error');
      });
  }

  // ====== OFFLINE (GraphQL) ======
  get gqlVars() {
    return { userId };
  }

  @wire(graphql, { query: GQL_OFFLINE, variables: '$gqlVars' })
  wiredOffline(result) {
    if (navigator.onLine || !ENABLE_OFFLINE) return; // run only when offline

    const { data, errors } = result || {};
    if (errors && errors.length) {
      this.showToast('GraphQL', 'Error loading offline data.', 'error');
      return;
    }
    if (!data) return;

        try {
            const ui = data?.uiapi?.query || null;
            if (!ui) {
                //this.showToast('GraphQL', 'No UIAPI query data returned.', 'error');
                this.isLoading = false;
                return;
            }

            const assignedEdges = ui.AssignedResource?.edges || [];
            //this.showToast('GraphQL Debug', `AssignedResource edges: ${assignedEdges.length}`, 'info');

            const allSA = assignedEdges.map(e => e?.node?.ServiceAppointment).filter(Boolean);
            //this.showToast('GraphQL Debug', `Total SA fetched: ${allSA.length}`, 'info');

            const snapshotStatus = (this.selectedStatus || '').trim().toLowerCase();
            const completed = new Set(['Completed']);
            const incomplete = new Set(['Cannot Complete', 'In Progress']);
            const unattempted = new Set(['None', 'Scheduled', 'Dispatched']);
            const totalStatuses = new Set(['Canceled', 'Cancelled', 'Completed', 'Cannot Complete', 'In Progress', 'Dispatched', 'Scheduled', 'None']);
            let targetStatuses = totalStatuses;
            if (snapshotStatus === 'completed') targetStatuses = completed;
            else if (snapshotStatus === 'incomplete') targetStatuses = incomplete;
            else if (snapshotStatus === 'unattempted') targetStatuses = unattempted;
            else if (snapshotStatus === 'total') targetStatuses = totalStatuses;

            const step1 = allSA.filter(sa =>
                sa?.ParentRecord?.RecordType?.DeveloperName?.value === 'MGL_O_M'
            );
            //this.showToast('Step 1', `RecordType = MGL_O_M → ${step1.length}`, 'info');

            const step2 = step1.filter(sa => targetStatuses.has(sa?.Status?.value));
            //this.showToast('Step 2', `Status filter (${this.selectedStatus || 'All'}) → ${step2.length}`, 'info');

           const todayStr = new Date().toISOString().split('T')[0];

            const filtered = step2.filter(sa => {
            const startVal = sa?.Schedule_Start_Date__c?.value || null;
            const endVal   = sa?.Schedule_End_Date__c?.value || null;
            const start = startVal ? startVal.split('T')[0] : null;
            const end   = endVal   ? endVal.split('T')[0]   : null;

            const inWindow = !start || todayStr >= start;
            const hasStart = !!sa?.SchedStartTime?.value;

            return inWindow && hasStart;
            });

            // this.showToast(
            // 'Final Filter',
            // `After relaxed date/time normalization → ${filtered.length}`,
            // filtered.length > 0 ? 'success' : 'warning'
            // );


            if (filtered.length === 0 && step2.length > 0) {
                const sample = step2[0];
                // this.showToast(
                //     'Sample SA Debug',
                //     `Start=${sample?.Schedule_Start_Date__c?.value || 'NA'} | End=${sample?.Schedule_End_Date__c?.value || 'NA'} | SchedStart=${sample?.SchedStartTime?.value || 'NA'}`,
                //     'info'
                // );
            }

            this.appointmentResult = filtered.map(sa => {
                let formattedDate = '';
                if (sa?.SchedStartTime?.value) {
                    const dateObj = new Date(sa.SchedStartTime.value);
                    const day = String(dateObj.getDate()).padStart(2, '0');
                    const month = String(dateObj.getMonth() + 1).padStart(2, '0');
                    const year = dateObj.getFullYear();
                    formattedDate = `${day}-${month}-${year}`;
                }

                return {
                    Id: sa.Id,
                    Status: sa.Status?.value,
                    Appointment_Type__c: sa.Appointment_Type__c?.value,
                    formattedSchedStartTime: formattedDate,
                    Account: {
                        Name: sa.Account?.Name?.value,
                        BP_Number__c: sa.Account?.BP_Number__c?.value,
                        Street__c: sa.Account?.Street__c?.value,
                        Wing__c: sa.Account?.Wing__c?.value,
                        Colony__c: sa.Account?.Colony__c?.value,
                        Floor__c: sa.Account?.Floor__c?.value,
                        Flat__c: sa.Account?.Flat__c?.value,
                        Road_name__c: sa.Account?.Road_name__c?.value,
                        FirstName__c: sa.Account?.FirstName__c?.value,
                        LastName__c: sa.Account?.LastName__c?.value
                    }
                };
            });

            this.allAppointmentsList = [...this.appointmentResult];

            // this.showToast(
            //     'GraphQL',
            //     `Loaded ${this.appointmentResult.length} O&M Appointments (offline)`,
            //     this.appointmentResult.length > 0 ? 'success' : 'warning'
            // );

            this.isLoading = false;

        } catch (err) {
            console.error('GraphQL Offline Error:', err);
            this.showToast('GraphQL Error', JSON.stringify(err), 'error');
            this.isLoading = false;
        }
  }

    @wire(getRecord, { recordId: '$serviceAppointmentIdForWire', fields: FIELDS })
    wiredServiceAppointment({ error, data }) {
    if (data) {
        const workOrderId = data.fields.ParentRecordId.value;
        if (workOrderId) {
        this.navigateToWorkOrderInFSL(workOrderId);
        } else {
        this.showToast('Missing Work Order', `No Work Order is associated with Service Appointment.`, 'warning');
        }
    } else if (error) {
        this.showToast('Error', 'Could not load Service Appointment record.', 'error');
        console.error(error);
    }
    }


  // ====== UI Logic (unchanged) ======
  handleSearch() {
    this.searchToggle = !this.searchToggle;
  }

  handleBacktoaddress() {
    this.showAppointmentScreen = false;
    this.flag = true;
    const event = new CustomEvent('childevent', {
      detail: { showDashboard: true, openMainPage: true }
    });
    this.dispatchEvent(event);
  }

  handleBack() {
    this.showDashboard = true;
    this.openMainPage = true;
    this.refreshAppointments();
    const event = new CustomEvent('childevent', {
      detail: { showDashboard: this.showDashboard, openMainPage: this.openMainPage }
    });
    this.dispatchEvent(event);
  }

  toggleBuilding(event) {
    this.isLoading = true;
    this.groupSelected = true;
    this.flag = false;
    const buildingName = event.currentTarget.dataset.building;
    this.appointmentsList = [];
    this.appointmentsListMain = [];
    this.appointmentGroups = this.appointmentGroups.map(group => {
      if (group.buildingName === buildingName) {
        this.appointmentsList = group.appointments;
        return { ...group, isExpanded: !group.isExpanded };
      }
      return group;
    });
    this.appointmentsListMain = JSON.parse(JSON.stringify(this.appointmentsList));
    this.isLoading = false;
  }

  filterAppointmentSearch(event) {
    const searchValue = (event.detail.value || '').toLowerCase();
    if (searchValue) {
      this.appointmentResult = this.allAppointmentsList.filter(group => {
        const acc = group.Account || {};
        return (
          (acc.Name && acc.Name.toLowerCase().includes(searchValue)) ||
          (acc.BP_Number__c && acc.BP_Number__c.toLowerCase().includes(searchValue)) ||
          (acc.Street__c && acc.Street__c.toLowerCase().includes(searchValue)) ||
          (acc.Colony__c && acc.Colony__c.toLowerCase().includes(searchValue)) ||
          (acc.Wing__c && acc.Wing__c.toLowerCase().includes(searchValue)) ||
          (acc.Flat__c && acc.Flat__c.toLowerCase().includes(searchValue)) ||
          (group.Status && group.Status.toLowerCase().includes(searchValue))
        );
      });
    } else {
      this.appointmentResult = [...this.allAppointmentsList];
    }
  }

//   handleAppointmentClick(event) {
//     this.isLoading = false;
//     const serviceAppointmentId = event.currentTarget.dataset.id;
//     getWorkOrderIdFromSA({ serviceAppointmentId })
//       .then(workOrderId => {
//         if (workOrderId) {
//           this.navigateToWorkOrderInFSL(workOrderId);
//         } else {
//           this.showToast('Missing Work Order', 'No Work Order associated with this Appointment.', 'warning');
//         }
//       })
//       .catch(() => {
//         this.showToast('Error', 'Error fetching Work Order.', 'error');
//       })
//       .finally(() => {
//         this.isLoading = false;
//       });
//   }

    handleAppointmentClick(event) {

      console.log('inside hanlde appointment open');
    this.isLoading = true;
    const serviceAppointmentId = event.currentTarget.dataset.id;
    this.selectedAppointment = this.appointmentResult.find(item => item.Id === serviceAppointmentId);

    // if (this.selectedAppointment && this.selectedAppointment.Status === 'Completed') {
    //   console.log('inside status completed');
    //     this.isLoading = false;
    //     return;
    // }

    // LDS will handle offline navigation automatically
    this._serviceAppointmentIdForWire = serviceAppointmentId;
    this.isLoading = false;
    }



  navigateToWorkOrderInFSL(workOrderId) {
    if (FORM_FACTOR === 'Large') {
      this[NavigationMixin.Navigate]({
        type: 'standard__recordPage',
        attributes: { recordId: workOrderId, actionName: 'view' }
      });
    } else {
      this[NavigationMixin.Navigate]({
        type: 'standard__webPage',
        attributes: { url: `com.salesforce.fieldservice://v1/sObject/${workOrderId}/overview` }
      });
    }
  }

  // ====== Helper Methods ======
  formatDateDDMMYYYY(date) {
    const d = String(date.getDate()).padStart(2, '0');
    const m = String(date.getMonth() + 1).padStart(2, '0');
    const y = date.getFullYear();
    return `${d}-${m}-${y}`;
  }

  showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant, mode: 'dismissable' }));
  }
}