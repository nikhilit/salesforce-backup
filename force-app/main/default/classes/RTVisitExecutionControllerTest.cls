@isTest
private class RTVisitExecutionControllerTest {
    
    static Id testWorkOrderId;
    static String testWorkStepName = 'Check In';
    
    @testSetup
    static void setupData() {
        Account acc = new Account(
            Name = 'Test Account',
            Phone = '9876543210',
            Secondary_Telephone__c = '1234567890',
            Account_Email__c = 'test@test.com',
            Account_Type__c = 'Business Account',
            Type = 'Customer',
            MRU_Code__c = 'MRU123',
            BP_Number__c = 'BP123',
            CA_Number__c = 'CA123',
            Building_name__c = 'Test Building',
            Street__c = 'Test Street',
            Colony__c = 'Test Colony',
            Wing__c = 'A',
            Floor__c = '1',
            Flat__c = '101',
            Road_name__c = 'Test Road',
            Portion__c = 'Left',
            BillingPostalCode = '123456',
            Location__c = 'Test Loc',
            Email_Id__c = 'acc@test.com'
        );
        insert acc;
        
        WorkOrder wo = new WorkOrder(
            AccountId = acc.Id,
            Subject = 'Test WO',
            Status = 'New',
            Due_Amount__c = 100
            // Customer_CA_Number__c = acc.CA_Number__c
        );
        insert wo;
        testWorkOrderId = wo.Id;
        
        ServiceAppointment sa = new ServiceAppointment(
            ParentRecordId = wo.Id,
            Status = 'New',
            SchedStartTime = System.now(),
            SchedEndTime = System.now().addHours(1)
        );
        insert sa;
        
        Billing__c bill = new Billing__c(
            Account__c = acc.Id,
            Due_Amount__c = 200,
            Bill_Date__c = Date.today()
        );
        insert bill;
        
        Payment__c pay = new Payment__c(
            Work_Order__c = wo.Id,
            Amount_Paid__c = 50,
            Payment_Date__c = Date.today()
        );
        insert pay;
        Case_Type_SMS__c smsTemplate = new Case_Type_SMS__c(
            Status__c = 'Approved',
            Template_Id__c = '1007554892533694087',
            Message__c = 'Dear MGL Customer, PNG bill for {!BillDate} is Rs {!Amount} to be paid by {!AccountName}. Please click {!pdfLink} to view & pay digitally. Thank you.',
            Active__c = true,
            Template_Name__c = 'view_bill',
            Sender__c = 'MGLLTD'
        );
        insert smsTemplate;
        Bank_Detail__c bank = new Bank_Detail__c(
            Name = 'MICR123',
            BANK__c = 'Test Bank',
            BRANCH__c = 'Test Branch',
            IFSC__c = 'IFSC0001'
        );
        insert bank;
    }
    
    @isTest
    static void test_getAccountInfoFromSA() {
        WorkOrder wo = [SELECT Id, AccountId, Account.Name, Account.Phone, Due_Amount__c, Customer_CA_Number__c,
                        X0_30__c, X31_60__c, X61_90__c, X91_180__c, X181_365__c, X1_2YR__c, X2_3YR__c,
                        B4DUE__c, NOTDUE__c, WorkType.Name
                        FROM WorkOrder LIMIT 1];
        Test.startTest();
        Map<String, Object> result = RTVisitExecutionController.getAccountInfoFromSA(wo.Id);
        System.assertNotEquals(null, result);
        System.assert(result.containsKey('acc'));
        Test.stopTest();
    }
    
    @isTest
    static void test_saveChequeDetails() {
        
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        String validPngBase64 = 
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGNgYAAAAAMAASsJTYQAAAAASUVORK5CYII=';
        
        List<String> images = new List<String>{ validPngBase64 };
            Test.startTest();
        Id payId = RTVisitExecutionController.saveChequeDetails(
            wo.Id,
            'MICR123',
            testWorkStepName,
            'SBI',
            'Main Branch',
            '123456',
            'Cheque',
            Date.today(),
            'CA123',
            500,
            images,
            validPngBase64
        );
        System.assertNotEquals(null, payId, 'Payment should be created');
        
        Test.stopTest();
        
    }
     @isTest
    static void testGetPreferencePicklistValues() {
        Test.startTest();
        List<String> pickVals = RTVisitExecutionController.getPreferencePicklistValues();
        Test.stopTest();
    }
    @isTest
    static void test_updateGeoLocation_CheckIn() {
        WorkOrder wo = [SELECT Id, AccountId, Account.Name, Account.Phone, Due_Amount__c, Customer_CA_Number__c,
                        X0_30__c, X31_60__c, X61_90__c, X91_180__c, X181_365__c, X1_2YR__c, X2_3YR__c,
                        B4DUE__c, NOTDUE__c, WorkType.Name
                        FROM WorkOrder LIMIT 1];
     ServiceAppointment sa = [SELECT Id, Check_In_Timestamp__c, Check_Out_Timestamp__c, ParentRecordId FROM ServiceAppointment WHERE ParentRecordId = :wo.Id];
        Test.startTest();
        RTVisitExecutionController.updateGeoLocation(String.valueOf(wo.Id), 23.0225d, 72.5714d, 'Check In');
        Test.stopTest();
    }
    
