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
    }
}