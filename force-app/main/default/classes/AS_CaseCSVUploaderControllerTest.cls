@IsTest
public class AS_CaseCSVUploaderControllerTest {

    @TestSetup
    static void setupData() {
        // Insert sample Cases for testing with Docket Numbers
        List<Case> cases = new List<Case>();
        for (Integer i = 0; i < 5; i++) {
            cases.add(new Case(
                Subject = 'Test Case ' + i,
                Status = 'New',
                Docket_Number__c = 'DOCKET00' + i,
                Standard_Remarks__c = 'Initial Remark ' + i,
                Planned_Start_Date__c = System.today().addDays(i),
                Planned_End_Date__c = System.today().addDays(i + 10)
            ));
        }
        insert cases;
    }

    @IsTest
    static void testGetObjectList() {
        Test.startTest();
        List<Map<String,String>> result = AS_CaseCSVUploaderController.getObjectList();
        Test.stopTest();
    }

    @IsTest
    static void testUploadCSVBatchValidWithAllFields() {
        Case c = [SELECT Id, Docket_Number__c FROM Case WHERE Docket_Number__c = 'DOCKET000' LIMIT 1];

        List<Map<String,String>> csvRecords = new List<Map<String,String>>();
        csvRecords.add(new Map<String,String>{
            'Docket_Number__c' => c.Docket_Number__c,
            'Standard_Remarks__c' => 'Updated Remark',
            'Planned_Start_Date__c' => '2024-01-15',
            'Planned_End_Date__c' => '2024-01-25'
        });

        Test.startTest();
        Map<String, Object> result = AS_CaseCSVUploaderController.uploadCSVBatch('Case', csvRecords);
        Test.stopTest();
    }

    @IsTest
    static void testUploadCSVBatchValidWithOnlyRequiredFields() {
        Case c = [SELECT Id, Docket_Number__c FROM Case WHERE Docket_Number__c = 'DOCKET001' LIMIT 1];

        List<Map<String,String>> csvRecords = new List<Map<String,String>>();
        csvRecords.add(new Map<String,String>{
            'Docket_Number__c' => c.Docket_Number__c,
            'Standard_Remarks__c' => 'Updated Remark Only Required'
        });

        Test.startTest();
        Map<String, Object> result = AS_CaseCSVUploaderController.uploadCSVBatch('Case', csvRecords);
        Test.stopTest();
    }

    @IsTest
    static void testUploadCSVBatchMissingRequiredHeader() {
        List<Map<String,String>> badRecords = new List<Map<String,String>>();
        badRecords.add(new Map<String,String>{ 
            'Standard_Remarks__c' => '123',
            'Planned_Start_Date__c' => '2024-01-01'
        });

        Test.startTest();
        Map<String, Object> result = AS_CaseCSVUploaderController.uploadCSVBatch('Case', badRecords);
        Test.stopTest();
    }

    @IsTest
    static void testUploadCSVBatchBlankAndInvalidDocket() {
        List<Map<String,String>> records = new List<Map<String,String>>();
        records.add(new Map<String,String>{
            'Docket_Number__c' => '',
            'Standard_Remarks__c' => 'Remark A'
        });
        records.add(new Map<String,String>{
            'Docket_Number__c' => 'NON_EXISTING_DOCKET',
            'Standard_Remarks__c' => 'Remark B'
        });

        Test.startTest();
        Map<String, Object> result = AS_CaseCSVUploaderController.uploadCSVBatch('Case', records);
        Test.stopTest();
    }

    @IsTest
    static void testEmptyCSVUpload() {
        List<Map<String,String>> emptyRecords = new List<Map<String,String>>();

        Test.startTest();
        Map<String, Object> result = AS_CaseCSVUploaderController.uploadCSVBatch('Case', emptyRecords);
        Test.stopTest();
    }

    @IsTest
    static void testDatabaseUpdateFailure() {
        Case c = [SELECT Id, Docket_Number__c FROM Case WHERE Docket_Number__c = 'DOCKET002' LIMIT 1];

        c.Status = 'Closed';
        update c;

        List<Map<String,String>> records = new List<Map<String,String>>();
        records.add(new Map<String,String>{
            'Docket_Number__c' => c.Docket_Number__c,
            'Standard_Remarks__c' => 'Remark After Closed'
        });

        Test.startTest();
        Map<String, Object> result = AS_CaseCSVUploaderController.processChunk('Case', records);
        Test.stopTest();
    }

