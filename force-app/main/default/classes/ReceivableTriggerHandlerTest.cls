@isTest
public class ReceivableTriggerHandlerTest {

    @isTest
    static void testMarkReceivablesToBeProcessed() {
        // Create test Receivable__c records
        List<Receivable__c> receivables = new List<Receivable__c>{
            new Receivable__c(Doc_Number__c = 'DOC1001'),
            new Receivable__c(Doc_Number__c = 'DOC1002'),
            new Receivable__c(Doc_Number__c = null) // Test null case
        };

        // Call the method under test
        ReceivableTriggerHandler.markReceivablesToBeProcessed(receivables);
        insert receivables;

        // Assert all records are marked to be processed
        for (Receivable__c rec : receivables) {
            System.assertEquals(true, rec.To_be_processed__c, 'To_be_processed__c should be true');
        }

        // Assert Name field behavior
        System.assertEquals('DOC1001', receivables[0].Name, 'Name should be set from Doc_Number__c');
        System.assertEquals('DOC1002', receivables[1].Name, 'Name should be set from Doc_Number__c');
        System.assertEquals(null, receivables[2].Name, 'Name should remain null when Doc_Number__c is null');
    }
}