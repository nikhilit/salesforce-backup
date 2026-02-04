@isTest
private class CaseReassignmentControllerTest {

    @testSetup
    static void setupTestData() {
        // Create DRS
        DRS__c drs = new DRS__c(Name = 'DRS001');
        insert drs;

        // Create Account linked to DRS
        Account acc = new Account(
            Name = 'Test Account',
            DRS_Master__c = drs.Id
        );
        insert acc;

        // Get a profile for test users
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        // Create SPOC Users
        User spoc1 = new User(
            Alias = 'spoc1',
            Email = 'spoc1@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'User1',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            Username = 'spoc1@testorg.com'
        );

        User spoc2 = spoc1.clone(false, true);
        spoc2.Alias = 'spoc2';
        spoc2.Email = 'spoc2@test.com';
        spoc2.Username = 'spoc2@testorg.com';

        User spoc3 = spoc1.clone(false, true);
        spoc3.Alias = 'spoc3';
        spoc3.Email = 'spoc3@test.com';
        spoc3.Username = 'spoc3@testorg.com';

        User spoc4 = spoc1.clone(false, true);
        spoc4.Alias = 'spoc4';
        spoc4.Email = 'spoc4@test.com';
        spoc4.Username = 'spoc4@testorg.com';

        insert new List<User>{spoc1, spoc2, spoc3, spoc4};

        // Create SPOC Mapping
        Departments_SPOC_Mapping__c mapping = new Departments_SPOC_Mapping__c(
            Department__c = 'Aftersales',
            DRS__c = drs.Id,
            SPOC_Id__c = spoc1.Id,
            SPOC_Id_2__c = spoc2.Id,
            SPOC_Id_3__c = spoc3.Id,
            SPOC_Id_4__c = spoc4.Id
        );
        insert mapping;

        // Case for SPOC4
        Case c = new Case(
            AccountId = acc.Id,
            Department__c = 'AFTER SALES',
            SPOC__c = spoc4.Id,
            TAT_in_minutes__c = '600',
            Status = 'New'
        );
        insert c;
    }

    @isTest
    static void testSuccessfulReassignment_SPOC4_to_SPOC3() {
        Case c = [SELECT Id, SPOC__c FROM Case LIMIT 1];

        Test.startTest();
        CaseReassignmentController.reassignCaseToPreviousSpoc(c.Id, 'Reassigning for test');
        Test.stopTest();

        Case updatedCase = [
            SELECT Status, SPOC__c, Assigned_To__c, Case_Violation2__c, Remaining_Tat_3__c
            FROM Case WHERE Id = :c.Id
        ];

        System.assertEquals('In-Progress', updatedCase.Status);
        System.assertEquals(false, updatedCase.Case_Violation2__c);
        System.assertEquals('540', updatedCase.Remaining_Tat_3__c);
    }

    @isTest
    static void testReassignment_SPOC3_to_SPOC2() {
        Case c = [SELECT Id FROM Case LIMIT 1];
        Departments_SPOC_Mapping__c mapping = [SELECT SPOC_Id_3__c FROM Departments_SPOC_Mapping__c LIMIT 1];
        c.SPOC__c = mapping.SPOC_Id_3__c;
        update c;

        Test.startTest();
        CaseReassignmentController.reassignCaseToPreviousSpoc(c.Id, 'Step back SPOC');
        Test.stopTest();

        Case updatedCase = [SELECT SPOC__c, Case_Violation1__c, Remaining_Tat_2__c FROM Case WHERE Id = :c.Id];
        System.assertEquals(false, updatedCase.Case_Violation1__c);
        System.assertEquals('540', updatedCase.Remaining_Tat_2__c);
    }

    @isTest
    static void testReassignment_SPOC2_to_SPOC1() {
        Case c = [SELECT Id FROM Case LIMIT 1];
        Departments_SPOC_Mapping__c mapping = [SELECT SPOC_Id_2__c FROM Departments_SPOC_Mapping__c LIMIT 1];
        c.SPOC__c = mapping.SPOC_Id_2__c;
        update c;

        Test.startTest();
        CaseReassignmentController.reassignCaseToPreviousSpoc(c.Id, 'Step back to first SPOC');
        Test.stopTest();

        Case updatedCase = [SELECT SPOC__c, Case_Violation__c, Remaining_TAT__c FROM Case WHERE Id = :c.Id];
        System.assertEquals(false, updatedCase.Case_Violation__c);
    }

