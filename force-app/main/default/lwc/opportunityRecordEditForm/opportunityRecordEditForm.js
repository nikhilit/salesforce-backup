import { api, LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import NAME from '@salesforce/schema/Opportunity.Name';
import OWNER from '@salesforce/schema/Opportunity.OwnerId';
import ACCOUNT from '@salesforce/schema/Opportunity.AccountId';
import CLOSE_DATE from '@salesforce/schema/Opportunity.CloseDate';
import STAGE from '@salesforce/schema/Opportunity.StageName';
import TYPE from '@salesforce/schema/Opportunity.Type';
import LEAD_SOURCE from '@salesforce/schema/Opportunity.LeadSource';
import PROBABILITY from '@salesforce/schema/Opportunity.Probability';
import AMOUNT from '@salesforce/schema/Opportunity.Amount';
import EXPECTED_REVENUE from '@salesforce/schema/Opportunity.ExpectedRevenue';
import DISCOUNT from '@salesforce/schema/Opportunity.Discount_Percentage__c';
import ORDER_NUMBER from '@salesforce/schema/Opportunity.OrderNumber__c';
import IS_PRIVATE from '@salesforce/schema/Opportunity.IsPrivate';
import APPROVAL_STATUS from '@salesforce/schema/Opportunity.Approval_Status__c';
import LOST_REASON from '@salesforce/schema/Opportunity.Closed_Lost_Reason__c';
import DELIVERY_STATUS from '@salesforce/schema/Opportunity.DeliveryInstallationStatus__c';
import SHOW_CONFETTI from '@salesforce/schema/Opportunity.Show_Confetti__c';
import CAMPAIGN from '@salesforce/schema/Opportunity.CampaignId';
import TRACKING_NUMBER from '@salesforce/schema/Opportunity.TrackingNumber__c';
import COMPETITORS from '@salesforce/schema/Opportunity.MainCompetitors__c';
import GENERATORS from '@salesforce/schema/Opportunity.CurrentGenerators__c';
import DESCRIPTION from '@salesforce/schema/Opportunity.Description';
import EMAIL from '@salesforce/schema/Opportunity.Email__c';
import DEMO from '@salesforce/schema/Opportunity.demo__c';
import CREATED_BY from '@salesforce/schema/Opportunity.CreatedById';
import LAST_MODIFIED_BY from '@salesforce/schema/Opportunity.LastModifiedById';
import NEXT_STEP from '@salesforce/schema/Opportunity.NextStep';


export default class OpportunityRecordEditForm extends NavigationMixin(LightningElement) {
   


    // Array of field references
    fields = [
        NAME,
        OWNER,
        ACCOUNT,
        CLOSE_DATE,
        STAGE,
        TYPE,
        LEAD_SOURCE,
        PROBABILITY,
        AMOUNT,
        EXPECTED_REVENUE,
        DISCOUNT,
        ORDER_NUMBER,
        IS_PRIVATE,
        APPROVAL_STATUS,
        LOST_REASON,
        DELIVERY_STATUS,
        SHOW_CONFETTI,
        CAMPAIGN,
        TRACKING_NUMBER,
        COMPETITORS,
        GENERATORS,
        DESCRIPTION,
        EMAIL,
        DEMO,
        CREATED_BY,
        LAST_MODIFIED_BY,
        NEXT_STEP
    ];


    // Handles the Cancel button
    handleCancel() {
        // Redirect to Opportunity list view
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Opportunity',
                actionName: 'list',
            },
        });
    }


    // Handles form success
    handleSuccess(event) {
        const evt = new ShowToastEvent({
            title: 'Success',
            message: `Opportunity created successfully! Record ID: ${event.detail.id}`,
            variant: 'success',
        });
        this.dispatchEvent(evt);


        // Redirect to the newly created Opportunity record
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.detail.id,
                objectApiName: 'Opportunity',
                actionName: 'view',
            },
        });
    }


    // Handles form submission errors
    handleError(event) {
        const evt = new ShowToastEvent({
            title: 'Error',
            message: `Error creating Opportunity: ${event.detail.message}`,
            variant: 'error',
        });
        this.dispatchEvent(evt);
    }
}