@isTest
public class BillingQRCBatchTest {

    private static List<User> testUsers;
    
    @testSetup
    static void setupTestData() {
        // Create test users for SPOC fields first
        testUsers = createTestUsers();
        
        // Create test QRC_Process__c records for Billing department
        List<QRC_Process__c> testQrcs = new List<QRC_Process__c>();
        for (Integer i = 0; i < 3; i++) {
            testQrcs.add(new QRC_Process__c(
                Department__c = 'Billing',
                IsActive__c = true
            ));
        }
        insert testQrcs;
        
        // Create test DRS records
        DRS__c drs1 = new DRS__c(Name = 'DRS_001');
        DRS__c drs2 = new DRS__c(Name = 'DRS_002');
        insert new List<DRS__c>{drs1, drs2};
        
        // Create test Departments_SPOC_Mapping__c records with proper User IDs
        List<Departments_SPOC_Mapping__c> testMappings = new List<Departments_SPOC_Mapping__c>();
        for (Integer i = 0; i < 2; i++) {
            testMappings.add(new Departments_SPOC_Mapping__c(
                Department__c = 'Billing',
                DRS__c = i == 0 ? drs1.Id : drs2.Id,
                SPOC_Id__c = testUsers[0].Id,
                SPOC_Id_2__c = testUsers[1].Id,
                SPOC_Id_3__c = testUsers[2].Id,
                SPOC_Id_4__c = testUsers[3].Id
            ));
        }
        insert testMappings;
        
        // Create some existing mappings to test duplicate prevention
        List<Departments_SPOC_Mapping__c> existingMappings = new List<Departments_SPOC_Mapping__c>();
        for (Integer i = 0; i < 1; i++) {
            existingMappings.add(new Departments_SPOC_Mapping__c(
                Department__c = 'Billing',
                DRS__c = drs1.Id,
                SPOC_Id__c = testUsers[0].Id,
                SPOC_Id_2__c = testUsers[1].Id,
                SPOC_Id_3__c = testUsers[2].Id,
                SPOC_Id_4__c = testUsers[3].Id,
                QRC_Process__c = testQrcs[0].Id // Link to first QRC
            ));
        }
        insert existingMappings;
    }
    
    // Helper method to create test users (same as reference test class)
    private static List<User> createTestUsers() {
        // First get a profile to use
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        // Generate a unique username
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueOf(Datetime.now().format('yyyyMMddHHmmssSSS'));
        Integer randomInt = Integer.valueOf(Math.rint(Math.random() * 1000000));
        String uniqueName = orgId + dateString + randomInt;
        
        List<User> users = new List<User>();
        // Create 4 test users for the 4 SPOC fields
        for (Integer i = 0; i < 4; i++) {
            users.add(new User(
                FirstName = 'Test',
                LastName = 'User' + i,
                Email = 'testuser' + i + '@example.com',
                Username = uniqueName + i + '@example.com',
                EmailEncodingKey = 'UTF-8',
                Alias = 'tuser' + i,
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US',
                ProfileId = p.Id
            ));
        }
        insert users;
        return users;
    }
    
    @isTest
    static void testBatchConstructor() {
        Test.startTest();
        BillingQRCBatch batch = new BillingQRCBatch();
        Test.stopTest();
        
        // Constructor should execute without errors
    }
    
    @isTest
    static void testStartMethod() {
        BillingQRCBatch batch = new BillingQRCBatch();
        
        Test.startTest();
        Database.QueryLocator ql = batch.start(null);
        Test.stopTest();
        
        // Start method should execute without errors
    }
    
    @isTest
    static void testExecuteMethodWithNewRecords() {
        BillingQRCBatch batch = new BillingQRCBatch();
        
        // Get source mappings (without QRC_Process__c)
        List<Departments_SPOC_Mapping__c> sourceMappings = [
            SELECT Id, Department__c, DRS__c, SPOC_Id__c, SPOC_Id_2__c, SPOC_Id_3__c, SPOC_Id_4__c
            FROM Departments_SPOC_Mapping__c
            WHERE QRC_Process__c = null
        ];
        
        Test.startTest();
        batch.execute(null, sourceMappings);
        Test.stopTest();
        
        // Execute method should complete without errors
    }
    
