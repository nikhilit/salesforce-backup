import { LightningElement, track, wire } from 'lwc';
import { gql, graphql } from 'lightning/uiGraphQLApi';
import userId from '@salesforce/user/Id';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import WORK_ORDER_OBJECT from '@salesforce/schema/WorkOrder';

const LIST_VIEW_API_NAME = 'O_MIncomplete_Work_Order';

const GET_INCOMPLETE_WORKORDERS = gql`
query getIncompleteWorkOrders($userId: ID!) {
  uiapi {
    query {
      WorkOrder(
        where: {
          Appointment_Status__c: { eq: "In Progress" },
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

export default class O_MIncompleteWorkOrderList extends NavigationMixin(LightningElement) {
    @track workOrders = [];
    @track isLoading = true;
    @track showOfflineListView = false;
    @track isNavigating = false;

    columns = [
        { label: 'Work Order Number', fieldName: 'workOrderNumber', type: 'text',initialWidth: 150 },
        { label: 'Connection Number', fieldName: 'connectionName', type: 'text', initialWidth: 180 },
        { label: 'Building Name', fieldName: 'buildingName', type: 'text', initialWidth: 200 },
        { label: 'Address', fieldName: 'address', type: 'text', wrapText: true,  initialWidth: 400 }
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

    @wire(graphql, { query: GET_INCOMPLETE_WORKORDERS, variables: '$graphQLVariables' })
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
 

        // Only trigger online navigation if online
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
    // This fires when user navigates away or Salesforce Mobile WebView "back" happens
    if (document.hidden || event.type === 'pagehide') {
        console.log('Detected mobile back or pagehide — redirecting to dashboard');
        this.handleBack();
    }
};
 
 
    handleBrowserBack = (event) => {
 
    console.log('Back pressed');
 
    // optionally prevent leaving
 
    history.pushState({ step: 'listView' }, '');
 
    this.handleBack(); // custom logic
 
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
        // In offline mode, navigate back in browser history
         // Fire event immediately for dashboard
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