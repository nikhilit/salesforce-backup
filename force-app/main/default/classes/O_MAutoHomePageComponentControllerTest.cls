@isTest
public class O_MAutoHomePageComponentControllerTest {
    
    @isTest
    static void testGetUserName() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            Alias = 'tuser',
            Email = 'testuser' + DateTime.now().getTime() + '@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser293402948@example.com'
            );
        insert u;
        Test.startTest();
        system.runAs(u){
        O_MAutoHomePageComponentController.UserWrapper result = 
            O_MAutoHomePageComponentController.getUserName();
        }
        Test.stopTest();
    }
    
    @isTest
    static void getTBTWorkOrderTest(){
        
                Id tbtRecordTypeId = Schema.getGlobalDescribe()
            .get('WorkOrder')
            .getDescribe()
            .getRecordTypeInfosByDeveloperName()
            .get('TBT')
            .getRecordTypeId();

      

        WorkOrder wo = new WorkOrder(
            Subject = 'Test TBT WorkOrder',
            Status = 'New',
           // AccountId = acc.Id,
            RecordTypeId = tbtRecordTypeId,
            OwnerId = UserInfo.getUserId(),
            Approval_Status__c = 'Pending'
        );
        insert wo;

        Test.startTest();
        WorkOrder result = O_MAutoHomePageComponentController.getTBTWorkOrder();
        Test.stopTest();

        
       
    }
    
}