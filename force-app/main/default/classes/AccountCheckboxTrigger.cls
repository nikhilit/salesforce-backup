public class AccountCheckboxTrigger {
    public static void createcontanddesc(List<Account> accList){
        List<Contact> contList = new List<Contact>();
        List<Opportunity> oppList = new List<Opportunity>();
        
        for(Account acc : accList)
        {
            if(acc.Contact__c)
            {
                Contact con = new Contact();
                con.FirstName= acc.Name;
                con.LastName= acc.Name;
                con.AccountId = acc.id;
                contList.add(con);
            }
            
            if(acc.Opportunity__c)
            {
                Opportunity opp = new Opportunity();
                opp.Name = acc.Name;
                opp.StageName = 'Prospecting';
                opp.CloseDate= SYstem.Today();
                opp.AccountID = acc.ID;
                oppList.add(opp);
                
            }
            
        }
        if(!contList.isEmpty())
        {
            insert contList;
        }
        if(!oppList.isEmpty())
        {
            insert oppList;
        }
    }
}