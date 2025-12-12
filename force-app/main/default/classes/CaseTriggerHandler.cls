public class CaseTriggerHandler {
    public static void populateCaseNumber(List<Case> caseList)
    {
        List<Account> accList= new  List<Account>();
        for(Case cs : caseList)
        {
            if(cs.AccountId!=null)
            {
                Account acc = new Account();
                acc.id=cs.AccountId;
                acc.Latest_Case_Number__c=cs.CaseNumber;
                accList.add(acc);
            }
        }
        if(!accList.isEmpty())
        {
            update accList;
        }
    }
    
    public static void CaseDeletionByAdmin(List<Case> caseList)
    {
        Profile p=[select id from profile WHERE Name = 'System Administrator'];
        
        for(case c : caseList)
        {
            if(Userinfo.getprofileid() != p.Id)
            {
                c.adderror('only system adminsitrator can delete case');
            }
        }
    }

}