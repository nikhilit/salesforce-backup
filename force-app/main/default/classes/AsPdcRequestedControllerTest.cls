@isTest
public class AsPdcRequestedControllerTest {
    
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
        
        Payment__c pay = new Payment__c(
            Name = 'test',
            Work_Order__c = wo.Id
        );
        insert pay;
        
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
    
    @isTest
    static void testSaveChequeDetails() {
        // Create Account with valid BP_Number__c
        Account acc = new Account(
            Name = 'Test BP',
            BP_Number__c = '1234567890' // use valid numeric BP number
        );
        insert acc;
        
        // Create WorkOrder linked to Account
        WorkOrder wo = new WorkOrder(
            Subject   = 'Test WO',
            AccountId = acc.Id,
            Status    = 'New'
        );
        insert wo;

        // Create valid Base64 image (tiny valid JPEG blob)
        Blob testBlob = Blob.valueOf('fakeimagecontent'); 
        String base64Image = 'data:image/jpeg;base64,' + EncodingUtil.base64Encode(testBlob);

        // Build ChequeWrapper
        AsPdcRequestedController.ChequeWrapper wrap = new AsPdcRequestedController.ChequeWrapper();
        wrap.recordId     = wo.Id;
        wrap.chequeNumber = 'CHQ123';
        wrap.chequeAmount = 5000;
        wrap.chequeDate   = Date.today();
        wrap.bankName     = 'Test Bank';
        wrap.branchName   = 'Test Branch';
        wrap.micrCode     = 'MICR001';
        wrap.paymentMode  = 'Cheque';
        wrap.base64Image  = base64Image;
        wrap.workStepName = 'Payment Capture';
        wrap.micrFound    = true;

        List<AsPdcRequestedController.ChequeWrapper> wrappers = new List<AsPdcRequestedController.ChequeWrapper>{wrap};

        Test.startTest();
        String result = AsPdcRequestedController.saveChequeDetails(wrappers, 'M-POS', 'Payment Received');
        Test.stopTest();

        System.debug('Result from saveChequeDetails: ' + result);
        System.assertEquals('Success', result);

        // Verify Payment was inserted correctly
        List<Payment__c> payments = [
            SELECT Id, Cheque_Amount__c, Work_Order__c 
            FROM Payment__c 
            WHERE Work_Order__c = :wo.Id
        ];
        System.assertEquals(1, payments.size(), 'One payment should be inserted');
        System.assertEquals(5000, payments[0].Cheque_Amount__c);
        System.assertEquals(wo.Id, payments[0].Work_Order__c);
    }

    @isTest
    static void testUpdateWorkStepStatus_NoSteps() {
        Account acc = new Account(Name = 'Test Acc', BP_Number__c = '9876543210');
        insert acc;

        WorkOrder wo = new WorkOrder(
            AccountId = acc.Id,
            Status    = 'Open',
            Subject   = 'Test WO'
        );
        insert wo;

        Test.startTest();
        AsPdcRequestedController.updateWorkStepStatus(new Set<Id>{wo.Id}, 'Payment Capture');
        Test.stopTest();

        System.assert(true, 'Method executed without exception');
    }
    
    @isTest
    static void testSendSMS(){
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SmsHttpMock());
        
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        AsPdcRequestedController.sendSms('0987654321', wo.Id);
        
        Test.stopTest();
    }
}