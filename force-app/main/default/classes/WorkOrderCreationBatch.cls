global with sharing class WorkOrderCreationBatch implements Database.Batchable<SObject>, Database.Stateful {

    private Map<String, Id> mapKeyAgentId = new Map<String, Id>();
    private Map<Id, Integer> mapAgencyUtilizedCapacity = new Map<Id, Integer>();

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, BP_Numbers__c, Created_WorkOrder__c, Work_orders_Type__c, Due_Amount__c, Due_Date__c, Bill_Date__c,Agency__c,Invoice_No__c,Net_Payment_upto_Due_Date__c,
                   B4DUE__c, NOTDUE__c, X91_180__c, X61_90__c, X2_3YR__c, X181_365__c, X1_2YR__c, X0_30__c, X31_60__c, Colony__c,RT_Customer_work_Type__c,Assigned_Agency__c,Total__c
            FROM WorkOrderAllocation__c
            WHERE Created_WorkOrder__c = FALSE
        ]);
    }

    global void execute(Database.BatchableContext bc, List<WorkOrderAllocation__c> scope) {
        if (scope == null || scope.isEmpty()) return;

        CreateAndAssignWorkorders.assignWorkOrders(
            scope,
            mapKeyAgentId,
            mapAgencyUtilizedCapacity
        );
    }

    global void finish(Database.BatchableContext bc) {
      //System.debug('workorders created');
    }
}