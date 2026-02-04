<<<<<<< HEAD
@isTest
private class AccountTriggerHandlerTest {

    @isTest
    static void setupTestData() {
        // Record Types
        String businessAccountRT = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName()
            .get('Business_Account').getRecordTypeId();
        String agencyAccountRT = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName()
            .get('Agency_Account').getRecordTypeId();

        // Business Account (Full_Name__c + BP_Number__c)
        Account ba = new Account(
            Name = 'Temp', // Will be overwritten
            Full_Name__c = 'Business FullName',
            BP_Number__c = 'BP002',
            RecordTypeId = businessAccountRT,
            Phone = '1234567890'
        );

        // Agency Account (Full_Name__c + BP_Number__c)
        Account aa = new Account(
            Name = 'Temp', // Will be overwritten
            Full_Name__c = 'Agency FullName',
            BP_Number__c = 'BP003',
            RecordTypeId = agencyAccountRT,
            Phone = '9876543210',
            No_of_Dispensers__c=1
        );

        insert new List<Account>{ba, aa};
            
            aa.Full_Name__c='Test';
        aa.No_of_Dispensers__c=2;
        update aa;
=======
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
>>>>>>> e604021b64f33882bfed07c2bfed265ad53326cf
    }
}