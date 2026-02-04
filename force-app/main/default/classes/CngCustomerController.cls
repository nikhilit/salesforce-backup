public with sharing class CngCustomerController {
    @AuraEnabled(cacheable=true)
    public static List<WorkOrder> searchCngCustomers(String location, String outlet, String company, String zone) {
        System.debug('location : --> '+location);
        System.debug('outlet : --> '+outlet);
        System.debug('company : --> '+company);
        System.debug('zone : --> '+zone);
        String baseQuery = 'SELECT Id, Remarks__c, WorkOrderNumber, Outlet_Name__c, Scheduled_Date__c, Account.BP_Number__c, Account.CA_Number__c, Account.Dispenser_Number__c, Account.Category__c, Subject, AccountId, ' +
                           'Account.Name, Account.Location__c, Account.BillingStreet, Account.BillingCity, Account.BillingState, Account.BillingPostalCode, ' +
                           'Account.Representative_Company__c, Account.Zone__c, Account.Phone, ' +
                           'Account.Meter_Number__c, Account.Customer_Contact_no__c, Account.Customer_Contact_No_Home__c, Account.Customer_Contact_No_Office__c, Account.Email_Id__c, Account.Flat__c, Account.Floor__c, Account.Plot__c, Account.Wing__c, Account.Building_name__c, Colony__c, ' +
                           'Account.Society_Name__c, Account.Road_name__c, Account.City__c, Account.Street__c ' +
                           'FROM WorkOrder WHERE Account.Category__c = \'CNG/LNG\' ';

        List<String> filters = new List<String>();
        if (String.isNotBlank(location)) {
            filters.add(' (Account.Location__c LIKE \'%' + String.escapeSingleQuotes(location) + '%\' OR Account.BillingCity LIKE \'%' + String.escapeSingleQuotes(location) + '%\') ');
        }
        if (String.isNotBlank(outlet)) {
            filters.add(' Outlet_Name__c LIKE \'%' + String.escapeSingleQuotes(outlet) + '%\' ');
        }
        if (String.isNotBlank(company)) {
            filters.add(' Account.Representative_Company__c LIKE \'%' + String.escapeSingleQuotes(company) + '%\' ');
        }
        if (String.isNotBlank(zone)) {
            filters.add(' Account.Zone__c LIKE \'%' + String.escapeSingleQuotes(zone) + '%\' ');
        }

        if (!filters.isEmpty()) {
            baseQuery += ' AND ' + String.join(filters, ' AND ');
        }

        // return Database.query(baseQuery + ' LIMIT 50');
        return Database.query(baseQuery);
    }
}