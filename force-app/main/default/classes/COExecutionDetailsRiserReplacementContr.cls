/**
* @File Name : COExecutionDetailsRiserReplacementContr.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : August 18, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | August 18, 2025 |   | Initial Version
**/

public without sharing class COExecutionDetailsRiserReplacementContr {

	@AuraEnabled
	public static WorkOrder getWorkOrder(String recordId){

		try {


			WorkOrder wo =[Select Id,Number_of_Risers__c,							
									Number_of_Floors__c,Type_of_Riser__c,
									RM_Instrument_Type_Range__c,
									RM_Calibration_Certificate_No__c,RM_Calibration_Date__c,
									RM_Calibration_Due_Date__c,Instrument_Serial_Number__c
									 from WorkOrder where Id=: recordId];

			return wo;
		}
		catch(Exception e){

			return new WorkOrder();
		}
	}

	
	@AuraEnabled
	public static void saveCODetails(string recordId, String riserNumber,  Decimal risersFloors, String riserPickListValue, String instrumentTypeRange, String calibrationCertificateNo, 
										 Date calibrationDate, Date calibrationDueDate, String instrumentSerialNumber  ){

		try {

			system.debug('record id::'+ recordId);

		WorkOrder woUpdate = [Select Id,Number_of_Risers__c,							
									Number_of_Floors__c,Type_of_Riser__c,RM_Instrument_Type_Range__c,
									RM_Calibration_Certificate_No__c,RM_Calibration_Date__c,
									RM_Calibration_Due_Date__c,Instrument_Serial_Number__c
									 
									from WorkOrder where Id=: recordId];

		woUpdate.Number_of_Risers__c =	riserNumber;
		woUpdate.Number_of_Floors__c =risersFloors;
		woUpdate.Type_of_Riser__c = riserPickListValue;
		woUpdate.RM_Instrument_Type_Range__c = 	instrumentTypeRange;
		woUpdate.RM_Calibration_Certificate_No__c = calibrationCertificateNo;
		woUpdate.RM_Calibration_Date__c = calibrationDate;
		woUpdate.RM_Calibration_Due_Date__c = calibrationDueDate;
		woUpdate.Instrument_Serial_Number__c = instrumentSerialNumber;
		


		Update woUpdate;

		Integer riserNumberValue = Integer.valueOf(riserNumber);

		List<WorkOrderLineItem> lstWorkOrderLineItem = new List<WorkOrderLineItem>();

		for(Integer i=1; i<= riserNumberValue; i++){

			WorkOrderLineItem wolitem = new WorkOrderLineItem();

			wolitem.Riser_Name__c	= 'Riser ' + i;
			wolitem.WorkOrderId = recordId;

			lstWorkOrderLineItem.add(wolitem);
		}

		if(!lstWorkOrderLineItem.isEmpty()){

			insert lstWorkOrderLineItem;

			system.debug('WorkOrderLineItem inserted ::'+ lstWorkOrderLineItem);
		}


			updateWorkStepStatus(recordId,'CO Execution Detail');



		}

		catch(Exception e){

			System.debug('Error updateworkorder details::'+ e.getLineNumber() + e.getMessage());
		}
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
            ws.Status = 'Completed'; 
            update ws;
        }
    }
}