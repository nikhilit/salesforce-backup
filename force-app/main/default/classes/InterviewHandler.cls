public class InterviewHandler {
    
    public static void updateAccount(List<Contact> conList)
    {
        set<Id>  accSet = new set<Id>();
        
        For(Contact con: conList )
        {
            if(con.Accountid!=null)
            {
                accSet.add(con.AccountId);
            }
        }
        
        List<Account> accList= [Select id, 	Total_contact_count__c, (Select id from Contacts) from Account
                               where id in : accSet];
        
        List<Account> updateAccount = new List<Account>();
         For(Account acc : accList)
         {
             acc.Total_contact_count__c = acc.contacts.size();
         }
        
        if(!updateAccount.isempty())
        {
            update updateAccount;
        }
        
    }

}