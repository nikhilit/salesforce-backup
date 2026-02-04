@isTest
private class IndirectMeterImageTaggingHelperTest {

    //
    // Utility: Create a ContentVersion for testing
    //
    private static ContentVersion createContentVersion(
        String bp,
        Boolean directFlag,
        String reading,
        Date readingDate
    ) {
        ContentVersion cv = new ContentVersion(
            Title = 'TestFile_' + bp,
            PathOnClient = 'test.jpg',
            VersionData = Blob.valueOf('dummy'),
            In_Direct_Meter_Reading__c = directFlag,
            BP_Number__c = bp,
            Meter_Reading_Value__c = reading,
            Meter_Reading_Date__c = readingDate,
            Mode__c = 'Web',
            Meter_Reading_Submited_By__c = 'Customer'
        );
        insert cv;

        // Re-query with ContentDocumentId
        return [
            SELECT Id, ContentDocumentId, Title, BP_Number__c, In_Direct_Meter_Reading__c,
                   Meter_Reading_Value__c, Meter_Reading_Date__c, Mode__c, Meter_Reading_Submited_By__c
            FROM ContentVersion
            WHERE Id = :cv.Id
        ];
    }

    //
    // Setup
    //
    @testSetup
    static void setupData() {

        // Existing Account for BP = 1001
        Account acc = new Account(
            Name = 'TestAcc',
            BP_Number__c = '1001'
        );
        insert acc;
        
        String meteringRecordTypeId = Schema.getGlobalDescribe().get('WorkOrder').getDescribe().getRecordTypeInfosByDeveloperName()
                                            .get('MGL_Metering').getRecordTypeId();

        // Existing WorkOrder for BP=1001
        WorkOrder wo = new WorkOrder(
            Subject = 'Existing WO',
            AccountId = acc.Id,
            Appointment_Status__c = 'New',
            Indirect_Reading_Received__c = false,
            RecordTypeId=meteringRecordTypeId
        );
        insert wo;

        // Another Account for new WorkOrders
        insert new Account(Name='Acc2', BP_Number__c='2002');
    }

    //
    // MAIN TEST
    //
    @isTest
    static void testIndirectMeterImageTaggingHelper() {

        //
        // Create ContentVersions
        //
        // 1. CV that should attach to existing WO (BP=1001)
        ContentVersion cvExisting = createContentVersion(
            '1001', true, '123', Date.today()
        );

        // 2. CV that should create a NEW WorkOrder (BP=2002)
        ContentVersion cvNewWO = createContentVersion(
            '2002', true, '45', Date.today()
        );

        Test.startTest();

        IndirectMeterImageTaggingHelper.attachFileToWorkOrder(
            new List<ContentVersion>{ cvExisting, cvNewWO }
        );

        Test.stopTest();

    }
}