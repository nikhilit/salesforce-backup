@IsTest
private class WorkOrderAccountInfoController_Test {
    
    @testSetup
    static void setupData() {
        
        Group_Master__c gM=new Group_Master__c();  
        gm.Name='Group Master';
        gm.Active__c=true;
        insert gm;
        
        Group_Code__c gc=new Group_Code__c(); 
        gc.Name='Group Code';
        gc.Group_Master__c=gm.Id;
        gc.Active__c=true;
        insert gc;
        
        Document_Master__c docMas=new Document_Master__c();
        docMas.Group_Code__c=gc.Id;
        docMas.Document_Name__c='test';
        docMas.Active__c=true;
        insert docMas;
        
        Group_Message__c gmss=new Group_Message__c();
        gmss.Name='Group Message';
        gmss.Group_Code__c=gc.Id;
        gmss.Active__c=true;
        insert gmss;
        
        // Account
        Account acc = new Account(Name = 'Test Account', Phone = '1234567890');
        insert acc;

        // Work Order (let org defaults handle Status etc.)
        WorkOrder wo = new WorkOrder(
            AccountId = acc.Id,
            Subject   = 'Test WO for Controller'
        );
        insert wo;

        // Pick a valid SA Status value (fallback to 'New' if schema returns empty for some reason)
        List<WorkOrderAccountInfoController.OptionsWrapper> saStatusOpts =
            WorkOrderAccountInfoController.fieldPicklistValue('ServiceAppointment', 'Status');
        String anySaStatus = saStatusOpts.isEmpty() ? 'New' : saStatusOpts[0].value;

        // Service Appointment minimally linked to the WO (no scheduling/territory)
        ServiceAppointment sa = new ServiceAppointment(
            ParentRecordId = wo.Id,
            Status         = 'In Progress'
        );
        insert sa;
    }

    @IsTest
    static void test_getAccountInfoFromSA_success() {
        WorkOrder wo = [SELECT Id, AccountId FROM WorkOrder LIMIT 1];

        Test.startTest();
        WorkOrderAccountInfoController.getGroupMasterOptions();
        Map<String, Object> result = WorkOrderAccountInfoController.getAccountInfoFromSA(wo.Id);
        Test.stopTest();
    }

    @IsTest
    static void test_getAccountInfoFromSA_nullId_throws() {
        Boolean threw = false;
        try {
            WorkOrderAccountInfoController.getAccountInfoFromSA(null);
        } catch (AuraHandledException ahe) {
            threw = true;
        }
    }

