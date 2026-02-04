public class MyFirstClass {
    public static ID insertAccount(String name, String rating, string active)
    {
        Account acc = new Account();
        acc.Name = name;
        acc.Rating = rating;
        acc.Active__c = active;
        
        insert acc;
        
        return acc.Id;
        
    }
    public static void insertContact()
    {
        Id accId;
        accId = insertAccount('binod1', 'Hot','Yes');
        Contact con = new Contact(FirstName='Contact102', LastName='con201');
        con.accountId=accId;
        insert con;
    }
    
    public static void inserttechnicalpos(String name)
    {
        Position__c pos=new Position__c();
        pos.Name = name;
        pos.RecordTypeId = '012dL000001fxy6QAA';
        insert pos;
    }

}