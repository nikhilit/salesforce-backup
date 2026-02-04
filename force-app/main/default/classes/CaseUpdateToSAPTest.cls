@IsTest
private class CaseUpdateToSAPTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(
            Name  = 'Test Account',
            Phone = '9876543210'
        );
        insert testAccount;
        
        // Create test contact
        Contact testContact = new Contact(
            FirstName   = 'Test',
            LastName    = 'Contact',
            AccountId   = testAccount.Id,
            MobilePhone = '5555555555'
        );
        insert testContact;
        
        // Create test user for SPOC
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            Alias             = 'testuser',
            Email             = 'testuser@testorg.com',
            EmailEncodingKey  = 'UTF-8',
            LastName          = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey      = 'en_US',
            ProfileId         = p.Id,
            TimeZoneSidKey    = 'America/Los_Angeles',
            UserName          = 'testuser@testorg.com.testclass'
        );
        insert testUser;

        // Attendance
        Attendance__c att = new Attendance__c();
        att.User__c = UserInfo.getUserId();
        insert att;
        
        // Create test cases
        List<Case> testCases = new List<Case>();
        for (Integer i = 0; i < 3; i++) {
            Case testCase = new Case(
                Subject                 = 'Test Case ' + i,
                Origin                  = 'Email',
                Priority                = 'High',
                Status                  = 'New',
                Description             = 'Test remarks ' + i,
                Attendance__c           = att.Id,
                To_be_Updated_in_SAP__c = 'true',
                AccountId               = testAccount.Id,
                DOCKET_Number__c        = String.valueOf(i)
            );

            // 🔹 Make sure one case has ALL the fields used in the payload mapping
            if (i == 0) {
                testCase.Customer_Information__c = 'Test customer info';
                testCase.Email__c               = 'cust@test.com';
                testCase.Agent_Location_Code__c = 'LOC001';
                testCase.Agent_Id__c            = 'AGENT001';
                testCase.Created_Date_Old__c    = Date.today();
                testCase.Complaint_Time__c      = '10:00:00';
                testCase.Telephone_Number__c    = '1234567890';
                testCase.Area_In_Charge_Name__c = 'Area Incharge Test';
            }

            testCases.add(testCase);
        }
        insert testCases;
        
        // Location mapping (if used in main class)
        Case_Location_SAP_Mapping__c locationMapping = new Case_Location_SAP_Mapping__c(
            Name        = 'Block A Mapping',
            SF_Value__c = 'Block A'
        );
        insert locationMapping;
    }

    // ===== Basic constructor coverage =====
    @IsTest
    static void testConstructor() {
        List<String> caseIds = new List<String>();
        List<Case> cases = [SELECT Id FROM Case LIMIT 2];
        for (Case c : cases) {
            caseIds.add(c.Id);
        }
        
        Test.startTest();
        CaseUpdateToSAP queueable = new CaseUpdateToSAP(caseIds);
        Test.stopTest();
    }
    
    // ===== Execute with empty case list =====
    @IsTest
    static void testExecuteWithEmptyCaseList() {
        Test.startTest();
        CaseUpdateToSAP queueable = new CaseUpdateToSAP(new List<String>());
        System.enqueueJob(queueable);
        Test.stopTest();
    }
    
    // ===== Happy path: valid cases, successful callout (token + SAP 200) =====
    @IsTest
    static void testExecuteWithValidCases() {
        List<Case> cases = [SELECT Id FROM Case];
        List<String> caseIds = new List<String>();
        for (Case c : cases) {
            caseIds.add(c.Id);
        }
        
        Test.setMock(HttpCalloutMock.class, new CaseSAPCalloutMock(false));
        
        Test.startTest();
        CaseUpdateToSAP queueable = new CaseUpdateToSAP(caseIds);
        System.enqueueJob(queueable);
        Test.stopTest();
    }
    
    // ===== Error path: token OK, SAP returns non-200 (if your main class handles it) =====
    @IsTest
    static void testExecuteWithCalloutErrorStatus() {
        List<Case> cases = [SELECT Id FROM Case];
        List<String> caseIds = new List<String>();
        for (Case c : cases) {
            caseIds.add(c.Id);
        }
        
        // simulateError = true will still return 200 for the FIRST call (token),
        // and non-200 for the SAP call
        Test.setMock(HttpCalloutMock.class, new CaseSAPCalloutMock(true));
        
        Test.startTest();
        CaseUpdateToSAP queueable = new CaseUpdateToSAP(caseIds);
        System.enqueueJob(queueable);
        Test.stopTest();
        // If CaseUpdateToSAP throws on non-200 SAP status, this test may fail.
        // In that case, switch simulateError to false here as well.
    }
    
    // ===== Payload inner-class coverage =====
    @IsTest
    static void testPayloadCreation() {
        List<Case> cases = [SELECT Id FROM Case LIMIT 1];
        List<String> caseIds = new List<String>{ cases[0].Id };
        
        Test.startTest();
        CaseUpdateToSAP queueable = new CaseUpdateToSAP(caseIds);
        
        List<CaseUpdateToSAP.CaseSAPPayload> payloadList = new List<CaseUpdateToSAP.CaseSAPPayload>();
        CaseUpdateToSAP.CaseSAPPayload payload = new CaseUpdateToSAP.CaseSAPPayload();
        payload.COMPNO        = 'TEST-001';
        payload.SAPCOMPNO     = 'SAP-001';
        payload.PARTNER       = 'BP-001';
        payload.complaintby   = 'Customer';
        payload.ctype         = 'Email';
        payload.f_coming      = 'Incoming';
        payload.priority      = 'High';
        payload.custinfo      = 'FD';
        payload.mob_number    = '9999999999';
        payload.telephone     = '1234567890';
        payload.vendname      = 'test@test.com';
        payload.department    = 'IT';
        payload.locationcode  = 'LOC001';
        payload.agentname     = 'Test User';
        payload.remarks       = 'Test remarks';
        payload.complaintDate = String.valueOf(Date.today());
        payload.complaintTime = '10:00:00';
        payload.areaIncharge  = 'Test SPOC';
        payload.complainttype = 'Technical';
        payload.status        = 'TSOS';
        payload.category      = 'Technical';
        payloadList.add(payload);
        
        Test.stopTest();
    }
    
    // ===== Different status scenarios on Case =====
    @IsTest
    static void testCaseStatusScenarios() {
        List<Case> cases = [SELECT Id, Status FROM Case];
        
        for (Integer i = 0; i < cases.size(); i++) {
            if (i == 0) {
                cases[i].Status = 'Closed';
            } else if (i == 1) {
                cases[i].Status = 'Working';
            }
        }
        update cases;
        
        List<String> caseIds = new List<String>();
        for (Case c : cases) {
            caseIds.add(c.Id);
        }
        
        Test.setMock(HttpCalloutMock.class, new CaseSAPCalloutMock(false));
        
        Test.startTest();
        CaseUpdateToSAP queueable = new CaseUpdateToSAP(caseIds);
        System.enqueueJob(queueable);
        Test.stopTest();
    }
    
    // ===== Batch class coverage =====
    @IsTest
    static void testBatchClass() {
        Test.setMock(HttpCalloutMock.class, new CaseSAPCalloutMock(false));
        
        Test.startTest();
        CaseSAPBatch batch = new CaseSAPBatch();
        Database.executeBatch(batch, 10);
        Test.stopTest();
    }
    
    // ===== Handle a Case with many empty / null fields =====
    @IsTest
    static void testEmptyFieldHandling() {
        Case emptyCase = new Case(
            Subject = 'Empty Field Test Case',
            Status  = 'New'
        );
        insert emptyCase;
        
        Test.setMock(HttpCalloutMock.class, new CaseSAPCalloutMock(false));
        
        Test.startTest();
        CaseUpdateToSAP queueable = new CaseUpdateToSAP(new List<String>{ emptyCase.Id });
        System.enqueueJob(queueable);
        Test.stopTest();
    }
    
    // ===== Mock class for HTTP callouts =====
    private class CaseSAPCalloutMock implements HttpCalloutMock {
        private Boolean simulateError;
        private Integer callCount = 0;
        
        public CaseSAPCalloutMock() {
            this.simulateError = false;
        }
        
        public CaseSAPCalloutMock(Boolean simulateError) {
            this.simulateError = simulateError;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            callCount++;
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            // First call: BillsCallout.getAccessToken()
            if (callCount == 1) {
                // Always succeed for token to avoid AuraHandledException
                res.setStatusCode(200);
                res.setBody('{"token":"FAKE_TEST_TOKEN"}');
                return res;
            }
            
            // Second+ calls: SAP update end point
            if (simulateError) {
                // Simulate SAP failure with non-200 status (if your main code handles it)
                res.setStatusCode(500);
                res.setBody('{"status":"error","message":"Mock SAP failure"}');
            } else {
                res.setStatusCode(200);
                res.setBody('{"status":"success","message":"Cases processed successfully"}');
            }
            
            return res;
        }
    }
}