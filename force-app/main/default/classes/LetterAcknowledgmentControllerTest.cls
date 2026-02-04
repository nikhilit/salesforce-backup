@isTest
private class LetterAcknowledgmentControllerTest {
    
    @isTest
    static void testControllerWithCaseId() {
        // Create test Account
        Account testAccount = new Account(
            Name = 'Test Account',
            Full_Name__c = 'Test Customer',
            Person_Title__c = 'Mr.',
            Room__c = '101',
            Flat__c = 'A1',
            Floor__c = '5',
            Supplement__c = 'East Wing',
            Street__c = 'Test Street',
            Other_City__c = 'Mumbai West',
            District__c = 'Test District',
            Postal_Code__c = '400001',
            Phone = '9876543210',
            BP_Number__c = 'BP123456'
        );
        insert testAccount;

        // Create Case
        Case testCase = new Case(
            Subject = 'Test Case',
            Status = 'New',
            Origin = 'Phone',
            Priority = 'Medium',
            Type = 'Complaint',
            AccountId = testAccount.Id
        );
        insert testCase;

        // Set VF page params
        PageReference pageRef = Page.LetterAcknowledgmentPDF;
        pageRef.getParameters().put('id', testCase.Id);
        pageRef.getParameters().put('objectType', 'Account');
        pageRef.getParameters().put('templateBody', 'Test Template Body');
        Test.setCurrentPage(pageRef);

        Test.startTest();
        LetterAcknowledgmentController controller = new LetterAcknowledgmentController();
        String ref = controller.referenceNumber;
        String todayDate = controller.today;
        String caseNum = controller.getCaseNumber();
        String subject = controller.getCaseSubject();
        String type = controller.getCaseType();
        String cat = controller.getCaseCategory();
        String pri = controller.getCasePriority();
        String orig = controller.getCaseOrigin();
        String owner = controller.getCaseOwner();
        String created = controller.getCaseCreatedDate();
        Test.stopTest();

        System.assertNotEquals('', ref);
        System.assertNotEquals('', todayDate);
        System.assertNotEquals('', caseNum);
    }

    @isTest
    static void testControllerWithLead() {
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Phone = '9876543210',
            Email = 'test@test.com',
            Building_Name__c = 'Lead Building',
            Flat__c = 'B2',
            Floor__c = '3',
            Street = 'Lead Street',
            City = 'Mumbai',
            PostalCode = '400002'
        );
        insert testLead;

        Case testCase = new Case(
            Subject = 'Lead Case',
            Status = 'New',
            Origin = 'Web',
            Priority = 'High',
            Type = 'Request',
            Lead__c = testLead.Id
        );
        insert testCase;

        PageReference pageRef = Page.LetterAcknowledgmentPDF;
        pageRef.getParameters().put('id', testCase.Id);
        pageRef.getParameters().put('objectType', 'Lead');
        pageRef.getParameters().put('templateBody', 'Lead Body');
        Test.setCurrentPage(pageRef);

        Test.startTest();
        LetterAcknowledgmentController controller = new LetterAcknowledgmentController();
        String ref = controller.referenceNumber;
        String todayDate = controller.today;
        String owner = controller.getCaseOwner();
        String subject = controller.getCaseSubject();
        String type = controller.getCaseType();
        Test.stopTest();

        System.assertNotEquals('', ref);
        System.assertNotEquals('', todayDate);
        System.assertNotEquals('', subject);
    }

    @isTest
    static void testControllerWithoutCaseId() {
        PageReference pageRef = Page.LetterAcknowledgmentPDF;
        Test.setCurrentPage(pageRef);

        Test.startTest();
        LetterAcknowledgmentController controller = new LetterAcknowledgmentController();
        String ref = controller.referenceNumber;
        String todayDate = controller.today;
        Test.stopTest();

        //System.assertEquals(true, ref.contains('MGL/CRM/'));
       // System.assertNotEquals('', todayDate);
    }

    @isTest
    static void testReferenceNumberCalculation() {
        Case testCase = new Case(
            Subject = 'Ref Case',
            Status = 'New',
            Origin = 'Email'
        );
        insert testCase;

        PageReference pageRef = Page.LetterAcknowledgmentPDF;
        pageRef.getParameters().put('id', testCase.Id);
        Test.setCurrentPage(pageRef);

        Test.startTest();
        LetterAcknowledgmentController controller = new LetterAcknowledgmentController();
        String ref = controller.referenceNumber;
        Test.stopTest();

        System.assert(ref.startsWith('MGL/CRM/'));
    }

    @isTest
    static void testConstructorWithCaseParameter() {
        Case testCase = new Case(
            Subject = 'Constructor Case',
            Status = 'New',
            Origin = 'Phone'
        );
        insert testCase;

        Test.startTest();
        LetterAcknowledgmentController controller = new LetterAcknowledgmentController(testCase);
        String ref = controller.referenceNumber;
        String todayDate = controller.today;
        Test.stopTest();

        System.assertNotEquals('', ref);
        System.assertNotEquals('', todayDate);
    }

    @isTest
    static void testConstructorWithNullCase() {
        Test.startTest();
        LetterAcknowledgmentController controller = new LetterAcknowledgmentController(null);
        String ref = controller.referenceNumber;
        Test.stopTest();

        System.assertNotEquals(null, ref);
    }

    @isTest
    static void testCaseWithoutAccountOrLead() {
        Case testCase = new Case(
            Subject = 'Case No Relation',
            Status = 'New',
            Origin = 'Phone'
        );
        insert testCase;

        PageReference pageRef = Page.LetterAcknowledgmentPDF;
        pageRef.getParameters().put('id', testCase.Id);
        Test.setCurrentPage(pageRef);

        Test.startTest();
        LetterAcknowledgmentController controller = new LetterAcknowledgmentController();
        String ref = controller.referenceNumber;
        String todayDate = controller.today;
        String subject = controller.getCaseSubject();
        String owner = controller.getCaseOwner();
        Test.stopTest();

        System.assertNotEquals('', ref);
        System.assertNotEquals('', todayDate);
    }
}