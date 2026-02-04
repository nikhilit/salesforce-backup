//After Delete 
//when a contact record is deletd then update 'Total cntact count ' fileds on related account.
//public class ContactTriggerHandler
//After undelete
// when a contact record is undeleted then update 'Total contact count' field on related account.
// OR  ROll up summary on account

public class ContactTriggerHandler {
    public static void TotalContactCount(List<Contact> conList)
    {
        List<Account> acclist = new List<Account>();
        set<id> accids = new  set<id>();
        
        for(Contact con : conList)
        {
            if(con.Accountid!=null)
            {
                accids.add(con.AccountId);
            }
        }
        for (Account acc : [select id, (select id from Contacts)From account where id in:accids])
        {
            Integer noofcontact = acc.contacts.size();
            acc.Total_Contacts__c=Decimal.valueof(noOfContact);
            accList.add(acc);
        }
        if(!accList.isEmpty())
        {
            update accList;
        }
    }
    
    
    Public static void AfterUndeletePopulateSatatusAsActive(List<Contact> ContList)
    {
        List<Contact> contactToUpdate = new  List<Contact>();
        for(Contact con: contList)
        {
            con.Status__c='Active';
            contactToUpdate.add(con);
        }
        if(!contactToUpdate.isempty())
            update contactToUpdate;
    }
    public static void populatechekbox(List<Contact> newcontactList)
    {
        set<id> accids = new set<id>();
        
        for(Contact con : newcontactList)
        {
            if(con.AccountId!= null && con.Primary_Contact__c)
                accids.add(con.AccountId);
        }
        List<Contact> updatecon = new List<Contact>();
        
        List<Account> accList=[select id, (Select id, primary_contact__c from Contacts where primary_contact__c= True )from Account where id in :accids];
        
        for(Account acc : accList)
        {
            for(Contact con : acc.Contacts)
            {
                con.Primary_Contact__c= false;
                updatecon.add(con);
                
            }
        }
        
        if(!updatecon.isempty())
        {
            update updatecon;
        }
    }
    //CASE 8 -if a contact is created without a parent account do not allow user to create the contact record    
    Public static void Contactcreatedwithourparentrecord(List <Contact> conList)
    {
        for(Contact con : conList)
        {
            if(con.AccountId==null){
                con.adderror('you cannot create contact wothout account');
            }
        }
    }
    //case 14 - Check is a contact exists with teh same last name, email & phone .
    //if so, do not let new contact creation:
    
    Public static void DoNotLetThemCreateContactCreation(List<Contact> newRecords)
    {
        List<Contact> existingrecord = [Select id, lastname, phone, email from contact Limit 10000];
        
        for(Contact  con: newRecords)
        {
            for(Contact  existingcon: existingrecord)
                if(con.lastname == existingcon.lastname && con.email == existingcon.email
                   && con.Phone == existingcon.phone)
            {
                con.adderror('Duplicate found');
            }
        }
    }
    

}