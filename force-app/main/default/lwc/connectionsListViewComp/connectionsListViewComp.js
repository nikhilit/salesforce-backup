import { LightningElement, track,wire } from 'lwc';
import { gql, graphql } from 'lightning/uiGraphQLApi';
import { NavigationMixin } from 'lightning/navigation';
import LightningAlert from 'lightning/alert';
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
            Maintenance_year__c { value }
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
            Maintenance_year__c { value }
          }
        }
      }
    }
  }
}
`;



export default class ConnectionsListViewComp extends NavigationMixin(LightningElement) {
    @track searchKey = null;
    @track connectionlist = [];
    @track isSearching = false;
    @track noResults = false;
    @track isLoading = true;
    get variables() {
    return { searchKey: this.searchKey };
    }

    get isSearchMode() {
    return this.searchKey && this.searchKey.trim().length >= 3;
    }

    get searchVariables() {
        return { searchKey: `%${this.searchKey}%` };
    }

    @wire(graphql, {
    query: GET_LATEST_CONNECTIONS,
    skip: '$isSearchMode'
    })
    wiredLatest({ data, errors }) {
         if (this.isSearchMode) {
        return;
    }
           this.isLoading = true;
        console.log('GET_LATEST_CONNECTIONS::::');
        if (data) {
            this.connectionlist = data.uiapi.query.Connection__c.edges.map(e => e.node);
            this.noResults = false;
        } else if (errors) {
            console.error('Error in wiredLatest:::',errors);
         
        }
              this.isLoading = false;
    }


    @wire(graphql, {
    query: SEARCH_CONNECTIONS,
    variables: '$searchVariables',
    skip: '!$isSearchMode'
    })
    wiredSearch({ data, errors }) {
        if (!this.isSearchMode) {
        return; // 🚫 ignore early lifecycle calls
    }

           this.isLoading = true;    
        console.log('SEARCH_CONNECTIONS');
        this.isSearching = true;
        if (data) {
            this.connectionlist = data.uiapi.query.Connection__c.edges.map(e => e.node);
            this.noResults = this.connectionlist.length === 0;
        } else if (errors) {
            console.error('Error in wiredsearch::connections::',errors);


            this.noResults = true;
        }
        this.isSearching = false;
        this.isLoading = false;
    }


    handleSearchChange(event) {
        this.searchKey = event.target.value;
        console.log('this.searchKey :::',this.searchKey );
    }

    // Navigate to record detail
    handleRowClick(event) {
        const recordId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: 'Connection__c',
                actionName: 'view'
            }
        });
    }
}