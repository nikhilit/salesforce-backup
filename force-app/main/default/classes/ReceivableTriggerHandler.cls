public class ReceivableTriggerHandler {

    public static void markReceivablesToBeProcessed(
        List<Receivable__c> newList,
        Map<Id, Receivable__c> oldMap
    ) {
        for (Receivable__c rev : newList) {

            Boolean isNew = (oldMap == null || !oldMap.containsKey(rev.Id));

            // Lookup fields null check
            Boolean hasNullLookup = 
                rev.Contract_Account_Name__c == null ||
                rev.BP_Number__c == null;

            // Text field change check
            Boolean textChanged = false;
            Boolean docNumberChanged = false;

            if (!isNew) {
                Receivable__c oldRev = oldMap.get(rev.Id);
                textChanged = 
                    rev.Contract_Account__c != oldRev.Contract_Account__c ||
                    rev.Business_Partner__c != oldRev.Business_Partner__c;

                docNumberChanged = rev.Doc_Number__c != oldRev.Doc_Number__c;
            } else {
                docNumberChanged = rev.Doc_Number__c != null;
            }

            // Set to be processed
            if (isNew || hasNullLookup || textChanged) {
                rev.To_be_processed__c = true;
            }

            // Update Name if Doc Number changed
            if (docNumberChanged && String.isNotBlank(rev.Doc_Number__c)) {
                rev.Name = rev.Doc_Number__c;
            }
        }
    }
}