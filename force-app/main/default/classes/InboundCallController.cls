public with sharing class InboundCallController {

    /**
     * This method returns the Account Id based on the provided phone number
     * and verifies if the current user’s Agent_Id__c matches the provided agentId.
     * 
     * @param phone   The phone number to search in Account records.
     * @param agentId The agent ID to match with the current user's Agent_Id__c.
     * @return Account Id if a match is found and agent is verified, otherwise null.
     */
     @AuraEnabled(cacheable=false)
    public static Inbound_Call__c getLatestInboundCall(String agentId) {
        list<Inbound_Call__c> InboundCallDetails =[SELECT Id, PhoneNumber__c, Agent_Id__c, Status__c
            FROM Inbound_Call__c
            WHERE Agent_Id__c = :agentId
            AND Status__c = 'New'
            ORDER BY CreatedDate DESC
            LIMIT 1];
        if(InboundCallDetails.size()>0){
            return InboundCallDetails[0];
        }
        else{
            return null;
        }
    }

    @AuraEnabled
    public static void markCallAsShown(Id callId) {
        Inbound_Call__c ic = new Inbound_Call__c(
            Id = callId,
            Status__c = 'Shown'
        );
        update ic;
    }
    @AuraEnabled(cacheable=true)
public static String getCurrentUserAgentId() {
    return [SELECT Id,Agent_Id__c FROM User WHERE Id = :UserInfo.getUserId()].Agent_Id__c;
}
    @AuraEnabled
    public static List<Account> getAccountIdByPhone(String phone, String agentId) {
        // Fetch the current user's Agent_Id__c
        User currentUser = [
            SELECT Agent_Id__c
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];
        
        // If the agentId does not match, return null
        if (currentUser.Agent_Id__c != agentId) {
           // return null;
           return new List<Account>();
        }
        
        // Query the Account based on the phone number
        List<Account> accounts = [
            SELECT Id
            FROM Account
            WHERE Phone = :phone
        ];
        
        // If an account is found, return the Id
        if (!accounts.isEmpty()) {
            return accounts;
        }
        
        // No account found, return null
        //return null;
        return new List<Account>();
    }
}