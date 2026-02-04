public class TaskTriggerHandler {
<<<<<<< HEAD
    public static void attachAccount(List<Task> newTasks){
        Set<String> phoneNumbers = new Set<String>();
        Set<String> agentIds = new Set<String>();
        for(Task newTask:newTasks){
            if(newTask.Phone_Number__c!=NULL && newTask.WhatId==NULL){
                phoneNumbers.add(newTask.Phone_Number__c);
            }
            if(newTask.Agent_Id__c!=null){
                agentIds.add(newTask.Agent_Id__c);
            }
        }
        List<Account> customerList = [SELECT Id,Phone,Secondary_Telephone__c FROM Account WHERE Phone IN:phoneNumbers OR Secondary_Telephone__c IN:phoneNumbers];
        List<User> userList = [SELECT Id,Agent_Id__c FROM User WHERE Agent_Id__c IN:agentIds];
        Map<String,Id> CAToAccountMap = new Map<String,Id>();
        Map<string,Id> userToIdMap=new Map<String,Id>();
        for(Account acc:customerList){
            if(CAToAccountMap.get(acc.Phone)==null){
                CAToAccountMap.put(acc.Phone,acc.Id);
            }else if(CAToAccountMap.get(acc.Secondary_Telephone__c)==null){
				CAToAccountMap.put(acc.Secondary_Telephone__c,acc.Id);                
            }
        }
        for(User us:userList){
                userToIdMap.put(us.Agent_Id__c,us.Id);
            }
        for(Task newTask:newTasks){
            if(newTask.Phone_Number__c!=NULL && newTask.WhatId==NULL && CAToAccountMap.get(newTask.Phone_Number__c)!=null){
                	newTask.WhatId=CAToAccountMap.get(newTask.Phone_Number__c);
            }
            if(newTask.Agent_Id__c!=null&&userToIdMap.get(newTask.Agent_Id__c)!=null){
                newTask.OwnerId=userToIdMap.get(newTask.Agent_Id__c);
            }
        }
    }
=======
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
    
>>>>>>> e604021b64f33882bfed07c2bfed265ad53326cf
}