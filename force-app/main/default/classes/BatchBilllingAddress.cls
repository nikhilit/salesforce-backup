public class BatchBilllingAddress implements Database.Batchable<sObject>,Database.Stateful{
    Integer totalCount = 0;
    public Database.QueryLocator start (Database.BatchableContext bc ){
        return Database.getQueryLocator([Select id, MailingStreet, MailingCity, 
                                         MailingState, MailingPostalCode, MailingCountry, 
                                         Account.BillingStreet, Account.BillingCity, 
                                         Account.BillingState, Account.BillingPostalCode, 
                                         Account.BillingCountry
                                         FROM Contact WHERE AccountId != NULL]);
    }
    
    public void execute(Database.BatchableContext bc, List<Contact> conList){
        if(!conList.isempty()){
            for(Contact con : conList){
                con.MailingStreet = con.Account.BillingStreet;
                con.MailingCity = con.Account.BillingCity;
                con.MailingState = con.Account.BillingState;
                con.MailingPostalCode = con.Account.BillingPostalCode;
                con.MailingCountry = con.Account.BillingCountry;
                conList.add(con);
                totalCount+=1;
                
            }
            update conList;
            
        }
    }
    public void finish(Database.BatchableContext bc) {
        System.debug('Contact processing completed.');
        System.debug('Contact processing completed. Total records processed: ' + totalCount);
    }
}