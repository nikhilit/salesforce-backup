/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : AddNoOfRisersContr
 * Author          : <YourName>
 * Created Date    : Jan 19, 2026
 * Last Modified By: <YourName>
 * Last Modified On: Jan 19, 2026
 * Description     : This class implements for......
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Jan 19, 2026  │ <YourName>   │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */

public without sharing class AddNoOfRisersContr {

	@AuraEnabled
	public static string getWorkOrder(String recordId){

		try {

			system.debug('inside add no of riser controller');
			WorkOrder wo =[Select Id,Number_of_Risers__c from WorkOrder where Id=: recordId];

			return wo.Number_of_Risers__c;
			//return wo;
		}
		catch(Exception e){

			system.debug('Error:::'+ e.getLineNumber() + e.getMessage());

			return '';

			//return new WorkOrder();
		}
	}

	@AuraEnabled
	public static void updateCODetails(string recordId, String riserNumber, string noOfRisersAlreadyCreated, string existingandCurrentNoOfRisers ){

		try {

		WorkOrder woUpdate = [Select Id,Number_of_Risers__c									
									from WorkOrder where Id=: recordId];

				

		woUpdate.Number_of_Risers__c =	existingandCurrentNoOfRisers;
		
		

		Update woUpdate;

		

		Integer riserNumberValue = Integer.valueOf(riserNumber);
		//Integer riserNumberCreatedValue = Integer.valueOf(noOfRisersAlreadyCreated) + 1 ;

		Integer riserNumberCreatedValue =
   											 (String.isBlank(noOfRisersAlreadyCreated)
    											    ? 0
       										 : Integer.valueOf(noOfRisersAlreadyCreated)
 									   ) + 1;
		Integer existingandCurrentNoOfRisersValue = Integer.valueOf(existingandCurrentNoOfRisers);

		system.debug('riserNumberValue::'+ riserNumberValue);
		system.debug('riserNumberCreatedValue::'+ riserNumberCreatedValue);

		system.debug('existingandCurrentNoOfRisersValue::'+ existingandCurrentNoOfRisersValue);


		// for(Integer i=riserNumberCreatedValue; i<= (riserNumberCreatedValue + riserNumberValue); i++){
		
		List<WorkOrderLineItem> lstWorkOrderLineItem = new List<WorkOrderLineItem>();

		for(Integer i=riserNumberCreatedValue; i<= existingandCurrentNoOfRisersValue; i++){

			WorkOrderLineItem wolitem = new WorkOrderLineItem();

			wolitem.Riser_Name__c	= 'Riser ' + i;
			wolitem.WorkOrderId = recordId;

			lstWorkOrderLineItem.add(wolitem);
		}

		if(!lstWorkOrderLineItem.isEmpty()){

			insert lstWorkOrderLineItem;

			system.debug('WorkOrderLineItem inserted ::'+ lstWorkOrderLineItem);
		}


		//updateWorkStepStatus(recordId,'CO Execution Detail');



		}

		catch(Exception e){

			System.debug('Error updateworkorder details::'+ e.getLineNumber() + e.getMessage());
		}
	}


}