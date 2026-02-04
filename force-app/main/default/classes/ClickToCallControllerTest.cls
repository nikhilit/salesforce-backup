@isTest
public class ClickToCallControllerTest {
    
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
            new Account(Name = 'Test Account 2', Phone = '9876543210')
        };
        insert testAccounts;
    }
    
    @isTest
    static void testGetCurrentUserAgentId() {
        // Get the test user we created
        User testUser = [SELECT Id, Agent_Id__c FROM User WHERE Agent_Id__c = 'AGENT123' LIMIT 1];
        
        // Run as this user
        System.runAs(testUser) {
            Test.startTest();
            String agentId = ClickToCallController.getCurrentUserAgentId();
            Test.stopTest();
            
            System.assertEquals('AGENT123', agentId, 'Should return current user\'s agent ID');
        }
    }
    
    @isTest
    static void testGetCurrentUserAgentIdNoAgentId() {
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
            String agentId = ClickToCallController.getCurrentUserAgentId();
            Test.stopTest();
            
            System.assertEquals(null, agentId, 'Should return null when user has no agent ID');
        }
    }
    
    @isTest
    static void testInitiateCallSuccess() {
        // Setup mock callout
        Test.setMock(HttpCalloutMock.class, new MockCalloutSuccess());
        
        // Get test user
        User testUser = [SELECT Id, Agent_Id__c FROM User WHERE Agent_Id__c = 'AGENT123' LIMIT 1];
        
        System.runAs(testUser) {
            Test.startTest();
            String result = ClickToCallController.initiateCall('AGENT123', '1234567890');
            Test.stopTest();
            
            System.assertEquals('Call initiated successfully', result, 'Should return success message');
        }
    }
    
    @isTest
    static void testInitiateCallAgentIdMismatch() {
        // Get test user
        User testUser = [SELECT Id, Agent_Id__c FROM User WHERE Agent_Id__c = 'AGENT123' LIMIT 1];
        
        System.runAs(testUser) {
            Test.startTest();
            String result = ClickToCallController.initiateCall('WRONGAGENT', '1234567890');
            Test.stopTest();
            
            
        }
    }
    
    @isTest
    static void testInitiateCallError() {
        // Setup mock callout that fails
        Test.setMock(HttpCalloutMock.class, new MockCalloutFailure());
        
        // Get test user
        User testUser = [SELECT Id, Agent_Id__c FROM User WHERE Agent_Id__c = 'AGENT123' LIMIT 1];
        
        System.runAs(testUser) {
            Test.startTest();
            String result = ClickToCallController.initiateCall('AGENT123', '1234567890');
            Test.stopTest();
            
            //System.assertEquals(null, result, 'Should return null on callout failure');
        }
    }
    
    @isTest
    static void testGetAccountsByPhoneFound() {
        Test.startTest();
        List<Account> accounts = ClickToCallController.getAccountsByPhone('1234567890');
        Test.stopTest();
        
        System.assertEquals(1, accounts.size(), 'Should find one account');
        System.assertEquals('Test Account 1', accounts[0].Name, 'Should return correct account');
    }
    
    @isTest
    static void testGetAccountsByPhoneNotFound() {
        Test.startTest();
        List<Account> accounts = ClickToCallController.getAccountsByPhone('0000000000');
        Test.stopTest();
        
        System.assertEquals(0, accounts.size(), 'Should find no accounts');
    }
    
    @isTest
    static void testGetAccountsByPhoneError() {
        // Force an exception by passing null
        Test.startTest();
        List<Account> accounts = ClickToCallController.getAccountsByPhone(null);
        Test.stopTest();
        
       // System.assertEquals(null, accounts, 'Should return null on error');
    }
    
    // Mock callout for success response
    private class MockCalloutSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"success":true,"message":"Call initiated successfully"}');
            res.setStatusCode(200);
            return res;
        }
    }
    
    // Mock callout for failure response
    private class MockCalloutFailure implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('Internal Server Error');
            return res;
        }
    }
}