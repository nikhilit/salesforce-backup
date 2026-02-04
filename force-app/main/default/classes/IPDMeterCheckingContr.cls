/**
* @File Name : IPDMeterCheckingContr.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : September 11, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | September 11, 2025 |   | Initial Version
**/

public without sharing class IPDMeterCheckingContr {
    
     @AuraEnabled
    public static void generateAndAttachPdf(String worOrderId) {

        try{

        WorkOrder worOrder = [Select id,BP_Number__c from WorkOrder where id=: worOrderId];

        system.debug('Inside generateAndAttachPdf'+ worOrderId);

       // List<WorkOrderLineItem> lstWOLItem = [Select id,WorkOrderId,Riser_Name__c from WorkOrderLineItem Where WorkOrderId=: worOrderId];


       // for(WorkOrderLineItem wolItem : lstWOLItem){

        PageReference pdfPage = Page.IPDReport;

        system.debug('Pdfpage :'+ pdfPage);
        pdfPage.getParameters().put('Id', worOrderId);
            
             Blob pdfBlob;
            if (Test.isRunningTest()) {
                pdfBlob = Blob.valueOf('Unit Test PDF Content'); 
            } else {
                pdfBlob = pdfPage.getContentAsPDF();
            }
            
       // Blob pdfBlob = pdfPage.getContentAsPDF();
      //  system.debug('pdfblob ::'+ pdfBlob);

        ContentVersion cv = new ContentVersion(
            Title = 'Service Report' + ' ' + worOrder.BP_Number__c + '.pdf',
          //  Title = 'Service Report' + ' ' + wolItem.Riser_Name__c + '.pdf',

            PathOnClient = 'ipd' + worOrderId + '.pdf',
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



      //  }

        updateWorkStepStatus(worOrderId,'Service Report');


       // return cd.Id;

        }
        catch(Exception e){

            system.debug('Error ::'+ e.getLineNumber() + e.getMessage());
           // return   null;
        }
    }

    @AuraEnabled
    public static  String getCreatedServiceReportDetail(string recordId){

        try {

            List<ContentDocumentLink> contDocLinkList = [select id,ContentDocument.Title from ContentDocumentLink 
            where LinkedEntityId =:recordId and ContentDocument.Title Like '%Service Report%' limit 1];

            if(!contDocLinkList.isEmpty()){

                return 'EXISTS';

            }else {

                return 'Not EXISTS';
            }
        }

        catch(Exception e){

            system.debug('Error getting service report pdf data::'+ e.getLineNumber() + e.getMessage());

            return 'Error';
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
            ws.Status = 'Completed'; // Or whatever picklist value you use
            update ws;
        }
     }

}