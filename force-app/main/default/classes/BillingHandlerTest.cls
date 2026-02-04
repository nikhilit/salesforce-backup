@IsTest
public class BillingHandlerTest {

    @IsTest
    static void testMarkBillingToBeProcessed_InsertAndUpdate() {
        // Step 1: Create test data
        Billing__c bill1 = new Billing__c(
            Contract_Account__c = 'CA-1',
            Business_Partner__c = 'BP-1',
            Print_Doc_Number__c = 'INV-001'
        );
        insert bill1;

        // Step 2: Simulate update by querying old values
        Billing__c oldBill = [SELECT Id, Contract_Account__c, Business_Partner__c, Print_Doc_Number__c 
                              FROM Billing__c WHERE Id = :bill1.Id];

        // Modify fields to trigger textFieldChanged and invoiceNumberChanged
        bill1.Contract_Account__c = 'CA-2';
        bill1.Business_Partner__c = 'BP-2';
        bill1.Print_Doc_Number__c = 'INV-002';

        List<Billing__c> newList = new List<Billing__c>{ bill1 };
        Map<Id, Billing__c> oldMap = new Map<Id, Billing__c>{ oldBill.Id => oldBill };

        // Step 3: Call the handler explicitly
        Test.startTest();
        BillingHandler.markBillingToBeProcessed(newList, oldMap);
        Test.stopTest();

        // Step 4: Assert outcomes
        System.assertEquals(true, bill1.To_be_processed__c, 'Bill should be marked for processing');
        System.assertEquals('INV-002', bill1.Name, 'Name should update to new Print_Doc_Number__c');
    }
}