    @IsTest
    static void testUploadLargeCSVChunkAndQueueable() {
        Case c = [SELECT Id, Docket_Number__c FROM Case WHERE Docket_Number__c = 'DOCKET003' LIMIT 1];

        List<Map<String,String>> csvRecords = new List<Map<String,String>>();
        csvRecords.add(new Map<String,String>{
            'Docket_Number__c' => c.Docket_Number__c,
            'Standard_Remarks__c' => 'Remark from Queue',
            'Planned_Start_Date__c' => '2024-02-01',
            'Planned_End_Date__c' => '2024-02-28'
        });

        Test.startTest();
        AS_CaseCSVUploaderController.uploadLargeCSVChunk(csvRecords, 'Case');
        Test.stopTest();
    }

    @IsTest
    static void testProcessChunkDirectlyWithDateValidationErrors() {
        Case c = [SELECT Id, Docket_Number__c FROM Case WHERE Docket_Number__c = 'DOCKET004' LIMIT 1];

        List<Map<String,String>> records = new List<Map<String,String>>();
        records.add(new Map<String,String>{
            'Docket_Number__c' => c.Docket_Number__c,
            'Standard_Remarks__c' => 'Direct Processing',
            'Planned_Start_Date__c' => 'INVALID_DATE',
            'Planned_End_Date__c' => '2024-01-25'
        });
        records.add(new Map<String,String>{
            'Docket_Number__c' => c.Docket_Number__c,
            'Standard_Remarks__c' => 'Another Remark',
            'Planned_Start_Date__c' => '2024-01-15',
            'Planned_End_Date__c' => 'INVALID_DATE'
        });

        Test.startTest();
        Map<String, Object> result = AS_CaseCSVUploaderController.processChunk('Case', records);
        Test.stopTest();
    }

    @IsTest
    static void testProcessChunkWithMixedValidAndInvalidRecords() {
        Case validCase = [SELECT Id, Docket_Number__c FROM Case WHERE Docket_Number__c = 'DOCKET000' LIMIT 1];

        List<Map<String,String>> records = new List<Map<String,String>>();
        records.add(new Map<String,String>{
            'Docket_Number__c' => validCase.Docket_Number__c,
            'Standard_Remarks__c' => 'Valid Remark',
            'Planned_Start_Date__c' => '2024-03-01',
            'Planned_End_Date__c' => '2024-03-31'
        });
        records.add(new Map<String,String>{
            'Docket_Number__c' => '',
            'Standard_Remarks__c' => 'Invalid Remark'
        });
        records.add(new Map<String,String>{
            'Docket_Number__c' => 'NON_EXISTENT_123',
            'Standard_Remarks__c' => 'Non-existent Remark'
        });

        Test.startTest();
        Map<String, Object> result = AS_CaseCSVUploaderController.processChunk('Case', records);
        Test.stopTest();
    }

