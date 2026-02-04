@isTest
private class UpdateCustomerDataMappingBatch_Test {

    @testSetup
    static void setupData() {
        // Create Account records
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 3; i++) {
            accounts.add(new Account(Name = 'Test Account ' + i,Category__c='Domestic'));
        }
        insert accounts;

        // Create Installation records (assuming Installation__c is a lookup to another object; we'll mock it with an sObject)
        // In case Installation__c is a standard object, adjust accordingly
        // Here, we use dummy Ids for test purposes (real implementation should use actual objects)
        // 
        
        Installation__c installRec=new Installation__c();
        insert installRec;

        // Create Move_In_Out__c records linking Account Ids with Installation Ids
        List<Move_In_Out__c> moveInOutList = new List<Move_In_Out__c>();
        for (Account acc : accounts) {
            moveInOutList.add(new Move_In_Out__c(
                BP_Number__c = acc.Id,
                Installation_Name__c = installRec.Id // assuming using Account Id as Installation Id for simplicity
                //Installation_Name__c = 'Installation ' + acc.Name
            ));
        }
        insert moveInOutList;

        // Create Device__c records (assuming it exists)
        List<Device__c> devices = new List<Device__c>();
        for (Account acc : accounts) {
            devices.add(new Device__c(Name = 'Device ' + acc.Name,Installation__c=installRec.Id));
        }
        insert devices;

        // Create Device_Allocation__c records linking Installations to Devices
        List<Device_Allocation__c> deviceAllocations = new List<Device_Allocation__c>();
        for (Integer i = 0; i < accounts.size(); i++) {
            deviceAllocations.add(new Device_Allocation__c(
                Installation__c = installRec.Id,
                Device__c = devices[i].Id
            ));
        }
        insert deviceAllocations;
    }

    @isTest
    static void testExecuteUpdatesAccounts() {
        // Fetch all accounts
        List<Account> accounts = [SELECT Id, Meter_Number__c FROM Account];

        Test.startTest();
        // Instantiate and run the batch
        UpdateCustomerDataMappingBatch batch = new UpdateCustomerDataMappingBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest(); 
    }

    @isTest
    static void testExecuteWithNoMatchingData() {
        // Create an account that won't match any Move_In_Out__c
        Account acc = new Account(Name = 'Unlinked Account');
        insert acc;

        Test.startTest();
        UpdateCustomerDataMappingBatch batch = new UpdateCustomerDataMappingBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();
    }
}