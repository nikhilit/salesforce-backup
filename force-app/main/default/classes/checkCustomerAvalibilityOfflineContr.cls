/**
* @File Name : checkCustomerAvalibilityOfflineContr.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : October 10, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 10, 2025 |   | Initial Version
**/

public class checkCustomerAvalibilityOfflineContr {


	@AuraEnabled
	 public static string getWorkStepStatus(Id workOrderId,String name){

		try {
        WorkStep steps = [
			SELECT Id, Status
			FROM WorkStep
			WHERE ParentRecordId = :workOrderId
			AND Name = :name
			LIMIT 1
		];

		return steps.Id;

		}

        
       // if (!steps.isEmpty()) {
          //  WorkStep ws = steps[0];
          //  ws.Status = 'Completed'; // Or whatever picklist value you use
          //  update ws;
        
		catch(Exception e){

			system.debug('error getting workstep id'+ e.getLineNumber() + e.getMessage());
			return 'error';
		}
     }

	 @AuraEnabled
	 public static WorkStep getWorkStepAndStatus(Id workOrderId,String name){

		try {
        WorkStep steps = [
			SELECT Id, Status
			FROM WorkStep
			WHERE ParentRecordId = :workOrderId
			AND Name = :name
			LIMIT 1
		];

		return steps;

		}

        
       // if (!steps.isEmpty()) {
          //  WorkStep ws = steps[0];
          //  ws.Status = 'Completed'; // Or whatever picklist value you use
          //  update ws;
        
		catch(Exception e){

			system.debug('error getting workstep id'+ e.getLineNumber() + e.getMessage());
			return new workStep();
		}
     }

}