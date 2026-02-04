/**
* @File Name : O_MAutoHomePageComponentController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : August 10, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | August 10, 2025 |   | Initial Version
**/

public without sharing class O_MAutoHomePageComponentController {
	
    
    @AuraEnabled(cacheable=true)
    public static UserWrapper getUserName() {
        User userRec = [SELECT Id, Name FROM User WHERE Id = :UserInfo.getUserId()];
        UserWrapper wrap = new UserWrapper();
        wrap.userName = userRec.Name;
        return wrap;
    }

    public class UserWrapper{
        @AuraEnabled public string userName{get;set;}
    }

@AuraEnabled(cacheable=true)
public static WorkOrder getTBTWorkOrder() {
    try {
        System.debug('getTBTWorkOrder called');

         String workOrderRecordTypeId = Schema.getGlobalDescribe().get('WorkOrder').getDescribe().getRecordTypeInfosByDeveloperName().get('TBT').getRecordTypeId();

        WorkOrder wo = [
            SELECT Id, Approval_Status__c
            FROM WorkOrder
            WHERE OwnerId = :UserInfo.getUserId()
            AND RecordTypeId = :workOrderRecordTypeId
            
        ];

      //  System.debug('WorkOrder Count: ' + wo);
        return wo;

    } catch (Exception e) {
        System.debug('Error: ' + e.getMessage() + ' Line: ' + e.getLineNumber());
        return new WorkOrder();
    }
}


}