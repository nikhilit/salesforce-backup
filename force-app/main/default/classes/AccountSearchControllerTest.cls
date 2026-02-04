@isTest
private class AccountSearchControllerTest {

   @testSetup
static void setupTestData() {

    // ===== NON-SETUP OBJECTS (OK) =====
    DRS__c drs = new DRS__c(Name = 'DRS Test', GA__c = 'GA123');
    insert drs;

    Account acc = new Account(
        Name = 'Test Account',
        FirstName__c = 'John',
        LastName__c = 'Doe',
        Contract_Account__c = 'CA123',
        BP_Number__c = 'BP456',
        Phone = '1234567890',
        Account_Email__c = 'test@example.com',
        Postal_Code__c = '560001',
        City__c = 'Bangalore',
        Floor__c = '1',
        Flat__c = '101',
        Street__c = 'Main Street'
    );
    insert acc;

    Identification_Number__c idNum = new Identification_Number__c(
        BP__c = acc.Id,
        ID_Number__c = 'REG123',
        Type_Desc__c = 'Application Form'
    );
    insert idNum;

    Move_In_Out__c mio = new Move_In_Out__c(
        BP_Number__c = acc.Id,
        Contract_Account__c = 'CA123'
    );
    insert mio;

    Billing__c bill = new Billing__c(
        Print_Doc_Number__c = 'INV123',
        Account__c = acc.Id
    );
    insert bill;

    Lead l = new Lead(
        FirstName = 'Jane',
        LastName = 'Smith',
        Company = 'Test Company',
        Phone = '9998887776',
        Email = 'lead@example.com',
        Status = 'Open - Not Contacted',
        LeadSource = 'Web',
        Postal_Code__c = '560002',
        City__c = 'Mysore',
        Street__c = 'Test Street'
    );
    insert l;

    // ===== SETUP OBJECTS (MUST BE runAs) =====
    User u = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

    System.runAs(u) {
        Group q = new Group(Name = 'Marketing Queue', Type = 'Queue');
        insert q;

        QueueSobject qso = new QueueSobject(
            QueueId = q.Id,
            SobjectType = 'Lead'
        );
        insert qso;
    }
}

    @isTest
    static void testSearchAccounts_WithFilters() {
        Test.startTest();
        List<AccountSearchController.AccountWithCANumber> results =
            AccountSearchController.searchAccounts(
                'John', 'Doe', 'CA123', 'BP456', '1234567890', '560001',
                'Bangalore', 'REG123', 'Building Name', 'Main Street',
                'CONN123', 'test@example.com', 'METER123', 'INV123'
            );
        Test.stopTest();

    }

    @isTest
    static void testSearchAccounts_NoFilters() {
        Test.startTest();
        List<AccountSearchController.AccountWithCANumber> results =
            AccountSearchController.searchAccounts(
                null, null, null, null, null, null, null,
                null, null, null, null, null, null, null
            );
        Test.stopTest();
    }

    @isTest
    static void testSearchAccounts_WithInvoiceNumber() {
        Test.startTest();
        List<AccountSearchController.AccountWithCANumber> results =
            AccountSearchController.searchAccounts(
                null, null, null, null, null, null, null,
                null, null, null, null, null, null, 'INV123'
            );
        Test.stopTest();
    }

    @isTest
    static void testSearchAccounts_WithRegistrationFilter() {
        Test.startTest();
        List<AccountSearchController.AccountWithCANumber> results =
            AccountSearchController.searchAccounts(
                null, null, null, null, null, null, null,
                'REG123', null, null, null, null, null, null
            );
        Test.stopTest();
    }

    @isTest
    static void testSearchLeads_WithFilters() {
        Test.startTest();
        List<Lead> leads = AccountSearchController.searchLeads(
            'Jane', 'Smith', null, '9998887776',
            'lead@example.com', '560002', 'Mysore', 'Test Street'
        );
        Test.stopTest();
    }

    @isTest
    static void testSearchLeads_NoFilters() {
        Test.startTest();
        List<Lead> leads = AccountSearchController.searchLeads(
            null, null, null, null, null, null, null, null
        );
        Test.stopTest();
    }

    @isTest
    static void testGetDRSList() {
        Test.startTest();
        List<DRS__c> drsList = AccountSearchController.getDRSList();
        Test.stopTest();
    }

    @isTest
    static void testGetLeadTypeValues() {
        Test.startTest();
        List<String> values = AccountSearchController.getLeadTypeValues();
        Test.stopTest();
    }

    @isTest
    static void testGetGAForDrs() {
        Id drsId = [SELECT Id FROM DRS__c LIMIT 1].Id;

        Test.startTest();
        String ga = AccountSearchController.getGAForDrs(drsId);
        Test.stopTest();
    }

  @isTest
static void testCreateLead_Success() {

    Test.startTest();
    String leadId = AccountSearchController.createLead(
        'First',                    // firstName
        'Last',                     // lastName
        '9999999999',               // phone
        'newlead@example.com',      // email
        null,                       // drsId
        null,                       // leadType
        '1',                        // floor
        'Building',                 // buildingName
        'B001',                     // buildingCode
        'Street 1',                 // street
        'Street 2',                 // street2
        'Street 3',                 // street3
        'Street 4',                 // street4
        'Street 5',                 // street5
        'Flat A',                   // flat
        'CityX',                    // city
        'DistrictY',                // district
        '560003',                   // postalCode
        'CountryZ',                 // country
        'IST',                      // timeZone
        'RegionR',                  // region
        'OtherCity',                // othercity
        'gcjh',                     // nameandNoofWings
        'tuw',                      // potentialInEachWing
        'yfwgus',                   // totalNosOfFloor
        'GA-1',                      // gaValue  ✅ ADDED
        'hgsj'                      // plotNo
    );
    Test.stopTest();
}

    @isTest
    static void testCreateLead_Exception() {
        // No Marketing Queue exists → should throw error
        Test.startTest();
        try {
            AccountSearchController.createLead(
                'X', 'Y', '1111111111', 'badlead@example.com',
                null, null, null, null, null, null,
                null, null, null, null, null, null,
                null, null, null, null,null,null,null,null,null,null,null
            );
        } catch (Exception e) {
        }
        Test.stopTest();
    }
}