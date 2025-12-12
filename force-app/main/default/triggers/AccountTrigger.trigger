trigger AccountTrigger on Account (before insert, After insert,before update,AFter update, Before delete) {
    
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)){
        FullNameTriggerHandler.populateFullName(Trigger.New);
        
    }
    
    
    
    if(Trigger.isInsert){
        if(Trigger.isBefore){
            AccountTriggerHandler.UpdateDesc(Trigger.New);
        }
        else if(Trigger.isAfter){
            AccountTriggerHandler.CreateOpp(Trigger.New);
            AccountTriggerHandler.populateNcontact(Trigger.New);
        }
    }
    
    if(Trigger.isUpdate){
        if(Trigger.isbefore){
            AccountTriggerHandler.updatePhone(Trigger.new,Trigger.OldMap);
            //AccountTriggerHandler.prevnetAccEdit(Trigger.new);
            AccountTriggerHandler.populatError(Trigger.new, trigger.oldmap);
        }
        else if(Trigger.isAfter)
        {
            AccountTriggerHandler.UpdateRelatedContact(Trigger.new, trigger.oldmap);
            AccountTriggerHandler.populateRelatedNumber(Trigger.new, trigger.oldmap);
            AccountTriggerHandler.populateBilingAddress(Trigger.new, trigger.OldMap);
            AccountTriggerHandler.pupulatewebsiteofcontact(Trigger.new, trigger.OldMap);
            
        }
    } 
    
    if(Trigger.isDelete){
        if(Trigger.isBefore){
            AccountTriggerHandler.preventDeletion(Trigger.old);
            AccountTriggerHandler.PreventdeleteifhasrelatedCase(Trigger.old);
            AccountTriggerHandler.Preventdeleteifhasrelatedoppo(Trigger.old);
        }
        else if(Trigger.isAfter){
            
        }
    }
}