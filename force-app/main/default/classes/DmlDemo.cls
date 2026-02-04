public class DmlDemo {
    public static void insertDemo() {
        List<Account> acclist = new List<Account>();
        List<Contact> contlist = new List<Contact>();
        
        // Create and add first Account
        Account acc = new Account();
        acc.Name = 'Test DML 101';
        acc.Active__c = 'yes';
        acclist.add(acc);
        
        // Create and add second Account
        Account acc1 = new Account();
        acc1.Name = 'Test DML 102';
        acc1.Active__c = 'yes';
        acclist.add(acc1);
        
        // Insert Accounts
        insert acclist;
        
        // Create and add first Contact
        Contact con = new Contact();
        con.FirstName = acc.Name;
        con.LastName = acc.Name;
        con.AccountId = acclist[0].Id;
        contlist.add(con);
        
        // Create and add second Contact
        Contact con1 = new Contact();
        con1.FirstName = acc1.Name;
        con1.LastName = acc1.Name;
        con1.AccountId = acclist[1].Id;
        contlist.add(con1);
        
        // Insert Contacts
        insert contlist;
    }
    
    public static void insertAccount()
    {
        List<Account> acclist = new list<Account>();
        for (integer i=1;i<=5;i++)
        {
            Account acc = new Account();
            acc.Name='test'+ i;
            acc.phone='12345';
            acclist.add(acc);
        }
        insert acclist;
    }
    public static void insertOpportunity()
    {
        List<Opportunity> opplist = new list<Opportunity>();
        Account acc = [SELECT Id FROM Account LIMIT 1];
        for (integer i=1;i<=5;i++)
        {
            Opportunity s = new Opportunity();
            s.Name= 'test'+ i;
            s.CloseDate= System.today();
            s.StageName = 'Prospecting';
            s.AccountId = acc.id;
            opplist.add(s);
            
        }
        insert opplist;
    }
}