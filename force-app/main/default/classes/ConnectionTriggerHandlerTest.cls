@isTest
public class ConnectionTriggerHandlerTest {

    @isTest
    static void testInsertAndUpdateConnectionTrigger() {
        // Scenario 1: Trigger Active
        Connection__c connWithCode = new Connection__c(Connection_Code__c = 'CON001');
        insert new List<Connection__c>{ connWithCode };

        List<Connection__c> inserted = [
            SELECT Id, Name FROM Connection__c
        ];
        inserted[0].Connection_Code__c = 'CON002';
        update inserted;
    }
}