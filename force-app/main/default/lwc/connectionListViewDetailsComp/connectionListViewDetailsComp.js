import { LightningElement, track, api, wire } from 'lwc';
import getAppointmentByStatus from '@salesforce/apex/connectionListViewDetailsContr.getAppointmentByStatus';
import { NavigationMixin } from 'lightning/navigation';
import getWorkOrderIdFromSA from '@salesforce/apex/connectionListViewDetailsContr.getWorkOrderIdFromSA';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import FORM_FACTOR from '@salesforce/client/formFactor';

/* ===== Offline (GraphQL Support) ===== */
import { gql, graphql } from 'lightning/uiGraphQLApi';
import USER_ID from '@salesforce/user/Id';
import { getRecord } from 'lightning/uiRecordApi';

const GET_CONNECTIONS = gql`
query getOMConnections($userId: ID!) {
  uiapi {
    query {
      AssignedResource(
        where: { ServiceResource: { RelatedRecordId: { eq: $userId } } }
        first: 2000
      ) {
        edges {
          node {
            ServiceAppointment {
              Id
              Status { value }
              Appointment_Type__c { value }
              ParentRecord {
                ... on WorkOrder {
                  Id
                  RecordType { DeveloperName { value } }
                  Connection__r {
                    Id
                    Name { value }
                    Building_Name__c { value }
                    Address_1__c { value }
                    Move_InDate__c { value }
                    Status__c { value }
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

export default class ConnectionListViewDetailsComp extends NavigationMixin(LightningElement) {
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
    @track connectionId;
    @api selectedType;
    @api secondPage;
    @api showAppointmentScreen;
    @track appointmentsList = [];
    appointmentsListMain = [];
    searchToggle = false;
    statusMap;
    @track appointmentSearchToggle = false;

    /* ====== Online/Offline support ====== */
    @track isOnline = navigator.onLine;
    @track refreshKey = 'init';

    connectedCallback() {
        window.addEventListener('online', this.handleOnline);
        window.addEventListener('offline', this.handleOffline);
        this.isOnline = navigator.onLine;
        this.getAppointmentByStatus(); // initial load (online)
    }

    disconnectedCallback() {
        window.removeEventListener('online', this.handleOnline);
        window.removeEventListener('offline', this.handleOffline);
        clearInterval(this.pollingInterval);
    }

    handleOnline = () => {
        this.isOnline = true;
        this.showToast('Back Online', 'Switching to live data.', 'success');
        this.getAppointmentByStatus();
    };

    handleOffline = () => {
        this.isOnline = false;
        this.showToast('Offline Mode', 'Showing cached data from device.', 'info');
        this.refreshKey = String(Date.now());
    };

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

    /* ========== ONLINE (Apex) ========== */
    getAppointmentByStatus() {
        this.isLoading = true;
        this.hasAppointments = false;
        this.appointmentsList = [];

        console.log('selected status::', this.selectedStatus);
        console.log('selected type ::', this.selectedType);

        if (!this.isOnline) {
            this.refreshKey = String(Date.now());
            return;
        }

        getAppointmentByStatus({ status: this.selectedStatus, type: this.selectedType })
            .then((result) => {
                console.log('Serviceappointment result::', JSON.stringify(result));
                this.appointmentResult = result;
                this.allAppointmentsList = [...this.appointmentResult];
            })
            .catch((error) => {
                console.log('Error ::', error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /* ========== OFFLINE (GraphQL wire) ========== */
    get gqlVars() {
        return { userId: USER_ID, refreshKey: this.refreshKey };
    }

    @wire(graphql, { query: GET_CONNECTIONS, variables: '$gqlVars' })
    wiredConnections({ data, errors }) {
        if (this.isOnline) return;
        if (errors) {
            console.error('GraphQL error:', JSON.stringify(error));
            this.isLoading = false;
            return;
        }
        if (!data) return;

        const edges = data?.uiapi?.query?.AssignedResource?.edges || [];
        const serviceAppointments = [];
        edges.forEach(({ node }) => {
            if (node?.ServiceAppointment) serviceAppointments.push(node.ServiceAppointment);
        });

        const byConnectionId = new Map();
        serviceAppointments.forEach((sa) => {
            const work = sa?.ParentRecord;
            const rt = work?.RecordType?.DeveloperName?.value;
            const conn = work?.Connection__r;
            if (rt === 'MGL_O_M' && conn?.Id) {
                const id = conn.Id;
                const existing = byConnectionId.get(id) || {
                    Id: conn.Id,
                    Name: conn.Name?.value || conn.Id,
                    Building_Name__c: conn.Building_Name__c?.value,
                    Address_1__c: conn.Address_1__c?.value,
                    Move_InDate__c: conn.Move_InDate__c?.value,
                    Status__c: conn.Status__c?.value,
                    _saStatuses: new Set(),
                    _apptTypes: new Set()
                };

                existing._saStatuses.add(sa.Status?.value || sa.Status);
                existing._apptTypes.add(sa.Appointment_Type__c?.value || sa.Appointment_Type__c);

                byConnectionId.set(id, existing);
            }

        });

        const normalize = (v) => (v ? String(v).trim().toLowerCase() : '');
        const completed = new Set(['completed']);
        const incomplete = new Set(['cannot complete', 'in progress']);
        const unattempted = new Set(['none', 'scheduled', 'dispatched']);
        const total = new Set(['canceled', 'completed', 'cannot complete', 'in progress', 'dispatched', 'scheduled', 'none']);

        const statusFilter = normalize(this.selectedStatus);
        const shouldKeep = (s) => {
            const val = normalize(s);
            switch (statusFilter) {
                case 'completed': return completed.has(val);
                case 'incomplete': return incomplete.has(val);
                case 'unattempted': return unattempted.has(val);
                case 'total': return total.has(val);
                default: return total.has(val);
            }
        };

        let rows = Array.from(byConnectionId.values()).filter((r) => {
            const statuses = Array.from(r._saStatuses || []);
            return statuses.some(s => shouldKeep(s));
        });


        const typeNorm = normalize(this.selectedType || '');
        if (typeNorm) {
            rows = rows.filter((r) => normalize(r._apptType || 'scheduled') === typeNorm);
        }

        this.appointmentResult = rows.map((r) => ({
            Id: r.Id,
            Name: r.Name,
            Building_Name__c: r.Building_Name__c,
            Address_1__c: r.Address_1__c,
            Move_InDate__c: r.Move_InDate__c,
            Status__c: r.Status__c
        }));

        this.allAppointmentsList = [...this.appointmentResult];
        this.isLoading = false;
        console.log('Offline Result:', JSON.stringify(this.appointmentResult));
    }

      @wire(getRecord, { recordId: '$connectionId', fields: ['Connection__c.Id'] })
        wiredConnection({ error, data }) {
          if (data) {
            //this.showToast('Briefcase Cache', `Connection ${data.id} is actually in offline DB.`, 'success');
          } else if (error) {
            //this.showToast('Briefcase Cache', `Connection ${this.connectionId} NOT in offline DB.`, 'warning');
          }
        }

    /* ========== SEARCH ========== */
    handleAppointmentSearch() {
        this.appointmentSearchToggle = !this.appointmentSearchToggle;
    }

    filterAppointmentSearch(event) {
        console.log('inside fillter appointment search');
        var value = event.detail.value;
        console.log('search value ::', value);
        if (value && value != '') {
            const searchValue = value.toLowerCase();
            this.appointmentResult = this.allAppointmentsList.filter((group) => {
                return (
                    (group.Name && group.Name.toLowerCase().includes(searchValue)) ||
                    (group.Status__c && group.Status__c.toLowerCase().includes(searchValue)) ||
                    (group.Building_Name__c && group.Building_Name__c.toLowerCase().includes(searchValue))
                );
            });
            console.log('appointmentsList after fillter', JSON.stringify(this.appointmentResult));
        } else {
            this.appointmentResult = [...this.allAppointmentsList];
        }
    }

    /* ========== NAVIGATION & UI EVENTS ========== */
    handleBacktoaddress() {
        console.log('Back clicked');
        this.showAppointmentScreen = false;
        this.flag = true;
        const event = new CustomEvent('childevent', {
            detail: { showDashboard: true, openMainPage: true }
        });
        this.dispatchEvent(event);
    }

//   handleAppointmentClick(event) {
//     this.connectionId = event.currentTarget.dataset.id;
//     const mode = this.isOnline ? 'ONLINE' : 'OFFLINE';
//     console.log(` Click detected | ConnectionId: ${this.connectionId} | Mode: ${mode}`);
//     this.showToast('DEBUG', `Clicked record: ${this.connectionId}\nMode: ${mode}`, 'info');

//     if (!this.connectionId) {
//         this.showToast('Error', ' No Connection Id found in dataset.', 'error');
//         console.error(' handleAppointmentClick: Missing ConnectionId');
//         return;
//     }

//     try {
//         this.showToast('DEBUG', 'Attempting NavigationMixin.Navigate...', 'info');
//         console.log(' Trying NavigationMixin.Navigate → type: standard__recordPage');


//             this[NavigationMixin.Navigate]({
//             type: 'standard__recordPage',
//             attributes: {
//                 recordId: this.connectionId,
//                 actionName: 'view'
//             }
//         });
        
        

//         this.showToast(
//             'DEBUG',
//             `NavigationMixin called successfully.\nOnline: ${this.isOnline}`,
//             'success'
//         );

//         if (!this.isOnline) {
//             this.showToast(
//                 'Offline Mode',
//                 'ℹ Opening cached Connection record (NavigationMixin called).',
//                 'info'
//             );
//         }
//     } catch (navErr) {
//         console.error(' NavigationMixin failed:', navErr);
//         this.showToast('DEBUG', `NavigationMixin failed: ${navErr.message}`, 'warning');

//         // ----------- Fallback deep-link attempt -----------
//         const deepLink = `com.salesforce.fieldservice://v1/sObject/${this.connectionId}/overview`;
//         console.log(' Attempting fallback deep link:', deepLink);
//         this.showToast('DEBUG', 'Trying deep link fallback...', 'info');

