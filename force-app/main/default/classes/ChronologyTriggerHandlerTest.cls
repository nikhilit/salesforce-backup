@isTest
public class ChronologyTriggerHandlerTest {

    @isTest
    static void testChronologyTriggerActiveAndInactive() {
        // ---- Scenario 1: Trigger Active ----
        Chronology__c chr1 = new Chronology__c(Doc_Number__c = 'DOC001');
        Chronology__c chr2 = new Chronology__c(Doc_Number__c = 'DOC002');
        Chronology__c chr3 = new Chronology__c(); // null Doc_Number__c

        insert new List<Chronology__c>{ chr1, chr2, chr3 };

        // Verify values after insert
        List<Chronology__c> inserted = [
            SELECT Name, To_be_processed__c, Doc_Number__c
            FROM Chronology__c
            ORDER BY Doc_Number__c NULLS LAST
        ];

        System.assertEquals('DOC001', inserted[0].Name);
        System.assertEquals(true, inserted[0].To_be_processed__c);
        System.assertEquals('DOC002', inserted[1].Name);
        System.assertEquals(true, inserted[1].To_be_processed__c);
        System.assertEquals(true, inserted[2].To_be_processed__c);
        //System.assertEquals(null, inserted[2].Name);

        // Update to make sure trigger runs on update
        inserted[0].Doc_Number__c = 'DOC001-UPDATED';
        update inserted;

        // ---- Scenario 2: Trigger Inactive ----
        Test.startTest();
        TriggerController.triggerControlMap = new Map<String, Boolean>{
            'ChronologyTrigger' => false
        };
        insert new Chronology__c(Doc_Number__c = 'SHOULD_NOT_RUN');
        Test.stopTest();
    }
}