public class TaskTriggerHandler {
    public static void populatepriorityhigh(List<Task> tList)
    {
        for(Task taskRecord : tlist)
        {
            taskRecord.priority='High';
        }
    }
    
    //use case #22- allow updating the task records 
    //only if the parents contacts account record has the modify task permission checked    
    
    public static void PermissionCheck(List<Task> tlist)
    {
        set<id> contactids = new set<id>();
        for(task t : tlist){
            if(t.whoid != null)
            {
                contactids.add(t.whoid);
            }
        }
        
        List<Account> accList = [SELECT Id, Name, Permission_check__c, 
                             (SELECT Id, Name FROM Contacts WHERE Id IN :contactIds) 
                             FROM Account 
                             WHERE Permission_check__c = false];
        
        set<id> conids = new set<id>();
        for(Account acc : accList)
        {
            for(Contact con : acc.contacts)
                conids.add(con.id);
        }
        for(task t : tlist)
        {
            if(t.whoid != null && conids.contains(t.WhoId))
            {
                t.adderror('bhai checkbox on karke aa');
            }
        }
    }
    
}