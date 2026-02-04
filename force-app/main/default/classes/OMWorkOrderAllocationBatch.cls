public with sharing class OMWorkOrderAllocationBatch implements Database.Batchable<SObject>, Database.Stateful {

    public String query =
'SELECT Id, Name, Building_Name__c, Marketing_BP_Status__c, Address1__c, Address2__c, ' +
'Move_In_Date__c, Move_Out_Date__c, Amount_Received__c, Created_Order__c, ' +
'Created_Work_Order__c, Account__c, Account__r.Id, Account__r.Connection_formula__c, ' + 
'Activity_Type__c, Start_Date__c ' +  
'FROM O_M_Appointment_Request__c ' +
'WHERE Created_Order__c = FALSE ' +
'AND Account__c != NULL ' +
'AND Account__r.Connection_formula__c != NULL';



    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('Starting OMWorkOrderAllocationBatch...');
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<O_M_Appointment_Request__c> scope) {
        System.debug('Processing ' + scope.size() + ' appointment requests...');
        OMWorkOrderAllocationHelper.createWorkOrders(scope);
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('O&M Work Order batch finished.');
    }
}