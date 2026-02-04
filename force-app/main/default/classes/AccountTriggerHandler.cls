<<<<<<< HEAD
/**
 * @description       :
 * @author            : Kartik Patkar Appstrail
 * @group             :
 * @last modified on  : 06-11-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   23-05-2025   Kartik Patkar, Appstrail   Initial Version
 **/
public class AccountTriggerHandler {    
    public static void fillName(List<Account> newList, Map<Id, Account> oldMap) {
        String gsRecordTypeID = Schema.getGlobalDescribe()
            .get('Account').getDescribe()
            .getRecordTypeInfosByDeveloperName()
            .get('Agency_Account').getRecordTypeId();

        String bsRecordTypeID = Schema.getGlobalDescribe()
            .get('Account').getDescribe()
            .getRecordTypeInfosByDeveloperName()
            .get('Business_Account').getRecordTypeId();

        for (Account acc : newList) {
            Boolean isNew = (oldMap == null || !oldMap.containsKey(acc.Id));
            Boolean drsChanged = false;
            Boolean connectionChanged = false;
            Boolean nameFieldsChanged = false;

            if(acc.Category__c=='CNG/LNG' || acc.Category__c=='MRS'){
                continue;
            }

            if (!isNew) {
                Account oldAcc = oldMap.get(acc.Id);

                // Compare DRS and Connection fields
                drsChanged = acc.DRS__c != oldAcc.DRS__c;
                connectionChanged = acc.Connection__c != oldAcc.Connection__c;

                // Compare name-building fields
                nameFieldsChanged = acc.Full_Name__c != oldAcc.Full_Name__c
                    || acc.BP_Number__c != oldAcc.BP_Number__c
                    || acc.FirstName__c != oldAcc.FirstName__c
                    || acc.Middle_Name__c != oldAcc.Middle_Name__c
                    || acc.LastName__c != oldAcc.LastName__c;
            }

            // Mark for processing if new OR drs/connection changed OR any of them is null
            if (isNew || drsChanged || connectionChanged 
                || acc.DRS__c == null || acc.Connection__c == null) {
                acc.To_be_processed__c = true;
            }

            // Rebuild name if new OR relevant name fields changed
            if (isNew || nameFieldsChanged) {
                String namePart = '';

                if (acc.Full_Name__c != null) {
                    namePart += acc.Full_Name__c;
                } else {
                    // Build name from FirstName__c, Middle_Name__c, and LastName__c
                    if (acc.FirstName__c != null) {
                        namePart += acc.FirstName__c;
                    }
                    
                    if (acc.Middle_Name__c != null) {
                        if (!namePart.equals('')) {
                            namePart += ' ';
                        }
                        namePart += acc.Middle_Name__c;
                    }
                    
                    if (acc.LastName__c != null) {
                        if (!namePart.equals('')) {
                            namePart += ' ';
                        }
                        namePart += acc.LastName__c;
                    }
                }
                
                if (acc.BP_Number__c != null) {
                    if (!namePart.equals('')) {
                        namePart += ' - ';
                    }
                    namePart += acc.BP_Number__c;
                }

                if (!namePart.equals('')) {
                    if (acc.RecordTypeId != gsRecordTypeID) {
                        if (acc.RecordTypeId == bsRecordTypeID) {
                            acc.Name = namePart;
                        } else {
                            if (namePart.length() > 80) {
                                acc.LastName = namePart.substring(0, 79);
                            } else {
                                acc.LastName = namePart;
                            }
                        }
                    } 
                }
            }
        }
    }
    public static void handleInsert(List<Account> newAccounts) {
        List<Account_Dispensor__c> dispensersToCreate = new List<Account_Dispensor__c>();

        for (Account acc : newAccounts) {
            Decimal dispenserCount = acc.No_of_Dispensers__c;
            for (Decimal i = 1; i <= dispenserCount; i++) {
                dispensersToCreate.add(new Account_Dispensor__c(
                    Name = 'Point_' + i,
                    Business_Partner__c=acc.Id
                ));
            }
        }

        if (!dispensersToCreate.isEmpty()) {
            insert dispensersToCreate;
        }
    }
    
