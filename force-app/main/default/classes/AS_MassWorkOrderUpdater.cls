/**
* @File Name : AS_MassWorkOrderUpdater.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : August 5, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | August 5, 2025 |   | Initial Version
**/

public without sharing class AS_MassWorkOrderUpdater {

    @AuraEnabled
    public static void updateRemarks(List<Id> workOrderIds, String remarks) {
		try{

			Set<String> setWorkOrderId = new Set<String>();

			List<WorkOrder> workOrdersToUpdate = [SELECT Id, Remarks__c, Agent__c, R_T_Agency__c
													FROM WorkOrder 
												   WHERE Id IN :workOrderIds 
												     AND Record_Type_Developer_Name__c = 'MGL_R_T'];

			for (WorkOrder wo : workOrdersToUpdate) {
				wo.Remarks__c = remarks;
				wo.Agent__c = null;
				wo.R_T_Agency__c = null;

				setWorkOrderId.add(wo.Id);
			}
 
			delete [SELECT Id FROM ServiceAppointment WHERE ParentRecordId =: setWorkOrderId];

			update workOrdersToUpdate;

		} catch (Exception ex) {
            AS_ErrorLogger.log('AS_MassWorkOrderUpdater', 'updateRemarks', ex, '');
        }
    }
}