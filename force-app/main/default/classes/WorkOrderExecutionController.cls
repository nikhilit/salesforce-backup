public with sharing class WorkOrderExecutionController {
    @AuraEnabled(cacheable=true)
    public static String getWorkOrderType(Id workOrderId) {
        return [
            SELECT Work_Order_Type__c 
            FROM WorkOrder 
            WHERE Id = :workOrderId 
            LIMIT 1
        ].Work_Order_Type__c;
    }
}