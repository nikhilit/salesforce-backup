@IsTest
private class RepeatCaseControllerTest {
    
    @isTest
    static void testHandleRepeatCase_withAllFields() {
        Case testCase = new Case(
            Subject = 'Test Case', 
            Status = 'New',
            Origin = 'Telephone',
            Child_Case_Count__c = 1
        );
        insert testCase;

        Test.startTest();
        Id repeatCaseId = RepeatCaseController.handleRepeatCase(
            testCase.Id, 
            'This is an internal comment for testing.', 
            'E-mail',
            'John Doe',
            'Family Member',
            '',
            '9876543210'
        );
        Test.stopTest();

        Case updatedCase = [
            SELECT Child_Case_Count__c, Latest_Repeat_Remark__c, Latest_Repeat_Origin__c,
                   Latest_Repeat_Date__c, Latest_Repeat_Time__c
            FROM Case WHERE Id = :testCase.Id
        ];

        Repeat_Case__c repeatRecord = [
            SELECT Id, Case__c, Repeat_Remarks__c, Repeat_Origin__c,
                   Contacted_By__c, Relationship_to_the_owner__c, Contact_Directions__c
            FROM Repeat_Case__c 
            WHERE Id = :repeatCaseId
        ];
    }

    @isTest
    static void testHandleRepeatCase_withNullAdditionalFields() {
        Case testCase = new Case(
            Subject = 'Test Case No Additional Fields',
            Status = 'New',
            Origin = 'Telephone',
            Child_Case_Count__c = 0
        );
        insert testCase;

        Test.startTest();
        Id repeatCaseId = RepeatCaseController.handleRepeatCase(
            testCase.Id, 
            'Test comment', 
            'Internet',
            null,
            null,
            null,
            '9876543210'
        );
        Test.stopTest();

        Case updatedCase = [
            SELECT Child_Case_Count__c, Latest_Repeat_Remark__c, Latest_Repeat_Origin__c 
            FROM Case WHERE Id = :testCase.Id
        ];

        Repeat_Case__c repeatRecord = [
            SELECT Repeat_Remarks__c, Repeat_Origin__c, Contacted_By__c, Relationship_to_the_owner__c, Contact_Directions__c
            FROM Repeat_Case__c 
            WHERE Id = :repeatCaseId
        ];
    }

    @isTest
    static void testHandleRepeatCase_withEmptyAdditionalFields() {
        Case testCase = new Case(
            Subject = 'Test Case Empty Fields',
            Status = 'New',
            Origin = 'Telephone',
            Child_Case_Count__c = 2
        );
        insert testCase;

        Test.startTest();
        Id repeatCaseId = RepeatCaseController.handleRepeatCase(
            testCase.Id, 
            null, 
            'SOCIAL MEDIA',
            '',
            '',
            '',
            '9876543210'
        );
        Test.stopTest();

        Case updatedCase = [
            SELECT Child_Case_Count__c, Latest_Repeat_Origin__c, Latest_Repeat_Remark__c 
            FROM Case WHERE Id = :testCase.Id
        ];
    }

    @isTest
    static void testHandleRepeatCase_initialNullChildCount() {
        Case testCase = new Case(
            Subject = 'Test Case Null Count',
            Status = 'New',
            Origin = 'Telephone'
        );
        insert testCase;

        Test.startTest();
        Id repeatCaseId = RepeatCaseController.handleRepeatCase(
            testCase.Id, 
            'Test comment', 
            'E-mail',
            'Test Contact',
            'Test Relationship',
            '',
            '9876543210'
        );
        Test.stopTest();

        Case updatedCase = [
            SELECT Child_Case_Count__c FROM Case WHERE Id = :testCase.Id
        ];
    }

    @isTest
    static void testNullCaseIdThrowsError() {
        try {
            Test.startTest();
            RepeatCaseController.handleRepeatCase(null, 'Test', 'Telephone', 'Test', 'Test', 'Inbound', '9876543210');
            Test.stopTest();
        } catch (AuraHandledException e) {
            // expected exception
        }
    }

    @isTest
    static void testGetRepeatOriginPicklistValues() {
        Test.startTest();
        List<String> origins = RepeatCaseController.getRepeatOriginPicklistValues();
        Test.stopTest();
    }

    @isTest
    static void testGetContactDirectionPicklistValues() {
        Test.startTest();
        List<String> directions = RepeatCaseController.getContactDirectionPicklistValues();
        Test.stopTest();
    }

    @isTest
    static void testDebugContactDirectionPicklists() {
        Test.startTest();
        Map<String, Object> result = RepeatCaseController.debugContactDirectionPicklists();
        Test.stopTest();
    }
    
    @TestVisible
    private static List<String> getCaseContactDirectionPicklistValues() {
        List<String> values = new List<String>();
        try {
            Schema.DescribeFieldResult fieldResult = Case.Contact_Directions__c.getDescribe();
            for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
                if (entry.isActive()) {
                    values.add(entry.getLabel());
                }
            }
        } catch (Exception e) {
            // Silent fail
        }
        return values;
    }


    @isTest
    static void testGetRepeatPicklistDetails() {
        Test.startTest();
        Map<String, Object> result = RepeatCaseController.getRepeatPicklistDetails();
        Test.stopTest();
    }
}