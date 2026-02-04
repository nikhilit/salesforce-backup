@IsTest
private class FRLPDFControllerTest {

    // Mock class for HTTP callouts
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"OK"}');
            res.setStatusCode(200);
            return res;
        }
    }

    @TestSetup
    static void setupTestData() {
        // Create SMS API configuration to avoid the error
        SmsApiConfig__c config = new SmsApiConfig__c(
            Name = 'Default',
            EndPoint__c = 'https://api.smsprovider.com/send',
            username__c = 'testUser',
            password__c = 'testPass',
            sender__c = 'MGLCRM',
            type__c = 'text'
        );
        insert config;
        
        Account acc = new Account(
            Name = 'Test Account',
            FirstName__c = 'John',
            LastName__c = 'Doe',
            Phone = '1234567890',
            Secondary_Telephone__c = '0987654321',
            BP_Number__c = 'BP123',
            Flat__c = '101',
            Floor__c = '5',
            Building_Name__c = 'Test Building',
            Street__c = 'Test Street',
            Street_Line_2__c = 'Test Line 2',
            Street_Line_3__c = 'Test Line 3',
            City__c = 'Test City',
            Postal_Code__c = '12345'
        );
        insert acc;

        Lead testLead = new Lead(
            FirstName = 'Lead',
            LastName = 'Test',
            Email = 'lead@test.com',
            Phone = '5555555555',
            Company = 'Test Company',
            Flat__c = '202',
            Floor__c = '10',
            Building_Name__c = 'Lead Building',
            Street__c = 'Lead Street',
            Street_Line_2__c = 'Lead Line 2',
            Street_Line_3__c = 'Lead Line 3',
            City__c = 'Lead City',
            Postal_Code__c = '67890'
        );
        insert testLead;

        Case csWithAccount = new Case(
            Subject = 'Test Case with Account',
            Status = 'New',
            AccountId = acc.Id
        );
        insert csWithAccount;

        Case csWithLead = new Case(
            Subject = 'Test Case with Lead',
            Status = 'New',
            Lead__c = testLead.Id
        );
        insert csWithLead;

        Case csWithoutOwner = new Case(
            Subject = 'Test Case without Owner',
            Status = 'New'
        );
        insert csWithoutOwner;
    }

    @IsTest
    static void testFRLPDFControllerConstructor() {
        Case testCase = [SELECT Id, AccountId FROM Case WHERE AccountId != null LIMIT 1];
id dataId=FRLTemplatesController.insertTemplateData('Test Template');
        // VF page context
        PageReference pageRef = Page.FRL_PDFGeneratorPage;
        Test.setCurrentPage(pageRef);

        ApexPages.currentPage().getParameters().put('caseId', testCase.Id);
        ApexPages.currentPage().getParameters().put('dataId',dataId );
        ApexPages.currentPage().getParameters().put('subject', 'Test Subject');

        // Set HTTP mock
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        FRLPDFController controller = new FRLPDFController();
        Test.stopTest();
    }

    @IsTest
    static void testFRLPDFControllerWithLead() {
        Case testCase = [SELECT Id, Lead__c FROM Case WHERE Lead__c != null LIMIT 1];
id dataId=FRLTemplatesController.insertTemplateData('Test Template');
        PageReference pageRef = Page.FRL_PDFGeneratorPage;
        Test.setCurrentPage(pageRef);

        ApexPages.currentPage().getParameters().put('caseId', testCase.Id);
        ApexPages.currentPage().getParameters().put('dataId', dataId);
        ApexPages.currentPage().getParameters().put('subject', 'Test Subject');

        Test.startTest();
        FRLPDFController controller = new FRLPDFController();
        Test.stopTest();
    }

    @IsTest
    static void testFRLPDFControllerWithoutOwner() {
        Case testCase = [SELECT Id FROM Case WHERE AccountId = null AND Lead__c = null LIMIT 1];

        PageReference pageRef = Page.FRL_PDFGeneratorPage;
        Test.setCurrentPage(pageRef);
id dataId=FRLTemplatesController.insertTemplateData('Test Template');
        ApexPages.currentPage().getParameters().put('caseId', testCase.Id);
        ApexPages.currentPage().getParameters().put('dataId', dataId);
        ApexPages.currentPage().getParameters().put('subject', 'Test Subject');

        Test.startTest();
        FRLPDFController controller = new FRLPDFController();
        Test.stopTest();
    }

    @IsTest
    static void testFRLPDFControllerNoCaseId() {
        PageReference pageRef = Page.FRL_PDFGeneratorPage;
        Test.setCurrentPage(pageRef);
id dataId=FRLTemplatesController.insertTemplateData('Test Template');
        ApexPages.currentPage().getParameters().put('templateBody', 'Test Template');
        ApexPages.currentPage().getParameters().put('subject', 'Test Subject');
ApexPages.currentPage().getParameters().put('dataId', dataId);
        Test.startTest();
        FRLPDFController controller = new FRLPDFController();
        Test.stopTest();
    }

    @IsTest
    static void testAddressHtmlPropertyWithAccount() {
        Case testCase = [SELECT Id, AccountId FROM Case WHERE AccountId != null LIMIT 1];
id dataId=FRLTemplatesController.insertTemplateData('Test Template');
        PageReference pageRef = Page.FRL_PDFGeneratorPage;
        Test.setCurrentPage(pageRef);

        ApexPages.currentPage().getParameters().put('caseId', testCase.Id);
 ApexPages.currentPage().getParameters().put('dataId', dataId);
        Test.startTest();
        FRLPDFController controller = new FRLPDFController();
        String addressHtml = controller.addressHtml;
        Test.stopTest();
    }

    @IsTest
    static void testAddressHtmlPropertyWithLead() {
        Case testCase = [SELECT Id, Lead__c FROM Case WHERE Lead__c != null LIMIT 1];
id dataId=FRLTemplatesController.insertTemplateData('Test Template');
        PageReference pageRef = Page.FRL_PDFGeneratorPage;
        Test.setCurrentPage(pageRef);

        ApexPages.currentPage().getParameters().put('caseId', testCase.Id);
ApexPages.currentPage().getParameters().put('dataId', dataId);
        Test.startTest();
        FRLPDFController controller = new FRLPDFController();
        String addressHtml = controller.addressHtml;
        Test.stopTest();
    }

    @IsTest
    static void testAddressHtmlPropertyNoOwner() {
        Case testCase = [SELECT Id FROM Case WHERE AccountId = null AND Lead__c = null LIMIT 1];
id dataId=FRLTemplatesController.insertTemplateData('Test Template');
        PageReference pageRef = Page.FRL_PDFGeneratorPage;
        Test.setCurrentPage(pageRef);

        ApexPages.currentPage().getParameters().put('caseId', testCase.Id);
ApexPages.currentPage().getParameters().put('dataId', dataId);
        Test.startTest();
        FRLPDFController controller = new FRLPDFController();
        String addressHtml = controller.addressHtml;
        Test.stopTest();
    }

    @IsTest
    static void testEscapeHtmlMethod() {
        Test.startTest();
        String result1 = FRLPDFController.escapeHtml(null);
        String result2 = FRLPDFController.escapeHtml('Test & String < with > special " characters \'');
        String result3 = FRLPDFController.escapeHtml('Normal string');
        Test.stopTest();
    }

    @IsTest
    static void testGetCaseAccountInfoWithAccount() {
        Case testCase = [SELECT Id, AccountId FROM Case WHERE AccountId != null LIMIT 1];

        Test.startTest();
        Map<String, Object> result = FRLPDFController.getCaseAccountInfo(testCase.Id);
        Test.stopTest();
    }

    @IsTest
    static void testGetCaseAccountInfoWithLead() {
        Case testCase = [SELECT Id, Lead__c FROM Case WHERE Lead__c != null LIMIT 1];

        Test.startTest();
        Map<String, Object> result = FRLPDFController.getCaseAccountInfo(testCase.Id);
        Test.stopTest();
    }

    @IsTest
    static void testGetCaseAccountInfoWithoutOwner() {
        Case testCase = [SELECT Id FROM Case WHERE AccountId = null AND Lead__c = null LIMIT 1];

        Test.startTest();
        Map<String, Object> result = FRLPDFController.getCaseAccountInfo(testCase.Id);
        Test.stopTest();
    }

    @IsTest
    static void testGetCaseAccountInfoWithNullValues() {
        Account acc = new Account(Name = 'Test Account Only');
        insert acc;

        Case cs = new Case(Subject = 'Test Case', Status = 'New', AccountId = acc.Id,Docket_Number__c='456');
        insert cs;

        Test.startTest();
        Map<String, Object> result = FRLPDFController.getCaseAccountInfo(cs.Id);
        Test.stopTest();
    }

    @IsTest
    static void testGetCaseAccountInfoWithLeadNullValues() {
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company'
        );
        insert testLead;

        Case cs = new Case(Subject = 'Test Case', Status = 'New', Lead__c = testLead.Id,Docket_Number__c='123');
        insert cs;

        Test.startTest();
        Map<String, Object> result = FRLPDFController.getCaseAccountInfo(cs.Id);
        Test.stopTest();
    }
    
    @IsTest
    static void testFRLPDFControllerNoParameters() {
        PageReference pageRef = Page.FRL_PDFGeneratorPage;
        id dataId=FRLTemplatesController.insertTemplateData('Test Template');
        Test.setCurrentPage(pageRef);
		ApexPages.currentPage().getParameters().put('dataId',dataId);
        Test.startTest();
        FRLPDFController controller = new FRLPDFController();
        Test.stopTest();
    }
    
    @IsTest
    static void testFRLPDFControllerWithTemplateBodyOnly() {
        Case testCase = [SELECT Id FROM Case WHERE AccountId != null LIMIT 1];
id dataId=FRLTemplatesController.insertTemplateData('Test Template');
        PageReference pageRef = Page.FRL_PDFGeneratorPage;
        Test.setCurrentPage(pageRef);

        ApexPages.currentPage().getParameters().put('caseId', testCase.Id);
        ApexPages.currentPage().getParameters().put('dataId', dataId);

        Test.startTest();
        FRLPDFController controller = new FRLPDFController();
        Test.stopTest();
    }
    
    @IsTest
    static void testFRLPDFControllerWithSubjectOnly() {
        Case testCase = [SELECT Id FROM Case WHERE AccountId != null LIMIT 1];
id dataId=FRLTemplatesController.insertTemplateData('Test Template');
        PageReference pageRef = Page.FRL_PDFGeneratorPage;
        Test.setCurrentPage(pageRef);

        ApexPages.currentPage().getParameters().put('caseId', testCase.Id);
        ApexPages.currentPage().getParameters().put('subject', 'Test Subject');
ApexPages.currentPage().getParameters().put('dataId', dataId);
        Test.startTest();
        FRLPDFController controller = new FRLPDFController();
        Test.stopTest();
    }
}