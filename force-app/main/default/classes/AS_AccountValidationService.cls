/**
* @File Name : AS_AccountValidationService.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : July 24, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | July 24, 2025 |   | Initial Version
**/
public without sharing class AS_AccountValidationService {
    @AuraEnabled(cacheable=true)
    public static WorkOrder isAccountFlagged(Id workOrderId) {
        return [SELECT Remarks__c 
                  FROM WorkOrder 
                 WHERE Id = :workOrderId 
                   AND Record_Type_Developer_Name__c = 'MGL_R_T'
                 LIMIT 1];
    }

    @AuraEnabled
    public static Boolean isDomestic() { 
      Id currentUserId = UserInfo.getUserId(); 
      List<ServiceTerritoryMember> lstSTM = [SELECT Id, ServiceResource.RelatedRecordId, ServiceResource.Service_Resource_Type__c
                                FROM ServiceTerritoryMember
                                WHERE ServiceResource.RelatedRecordId =: currentUserId
                            AND ServiceResource.Service_Resource_Type__c IN ('Collection Agent', 'I&C Agent')];
      return (!lstSTM.isEmpty() && lstSTM.get(0).ServiceResource.Service_Resource_Type__c.contains('Collection Agent'));
    }
}