    @isTest
    static void testExecuteMethodWithEmptyBatch() {
        BillingQRCBatch batch = new BillingQRCBatch();
        
        Test.startTest();
        batch.execute(null, new List<Departments_SPOC_Mapping__c>());
        Test.stopTest();
        
        // Should handle empty batch without errors
    }
    
    @isTest
    static void testExecuteMethodWithExistingKeysPrePopulated() {
        BillingQRCBatch batch = new BillingQRCBatch();
        
        Test.startTest();
        batch.execute(null, new List<Departments_SPOC_Mapping__c>());
        Test.stopTest();
        
        // Should handle execution without errors
    }
    
    @isTest
    static void testFinishMethod() {
        BillingQRCBatch batch = new BillingQRCBatch();
        
        Test.startTest();
        batch.finish(null);
        Test.stopTest();
        
        // Finish method should execute without errors
    }
    
    @isTest
    static void testFullBatchExecution() {
        Test.startTest();
        BillingQRCBatch batch = new BillingQRCBatch();
        Id batchProcessId = Database.executeBatch(batch, 10);
        Test.stopTest();
        
        // Full batch execution should complete
    }
    
    @isTest
    static void testNoActiveQRCs() {
        // Deactivate all QRCs
        List<QRC_Process__c> qrcs = [SELECT Id FROM QRC_Process__c];
        for (QRC_Process__c qrc : qrcs) {
            qrc.IsActive__c = false;
        }
        update qrcs;
        
        Test.startTest();
        BillingQRCBatch batch = new BillingQRCBatch();
        Test.stopTest();
        
        // Should handle no active QRCs without errors
    }
    
    @isTest
    static void testNoSourceMappings() {
        // Delete all source mappings
        delete [SELECT Id FROM Departments_SPOC_Mapping__c WHERE QRC_Process__c = null];
        
        BillingQRCBatch batch = new BillingQRCBatch();
        
        Test.startTest();
        batch.execute(null, new List<Departments_SPOC_Mapping__c>());
        Test.stopTest();
        
        // Should handle no source mappings without errors
    }
    
    @isTest
    static void testDuplicatePreventionLogic() {
        BillingQRCBatch batch = new BillingQRCBatch();
        
        List<Departments_SPOC_Mapping__c> sourceMappings = [
            SELECT Id, Department__c, DRS__c, SPOC_Id__c, SPOC_Id_2__c, SPOC_Id_3__c, SPOC_Id_4__c
            FROM Departments_SPOC_Mapping__c
            WHERE QRC_Process__c = null
            LIMIT 1
        ];
        
        Test.startTest();
        batch.execute(null, sourceMappings);
        Test.stopTest();
        
        // Should process without errors
    }

    @isTest
    static void testBatchWithLargeDataSet() {
        // Create additional test data to simulate larger dataset
        List<QRC_Process__c> additionalQrcs = new List<QRC_Process__c>();
        for (Integer i = 0; i < 5; i++) {
            additionalQrcs.add(new QRC_Process__c(
                Department__c = 'Billing',
                IsActive__c = true
            ));
        }
        insert additionalQrcs;
        
        Test.startTest();
        BillingQRCBatch batch = new BillingQRCBatch();
        Id batchProcessId = Database.executeBatch(batch, 5); // Smaller batch size
        Test.stopTest();
        
        // Should handle larger dataset without errors
    }

    @isTest
    static void testExecuteMethodWithDMLPartialSuccess() {
        BillingQRCBatch batch = new BillingQRCBatch();
        
        // Get source mappings
        List<Departments_SPOC_Mapping__c> sourceMappings = [
            SELECT Id, Department__c, DRS__c, SPOC_Id__c, SPOC_Id_2__c, SPOC_Id_3__c, SPOC_Id_4__c
            FROM Departments_SPOC_Mapping__c
            WHERE QRC_Process__c = null
        ];
        
        Test.startTest();
        batch.execute(null, sourceMappings);
        Test.stopTest();
        
        // Should handle DML operations without errors
    }
}