trigger deleteassociate on Candidate__c (before delete) {
    set<id> newid = new set<id>();
    for(Candidate__c c : trigger.old){
        newid.add(c.id);
    }
    list<Job_Application__c> jlist = [SELECT Id, Candidate__c FROM Job_Application__c where Candidate__c in :newid ];
    
    delete jlist;

}