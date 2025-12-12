public with sharing class OpportunityHelper {

    @AuraEnabled(cacheable=true)
    public static List<Opportunity> getOpportunityData() {
        return[
            select id , Name , AccountId , StageName , Amount , CloseDate 
            from Opportunity limit 10];
}
}