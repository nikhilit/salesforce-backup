/**
* @File Name : COExecutionDetailsRiserMaintenanceContr.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : August 15, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | August 15, 2025 |   | Initial Version
**/

public without sharing class COExecutionDetailsRiserMaintenanceContr {


	@AuraEnabled
	public static WorkOrder getWorkOrder(String recordId){

		try {


			WorkOrder wo =[Select Id,Number_of_Risers__c,Sample_BP_Number_1__c,
									Sample_BP_Number_2__c,Information_Board_available__c,
									Number_of_Floors__c,Type_of_Riser__c,
									New_information_board_installed__c,RM_Instrument_Type_Range__c,
									RM_Calibration_Certificate_No__c,RM_Calibration_Date__c,
									RM_Calibration_Due_Date__c,Instrument_Serial_Number__c	 from WorkOrder where Id=: recordId];

			return wo;
		}
		catch(Exception e){

			return new WorkOrder();
		}
	}

@AuraEnabled
	public static ServiceAppointment getServiceAppointment(String recordId){

		try {


			ServiceAppointment srAppointment = [Select id,Is_Any_Copper_Leakage_Found__c,Is_Any_Crimp_Guard_Leakage_Found__c,Is_Any_SR_Leakage_Found__c,
													CopperLeakageFoundNotificationNo__c,CrimpLeakageFoundNotificationNo__c,SRLeakageFountNotificationNo__c
													 from ServiceAppointment where ParentRecordId =:recordId limit 1];	
			return srAppointment;
		}
		catch(Exception e){

			return new ServiceAppointment();
		}
	}
	
	@AuraEnabled
	public static void saveCODetails(string recordId, String riserNumber, String sampleBP1, 
										String sampleBP2, String boardAvailable, String risersFloors,
										 String riserPickListValue, String newInformationBoardInstalled,
										 String instrumentTypeRange, String calibrationCertificateNo, 
										 Date calibrationDate, Date calibrationDueDate, String instrumentSerialNumber,
										 string isanycopperleakagefound, string copperLeakageFoundNotificationNo, string isanycrimpguardleakagefound,
										 string crimpLeakageFoundNotificationNo, string isanySRleakagefound, string srLeakageFountNotificationNo ){

		try {

		WorkOrder woUpdate = [Select Id,Number_of_Risers__c,Sample_BP_Number_1__c,
									Sample_BP_Number_2__c,Information_Board_available__c,
									Number_of_Floors__c,Type_of_Riser__c,
									New_information_board_installed__c ,RM_Instrument_Type_Range__c,
									RM_Calibration_Certificate_No__c,RM_Calibration_Date__c,
									RM_Calibration_Due_Date__c,Instrument_Serial_Number__c										
									from WorkOrder where Id=: recordId];

			ServiceAppointment srAppointment = [Select id,Is_Any_Copper_Leakage_Found__c,Is_Any_Crimp_Guard_Leakage_Found__c,Is_Any_SR_Leakage_Found__c,
													CopperLeakageFoundNotificationNo__c,CrimpLeakageFoundNotificationNo__c,SRLeakageFountNotificationNo__c
													 from ServiceAppointment where ParentRecordId =:recordId limit 1];						

		woUpdate.Number_of_Risers__c =	riserNumber;
		woUpdate.Sample_BP_Number_1__c = sampleBP1;
		woUpdate.Sample_BP_Number_2__c = sampleBP2;
		woUpdate.Number_of_Floors__c =Decimal.valueOf(risersFloors);
		woUpdate.Type_of_Riser__c = riserPickListValue;
	    woUpdate.Information_Board_available__c = boardAvailable;
		woUpdate.New_information_board_installed__c	= newInformationBoardInstalled;	
		woUpdate.RM_Instrument_Type_Range__c = 	instrumentTypeRange;
		woUpdate.RM_Calibration_Certificate_No__c = calibrationCertificateNo;
		woUpdate.RM_Calibration_Date__c = calibrationDate;
		woUpdate.RM_Calibration_Due_Date__c = calibrationDueDate;
		woUpdate.Instrument_Serial_Number__c = instrumentSerialNumber;
		

		Update woUpdate;

		srAppointment.Is_Any_Copper_Leakage_Found__c = isanycopperleakagefound;
		srAppointment.Is_Any_Crimp_Guard_Leakage_Found__c = isanycrimpguardleakagefound;
		srAppointment.Is_Any_SR_Leakage_Found__c = isanySRleakagefound;
		//srAppointment.CopperLeakageFoundNotificationNo__c = copperLeakageFoundNotificationNo;
		//srAppointment.CrimpLeakageFoundNotificationNo__c = crimpLeakageFoundNotificationNo;
		srAppointment.SRLeakageFountNotificationNo__c = srLeakageFountNotificationNo;

		update srAppointment;


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