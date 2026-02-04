/*@author : Hira Prabhu Kholkar
 * @last modified on  : 08-01-2025    */
 
@isTest
public class ApprovalControllerTest {
 
    @testSetup
    static void setupTestData() {
        // Create a test user
   //     User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
   Profile portalProfile = [select Id from Profile where Name = 'System Administrator' limit 1];
        User use = [select Id From User where Id =: UserInfo.getUserId() LIMIT 1];
 
        User testUser = new User();
        System.runAs(use){
             testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'tuser',
    //        ContactId = newContact[0].Id,
            ProfileId = portalProfile.Id,
            Email = 'testuser@test.com',
            Username = 'zzanak@communityuser.com',
            CommunityNickname = 'testuser',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
            //     HOD__c = use.Id
        );
        insert testUser;
        }
       
        User testUser2 = new User();
        System.runAs(use){
             testUser2 = new User(
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'tuser',
    //        ContactId = newContact[0].Id,
            ProfileId = portalProfile.Id,
            Email = 'testuser@test.com',
            Username = 'zzanak123@communityuser.com',
            CommunityNickname = 'tesdstuser',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
               //  HOD__c = testUser.Id
        );
        insert testUser2;
        }
        system.debug('testUser2::'+testUser2);
       
       
        //System.runAs(testUser) {
            // Mock custom metadata by creating a map in memory
            Map<String, String> mockMetadataMap = new Map<String, String>{
                'TestApprovalProcess1' => 'TestTab1',
                'TestApprovalProcess2' => 'TestTab2'
            };
               
  //          ApprovalController.setTestMetadata(mockMetadataMap); // Update the class to handle this.
 
            // Create a custom object record as target for approval
            Account acc = new Account(Name = 'Test Account');
            insert acc;
            System.debug('acc: ' + acc);
           
