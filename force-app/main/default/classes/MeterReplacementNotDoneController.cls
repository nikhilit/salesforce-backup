public class MeterReplacementNotDoneController {

  
@AuraEnabled
public static void markCustomerUnavailable(Id workOrderId, String reason, Date followUpDate, String remarks) {
    try {
        if (workOrderId == null) {
            throw new AuraHandledException('Work Order ID is required.');
        }

        // Fetch original WO with hierarchy and key fields
        WorkOrder wo = [
            SELECT Id, WorkOrderNumber, Subject, ParentWorkOrderId, AccountId, OwnerId, Status, 
                   Meter_Replacement_Status__c, Description
            FROM WorkOrder
            WHERE Id = :workOrderId
            LIMIT 1
        ];

        // Update current WorkOrder
        wo.Meter_Replacement_Status__c = 'Customer Not Available';
        wo.Follow_Up_Appointment_Date__c = followUpDate;
        wo.Description = (wo.Description == null ? '' : wo.Description + '\n') +
                         'Customer Unavailable Reason: ' + reason +
                         '\nRemarks: ' + remarks;
        update wo;

        // List<Case> casesToInsert = new List<Case>();
        // List<Case> casesToUpdate = new List<Case>();
        List<WorkOrder> newWorkOrders = new List<WorkOrder>();

        Boolean isFirstVisit = (wo.ParentWorkOrderId == null);
        Boolean isSecondVisit = (wo.Subject != null && wo.Subject.startsWith('Follow-up Visit 1'));

        if (isFirstVisit) {
            // Create first case
            // Case c = new Case();
            // c.Origin = 'Field Technician';
            // c.Subject = 'Customer Not Available - Work Order: ' + wo.WorkOrderNumber;
            // c.Status = 'New';
            // c.Work_Order__c = wo.Id;
            // c.Description = 'Technician marked customer as unavailable for Work Order ' + wo.WorkOrderNumber;
            // c.First_Intimation_Sent_Date__c = Date.today();
            // casesToInsert.add(c);

            // Create Follow-up Work Order 1
            WorkOrder followUp1 = new WorkOrder();
            followUp1.AccountId = wo.AccountId;
            followUp1.Subject = 'Follow-up Visit 1: ' + wo.Subject;
            followUp1.Status = 'Scheduled'; // This is standard field
            followUp1.Meter_Replacement_Status__c = 'Rescheduled'; // Use valid picklist value
            followUp1.Scheduled_Date__c = Date.today().addDays(7);
            followUp1.ParentWorkOrderId = wo.Id;
            followUp1.OwnerId = wo.OwnerId;
            newWorkOrders.add(followUp1);

        } else if (isSecondVisit) {
            // Find linked Case for follow-up visit
            List<Case> linkedCases = [
                SELECT Id, Final_Attempt_WorkOrder__c
                FROM Case
                WHERE Second_Attempt_Work_Order__c = :wo.Id
                LIMIT 1
            ];

            WorkOrder followUp2 = new WorkOrder();
            followUp2.AccountId = wo.AccountId;
            followUp2.Subject = 'Follow-up Visit 2 (Final Attempt): ' + wo.Subject;
            followUp2.Status = 'Scheduled';
            followUp2.Meter_Replacement_Status__c = 'Rescheduled';
            followUp2.Scheduled_Date__c = Date.today().addDays(15);
            followUp2.ParentWorkOrderId = wo.Id;
            followUp2.OwnerId = wo.OwnerId;
            newWorkOrders.add(followUp2);

            // if (!linkedCases.isEmpty()) {
            //     Case c = linkedCases[0];
            //     c.Final_Intimation_Sent_Date__c = Date.today();
            //     casesToUpdate.add(c);
            // }
        }

        // if (!casesToInsert.isEmpty()) insert casesToInsert;
        if (!newWorkOrders.isEmpty()) insert newWorkOrders;

        // Update Final_Attempt_WorkOrder__c in Case after WOs inserted
        // if (!casesToUpdate.isEmpty()) {
        //     for (Integer i = 0; i < casesToUpdate.size(); i++) {
        //         casesToUpdate[i].Final_Attempt_WorkOrder__c = newWorkOrders[i].Id;
        //     }
        //     update casesToUpdate;
        // }

    } catch (Exception e) {
        System.debug('Error in markCustomerUnavailable: ' + e.getMessage());
        throw new AuraHandledException('Failed to mark customer unavailable: ' + e.getMessage());
    }
}





@AuraEnabled
    public static String savePhotoUploads(Id recordId, List<PhotoWrapper> listFiles) {
        System.debug('Starting savePhotoUploads for Record Id: ' + recordId);
        System.debug('Received PhotoWrapper List: ' + JSON.serializePretty(listFiles));

        try {
            List<ContentVersion> contentVersions = new List<ContentVersion>();

            for (PhotoWrapper file : listFiles) {
                if (String.isNotBlank(file.base64Data) && String.isNotBlank(file.fileName)) {
                    ContentVersion cv = new ContentVersion();
                    cv.Title = file.label;
                    cv.PathOnClient = '/' + file.fileName;
                    cv.VersionData = EncodingUtil.base64Decode(file.base64Data);
                    contentVersions.add(cv);
                    System.debug('Added ContentVersion for: ' + file.label);
                } else {
                    System.debug('Skipping file due to missing base64Data or fileName');
                }
            }

            if (contentVersions.isEmpty()) {
                System.debug('No valid files to insert. Exiting early.');
                return 'No valid files to upload.';
            }

            insert contentVersions;
            System.debug('Inserted ContentVersions: ' + contentVersions);

            // Map ContentVersion Id to ContentDocumentId
            Map<Id, Id> versionToDocMap = new Map<Id, Id>();
            for (ContentVersion cv : [
                SELECT Id, ContentDocumentId 
                FROM ContentVersion 
                WHERE Id IN :contentVersions
            ]) {
                versionToDocMap.put(cv.Id, cv.ContentDocumentId);
                System.debug('Mapped ContentVersion ' + cv.Id + ' to Document ' + cv.ContentDocumentId);
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
                System.debug('Created ContentDocumentLink for doc: ' + versionToDocMap.get(versionId));
            }

            insert links;
            System.debug('Linked documents to record: ' + recordId);

            // Optionally update status of related step
            updateWorkStepStatus(recordId, 'CO Execution Detail');

            return 'SUCCESS';

        } catch (Exception e) {
            System.debug('Error saving photos: ' + e.getMessage() + ' at line ' + e.getLineNumber());
            return 'ERROR: ' + e.getMessage();
        }
    }

    public static void handleCustomerNotAvailable(List<WorkOrder> newList, Map<Id, WorkOrder> oldMap) {
    List<Case> casesToCreate = new List<Case>();
    List<Case> casesToUpdate = new List<Case>();
    List<WorkOrder> newWorkOrders = new List<WorkOrder>();

    for (WorkOrder wo : newList) {
        WorkOrder oldWo = oldMap.get(wo.Id);

        // Check if current work order was changed to "Customer Not Available"
        if (wo.Meter_Replacement_Status__c == 'Customer Not Available' &&
            oldWo.Meter_Replacement_Status__c != 'Customer Not Available') {

            // Determine follow-up type based on parent chain
            Boolean isFirstVisit = (wo.ParentWorkOrderId == null);
            Boolean isSecondVisit = (wo.Subject != null && wo.Subject.startsWith('Follow-up Visit 1'));
            Boolean isFinalVisit = (wo.Subject != null && wo.Subject.startsWith('Follow-up Visit 2'));

            if (isFirstVisit) {
                // First Visit — Create case and Follow-up Visit 1
                Case c = new Case();
                c.Origin = 'Field Technician';
                c.Subject = 'Customer Not Available - Work Order: ' + wo.WorkOrderNumber;
                c.Status = 'New';
                c.Work_Order__c = wo.Id;
                c.Description = 'Technician marked customer as unavailable for Work Order ' + wo.WorkOrderNumber;
                c.First_Intimation_Sent_Date__c = Date.today();
                casesToCreate.add(c);

                WorkOrder newWO = new WorkOrder();
                newWO.AccountId = wo.AccountId;
                newWO.Subject = 'Follow-up Visit 1: ' + wo.Subject;
                //newWO.Status = 'Scheduled';
                newWO.Scheduled_Date__c = Date.today().addDays(7);
                newWO.ParentWorkOrderId = wo.Id;
                newWO.OwnerId = wo.OwnerId;
                newWO.Meter_Replacement_Status__c = 'Scheduled';
                newWorkOrders.add(newWO);

            } else if (isSecondVisit) {
                // Second Visit — Create final Follow-up Visit 2
                List<Case> relatedCases = [
                    SELECT Id, Final_Attempt_WorkOrder__c
                    FROM Case
                    WHERE Second_Attempt_Work_Order__c = :wo.Id
                    LIMIT 1
                ];

                if (!relatedCases.isEmpty()) {
                    Case c = relatedCases[0];
                    c.Final_Intimation_Sent_Date__c = Date.today();

                    WorkOrder finalWO = new WorkOrder();
                    finalWO.AccountId = wo.AccountId;
                    finalWO.Subject = 'Follow-up Visit 2 (Final Attempt): ' + wo.Subject;
                    //finalWO.Status = 'Scheduled';
                    finalWO.Scheduled_Date__c = Date.today().addDays(15);
                    finalWO.ParentWorkOrderId = wo.Id;
                    finalWO.OwnerId = wo.OwnerId;
                    finalWO.Meter_Replacement_Status__c = 'Rescheduled';

                    newWorkOrders.add(finalWO);
                    casesToUpdate.add(c);
                }

            } else if (isFinalVisit) {
                // Final Visit – no more follow-ups
                System.debug('Final follow-up reached. No more work orders created.');
            } else {
                // Default/fallback for safety (e.g. if subject doesn't match expected pattern)
                WorkOrder fallbackWO = new WorkOrder();
                fallbackWO.AccountId = wo.AccountId;
                fallbackWO.Subject = 'Follow-up Visit (Unidentified Stage): ' + wo.Subject;
                //fallbackWO.Status = 'Scheduled';
                fallbackWO.Scheduled_Date__c = Date.today().addDays(7);
                fallbackWO.ParentWorkOrderId = wo.Id;
                fallbackWO.OwnerId = wo.OwnerId;
                fallbackWO.Meter_Replacement_Status__c = 'Rescheduled';
                newWorkOrders.add(fallbackWO);
            }
        }
    }

    if (!casesToCreate.isEmpty()) insert casesToCreate;
    if (!newWorkOrders.isEmpty()) insert newWorkOrders;

    // Link final attempt WorkOrder to related Case
    if (!casesToUpdate.isEmpty()) {
        for (Integer i = 0; i < casesToUpdate.size(); i++) {
            casesToUpdate[i].Final_Attempt_WorkOrder__c = newWorkOrders[i + casesToCreate.size()].Id;
        }
        update casesToUpdate;
    }
}



    public static void updateWorkStepStatus(Id workOrderId, String name) {
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
            System.debug('Updated WorkStep status to Completed for step: ' + name);
        } else {
            System.debug('No matching WorkStep found to update for: ' + name);
        }
    }

    public class PhotoWrapper {
        @AuraEnabled public String base64Data { get; set; }
        @AuraEnabled public String fileName { get; set; }
        @AuraEnabled public String label { get; set; }
    }




}