/**
 * @description       :
 * @author            : Kartik Patkar Appstrail
 * @group             :
 * @last modified on  : 22-05-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   22-05-2025   Kartik Patkar, Appstrail   Initial Version
 **/
@isTest
private class MeteringWorkOrderAllocationBatchTest {
    
    @testSetup
    static void setupTestData() {
        // Create test Account (Customer)
        String gsRecordTypeID = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName()
            .get('PersonAccount').getRecordTypeId();
        Account cust = new Account(lastName = 'Test Customer',RecordTypeId=gsRecordTypeID);
        insert cust;
        
        // Valid Meter Reading Order (meant to be processed)
        Meter_Reading_Order__c validOrder = new Meter_Reading_Order__c(
            Name = 'Valid MRO',
            Customer__c = cust.Id,
            MRU__c = '12234',
            Scheduled_Meter_Reading_Date__c = Date.today().addDays(1),
            Scheduled_Meter_Reading_End_Date__c = Date.today().addDays(2),
            Meter_Reading_Date__c = null,
            Created_Order__c = false,
            Meter_Reading_Doc_Number__c = 'MRSDOC8978'
        );
        
        insert new List<Meter_Reading_Order__c>{
            validOrder
        };
    }
    
    @isTest
    static void testBatchExecution() {
        // Mock the static method in helper
        Test.startTest();
        
        // Use Test.setMock if helper method uses callouts or external deps
        // Run with default constructor
        MeteringWorkOrderAllocationBatch batch = new MeteringWorkOrderAllocationBatch();
        ID batchId = Database.executeBatch(batch, 1);
        Test.stopTest();
        
        System.assertNotEquals(null, batchId, 'Batch ID should not be null');
    }
    
    @isTest
    static void testBatchWithCustomQuery() {
        String customQuery = 'SELECT Id, Customer__c,Portion__c, Meter_Reading_Date__c, Scheduled_Meter_Reading_Date__c, MRU__c,Name,'+
                            'Customer_Location__c,Customer_Road_Name__c,Building__c,Customer_Postal_Code__c,Meter_Reading_Doc_Number__c,Customer_Category__c,Agent__c,Scheduled_Meter_Reading_End_Date__c,Meter_Reader_Name__c ' +
            'FROM Meter_Reading_Order__c WHERE Name = \'Valid MRO\'';
        
        MeteringWorkOrderAllocationBatch batch = new MeteringWorkOrderAllocationBatch(customQuery);
        Test.startTest();
        Database.executeBatch(batch, 1);
        Test.stopTest();
    }
}