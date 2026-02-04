@isTest
public class COExecutionDetailsRiserContrTest {
    
    
     @TestSetup
    static void setupTestData() {

    
      Profile fieldAgentRiserProfile = [SELECT Id FROM Profile WHERE Name = 'Field Agent Riser' LIMIT 1];
       Profile fieldAgentOMProfile = [SELECT Id FROM Profile WHERE Name = 'Field Agent(O&M)- IPD' LIMIT 1];
        
        
        User riserUser = new User(
            FirstName = 'Riser',
            LastName = 'Test',
            Email = 'riser.test@test.com',
            Username = 'riser.test@test.com',
            Alias = 'rtest',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = fieldAgentRiserProfile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert riserUser;
        
         User omUser = new User(
            FirstName = 'OM',
            LastName = 'Test',
            Email = 'om.test@test.com',
            Username = 'om.test@test.com',
            Alias = 'otest',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = fieldAgentOMProfile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert omUser;
        
         // Create WorkType
        WorkType wt = new WorkType(Name='Riser Painting', EstimatedDuration=60);
        insert wt;

        // Create RecordType for WorkOrder
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType='WorkOrder' LIMIT 1];

        // Create WorkOrder
        WorkOrder wo = new WorkOrder(
            Subject='Test WorkOrder',
            Status='New',
            WorkTypeId = wt.Id,
            RecordTypeId = rt.Id
        );
        insert wo;

        // Create WorkPlan linked to WorkOrder
        WorkPlan wp = new WorkPlan(Name='Test Plan', WorkOrderId=wo.Id);
        insert wp;

        // Create WorkStep
        WorkStep ws = new WorkStep(
            Name='CO Execution Detail',
            WorkPlanId=wp.Id,
            Status='Pending'
        );
        insert ws;
        
    }
    
    


     @IsTest
    static void testGetWOrderWType() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        Test.startTest();
        String workTypeName = COExecutionDetailsRiserContr.getWOrderWType(wo.Id);
        Test.stopTest();

        System.assertEquals('Riser Painting', workTypeName);
    }
    
     @IsTest
    static void testGetApprovalStatusWithoutDocument() {
        User testUser = [SELECT Id, Username FROM User WHERE Username = 'riser.test@test.com'];
        
        System.runAs(testUser) {
            Test.startTest();
            WorkOrder result = COExecutionDetailsRiserContr.getApprovalStatus();
            Test.stopTest();
            
           // System.assertNotEquals(null, result, 'Should return empty document object');
        }
    }
    
     @IsTest
    static void testGetApprovalStatusWithDocument() {
        User testUser = [SELECT Id, Username FROM User WHERE Username = 'riser.test@test.com'];
        
        System.runAs(testUser) {
            // Create test document
           /* Document__c testDoc = new Document__c(
                Submitted_Agent_Name__c = testUser.Username,
                Approval_Status_O_M__c = 'Pending'
            );
            insert testDoc; */
            
            Test.startTest();
            WorkOrder result = COExecutionDetailsRiserContr.getApprovalStatus();
            Test.stopTest();
            
           
        }
    } 
    
     @isTest
    static void testCheckWorkStep() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        Test.startTest();
        String status = COExecutionDetailsRiserContr.checkWorkStep(wo.Id);
        Test.stopTest();

        
    }
    
   
    
    
  
}