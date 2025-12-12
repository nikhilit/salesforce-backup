trigger ContactTrigger on Contact (before insert, before update, after insert, after delete, after undelete) {
    if(Trigger.isInsert){
        if(Trigger.isafter){
            ContactTriggerHandler.TotalContactCount(Trigger.new);
            
            
        }
        
    }
    if(Trigger.isDelete){
        if(Trigger.isafter){
            ContactTriggerHandler.TotalContactCount(Trigger.old);
            ContactTriggerHandler.AfterUndeletePopulateSatatusAsActive(Trigger.new);
        }
    }
    
    if(Trigger.isinsert){
        if(Trigger.isbefore){
            ContactTriggerHandler.populatechekbox(Trigger.new);
            ContactTriggerHandler.Contactcreatedwithourparentrecord(trigger.new);
            ContactTriggerHandler.DoNotLetThemCreateContactCreation(trigger.new);
        }
        
    }
    if(Trigger.isupdate){
        if(Trigger.isbefore){
            ContactTriggerHandler.populatechekbox(Trigger.new);
            
        }
        
    }
    
    
}