    @isTest
    static void test_updateGeoLocation_CheckOut() {
        WorkOrder wo = [SELECT Id, AccountId, Account.Name, Account.Phone, Due_Amount__c, Customer_CA_Number__c,
                        X0_30__c, X31_60__c, X61_90__c, X91_180__c, X181_365__c, X1_2YR__c, X2_3YR__c,
                        B4DUE__c, NOTDUE__c, WorkType.Name
                        FROM WorkOrder LIMIT 1];
        ServiceAppointment sa = [SELECT Id, Check_In_Timestamp__c, Check_Out_Timestamp__c, ParentRecordId FROM ServiceAppointment WHERE ParentRecordId = :wo.Id];
        Test.startTest();
        RTVisitExecutionController.updateGeoLocation(String.valueOf(wo.Id), 23.0225d, 72.5714d, 'Check Out');
        Test.stopTest();
    }
    
    @isTest
    static void test_updateWorkStepStatus() {
        Test.startTest();
        RTVisitExecutionController.updateWorkStepStatus(testWorkOrderId, testWorkStepName);
        Test.stopTest();
        
        // WorkStep ws = [SELECT Id, Status FROM WorkStep WHERE ParentRecordId = :testWorkOrderId AND Name = :testWorkStepName LIMIT 1];
        //System.assertEquals('Completed', ws.Status, 'WorkStep status must be Completed');
    }
    
    @isTest
    static void test_getBankDetailsByMicr() {
        Test.startTest();
        Bank_Detail__c bank = RTVisitExecutionController.getBankDetailsByMicr('MICR123');
        System.assertEquals('Test Bank', bank.BANK__c);
        Test.stopTest();
    }
    
    @isTest
    static void test_getBankDetailsByMicr_NoRecord() {
        Test.startTest();
        try {
            RTVisitExecutionController.getBankDetailsByMicr('INVALID');
            System.assert(false, 'Exception should be thrown');
        } catch (AuraHandledException e) {
            system.debug('Exception:: '+e.getMessage());
        }
        Test.stopTest();
    }
   
    @isTest
    static void test_getReceivables() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        // create receivable record
        Receivable__c rec = new Receivable__c(
            Name = 'Test Rec',
            Business_Partner__c = acc.Id,
            Amount__c = '100',
            Doc_Number__c = 'DOC123'
        );
        insert rec;

        Test.startTest();
        List<Receivable__c> recs = RTVisitExecutionController.getReceivables(acc.Id);
        System.assert(!recs.isEmpty(), 'Receivables should be returned');
        Test.stopTest();
    }

    // Test savePdfFile when ContentVersion already exists
  @isTest