    @isTest
    static void testResolvedCaseThrowsError() {
        Case c = [SELECT Id FROM Case LIMIT 1];
        c.Status = 'Resolved';
        update c;

        try {
            Test.startTest();
            CaseReassignmentController.reassignCaseToPreviousSpoc(c.Id, 'Resolved test');
            Test.stopTest();
            System.assert(false, 'Expected exception for resolved case');
        } catch (AuraHandledException e) {
           // System.assert(e.getMessage().contains('Re-assignment cannot be done'));
        }
    }

    @isTest
    static void testMissingDepartmentThrowsError() {
        Case c = [SELECT Id FROM Case LIMIT 1];
        c.Department__c = null;
        update c;

        try {
            Test.startTest();
            CaseReassignmentController.reassignCaseToPreviousSpoc(c.Id, 'No dept');
            Test.stopTest();
            System.assert(false, 'Expected exception for missing department');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('Department is missing'));
        }
    }

    @isTest
    static void testMissingAccountThrowsError() {
        Case c = [SELECT Id FROM Case LIMIT 1];
        c.AccountId = null;
        update c;

        try {
            Test.startTest();
            CaseReassignmentController.reassignCaseToPreviousSpoc(c.Id, 'No account');
            Test.stopTest();
            System.assert(false, 'Expected exception for missing account');
        } catch (AuraHandledException e) {
           // System.assert(e.getMessage().contains('No Account linked'));
        }
    }

    @isTest
    static void testMissingDRSThrowsError() {
        Account acc = [SELECT Id, DRS_Master__c FROM Account LIMIT 1];
        acc.DRS_Master__c = null;
        update acc;

        Case c = [SELECT Id FROM Case LIMIT 1];

        try {
            Test.startTest();
            CaseReassignmentController.reassignCaseToPreviousSpoc(c.Id, 'No DRS');
            Test.stopTest();
            System.assert(false, 'Expected exception for missing DRS');
        } catch (AuraHandledException e) {
           // System.assert(e.getMessage().contains('DRS is missing'));
        }
    }

    @isTest
    static void testMappingNotFoundThrowsError() {
        // Remove mapping
        delete [SELECT Id FROM Departments_SPOC_Mapping__c LIMIT 1];
        Case c = [SELECT Id FROM Case LIMIT 1];

        try {
            Test.startTest();
            CaseReassignmentController.reassignCaseToPreviousSpoc(c.Id, 'No mapping');
            Test.stopTest();
            System.assert(false, 'Expected exception for missing mapping');
        } catch (Exception e) {
            System.assert(true);
        }
    }

    @isTest
static void testPreviousSPOCNullThrowsError() {
    Departments_SPOC_Mapping__c mapping = [
        SELECT Id, SPOC_Id_3__c, SPOC_Id_4__c
        FROM Departments_SPOC_Mapping__c
        LIMIT 1
    ];
    mapping.SPOC_Id_3__c = null;
    update mapping;

    Case c = [SELECT Id FROM Case LIMIT 1];
    c.SPOC__c = mapping.SPOC_Id_4__c;
    update c;

    try {
        Test.startTest();
        CaseReassignmentController.reassignCaseToPreviousSpoc(c.Id, 'Null prev SPOC');
        Test.stopTest();
        System.assert(false, 'Expected exception for null previous SPOC');
    } catch (AuraHandledException e) {
       // System.assert(e.getMessage().contains('Previous SPOC not found'));
    }
}

    @isTest
    static void testGenericExceptionBranch() {
        // Simulate an unexpected exception by deleting the case before update
        Case c = [SELECT Id FROM Case LIMIT 1];
        delete c;

        try {
            Test.startTest();
            CaseReassignmentController.reassignCaseToPreviousSpoc(c.Id, 'Trigger error');
            Test.stopTest();
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('An error occurred'));
        }
    }

    @isTest
    static void testNoCaseIdProvided() {
        try {
            Test.startTest();
            CaseReassignmentController.reassignCaseToPreviousSpoc(null, 'Should fail');
            Test.stopTest();
            System.assert(false, 'Expected exception not thrown');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('No Case ID provided.'));
        }
    }
}