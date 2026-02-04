@isTest
private class CaseSearchControllerTest {

    @testSetup
    static void setupTestData() {
        // Setup sample SMS API config (if used elsewhere)
        SmsApiConfig__c config = new SmsApiConfig__c(
            Name = 'Default',
            EndPoint__c = 'https://api.smsprovider.com/send',
            username__c = 'testUser',
            password__c = 'testPass',
            sender__c = 'MGLCRM',
            type__c = 'text'
        );
        insert config;

        // Create Account
        Account acc = new Account(
            FirstName__c = 'Test',
            LastName__c = 'User',
            Name = 'Test User',
            Contract_Account__c = 'CA001',
            BP_Number__c = 'BP001',
            Phone = '9999999999',
            Account_Email__c = 'test.user@example.com',
            Connection_Object__c = 'CONN001'
        );
        insert acc;

        // Create Lead
        Lead lead = new Lead(
            FirstName = 'Lead',
            LastName = 'User',
            Company = 'Test Company',
            Phone = '8888888888',
            Email = 'lead.user@example.com'
        );
        insert lead;

        // Create Cases
        Case c1 = new Case(
            AccountId = acc.Id,
            Origin = 'Phone',
            //Category__c = 'Query',
            Status = 'New',
            Subject = 'Account Case'
        );
        Case c2 = new Case(
            Lead__c = lead.Id,
            Origin = 'Email',
            //Category__c = 'Request',
            Status = 'New',
            Subject = 'Lead Case'
        );
        insert new List<Case>{c1, c2};

        // Move_In_Out__c record for CA number logic
        Move_In_Out__c mio = new Move_In_Out__c(
            Contract_Account__c = 'CA001',
            Business_Partner__c = 'BP001'
        );
        insert mio;
    }

    @isTest
    static void testSearchCasesByCaseNumberOnly() {
        Case c = [SELECT CaseNumber FROM Case LIMIT 1];

        Test.startTest();
        List<Case> results = CaseSearchController.searchCases('', '', '', '', '', '', '', c.CaseNumber);
        Test.stopTest();

        System.assert(!results.isEmpty(), 'Should return case by CaseNumber');
    }

    @isTest
    static void testSearchCasesBySingleField() {
        Test.startTest();
        System.assert(!CaseSearchController.searchCases('Test', '', '', '', '', '', '', '').isEmpty(), 'Search by first name');
        System.assert(!CaseSearchController.searchCases('', 'User', '', '', '', '', '', '').isEmpty(), 'Search by last name');
        System.assert(!CaseSearchController.searchCases('', '', 'CA001', '', '', '', '', '').isEmpty(), 'Search by CA');
        System.assert(!CaseSearchController.searchCases('', '', '', 'BP001', '', '', '', '').isEmpty(), 'Search by BP');
        System.assert(!CaseSearchController.searchCases('', '', '', '', '', '', 'test.user@example.com', '').isEmpty(), 'Search by email');
        System.assert(!CaseSearchController.searchCases('', '', '', '', '', 'CONN001', '', '').isEmpty(), 'Search by connection');
        Test.stopTest();
    }

    @isTest
    static void testSearchCasesByMultipleFields() {
        Test.startTest();
        List<Case> results = CaseSearchController.searchCases(
            'Test', 'User', 'CA001', 'BP001', '9999999999', 'CONN001', 'test.user@example.com', ''
        );
        Test.stopTest();
    }

    @isTest
    static void testSearchCasesWithCaseNumberAndOtherFields() {
        Case c = [SELECT CaseNumber FROM Case WHERE AccountId != null LIMIT 1];

        Test.startTest();
        List<Case> results1 = CaseSearchController.searchCases('Test', '', '', '', '', '', '', c.CaseNumber);
        List<Case> results2 = CaseSearchController.searchCases('Wrong', '', '', '', '', '', '', c.CaseNumber);
        Test.stopTest();

        System.assert(!results1.isEmpty(), 'Should return matching case by CaseNumber');
        System.assertEquals(0, results2.size(), 'Invalid combo should return none');
    }

    @isTest
    static void testLeadFallbackSearch() {
        Test.startTest();
        List<Case> results = CaseSearchController.searchCases(
            'Lead', 'User', '', '', '8888888888', '', 'lead.user@example.com', ''
        );
        Test.stopTest();

        System.assert(!results.isEmpty(), 'Should fallback to lead-based search');
    }

    @isTest
    static void testEmptyInputsReturnEmptyList() {
        Test.startTest();
        List<Case> results = CaseSearchController.searchCases('', '', '', '', '', '', '', '');
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Empty input should return empty list');
    }

    @isTest
    static void testGetCasesByPhone() {
        Test.startTest();
        List<Case> results1 = CaseSearchController.getCasesByPhone('9999999999');
        List<Case> results2 = CaseSearchController.getCasesByPhone('8888888888');
        List<Case> results3 = CaseSearchController.getCasesByPhone('0000000000');
        Test.stopTest();

        System.assert(!results2.isEmpty(), 'Should return lead cases');
        System.assertEquals(0, results3.size(), 'Should return empty list for non-matching phone');
    }

    @isTest
    static void testGetCategoryOptions() {
        Test.startTest();
        List<CaseSearchController.PicklistOption> options = CaseSearchController.getCategoryOptions();
        Test.stopTest();

        System.assert(!options.isEmpty(), 'Category options should not be empty');
        System.assertNotEquals(null, options[0].label, 'Label should not be null');
    }
}