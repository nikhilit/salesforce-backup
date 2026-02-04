/**
* @File Name : RiserReplacementServiceReportContr.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : July 19, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | July 19, 2025 |   | Initial Version
**/

public without sharing class RiserReplacementServiceReportContr {

/*@AuraEnabled
	public static string saveServiReportData(string recordId,  String oldMaterialUsed){

//string serviceReport,
		try {

  // Map<String, Object> dataMap = (Map<String, Object>) JSON.deserializeUntyped(serviceReport);

 WorkOrder wOrder = [
        SELECT Id, RM_Instrument_Type_Range__c,RM_Calibration_Certificate_No__c,RM_Calibration_Due_Date__c,
		RM_Calibration_Date__c,SR_Material_Used__c
        FROM WorkOrder
        WHERE Id = :recordId
        LIMIT 1
    ];

// wOrder.RM_Calibration_Date__c = String.isNotBlank((String)dataMap.get('calibrationDate')) ? Date.valueOf((String)dataMap.get('calibrationDate')) : null;
// wOrder.RM_Calibration_Due_Date__c = String.isNotBlank((String)dataMap.get('calibrationDueDate')) ? Date.valueOf((String)dataMap.get('calibrationDueDate')) : null;

// wOrder.RM_Instrument_Type_Range__c = String.isNotBlank((String)dataMap.get('instrumentTypeRange')) ? (String)dataMap.get('instrumentTypeRange') : null;


// wOrder.RM_Calibration_Certificate_No__c = String.isNotBlank((String)dataMap.get('calibrationCertificateNo')) ? (String)dataMap.get('calibrationCertificateNo') : null;

wOrder.SR_Material_Used__c = oldMaterialUsed;


        update wOrder;

        system.debug('Updated work order ::'+ wOrder);

	  updateWorkStepStatus(recordId,'Service Report');

       // generateAndAttachPdf(recordId);

	return 'Success';

		}
		catch(Exception e){
            system.debug('Error ::'+ e.getLineNumber() + e.getMessage());
			return  'Error';
		}

	} */


	

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
            system.debug('workstep updated ::'+ steps[0].Status);

        }
     }

	   @AuraEnabled
    public static string generateAndAttachPdf(String worOrderId) {



          try{

      //  WorkOrder worOrder = [Select id,BP_Number__c from WorkOrder where id=: worOrderId];

        system.debug('Inside generateAndAttachPdf'+ worOrderId);

        Set<Id> wolitemIds = new Set<Id>();

        List<WorkOrderLineItem> lstWOLItem = [Select id,WorkOrderId,Riser_Name__c from WorkOrderLineItem Where WorkOrderId=: worOrderId  
                                                and LastModifiedDate = today];

        List<WorkOrderLineItem_Day_Wise__c> lstWOLItemDayWise = [select id,Name,Work_Order_Line_Item__c, Work_Order_Line_Item__r.riser_name__c 
                                                                    from WorkOrderLineItem_Day_Wise__c where Work_Order_Line_Item__c
                                                                     IN:lstWOLItem and CreatedDate =today
                                                                     AND (Length_of_Riser_Tested__c !='' OR Length_of_Riser_Commissioned__c !='')];

        for(WorkOrderLineItem_Day_Wise__c wodaywise : lstWOLItemDayWise){

            wolitemIds.add(wodaywise.Work_Order_Line_Item__c);
        }

        List<WorkOrderLineItem> wolitemlst = [Select id,WorkOrderId,Riser_Name__c from WorkOrderLineItem Where Id=: wolitemIds ]; 

         
        if(!wolitemlst.isEmpty()){

          for(WorkOrderLineItem wolItem : wolitemlst){

        PageReference pdfPage = Page.riserReplacement;

        system.debug('Pdfpage :'+ pdfPage);
        pdfPage.getParameters().put('Id', wolItem.Id);
            
             Blob pdfBlob;
            if (Test.isRunningTest()) {
                pdfBlob = Blob.valueOf('Unit Test PDF Content'); 
            } else {
                pdfBlob = pdfPage.getContentAsPDF();
            }
            
            
      //  Blob pdfBlob = pdfPage.getContentAsPDF();
     //   system.debug('pdfblob ::'+ pdfBlob);

        ContentVersion cv = new ContentVersion(
           // Title = 'Service Report' + ' ' + worOrder.BP_Number__c + '.pdf',
            Title = 'Service Report' + ' ' + wolItem.Riser_Name__c + '.pdf',

            PathOnClient = 'riserReplacement' + wolItem.Id + '.pdf',
            VersionData = pdfBlob
        );
        insert cv;

        system.debug('Content version::'+ cv);

        ContentDocument cd = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :cv.Id LIMIT 1];
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cd.Id,
            LinkedEntityId = wolItem.Id,
            ShareType = 'V'
        );
        insert cdl;

        system.debug('cdl::'+ cdl);



        }



        updateWorkStepStatus(worOrderId,'Service Report');

        return 'Records Found';

        }
        else {

            return 'Records Not Found';
        }


       // return cd.Id;

        }
        catch(Exception e){

            system.debug('Error ::'+ e.getLineNumber() + e.getMessage());
            return   'Error';
        }
    }

	 
}