    public static void handleUpdate(List<Account> newList, Map<Id, Account> oldMap) {
        List<Account_Dispensor__c> dispensersToCreate = new List<Account_Dispensor__c>();

        // Query existing dispensers to find the last number per account
        Map<Id, Integer> accountMaxPointNumMap = new Map<Id, Integer>();
        for (Account_Dispensor__c disp : [
            SELECT Name, Business_Partner__c
            FROM Account_Dispensor__c
            WHERE Business_Partner__c IN :newList
        ]) {
            Integer num = 0;
            if (disp.Name != null && disp.Name.startsWith('Point_')) {
                String suffix = disp.Name.replace('Point_', '');
                // ✅ Apex way to check numeric
                if (Pattern.matches('^[0-9]+$', suffix)) {
                    num = Integer.valueOf(suffix);
                }
            }
            Integer currentMax = accountMaxPointNumMap.get(disp.Business_Partner__c);
            accountMaxPointNumMap.put(
                disp.Business_Partner__c,
                currentMax == null ? num : Math.max(currentMax, num)
            );
        }
        
        for (Account acc : newList) {
            Account oldAcc = oldMap.get(acc.Id);

            Decimal oldCount = oldAcc.No_of_Dispensers__c;
            Decimal newCount = acc.No_of_Dispensers__c;
            if (oldCount == null) oldCount = 0;
            if (newCount == null) newCount = 0;

            if (newCount > oldCount) {
                Decimal additional = newCount - oldCount;
                Integer startIndex = accountMaxPointNumMap.containsKey(acc.Id)
                    ? accountMaxPointNumMap.get(acc.Id) + 1
                    : 1;

                for (Integer i = 0; i < additional; i++) {
                    dispensersToCreate.add(new Account_Dispensor__c(
                        Name = 'Point_' + (startIndex + i),
                        Business_Partner__c = acc.Id
                    ));
                }
            }
        }

        if (!dispensersToCreate.isEmpty()) {
            insert dispensersToCreate;
        }
    }
    public static void updateBillingLatLong(List<Account> newList, Map<Id, Account> oldMap) {
        for (Account acc : newList) {
            Boolean isNew = (acc.Id == null);
            Boolean geoChanged = false;
            if (isNew) {
                geoChanged = (acc.Geolocation__Longitude__s != null && acc.Geolocation__Latitude__s!=null);
            } else {
                Account oldAcc = oldMap.get(acc.Id);
                geoChanged = ((acc.Geolocation__Longitude__s != oldAcc.Geolocation__Longitude__s) && (acc.Geolocation__Latitude__s != oldAcc.Geolocation__Latitude__s));
            }
            if (geoChanged) {
                acc.BillingLatitude  = acc.Geolocation__Latitude__s;
                acc.BillingLongitude = acc.Geolocation__Longitude__s;
            }
        }
    }

    public static void lastModifiedBySAP(List<Account> newList) {
        // Username of SAP Automated User
        String SAP_USER_NAME = 'Automated User';

        if (UserInfo.getName() != SAP_USER_NAME) {
            return;
        }

        Datetime nowDt = System.now();

        for (Account acc : newList) {
            acc.Last_Modified_By_SAP__c = nowDt;
        }
    }


=======
public class AccountTriggerHandler {
    
    public static void updatePhone(List<Account>accList, Map<id, Account> accOldMap)
    {
        
        for(Account acc : accList)
        {   
            if(acc.Phone != accOldMap.get(acc.Id).phone)
            {
                acc.Description = 'Phone is updated | Old Value = ' + accOldMap.get(acc.Id).Phone +'New Value='+ acc.Phone;
            }
        }
    }
    public static void CreateOpp(List<Account> accList)
    {
        List<Opportunity> oppList = new List<Opportunity>();
        for(Account acc : accList)
        {
            Opportunity opp = new Opportunity();
            opp.Name= acc.Name; 
            opp.CloseDate = System.today();
            opp.StageName = 'Prospecting';
            opp.AccountId = acc.Id;
            oppList.add(opp);
        }
        if(!oppList.isEmpty())
        {
            insert oppList;
        }
    }
    
