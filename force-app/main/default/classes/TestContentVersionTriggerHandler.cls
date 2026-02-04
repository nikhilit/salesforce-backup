@isTest
private class TestContentVersionTriggerHandler {

    @isTest
    static void testAfterInsertIndirectMeterTrue() {
        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile.jpg',
            VersionData = Blob.valueOf('Test content'),
            In_Direct_Meter_Reading__c = true,
            BP_Number__c = 'BP1234567',
            MRO_Doc_Number__c = 'MRO001'
        );
        insert cv;

        // Simulate after insert
        Test.startTest();
        ContentVersionTriggerHandler.afterInsert(new List<ContentVersion>{cv});
        Test.stopTest();
    }

    @isTest
    static void testAfterUpdateWithChangedFields() {
        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile2.jpg',
            VersionData = Blob.valueOf('Another test content'),
            In_Direct_Meter_Reading__c = false,
            BP_Number__c = 'BP7654321',
            MRO_Doc_Number__c = 'MRO002'
        );
        insert cv;

        // Simulate changes
        ContentVersion cvUpdate = [SELECT Id, In_Direct_Meter_Reading__c, BP_Number__c, MRO_Doc_Number__c FROM ContentVersion WHERE Id = :cv.Id];
        cvUpdate.In_Direct_Meter_Reading__c = true;
        update cvUpdate;

        // Simulate after update
        Map<Id, ContentVersion> oldMap = new Map<Id, ContentVersion>{
            cv.Id => cv
        };

        Test.startTest();
        ContentVersionTriggerHandler.afterUpdate(new List<ContentVersion>{cvUpdate}, oldMap);
        Test.stopTest();
    }

    @isTest
    static void testAfterUpdateWithNoRelevantChange() {
        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile3.jpg',
            VersionData = Blob.valueOf('Third test content'),
            In_Direct_Meter_Reading__c = true,
            BP_Number__c = 'BP123123',
            MRO_Doc_Number__c = 'MRO003'
        );
        insert cv;

        // Same values, so nothing should trigger
        Map<Id, ContentVersion> oldMap = new Map<Id, ContentVersion>{
            cv.Id => cv
        };

        Test.startTest();
        ContentVersionTriggerHandler.afterUpdate(new List<ContentVersion>{cv}, oldMap);
        Test.stopTest();
    }
}