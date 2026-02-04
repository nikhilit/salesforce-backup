public with sharing class RiserPaintingFormController {

    @AuraEnabled(cacheable=true)
public static List<Form__c> getForms(Id appointmentId, Integer riserIndex) {
    System.debug('Fetching forms for AppointmentId: ' + appointmentId + ', RiserIndex: ' + riserIndex);

    Decimal riserDecimal = Decimal.valueOf(riserIndex);

    return [
        SELECT Id, Response__c, Riser_Index__c,
               Form_Master__r.Question_Label__c,
               Form_Master__r.Data_Type__c
        FROM Form__c
        WHERE Service_Appointment__c = :appointmentId
        AND Riser_Index__c = :riserDecimal
        ORDER BY CreatedDate
    ];
}



    @AuraEnabled(cacheable=true)
    public static Id getServiceAppointmentId(Id workOrderId) {
        System.debug('Fetching Service Appointment for WorkOrderId: ' + workOrderId);

        if (String.isBlank(workOrderId)) {
            throw new AuraHandledException('Work Order ID is required');
        }

        List<ServiceAppointment> saList = [
            SELECT Id FROM ServiceAppointment WHERE ParentRecordId = :workOrderId LIMIT 1
        ];

        if (saList.isEmpty()) {
            throw new AuraHandledException('No Service Appointment found for this Work Order.');
        }

        System.debug('Found ServiceAppointment Id: ' + saList[0].Id);
        return saList[0].Id;
    }

    @AuraEnabled
    public static void saveForms(List<Form__c> forms) {
        System.debug('Saving Form responses: ' + forms);

        if (forms == null || forms.isEmpty()) {
            System.debug('No forms to save.');
            return;
        }

        try {
            update forms;
            System.debug('Forms updated successfully');
        } catch (Exception e) {
            System.debug('Error while updating forms: ' + e.getMessage());
            throw new AuraHandledException('Error saving form responses: ' + e.getMessage());
        }
    }

    public static void createFormsForRisers(Id serviceAppointmentId, Integer totalRisers) {
        System.debug('Creating forms for ServiceAppointmentId: ' + serviceAppointmentId + ' with total risers: ' + totalRisers);

        List<Form_Master__c> masters = [
            SELECT Id, Question_Label__c, Data_Type__c 
            FROM Form_Master__c 
            WHERE Type__c = 'Riser Painting Details'
        ];
        System.debug('Master forms count: ' + masters.size());

        List<Form__c> formsToInsert = new List<Form__c>();

        for (Integer i = 1; i <= totalRisers; i++) {
            Integer existingCount = [
                SELECT count() 
                FROM Form__c 
                WHERE Service_Appointment__c = :serviceAppointmentId 
                AND Riser_Index__c = :i
            ];
            System.debug('Existing form count for riser ' + i + ': ' + existingCount);

            if (existingCount > 0) {
                continue;
            }

            for (Form_Master__c fm : masters) {
                formsToInsert.add(new Form__c(
                    Service_Appointment__c = serviceAppointmentId,
                    Form_Master__c = fm.Id,
                    Riser_Index__c = i
                ));
            }
        }

        if (!formsToInsert.isEmpty()) {
            insert formsToInsert;
            System.debug('Inserted forms count: ' + formsToInsert.size());
        } else {
            System.debug('No new forms to insert.');
        }
    }

    @AuraEnabled
    public static String setupRiserForms(Id workOrderId, Integer totalRisers) {
        System.debug('Setting up riser forms for WorkOrderId: ' + workOrderId + ' with totalRisers: ' + totalRisers);

        if (totalRisers == null || totalRisers <= 0) {
            System.debug('Invalid riser count');
            return 'InvalidRiserCount';
        }

        ServiceAppointment sa = [
            SELECT Id FROM ServiceAppointment
            WHERE ParentRecordId = :workOrderId
            LIMIT 1
        ];
        System.debug('Service Appointment for setup: ' + sa.Id);

        List<Form_Master__c> masterForms = [
            SELECT Id FROM Form_Master__c
            WHERE Type__c = 'Riser Painting Details'
        ];
        System.debug('Form Master template count: ' + masterForms.size());

        Map<Integer, List<Form__c>> existingFormsByIndex = new Map<Integer, List<Form__c>>();
        for (Form__c form : [
    SELECT Id, Riser_Index__c
    FROM Form__c
    WHERE Service_Appointment__c = :sa.Id
]) {
    Integer index = (Integer) form.Riser_Index__c;
    if (!existingFormsByIndex.containsKey(index)) {
        existingFormsByIndex.put(index, new List<Form__c>());
    }
    existingFormsByIndex.get(index).add(form);
}

        System.debug('Existing forms by riser index: ' + existingFormsByIndex.keySet());

        List<Form__c> formsToInsert = new List<Form__c>();
        for (Integer i = 1; i <= totalRisers; i++) {
            Integer existingFormCount = existingFormsByIndex.containsKey(i) ? existingFormsByIndex.get(i).size() : 0;

if (existingFormCount >= masterForms.size()) {
    // All required forms already exist for this riser
    continue;
}

            for (Form_Master__c master : masterForms) {
                formsToInsert.add(new Form__c(
                    Service_Appointment__c = sa.Id,
                    Form_Master__c = master.Id,
                    Riser_Index__c = i
                ));
            }
        }

        if (!formsToInsert.isEmpty()) {
            insert formsToInsert;
            System.debug('Inserted new form records for risers.');
            return 'Created';
        } else {
            System.debug('All forms already exist for this Work Order.');
            return 'AlreadyExists';
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
            updateWorkStepStatus(recordId, 'Work Order Execution Detail');

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
}