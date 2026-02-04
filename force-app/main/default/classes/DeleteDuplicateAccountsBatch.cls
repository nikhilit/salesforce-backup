public class DeleteDuplicateAccountsBatch implements Database.Batchable<SObject>, Database.Stateful {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Print_Doc_Number__c, LastModifiedDate
            FROM Billing__c
            WHERE Print_Doc_Number__c != null
            ORDER BY Print_Doc_Number__c, LastModifiedDate DESC
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Billing__c> scope) {
        // Group by Print_Doc_Number__c
        Map<String, List<Billing__c>> groupedByDoc = new Map<String, List<Billing__c>>();

        for (Billing__c bill : scope) {
            if (!groupedByDoc.containsKey(bill.Print_Doc_Number__c)) {
                groupedByDoc.put(bill.Print_Doc_Number__c, new List<Billing__c>());
            }
            groupedByDoc.get(bill.Print_Doc_Number__c).add(bill);
        }

        List<Billing__c> toDelete = new List<Billing__c>();

        // For each group, keep the latest, delete the rest
        for (String docNumber : groupedByDoc.keySet()) {
            List<Billing__c> bills = groupedByDoc.get(docNumber);

            // Sort using custom comparator
            bills.sort(new BillingDateComparator());

            // Keep the first record (latest), delete the rest
            for (Integer i = 1; i < bills.size(); i++) {
                toDelete.add(bills[i]);
            }
        }

        if (!toDelete.isEmpty()) {
            try {
                delete toDelete;
            } catch (Exception e) {
                System.debug('Error deleting duplicates: ' + e.getMessage());
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Duplicate Billings deletion cleanup completed.');
    }

    // Custom comparator class to sort by LastModifiedDate DESC
    public class BillingDateComparator implements Comparator<Billing__c> {
        public Integer compare(Billing__c a, Billing__c b) {
            if (a.LastModifiedDate == b.LastModifiedDate) return 0;
            return a.LastModifiedDate > b.LastModifiedDate ? -1 : 1; 
        }
    }
}