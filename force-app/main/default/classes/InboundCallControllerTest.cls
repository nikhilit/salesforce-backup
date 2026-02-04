@isTest
public class InboundCallControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test user with agent ID
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        String timestamp = String.valueOf(Datetime.now().getTime());
        
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'Agent',
            Email = 'testagent.' + timestamp + '@test.com',
            Username = 'testagent.' + timestamp + '@test.com.uniquedomain',
            Alias = 'tagent',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            ProfileId = p.Id,
            Agent_Id__c = 'AGENT123'
        );
        insert testUser;
        
        // Create test accounts with phone numbers
        List<Account> testAccounts = new List<Account>{
            new Account(Name = 'Test Account 1', Phone = '1234567890'),
            new Account(Name = 'Test Account 2', Phone = '9876543210'),
            new Account(Name = 'Test Account 3', Phone = '5555555555')
        };
        insert testAccounts;
    }
    
    
    
    @isTest
    static void testGetAccountIdByPhoneAgentIdMismatch() {
        // Get test user by Username instead of Agent_Id__c
        User testUser = [SELECT Id, Agent_Id__c FROM User WHERE Username LIKE 'testagent.%' LIMIT 1];
        
        Inbound_Call__c callRec = new Inbound_Call__c(
            PhoneNumber__c = '9876543210',
            Agent_Id__c = 'AGENT123',
            Status__c='New'
        );
        insert callRec;
        
        System.runAs(testUser) {
            Test.startTest();
            List<Account> result = InboundCallController.getAccountIdByPhone('1234567890', 'WRONGAGENT');
            InboundCallController.getLatestInboundCall('AGENT123');
            InboundCallController.markCallAsShown(callRec.Id);
            Test.stopTest();
        }
    }
    
    @isTest
    static void testGetAccountIdByPhoneNoAccountFound() {
        // Get test user by Username instead of Agent_Id__c
        User testUser = [SELECT Id, Agent_Id__c FROM User WHERE Username LIKE 'testagent.%' LIMIT 1];
        
        System.runAs(testUser) {
            Test.startTest();
            List<Account> result = InboundCallController.getAccountIdByPhone('0000000000', 'AGENT123');
            Test.stopTest();
        }
    }
    
    @isTest
    static void testGetAccountIdByPhoneMultipleAccounts() {
        // Create additional account with same phone number
        Account dupAccount = new Account(Name = 'Duplicate Account', Phone = '1234567890');
        insert dupAccount;
        
        // Get test user by Username instead of Agent_Id__c
        User testUser = [SELECT Id, Agent_Id__c FROM User WHERE Username LIKE 'testagent.%' LIMIT 1];
        
        System.runAs(testUser) {
            Test.startTest();
            List<Account> result = InboundCallController.getAccountIdByPhone('1234567890', 'AGENT123');
            Test.stopTest();
        }
    }
    
    @isTest
    static void testGetAccountIdByPhoneUserWithoutAgentId() {
        // Create user without agent ID
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User noAgentUser = new User(
            FirstName = 'No',
            LastName = 'Agent',
            Email = 'noagent@test.com',
            Username = 'noagent@test.com.uniquedomain',
            Alias = 'nagent',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            ProfileId = p.Id
        );
        insert noAgentUser;
        
        System.runAs(noAgentUser) {
            Test.startTest();
            List<Account> result = InboundCallController.getAccountIdByPhone('1234567890', null);
            Test.stopTest();
        }
    }
}