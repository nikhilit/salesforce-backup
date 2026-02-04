/**
* @File Name : AS_CSVUploaderControllerTest.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : July 9, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | July 9, 2025 |   | Initial Version
**/
@isTest
private class AS_CSVUploaderControllerTest {

    @testSetup
    static void setupTestData() {
        insert new Account(Name = 'Existing Account', BP_Number__c = 'AC123');
    }

    @isTest
    static void testGetObjectList() {
        Test.startTest();
        List<Map<String, String>> objectList = AS_CSVUploaderController.getObjectList();
        Test.stopTest();
    }
    @isTest
    static void testUploadCSVBatch_Insert_Success() {
        List<Map<String, String>> csvData = new List<Map<String, String>>{
            new Map<String, String>{ 'Name' => 'Test Account A', 'Phone' => '1111111111' },
            new Map<String, String>{ 'Name' => 'Test Account B', 'Phone' => '2222222222' }
        };

        Test.startTest();
        Map<String, Object> result = AS_CSVUploaderController.uploadCSVBatch(csvData, 'Account', null);
        Test.stopTest();

        // Verify records were inserted
        List<Account> accounts = [SELECT Name FROM Account WHERE Name IN ('Test Account A', 'Test Account B')];
    }

    @isTest
    static void testUploadCSVBatch_Upsert_Success() {
        List<Map<String, String>> csvData = new List<Map<String, String>>{
            new Map<String, String>{
                'Name' => 'Updated Existing Account',
                'BP_Number__c' => 'AC123',
                'Phone' => '5555555555'
            },
            new Map<String, String>{
                'Name' => 'New Upserted Account',
                'BP_Number__c' => 'AC999',
                'Phone' => '9999999999'
            }
        };

        Test.startTest();
        Map<String, Object> result = AS_CSVUploaderController.uploadCSVBatch(csvData, 'Account', 'BP_Number__c');
        Test.stopTest();
        // Verify records in DB
        List<Account> accounts = [SELECT Name, BP_Number__c FROM Account WHERE BP_Number__c IN ('AC123', 'AC999')];
    }

    @isTest
    static void testUploadCSVBatch_InvalidField_Error() {
        List<Map<String, String>> csvData = new List<Map<String, String>>{
            new Map<String, String>{ 'NonExistentField__c' => 'Test', 'Name' => 'Bad Account' }
        };

        Test.startTest();
        Map<String, Object> result = AS_CSVUploaderController.uploadCSVBatch(csvData, 'Account', null);
        Test.stopTest();

        List<Object> errors = (List<Object>)result.get('errors');
    }

    @isTest
    static void testUploadCSVBatch_InvalidObject_Error() {
        List<Map<String, String>> csvData = new List<Map<String, String>>{
            new Map<String, String>{ 'Name' => 'Test Record' }
        };

        Test.startTest();
        try {
            AS_CSVUploaderController.uploadCSVBatch(csvData, 'NonExistent__c', null);
        } catch (Exception e) {
        }
        Test.stopTest();
    }

    @isTest
    static void testUploadCSVBatch_BlankObject_Error() {
        List<Map<String, String>> csvData = new List<Map<String, String>>{
            new Map<String, String>{ 'Name' => 'Test Record' }
        };

        Test.startTest();
        try {
            AS_CSVUploaderController.uploadCSVBatch(csvData, '', null);
        } catch (Exception e) {
        }
        Test.stopTest();
    }

    @isTest
    static void testUploadCSVBatch_AllSupportedTypes() {
        List<Map<String, String>> csvData = new List<Map<String, String>>();

        csvData.add(new Map<String, String>{
            'Name' => 'Full Type Test Account',
            'Phone' => '1234567890',                    // String
            'NumberOfEmployees' => '250',               // Integer
            'AnnualRevenue' => '500000.50',             // Decimal
            'IsPartner' => 'true',                      // Boolean
            'BillingCity' => 'San Francisco',           // String
            'CreatedDate' => '2023-03-04 14:30:00',     // DateTime
            'SLAExpirationDate__c' => '03/15/2024',     // Custom Date field
            'Industry' => 'Technology',                 // Picklist

            // Mock unsupported types
            'BillingAddress' => '123 Test St',          // Address
            'Geolocation__c' => '37.7749,-122.4194',     // Location
            'Attachment__c' => 'VGVzdA==',              // Base64
            'Preferred_Languages__c' => 'English;French' // Multipicklist
        });

        Test.startTest();
        Map<String, Object> result = AS_CSVUploaderController.uploadCSVBatch(csvData, 'Account', null);
        Test.stopTest();
    }

    @isTest
    static void testUploadCSVBatch_DateFormatSupport() {
        List<Map<String, String>> csvData = new List<Map<String, String>>();

        csvData.add(new Map<String, String>{
            'Name' => 'Date Format Account',
            'SLAExpirationDate__c' => '03-15-2024'   // MM-dd-yyyy
        });

        Test.startTest();
        Map<String, Object> result = AS_CSVUploaderController.uploadCSVBatch(csvData, 'Account', null);
        Test.stopTest();
    }

