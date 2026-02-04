trigger OpportunityTrigger on Opportunity (before update,before insert, after insert,after update,after delete,after undelete) { 
    set<id> newid= new set<id> ();
    
    if(Trigger.isUpdate){
        if(Trigger.isbefore)
        {
            //OpportunityTriggerHandler.populateClosedReason(Trigger.new,trigger.oldmap);
        }
        else if(Trigger.isAfter)
        {
            //OpportunityTriggerHandler.UpdateOppoAmount(Trigger.new,trigger.oldmap);
        }
    }
    if(Trigger.isInsert){
        if(Trigger.isafter){
            OpportunityTriggerHandler.RollupOnAccountofOppo(Trigger.new);
            
        }
    }
    if(Trigger.isDelete){
        if(Trigger.isafter){
            OpportunityTriggerHandler.RollupOnAccountofOppo(Trigger.old);
            OpportunityTriggerHandler.createTaskWhenOppoisDeleted(Trigger.old);
            
        }
    }
    if(Trigger.isundelete){
        if(Trigger.isafter){
            OpportunityTriggerHandler.RollupOnAccountofOppo(Trigger.new);
        }
    }
    if(Trigger.isupdate){
        if(Trigger.isafter){
            OpportunityTriggerHandler.RollupOnAccountofOppotoupdate(Trigger.new,Trigger.oldmap);
            OpportunityTriggerHandler.RemoveallOppTeamMember(Trigger.new,trigger.oldmap);
            
        }
    }
    if(trigger.isbefore && trigger.isinsert)
    {
        OpportunityTriggerHandler.preventMultipleOpportunities(Trigger.new);
        OpportunityTriggerHandler.addErrorOnEmail(Trigger.new);
        
    }
}


//yash method        
/*if(trigger.isafter &&(trigger.isinsert || trigger.isundelete)){
for(opportunity op : trigger.new){
newid.add(op.accountid); 
}
}
if(trigger.isafter && trigger.isupdate ){
for(opportunity op : trigger.new){
if(op.accountid != null && op.accountid != trigger.oldmap.get(op.id).accountid){
newid.add(op.accountid);
newid.add(trigger.oldmap.get(op.id).accountid);
}
else {
newid.add(op.accountid); 
}
}
}
if(trigger.isafter && trigger.isdelete ){
for(opportunity op : trigger.old){
newid.add(op.accountid); 
}
}

OpportunityTriggerHandler.RollupOnAccountofOppoTest(newid);*/