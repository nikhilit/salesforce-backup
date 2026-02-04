import { LightningElement, track, wire } from 'lwc';
import { gql, graphql, refreshGraphQL } from 'lightning/uiGraphQLApi';

import { NavigationMixin } from 'lightning/navigation';
import USER_ID from '@salesforce/user/Id';

const GET_LATEST_WORKORDER = gql`
query getLatestWorkOrders($ownerId: ID!) {
  uiapi {
    query {
      WorkOrder(
        first: 10
        orderBy: { CreatedDate: { order: DESC } }
        where: {
          OwnerId: { eq: $ownerId }
          Type__c: { eq: "TBT Document" }
        }
      ) {
        edges {
          node {
            Id
            WorkOrderNumber { value }
            Agent__r {
              Name { value }
            }
            Approval_Status__c { value }
          }
        }
      }
    }
  }
}
`;


export default class WorkOrderListViewomp extends NavigationMixin(LightningElement) {

  workorderlist = [];
    noResults = false;
    isLoading = true;
    wiredResult;


    userId = USER_ID;

    @wire(graphql, {
    query: GET_LATEST_WORKORDER,
    variables: { ownerId: USER_ID }
    })
    wiredLatest(result) {
        this.wiredResult = result;
        const { data, errors } = result;

        this.isLoading = true;

        if (data) {
            this.workorderlist =
                data.uiapi.query.WorkOrder.edges.map(e => e.node);
            this.noResults = this.workorderlist.length === 0;
        } else if (errors) {
            console.error('GraphQL error:', errors);
            this.noResults = true;
        }

        this.isLoading = false;
    }

    handleRefresh() {
      console.log('handlerefresh::');
    if (this.wiredResult) {
        console.log('wiredresult::handlerefresh::');
        this.isLoading = true;
        refreshGraphQL(this.wiredResult);
    }
}



    // @wire(graphql, {
    //     query: GET_LATEST_WORKORDER,
    //     variables: { ownerId: USER_ID }
    // })
    // wiredLatest({ data, errors }) {
    //     this.isLoading = true;

    //     if (data) {
    //         this.workorderlist =
    //             data.uiapi.query.WorkOrder.edges.map(e => e.node);
    //         this.noResults = this.workorderlist.length === 0;
    //     } else if (errors) {
    //         console.error('GraphQL error:', errors);
    //         this.noResults = true;
    //     }

    //     this.isLoading = false;
    // }

    handleRowClick(event) {
        const recordId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId,
                objectApiName: 'WorkOrder',
                actionName: 'view'
            }
        });
    }
}