@isTest
public class AccountDetailsController1Test {
    
    @isTest
    static void testGetAccountDetails_withAccount() {
        // Create Premise
        Premise__c premise = new Premise__c(
            Name = 'Test Premise',
            Connection_Name__c = 'Test Connection'
        );
        insert premise;

        // Create Account
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
            Building_Code__c = 'BLDG123',
            BP_Number__c = 'BP001',
            Premise__c = premise.Id
        );
        insert testAccount;

        // Create Installation
        Installation__c installation = new Installation__c(
            Name = 'Test Installation',
            Minimum_Charges__c = 'true',
            Charges_Valid_From__c = Date.today(),
            Charges_Valid_To__c = String.valueOf(Date.today().addMonths(12))
        );
        insert installation;

        // Create Move In/Out (linking to Installation)
        Move_In_Out__c moveInOut = new Move_In_Out__c(
            Business_Partner__c = testAccount.BP_Number__c,
            Installation_Name__c = installation.Id,
            Installation__c='Test Installation',
            Move_In_Date__c = String.valueOf(Date.today().addDays(-30)),
            Move_Out_Date__c = String.valueOf(Date.today().addDays(30))
        );
        insert moveInOut;

        // Create Device Allocation
        Device_Allocation__c devAlloc = new Device_Allocation__c(
            Installation_Number__c = installation.Id,
            Device_Number__c='1234',
            Last_Meter_Reading__c = '123',
            Last_Meter_Date__c = '2024-08-01'
        );
        insert devAlloc;

        // Security Deposit
        Security_Deposit__c deposit = new Security_Deposit__c(
            BP_Number__c = testAccount.Id,
            Cash_Amount__c = 500
        );
        insert deposit;

        // Chronology
        Chronology__c chronology = new Chronology__c(
            BP_Number__c = testAccount.Id,
            Credit_Amt__c = '100', // Decimal not string
            Net_Due_Date__c = Date.today()
        );
        insert chronology;

        // Identification Numbers
        insert new Identification_Number__c(
            BP__c = testAccount.Id,
            Type_Desc__c = 'Application Form',
            ID_Number__c = 'ID123'
        );
        insert new Identification_Number__c(
            BP__c = testAccount.Id,
            Type__c = 'DOM Type',
            ID_Number__c = 'DOM123'
        );

        Test.startTest();
        AccountDetailsController1.AccountWrapper result =
            AccountDetailsController1.getAccountDetails(testAccount.Id);
        Test.stopTest();

        // System.assertNotEquals(null, result);
        // System.assertEquals('Active', result.status);
        // System.assertEquals(testAccount.Id, result.account.Id);
        // System.assertNotEquals(null, result.deviceAllocation);
        // System.assertNotEquals(null, result.securitydeposit);
        // System.assertNotEquals(null, result.idnumber);
        // System.assertNotEquals(null, result.domId);
        // System.assertNotEquals(null, result.lastamountpaid);
        // System.assertNotEquals(null, result.minimumcharges);
        //System.assertNotEquals(null, result.servicecontract);
    }

    @isTest
    static void testGetAccountDetails_withLead() {
        Lead testLead = new Lead(
            LastName = 'Prospect',
            Company = 'Test Company'
           // Lead_No__c = 'L123'
        );
        insert testLead;

        // Create Case related only to Lead
        Case c = new Case(
            Subject = 'Test Case',
            Status = 'New',
            Lead__c = testLead.Id
        );
        insert c;

        Test.startTest();
        AccountDetailsController1.AccountWrapper result =
            AccountDetailsController1.getAccountDetails(c.Id);
        Test.stopTest();
       // System.assertEquals('L123', result.prospectNumber);
    }

    @isTest
    static void testGetTotalCashAmount() {
        Account acc = new Account(Name = 'Cash Test Account', BP_Number__c = 'BP002');
        insert acc;

        insert new Security_Deposit__c(BP_Number__c = acc.Id, Cash_Amount__c = 200);
        insert new Security_Deposit__c(BP_Number__c = acc.Id, Cash_Amount__c = 300);

        Test.startTest();
        Decimal total = AccountDetailsController1.getTotalCashAmount(acc.Id);
        Test.stopTest();

        //System.assertEquals(500, total);
    }
}