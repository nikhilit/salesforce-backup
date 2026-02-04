import { LightningElement, api, wire,track } from 'lwc';
//import getWorkOrderLineItems from '@salesforce/apex/WorkOrderLineItemController.getWorkOrderLineItems';
import { NavigationMixin } from 'lightning/navigation';

//lds offline

import { getRelatedListRecords } from 'lightning/uiRelatedListApi';

import { gql, graphql } from 'lightning/uiGraphQLApi';



 const GET_WORKORDER_LINE_ITEMS = gql`
    query getWorkOrderLineItems($workOrderId: ID!, $first: Int) {
      uiapi {
        query {
          WorkOrderLineItem(
            where: { WorkOrderId: { eq: $workOrderId } }
            orderBy: { Riser_Name__c: { order: ASC } }

            first: $first
          ) {
            edges {
              node {
                Id
                Riser_Name__c { value }
                CreatedDate { value }
              }
            }
          }
        }
      }
    }
    `;


export default class WorkOrderLineItemOfflineComponent extends NavigationMixin(LightningElement) {
    @api recordId; // Work Order Id

    @track showCOWorkOrderLineItemPage = true;
    @api workOrderLineItemName='';
    @api workOrderLineItemId;
    
    
    @track  workOrderLineItems = [];

    @track showEnterRiserDetails=false;
   // openModal=false;
    error;

    // connectedCallback() {
        
    //     console.log('record id riser maintenance offline::', this.recordId);
    // }

    // @wire(getWorkOrderLineItems, { workOrderId: '$recordId' })
    // wiredItems({ data, error }) {
    //     if (data) {
    //         this.workOrderLineItems = data;
    //         this.error = undefined;
    //     } else if (error) {
    //         this.error = error;
    //         this.workOrderLineItems = [];
    //     }
    // }



    //  @wire(getRelatedListRecords, {
    //     parentRecordId: '$recordId',
    //     relatedListId: 'WorkOrderLineItems', // child relationship name
    //     fields: ['WorkOrderLineItem.Id', 'WorkOrderLineItem.Riser_Name__c'],
    //     sortBy: ['CreatedDate']
    // })
    // wiredRelatedItems({ data, error }) {
    //     if (data) {
    //         let index = 1;
    //         this.workOrderLineItems = data.records.map(r => ({
    //             index: index++,
    //             recordId: r.fields.Id.value,
    //             name: r.fields.Riser_Name__c.value
    //         }));
    //         this.error = undefined;
    //         console.log(' WorkOrderLineItems loaded:', JSON.stringify(this.workOrderLineItems));
    //     } else if (error) {
    //         this.error = error;
    //         this.workOrderLineItems = [];
    //         console.error('Error fetching WorkOrderLineItems:', error);
    //     }
    // }

     get graphqlVars() {
        return {
            workOrderId: this.recordId,
            first: 2000
        };
    }

    @wire(graphql, { query: GET_WORKORDER_LINE_ITEMS, variables: '$graphqlVars' })
    wiredWorkOrderLineItems({ errors, data }) {
        // if (this.isOnline) {
        //     return;
        // }

        if (errors) {
            this.error = errors;
            this.workOrderLineItems = [];
            console.error('GraphQL error fetching WorkOrderLineItems:', error);
            return;
        }

        if (data) {
            try {
                const edges = data?.uiapi?.query?.WorkOrderLineItem?.edges || [];
                let idx = 1;
                this.workOrderLineItems = edges.map(e => {
                    const node = e.node || {};
                    return {
                        index: idx++,
                        recordId: node.Id,
                        name: node.Riser_Name__c?.value || '—'
                    };
                });
                this.error = undefined;
                console.log('GraphQL WorkOrderLineItems loaded:', JSON.stringify(this.workOrderLineItems));
            } catch (err) {
                this.error = err;
                this.workOrderLineItems = [];
                console.error('Parsing error for WorkOrderLineItems GraphQL response', err);
            }
        } else {
            this.workOrderLineItems = [];
        }
    }
    handleOpenModal(event){

     this.workOrderLineItemId = event.currentTarget.dataset.id; // Capture clicked Id
     console.log('workOrderLineItemName::',event.currentTarget.dataset.name);
    this.workOrderLineItemName=event.currentTarget.dataset.name;
        this.showEnterRiserDetails=true;
        this.showCOWorkOrderLineItemPage=false;
     // this.openModal=true;
    }
    handleCancel(){
      this.showEnterRiserDetails=false;
      this.showCOWorkOrderLineItemPage=true;
    }
    handleNavigate(event) {
        const recordId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: 'WorkOrderLineItem',
                actionName: 'view'
            }
        });
    }
}