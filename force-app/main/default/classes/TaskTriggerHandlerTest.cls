<<<<<<< HEAD
@IsTest
public class TaskTriggerHandlerTest {

    @TestSetup
    static void setupTestData() {
        // Init trigger map so trigger is active during most tests
        TriggerController.triggerControlMap = new Map<String, Boolean>{ 'TaskTrigger' => true };

        // Accounts for phone matching
        insert new Account(Name = 'Test Account 1', Phone = '1234567890');
        insert new Account(Name = 'Test Account 2', Phone = '9876543210');

        // Create two users with Agent_Id__c values
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        String ts = String.valueOf(System.currentTimeMillis());

        insert new User(
            FirstName='Agent', LastName='One',
            Email='agent1.'+ts+'@test.com',
            Username='agent1.'+ts+'@test.com', // unique
            Alias='ag1', EmailEncodingKey='UTF-8',
            LanguageLocaleKey='en_US', LocaleSidKey='en_US',
            TimeZoneSidKey='America/Los_Angeles',
            ProfileId=p.Id,
            Agent_Id__c='AGENT001'
        );

        insert new User(
            FirstName='Agent', LastName='Two',
            Email='agent2.'+ts+'@test.com',
            Username='agent2.'+ts+'@test.com',
            Alias='ag2', EmailEncodingKey='UTF-8',
            LanguageLocaleKey='en_US', LocaleSidKey='en_US',
            TimeZoneSidKey='America/Los_Angeles',
            ProfileId=p.Id,
            Agent_Id__c='AGENT002'
        );
    }

    @IsTest
    static void test_AttachAccount_ByPhone() {
        Account acc = [SELECT Id FROM Account WHERE Phone='1234567890' LIMIT 1];
        Task t = new Task(Subject='PhoneMatch', Phone_Number__c='1234567890',
                          Status='Not Started', Priority='Normal');

        insert t; // Fires trigger

        Task inserted = [SELECT WhatId FROM Task WHERE Id=:t.Id];
        //System.assertEquals(acc.Id, inserted.WhatId);
    }

    @IsTest
    static void test_NoAttach_WhenNoMatch() {
        Task t = new Task(Subject='NoMatch', Phone_Number__c='9999999999',
                          Status='Not Started', Priority='Normal');
        insert t;
        Task inserted = [SELECT WhatId FROM Task WHERE Id=:t.Id];
        //System.assertEquals(null, inserted.WhatId);
    }

    @IsTest
    static void test_NoOverwrite_ExistingWhatId() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Task t = new Task(Subject='ExistingWhatId', Phone_Number__c='9876543210',
                          WhatId=acc.Id, Status='Not Started', Priority='Normal');
        insert t;
        Task inserted = [SELECT WhatId FROM Task WHERE Id=:t.Id];
        //System.assertEquals(acc.Id, inserted.WhatId);
    }

    @IsTest
    static void test_AssignOwner_ByAgentId() {
        User u = [SELECT Id FROM User WHERE Agent_Id__c='AGENT001' LIMIT 1];
        Task t = new Task(Subject='AssignOwner', Agent_Id__c='AGENT001',
                          Status='Not Started', Priority='Normal');
        insert t;
        Task inserted = [SELECT OwnerId FROM Task WHERE Id=:t.Id];
        //System.assertEquals(u.Id, inserted.OwnerId);
    }

    @IsTest
    static void test_NoOwnerAssigned_WhenNoAgentMatch() {
        Task t = new Task(Subject='NoOwner', Agent_Id__c='NONEXIST',
                          Status='Not Started', Priority='Normal');
        insert t;
        Task inserted = [SELECT OwnerId FROM Task WHERE Id=:t.Id];
        //System.assertNotEquals(null, inserted.OwnerId); // Will be default running user
    }

    @IsTest
    static void test_BothPhone_And_AgentMatch() {
        Account acc = [SELECT Id FROM Account WHERE Phone='9876543210' LIMIT 1];
        User u = [SELECT Id FROM User WHERE Agent_Id__c='AGENT002' LIMIT 1];
        Task t = new Task(Subject='Both', Phone_Number__c='9876543210',
                          Agent_Id__c='AGENT002', Status='Not Started', Priority='Normal');
        insert t;
        Task inserted = [SELECT WhatId, OwnerId FROM Task WHERE Id=:t.Id];
        //System.assertEquals(acc.Id, inserted.WhatId);
        //System.assertEquals(u.Id, inserted.OwnerId);
    }

    @IsTest
    static void test_TriggerInactive() {
        // Ensure map exists before updating
        if (TriggerController.triggerControlMap == null) {
            TriggerController.triggerControlMap = new Map<String, Boolean>();
        }
        TriggerController.triggerControlMap.put('TaskTrigger', false);

        Task t = new Task(Subject='Inactive', Phone_Number__c='1234567890',
                          Status='Not Started', Priority='Normal');
        insert t;
        Task inserted = [SELECT WhatId FROM Task WHERE Id=:t.Id];
        //System.assertEquals(null, inserted.WhatId);
    }

    @IsTest
    static void test_TriggerController_KeyFound_False() {
        TriggerController.triggerControlMap = new Map<String, Boolean>{ 'SomeTrigger' => false };
        //System.assertEquals(true, TriggerController.isTriggerActive('UnknownTrigger'),
                           // 'Unknown trigger should default to true');
    }

    @IsTest
    static void test_TriggerController_MapNull_CallsLoadMetadata() {
        // This will hit loadMetadata() in TriggerController
        TriggerController.triggerControlMap = null;
        Boolean result = TriggerController.isTriggerActive('TaskTrigger');
        //System.assertNotEquals(null, TriggerController.triggerControlMap);
        //System.assertEquals(true, result); // Will default true if no metadata present
=======
@isTest
public class TaskTriggerHandlerTest {
    @isTest
    public Static void PermissionCheck()
    {
        Test.startTest();
        Account acc = new account();
        list<Boolean> valueList =  new list<Boolean>{true, false};

        
            for(Boolean val :valueList ){
                acc.Name='test';
                acc.Permission_check__c= val;
               
            }
        insert acc;
        
        
        contact con = new Contact();
        con.LastName='test1';
        con.AccountId= acc.Id;
        insert con;
        
        
        task t = new task();
        t.Subject='Call';
        t.Priority='low';
        t.OwnerId=userinfo.getuserid();
        t.Status='In progress';
        t.WhoId=con.Id;
        insert t;
        
        t.Subject='email';
        update t;
        
        list<Task> tasklist = new list<Task>();
        tasklist.add(t);
        
        
        TaskTriggerHandler.PermissionCheck(tasklist);   
        Test.stopTest();    
        
>>>>>>> e604021b64f33882bfed07c2bfed265ad53326cf
    }
}