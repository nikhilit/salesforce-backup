public class RHNotDoneController {

    
@AuraEnabled
public static void saveRHNotDoneDetails(Id recordId, String payload) {
    try {
        Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(payload);

        List<ServiceAppointment> saList = [
            SELECT Id, ParentRecordId, Status 
            FROM ServiceAppointment 
            WHERE ParentRecordId = :recordId 
            LIMIT 1
        ];

        if (saList.isEmpty()) {
            throw new AuraHandledException('No ServiceAppointment found for WorkOrder Id: ' + recordId);
        }

        // ServiceAppointment sa = saList[0];
        // sa.Status = 'Customer Not Available';
        // update sa;

        WorkOrder wo = [
            SELECT Id,
                   RH_Cancellation_Reason__c,
                   Follow_up_Remarks__c,
                   RH_Location__latitude__s,
                   RH_Location__longitude__s,
                   Follow_up_Date__c
            FROM WorkOrder 
            WHERE Id = :recordId 
            LIMIT 1
        ];

        if (wo == null) {
            throw new AuraHandledException('No WorkOrder found with Id: ' + recordId);
        }

        wo.RH_Cancellation_Reason__c     = (String) data.get('reason');
        wo.Follow_up_Remarks__c          = (String) data.get('remarks');
        wo.Follow_up_Date__c             = Date.valueOf((String) data.get('followUpDate'));
        wo.RH_Location__latitude__s      = (Decimal) data.get('latitude');
        wo.RH_Location__longitude__s     = (Decimal) data.get('longitude');

        update wo;
    } catch (Exception e) {
        System.debug('RHNotDoneController error: ' + e.getMessage());
        throw new AuraHandledException('Apex Error: ' + e.getMessage());
    }
}



    // Upload photos and link them to Work Order
    @AuraEnabled
    public static String savePhotoUploads(Id recordId, List<PhotoWrapper> listFiles) {
        System.debug('savePhotoUploads started for: ' + recordId);
        System.debug('Files to upload: ' + JSON.serializePretty(listFiles));

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
                System.debug('No valid files to insert.');
                return 'No valid files to upload.';
            }

            insert contentVersions;
            System.debug('Inserted ContentVersions.');

            // Map inserted ContentVersion Ids to ContentDocumentIds
            Map<Id, Id> versionToDocMap = new Map<Id, Id>();
            for (ContentVersion cv : [
                SELECT Id, ContentDocumentId 
                FROM ContentVersion 
                WHERE Id IN :contentVersions
            ]) {
                versionToDocMap.put(cv.Id, cv.ContentDocumentId);
            }

            // Link each ContentDocument to the Work Order
            List<ContentDocumentLink> links = new List<ContentDocumentLink>();
            for (Id versionId : versionToDocMap.keySet()) {
                ContentDocumentLink link = new ContentDocumentLink(
                    ContentDocumentId = versionToDocMap.get(versionId),
                    LinkedEntityId = recordId,
                    ShareType = 'V',
                    Visibility = 'AllUsers'
                );
                links.add(link);
            }

            insert links;
            System.debug('Files linked to Work Order: ' + recordId);

            // Optional: Update related WorkStep
            updateWorkStepStatus(recordId, 'CO Execution Detail');

            return 'SUCCESS';

        } catch (Exception e) {
            System.debug('Error saving photos: ' + e.getMessage() + ' (line ' + e.getLineNumber() + ')');
            return 'ERROR: ' + e.getMessage();
        }
    }

    // Optional: Mark a specific WorkStep as completed
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

            System.debug('WorkStep marked Completed: ' + ws.Id);
        } else {
            System.debug('No matching WorkStep found with name: ' + name);
        }
    }

    // Wrapper class for photo metadata
    public class PhotoWrapper {
    @AuraEnabled public String base64Data { get; set; }
    @AuraEnabled public String fileName { get; set; }
    @AuraEnabled public String label { get; set; }
}

}