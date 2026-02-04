@isTest
public class PaymentReceiptControllerTest {

    @isTest
    static void testPaymentReceiptConstructor() {
        User agentUser = new User(
            FirstName = 'Test',
            LastName = 'Agent',
            Alias = 'tagent',
            Email = 'agent@example.com',
            Username = 'agentuser' + System.currentTimeMillis() + '@test.com',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert agentUser;

        Account agency = new Account(Name = 'Test Agency');
        insert agency;

        Account bpAccount = new Account(Name = 'Test Customer');
        insert bpAccount;

        Account agentAccount = new Account(Name = 'Agent Account');
        insert agentAccount;
        
        WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            Agent__c = agentAccount.Id 
        );

        Payment__c pay = new Payment__c(
            Business_Partner__c = bpAccount.Id,
            Work_Order__c = wo.Id,
            CA_Number__c = 'CA-456',
            Bank_Name__c = 'Test Bank',
            Cheque_Number__c = '987654',
            Cheque_Date__c = Date.today(),
            Cheque_Amount__c = 1234,
            Payment_Mode__c = 'Cheque',
            Total_Due_Amount__c = 2345
        );
        insert pay;

        Test.setCurrentPageReference(new PageReference('/apex/PaymentReceipt'));
        ApexPages.currentPage().getParameters().put('id', pay.Id);

        PaymentReceiptController ctrl = new PaymentReceiptController();

        System.assertNotEquals(null, ctrl.payment);
        System.assertEquals(agentUser.Name, ctrl.agentName);
    }
}