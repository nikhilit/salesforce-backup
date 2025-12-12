public class LeadTriggerHandler {
    Public static void leadDeletionError(List<Lead> leadList)
    {
        for(Lead lead : leadList)
        {
            if(lead.status=='working Contacted')
            {
                lead.adderror('You cannot a delete a lead in porgress');
            }
        }
    }
    
    
    public static void populatetheDescription(List<Lead> newLeadList, Map<Id,Lead> oldLeadMap)
    {
        List<Lead> convertedLeads = new List<Lead>();
        set<Id> convertedAccIds = new set<Id>();
        set<Id> convertedConIds = new set<Id>();
        set<Id> convertedOppIds = new set<Id>();
        
        Map<ID,Account> accMap = new Map<ID,Account>();
        Map<ID,Contact> conMap = new Map<ID,Contact>();
        Map<ID,Opportunity> oppMap = new Map<ID,Opportunity>();
        List<Task> tasksToUpdate = new List<Task>();
        
        
        if(!newLeadList.isEmpty())
        {
            for(Lead newLead : newLeadList)
            {
                if(!oldLeadMap.isempty())
                {
                    lead oldLead = oldLeadMap.get(newlead.Id);
                    
                    if(newLead.isConverted && !oldLead.isConverted)
                    {
                        convertedLeads.add(newLead);
                        
                        
                        if(newLead.ConvertedAccountId!= null)
                        {
                           convertedAccIds.add(newLead.ConvertedAccountId); 
                        }
                        
                        if(newLead.ConvertedContactId!= null)
                        {
                           convertedConIds.add(newLead.ConvertedContactId); 
                        }
                        
                        if(newLead.ConvertedOpportunityId!= null)
                        {
                           convertedOppIds.add(newLead.ConvertedOpportunityId); 
                        }
                    }
                }
            }
        }
        
        if(!convertedLeads.isempty())
        {
            if(!convertedAccIds.isempty())
            {
                accMap= new Map<Id,Account>([Select id, name from Account where Id in: convertedAccIds]);
            }
            
            if(!convertedConIds.isempty())
            {
                conMap= new Map<Id,Contact>([Select id, name, email from Contact where Id in: convertedConIds]);
            }
            
            if(!convertedOppIds.isempty())
            {
                oppMap= new Map<Id,Opportunity>([Select id, name, CloseDate from Opportunity where Id in: convertedOppIds]);
            }
            
            for(Lead leadObj : convertedLeads)
            {
                Task newtask = new Task();
                newtask.Subject='Follow-up with converted leads';
                newtask.Priority='Normal';
                newtask.Status='Not Started';
                newtask.ActivityDate= Date.today()+7;
                newtask.WhoId=leadObj.ConvertedContactId;
                newtask.WhatId=leadObj.ConvertedOpportunityId;
                
                
                string taskdescription = 'Lead Name: '+ leadObj.FirstName+'\n';
                taskdescription+='Lead Email:' + leadObj.Email+'\n';
                taskdescription+='Lead Phone:' + leadObj.Email+'\n';
                
                if(accMap.containsKey(leadObj.ConvertedAccountId))
                {
                    Account acc = accMap.get(leadObj.ConvertedAccountId);
                    TaskDescription+='Account Name:' +acc.Name+'\n';
                }
                
                if(conMap.containsKey(leadObj.ConvertedContactId))
                {
                    Contact con = conMap.get(leadObj.ConvertedContactId);
                    TaskDescription+='Contact Name:' +con.Name+'\n';
                    TaskDescription+='Contact Email:' +con.Email+'\n';
                }
                
                if(oppMap.containsKey(leadObj.ConvertedOpportunityId))
                {
                    Opportunity opp = oppMap.get(leadObj.ConvertedOpportunityId);
                    TaskDescription+='Opportunity Name:' +opp.Name+'\n';
                    TaskDescription+='Opportunity Close Date:' +opp.CloseDate+'\n';
                }
                
                newTask.Description = taskDescription;
                tasksToUpdate.add(newTask);
            }
        }
        if(!tasksToUpdate.isEmpty())
        {
            insert tasksToUpdate;
        }
    }
}