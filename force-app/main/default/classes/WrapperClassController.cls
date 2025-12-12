public with sharing class WrapperClassController {
    @AuraEnabled(Cacheable = true)
    public static List<WrapperDemo> fetchAccAndCons() {
        List<WrapperDemo> lstWrapper = new List<WrapperDemo>();

        // Query Accounts with their related Contacts
        for (Account acc : [SELECT Id, Name, (SELECT Id, Name FROM Contacts) FROM Account with USER_MODE LIMIT 10]) {
            lstWrapper.add(new WrapperDemo(acc, acc.Contacts));
        }

        return lstWrapper;
    }

    // Wrapper Class
    public class WrapperDemo {
        @AuraEnabled public Account objAcc; // Account object
        @AuraEnabled public List<Contact> lstCons; // List of related Contacts

        // Constructor to initialize wrapper data
        public WrapperDemo(Account acc, List<Contact> contacts) {
            this.objAcc = acc;
            this.lstCons = contacts;
        }
    }
}