    @IsTest
    static void testProcessChunkWithPartialOptionalFields() {
        Case c = [SELECT Id, Docket_Number__c FROM Case WHERE Docket_Number__c = 'DOCKET001' LIMIT 1];

        List<Map<String,String>> records = new List<Map<String,String>>();
        records.add(new Map<String,String>{
            'Docket_Number__c' => c.Docket_Number__c,
            'Standard_Remarks__c' => 'Partial Fields Remark'
        });

        Test.startTest();
        Map<String, Object> result = AS_CaseCSVUploaderController.processChunk('Case', records);
        Test.stopTest();
    }

@IsTest
static void testProcessChunkWithDateValidationErrorOnStartDateOnly() {
    Case c = [SELECT Id, Docket_Number__c FROM Case WHERE Docket_Number__c = 'DOCKET000' LIMIT 1];
    
    List<Map<String,String>> records = new List<Map<String,String>>();
    records.add(new Map<String,String>{
        'Docket_Number__c' => c.Docket_Number__c,
        'Planned_Start_date__c' => 'INVALID_DATE_FORMAT'  // This should cause validation error
    });
    
    Test.startTest();
    Map<String, Object> result = AS_CaseCSVUploaderController.processChunk('Case', records);
    Test.stopTest();
   
}

@IsTest
static void testProcessChunkWithDateValidationErrorOnEndDateOnly() {
    Case c = [SELECT Id, Docket_Number__c FROM Case WHERE Docket_Number__c = 'DOCKET001' LIMIT 1];
    
    List<Map<String,String>> records = new List<Map<String,String>>();
    records.add(new Map<String,String>{
        'Docket_Number__c' => c.Docket_Number__c,
        'Planned_End_Date__c' => 'INVALID_END_DATE'  // This should cause validation error
    });
    
    Test.startTest();
    Map<String, Object> result = AS_CaseCSVUploaderController.processChunk('Case', records);
    Test.stopTest();
    

}

@IsTest
static void testProcessChunkWithMultipleValidationErrorsInSingleRecord() {
    Case c = [SELECT Id, Docket_Number__c FROM Case WHERE Docket_Number__c = 'DOCKET002' LIMIT 1];
    
    List<Map<String,String>> records = new List<Map<String,String>>();
    records.add(new Map<String,String>{
        'Docket_Number__c' => c.Docket_Number__c,
        'Planned_Start_date__c' => 'INVALID_START',
        'Planned_End_Date__c' => 'INVALID_END'
    });
    
    Test.startTest();
    Map<String, Object> result = AS_CaseCSVUploaderController.processChunk('Case', records);
    Test.stopTest();
    

}

@IsTest
static void testProcessChunkWithSuccessRecordHavingAllOptionalFields() {
    Case c = [SELECT Id, Docket_Number__c FROM Case WHERE Docket_Number__c = 'DOCKET003' LIMIT 1];
    
    List<Map<String,String>> records = new List<Map<String,String>>();
    records.add(new Map<String,String>{
        'Docket_Number__c' => c.Docket_Number__c,
        'Standard_Remarks__c' => 'Test Remark',
        'Planned_Start_date__c' => '2024-01-01',
        'Planned_End_Date__c' => '2024-12-31'
    });
    
    Test.startTest();
    Map<String, Object> result = AS_CaseCSVUploaderController.processChunk('Case', records);
    Test.stopTest();
    
}

@IsTest
static void testProcessChunkWithDatabasePartialFailure() {
    Case c1 = [SELECT Id, Docket_Number__c FROM Case WHERE Docket_Number__c = 'DOCKET000' LIMIT 1];
    Case c2 = [SELECT Id, Docket_Number__c FROM Case WHERE Docket_Number__c = 'DOCKET001' LIMIT 1];
    
    // Make c2 invalid for update by closing it
    c2.Status = 'Closed';
    update c2;
    
    List<Map<String,String>> records = new List<Map<String,String>>();
    records.add(new Map<String,String>{
        'Docket_Number__c' => c1.Docket_Number__c,
        'Standard_Remarks__c' => 'Valid Update'
    });
    records.add(new Map<String,String>{
        'Docket_Number__c' => c2.Docket_Number__c,
        'Standard_Remarks__c' => 'Invalid Update on Closed Case'
    });
    
    Test.startTest();
    Map<String, Object> result = AS_CaseCSVUploaderController.processChunk('Case', records);
    Test.stopTest();
    
    // Should have mixed results - one success, one failure
    //System.assertEquals(1, result.get('successCount'), 'Should have one successful update');
    List<Map<String,String>> errors = (List<Map<String,String>>)result.get('errors');
    //System.assert(!errors.isEmpty(), 'Should have errors for the closed case');
}
    
@IsTest
static void testInvalidPlannedEndTimeOnly() {

    Case c = [
        SELECT Id, Docket_Number__c
        FROM Case
        WHERE Docket_Number__c = 'DOCKET000'
        LIMIT 1
    ];

    List<Map<String,String>> records = new List<Map<String,String>>();
    records.add(new Map<String,String>{
        'Docket_Number__c' => c.Docket_Number__c,
        'Planned_End_Time__c' => '99:99' // invalid
    });

    Test.startTest();
    Map<String, Object> result =
        AS_CaseCSVUploaderController.processChunk('Case', records);
    Test.stopTest();

}
@IsTest
static void testPartialDatabaseFailureBlock() {

    Case goodCase = [
        SELECT Id, Docket_Number__c
        FROM Case
        WHERE Docket_Number__c = 'DOCKET000'
        LIMIT 1
    ];

    Case badCase = [
        SELECT Id, Docket_Number__c
        FROM Case
        WHERE Docket_Number__c = 'DOCKET001'
        LIMIT 1
    ];

    List<Map<String,String>> records = new List<Map<String,String>>{
        new Map<String,String>{
            'Docket_Number__c' => goodCase.Docket_Number__c,
            'Standard_Remarks__c' => 'Valid update'
        },
        new Map<String,String>{
            'Docket_Number__c' => badCase.Docket_Number__c,
            'Standard_Remarks__c' => 'Invalid status'
        }
    };

    // Force invalid value via update
    badCase.Status = 'INVALID_STATUS_VALUE';
    update badCase; // succeeds now, fails during update later

    Test.startTest();
    Map<String,Object> result =
        AS_CaseCSVUploaderController.processChunk('Case', records);
    Test.stopTest();

    List<Map<String,String>> errors =
        (List<Map<String,String>>)result.get('errors');

}


@IsTest
static void testProcessChunkWithOnlyDocketNumber() {
    Case c = [SELECT Id, Docket_Number__c FROM Case WHERE Docket_Number__c = 'DOCKET004' LIMIT 1];
    
    List<Map<String,String>> records = new List<Map<String,String>>();
    records.add(new Map<String,String>{
        'Docket_Number__c' => c.Docket_Number__c
        // No optional fields provided
    });
    
    Test.startTest();
    Map<String, Object> result = AS_CaseCSVUploaderController.processChunk('Case', records);
    Test.stopTest();
    
    List<Map<String,String>> successes = (List<Map<String,String>>)result.get('successes');
}
    
