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
private class OMWOCSVUploaderContrTest {

    @testSetup
    static void setupTestData() {
        insert new Account(Name = 'Existing Account', BP_Number__c = 'AC123');
    }

    @isTest
    static void testGetObjectList() {
        Test.startTest();
        List<Map<String, String>> objectList = OMWOCSVUploaderContr.getObjectList();
        Test.stopTest();
    }
    @isTest
    static void testUploadCSVBatch_Insert_Success() {
        List<Map<String, String>> csvData = new List<Map<String, String>>{
            new Map<String, String>{ 'Name' => 'Test Account A', 'Phone' => '1111111111' },
            new Map<String, String>{ 'Name' => 'Test Account B', 'Phone' => '2222222222' }
        };

        Test.startTest();
        Map<String, Object> result = OMWOCSVUploaderContr.uploadCSVBatch(csvData, 'Account', null);
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
        Map<String, Object> result = OMWOCSVUploaderContr.uploadCSVBatch(csvData, 'Account', 'BP_Number__c');
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
        Map<String, Object> result = OMWOCSVUploaderContr.uploadCSVBatch(csvData, 'Account', null);
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
            OMWOCSVUploaderContr.uploadCSVBatch(csvData, 'NonExistent__c', null);
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
            OMWOCSVUploaderContr.uploadCSVBatch(csvData, '', null);
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
        Map<String, Object> result = OMWOCSVUploaderContr.uploadCSVBatch(csvData, 'Account', null);
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
        Map<String, Object> result = OMWOCSVUploaderContr.uploadCSVBatch(csvData, 'Account', null);
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
        Map<String, Object> result = OMWOCSVUploaderContr.uploadCSVBatch(csvData, 'Account', null);
        Test.stopTest();

        List<Object> errors = (List<Object>)result.get('errors');
    }

    @isTest
    static void testUploadLargeCSVChunk() {
        List<Map<String, String>> records = new List<Map<String, String>>{
            new Map<String, String>{ 'Name' => 'Async Test Account', 'Phone' => '1234567890' }
        };

        Test.startTest();
        OMWOCSVUploaderContr.uploadLargeCSVChunk(records, 'Account', null);
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
        Map<String, Object> result = OMWOCSVUploaderContr.uploadCSVBatch(csvData, 'Account', null);
        Test.stopTest();     
        List<Object> errors = (List<Object>)result.get('errors');
    	System.assert(!errors.isEmpty(), 'Should catch error for missing required Name');
    }

	@isTest
    static void test_parseFlexibleDate_MMddyyyy() {
        Date result = OMWOCSVUploaderContr.parseFlexibleDate('08/19/2025');
    }

    @isTest
    static void test_parseFlexibleDate_Mdyyyy() {
        Date result = OMWOCSVUploaderContr.parseFlexibleDate('8/5/2025');
    }

    @isTest
    static void test_parseFlexibleDate_yyyyMMdd() {
        Date result = OMWOCSVUploaderContr.parseFlexibleDate('2025-08-19');
    }

    @isTest
    static void test_parseFlexibleDate_MMddyyyy_dash() {
        Date result = OMWOCSVUploaderContr.parseFlexibleDate('08-19-2025');
    }

    @isTest
    static void test_parseFlexibleDate_invalid() {
        Date result = OMWOCSVUploaderContr.parseFlexibleDate('invalid-date');
    }

    @isTest
    static void test_parseFlexibleDate_empty() {
        Date result = OMWOCSVUploaderContr.parseFlexibleDate('  ');
    }

	    @isTest
    static void test_parseFlexibleDateTime_ISO() {
        DateTime dt = OMWOCSVUploaderContr.parseFlexibleDateTime('2025-08-19T14:30:45');
        System.assertEquals(DateTime.newInstance(2025, 8, 19, 14, 30, 45), dt);
    }

    @isTest
    static void test_parseFlexibleDateTime_spaceFormat() {
        DateTime dt = OMWOCSVUploaderContr.parseFlexibleDateTime('2025-08-19 14:30:00');
    }

    @isTest
    static void test_parseFlexibleDateTime_missingTime() {
        DateTime dt = OMWOCSVUploaderContr.parseFlexibleDateTime('2025-08-19');
        System.assertEquals(null, dt);
    }

    @isTest
    static void test_parseFlexibleDateTime_partialTime() {
        DateTime dt = OMWOCSVUploaderContr.parseFlexibleDateTime('2025-08-19 09:15');
    }

    @isTest
    static void test_parseFlexibleDateTime_invalidFormat() {
        DateTime dt = OMWOCSVUploaderContr.parseFlexibleDateTime('invalid-datetime');
    }