            Opportunity opp = new Opportunity(Name = 'Test Opportunity', StageName = 'Commercial', CloseDate = Date.today());
        insert opp;
         //   System.runAs(testUser2){
            quote testQuote = new quote();
            testQuote.name = 'test';
            testQuote.OpportunityId = opp.Id;
           // testQuote.HOD__c = testUser.Id;
            Insert testQuote;
           // }
          /*  Upload_PJP__c pjpPlan = new Upload_PJP__c();
        pjpPlan.Beats_Name__c = 'test';
        pjpPlan.Effective_Start_Date__c = Date.today();
        pjpPlan.Effective_End_Date__c = Date.today()+5;
        Insert pjpPlan; */
      //}
    }
 
    @isTest
    static void testGetApprovalRequests() {
               
  /*   User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        Profile portalProfile = [select Id from Profile where Name = 'HOD' limit 1];
        User use = [select Id From User where Id =: UserInfo.getUserId() LIMIT 1];
 */
        Profile portalProfile = [select Id from Profile where Name='System Administrator' limit 1];
 
        User testUser = new User();
       // System.runAs(use){
             testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'tuser',
    //      ContactId = newContact[0].Id,
            ProfileId = portalProfile.Id,
            Email = 'testuser@test.com',
            Username = 'zzanakhh@communityuser.com',
            CommunityNickname = 'testhjguser',
            TimeZoneSidKey = 'GMT',
            ManagerId=UserInfo.getUserId(),
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
            // HOD__c = testUser.Id
        );
        insert testUser;
      //  }
       
      //  System.runAs(testUser) {
            // Mock custom metadata by creating a map in memory
            Map<String, String> mockMetadataMap = new Map<String, String>{
                'TestApprovalProcess1' => 'TestTab1',
                'TestApprovalProcess2' => 'TestTab2'
            };
  //          ApprovalController.setTestMetadata(mockMetadataMap); // Update the class to handle this.
 
            // Create a custom object record as target for approval
          /*   Account acc = new Account();
             acc.Name='test account';
            acc.Name_1__c='test';
            acc.cgcloud__Name_2__c='account';
            acc.AccountNumber='122121';
       
            insert acc;
            System.debug('acc: ' + acc);
           
            Opportunity opp = new Opportunity(Name = 'Test Opportunity', StageName = 'Commercial', CloseDate = Date.today());
        insert opp;
           
            quote testQuote = new quote();
            testQuote.name = 'test';
            testQuote.OpportunityId = opp.Id;
           // testQuote.HOD__c = UserInfo.getUserId() ;
            Insert testQuote;
           
            Quote qtresult = [SELECT Id,HOD__c from Quote WHERE Id=:testQuote.Id LIMIT 1];
           
        Upload_PJP__c pjpPlan = [SELECT Id from Upload_PJP__c LIMIT 1];
           
            System.debug('qtresult ::>> ' + qtresult); */
       
 
                 WorkType testWorkType = new WorkType(
        Name = 'Test WorkType',
        EstimatedDuration = 2.5,
        DurationType = 'Hours'
    );
    insert testWorkType;
       
          WorkOrder testWorkOrder = new WorkOrder(
        WorkTypeId = testWorkType.Id,
        Status = 'New'
     //   Approval_Status__c = getValidApprovalStatus()
    );
    insert testWorkOrder;
           
 
        // Get the ProcessDefinition for the approval process
        ProcessDefinition processDefinition = [SELECT Id FROM ProcessDefinition WHERE DeveloperName='IPDAICSiteDocumentApprovalProcess' LIMIT 1];
        System.debug('processDefinition::' + processDefinition);
 
        // Submit the Order__c records for approval
            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
            req1.setComments('Testing Purpose');
            req1.setObjectId(testWorkOrder.Id);
            req1.setSubmitterId(testUser.id);
            req1.setProcessDefinitionNameOrId('IPDAICSiteDocumentApprovalProcess');
            req1.setSkipEntryCriteria(true);
            System.debug('req1'+req1);
           // Test.startTest();
            Approval.ProcessResult result = Approval.process(req1);
            System.debug('result'+result);
           // Test.stopTest();
           //
                   List<ProcessInstanceWorkitem> approvalRequests =  [SELECT Id, ActorId, ProcessInstance.TargetObjectId,
                                        ProcessInstance.TargetObject.Name, ProcessInstance.Status,
                                        ProcessInstance.ProcessDefinition.Name,
                                        ProcessInstance.ProcessDefinition.DeveloperName,ProcessInstance.CreatedBy.Name,
                                        CreatedDate
                                    FROM ProcessInstanceWorkitem
                                    WHERE ActorId = :UserInfo.getUserId()
                                    AND ProcessInstance.Status = 'Pending' and CreatedDate = Today
                                    ORDER BY CreatedDate ASC
            ];
            System.debug('approvalRequests::test: ' + approvalRequests);
 /*
            System.debug('Approval process result::' + result);
            List<ProcessInstance> pi = [SELECT Id, Status, TargetObjectId, CreatedDate FROM ProcessInstance WHERE ProcessDefinitionId = :processDefinition.Id AND TargetObjectId = :testQuote.Id  LIMIT 1];
            System.debug('pi::' + pi);
           
            // Approve the Order__c if submitted successfully
            if (result.isSuccess()) {
                Id workItemId = null;
                for (ProcessInstanceWorkitem workItem : [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstanceId = :pi[0].Id AND ProcessInstance.Status = 'Pending' AND ActorId= :UserInfo.getUserId()ORDER BY CreatedDate ASC ]) {
                    workItemId = workItem.Id;
                   
                }
 
                if (workItemId != null) {
                    Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
                    req2.setAction('Approve');
                    req2.setComments('Anything');
                    req2.setWorkitemId(workItemId);
 
                    System.debug('req2'+req2);
                   // Test.startTest();
                    Approval.ProcessResult processResult = Approval.process(req2);
                   // Test.stopTest();
 
                    System.debug('Approval process work item result::' + processResult);
                }
            }
            */
           
            Test.startTest();
           // System.runAs(testUser){
        List<ApprovalController.ApprovalWrapClass> approvalRequestsResult = ApprovalController.getApprovalRequests();
 
        Test.stopTest();
            //}
       //}
       
    }
 /*   @isTest
    static void testHandleApproval() {
        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        System.runAs(testUser) {
            // Mock custom metadata by creating a map in memory
            Map<String, String> mockMetadataMap = new Map<String, String>{
                'TestApprovalProcess1' => 'TestTab1',
                'TestApprovalProcess2' => 'TestTab2'
            };
  //          ApprovalController.setTestMetadata(mockMetadataMap); // Update the class to handle this.
 
            // Create a custom object record as target for approval
            Account acc = new Account(Name = 'Test Account');
            insert acc;
            System.debug('acc: ' + acc);
           
            Opportunity opp = new Opportunity(Name = 'Test Opportunity', StageName = 'Commercial', CloseDate = Date.today());
        insert opp;
           
            quote testQuote = new quote();
            testQuote.name = 'test';
            testQuote.OpportunityId = opp.Id;
            Insert testQuote;
           
 
        // Get the ProcessDefinition for the approval process
        ProcessDefinition processDefinition = [SELECT Id FROM ProcessDefinition WHERE DeveloperName='Quote_Approval_Process' LIMIT 1];
        System.debug('processDefinition::' + processDefinition);
 
        // Submit the Order__c records for approval
            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
            req1.setComments('Testing Purpose');
            req1.setObjectId(testQuote.Id);
            req1.setSubmitterId(UserInfo.getUserId());
            req1.setProcessDefinitionNameOrId('Quote_Approval_Process');
            req1.setSkipEntryCriteria(true);
 
            System.debug('req1'+req1);
           // Test.startTest();
            Approval.ProcessResult result = Approval.process(req1);
           // Test.stopTest();
 
            System.debug('Approval process result::' + result);
 
            // Approve the Order__c if submitted successfully
            if (result.isSuccess()) {
                Id workItemId = null;
                for (ProcessInstanceWorkitem workItem : [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId = :testQuote.Id]) {
                    workItemId = workItem.Id;
                }
 
                if (workItemId != null) {
                    Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
                    req2.setAction('Approve');
                    req2.setComments('Anything');
                    req2.setWorkitemId(workItemId);
 
                    System.debug('req2'+req2);
                   // Test.startTest();
                    Approval.ProcessResult processResult = Approval.process(req2);
                   // Test.stopTest();
 
                    System.debug('Approval process work item result::' + processResult);
                }
            }
 
        Test.startTest();
    List<ApprovalController.ApprovalWrapClass> HandleApproval = ApprovalController.HandleApproval();
  /*      // Get the work item created in test setup
        ProcessInstanceWorkitem workItem = [SELECT Id FROM ProcessInstanceWorkitem LIMIT 1];
 
        // Create payload
        List<ApprovalController.payLoadWrapper> payload = new List<ApprovalController.payLoadWrapper>();
        ApprovalController.payLoadWrapper wrapper = new ApprovalController.payLoadWrapper();
        wrapper.workItemIds = workItem.Id;
        wrapper.comment = 'Test comment';
        payload.add(wrapper);
 
        // Call the method with Approve action
        String result = ApprovalController.handleApproval(payload, 'Approve', 'Common comment');
       
        // Assert the result
    ////    System.assertEquals('Success', result, 'The method should return Success for a valid approval process');  
       
        Test.stopTest();
    }
    }   */
   
    @isTest
    static void testHandleApproval() {
        Test.startTest();
 
        // Create payload with invalid work item ID
        List<ApprovalController.payLoadWrapper> payload = new List<ApprovalController.payLoadWrapper>();
        ApprovalController.payLoadWrapper wrapper = new ApprovalController.payLoadWrapper();
        wrapper.workItemIds = 'InvalidId';
        wrapper.comment = 'Test invalid comment';
        payload.add(wrapper);
 
        // Call the method with invalid data
        String result = ApprovalController.handleApproval(payload, 'Approve', 'Common comment');
       
        // Assert the result
        System.assertEquals('error', result, 'The method should return error for invalid work item ID');
       
        Test.stopTest();
    }
   
 
    @isTest
    static void testHandleApprovalWithInvalidData() {
        Test.startTest();
 
        // Create payload with invalid work item ID
        List<ApprovalController.payLoadWrapper> payload = new List<ApprovalController.payLoadWrapper>();
        ApprovalController.payLoadWrapper wrapper = new ApprovalController.payLoadWrapper();
        wrapper.workItemIds = 'InvalidId';
        wrapper.comment = 'Test invalid comment';
        payload.add(wrapper);
 
        // Call the method with invalid data
        String result = ApprovalController.handleApproval(payload, 'Approve', 'Common comment');
       
        // Assert the result
        System.assertEquals('error', result, 'The method should return error for invalid work item ID');
       
        Test.stopTest();
    }
   
   
}