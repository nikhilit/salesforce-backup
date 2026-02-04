@isTest
public class O_MRubberHoseDetailContr_Test {

    // Helper: create test Account
    private static Account createTestAccount() {
        Account acc = new Account(Name = 'Test Acc', Meter_Number__c = '12345');
        insert acc;
        return acc;
    }

    // Helper: create test WorkOrder
    private static WorkOrder createTestWorkOrder(Id accId) {
        Id woRTId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName()
                        .get('MGL Metering').getRecordTypeId();

        WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            AccountId = accId,
            Status = 'Open',
            RecordTypeId = woRTId
        );
        insert wo;
        return wo;
    }

    @isTest
    static void testGetWOAccountDetails() {
        Account acc = createTestAccount();
        WorkOrder wo = createTestWorkOrder(acc.Id);

        Test.startTest();
        String result = O_MRubberHoseDetailContr.getWOAccountDetails(wo.Id);
        Test.stopTest();

        System.assertEquals(acc.Meter_Number__c, result);
    }

    @isTest
    static void testSaveRubberHoseDetails() {
        Account acc = createTestAccount();
        WorkOrder wo = createTestWorkOrder(acc.Id);

        // Rubber Hose JSON
        String rubberHoseJson = '{"meterNumber":"1111","meterReading":"2222","oldHoseExpiry":"2025-01-01","newHoseExpiry":"2026-01-01","rhLength":"10","numberOfleakageObserved":"Yes","leakagelocations":[{"index":1,"value":"Kitchen"}]}';

        // Dummy File
        List<O_MRubberHoseDetailContr.FileWrapper> files = new List<O_MRubberHoseDetailContr.FileWrapper>();
        O_MRubberHoseDetailContr.FileWrapper fw = new O_MRubberHoseDetailContr.FileWrapper();
        fw.base64Data = EncodingUtil.base64Encode(Blob.valueOf('Test File'));
        fw.fileName = 'test.txt';
        fw.label = 'TestFile';
        files.add(fw);

        Test.startTest();
        O_MRubberHoseDetailContr.saveRubberHoseDetails(wo.Id, rubberHoseJson, files, 'After remark');
        Test.stopTest();

        WorkOrder updatedWO = [SELECT Id, RH_Remark__c FROM WorkOrder WHERE Id = :wo.Id];
        System.assertEquals('After remark', updatedWO.RH_Remark__c);
    }

    @isTest
    static void testSaveMaterialDetails() {
        Account acc = createTestAccount();
        WorkOrder wo = createTestWorkOrder(acc.Id);

        // Picklist se valid value fetch karna
        Schema.DescribeFieldResult fieldResult = Material_Consumption__c.Item_description_Rubberhose__c.getDescribe();
        List<Schema.PicklistEntry> pickVals = fieldResult.getPicklistValues();
        String validItemDesc = (!pickVals.isEmpty()) ? pickVals[0].getValue() : null;

        List<O_MRubberHoseDetailContr.MaterialWrapper> mats = new List<O_MRubberHoseDetailContr.MaterialWrapper>();
        O_MRubberHoseDetailContr.MaterialWrapper mw = new O_MRubberHoseDetailContr.MaterialWrapper();
        mw.itemDescription = validItemDesc;  // ✅ Always valid picklist value
        mw.itemCode = 'RH-01';
        mw.unit = 'Nos';
        mw.quantity = 5;
        mats.add(mw);

        Test.startTest();
        O_MRubberHoseDetailContr.saveMaterialDetails(wo.Id, mats);
        Test.stopTest();

        List<Material_Consumption__c> inserted = [SELECT Id, Work_Order__c FROM Material_Consumption__c WHERE Work_Order__c = :wo.Id];
        System.assert(!inserted.isEmpty(), 'Material Consumption should be inserted');
    }

    @isTest
    static void testGetItemDescriptionOptions() {
        Test.startTest();
        List<String> options = O_MRubberHoseDetailContr.getItemDescriptionOptions();
        Test.stopTest();

        System.assertNotEquals(0, options.size(), 'Picklist options should not be empty');
    }

    @isTest
    static void testUploadRHReplacedServiceNote() {
        Account acc = createTestAccount();
        WorkOrder wo = createTestWorkOrder(acc.Id);

        String fileContent = EncodingUtil.base64Encode(Blob.valueOf('DummyFileContent'));

        Test.startTest();
        O_MRubberHoseDetailContr.uploadRHReplacedServiceNote('TestNote.txt', fileContent, wo.Id);
        Test.stopTest();

        List<ContentDocumentLink> links = [SELECT Id, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId = :wo.Id];
        System.assert(!links.isEmpty(), 'ContentDocumentLink should be created');
    }
}