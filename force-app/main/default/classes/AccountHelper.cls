public with sharing class AccountHelper {
    @AuraEnabled(cacheable=true)
    public static List<Account> getAccountData() {
        return [
            select id , Name , Industry, Rating 
            from account 
            with USER_MODE 
        ];
    }


    @AuraEnabled(cacheable=true)
    public static List<Account> getParentAccounts(){
        return [select id , Name , Industry from Account where
        AnnualRevenue != null WITH USER_MODE];
    }

    @AuraEnabled(cacheable=true)
    public static List<Account> searchData(String searchKey){
        String s1 ='%'+searchKey+'%';
        return [select Id, Name, Phone, Type, Industry from Account where Name LIKE:s1];
        
    }

    @AuraEnabled
    public static void updateData(List<Account> updatedRecords) {
        try {
            update updatedRecords;
        } catch (Exception e) {
            throw new AuraHandledException('Error updating records: ' + e.getMessage());
        }
    }

    
        @AuraEnabled(cacheable=true)
        public static List<Contact> getRelatedContacts(Id accountId) {
            return [SELECT Id, Name, Email, Phone FROM Contact WHERE AccountId = :accountId];
        }




    @AuraEnabled(cacheable=true)
    public static List<Account> getAccounts(String searchText){
        try {
        
            if(String.IsEmpty(searchText)){
                return [SELECT Id,Name FROM  Account limit 10];
            }
            else {
                searchText='%'+searchText+'%';
                return [SELECT Id,Name FROM  Account WHERE Name LIKE :searchText limit 10];
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
   public static List<Contact> getAccountContacts(String accountId){
    try {
        return [SELECT Id,Name FROM Contact WHERE accountId=:accountId];
    } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
    }
   }

}