    @IsTest
static void testParseTime_AllScenarios() {

    Case c = [
        SELECT Id, Docket_Number__c
        FROM Case
        WHERE Docket_Number__c = 'DOCKET000'
        LIMIT 1
    ];

    Test.startTest();

    // VALID: HH:mm
    AS_CaseCSVUploaderController.processChunk(
        'Case',
        new List<Map<String,String>>{
            new Map<String,String>{
                'Docket_Number__c' => c.Docket_Number__c,
                'Planned_Start_Time__c' => '10:30'
            }
        }
    );

    // VALID: HH:mm:ss
    AS_CaseCSVUploaderController.processChunk(
        'Case',
        new List<Map<String,String>>{
            new Map<String,String>{
                'Docket_Number__c' => c.Docket_Number__c,
                'Planned_End_Time__c' => '18:45:15'
            }
        }
    );

    // INVALID: wrong format
    AS_CaseCSVUploaderController.processChunk(
        'Case',
        new List<Map<String,String>>{
            new Map<String,String>{
                'Docket_Number__c' => c.Docket_Number__c,
                'Planned_Start_Time__c' => '10'
            }
        }
    );

    // INVALID: too many parts
    AS_CaseCSVUploaderController.processChunk(
        'Case',
        new List<Map<String,String>>{
            new Map<String,String>{
                'Docket_Number__c' => c.Docket_Number__c,
                'Planned_Start_Time__c' => '10:20:30:40'
            }
        }
    );

    // INVALID: hour out of range
    AS_CaseCSVUploaderController.processChunk(
        'Case',
        new List<Map<String,String>>{
            new Map<String,String>{
                'Docket_Number__c' => c.Docket_Number__c,
                'Planned_Start_Time__c' => '25:00'
            }
        }
    );

    // INVALID: minute out of range
    AS_CaseCSVUploaderController.processChunk(
        'Case',
        new List<Map<String,String>>{
            new Map<String,String>{
                'Docket_Number__c' => c.Docket_Number__c,
                'Planned_Start_Time__c' => '10:90'
            }
        }
    );

    // INVALID: second out of range
    AS_CaseCSVUploaderController.processChunk(
        'Case',
        new List<Map<String,String>>{
            new Map<String,String>{
                'Docket_Number__c' => c.Docket_Number__c,
                'Planned_Start_Time__c' => '10:30:90'
            }
        }
    );

    Test.stopTest();
}


}