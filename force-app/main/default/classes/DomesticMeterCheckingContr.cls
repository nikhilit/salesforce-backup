/**
* @File Name : DomesticMeterCheckingContr.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : August 14, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | August 14, 2025 |   | Initial Version
**/

public without sharing class DomesticMeterCheckingContr {
 
 
 /*@AuraEnabled
public static void saveMeterCheckingData(String workOrderId, String materialUsed, String materialRecovered, String actionTaken) {
    try {
        WorkOrder wo = [SELECT Id, SR_Material_Used__c,Remarks__c,Material_Recovered__c  FROM WorkOrder WHERE Id = :workOrderId LIMIT 1];
        wo.SR_Material_Used__c = materialUsed;
		wo.Material_Recovered__c =materialRecovered;
		wo.Remarks__c = actionTaken;
        update wo;

		system.debug('workorder update save meter checking data'+ wo);

          updateWorkStepStatus(workOrderId,'Service Report');

        //return 'Success';


    } catch (Exception e) {
        System.debug('Error in saveMeterCheckingData: ' + e.getMessage());
       // return 'Error';
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
        }
     }


	 @AuraEnabled
    public static Id generateAndAttachPdf(String workOrderId) {

        try{

			system.debug('insde generateand attach pdf');

            system.debug('workorder id ::'+ workOrderId);

        WorkOrder worOrder = [Select id,BP_Number__c from WorkOrder where id=: workOrderId];

        system.debug('Inside generateAndAttachPdf'+ workOrderId);

        PageReference pdfPage = Page.domesticMeterCheckingReportPage;

        system.debug('Pdfpage :'+ pdfPage);
        pdfPage.getParameters().put('Id', workOrderId);
            Blob pdfBlob;
            if(!Test.isRunningTest()){
                  pdfBlob = pdfPage.getContentAsPDF();
            }else{
                  pdfBlob = Blob.valueOf('gimme a blob value');
            }
        system.debug('pdfblob ::'+ pdfBlob);

        ContentVersion cv = new ContentVersion(
            Title = 'Service Report' + ' ' + worOrder.BP_Number__c + '.pdf',
            PathOnClient = 'dmc' + workOrderId + '.pdf',
            VersionData = pdfBlob
        );
        insert cv;

        system.debug('Content version::'+ cv);

        ContentDocument cd = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :cv.Id LIMIT 1];
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cd.Id,
            LinkedEntityId = workOrderId,
            ShareType = 'V'
        );
        insert cdl;

             updateWorkStepStatus(workOrderId,'Service Report');


        system.debug('cdl::'+ cdl);

        return cd.Id;

        }
        catch(Exception e){

            system.debug('Error ::'+ e.getLineNumber() + e.getMessage());
            return   null;
        }
    }
}