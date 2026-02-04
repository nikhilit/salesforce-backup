// File: MeterReplacementServiceController.cls
// Purpose: Apex methods used by LWC for Meter Replacement flow (save, generate pdf, preview, upload)
// Note: sample PDF for visual matching: /mnt/data/Meter Replacement.pdf

public without sharing class MeterReplacementServiceController {

   
    public class serviceReportControllerWrapper {
        @AuraEnabled public Document__c documentRecordDetail {get; set;}
        @AuraEnabled public String profileName {get; set;}
    }

    @AuraEnabled
    public static serviceReportControllerWrapper getApprovalStatus() {
        serviceReportControllerWrapper res = new serviceReportControllerWrapper();
        try {
            User u = [SELECT Id, UserName, Profile.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            res.profileName = u.Profile.Name;
            List<Document__c> docs = [SELECT Id, Submitted_Agent_Name__c, Approval_Status_O_M__c FROM Document__c WHERE Submitted_Agent_Name__c = :u.UserName LIMIT 1];
            if (!docs.isEmpty()) res.documentRecordDetail = docs[0];
            return res;
        } catch (Exception e) {
            return res;
        }
    }

    @AuraEnabled
    public static String getWOrderWType(String recordId) {
        try {
            WorkOrder w = [SELECT Id, WorkType.Name FROM WorkOrder WHERE Id = :recordId LIMIT 1];
            return (w != null && w.WorkType != null) ? w.WorkType.Name : '';
        } catch (Exception e) {
            return 'Error';
        }
    }

    @AuraEnabled
    public static String saveMeterReplacementData(String recordId, String serviceReport) {
        try {
            Map<String, Object> dataMap = (Map<String, Object>) JSON.deserializeUntyped(serviceReport);
            WorkOrder wOrder = [SELECT Id, The_Work_Done__c, Satisfactory__c, Not_Satisfactory__c FROM WorkOrder WHERE Id = :recordId LIMIT 1];

            String satNoSatValue = (String) dataMap.get('satisfactoryNotSatisfactory');
            wOrder.The_Work_Done__c = String.isNotBlank((String) dataMap.get('workDone')) ? (String) dataMap.get('workDone') : null;

            if (satNoSatValue == 'Satisfactory') {
                wOrder.Satisfactory__c = true;
                wOrder.Not_Satisfactory__c = false;
            } else if (satNoSatValue == 'Not Satisfactory') {
                wOrder.Not_Satisfactory__c = true;
                wOrder.Satisfactory__c = false;
            } else {
                wOrder.Satisfactory__c = false;
                wOrder.Not_Satisfactory__c = false;
            }

            update wOrder;
            updateWorkStepStatus(recordId, 'Service Report');

            // generate and attach pdf
            generateAndAttachPdf(recordId);

            return 'Success';
        } catch (Exception e) {
            System.debug('Error saveMeterReplacementData: ' + e.getMessage());
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
        if (!steps.isEmpty()){
            WorkStep ws = steps[0];
            ws.Status = 'Completed';
            update ws;
        }
    }

    public static Id generateAndAttachPdf(Id workOrderId) {
        WorkOrder w = [SELECT Id, BP_Number__c FROM WorkOrder WHERE Id = :workOrderId LIMIT 1];
        PageReference pdfPage = Page.MeterReplacementDetails;
        pdfPage.getParameters().put('id', String.valueOf(workOrderId));
        Blob pdfBlob = pdfPage.getContentAsPDF();

        ContentVersion cv = new ContentVersion(
            Title = 'Meter Replacement Report ' + (w.BP_Number__c == null ? '' : w.BP_Number__c) + '.pdf',
            PathOnClient = 'MeterReplacementReport_' + workOrderId + '.pdf',
            VersionData = pdfBlob,
            FirstPublishLocationId = workOrderId
        );
        insert cv;

        ContentVersion insertedCv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        return insertedCv.ContentDocumentId;
    }

    @AuraEnabled
    public static String meterReplacementPdf(String recordId) {
        try {
            ContentDocumentLink cdl = [
                SELECT ContentDocument.LatestPublishedVersion.Id
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :recordId
                  AND ContentDocument.LatestPublishedVersion.Title LIKE '%Meter Replacement Report%'
                LIMIT 1
            ];
            if (cdl != null && cdl.ContentDocument != null) {
                return String.valueOf(cdl.ContentDocument.LatestPublishedVersion.Id);
            } else {
                return 'Error';
            }
        } catch (Exception e) {
            System.debug('meterReplacementPdf error: ' + e.getMessage());
            return 'Error';
        }
    }

    @AuraEnabled
    public static void uploadFileForMeterReplacement(String fileName, String base64Data, String recordId) {
        Blob fileBlob = EncodingUtil.base64Decode(base64Data);
        ContentVersion cv = new ContentVersion();
        cv.Title = fileName;
        cv.PathOnClient = fileName;
        cv.VersionData = fileBlob;
        cv.FirstPublishLocationId = recordId;
        insert cv;
        updateWorkStepStatus(recordId,'Service Report');
    }

    @AuraEnabled
    public static String checkWorkStep(String recordId){
        try {
            WorkStep worStep = [SELECT Id, Status,Name
                FROM WorkStep
                WHERE ParentRecordId =: recordId AND (Name='CO Execution Detail' OR Name='BP Execution Details' OR Name='Site Details')
                LIMIT 1];
            return worStep.Status;
        } catch (Exception e) {
            return 'Error';
        }
    }
}