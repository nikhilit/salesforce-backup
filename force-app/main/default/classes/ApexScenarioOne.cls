public class ApexScenarioOne {
    public static void Apexsc1()
    {
        LIST<Account> acc =new LIST<Account>();
        acc = [SELECT id, Name,(SELECT id FROM Contacts) FROM Account WHERE phone != Null ];
        
        if(!acc.isEmpty())
        {
            for(Account a : acc)
            {
                
                System.debug(a.Name + ' has ' + a.Contacts.size() + ' contacts.');
                
            }
        }
    }
    public static void Apexsc2()
    {
        LIST<Account> acc =new LIST<Account>();
        acc = [SELECT id, Name, (SELECT id, Amount FROM Opportunities) FROM Account WHERE phone != Null ];
        
        if(!acc.isEmpty())
        {
            for(Account a : acc)
            {
                Decimal total =0;
                for(Opportunity opp : a.Opportunities)
                {
                    if(opp.Amount!=null){
                        total = total + opp.Amount;
                    }
                }
                System.debug(a.Name + ' has ' + total + ' opportunites');
            }
        }   
    }
    public static void ApexSc3()
    {
        LIST<Opportunity> oppList =new LIST<Opportunity>();
        oppList = [SELECT id, StageName FROM Opportunity WHERE CreatedDate = This_Year ];
        
        if(!oppList.isEmpty())
        {
            for(Opportunity opp : opplist)
            {
                if(opp.StageName=='Closed Won')
                {
                    opp.Description = 'Opportunity is Closed Won';
                }
                else if(opp.StageName=='Closed Lost')
                {
                    opp.Description = 'Opportunity is Closed Lost';
                }
                else
                {
                    opp.Description = 'Opportunity is Open';
                }
            }
            update opplist;
        }
    }
    public static void Apexsc4()
    {
        LIST<Account> acc =new LIST<Account>();
        acc = [SELECT id, Total_Contact_Count__c,Active__c,(SELECT id FROM Contacts) FROM Account WHERE phone != Null ];
        
        if(!acc.isEmpty())
        {
            for(Account a : acc)
            {
                a.Total_contact_count__c = a.Contacts.size();
                if(a.Active__c== null)
                {
                    a.active__c='Yes';
                }
                
            }
            Update acc;
        }
    }
    public static void Apexsc5()
    {
        LIST<Contact> conList =new LIST<Contact>();
        conList = [SELECT id, MobilePhone, Account.Phone FROM Contact WHERE CreatedDate = THIS_YEAR ];
        
        if(!conList.isEmpty())
        {
            for(Contact con : conList)
            {
                
                if(con.MobilePhone == null && con.Account.Phone != Null)
                {
                    con.MobilePhone=con.Account.Phone;
                }
                
            }
            Update conList;
        }
    }
}