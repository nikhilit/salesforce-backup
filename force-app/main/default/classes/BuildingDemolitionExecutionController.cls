public without sharing class BuildingDemolitionExecutionController {

    // Validate Meter Number
    public class ValidationResult {
    @AuraEnabled public Boolean isValid;
    @AuraEnabled public String message;
}

@AuraEnabled
public static ValidationResult validateMeterApex(Id workOrderId, String meterNumber) {
    ValidationResult result = new ValidationResult();

    WorkOrder wo = [
        SELECT Id, AccountId, Account.Meter_Number__c
        FROM WorkOrder
        WHERE Id = :workOrderId
        LIMIT 1
    ];

    if (wo.Account != null && wo.Account.Meter_Number__c != null) {
        if (wo.Account.Meter_Number__c == meterNumber) {
            result.isValid = true;
            result.message = 'Valid';
        } else {
            result.isValid = false;
            result.message = 'Invalid meter number.';
        }
    } else {
        result.isValid = false;
        result.message = 'No meter number found on related account.';
    }

    return result;
}


    // 🛠 Update Work Order
    @AuraEnabled
public static void updateWorkOrder(
    Id recordId,
    String typeOfWork,
    String loopVerificationStatus,
    String remarks,
    Decimal meterNumber,
    Decimal meterReading,
    Date meterReadingDate,
    Decimal trenchVolume,
    Decimal pipelineLength,
    String lineType,
    String lineTypeLength
) {
    System.debug('🛠 updateWorkOrder called for ID: ' + recordId);

    if (recordId == null) {
        throw new AuraHandledException('Missing Work Order ID. Cannot update record.');
    }

    try {
        WorkOrder woToUpdate = [
            SELECT Id,
                   Type_Of_Work__c,
                   Loop_Verification_Status__c,
                   Remarks__c,
                   Meter_Number__c,
                   Meter_Reading__c,
                   Meter_Reading_Date__c,
                   Volume_of_Trench__c,
                   Length_of_Pipeline__c FROM WorkOrder
            WHERE Id = :recordId
            LIMIT 1
        ];

        // Assign updated values
        woToUpdate.Type_Of_Work__c = typeOfWork;
        woToUpdate.Loop_Verification_Status__c = loopVerificationStatus;
        woToUpdate.Remarks__c = remarks;
        //woToUpdate.Meter_Number__c = meterNumber;
        woToUpdate.Meter_Reading__c = meterReading;
        woToUpdate.Meter_Reading_Date__c = meterReadingDate;
        woToUpdate.Volume_of_Trench__c = String.valueOf(trenchVolume);
        woToUpdate.Length_of_Pipeline__c = String.valueOf(lineTypeLength);

      //  woToUpdate.Type_of_Line_Laid__c = lineType;

        update woToUpdate;

        System.debug('Work Order updated successfully: ' + woToUpdate.Id);

    } catch (Exception ex) {
        System.debug('updateWorkOrder error: ' + ex.getMessage());
        throw new AuraHandledException('Error updating Work Order: ' + ex.getMessage());
    }
}


    // Save Material Details
    @AuraEnabled
    public static void saveMaterialDetails(Id workOrderId, List<MaterialWrapper> materialList) {
        System.debug('saveMaterialDetails STARTED');
        System.debug('WorkOrderId: ' + workOrderId);
        System.debug('Received material list: ' + JSON.serializePretty(materialList));

        List<Material_Consumption__c> toInsert = new List<Material_Consumption__c>();

        for (MaterialWrapper wrapper : materialList) {
            System.debug('Processing material: ' + JSON.serialize(wrapper));

            Material_Consumption__c record = new Material_Consumption__c(
                Work_Order__c = workOrderId,
                Item_Description__c = wrapper.itemDescription,
                Unit__c = wrapper.unit,
                Quantity__c = wrapper.quantity
            );
            toInsert.add(record);
        }

        if (!toInsert.isEmpty()) {
            insert toInsert;
            System.debug('Inserted Material_Consumption__c records: ' + toInsert);
        } else {
            System.debug('No material records to insert.');
        }
    }

    public class MaterialWrapper {
        @AuraEnabled public String itemCode;
        @AuraEnabled public String itemDescription { get; set; }
        @AuraEnabled public String unit { get; set; }
        @AuraEnabled public Integer quantity { get; set; }
    }

    // Get Item Description Options
    @AuraEnabled
    public static List<String> getItemDescriptionOptions() {
        System.debug('getItemDescriptionOptions CALLED');

        List<String> options = new List<String>();
        Schema.DescribeFieldResult fieldResult = Material_Consumption__c.Item_Description__c.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();

        for (Schema.PicklistEntry pe : picklistValues) {
            options.add(pe.getValue());
        }

        System.debug('Returning picklist options: ' + options);
        return options;
    }

    // Save Photo Uploads
    @AuraEnabled
    public static String savePhotoUploads(Id recordId, List<PhotoWrapper> listFiles) {
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

    public class PhotoWrapper {
        @AuraEnabled public String base64Data { get; set; }
        @AuraEnabled public String fileName { get; set; }
        @AuraEnabled public String label { get; set; }
        
    }

    // Update Work Step Status
    public static void updateWorkStepStatus(Id workOrderId, String name) {
        System.debug('updateWorkStepStatus CALLED for WO: ' + workOrderId + ', stepName: ' + name);

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
            System.debug('WorkStep status updated to Completed');
        } else {
            System.debug('No WorkStep found for update');
        }
    }
}