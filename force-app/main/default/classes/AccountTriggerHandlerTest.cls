@isTest(SeeAllData=false)
public class AccountTriggerHandlerTest {

    @isTest
    static void TestpopulateNcontact() {
        // Create an account with a unique name
        Account a = new Account();
        a.Name = 'Test_' + Datetime.now().getTime(); // Unique name
        a.create_N_Contact__c = 5;

        // Insert the account
        insert a;

        // Query the account to simulate real-world behavior
        List<Account> accList = [SELECT Id, Name, create_N_Contact__c FROM Account WHERE Id = :a.Id];

        Test.startTest();
        AccountTriggerHandler.populateNcontact(accList);
        Test.stopTest();

        // Verify the contacts created by the trigger
        List<Contact> conList = [SELECT AccountId, Id FROM Contact WHERE AccountId = :a.Id];
        System.assertEquals(5, conList.size(), 'Expected 5 contacts to be created.');
    }
}