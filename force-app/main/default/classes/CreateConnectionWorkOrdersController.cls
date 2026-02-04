public without sharing class CreateConnectionWorkOrdersController {

    // ------------------------------------------------------------------
    // STEP 1: Get Accounts from selected Connections
    // ------------------------------------------------------------------
    @AuraEnabled(cacheable=true)
    public static List<Account> getAccountsFromConnections(List<Id> connectionIds) {

        if (connectionIds == null || connectionIds.isEmpty()) {
            return new List<Account>();
        }

        // Accounts under selected Connections via Relationship: Business_Partners__r
        List<Account> allAccounts = [
            SELECT Id, Name, Connection__c, Connection_Object__c,
                   BP_Number__c, Full_Name__c,
                   sharinpix__Active__c, Move_Out_Date__c
            FROM Account
            WHERE Connection__c IN :connectionIds
            AND sharinpix__Active__c = 'Yes'
        ];

        // Same filtering logic as Demolition
        Date sentinelDate = Date.newInstance(9999, 12, 31);

        List<Account> finalList = new List<Account>();

        for (Account a : allAccounts) {
            Boolean moveOutValid = (a.Move_Out_Date__c == null ||
                                    a.Move_Out_Date__c == sentinelDate);

            if (moveOutValid) {
                finalList.add(a);
            }
        }

        return finalList;
    }


    // ------------------------------------------------------------------
    // STEP 2: Create WorkOrders for selected Accounts
    // ------------------------------------------------------------------

    @AuraEnabled
    public static String createWorkOrders(List<Id> connectionIds, List<AccountDateWrapper> accountDateWrappers) {

        System.debug('🔴 connectionIds => ' + connectionIds);
    System.debug('🔴 accountDateWrappers SIZE => ' +
        (accountDateWrappers.size())
    );


        if (connectionIds == null || connectionIds.isEmpty() ||
            accountDateWrappers == null || accountDateWrappers.isEmpty()) {
            return 'Error: Missing Connection Ids or Accounts.';
        }

        System.debug('accountDateWrappers::::'+accountDateWrappers);
        // Only demolition team allowed (same rule as previous flow)
        User u = [
            SELECT Id, Profile.Name
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ];

       // if (u.Profile.Name != 'AIC Building Demolition')
        
          if (u.Profile.Name != 'AIC Building Demolition'){
            return 'Error: You are not authorized to create demolition Work Orders.';
        }

        // Get WorkType
        WorkType wt = [
            SELECT Id FROM WorkType
            WHERE Name = 'Building Demolition'
            LIMIT 1
        ];

        Id rtId = Schema.SObjectType.WorkOrder
                        .getRecordTypeInfosByName()
                        .get('MGL O&M')
                        .getRecordTypeId();

        List<WorkOrder> woList = new List<WorkOrder>();

        // Create WO: 1 Connection × N Accounts
        for (Id conId : connectionIds) {
           // for (Id accId : selectedAccountIds) 
           for (AccountDateWrapper w : accountDateWrappers)
            
            {
                System.debug('🟢 Wrapper.accountId => ' + w.accountId);
    System.debug('🟢 Wrapper.startDate => ' + w.startDate);
    System.debug('🟢 Wrapper.endDate => ' + w.endDate);

                WorkOrder wo = new WorkOrder();
                wo.AccountId = w.accountId;
                wo.Connection__c = conId;
                wo.RecordTypeId = rtId;
                wo.WorkTypeId = wt.Id;
                wo.Department__c = 'O&M';

                wo.StartDate = w.startDate;
                wo.EndDate = w.endDate;
                if (w.caseId != null) {
    wo.CaseId = w.caseId;
}


                woList.add(wo);
            }
        }

        
        insert woList;    
        return 'Success';
    }


public  class AccountDateWrapper {
     @AuraEnabled public Id accountId { get; set; }
    @AuraEnabled public Datetime startDate { get; set; }
    @AuraEnabled public Datetime endDate { get; set; }
     @AuraEnabled public Id caseId { get; set; }
}







}