    public static void UpdateDesc(List<Account> accList)
    {
        for(Account acc: acclist)
        {
            acc.Description = 'Account is created';
        }
    }
    
    //if account phone is updated then populate phone number on all the related contact: using Map
    
    public static void UpdateRelatedContact(List<Account> accList, Map<ID, Account> accOldMap)
    {
        List<Contact > conList = new List<Contact>();
        Map<Id, Account> accMap = new Map <id,Account>();
        
        for(Account acc : accList)
        {
            if(acc.Phone!= accoldMap.get(acc.Id).phone)
            {
                accMap.put(acc.Id,acc);
            }
        }
        conList = [Select ID, HomePhone,AccountId from Contact where AccountId in: accMap.KeySet()];
        
        List<Contact> contListupdate = new List<Contact>();
        
        for(Contact con : conList){
            if(accMap.containsKey(con.AccountId))
            {
                con.HomePhone= accMap.get(con.AccountId).Phone;
                contListupdate.add(con);
            }
        }
        
        if(!conlist.isempty())
        {
            update contListupdate;
        }
        
    }
    
    //Q.If the Account phone is updated then populate the phone number on all
    //related Contacts (Home Phone field). [Using Parent-Child SOQL]
    public static void populateRelatedNumber(List<Account> accList, Map<id, Account> OldMap)
    {
        set<Id> accIds = new set<Id>();
        // Identify Accounts with updated Phone numbers and collect their IDs.
        for(Account acc : accList)
        {
            if((acc.Phone!=null&& acc.Phone!=(OldMap.get(acc.id).Phone))&& OldMap!=Null)
            {
                accIds.add(acc.id);
            }
        }
        // Query related Contacts and update their HomePhone to match the Account's new Phone number.
        List<Contact> conList= new List<Contact>();
        for(Account acc: [SELECT id, Phone, (Select Homephone from contacts) from account where id in: accids])
        {
            if(acc.contacts!=null)
            {
                for(Contact con : acc.Contacts)
                {
                    con.HomePhone =acc.phone;
                    conList.add(con);
                }
            }
        }
        if(!conList.isempty())
        {
            update conList;
        }
    }
    //If the Account billing address is updated then update related contacts
    //mailing address. [Using Parent-Child SOQL]
    
