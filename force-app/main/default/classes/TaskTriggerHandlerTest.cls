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
        
    }
}