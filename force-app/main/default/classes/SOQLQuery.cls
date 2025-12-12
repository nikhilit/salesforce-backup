public class SOQLQuery {
    public static void querydemo()
    {
        List<Account> acclist= [SELECT id, Name FROM Account WHERE industry='Media'];
        for(Account acc : acclist)
        {
            System.debug(acc);
        }
        
    }
    public static void loopdemo()
    {
        for (Account acc : [SELECT Id, Name FROM Account]) {
            System.debug('Account Name: ' + acc.Name);
        }
    }   
    public static void Contdemo()
    {
        
        List<Contact> contlist= [SELECT Id, Name, Account.Name, Account.Industry FROM Contact];
        for(Contact cont : contlist)
        {
            System.debug(cont);
        }
    }
}