	@isTest
    static void testUploadCSVBatch_EmptyCSV() {
        Test.startTest();
        Map<String, Object> result =
            OMWOCSVUploaderContr.uploadCSVBatch('Account', new List<Map<String,String>>());
        Test.stopTest();
    
        System.assertEquals(0, (Integer)result.get('successCount'));
    }

	@isTest
    static void testUploadCSVBatch_InvalidObject_FirstMethod() {
        List<Map<String,String>> csv = new List<Map<String,String>>{
            new Map<String,String>{ 'Name' => 'Test' }
        };
    
        Test.startTest();
        Map<String,Object> res =
            OMWOCSVUploaderContr.uploadCSVBatch(csv, 'BadObject__c', null);
        Test.stopTest();
    
        System.assertEquals(0, (Integer)res.get('successCount'));
    }

	@isTest
	static void testConversionError_Integer() {
        List<Map<String,String>> csv = new List<Map<String,String>>{
            new Map<String,String>{
                'Name' => 'Bad Int',
                'NumberOfEmployees' => 'NOT_A_NUMBER'
            }
        };

        Test.startTest();
        Map<String,Object> res =
            OMWOCSVUploaderContr.uploadCSVBatch(csv, 'Account', null);
        Test.stopTest();

        List<Object> exceptions = (List<Object>)res.get('exceptions');
        System.assert(!exceptions.isEmpty());
    }

	@isTest
	static void testUnsupportedFieldWarning() {
        List<Map<String,String>> csv = new List<Map<String,String>>{
            new Map<String,String>{
                'Name' => 'Warn Account',
                'BillingAddress' => 'Some address'
            }
        };

        Test.startTest();
        Map<String,Object> res =
            OMWOCSVUploaderContr.uploadCSVBatch(csv, 'Account', null);
        Test.stopTest();

        List<Map<String,String>> successes =
            (List<Map<String,String>>)res.get('successes');

        System.assert(successes[0].containsKey('Warnings'));
    }

	@isTest
    static void testDateTimeFallbackPath() {
        List<Map<String,String>> csv = new List<Map<String,String>>{
            new Map<String,String>{
                'Name' => 'DT Test',
                'CreatedDate' => '2025-08-19T10:15:30'
            }
        };
    
        Test.startTest();
        Map<String,Object> res =
            OMWOCSVUploaderContr.uploadCSVBatch(csv, 'Account', null);
        Test.stopTest();
    
        System.assertEquals(1, (Integer)res.get('successCount'));
    }

	
	@isTest
    static void testUploadLargeCSVChunk_HappyPath() {
        List<Map<String,String>> csv = new List<Map<String,String>>{
            new Map<String,String>{ 'Name' => 'Chunk OK' }
        };
    
        Test.startTest();
        OMWOCSVUploaderContr.uploadLargeCSVChunk(csv, 'Account', null);
        Test.stopTest();
    }

		
	@isTest
	static void testWrapper_EmptyCSV() {
    Test.startTest();
    Map<String,Object> res =
        OMWOCSVUploaderContr.uploadCSVBatch(
            'Account',
            new List<Map<String,String>>()
        );
        Test.stopTest();
    
        System.assertEquals(0, (Integer)res.get('successCount'));
    }

	
	@isTest
	static void testWrapper_WorkOrderPath_EXECUTES() {

    List<Map<String,String>> csv = new List<Map<String,String>>{
        new Map<String,String>{
            'Subject' => 'WO Test',
            'Status' => 'New'
        }
    };

    Test.startTest();
    Map<String,Object> res =
        OMWOCSVUploaderContr.uploadCSVBatch(
            'WorkOrder',
            csv
        );
    Test.stopTest();

    System.assertNotEquals(null, res);
}

	@isTest
    static void testWrapper_NonWorkOrderPath() {
    
        List<Map<String,String>> csv = new List<Map<String,String>>{
            new Map<String,String>{
                'Name' => 'Wrapper Account'
            }
        };
    
        Test.startTest();
        Map<String,Object> res =
            OMWOCSVUploaderContr.uploadCSVBatch(
                'Account',
                csv
            );
        Test.stopTest();
    
        System.assertEquals(1, (Integer)res.get('successCount'));
    }


/*	@isTest
    static void testWrapper_ExceptionCatch() {
        Test.startTest();
        Map<String,Object> res =
            OMWOCSVUploaderContr.uploadCSVBatch(
                null,
                null
            ); 
        Test.stopTest(); 
    
       // System.assertNotEquals(null, res);
    } */











    
}