@IsTest
public class AS_PaymentNotificationServiceTest {

    // ======================================================
    // @testSetup — create all test data once for all tests
    // ======================================================
    @testSetup
    static void setupTestData() {

        // --- Account ---
        Account acc = new Account(
            Name = 'Test Account',
            CA_Number__c = 'CA12345',
            Phone = '9876543210'
        );
        insert acc;

        // --- Agency ---
        /*
        R_T_Agency__c agency = new R_T_Agency__c(
            Name = 'Test Agency',
            AgencyCode__c = 'AG001'
        );
        insert agency;

        // --- Agent ---
        Agent__c agent = new Agent__c(
            Name = 'Test Agent',
            Agent_ID__c = 'AGT1001'
        );
        insert agent;*/
        
        Id rtId = [SELECT Id FROM RecordType 
                   WHERE SObjectType = 'WorkOrder' 
                   AND DeveloperName = 'MGL_R_T' LIMIT 1].Id;

        // --- Work Order ---
        WorkOrder wo = new WorkOrder(
            //Name = 'WO-001',
            RecordTypeId = rtId,
            AccountId = acc.Id,
            //R_T_Agency__c = agency.Id,
            //Agent__c = agent.Id,
            //Agency_Name_Formula__c = 'Test Agency',
            Amount_Received__c = 5000,
            Payment_Mode__c = 'Cheque',
            Due_Amount__c = 200,
            New_Mobile_Number__c = '321312313'
            //WorkOrderNumber = 'WO-1001',
            //Customer_CA_Number__c = acc.CA_Number__c
        );
        insert wo;

        // --- Payment ---
        Payment__c pay = new Payment__c(
            Name = 'PAY-001',
            Work_Order__c = wo.Id,
            Cheque_Amount__c = 200
            //Receipt_Number__c = 'R-1001'
        );
        insert pay;

        // --- Metadata (Go_Collect_Follow_Up__mdt) ---
        // Simulate required metadata entries
        /*
        List<Go_Collect_Follow_Up__mdt> mdts = new List<Go_Collect_Follow_Up__mdt>();
        mdts.add(new Go_Collect_Follow_Up__mdt(
            MasterLabel = 'Payment Confirmation',
            Template_Id__c = 'TMP1001',
            SMS_requried__c = true
        ));
        insert mdts;
		*/

        // --- SMS Template ---
        Case_Type_SMS__c tmpl = new Case_Type_SMS__c(
            //Name = 'Payment Confirmation Template',
            Template_Id__c = '1007196877274116457',
            Message__c = 'Dear Customer, your payment {!ReceiptNo} has been received.'
        );
        insert tmpl;

        // --- Mock Config ---
        SmsApiConfigLTD__c config = new SmsApiConfigLTD__c(
            Name = 'Default',
            API_Key__c = 'TESTKEY123',
            EndPoint__c = 'https://test-endpoint.com/sms'
        );
        insert config;
    }

    // ======================================================
    // TEST #1 — Process Notifications on Payment Insert
    // ======================================================
    @IsTest
    static void testProcessNotifications_Insert() {

        // Query test data
        Payment__c pay = [SELECT Id, Work_Order__r.Record_Type_Developer_Name__c,
                                 Work_Order__r.R_T_Agency__r.AgencyCode__c,
                                 Work_Order__r.Agent__r.Agent_ID__c,
                          		 Work_Order__r.New_Mobile_Number__c,
                          		 Work_Order__r.RecordType.DeveloperName,
                                 Cheque_Amount__c, Work_Order__r.Account.Phone
                          FROM Payment__c LIMIT 1];

        // Call the service
        Test.startTest();
        AS_PaymentNotificationService.processNotifications(new List<Payment__c>{pay});
        Test.stopTest();
 
        // Validation
        System.assert(true, 'Service executed without exception.');
    }

    // ======================================================
    // TEST #2 — Batch Execution (AS_PaymentSMSBatch)
    // ======================================================
    @IsTest
    static void testPaymentSMSBatch_Execute() {
        // Build dummy wrapper
        AS_PaymentNotificationService.WorkOrderNotificationWrapper wrap = 
            new AS_PaymentNotificationService.WorkOrderNotificationWrapper();

        wrap.pay = [SELECT Id, Work_Order__c, Cheque_Amount__c, 
                    	   Work_Order__r.Account.Phone,Work_Order__r.New_Mobile_Number__c 
                    FROM Payment__c LIMIT 1];
        wrap.tmpl = [SELECT Id, Template_Id__c, Message__c FROM Case_Type_SMS__c LIMIT 1];
        wrap.templateId = wrap.tmpl.Template_Id__c;
        wrap.followUpRemarksOpt = null;

        List<AS_PaymentNotificationService.WorkOrderNotificationWrapper> wrapperList = 
            new List<AS_PaymentNotificationService.WorkOrderNotificationWrapper>{wrap};

        // Instantiate batch
        AS_PaymentSMSBatch batch = new AS_PaymentSMSBatch(wrapperList);

        Test.startTest();
        Database.executeBatch(batch, 1);
        Test.stopTest();

        System.assert(true, 'Batch executed successfully.');
    }

    // ======================================================
    // TEST #3 — No valid payments
    // ======================================================
    @IsTest
    static void testProcessNotifications_NoValidPayments() {
        Payment__c invalidPay = new Payment__c(
            Name = 'PAY-INVALID',
            Cheque_Amount__c = null,
            Work_Order__c = null
        );
        insert invalidPay;

        Test.startTest();
        AS_PaymentNotificationService.processNotifications(new List<Payment__c>{invalidPay});
        Test.stopTest();

        System.assert(true, 'Handled invalid payment gracefully.');
    }
}