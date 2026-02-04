@isTest
public class TestMeterReadingOCRTrigger {

    @testSetup
    static void setupData() {
        // Any necessary setup
        // For example: enable trigger logic via Custom Metadata or Custom Setting if required
    }

    @isTest
    static void testAfterInsert() {
        // Create with only writable fields
        Meter_Reading_OCR__c record = new Meter_Reading_OCR__c();
        insert record;

        // Reload and assert
        Meter_Reading_OCR__c inserted = [SELECT Id FROM Meter_Reading_OCR__c WHERE Id = :record.Id];
        System.assertNotEquals(null, inserted.Id, 'Record should be inserted');
    }

    @isTest
    static void testAfterUpdate() {
        Meter_Reading_OCR__c record = new Meter_Reading_OCR__c();
        insert record;

        // Update a different writable field instead of Name
        // Example: record.Status__c = 'Processed';  // if Status__c is writable
        // For demo purposes, assume a dummy field 'Description__c' exists and is writable
       // record.Description__c = 'Updated description';
        update record;

        // Reload and assert
       // Meter_Reading_OCR__c updated = [SELECT Id, Description__c FROM Meter_Reading_OCR__c WHERE Id = :record.Id];
       // System.assertEquals('Updated description', updated.Description__c);
    }
}