@isTest
public class PremiseTriggerHandlerTest {

    @isTest
    static void testInsertAndUpdatePremise() {
        // Prepare records for insert
        Premise__c premWithCode = new Premise__c(Premise_Code__c = 'PRM001',Connection_Name__c ='CON001');

        // Insert to fire before insert trigger
        insert new List<Premise__c>{ premWithCode };

        // Query inserted records
        List<Premise__c> insertedPremises = [
            SELECT Id, Name, Premise_Code__c, To_be_processed__c 
            FROM Premise__c 
            WHERE Id IN :new List<Id>{premWithCode.Id}
        ];

        insertedPremises[0].Premise_Code__c = 'PRM002';
		insertedPremises[0].Connection_Name__c ='CON002';
        update insertedPremises;
    }
}