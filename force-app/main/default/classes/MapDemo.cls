public class MapDemo {
    public static void SobjectDemowithoutloop()
    {
        List<Account> accList = new List<Account>();
        accList = [SELECT Name FROM Account LIMIT 5];
        
        Map<Id, Account> accMap = new Map<Id, Account>(acclist);
        
        System.debug('Map contains:' + accMap);
        System.debug('Map Key :' + accMap.keySet());
        System.debug('Map values:'+ accMap.values());
        
        
    }
    
    public static void SobjectDemoWithLoop()
    {
        List<Account> accList = new List<Account>();
        accList = [SELECT Name FROM Account LIMIT 5];
        
        Map<Id, Account> accMap = new Map<Id, Account>(acclist);
        
        for(Account acc: accList)
        {
            accMap.put(acc.id,acc);
        }
        
        System.debug('Map contains:' + accMap);
        System.debug('Map Key :' + accMap.keySet());
        System.debug('Map values:'+ accMap.values());
        
        
    }
    
}