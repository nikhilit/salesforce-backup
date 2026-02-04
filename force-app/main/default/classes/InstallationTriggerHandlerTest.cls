@isTest
public class InstallationTriggerHandlerTest {

    @isTest
    static void testInsertAndUpdatePremise() {
        Installation__c ins = new Installation__c(
            Installation__c = 'INST001',
            Premise__c = 'PREM001'
        );
        insert ins;

        Installation__c insertedRec = [
            SELECT Name, To_Be_Processed__c, Installation__c, Premise__c
            FROM Installation__c
            WHERE Id = :ins.Id
        ];

        insertedRec.Premise__c = 'PREM002';
        insertedRec.Installation__c = 'INST002';
        update insertedRec;

   }
}