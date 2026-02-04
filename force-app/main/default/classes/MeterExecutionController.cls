// public with sharing class MeterExecutionController {
//     @AuraEnabled(cacheable=true)
//     public static String getSubTypeForWorkOrder(Id workOrderId) {
//         WorkOrder wo = [
//             SELECT CaseId, Case.Sub_Type__c
//             FROM WorkOrder
//             WHERE Id = :workOrderId
//             LIMIT 1
//         ];

//         return wo.CaseId != null ? wo.Case.Sub_Type__c : null;
    
//     }
// }
public without sharing class MeterExecutionController {
    @AuraEnabled(cacheable=true)
    public static String getSubTypeForWorkOrder(Id workOrderId) {

        // Query without sharing so Case is accessible even if user cannot view Case
        WorkOrder wo = [
            SELECT CaseId, Case.Sub_Type__c
            FROM WorkOrder
            WHERE Id = :workOrderId
            LIMIT 1
        ];

        // Only return the subtype string, not the Case record
        if (wo.CaseId != null && wo.Case.Sub_Type__c != null) {
            return wo.Case.Sub_Type__c;
        }

        return null;
    }
}