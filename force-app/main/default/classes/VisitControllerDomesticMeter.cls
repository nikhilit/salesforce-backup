public without sharing class VisitControllerDomesticMeter {
    @AuraEnabled
public static void markCustomerUnavailable(Id recordId, String reason, String remarks, Date followUpDate) {
    try {
        System.debug('Step 1: Fetching WorkOrder');
        WorkOrder wo = [
            SELECT Id, Status, Attempt_Count__c, Enable_DPR_Submission__c
            FROM WorkOrder
            WHERE Id = :recordId
            LIMIT 1
        ];

        System.debug('Step 2: Fetching ServiceAppointment');
        List<ServiceAppointment> appointments = [
            SELECT Id, ParentRecordId, Customer_Unavailability_Reason__c, Follow_up_Remarks__c, Follow_Up_Visit_Date__c
            FROM ServiceAppointment
            WHERE ParentRecordId = :wo.Id
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        if (appointments.isEmpty()) {
            throw new AuraHandledException('No ServiceAppointment found for this Work Order.');
        }

        ServiceAppointment sa = appointments[0];

        System.debug('Step 3: Updating ServiceAppointment');
        sa.Customer_Unavailability_Reason__c = reason;
        sa.Follow_up_Remarks__c = remarks;
        sa.SchedStartTime = followUpDate;
        update sa;

        System.debug('Step 4: Updating WorkOrder');
        wo.Status = 'Customer Unavailable';
        wo.Attempt_Count__c = (wo.Attempt_Count__c == null) ? 1 : wo.Attempt_Count__c + 1;
        update wo;

        System.debug('Step 5: Creating FollowUp or Enabling DPR');
        // if (wo.Attempt_Count__c < 4) {
        //     createFollowUpAppointment(sa, wo);
        // } else {
        //     enableDPRSubmission(wo);
        // }

    } catch (Exception e) {
        System.debug('Exception in markCustomerUnavailable: ' + e.getMessage());
        throw new AuraHandledException('Server Error: ' + e.getMessage());
    }
}




    // private static void createFollowUpAppointment(ServiceAppointment originalSA, WorkOrder wo) {
    //     ServiceAppointment followUp = new ServiceAppointment();
    //     followUp.ParentRecordId = wo.Id;
    //     followUp.Status = 'None';
    //     followUp.Subject = 'Follow-Up Visit after Customer Unavailable';
    //     followUp.SchedStartTime = originalSA.Follow_Up_Visit_Date__c;
    //     followUp.SchedEndTime = originalSA.Follow_Up_Visit_Date__c.addDays(7);
    //     followUp.Description = 'Auto-created follow-up after failed attempt on: ' + originalSA.Id;

    //     insert followUp;
    // }

    private static void enableDPRSubmission(WorkOrder wo) {
        wo.Enable_DPR_Submission__c = true;
        update wo;
    }

	@AuraEnabled
    public static String savePhotoUploadsDomesticMeter(Id recordId, List<PhotoWrapper> listFiles) {
        System.debug('savePhotoUploads START for Record Id: ' + recordId);
        System.debug('Received Files: ' + JSON.serializePretty(listFiles));

        try {
            List<ContentVersion> contentVersions = new List<ContentVersion>();

            for (PhotoWrapper file : listFiles) {
                if (String.isNotBlank(file.base64Data) && String.isNotBlank(file.fileName)) {
                    ContentVersion cv = new ContentVersion();
                    cv.Title = file.label;
                    cv.PathOnClient = '/' + file.fileName;
                    cv.VersionData = EncodingUtil.base64Decode(file.base64Data);
                    contentVersions.add(cv);
                }
            }

            if (contentVersions.isEmpty()) {
                return 'No valid files to upload.';
            }

            insert contentVersions;

            // Map ContentVersion to ContentDocument
            Map<Id, Id> versionToDocMap = new Map<Id, Id>();
            for (ContentVersion cv : [
                SELECT Id, ContentDocumentId 
                FROM ContentVersion 
                WHERE Id IN :contentVersions
            ]) {
                versionToDocMap.put(cv.Id, cv.ContentDocumentId);
            }

            // Create ContentDocumentLinks
            List<ContentDocumentLink> links = new List<ContentDocumentLink>();
            for (Id versionId : versionToDocMap.keySet()) {
                links.add(new ContentDocumentLink(
                    ContentDocumentId = versionToDocMap.get(versionId),
                    LinkedEntityId = recordId,
                    ShareType = 'V',
                    Visibility = 'AllUsers'
                ));
            }

            insert links;

            updateWorkStepStatus(recordId, 'Work Order Execution Detail');

            return 'SUCCESS';
        } catch (Exception e) {
            return 'ERROR: ' + e.getMessage();
        }
    }

    // Mark Work Step as Completed
    public static void updateWorkStepStatus(Id workOrderId, String name) {
        try {
            List<WorkStep> steps = [
                SELECT Id, Status 
                FROM WorkStep 
                WHERE ParentRecordId = :workOrderId 
                AND Name = :name 
                LIMIT 1
            ];

            if (!steps.isEmpty()) {
                WorkStep ws = steps[0];

                if (String.isBlank(ws.Status)) {
                    return;
                }

                ws.Status = 'Completed';
                update ws;
            }
        } catch (Exception e) {
            System.debug('Exception in updateWorkStepStatus: ' + e.getMessage());
        }
    }

    // Wrapper for Files from LWC
    public class PhotoWrapper {
        @AuraEnabled public String base64Data { get; set; }
        @AuraEnabled public String fileName { get; set; }
        @AuraEnabled public String label { get; set; }
    }	
    
}