    public static void populateBilingAddress(List<Account> accList,Map<id,Account> OldMap)
    {
        Set<id> idSet = new Set<id>();
        
        for(Account acc: accList)
        {
            if (OldMap != null && acc.BillingAddress != null && 
                (!acc.BillingCity.equals(OldMap.get(acc.Id).BillingCity) ||
                 !acc.BillingCountry.equals(OldMap.get(acc.Id).BillingCountry) ||
                 !acc.BillingPostalCode.equals(OldMap.get(acc.Id).BillingPostalCode) ||
                 !acc.BillingState.equals(OldMap.get(acc.Id).BillingState) ||
                 !acc.BillingStreet.equals(OldMap.get(acc.Id).BillingStreet)))
            {
                idSet.add(acc.Id);
            }
        }
        List<Contact> conList = new List<Contact>();
        for(Account acc:[SELECT Id, BillingCountry, BillingCity, BillingState,
                         BillingPostalCode, BillingStreet, (SELECT Id FROM Contacts) FROM
                         Account WHERE Id IN:idSet])
        {
            if(acc.Contacts!=null)
            {
                for(Contact con : acc.contacts)
                {
                    con.MailingCountry=acc.BillingCountry;
                    con.MailingCity= acc.BillingCity;
                    con.MailingState=acc.BillingState;
                    con.MailingPostalCode=acc.BillingPostalCode;
                    con.MailingStreet=acc.BillingStreet;
                    conList.add(con);
                }
            }
        }
        if(!conList.isempty())    
        {
            update conList;
        }
        
    }
    //Write a trigger on Account when Account Active field is updated from ‘Yes’
    //to ‘No’ then check all opportunities associated with the account. Update all
    //Opportunities Stage to close lost if stage not equal to close won.
    public static void  updateopportunityStageName(List<Account> accList, Map<id, Account> oldmap)
    {
        set<id> idset = new set<id>();
        
        for(Account acc: accList)
        {
            if(acc.Active__c=='No' &&acc.Active__c!=oldmap.get(acc.Id).Active__c)
            {
                idset.add(acc.Id);
            }
        }
        List<Opportunity> oppList =  new List<Opportunity> ();       
        for (account acc :[Select id, Active__c,(select id, StageName from Opportunities) from Account where id in: idset])
        {
            if(acc.Opportunities!=null)
            {
                for(opportunity opp: acc.Opportunities)
                {
                    if(opp.StageName!='Closed Won' && 
                       opp.StageName!='Closed Lost')
                    {
                        opp.StageName='Closed LOst';
                        oppList.add(opp);
                    }
                }
                
            }
        }
        Update oppList;
    }
    // Before Delete
    // 1.Account record cannot be deleted if active is yes.
    // 2. Use Custom Label to show error  message
    // 3. apply a check that only system  Administrator profile user can delte an account.   
    public static void preventDeletion(List<Account> accList)
    {
        profile p = [Select id from profile where Name= 'System administrator'];
        
        for(Account acc: acclist)
        {
            if(userinfo.getProfileid()!= p.id || acc.Active__c=='Yes')
            {
                acc.addError(Label.Prevent_deletion_creation);
            }
        }
    }
    
    //Prevent account record from being edited if the record is created 7 days
    //back
    
    public static void prevnetAccEdit(List<Account> accList)
    {
        for(Account acc: accList)
        {
            if(acc.CreatedDate<System.today()-6)
            {
                acc.addError('You cannot update account created 7 days back');
            }
        }
    }
    
    //Apply validation using addError( ) method in trigger. While Creation of
    //Opportunity is Amount is null then throw an error message.
    
    public static void validateAmmount(List<Opportunity> oppList)
    {
        for(Opportunity opp: oppList)
        {
            if(opp.Amount==null)
            {
                opp.addError('Amount filed can not be null');
            }
        }
    }
    
    
    //26. Prevent deletion of an account if there is any opportunity related to that
    //account.    
    public static void Preventdeleteifhasrelatedoppo(List<Account> accList)
    {
        set<id> idset = new set<id>();
        
        for(Account acc : accList)
        {
            idset.add(acc.Id);
        }
        
        List<opportunity> accList1 = [select accountid from opportunity where accountid in : idset];
        
        if(accList1.size()>0){
            
            for(Account acc: accList)
            {
                acc.addError('You can ]not delete account where the the opportunities are available');
                
            }
        }
        
        
    }
    
    //27. Prevent deletion of an account if there is any case related to that account.
    
    /*Public static void PreventdeleteifhasrelatedCase(List<Account> accList)
{
Set<id> idset = new Set<id>();

for(Account acc: accList)
{
idset.add(acc.id);
}

List<Account> accList1 = [Select id,(Select id from cases) from Account where id in: idset];

for(Account acc : accList1)
{
if(acc.cases.size()>0)
{
acc.addError('You can not delete account where the the case are available');
}
}
}*/
    
    /*Public static void PreventdeleteifhasrelatedCase(List<Account> accList)
{
Set<id> idset = new Set<id>();

for(Account acc: accList)
{
idset.add(acc.id);
}

List<CAse> caseList = [Select Accountid from case  where Accountid in: idset];

if(caseList.size()>0)
{
For(Account acc: acclist)
{
acc.addError('You can not delete account where the the case are available');
}
}
}*/
    
