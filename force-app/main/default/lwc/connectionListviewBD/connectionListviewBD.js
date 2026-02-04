import { LightningElement, track, wire } from 'lwc';
import { gql, graphql } from 'lightning/uiGraphQLApi';
import { NavigationMixin } from 'lightning/navigation';
import LightningAlert from 'lightning/alert';

/* ------------------- GRAPHQL QUERIES ------------------- */

const GET_LATEST_CONNECTIONS = gql`
query getLatestConnections {
  uiapi {
    query {
      Connection__c(
       first: 10, orderBy: { CreatedDate: { order: DESC } }
      ) {
        edges {
          node {
            Id
            Name { value }
            Building_Name__c { value }
            Address_1__c { value }
          }
        }
      }
    }
  }
}
`;

const SEARCH_CONNECTIONS = gql`
query searchConnections($searchKey: String!) {
  uiapi {
    query {
      Connection__c(
        where: { Name: { like: $searchKey } }
        first: 30
      ) {
        edges {
          node {
            Id
            Name { value }
            Building_Name__c { value }
            Address_1__c { value }
          }
        }
      }
    }
  }
}
`;

/* ------------------- COMPONENT ------------------- */

export default class ConnectionsListViewComp extends NavigationMixin(LightningElement) {

    @track searchKey = null;
    @track connectionlist = [];
    @track isSearching = false;
    @track noResults = false;

   @track selectedConnectionIds = [];

    @track showChild = false;

    /* ------------------- SEARCH HELPERS ------------------- */

    get isSearchMode() {
        return this.searchKey && this.searchKey.trim().length >= 3;
    }

    get searchVariables() {
        return { searchKey: `%${this.searchKey}%` };
    }

    /* ------------------- LOAD LATEST CONNECTIONS ------------------- */

    @wire(graphql, {
        query: GET_LATEST_CONNECTIONS,
        skip: '$isSearchMode'
    })
    wiredLatest({ data, errors }) {
        if (this.isSearchMode) {
            return;
        }

        console.log('🟢 GET_LATEST_CONNECTIONS fired');

        if (data) {
            this.connectionlist =
                data.uiapi.query.Connection__c.edges.map(e => e.node);

            console.log(
                '🟢 Loaded Connections:',
                this.connectionlist.map(c => c.Id)
            );

            this.noResults = false;
        } else if (errors) {
            console.error('🔴 Error in wiredLatest:', errors);
        }
    }

    /* ------------------- SEARCH CONNECTIONS ------------------- */

    @wire(graphql, {
        query: SEARCH_CONNECTIONS,
        variables: '$searchVariables',
        skip: '!$isSearchMode'
    })
    wiredSearch({ data, errors }) {
        if (!this.isSearchMode) {
            return;
        }

        console.log('🟡 SEARCH_CONNECTIONS fired for:', this.searchKey);
        this.isSearching = true;

        if (data) {
            this.connectionlist =
                data.uiapi.query.Connection__c.edges.map(e => e.node);

            console.log(
                '🟡 Search Results IDs:',
                this.connectionlist.map(c => c.Id)
            );

            this.noResults = this.connectionlist.length === 0;
        } else if (errors) {
            console.error('🔴 Error in wiredSearch:', errors);
            this.noResults = true;
        }

        this.isSearching = false;
    }

    /* ------------------- SEARCH INPUT ------------------- */

    handleSearchChange(event) {
        this.searchKey = event.target.value;
        this.showChild = false;
        this.selectedConnectionIds = [];
        //console.log('🔵 Search Key:', this.searchKey);
        console.log('🔵 Cleared selectedConnectionIds');
    }

    /* ------------------- NAVIGATION ------------------- */

    handleNavigate(event) {
        event.stopPropagation();
        const recordId = event.target.dataset.id;

        console.log('➡️ Navigating to Connection:', recordId);

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId,
                objectApiName: 'Connection__c',
                actionName: 'view'
            }
        });
    }

    /* ------------------- CHECKBOX SELECTION ------------------- */

    
 handleSelectConnection(event) {
    const connId = event.target.dataset.id;
    const isChecked = event.target.checked; // ✅ NOT event.detail.checked

    if (isChecked) {
        if (!this.selectedConnectionIds.includes(connId)) {
            this.selectedConnectionIds = [...this.selectedConnectionIds, connId];
        }
        console.log('✅ Selected:', connId);
    } else {
        this.selectedConnectionIds =
            this.selectedConnectionIds.filter(id => id !== connId);
        console.log('❌ Deselected:', connId);
    }

    console.log('📌 Current Selected IDs:', JSON.stringify(this.selectedConnectionIds));
}




    /* ------------------- BUTTON CLICK ------------------- */

   handleCreateDemolition() {
    console.log(
        '🚀 Create Button Clicked. Selected IDs:',
        this.selectedConnectionIds
    );

    if (this.selectedConnectionIds.length === 0) { // ✅ length, not size
        LightningAlert.open({
            message: 'Please select at least one Connection',
            theme: 'warning',
            label: 'No Selection'
        });
        return;
    }

    this.showChild = true;

    console.log(
        'Child Component will receive IDs:',
        this.selectedConnectionsArray
    );
}

    /* ------------------- CHILD INPUT ------------------- */

   get selectedConnectionsArray() {
    const ids = [...this.selectedConnectionIds]; // ✅ clone
    console.log('📤 Passing to Child (CLONED):', JSON.stringify(ids));
    return ids;
}

handleBackFromChild() {
    this.showChild = false;
}


}