//23.When an opportunity is updated to Closed Lost and Closed Lost Reason
//(field) is not populated then throw validation error that ‘Please populate
//Closed Lost Reason’ on opportunity. [before update]
/*public static void populateClosedReason(List<Opportunity> oppList, Map<id,Opportunity> oldmap)
{
for(Opportunity opp: oppList)
{
if(opp.StageName== 'Closed Lost' && opp.Closed_Lost_Reason__c== null &&
opp.StageName != oldmap.get(opp.id).StageName)
{
opp.addError('Please populate Closed Lost reason');
}

}
}*/

//IMPORTANT 
//25. If an opportunity is closed then, no one should be able to delete it except
//the user having a System Administrator profile.
public class OpportunityTriggerHandler {    
    public static void checkprofilefordeletion(List <opportunity> oppList)
    {
        Profile p =[SELECT id FROM Profile WHERE Name = 'System Administrator'];
        
        for(Opportunity opp : oppList)
        {
            if(opp.StageName=='Closed Lost' || opp.StageName=='Closed Won')
            {
                if(Userinfo.getProfileid()!=p.Id)
                {
                    opp.adderror('only system adminsitrator can delete opportunity');
                }
            }
        }
    }
    
    //for insert update delete
    Public static void RollupOnAccountofOppo(List<Opportunity> oppList)
    {
        Set<Id> accountids = new Set<id>();
        
        for(Opportunity opp : oppList)
        {
            if(opp.Accountid!=null) // Check if the Opportunity is linked to an Account (AccountId is not null)
            {
                accountids.add(opp.Accountid);  // Add the AccountId to the set (to ensure uniqueness)
            }
        }
        List<Account> Accounttoupdate = new List<Account>();
        for(Account acc : [Select id,(Select id from opportunities) from Account where id in: accountids])
        {  
            integer noOfopportunities = acc.opportunities.size();
            acc.Total_Opportunity__c = noOfopportunities;
            Accounttoupdate.add(acc);
        }
        
        
        if(!Accounttoupdate.isEmpty())
        {
            update Accounttoupdate;
        }
    }
    
    //for update        
    Public static void RollupOnAccountofOppotoupdate(List<Opportunity> oppList, Map<id,Opportunity> oldmap)
    {
        Set<Id> accountids = new Set<id>();
        
        for(Opportunity opp : oppList)
        {
            if(opp.Accountid!=null && opp.Accountid!=oldmap.get(opp.id).Accountid) // Check if the Opportunity is linked to an Account (AccountId is not null)
            {
                accountids.add(opp.Accountid);  // Add the AccountId to the set (to ensure uniqueness)
            }
        }
        List<Account> Accounttoupdate = new List<Account>();
        for(Account acc : [Select id,(Select id from opportunities) from Account where id in: accountids])
        {  
            integer noOfopportunities = acc.opportunities.size();
            acc.Total_Opportunity__c = noOfopportunities;
            Accounttoupdate.add(acc);
        }
        
        
        if(!Accounttoupdate.isEmpty())
        {
            update Accounttoupdate;
        }
    }
    //yash method       
    /*Public static void RollupOnAccountofOppoTest(set<id> newid){
list<aggregateresult> agglist = [select count(id) countofid,accountid from opportunity where accountid in : newid group by accountid ];

map<id,account> upadtedlist = new map<id,account>();

for(aggregateresult ag : agglist){
account ac = new account ();
ac.id=(id)ag.get('accountid');
ac.Total_Opportunity__c=(decimal)ag.get('countofid');
upadtedlist.put(ac.id,ac);
}
update upadtedlist.values();
}*/
    //use case 7 If opportunity stage is modified, update opportunity aount based on probalality * expected revenue;    
    /*public static void UpdateOppoAmount(List<Opportunity> newRecords,Map<id,Opportunity> oldmap)
{
for(Opportunity newopp : newRecords)
{
if(oldmap.get(newopp.id).stageName != newopp.StageName)
{
newopp.Amount = newopp.Probability *10;
}
}
}*/
    //USE CASE #13 As soon as an opportunity is deleted, create a task for the opportunity account owener to investigate 
    //why the record was deleted and submit the information
    