    public static void PreventdeleteifhasrelatedCase(List<Account> accList) {
        Set<Id> idSet = new Set<Id>();
        
        // Collect account IDs from the provided list
        for (Account acc : accList) {
            idSet.add(acc.Id);
        }
        
        // Query cases that are related to these accounts
        List<Case> caseList = [SELECT AccountId FROM Case WHERE AccountId IN :idSet];
        
        // Collect Account IDs that have related cases
        Set<Id> accountsWithCases = new Set<Id>();
        for (Case c : caseList) {
            accountsWithCases.add(c.AccountId);
        }
        
        // Add error to accounts that have related cases
        for (Account acc : accList) {
            if (accountsWithCases.contains(acc.Id)) {
                acc.addError('You cannot delete an account where cases are available.');
            }
        }
    }
    //case 9 - if Account with industry aggriculture and type is prospect updated and ownership is set to private do not allow 
    //user to set this ownership?
    public static void populatError(List<Account> newRecord,map<id,Account> oldmap){
        for(Account acc: newRecord)
        {
            if((acc.Industry=='Agriculture' && acc.type=='Prospect') 
               && 
               (oldmap.get(acc.id).Ownership != acc.Ownership) && acc.Ownership=='private')
            {
                acc.adderror('ownership cannot bew modidfied');
            }
        }
    }
    //CAse 10: every time an account website is updated , 
    //update the website field on all child contacts for the account
    
    public static void pupulatewebsiteofcontact(List<Account> newrecord,Map<id,Account> oldmap)
    {
        set<id> accid =new set<id>();
        for(Account acc : newrecord)
        {
            if(acc.Website!=oldmap.get(acc.id).website)
            {
                accid.add(acc.Id);
            }
        }
        List<Account> accList=[Select id,website,(select website__c from contacts ) from account where id in : accid];
        
        List<Contact> conList = new List<Contact>();
        
        for(Account acc: accList)
        {
            if(acc.contacts!=null)
            {
                for(Contact con : acc.contacts)
                {
                    con.Website__c=acc.Website;
                    conList.add(con);
                }
            }
        }
        
        if(!conList.isempty())
        {
            update conList;
        }
    }
    //OR
    
    public static void handleBeforeUpdateactivities(List<Account> newRecords, map<id,Account> oldmap)
    {
        Map<id,string> accToWebsiteMap = new Map<id,string>();
        
        for(Account acc : newRecords)
        {
            if(acc.website != oldmap.get(acc.Id).website){
                accToWebsiteMap.put(acc.id,acc.Website);
            }
        }
        
        if(accToWebsiteMap.keyset().size()>0){
            
            list<Contact> addConTUpdate = new List<Contact>();
            
            List<Contact> conRecords = [Select id, firstName, website__c from Contact 
                                        where Accountid in:accToWebsiteMap.keyset()];
            
            for(Contact con :conRecords){
                con.Website__c=accToWebsiteMap.get(con.AccountId);
                addConTUpdate.add(con);
            }
            
            if(addConTUpdate.size() > 0){
                update addConTUpdate;
            }
        }
    }
    
  //case11 create contact records based on create N contact filed on the account record
  
     
    Public static void populateNcontact(List<Account> newRecords)
    {
        List<Contact> conList = new List<Contact>();
        for(Account acc : newRecords)
        {
            if(acc.create_N_Contact__c!= null)
            {
                for(integer i=0; i<acc.create_N_Contact__c; i++)
                {
                    Contact con = new Contact();
                    con.FirstName = acc.Name + i;
                    con.LastName = 'miki';
                    con.Accountid=acc.Id;
                    conList.add(con);
                }
            }
        }
        if(!conList.isempty())
        {
           insert conList;
        }
    }
>>>>>>> e604021b64f33882bfed07c2bfed265ad53326cf
}