public class SetDemo {
    
    
    public static void DemoCustomObjectWithSet(){
        Set<Id> posIds = new Set<Id>();
        List<Position__c> posList = new List<Position__c>();
        
        posList= [SELECT Id, Name from Position__c LIMIT 5];
        
        For(Position__c  pos : posList)
        {
            posIds.add(pos.id);
        }
        
        System.debug('Set Contains=' + posIds);
    }
    
    public static void DemoSObjectWithSet(){
        Set<Id> accIds = new Set<Id>();
        List<Account> accList = new List<Account>();
        
        accList= [SELECT Id, Name from Account LIMIT 5];
        
        For(Account  acc : accList)
        {
            accIds.add(acc.id);
        }
            
        System.debug('Set Contains=' + accIds);
    }
    
    
    
    
    
    public static void Demo(){
        Set <Integer> intset = new Set<Integer>();
        
        intset.add(10);
        intset.add(30);
        intset.add(30);
        intset.add(40);
        intset.add(50);
        
        System.debug('Set Contain:' + intset);
        
        
    }
}