    public static void createTaskWhenOppoisDeleted(List<Opportunity> oldRecords){
        
        set<id> accountids = new set<id>();
        Map<id,id> oppvsAccoutmap = new map<id,id>();
        map<id,id> accidvsOwneridMap = new Map<id,id>();
        
        for(Opportunity opp: oldRecords)
        {
            accountids.add(opp.AccountId);
            oppvsAccoutmap.put(opp.Id,opp.AccountId);
        }
        
        List<Account> accountRecords = [select id , ownerid from account where id in: accountids];
        
        for(Account acc: accountRecords){
            accidvsOwneridMap.put(acc.id,acc.OwnerId);
        }
        
        list<Task> taskRecordList = new List<Task>();
        
        for(opportunity opp : oldRecords){
            task taskrecord = new task();
            taskrecord.Description='Please investigate why the opportunity was deleted';
            taskrecord.Priority='High';
            taskrecord.OwnerId= accidvsOwneridMap.get(oppvsAccoutmap.get(opp.id));
            taskrecord.status ='Not started';
            taskrecord.Subject = 'Follow Up';
            taskRecordList.add(taskrecord);
            
        }
        if(!taskRecordList.isEmpty())
        {
            insert taskRecordList;
        }
    }
    
    //same solution using SOQL
    
    /*public static void createTaskWhenOppoisDeleted(List<Opportunity> oldRecords) {
// List to store Task records to be inserted
List<Task> taskRecordList = new List<Task>();

// Query Opportunities with their related Account OwnerId directly
List<Opportunity> oppWithAccountOwners = [
SELECT Id, Account.OwnerId 
FROM Opportunity 
WHERE Id IN :oldRecords
];

// Loop through opportunities to create tasks
for (Opportunity opp : oppWithAccountOwners) {
if (opp.Account.OwnerId != null) {
Task taskRecord = new Task();
taskRecord.Description = 'Please investigate why the opportunity was deleted';
taskRecord.Priority = 'High';
taskRecord.OwnerId = opp.Account.OwnerId; // Directly using OwnerId from Account
taskRecord.Status = 'Not started';
taskRecord.Subject = 'Follow Up';
taskRecordList.add(taskRecord);
}
}

// Insert tasks if the list is not empty
if (!taskRecordList.isEmpty()) 
insert taskRecordList;
}*/
    
    
    //Use 15- As soon as Opportunity is close dLost, remove all the oportunity team member from the opportunity:
    
    public static void RemoveallOppTeamMember(List<Opportunity> newRecord, Map<Id, Opportunity> oldRecordMap) {
        
        Set<Id> closedLostOppIds = new Set<Id>();
        
        
        for (Opportunity opp : newRecord) {
            if (opp.StageName == 'Closed Lost') {
                closedLostOppIds.add(opp.Id);
            } 
        }
        
        List<OpportunityTeamMember> teamMembers = [SELECT Id, OpportunityId FROM OpportunityTeamMember WHERE OpportunityId IN :closedLostOppIds];
        
        if (!teamMembers.isEmpty()) {
            delete teamMembers;
            system.debug('delete');
        }
    }
    
    public static void preventMultipleOpportunities(List<Opportunity> newOpportunities) {
        // Step 1: Collect Account IDs from new Opportunities
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : newOpportunities) {
            if (opp.AccountId != null) {
                accountIds.add(opp.AccountId);
            }
        }
        
        // Step 2: Query existing Opportunities created today for these Account IDs
        Map<Id, Date> accountToOpportunityDate = new Map<Id, Date>();
        if (!accountIds.isEmpty()) {
            for (Opportunity existingOpp : [
                SELECT AccountId, CreatedDate 
                FROM Opportunity 
                WHERE AccountId IN :accountIds 
                AND DAY_ONLY(CreatedDate) = :Date.today()
            ]) {
                accountToOpportunityDate.put(existingOpp.AccountId, (Date)existingOpp.CreatedDate);
            }
        }
        
        // Step 3: Check and add an error for duplicate Opportunities
        for (Opportunity opp : newOpportunities) {
            if (opp.AccountId != null && accountToOpportunityDate.containsKey(opp.AccountId)) {
                opp.addError('An Opportunity for this Account has already been created today.');
            }
        }
    }
    
    
    
    
    public static void addErrorOnEmail(List<Opportunity> oppList)
    {
        set<String> newEmail = new set<String>(); // to store the email of the new opportunity:
        for(Opportunity opp: oppList) // new opportunity and add their emails to the set:
        {
            if(opp.email__c!= null)
            {
                newEmail.add(opp.Email__c.toLowerCase());
            }
        }
        //Querying the existing opportunity with same email
        List<Opportunity> existingoppList =[Select id, email__c from Opportunity where email__c in : newEmail];
        
        set<String> existingOppEmail = new set<String>();
        
        for(Opportunity op : existingoppList)
        {
            if(op.email__c!= null)
            {
                existingOppEmail.add(op.email__c.toLowerCase());
            }
        }
        
        for(Opportunity opp: oppList)
        {
            if(opp.email__c!=null  &&  existingOppEmail.contains(opp.email__c.toLowerCase()))
            {
                opp.addError('A opportunity with this email already exist');
            }
        }
    }
}