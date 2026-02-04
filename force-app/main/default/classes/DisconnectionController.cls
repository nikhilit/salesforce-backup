public without sharing class DisconnectionController {
    
    @AuraEnabled
    public static Map<String, Double> getGeolocation() {
        // Dummy, front-end fetches actual location; return placeholder
        return new Map<String, Double>{ 'latitude' => 12.9716, 'longitude' => 77.5946 };
    }

    @AuraEnabled
public static void saveVisitDetails(Id workOrderId, String status, String reason, String remarks, Double latitude, Double longitude,Decimal outstandingAmount,String reasonOtherRemark,String billPaid,Decimal meterReading,
    Decimal meterNumber) {
    System.debug('⚙️ saveVisitDetails START');
    System.debug('▶ workOrderId: ' + workOrderId);
    System.debug('▶ status: ' + status);
    System.debug('▶ reason: ' + reason);
    System.debug('▶ remarks: ' + remarks);
    System.debug('▶ latitude: ' + latitude);
    System.debug('▶ longitude: ' + longitude);

    try {
        ServiceAppointment sa = [
            SELECT Id, Status 
            FROM ServiceAppointment 
            WHERE ParentRecordId = :workOrderId 
            LIMIT 1
        ];

        System.debug('✅ Found ServiceAppointment: ' + sa.Id);

        String currentStatus = sa.Status != null ? sa.Status.trim() : null;
        System.debug('💬 SA Status Before Decision (normalized): "' + currentStatus + '"');

        // Step 1: If status is not yet "In Progress", update to it
        if (currentStatus == null || currentStatus == 'None' || currentStatus == 'Dispatched') {
            System.debug('⚙️ Inside status intermediate update block');
            sa.Status = 'In Progress';
            update sa;
            System.debug('🔁 Intermediate status updated to In Progress');

            sa = [
                SELECT Id, Status,If_bill_paid__c 
                FROM ServiceAppointment 
                WHERE Id = :sa.Id
            ];
        } else {
            System.debug('🚫 Skipping intermediate status update. Current Status: "' + currentStatus + '"');
        }

        // 🚫 Don't attempt to change final status – just update extra fields
        sa.Follow_up_Remarks__c = remarks;
        sa.Reason_For_Not_Disconnecting__c = reason;
        sa.Location__latitude__s = latitude;
        sa.Location__longitude__s = longitude;
        sa.If_bill_paid__c = billPaid;
        sa.Check_In_Time__c = System.now();

        update sa;
        System.debug('✅ Additional SA fields updated while keeping Status = "In Progress"');

        WorkOrder wo = [SELECT Id, Outstanding_Amount__c, Remarks__c FROM WorkOrder WHERE Id = :workOrderId LIMIT 1];
        wo.Outstanding_Amount__c = outstandingAmount;
        wo.Remarks__c = reasonOtherRemark;
        wo.Meter_Reading__c = meterReading;
        wo.Meter_Number__c = meterNumber;
        update wo;

    } catch (Exception ex) {
        System.debug('❌ Error in saveVisitDetails: ' + ex.getMessage());
        throw new AuraHandledException('Failed to Save Details: ' + ex.getMessage());
    }

    System.debug('⚙️ saveVisitDetails END');
}

@AuraEnabled(cacheable=true)
public static List<String> getBillPaidPicklistValues() {
    List<String> values = new List<String>();
    Schema.DescribeFieldResult fieldResult = ServiceAppointment.If_bill_paid__c.getDescribe();
    for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
        values.add(entry.getValue());
    }
    return values;
}


    @AuraEnabled
    public static String savePhotoUploadsBeforeWork(Id recordId, List<PhotoWrapper> listFiles) {
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

    @AuraEnabled
    public static String savePhotoUploadsMeterCounter(Id recordId, List<PhotoWrapper> listFiles) {
    try {
        List<ContentVersion> versionsToInsert = new List<ContentVersion>();

        for (PhotoWrapper file : listFiles) {
            if (file.base64Data != null && file.fileName != null) {
                ContentVersion cv = new ContentVersion();
                cv.VersionData = EncodingUtil.base64Decode(file.base64Data);
                cv.PathOnClient = '/' + file.fileName;
                cv.Title = file.fileName;
                cv.Description = file.label;
                versionsToInsert.add(cv);
            }
        }

        insert versionsToInsert;

        List<ContentDocumentLink> linksToInsert = new List<ContentDocumentLink>();
        for (ContentVersion cv : [SELECT ContentDocumentId FROM ContentVersion WHERE Id IN :versionsToInsert]) {
            linksToInsert.add(new ContentDocumentLink(
                LinkedEntityId = recordId,
                ContentDocumentId = cv.ContentDocumentId,
                ShareType = 'V'
            ));
        }

        insert linksToInsert;

        updateWorkStepStatus(recordId, 'Data Capture Details');

        return 'SUCCESS';
    } catch (Exception e) {
        return 'ERROR: ' + e.getMessage();
    }
}


    @AuraEnabled
    public static String savePhotoUploadsProof(Id recordId, List<PhotoWrapper> listFiles) {
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

            updateWorkStepStatus(recordId, 'Data Capture Details');

            return 'SUCCESS';
        } catch (Exception e) {
            return 'ERROR: ' + e.getMessage();
        }
    }

    @AuraEnabled
    public static String savePhotoUploadsAfterWork(Id recordId, List<PhotoWrapper> listFiles) {
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