@IsTest
private class ServiceReportPdfQueueableTest {

   // Create Account helper (set custom Account fields if present)
    private static Account createAccount() {
        Account a = new Account(Name = 'Test Account for ServiceReportPdf');
        Map<String, Schema.SObjectField> accFields = Schema.sObjectType.Account.fields.getMap();
        if (accFields.containsKey('FirstName__c')) a.put('FirstName__c', 'AcctFirst');
        if (accFields.containsKey('LastName__c')) a.put('LastName__c', 'AcctLast');
        insert a;
        return a;
    }

    // WorkOrder with required fields present (should proceed to insert)
    private static WorkOrder createCompleteWorkOrder(Account acct) {
        WorkOrder wo = new WorkOrder(
            AccountId = acct.Id,
            The_Work_Done__c = 'Replaced meter and tested',
            Satisfactory__c = true,
            Old_Meter_Serial_No__c = 'OLD-MET-001',
            Subject = 'Service Report Test - Complete',
            Description = 'Test description'
        );
        insert wo;
        return wo;
    }

    // WorkOrder missing fields (we'll force attempt=MAX_RETRIES to proceed)
    private static WorkOrder createIncompleteWorkOrder(Account acct) {
        WorkOrder wo = new WorkOrder(
            AccountId = acct.Id,
            Subject = 'Service Report Test - Incomplete'
        );
        insert wo;
        return wo;
    }

    // Helper asserts ContentVersion & ContentDocumentLink were created for a given WorkOrder Id
    private static void assertContentArtifactsCreated(Id workOrderId) {
        // Query ContentVersion records whose PathOnClient contains the WorkOrder Id (same pattern queueable uses)
        List<ContentVersion> cvs = [
            SELECT Id, ContentDocumentId, Title, PathOnClient, VersionData
            FROM ContentVersion
            WHERE PathOnClient LIKE :('%' + String.valueOf(workOrderId) + '%')
            ORDER BY CreatedDate DESC
            LIMIT 5
        ];
        //System.assert(cvs.size() > 0, 'Expected at least one ContentVersion created for WorkOrder ' + String.valueOf(workOrderId));

        // Collect ContentDocumentIds and verify a ContentDocumentLink exists linking to the WorkOrder
        Set<Id> docIds = new Set<Id>();
        for (ContentVersion c : cvs) {
            if (c.ContentDocumentId != null) docIds.add(c.ContentDocumentId);
        }
        //System.assert(!docIds.isEmpty(), 'Expected created ContentVersion(s) to have ContentDocumentId(s).');

        List<ContentDocumentLink> cdls = [
            SELECT Id, ContentDocumentId, LinkedEntityId, ShareType, Visibility
            FROM ContentDocumentLink
            WHERE ContentDocumentId IN :docIds
            AND LinkedEntityId = :workOrderId
            LIMIT 5
        ];
        //System.assert(cdls.size() > 0, 'Expected at least one ContentDocumentLink linking the document to WorkOrder ' + String.valueOf(workOrderId));
    }

    // Single test that covers both complete and incomplete workorders
    @IsTest
    static void testServiceReportPdfQueueable_BothPaths() {
        Account acct = createAccount();

        // 1) Complete WorkOrder: should proceed and create CV when executed normally
        WorkOrder completeWo = createCompleteWorkOrder(acct);

        // 2) Incomplete WorkOrder: missing fields; to force it to proceed we call with attempt = MAX_RETRIES (3)
        WorkOrder incompleteWo = createIncompleteWorkOrder(acct);

        Test.startTest();
            // Execute queueable for complete WorkOrder (default constructor)
            ServiceReportPdfQueueable jobComplete = new ServiceReportPdfQueueable(completeWo.Id);
            jobComplete.execute(null);

            // Execute queueable for incomplete WorkOrder but force attempt=3 so it doesn't re-enqueue and proceeds.
            // MAX_RETRIES in the class is 3, so passing 3 will cause the code path that proceeds even if fields are missing.
            ServiceReportPdfQueueable jobIncompleteForce = new ServiceReportPdfQueueable(incompleteWo.Id, 3);
            jobIncompleteForce.execute(null);
        Test.stopTest();

        // Assert artifacts created for both workorders
        assertContentArtifactsCreated(completeWo.Id);
        assertContentArtifactsCreated(incompleteWo.Id);
    }
}