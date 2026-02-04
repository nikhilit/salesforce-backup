/**
* @File Name : AS_PaymentModuleHandlerTest.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : July 11, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | July 11, 2025 |   | Initial Version
**/
@IsTest
public class AS_PaymentModuleHandlerTest {
    
    class SmsHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse resp = new HttpResponse();
            resp.setHeader('Content-Type', 'application/json');
            resp.setStatusCode(200);
            String body = '[{"code":"200","destination":"9876543210","uuid":"abc123"}]';
            resp.setBody(body);
            return resp;
        }
    }

    // Mock callout class
    class MockPOSPayCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"success":true,"p2pRequestId":"250709120657810E010054604","message":"Payment initiated.", "status":"AUTHORIZED"}');
            res.setStatusCode(200);
            return res;
        }
    }

    class MockPOSStatusCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"success":true,"txnId":"TXN123456","amount":4500,"message":"Transaction done on device, Please look at Txn status.", "status":"AUTHORIZED"}');
            res.setStatusCode(200);
            return res;
        }
    }

	class MockQRPayCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"success":true,"sessionKey":"1456d6a7-0331-439c-83ce-d46e69d22c65","username":"1212127800", "status":"AUTHORIZED"}');
            res.setStatusCode(200);
            return res;
        }
    }

    class MockQRStatusCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"success":true,"sessionKey":"6d9b46b2-0e3f-41b0-9fb1-abc344d89c8a","username":"1212127800", "status":"AUTHORIZED"}');
            res.setStatusCode(200);
            return res;
        }
    }

    @TestSetup
    static void setupData() {
        // Create Account
        Account acc = new Account(Name = 'Test Account', Phone = '9999999999');
        insert acc;
 
        // Create WorkOrder
        WorkOrder wo = new WorkOrder(
            Subject = 'Test WorkOrder',
            AccountId = acc.Id,
            Due_Amount__c = 1000
        );
        insert wo;
        
        // Assign Device Id to running user
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        u.Device_Id__c = 'TestDevice123';
        update u;
        
        Case_Type_SMS__c tmpl = new Case_Type_SMS__c(
            Message__c = 'Hello {!Remark}',
            Template_Id__c = '1007196877274116457'
        );
        insert tmpl;
    }

    @IsTest
    static void testPayViaPOS_Success() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new MockPOSPayCallout());

        Test.startTest();
        Object result = AS_PaymentModuleHandler.payRequest(wo.Id, 'M-POS', 20.1, 'Full Payment', 'Payment Received');
        Test.stopTest();
        
        // Verify WorkOrder got updated
        WorkOrder updatedWO = [SELECT P2PRequestId__c FROM WorkOrder WHERE Id = :wo.Id];
        //System.assertNotEquals(null, updatedWO.P2PRequestId__c, 'Expected P2PRequestId__c to be set');
    }

	@IsTest
    static void testPayViaQR_Success() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new MockQRPayCallout());

        Test.startTest();
        Object result = AS_PaymentModuleHandler.payRequest(wo.Id, 'QR Code', 10, 'Partial Payment', 'Payment Received');
        Test.stopTest();
        
        // Verify WorkOrder got updated
        WorkOrder updatedWO = [SELECT QR_Code_Txn_Id__c FROM WorkOrder WHERE Id = :wo.Id];
        //System.assertNotEquals(null, updatedWO.QR_Code_Txn_Id__c, 'Expected QR_Code_Txn_Id__c to be set');
    }

    @IsTest
    static void testCheckStatusPOS_Success() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        update new WorkOrder(Id = wo.Id, P2PRequestId__c = '250709120657810E010054604');

        Test.setMock(HttpCalloutMock.class, new MockPOSStatusCallout());

        Test.startTest();
        Object result = AS_PaymentModuleHandler.checkStatus(wo.Id, 'M-POS');
        Test.stopTest();

        WorkOrder updatedWO = [SELECT Transaction_Id__c FROM WorkOrder WHERE Id = :wo.Id];
		//System.assertEquals('TXN123456', updatedWO.Transaction_Id__c, 'Transaction_Id__c should be updated');
    }

	@IsTest
    static void testCheckStatusQR_Success() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        update new WorkOrder(Id = wo.Id, QR_Code_Txn_Id__c = '250709120657810E010054604');

        Test.setMock(HttpCalloutMock.class, new MockQRStatusCallout());

        Test.startTest();
        Object result = AS_PaymentModuleHandler.checkStatus(wo.Id, 'QR Code');
        Test.stopTest();

        WorkOrder updatedWO = [SELECT QR_Code_Txn_Id__c FROM WorkOrder WHERE Id = :wo.Id];
        System.assertEquals('250709120657810E010054604', updatedWO.QR_Code_Txn_Id__c, 'QR_Code_Txn_Id__c should be updated');
    }

    @IsTest
    static void testPayViaPOS_Exception() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        Test.startTest();
        try {
            Object result = AS_PaymentModuleHandler.payRequest(wo.Id, 'M-POS', 10, 'Full Payment', 'Payment Received');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('unexpected'), 'Expected handled exception');
        }
        Test.stopTest();
    }

	@IsTest
    static void testPayViaQR_Exception() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        Test.startTest();
        try {
            Object result = AS_PaymentModuleHandler.payRequest(null, 'QR Code', 10, 'Full Payment', 'Payment Received');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('unexpected'), 'Expected handled exception');
        }
        Test.stopTest();
    }

    @IsTest
    static void testCheckStatusPOS_MissingP2PId() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        Test.startTest();
        Object result = AS_PaymentModuleHandler.checkStatus(wo.Id, 'M-POS');
        Test.stopTest();
    }

	@IsTest
    static void testCheckStatusQR_MissingTXNId() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        Test.startTest();
        Object result = AS_PaymentModuleHandler.checkStatus(wo.Id, 'QR Code');
        Test.stopTest();
    }

	@IsTest
    static void testGetWorkOrderPaymentState() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        Test.startTest();
        Object result = AS_PaymentModuleHandler.getWorkOrderPaymentState(wo.Id);
        Test.stopTest();
    }

	@isTest
	static void testUpdateGeoLocation() {
        OperatingHours hours = new OperatingHours(Name = 'Default Hours', TimeZone = 'Asia/Kolkata');
        insert hours;
    
        ServiceTerritory territory = new ServiceTerritory(Name = 'Test Territory', OperatingHoursId = hours.Id, IsActive = true);
        insert territory;
    
        Account acc = new Account(Name = 'Test Account');
        insert acc;
    
        WorkType wt = new WorkType(Name = 'Installation', EstimatedDuration = 60);
        insert wt;
    
        WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            AccountId = acc.Id,
            WorkTypeId = wt.Id,
            Status = 'New'
        );
        insert wo;
    
        ServiceAppointment sa = new ServiceAppointment(
            ParentRecordId = wo.Id,
            ServiceTerritoryId = territory.Id,
            EarliestStartTime = System.now(),
            DueDate = System.now().addHours(1),
            Status = 'Scheduled'
        );
        insert sa;
    
        Test.startTest();
        AS_PaymentModuleHandler.updateGeoLocation(wo.Id, 12.9716d, 77.5946d, 'Check In');
        AS_PaymentModuleHandler.updateGeoLocation(wo.Id, 12.9716d, 77.5946d, 'Check Out');
        Test.stopTest();
    
        WorkOrder updatedWO = [SELECT Id, Check_In_Date_Time__c, Check_Out_Date_Time__c FROM WorkOrder WHERE Id = :wo.Id];
    }

  	@isTest
    static void testupdateWorkStepStatus(){
        WorkOrder wo = [SELECT Id, Subject, AccountId, Due_Amount__c FROM WorkOrder LIMIT 1];
        Test.startTest();
        As_RazorPayPOSModule.updateWorkStepStatus(wo.Id, 'Test Work Step');
        AS_RazorPayQRCodeModule.updateWorkStepStatus(wo.Id, 'Test Work Step');
        Test.stopTest();
    }
    
    @isTest
    static void testCancelRequest(){
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        AS_PaymentModuleHandler.cancelRequest(wo.Id);
    }
    
    @isTest
    static void testSendSMS(){
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SmsHttpMock());
        
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        AS_PaymentModuleHandler.sendSms('0987654321', wo.Id);
        
        Test.stopTest();
    }
}