//         try {
//             window.open(deepLink);
//             this.showToast(
//                 'DEBUG',
//                 `Deep link opened:\n${deepLink}`,
//                 'success'
//             );
//         } catch (deepErr) {
//             console.error(' Deep link navigation failed:', deepErr);
//             this.showToast(
//                 'Offline Record',
//                 ' Record view not available offline.',
//                 'error'
//             );
//         }
//     }
// }

    handleAppointmentClick(event) {
    this.connectionId = event.currentTarget.dataset.id;
    const mode = this.isOnline ? 'ONLINE' : 'OFFLINE';
    console.log(`Click detected | ConnectionId: ${this.connectionId} | Mode: ${mode}`);
    //this.showToast('DEBUG', `Clicked record: ${this.connectionId}\nMode: ${mode}`, 'info');

    if (!this.connectionId) {
        //this.showToast('Error', 'No Connection Id found in dataset.', 'error');
        console.error('handleAppointmentClick: Missing ConnectionId');
        return;
    }

    if (this.isOnline) {
        const allCached = this.allAppointmentsList || [];
        const foundOffline = allCached.some(rec => rec.Id === this.connectionId);

        if (foundOffline) {
            // this.showToast(
            //     'Offline Briefcase Check',
            //     `Connection ${this.connectionId} found in local cache.`,
            //     'success'
            // );
        } else {
            // this.showToast(
            //     'Offline Briefcase Check',
            //     `Connection ${this.connectionId} NOT found in local cache!\nRecord may not open offline.`,
            //     'warning'
            // );
        }
        console.log('Briefcase check:', foundOffline ? 'FOUND ' : 'NOT FOUND ');
    }

        try {
            // this.showToast('DEBUG', 'Attempting NavigationMixin.Navigate...', 'info');
            console.log('Trying NavigationMixin.Navigate → type: standard__recordPage');

            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.connectionId,
                    actionName: 'view'
                }
            });

            // this.showToast(
            //     'DEBUG',
            //     `NavigationMixin called successfully.\nOnline: ${this.isOnline}`,
            //     'success'
            // );

            if (!this.isOnline) {
                // this.showToast(
                //     'Offline Mode',
                //     'Opening cached Connection record (NavigationMixin called).',
                //     'info'
                // );
            }
        } catch (navErr) {
            console.error('NavigationMixin failed:', navErr);
            //this.showToast('DEBUG', `NavigationMixin failed: ${navErr.message}`, 'warning');

            const deepLink = `com.salesforce.fieldservice://v1/sObject/${this.connectionId}/overview`;
            console.log(' Attempting fallback deep link:', deepLink);
            //this.showToast('DEBUG', 'Trying deep link fallback...', 'info');

            try {
                window.open(deepLink);
                //this.showToast('DEBUG', `Deep link opened:\n${deepLink}`, 'success');
            } catch (deepErr) {
                console.error('Deep link navigation failed:', deepErr);
                // this.showToast(
                //     'Offline Record',
                //     'Record view not available offline.',
                //     'error'
                // );
            }
        }

    }


    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant,
                mode: 'dismissable'
            })
        );
    }
}