trigger opportunityAmountTrigger on Opportunity (After insert) {
    OpportunityAmountHandler.populateAmount(Trigger.new);

}