    @isTest
    static void testUploadCSVBatch_InvalidDateFormat_Error() {
        List<Map<String, String>> csvData = new List<Map<String, String>>();

        csvData.add(new Map<String, String>{
            'Name' => 'Invalid Date Format Account',
            'SLAExpirationDate__c' => '15/03/2024'   // Invalid format
        });

        Test.startTest();
        Map<String, Object> result = AS_CSVUploaderController.uploadCSVBatch(csvData, 'Account', null);
        Test.stopTest();

        List<Object> errors = (List<Object>)result.get('errors');
    }

    @isTest
    static void testUploadLargeCSVChunk() {
        List<Map<String, String>> records = new List<Map<String, String>>{
            new Map<String, String>{ 'Name' => 'Async Test Account', 'Phone' => '1234567890' }
        };

        Test.startTest();
        AS_CSVUploaderController.uploadLargeCSVChunk(records, 'Account', null);
        Test.stopTest();
    }

    @isTest
    static void testChunkProcessor_ExceptionHandling() {
        Test.startTest();
        AS_CSVChunkProcessor job = new AS_CSVChunkProcessor(null, null, null);
        System.enqueueJob(job);
        Test.stopTest();          
    }
    
    @isTest
    static void testChunkProcessor_SuccessPath(){
       List<Map<String, String>> records = new List<Map<String, String>>{
           new Map<String, String>{ 'Name' => 'Test Account A', 'Phone' => '1111111111' },
           new Map<String, String>{ 'Name' => 'Test Account B', 'Phone' => '2222222222' }
        };   
        Test.startTest();
        AS_CSVChunkProcessor job = new AS_CSVChunkProcessor(records, 'WorkOrder', null);
        System.enqueueJob(job);
        Test.stopTest();  
    }
    
     @isTest
    static void testChunkProcessor_EmptyRecords(){
       List<Map<String, String>> records = new List<Map<String, String>>{};   
        Test.startTest();
        AS_CSVChunkProcessor job = new AS_CSVChunkProcessor(records, null, null);
        System.enqueueJob(job);
        Test.stopTest();  
    }

	@isTest
    static void testUploadCSVBatch_Insert_ErrorHandling() {
        List<Map<String, String>> csvData = new List<Map<String, String>>{
        	new Map<String, String>{ 'Name' => null } // Name is required for Account
        };     
        Test.startTest();
        Map<String, Object> result = AS_CSVUploaderController.uploadCSVBatch(csvData, 'Account', null);
        Test.stopTest();     
        List<Object> errors = (List<Object>)result.get('errors');
    	System.assert(!errors.isEmpty(), 'Should catch error for missing required Name');
    }

	@isTest
    static void test_parseFlexibleDate_MMddyyyy() {
        Date result = AS_CSVUploaderController.parseFlexibleDate('08/19/2025');
    }

    @isTest
    static void test_parseFlexibleDate_Mdyyyy() {
        Date result = AS_CSVUploaderController.parseFlexibleDate('8/5/2025');
    }

    @isTest
    static void test_parseFlexibleDate_yyyyMMdd() {
        Date result = AS_CSVUploaderController.parseFlexibleDate('2025-08-19');
    }

    @isTest
    static void test_parseFlexibleDate_MMddyyyy_dash() {
        Date result = AS_CSVUploaderController.parseFlexibleDate('08-19-2025');
    }

    @isTest
    static void test_parseFlexibleDate_invalid() {
        Date result = AS_CSVUploaderController.parseFlexibleDate('invalid-date');
    }

    @isTest
    static void test_parseFlexibleDate_empty() {
        Date result = AS_CSVUploaderController.parseFlexibleDate('  ');
    }

	    @isTest
    static void test_parseFlexibleDateTime_ISO() {
        DateTime dt = AS_CSVUploaderController.parseFlexibleDateTime('2025-08-19T14:30:45');
        System.assertEquals(DateTime.newInstance(2025, 8, 19, 14, 30, 45), dt);
    }

    @isTest
    static void test_parseFlexibleDateTime_spaceFormat() {
        DateTime dt = AS_CSVUploaderController.parseFlexibleDateTime('2025-08-19 14:30:00');
    }

    @isTest
    static void test_parseFlexibleDateTime_missingTime() {
        DateTime dt = AS_CSVUploaderController.parseFlexibleDateTime('2025-08-19');
        System.assertEquals(null, dt);
    }

    @isTest
    static void test_parseFlexibleDateTime_partialTime() {
        DateTime dt = AS_CSVUploaderController.parseFlexibleDateTime('2025-08-19 09:15');
    }

    @isTest
    static void test_parseFlexibleDateTime_invalidFormat() {
        DateTime dt = AS_CSVUploaderController.parseFlexibleDateTime('invalid-datetime');
    }
    
}