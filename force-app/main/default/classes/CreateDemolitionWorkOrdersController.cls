public without sharing class CreateDemolitionWorkOrdersController {

    // ====================================================================
    // METHOD 1: Return Accounts for selection (NO WO creation here)
    // ====================================================================
    @AuraEnabled(cacheable=true)
    public static List<Account> getFilteredAccounts(List<Id> caseIds) {

        if (caseIds == null || caseIds.isEmpty()) {
            return new List<Account>();
        }

        // Get Case → Account
        List<Case> cases = [
            SELECT Id, AccountId
            FROM Case
            WHERE Id IN :caseIds
        ];

        Set<Id> accountIds = new Set<Id>();
        for (Case c : cases) {
            if (c.AccountId != null) {
                accountIds.add(c.AccountId);
            }
        }

        if (accountIds.isEmpty()) {
            return new List<Account>();
        }

        // Get Connection__c from Accounts
        List<Account> baseAccounts = [
            SELECT Id, Connection__c
            FROM Account
            WHERE Id IN :accountIds
        ];

        Set<Id> connectionIds = new Set<Id>();
        for (Account a : baseAccounts) {
            if (a.Connection__c != null) {
                connectionIds.add(a.Connection__c);
            }
        }

        if (connectionIds.isEmpty()) {
            return new List<Account>();
        }

        // Return ALL related Accounts of those connections
        // where Active = Yes AND Move_Out_Date__c NULL or sentinel
        Date sentinelDate = Date.newInstance(9999, 12, 31);

        List<Account> relatedAccounts = [
            SELECT Id, Name, Connection__c,
                   Connection_Object__c,
                   BP_Number__c,
                   Full_Name__c,
                   sharinpix__Active__c,
                   Move_Out_Date__c
            FROM Account
            WHERE Connection__c IN :connectionIds
            AND sharinpix__Active__c = 'Yes'
        ];

        // Final filtering in Apex
        List<Account> finalList = new List<Account>();

        for (Account a : relatedAccounts) {
            Boolean moveOutOK = (a.Move_Out_Date__c == null ||
                                 a.Move_Out_Date__c == sentinelDate);

            if (moveOutOK) {
                finalList.add(a);
            }
        }

        return finalList;
    }


    // ====================================================================
    // METHOD 2: Create WorkOrders for selected Accounts
    // ====================================================================
    @AuraEnabled
   // public static String createSelectedWOs(Id caseId, List<Id> selectedAccountIds)
   public static String createSelectedWOs(List<Id> caseIds,  List<AccountDateWrapper> accountDateWrappers)  {

        // if (caseId == null || selectedAccountIds == null || selectedAccountIds.isEmpty()) {
        //     return 'Error: Missing Case Id or Accounts.';
        // }
        if (caseIds == null || caseIds.isEmpty() || accountDateWrappers == null || accountDateWrappers.isEmpty()) {
    return 'Error: Missing Case Ids or Accounts.';
}


        // Security — Only Demolition users allowed
        User u = [
            SELECT Id, Profile.Name
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ];

        if (u.Profile.Name != 'AIC Building Demolition') {
            return 'Error: You are not authorized to create demolition Work Orders.';
        }

        // Get WorkType for Demolition
        WorkType wt = [
            SELECT Id, Name
            FROM WorkType
            WHERE Name = 'Building Demolition'
            LIMIT 1
        ];

        // Record type for Demolition WO
        Id rtId = Schema.SObjectType.WorkOrder
                        .getRecordTypeInfosByName()
                        .get('MGL O&M')
                        .getRecordTypeId();

        List<WorkOrder> woList = new List<WorkOrder>();

        // for (Id accId : selectedAccountIds) {
        //     WorkOrder wo = new WorkOrder();
        //     wo.AccountId = accId;
        //     wo.CaseId = caseId;
        //     wo.WorkTypeId = wt.Id;
        //     wo.RecordTypeId = rtId;
        //     wo.Department__c = 'O&M';
        //     //wo.Work_Order_Type__c = 'Building Demolition';

        //     woList.add(wo);
        // }

        for (Id caseId : caseIds) {
     for (AccountDateWrapper w : accountDateWrappers) {
        WorkOrder wo = new WorkOrder();
        wo.AccountId = w.accountId;
        wo.CaseId = caseId;
        wo.WorkTypeId = wt.Id;
        wo.RecordTypeId = rtId;
        wo.Department__c = 'O&M';
        wo.StartDate = w.startDate;
        wo.EndDate = w.endDate;
        woList.add(wo);
    }
}


        insert woList;

        return 'Success';
    }


    public class AccountDateWrapper {
    @AuraEnabled public Id accountId { get; set; }
    @AuraEnabled public Datetime startDate { get; set; }
    @AuraEnabled public Datetime endDate { get; set; }
}

}