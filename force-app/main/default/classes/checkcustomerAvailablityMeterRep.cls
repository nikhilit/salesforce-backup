/**
* @File Name : checkCustomerAvalibilityIPDContr.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : October 18, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 18, 2025 |   | Initial Version
**/

public without sharing class checkcustomerAvailablityMeterRep {
	
	@AuraEnabled
	public static void updateWorkOrder(String recordId, String customerAvailability){

		  WorkOrder wo =[Select Id,Check_Customer_Availability__c from WorkOrder where Id=: recordId ];
			
			wo.Id = recordId;
            wo.Check_Customer_Availability__c = customerAvailability;
            

            update wo;

         //updateWorkStepStatus(recordId,'Check Customer Availability');
		updateWorkStepStatus(recordId, 'Check Customers Availability');


	}

	public static void updateWorkStepStatus(Id workOrderId,String name){
        List<WorkStep> steps = [
			SELECT Id, Status
			FROM WorkStep
			WHERE ParentRecordId = :workOrderId
			AND Name = :name
			LIMIT 1
		];
        
        if (!steps.isEmpty()) {
            WorkStep ws = steps[0];
            ws.Status = 'Completed'; // Or whatever picklist value you use
            update ws;
        }
     }

	  @AuraEnabled
    public static string checkWorkStepCheckin(string recordId){

        try {

            System.debug('inside check work step method in apex');
             System.debug('Record id::'+ recordId);

       WorkStep worStep = [SELECT Id, Status,Name
			FROM WorkStep
			WHERE ParentRecordId =: recordId AND Name='Check/In'];

    system.debug('Work step result ::'+ worStep.Status);
        return worStep.Status;
    
    }
    catch(Exception e){
        return 'Error';
    }
			
    }

     @AuraEnabled 
    public static string getWOrderWType(string recordId){

        try {

        WorkOrder wOrder = [Select id,WorkType.Name from WorkOrder where Id=:recordId];

        return wOrder.WorkType.Name;
    }

    catch(Exception e){
        return 'Error';
    }

    }

}