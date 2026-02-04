import { LightningElement, track, wire } from 'lwc';
import { gql, graphql } from 'lightning/uiGraphQLApi';
import userId from '@salesforce/user/Id';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import WORK_ORDER_OBJECT from '@salesforce/schema/WorkOrder';

const LIST_VIEW_API_NAME = 'O_MUnattempted_Work_Order';

const GET_UNATTEMPTED_WORKORDERS = gql`
query getUnattemptedWorkOrders($userId: ID!) {
  uiapi {
    query {
      WorkOrder(
        where: {
          Appointment_Status__c: { eq: "Unattempted" },
          OwnerId: { eq: $userId }
        },
        orderBy: { CreatedDate: { order: DESC } },
        first: 500
      ) {
        edges {
          node {
            Id
            WorkOrderNumber { value }
            Connection_Number__c { value }
            Building_Name__c { value }
            Address_1_ConnectionAddress__c { value }
          }
        }
      }
    }
  }
}
`;

export default class O_MRiserUnattemptedWorkOrder extends NavigationMixin(LightningElement) {
    @track workOrders = [];
    @track isLoading = true;
    @track showOfflineListView = false;
    @track isNavigating = false;

    columns = [
        { label: 'Work Order Number', fieldName: 'workOrderNumber', type: 'text', initialWidth: 150 },
        { label: 'Connection Number', fieldName: 'connectionName', type: 'text', initialWidth: 180 },
        { label: 'Building Name', fieldName: 'buildingName', type: 'text', initialWidth: 200 },
        { label: 'Address', fieldName: 'address', type: 'text', wrapText: true, initialWidth: 400 }
    ];

    get isOnline() {
        return navigator.onLine;
    }

    get hasData() {
        return this.workOrders && this.workOrders.length > 0;
    }

    get graphQLVariables() {
        return { userId };
    }

    @wire(graphql, { query: GET_UNATTEMPTED_WORKORDERS, variables: '$graphQLVariables' })
    wiredWorkOrders({ error, data }) {
        if (data) {
            const edges = data?.uiapi?.query?.WorkOrder?.edges || [];
            this.workOrders = edges.map(edge => ({
                id: edge.node.Id,
                workOrderNumber: edge.node.WorkOrderNumber?.value || '',
                connectionName: edge.node.Connection_Number__c?.value || '',
                buildingName: edge.node.Building_Name__c?.value || '',
                address: edge.node.Address_1_ConnectionAddress__c?.value || ''
            }));
            this.isLoading = false;
            console.log(`✅ Loaded ${this.workOrders.length} Unattempted Work Orders`);
        } else if (error) {
            this.isLoading = false;
            this.showToast('Error', 'Failed to load cached work orders', 'error');
        }
    }

    connectedCallback() {
        this.checkConnectivity();

        window.addEventListener('online', this.handleOnlineStatusChange.bind(this));
        window.addEventListener('offline', this.handleOnlineStatusChange.bind(this));
        window.history.pushState({ step: 'listView' }, '');
        window.addEventListener('popstate', this.handleBrowserBack);
        document.addEventListener('visibilitychange', this.handleMobileBack);
        window.addEventListener('pagehide', this.handleMobileBack);

        if (this.isOnline) {
            this.navigateToListView();
        }
    }

    disconnectedCallback() {
        window.removeEventListener('online', this.handleOnlineStatusChange.bind(this));
        window.removeEventListener('offline', this.handleOnlineStatusChange.bind(this));
        window.removeEventListener('popstate', this.handleBrowserBack);
        document.removeEventListener('visibilitychange', this.handleMobileBack);
        window.removeEventListener('pagehide', this.handleMobileBack);
    }

    checkConnectivity() {
        this.showOfflineListView = !this.isOnline;
        if (!this.showOfflineListView) {
            this.isLoading = false;
        }
    }

    handleMobileBack = (event) => {
        if (document.hidden || event.type === 'pagehide') {
            this.handleBack();
        }
    };

    handleBrowserBack = () => {
        history.pushState({ step: 'listView' }, '');
        this.handleBack();
    };

    handleOnlineStatusChange = () => {
        if (this.isOnline) {
            this.showOfflineListView = false;
            this.navigateToListView();
        } else {
            this.showOfflineListView = true;
            this.isLoading = false;
        }
    }

    navigateToListView() {
        try {
            this.isNavigating = true;
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: WORK_ORDER_OBJECT.objectApiName,
                    actionName: 'list'
                },
                state: { filterName: LIST_VIEW_API_NAME }
            });
        } catch (error) {
            this.showToast('Error', 'Unable to open list view.', 'error');
            this.isNavigating = false;
        }
    }

    handleBack() {
        this.dispatchEvent(new CustomEvent('back'));
    }

    refreshData() {
        if (this.isOnline) {
            this.navigateToListView();
        } else {
            this.showToast('Offline', 'Cannot refresh while offline', 'warning');
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}