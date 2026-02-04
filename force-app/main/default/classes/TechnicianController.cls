public with sharing class TechnicianController {

   
    @AuraEnabled
public static void updateMeterStatus(Id recordId, String status, String beforeReading, String afterReading, String reason, String meterNumber, String isMeterAvailable, String isUsingGas) {
    System.debug('updateMeterStatus Triggered');

    try {
        // Step 1: Get ServiceAppointment
        List<ServiceAppointment> saList = [
            SELECT Id, ParentRecordId
            FROM ServiceAppointment
            WHERE ParentRecordId = :recordId
            LIMIT 1
        ];
        
        if (saList.isEmpty()) {
            throw new AuraHandledException('No related ServiceAppointment found for Work Order ID: ' + recordId);
        }

        ServiceAppointment sa = saList[0];

        // Step 2: Get WorkOrder
        WorkOrder originalWO = [
            SELECT Id, Subject, CaseId, AccountId, Agent__c
            FROM WorkOrder
            WHERE Id = :sa.ParentRecordId
            LIMIT 1
        ];

        originalWO.Is_Meter_Available__c = isMeterAvailable;
        originalWO.Is_Customer_Using_Gas__c = isUsingGas;
        originalWO.Abnormal_Reading_Reason__c = reason;
        // Update meter status
        originalWO.Meter_Status__c = status;
        try {
    originalWO.Before_Meter_Reading__c = Decimal.valueOf(beforeReading);
    originalWO.After_Meter_Reading__c = Decimal.valueOf(afterReading);
} catch (Exception e) {
    // handle invalid input, e.g., log error or set default
    System.debug('Invalid meter reading input: ' + beforeReading);
}
        Decimal meterNumberDecimal;

try {
    meterNumberDecimal = Decimal.valueOf(meterNumber);
} catch (Exception e) {
    throw new AuraHandledException('Invalid Meter Number format. Please enter a valid number.');
}

originalWO.Meter_Number__c = meterNumberDecimal;

        update originalWO;

        // Step 3: If meter is Not Okay/Faulty, create new WorkOrder and ServiceAppointment
        if (status == 'Not Okay/Faulty') {
            WorkOrder replacementWO = new WorkOrder(
                Subject = 'Meter Replacement - Auto Created',
                CaseId = originalWO.CaseId,
                AccountId = originalWO.AccountId,
                ParentWorkOrderId = originalWO.Id,
                Agent__c = originalWO.Agent__c
            );
            insert replacementWO;

            ServiceAppointment newSA = new ServiceAppointment(
                ParentRecordId = replacementWO.Id,
                Status = 'New',
                Subject = 'Meter Replacement Visit'
            );
            insert newSA;
        }

    } catch (Exception e) {
        System.debug('Error in updateMeterStatus: ' + e.getMessage());
        throw new AuraHandledException('Meter update failed: ' + e.getMessage());
    }
}




@AuraEnabled
    public static String uploadPhotosToWorkOrder(Id recordId, List<PhotoWrapper> listFiles) {
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

    public class PhotoWrapper {
        @AuraEnabled public String base64Data { get; set; }
        @AuraEnabled public String fileName { get; set; }
        @AuraEnabled public String label { get; set; }
    }


@AuraEnabled
public static String uploadPhotosToWorkOrderMeter(Id recordId, List<PhotoWrapper> listFiles) {
    System.debug('Starting savePhotoUploads for Record Id: in uploadPhotosToWorkOrderMeter' + recordId);
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

@AuraEnabled
public static String uploadPhotosToGas(Id recordId, List<PhotoWrapper> listFiles) {
    System.debug('Starting savePhotoUploads for Record Id: in uploadPhotosToGas' + recordId);
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

public static void updateWorkStepStatus(Id workOrderId, String name) {
        System.debug('🛠️ [updateWorkStepStatus] Updating status for: ' + name + ' under WorkOrder: ' + workOrderId);

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
            System.debug('✅ [updateWorkStepStatus] WorkStep marked as Completed: ' + ws.Id);
        } else {
            System.debug('⚠️ [updateWorkStepStatus] No matching WorkStep found for update.');
        }
    }




    // public class FileWrapper {
    //     @AuraEnabled public String base64Data { get; set; }
    //     @AuraEnabled public String fileName { get; set; }
    //     @AuraEnabled public String label { get; set; }
    //     @AuraEnabled public Double latitude { get; set; }
    //     @AuraEnabled public Double longitude { get; set; }
    //     @AuraEnabled public Datetime capturedTime { get; set; }
    // }


}