static void test_savePdfFile_existingVersion() {
    WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
    ContentVersion cv = new ContentVersion(
        Title = 'Bill_123',
        PathOnClient = 'Bill_123.pdf',
        VersionData = Blob.valueOf('Test')
    );
    insert cv;
    Test.setMock(HttpCalloutMock.class, new EbillApiMock());
    Test.startTest();
	RTVisitExecutionController.savePdfFile('123', wo.Id);
    Test.stopTest();
}

    // Test savePdfFile when HTTP callout is required
    private class PdfMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(EncodingUtil.base64Encode(Blob.valueOf('fakepdf')));
            return res;
        }
    }

   @isTest
    static void test_savePdfFile_newVersion() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new PdfMock());
        //Test.setMock(HttpCalloutMock.class, new EbillApiMock());
        Test.startTest();
        RTVisitExecutionController.savePdfFile('456', wo.Id);
        Test.stopTest();
    }
    @isTest
    static void test_getAccountInfoFromSA_withNullId() {
        Test.startTest();
        try {
            RTVisitExecutionController.getAccountInfoFromSA(null);
            System.assert(false, 'Exception expected');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('Work Order Id is null'));
        }
        Test.stopTest();
    }

   
    @isTest
    static void test_updateWorkStepStatus_noStep() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        Test.startTest();
        // Pass a name that does not exist
        RTVisitExecutionController.updateWorkStepStatus(wo.Id, 'NonExistingStep');
        Test.stopTest();
    }
    // Mock for HTTP callouts
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/pdf');
            res.setBody(EncodingUtil.base64Encode(Blob.valueOf('Test PDF Content')));
            res.setStatusCode(200);
            return res;
        }
    }

    @IsTest
    static void testSavePdfFiles() {
        // Set up test data
        Account acc = new Account(Name='Test Account');
        insert acc;

        WorkOrder wo = new WorkOrder(
            AccountId = acc.Id, 
            Subject = 'Test WorkOrder'
        );
        insert wo;

        String billNumbers ='203010855427';
        String phone = '';
        String accName = acc.Name;
        String preference = 'SMS';

        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new EbillApiMock());
        Test.setMock(HttpCalloutMock.class, new PdfMock());
        Test.startTest();
        String result = RTVisitExecutionController.savePdfFiles(
            billNumbers, 
            '131',
            phone, 
            accName, 
            preference, 
            wo.Id
        );
        Test.stopTest();

        // Assertions

        // Check ContentVersions are created
        List<ContentVersion> cvs = [
            SELECT Id, Title, ContentDocumentId
            FROM ContentVersion
            WHERE Title IN :new List<String>{'Bill_001','Bill_002'}
        ];

        // Check ContentDocumentLinks
        List<ContentDocumentLink> cdls = [
            SELECT Id, ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :wo.Id
        ];

        // Check ContentDistributions
        List<ContentDistribution> dists = [
            SELECT Id, ContentVersionId, DistributionPublicUrl
            FROM ContentDistribution
            WHERE ContentVersionId IN :cvs
        ];
        
    }

    // @IsTest
    // static void testSavePdfFiles_NoBillNumbers() {
    //     // Test for empty billPrintNumbers
    //     try {
    //         WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
    //         Test.setMock(HttpCalloutMock.class, new PdfMock());
    //         RTVisitExecutionController.savePdfFiles(new List<String>(), '9999999999', 'Test Acc', 'SMS', '0);
    //         System.assert(false, 'Expected AuraHandledException not thrown');
    //     } catch (AuraHandledException ex) {
    //         System.assertEquals('No Bill Print Numbers provided.', ex.getMessage());
    //     }
    // }

    @IsTest
    static void testSavePdfFiles_NoSmsPreference() {
        // Test with preference other than SMS
        Account acc = new Account(Name='Test Account 2');
        insert acc;
        WorkOrder wo = new WorkOrder(AccountId = acc.Id, Subject = 'WO 2');
        insert wo;

        String billNumbers = '203010855427';
        String result = '';
        Test.setMock(HttpCalloutMock.class, new EbillApiMock());
        Test.setMock(HttpCalloutMock.class, new PdfMock());
        Test.startTest();
        result = RTVisitExecutionController.savePdfFiles(billNumbers, '3123', '7297397397', acc.Name, 'SMS', wo.Id);
        Test.stopTest();

    }
    @IsTest
    static void testExtractDynamicComponents_NormalCase() {
        String message = 'Hello {!firstName}, welcome to {!buildingName}!';
        Map<String, String> mergeFields = new Map<String, String>{
            'firstName' => 'John',
            'buildingName' => 'Sunrise Towers'
        };

        List<Map<String, String>> result = RTVisitExecutionController.extractDynamicComponents(message, mergeFields);

        
    }

    @IsTest
    static void testExtractDynamicComponents_MissingField() {
        String message = 'Hello {!firstName}, your flat {!flatNumber} is ready!';
        Map<String, String> mergeFields = new Map<String, String>{
            'firstName' => 'Alice'
            // flatNumber is missing
        };

        List<Map<String, String>> result = RTVisitExecutionController.extractDynamicComponents(message, mergeFields);

       
    }

    @IsTest
    static void testExtractDynamicComponents_EmptyMessage() {
        Map<String, String> mergeFields = new Map<String, String>{'key' => 'value'};
        List<Map<String, String>> result = RTVisitExecutionController.extractDynamicComponents('', mergeFields);
    }

    @IsTest
    static void testExtractDynamicComponents_NullMessage() {
        Map<String, String> mergeFields = new Map<String, String>{'key' => 'value'};
        List<Map<String, String>> result = RTVisitExecutionController.extractDynamicComponents(null, mergeFields);
    }

    @IsTest
    static void testExtractDynamicComponents_NoTokens() {
        String message = 'Hello World, no merge fields here!';
        Map<String, String> mergeFields = new Map<String, String>{'firstName' => 'Bob'};
        List<Map<String, String>> result = RTVisitExecutionController.extractDynamicComponents(message, mergeFields);
    }
    @isTest
    static void test_sendSms_SMSPreference() {
        WorkOrder wo = [SELECT Id, AccountId FROM WorkOrder LIMIT 1];
        Account acc = [SELECT Id, Name FROM Account WHERE Id = :wo.AccountId];
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Test.startTest();
        String result = RTVisitExecutionController.sendSms(acc.Name, '9876543210', wo.Id, 'SMS', '123456', '213123');
        Test.stopTest();
    }

    @isTest
    static void test_sendSms_WhatsappPreference() {
        WorkOrder wo = [SELECT Id, AccountId FROM WorkOrder LIMIT 1];
        Account acc = [SELECT Id, Name FROM Account WHERE Id = :wo.AccountId];
        
        Test.startTest();
        String result = RTVisitExecutionController.sendSms(acc.Name, '9876543210', wo.Id, 'Whatsapp', '123456', '12312321');
        Test.stopTest();
    }

    @isTest
    static void test_sendSms_EmptyPhone() {
        WorkOrder wo = [SELECT Id, AccountId FROM WorkOrder LIMIT 1];
        Account acc = [SELECT Id, Name FROM Account WHERE Id = :wo.AccountId];
        
        Test.startTest();
        try {
            String result = RTVisitExecutionController.sendSms(acc.Name, '', wo.Id, 'SMS', '123456', '12412');
        } catch (AuraHandledException e) {
            // Expected behavior
        }
        Test.stopTest();
    }

    @isTest
    static void test_savePdfFiles_EmptyPhone() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Test.startTest();
        String result = RTVisitExecutionController.savePdfFiles('123456', '12313', '', 'Test Account', 'SMS', wo.Id);
        Test.stopTest();
    }

    @isTest
    static void test_saveChequeDetails_NoSignature() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        String validPngBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGNgYAAAAAMAASsJTYQAAAAASUVORK5CYII=';
        List<String> images = new List<String>{ validPngBase64 };
        
        Test.startTest();
        Id payId = RTVisitExecutionController.saveChequeDetails(
            wo.Id,
            'MICR123',
            testWorkStepName,
            'SBI',
            'Main Branch',
            '123456',
            'Cheque',
            Date.today(),
            'CA123',
            500,
            images,
            null // No signature
        );
        Test.stopTest();
    }

    @isTest
    static void test_getAccountInfoFromSA_NoAccount() {
        WorkOrder wo = new WorkOrder(Subject = 'Test WO No Account');
        insert wo;
        
        Test.startTest();
        try {
            Map<String, Object> result = RTVisitExecutionController.getAccountInfoFromSA(wo.Id);
        } catch (AuraHandledException e) {
            // Expected behavior
        }
        Test.stopTest();
    }

    @isTest
    static void test_savePdfFile_ExceptionHandling() {
        Test.setMock(HttpCalloutMock.class, new ErrorMock());
        
        Test.startTest();
        try {
            String result = RTVisitExecutionController.savePdfFile('123456', null);
        } catch (AuraHandledException e) {
            // Expected behavior
        }
        Test.stopTest();
    }

    @isTest
    static void test_fetchBillingByBP() {
        Test.setMock(HttpCalloutMock.class, new BillingApiMock());
        
        Test.startTest();
        List<RTVisitExecutionController.BillWrapper> result = RTVisitExecutionController.fetchPaymentByBP('BP123');
        Test.stopTest();
    }

    @isTest
    static void test_fetchBillingByBP_Empty() {
        Test.setMock(HttpCalloutMock.class, new EmptyBillingMock());
        
        Test.startTest();
        List<RTVisitExecutionController.BillWrapper> result = RTVisitExecutionController.fetchPaymentByBP('INVALID');
        Test.stopTest();
    }

    @isTest
    static void test_fetchBillByBP_Empty() {
        Test.setMock(HttpCalloutMock.class, new EmptyBillingMock());
        
        Test.startTest();
        RTVisitExecutionController.SAP_Response result = RTVisitExecutionController.fetchBillByBP('INVALID', '123123', '312412');
        Test.stopTest();
    }
    
    @IsTest
    static void testFetchChequeBounceByBP() {
        Test.setMock(HttpCalloutMock.class, new ChequeHistoryMock());
        Test.startTest();
        RTVisitExecutionController.fetchChequeBounceByBP('1100042634');
        Test.stopTest();
    }   
    
    // Additional mock classes for new test scenarios
    private class NonJsonMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('This is not JSON');
            return res;
        }
    }

    private class ErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('Server Error');
            return res;
        }
    }

    private class BillingApiMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"sapData": [{"OPBEL": "DOC001", "VKONT": "CA123", "BLDAT": "2023-01-01", "TOTAL_AMNT": "100.00"}]}');
            return res;
        }
    }

    private class EmptyBillingMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"error": "No data found"}');
            return res;
        }
    }

    private class EbillApiMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status": "SUCCESS", "data": ["http://example.com/bill.pdf"]}');
            return res;
        }
    }

    private class ChequeHistoryMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {

            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"sapData": [{"NET_DATE":"2025-11-05","RTEXT":"Test"},{"NET_DATE":"2025-11-06","RTEXT":"Test"},{"NET_DATE":"2025-11-07","RTEXT":"Test"}]}');
            return res;
        }
    }

}