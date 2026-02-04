/**
* @File Name : MeterReplacementMRJCContr.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : July 1, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | July 1, 2025 |   | Initial Version
**/

public without sharing class MeterReplacementMRJCContr {
	
	 

	@AuraEnabled
	public static string saveMRJCData(string recordId, string mrjcReport){


		try {

   Map<String, Object> dataMap = (Map<String, Object>) JSON.deserializeUntyped(mrjcReport);

 WorkOrder wOrder = [
        SELECT Id, Penumatic_Pressure_Test_At_32_mba__c,Leak_Test_With_SOAP_Solution__c,
                      Gascoseeker_Reading__c,Rubber_Tube_Type__c,Ensure_No_Gas_Leakage_Before_LeavingSit__c,Reason_MetRep_Pdf__c,
                      Action_Taken_MetRep_Pdf__c,Material_Recovered__c,Satisfactory__c,Not_Satisfactory__c,Rubber_Tube_Condition__c,
					  Old_Meter_Make__c,Old_Meter_Serial_No__c,Old_Meter_Reading__c, Old_Remark__c , New_Meter_Make__c,
					  New_Meter_Serial_No__c, New_Meter_Reading__c,New_Remark__c 
					  	FROM WorkOrder WHERE Id = :recordId LIMIT 1
    ];
String satNoSatValue = (String)dataMap.get('satisOrNotSatisfactory');

wOrder.Penumatic_Pressure_Test_At_32_mba__c = String.isNotBlank((String)dataMap.get('penumaticPressure')) ? (String)dataMap.get('penumaticPressure') : null;
//wOrder.Nature_of_work_type_of_request__c = String.isNotBlank((String)dataMap.get('natureOfWork')) ? (String)dataMap.get('natureOfWork') : null;
wOrder.Leak_Test_With_SOAP_Solution__c = String.isNotBlank((String)dataMap.get('leakTestSolution')) ? (String)dataMap.get('leakTestSolution') : null;
wOrder.Gascoseeker_Reading__c = String.isNotBlank((String)dataMap.get('gascoseekerReading')) ? (String)dataMap.get('gascoseekerReading') : null;
wOrder.Rubber_Tube_Type__c = String.isNotBlank((String)dataMap.get('rubberTubeType')) ? (String)dataMap.get('rubberTubeType') : null;
wOrder.Ensure_No_Gas_Leakage_Before_LeavingSit__c = String.isNotBlank((String)dataMap.get('noGasLeak')) ? (String)dataMap.get('noGasLeak') : null;
wOrder.Reason_MetRep_Pdf__c = String.isNotBlank((String)dataMap.get('reason')) ? (String)dataMap.get('reason') : null;
wOrder.Action_Taken_MetRep_Pdf__c = String.isNotBlank((String)dataMap.get('actionTaken')) ? (String)dataMap.get('actionTaken') : null;



wOrder.Material_Recovered__c = String.isNotBlank((String)dataMap.get('materialRecovered')) ? (String)dataMap.get('materialRecovered') : null;
wOrder.Old_Meter_Serial_No__c = String.isNotBlank((String)dataMap.get('oldMeterSerialNo')) ? (String)dataMap.get('oldMeterSerialNo') : null;
wOrder.Old_Meter_Make__c = String.isNotBlank((String)dataMap.get('oldMeterMake')) ? (String)dataMap.get('oldMeterMake') : null;
wOrder.Rubber_Tube_Condition__c = String.isNotBlank((String)dataMap.get('rubberTuberCondition')) ? (String)dataMap.get('rubberTuberCondition') : null;
wOrder.Old_Meter_Reading__c = String.isNotBlank((String)dataMap.get('oldMeterReading')) ? (String)dataMap.get('oldMeterReading') : null;
wOrder.Old_Remark__c = String.isNotBlank((String)dataMap.get('oldRemark')) ? (String)dataMap.get('oldRemark') : null;
wOrder.New_Meter_Make__c = String.isNotBlank((String)dataMap.get('newMeterMake')) ? (String)dataMap.get('newMeterMake') : null;
wOrder.New_Meter_Serial_No__c = String.isNotBlank((String)dataMap.get('newMeterSerialNo')) ? (String)dataMap.get('newMeterSerialNo') : null;

wOrder.New_Meter_Reading__c = String.isNotBlank((String)dataMap.get('newMeterReading')) ? (String)dataMap.get('newMeterReading') : null;
wOrder.New_Remark__c = String.isNotBlank((String)dataMap.get('newRemark')) ? (String)dataMap.get('newRemark') : null;


if (satNoSatValue == 'Satisfactory') {
    wOrder.Satisfactory__c = true;
} 
 else if (satNoSatValue == 'Not Satisfactory') {
    wOrder.Not_Satisfactory__c = true;
}

        update wOrder;

        system.debug('Updated work order ::'+ wOrder);

	  updateWorkStepStatus(recordId,'Service Report');

        //generateAndAttachPdf(recordId);
        System.enqueueJob(new ServiceReportPdfQueueable(recordId));


	return 'Success';

		}
		catch(Exception e){
            system.debug('Error ::'+ e.getLineNumber() + e.getMessage());
			return  'Error';
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

      @AuraEnabled
    public static void materialConsumption(String recordId,  List<MaterialWrapper> materialList){


        try {

          List<Material_Consumption__c> lstMaterConsumption = new List<Material_Consumption__c>();

        for (MaterialWrapper wrapper : materialList) {
            System.debug('Processing MaterialWrapper: ' + JSON.serializePretty(wrapper));
            
            Material_Consumption__c record = new Material_Consumption__c(
                Work_Order__c = recordId,
                Item_description__c = wrapper.itemDescription,
             //   Unit__c = wrapper.unit,
                Quantity__c	 = wrapper.quantity
            );
            lstMaterConsumption.add(record);
        }

        if (!lstMaterConsumption.isEmpty()) {
            insert lstMaterConsumption;
            System.debug('Inserted Material Consumption records: ' + lstMaterConsumption);
        }

        }

           catch(Exception e){

            system.debug('Error ::'+ e.getMessage() + ' ' + e.getLineNumber());
        }


    }

    public class MaterialWrapper {
        // @AuraEnabled public String itemCode;
        @AuraEnabled public String itemDescription{get;set;}
     //   @AuraEnabled public String unit{get;set;}
        @AuraEnabled public Integer quantity{get;set;} // or Decimal if you're always passing a number
    }


     
    public static Id generateAndAttachPdf(String worOrderId) {

        WorkOrder worOrder = [Select id,BP_Number__c from WorkOrder where id=: worOrderId];

        system.debug('Inside generateAndAttachPdf'+ worOrderId);

        PageReference pdfPage = Page.MRJCReport;

        system.debug('Pdfpage :'+ pdfPage);
        pdfPage.getParameters().put('id', worOrderId);
        Blob pdfBlob = pdfPage.getContentAsPDF();

        ContentVersion cv = new ContentVersion(
            Title = 'Service Report' + ' ' + worOrder.BP_Number__c + '.pdf',
            PathOnClient = 'MeterReplacement' + worOrderId + '.pdf',
            VersionData = pdfBlob
        );
        insert cv;

        system.debug('Content version::'+ cv);

        ContentDocument cd = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :cv.Id LIMIT 1];
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cd.Id,
            LinkedEntityId = worOrderId,
            ShareType = 'V'
        );
        insert cdl;

        system.debug('cdl::'+ cdl);

        return cd.Id;
    }

      @AuraEnabled
public static List<String> getItemDescriptionOptions() {
    List<String> options = new List<String>();

    // This is the correct way to get the picklist entries for a field
    Schema.DescribeFieldResult fieldResult = Material_Consumption__c.Item_Description__c.getDescribe();
    List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();

    for (Schema.PicklistEntry pe : picklistValues) {
        options.add(pe.getValue());
    }

    return options;
}



}