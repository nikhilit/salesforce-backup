public class TPEController {

    @AuraEnabled
public static void markAsUnsuccessful(Id workOrderId, String reason, String reasonDetails) {
    System.debug('✅ Apex method markAsUnsuccessful() STARTED');

    System.debug('markAsUnsuccessful started with WorkOrderId: ' + workOrderId + ', reason: ' + reason + ', reasonDetails: ' + reasonDetails);

    if (String.isBlank(reason)) {
        throw new AuraHandledException('Please select a reason.');
    }

    List<ServiceAppointment> saList = [
        SELECT Id, Status 
        FROM ServiceAppointment 
        WHERE ParentRecordId = :workOrderId 
        LIMIT 1
    ];

    System.debug('SA Id: ' + saList[0].Id + ', Status: ' + saList[0].Status);


    System.debug('Total SA found: ' + saList.size());


    if (saList.isEmpty()) {
        throw new AuraHandledException('No Service Appointment found for this Work Order.');
    }

    ServiceAppointment sa = saList[0];
    //sa.Status = 'Unsuccessful';
    sa.Unsuccessful_Reason_Riser_Replacement_Te__c = reason;
    sa.Unsuccessful_Reason_Details_riser_repl__c = reason == 'Other' ? reasonDetails : null;

    try {
    if (String.isBlank(sa.Status)) {
        sa.Status = 'Unsuccessful'; // fallback
    }

    update sa;
    System.debug('✅ SA updated successfully');
} catch (Exception e) {
    System.debug('❌ Exception while updating SA: ' + e.getMessage());
    throw new AuraHandledException('Update failed: ' + e.getMessage());
}


if (String.isNotBlank(sa.Status)) {
    sa.Status = 'Unsuccessful';
}

}


    @AuraEnabled(cacheable=true)
    public static List<String> getUnsuccessfulReasons() {
        System.debug('getUnsuccessfulReasons called');

        List<String> reasons = new List<String>();

        try {
            Schema.DescribeFieldResult fieldResult = ServiceAppointment.Unsuccessful_Reason_Riser_Replacement__c.getDescribe();
            for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
                reasons.add(entry.getLabel());
                System.debug('Found picklist value: ' + entry.getLabel());
            }
        } catch (Exception e) {
            System.debug('Error fetching picklist values: ' + e.getMessage());
            throw new AuraHandledException('Failed to fetch reason picklist values.');
        }

        return reasons;
    }

    @AuraEnabled
    public static String savePhotoUploads(Id recordId, List<PhotoWrapper> listFiles) {
        System.debug('savePhotoUploads START for Record Id: ' + recordId);
        System.debug('Received Files: ' + JSON.serializePretty(listFiles));

        try {
            List<ContentVersion> contentVersions = new List<ContentVersion>();

            for (PhotoWrapper file : listFiles) {
                System.debug('Processing file: ' + file.label);

                if (String.isNotBlank(file.base64Data) && String.isNotBlank(file.fileName)) {
                    ContentVersion cv = new ContentVersion();
                    cv.Title = file.label;
                    cv.PathOnClient = '/' + file.fileName;
                    cv.VersionData = EncodingUtil.base64Decode(file.base64Data);
                    contentVersions.add(cv);
                    System.debug('Added ContentVersion for: ' + file.label);
                } else {
                    System.debug('Skipping file due to missing data or filename: ' + file.label);
                }
            }

            if (contentVersions.isEmpty()) {
                System.debug('No valid files to insert.');
                return 'No valid files to upload.';
            }

            insert contentVersions;
            System.debug('Inserted ContentVersions: ' + contentVersions);

            Map<Id, Id> versionToDocMap = new Map<Id, Id>();
            for (ContentVersion cv : [
                SELECT Id, ContentDocumentId 
                FROM ContentVersion 
                WHERE Id IN :contentVersions
            ]) {
                versionToDocMap.put(cv.Id, cv.ContentDocumentId);
                System.debug('Mapped ContentVersion ' + cv.Id + ' to Document ' + cv.ContentDocumentId);
            }

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

            updateWorkStepStatus(recordId, 'CO Execution Detail');

            return 'SUCCESS';
        } catch (Exception e) {
            System.debug('Exception while saving photos: ' + e.getMessage() + ' at line ' + e.getLineNumber());
            return 'ERROR: ' + e.getMessage();
        }
    }

    public static void updateWorkStepStatus(Id workOrderId, String name) {
    System.debug('updateWorkStepStatus START for WorkOrder: ' + workOrderId + ', Step: ' + name);

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
                System.debug('Skipping update: WorkStep.Status is currently null, may violate validation rule');
                return; // Don't update if Status is null to avoid validation error
            }

            // Optional: Add check for valid status transitions if needed
            ws.Status = 'Completed';
            update ws;
            System.debug('Updated WorkStep to Completed: ' + ws.Id);
        } else {
            System.debug('No matching WorkStep found to update.');
        }
    } catch (Exception e) {
        System.debug('Exception in updateWorkStepStatus: ' + e.getMessage());
    }
}



    public class PhotoWrapper {
        @AuraEnabled public String base64Data { get; set; }
        @AuraEnabled public String fileName { get; set; }
        @AuraEnabled public String label { get; set; }
    }
}