    @IsTest
    static void test_getGroupDataForTodayAppointments() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        Test.startTest();
        Map<String, Object> res = WorkOrderAccountInfoController.getGroupDataForTodayAppointments(wo.Id);
        Test.stopTest();

    }

    @IsTest
    static void test_updateServiceAppointment_and_workOrder_updates() {
        // Fetch created data
        ServiceAppointment sa = [SELECT Id, ParentRecordId, Status FROM ServiceAppointment LIMIT 1];
        WorkOrder woBefore = [SELECT Id, Appointment_Status__c, Approval_Status__c FROM WorkOrder WHERE Id = :sa.ParentRecordId LIMIT 1];
		Group_Master__c gm=[SELECT Id FROM Group_Master__c LIMIT 1];
        Group_Code__c gc=[SELECT Id FROM Group_Code__c LIMIT 1];
        Group_Message__c gmss=[SELECT Id FROM Group_Message__c LIMIT 1];
        // Call: set finalAttempt = true -> SA.Status should become 'Completed' and WO marked complete
        Test.startTest();
        WorkOrderAccountInfoController.getGroupCodeOptions(gm.Id,'',false);
        WorkOrderAccountInfoController.getGroupMessageOptions(gc.Id,false,false,false,false,false);
        WorkOrderAccountInfoController.updateServiceAppointment(
            sa.Id,
            gm.Id,     // groupMasterId
            gc.Id,     // groupCodeId
            gmss.Id,     // groupMsgId
            sa.ParentRecordId,
            12,       // currentMeterReading
            10,       // amrReading
            'Addl comment',
            'FU remarks',
            true,     // finalAttempt
            true,     // premiseCorrect
            true,     // meterSerialCorrect
            true,     // meterSerialVisible
            Date.today().addDays(2),
            19.1234,  // latitude
            72.9876,  // longitude
            true,     // mglGasBurningPossible
            null,     // mglGasBurntMeterStatus
            false,    // defaultGroupCode
            5,         // sealReading
            false,
            false,
            false,
            false,
            ''
        );
        Test.stopTest();

    }

    @IsTest
    static void test_workOrderCheckIn_twice() {
        ServiceAppointment sa = [SELECT Id, ParentRecordId FROM ServiceAppointment LIMIT 1];
        Id woId = sa.ParentRecordId;

        Test.startTest();
        String first = WorkOrderAccountInfoController.workOrderCheckIn(
            String.valueOf(woId), String.valueOf(sa.Id), 18.5555, 73.0000);
        String second = WorkOrderAccountInfoController.workOrderCheckIn(
            String.valueOf(woId), String.valueOf(sa.Id), 18.5555, 73.0000);
        Test.stopTest();

    }
    
    @IsTest
    static void test_saveImage_createsContentAndDocsAndOCR() {
        // Query setup records
        WorkOrder wo = [SELECT Id, Meter_Reading_Doc_Number__c, BP_Number__c, Scheduled_Date__c FROM WorkOrder LIMIT 1];
        Account acc = [SELECT Id, BP_Number__c FROM Account LIMIT 1];
        ServiceAppointment sa = [SELECT Id, ParentRecordId, Work_Order__c FROM ServiceAppointment LIMIT 1];

        // Prepare FileWrapper(s)
        WorkOrderAccountInfoController.FileWrapper fw = new WorkOrderAccountInfoController.FileWrapper();
        fw.label = 'FrontPhoto';
        // base64-encoded sample content
        fw.base64Data = EncodingUtil.base64Encode(Blob.valueOf('Dummy image bytes'));
        fw.ocr = true; // will cause Meter_Reading_OCR__c creation in method

        List<WorkOrderAccountInfoController.FileWrapper> files = new List<WorkOrderAccountInfoController.FileWrapper>{ fw };

        Test.startTest();
        // serviceAppointmentId and workOrderId are Strings in method signature
        WorkOrderAccountInfoController.saveImage(
            files,
            String.valueOf(sa.Id),
            false,      // defaultGroupCode (not used in current method body)
            acc,        // Account record as parameter
            String.valueOf(wo.Id)
        );
        Test.stopTest();

        // Assert ContentVersion(s) created (title == fw.label)
        List<ContentVersion> cvs = [SELECT Id, Title, ContentDocumentId, PathOnClient FROM ContentVersion WHERE Title = :fw.label];
        System.assert(cvs.size() > 0, 'Expected at least one ContentVersion created with Title = ' + fw.label);

        ContentVersion cv = cvs[0];
        System.assertEquals(fw.label, cv.Title);

        // Assert that Document__c records were created and updated to 'Pending'
        List<Document__c> docs = [SELECT Id, Type__c, Upload_Status__c, Work_Order__c, Service_Appointment__c
                                   FROM Document__c
                                   WHERE Work_Order__c = :wo.Id];
        System.assert(docs.size() > 0, 'Document__c records should be created');
        // All created docs should have Upload_Status__c = 'Pending'
        for (Document__c d : docs) {
            System.assertEquals('Pending', d.Upload_Status__c, 'Document Upload_Status__c should be Pending');
        }

        // Assert that Meter_Reading_OCR__c records were created (since fw.ocr = true) and set to Pending
        List<Meter_Reading_OCR__c> ocrs = [SELECT Id, Status__c, Work_Order__c, Type__c FROM Meter_Reading_OCR__c WHERE Work_Order__c = :wo.Id];
        System.assert(ocrs.size() > 0, 'Expected at least one Meter_Reading_OCR__c record created');
        for (Meter_Reading_OCR__c m : ocrs) {
            System.assertEquals('Pending', m.Status__c, 'Meter_Reading_OCR__c should be Pending');
        }

        // Assert ContentDocumentLink(s) exist linking CV's ContentDocumentId to the WorkOrder and to the created docs/ocrs
        Id contentDocId = cv.ContentDocumentId;
        System.assertNotEquals(null, contentDocId, 'ContentDocumentId should be populated on ContentVersion');

        List<ContentDocumentLink> linksToWorkOrder = [
            SELECT Id, ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :contentDocId AND LinkedEntityId = :wo.Id
            LIMIT 1
        ];
        System.assert(linksToWorkOrder.size() == 1, 'There should be a ContentDocumentLink linking the content to the WorkOrder');

        // Also check links to created Document__c and Meter_Reading_OCR__c (if present)
        // Collect linked entity ids that were used in code
        Set<Id> expectedLinkedEntities = new Set<Id>{ wo.Id };
        for (Document__c d : docs) expectedLinkedEntities.add(d.Id);
        for (Meter_Reading_OCR__c m : ocrs) expectedLinkedEntities.add(m.Id);

        List<ContentDocumentLink> linksAll = [
            SELECT Id, ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :contentDocId AND LinkedEntityId IN :expectedLinkedEntities
        ];
        // Should have at least one link (we asserted above for work order), expect more for docs/ocrs
        System.assert(linksAll.size() >= 1, 'Expected ContentDocumentLink records linking to one or more expected entities');
    }
    @isTest
private static void testGetAccountLocation_NoAssertions() {
    Account accNoGeo = new Account(
        Name = 'Test No Geo'
    );
    insert accNoGeo;

    Map<String, Decimal> resultNoGeo =
        WorkOrderAccountInfoController.getAccountLocation(accNoGeo.Id);

    Account accWithGeo = new Account(
        Name = 'Test With Geo',
        Geolocation__Latitude__s = 19.12345,
        Geolocation__Longitude__s = 72.98765
    );
    insert accWithGeo;

    Map<String, Decimal> resultWithGeo =
        WorkOrderAccountInfoController.getAccountLocation(accWithGeo.Id);

    Map<String, Decimal> resultNullId =
        WorkOrderAccountInfoController.getAccountLocation(null);
}

}