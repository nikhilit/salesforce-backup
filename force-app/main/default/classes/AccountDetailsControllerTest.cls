@isTest
public class AccountDetailsControllerTest {
    
    @isTest
    static void testGetAccountDetails() {
        // Create related Premise
        Premise__c premise = new Premise__c(
            Name = 'Test Premise',
            Connection_Name__c = 'Test Connection'
        );
        insert premise;

        // Create test Account
        Account testAccount = new Account(
            Name = 'Test Account',
            FirstName__c = 'John',
            LastName__c = 'Doe',
            Account_Email__c = 'john.doe@example.com',
            Type = 'Customer',
            Description = 'Test Account',
            City__c = 'Mumbai',
            Postal_Code__c = '400093',
            Phone = '9988776655',
            Street__c = 'Main Street',
            Street_Line_2__c = 'Near Park',
            Street_Line_3__c = 'Sector 3',
            Street_Line_4__c = 'Building 4',
            Street_Line_5__c = 'Zone 5',
            Building_Code__c = 'BLDG123',
            BP_Number__c = 'BP001',
            Premise__c = premise.Id
        );
        insert testAccount;

        // Create related Device
        Device__c device = new Device__c(
            Name = 'Device 1',
            Last_Meter_Reading__c = '100',
            Last_Meter_Date__c = 'shruthi'
        );
        insert device;

        // Create related Security Deposit
        Security_Deposit__c deposit = new Security_Deposit__c(
            BP_Number__c = testAccount.Id,
            Cash_Amount__c = 500
        );
        insert deposit;

        // Create related Identification Numbers
        Identification_Number__c idNumber = new Identification_Number__c(
            BP__c = testAccount.Id,
            Type_Desc__c = 'Application Form',
            ID_Number__c = 'ID123'
        );
        insert idNumber;

        Identification_Number__c domId = new Identification_Number__c(
            BP__c = testAccount.Id,
            Type__c = 'DOM Type',
            ID_Number__c = 'DOM123'
        );
        insert domId;

        // Create related Service Contract
ServiceContract serviceContract = new ServiceContract(
    Name = 'Test Service Contract',
    AccountId = testAccount.Id,
    StartDate = System.today()
);
insert serviceContract;

        Test.startTest();
        AccountDetailsController.AccountWrapper result = AccountDetailsController.getAccountDetails(testAccount.Id);
        Test.stopTest();
    }

    @isTest
    static void testGetTotalCashAmount() {
        Account acc = new Account(Name = 'Cash Test Account');
        insert acc;

        // Create deposits
        insert new Security_Deposit__c(BP_Number__c = acc.Id, Cash_Amount__c = 200);
        insert new Security_Deposit__c(BP_Number__c = acc.Id, Cash_Amount__c = 300);

        Test.startTest();
        Decimal total = AccountDetailsController.getTotalCashAmount(acc.Id);
        Test.stopTest();
    }
}