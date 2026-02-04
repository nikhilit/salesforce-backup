public class OpportunityAmountHandler {
    public static void populateAmount(List<Opportunity> oppoList)
    {
        list<Account> accList= new list<Account>();
        for(Opportunity opp : oppoList)
        {
            if(opp.Amount!=null && opp.Accountid!=null)
            {
                Account acc = new Account();
                acc.id= opp.AccountId;
                acc.Recent_Opportunity_Amount__c= opp.Amount;
                accList.add(acc);
                
            }
        }
        if(!acclist.isempty())
        {
            update acclist;
        }
    }

}