public without sharing class CaseFileController {
    
    public class FileWrapper {
        @AuraEnabled public String title;
        @AuraEnabled public String fileType;
        @AuraEnabled public String uploadedBy;
        @AuraEnabled public String uploadDate;
        @AuraEnabled public String contentVersionId;
        @AuraEnabled public String remarks;
        @AuraEnabled public String status;
        @AuraEnabled public String typeofdoc;
        @AuraEnabled public String reason;
        @AuraEnabled public String selectedDocs;

        public FileWrapper(String title, String fileType, String uploadedBy, String uploadDate,
                           String contentVersionId, String remarks, String status, String typeofdoc, String reason, String selectedDocs) {
            this.title = title;
            this.fileType = fileType;
            this.uploadedBy = uploadedBy;
            this.uploadDate = uploadDate;
            this.contentVersionId = contentVersionId;
            this.remarks = remarks;
            this.status = status;
            this.typeofdoc = typeofdoc;
            this.reason = reason;
            this.selectedDocs = selectedDocs;
        }
    }

    @AuraEnabled
    public static List<FileWrapper> getFilesForCase(Id caseId) {
        List<FileWrapper> fileList = new List<FileWrapper>();

        // Step 1: Get files linked directly to the Case
        List<ContentDocumentLink> caseLinks = [
            SELECT ContentDocumentId,
                   ContentDocument.Title,
                   ContentDocument.FileType,
                   ContentDocument.CreatedBy.Name,
                   ContentDocument.CreatedDate,
                   ContentDocument.LatestPublishedVersion.Id,
                   ContentDocument.LatestPublishedVersion.Remarks__c,
                   ContentDocument.LatestPublishedVersion.Status__c,
                   ContentDocument.LatestPublishedVersion.Type_Of_Document__c,
                   ContentDocument.LatestPublishedVersion.Reason_for_Rejection__c,
                   ContentDocument.LatestPublishedVersion.Selected_Document_Names__c
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :caseId
        ];

        // Step 2: Get EmailMessages related to this Case
        List<Id> emailMessageIds = new List<Id>();
        for (EmailMessage em : [
            SELECT Id 
            FROM EmailMessage 
            WHERE ParentId = :caseId
        ]) {
            emailMessageIds.add(em.Id);
        }

        // Step 3: Get files linked to those EmailMessages
        List<ContentDocumentLink> emailLinks = new List<ContentDocumentLink>();
        if (!emailMessageIds.isEmpty()) {
            emailLinks = [
                SELECT ContentDocumentId,
                       ContentDocument.Title,
                       ContentDocument.FileType,
                       ContentDocument.CreatedBy.Name,
                       ContentDocument.CreatedDate,
                       ContentDocument.LatestPublishedVersion.Id,
                       ContentDocument.LatestPublishedVersion.Remarks__c,
                       ContentDocument.LatestPublishedVersion.Status__c,
                       ContentDocument.LatestPublishedVersion.Type_Of_Document__c,
                       ContentDocument.LatestPublishedVersion.Reason_for_Rejection__c,
                       ContentDocument.LatestPublishedVersion.Selected_Document_Names__c
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :emailMessageIds
            ];
        }

        // Step 4: Merge both lists
        List<ContentDocumentLink> allLinks = new List<ContentDocumentLink>();
        allLinks.addAll(caseLinks);
        allLinks.addAll(emailLinks);

        // Step 5: Build FileWrapper list
        for (ContentDocumentLink link : allLinks) {
            fileList.add(new FileWrapper(
                link.ContentDocument.Title,
                link.ContentDocument.FileType,
                link.ContentDocument.CreatedBy.Name,
                String.valueOf(link.ContentDocument.CreatedDate),
                link.ContentDocument.LatestPublishedVersion.Id,
                link.ContentDocument.LatestPublishedVersion.Remarks__c,
                link.ContentDocument.LatestPublishedVersion.Status__c,
                link.ContentDocument.LatestPublishedVersion.Type_Of_Document__c,
                link.ContentDocument.LatestPublishedVersion.Reason_for_Rejection__c,
                link.ContentDocument.LatestPublishedVersion.Selected_Document_Names__c
            ));
        }

        return fileList;
    }

    @AuraEnabled
    public static void updateFileFields(
        String contentVersionId,
        String status,
        String reason,
        String docType,
        String comment,
        String selectedNamesCSV
    ) {
        // Query all necessary fields in one go
        ContentVersion cv = [
            SELECT Id, 
                   Status__c, 
                   Reason_for_Rejection__c, 
                   Type_Of_Document__c, 
                   Remarks__c,
                   Selected_Document_Names__c
            FROM ContentVersion 
            WHERE Id = :contentVersionId 
            LIMIT 1
        ];
        System.debug('selectedNamesCSV'+selectedNamesCSV);

        Boolean isUpdated = false;

        if (String.isNotBlank(status)) {
            cv.Status__c = status;
            isUpdated = true;
        }

        if (String.isNotBlank(reason)) {
            cv.Reason_for_Rejection__c = reason;
            isUpdated = true;
        }

        if (String.isNotBlank(docType)) {
            cv.Type_Of_Document__c = docType;
            isUpdated = true;
        }

        if (String.isNotBlank(comment)) {
            cv.Remarks__c = comment;
            isUpdated = true;
        }
        cv.Selected_Document_Names__c = selectedNamesCSV;
        if (isUpdated) {
            update cv;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getTypeOfDocumentOptions() {
        List<String> values = new List<String>();
        Schema.DescribeFieldResult fieldResult = ContentVersion.Type_Of_Document__c.getDescribe();
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            if (entry.isActive()) {
                values.add(entry.getLabel());
            }
        }
        return values;
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getStatusOptions() {
        List<String> values = new List<String>();
        Schema.DescribeFieldResult fieldResult = ContentVersion.Status__c.getDescribe();
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            if (entry.isActive()) {
                values.add(entry.getLabel());
            }
        }
        return values;
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getReasonOptions() {
        List<String> values = new List<String>();
        Schema.DescribeFieldResult fieldResult = ContentVersion.Reason_for_Rejection__c.getDescribe();
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            if (entry.isActive()) {
                values.add(entry.getLabel());
            }
        }
        return values;
    }

    @AuraEnabled(cacheable=true)
    public static String getTransferTypeFromCase(Id caseId) {
        if (String.isBlank(caseId)) {
            throw new AuraHandledException('Case Id is required');
        }

        Case caseRecord = [
            SELECT Transfer_Type__c
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];

        return caseRecord.Transfer_Type__c;
    }

    // SIMPLE VALIDATION METHOD: Check if required fields are filled
    @AuraEnabled
    public static String validateCaseForApproval(String caseId) {
        try {
            Case caseRecord = [
                SELECT Id, New_Salutation__c, New_First_Name__c, 
                       New_Middle_Name__c, New_Last_Name__c, New_Contact__c
                FROM Case 
                WHERE Id = :caseId
                LIMIT 1
            ];
            
            // Check if all required fields are filled
            if (String.isBlank(caseRecord.New_Salutation__c) ||
                String.isBlank(caseRecord.New_First_Name__c) ||
                String.isBlank(caseRecord.New_Last_Name__c) ||
                String.isBlank(caseRecord.New_Contact__c)) {
                
                return 'Cannot approve Case: All name fields (Salutation, First Name, Last Name) and Contact must be filled before approval.';
            }
            
            return 'SUCCESS'; // All fields are filled
            
        } catch (Exception e) {
            throw new AuraHandledException('Error validating case: ' + e.getMessage());
        }
    }

    // SIMPLE APPROVAL METHOD: Only approve if validation passes
    @AuraEnabled
    public static String approveCase(String caseId) {
        try {
            // First validate
            String validationResult = validateCaseForApproval(caseId);
            
            if (validationResult != 'SUCCESS') {
                return validationResult; // Return error message
            }
            
            // If validation passes, update status to Approved
            Case caseToApprove = new Case(
                Id = caseId, 
                Name_Transfer_Request_Status__c = 'Approved'
            );
            update caseToApprove;
            
            return 'SUCCESS'; // Approval successful
            
        } catch (Exception e) {
            throw new AuraHandledException('Error approving case: ' + e.getMessage());
        }
    }
}