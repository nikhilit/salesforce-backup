public class ChronologyTriggerHandler {

    public static void markChronologyToBeProcessed(
        List<Chronology__c> newList,
        Map<Id, Chronology__c> oldMap
    ) {
        for (Chronology__c chr : newList) {
            
            Boolean isNew = (oldMap == null || !oldMap.containsKey(chr.Id));

            Boolean hasNullLookup =
                chr.Contract_Account_Name__c == null ||
                chr.BP_Number__c == null;

            Boolean textChanged = false;
            Boolean docNumberChanged = false;

            if (!isNew) {
                Chronology__c oldChr = oldMap.get(chr.Id);
                textChanged = 
                    chr.Contract_Account__c != oldChr.Contract_Account__c ||
                    chr.Business_Partner__c != oldChr.Business_Partner__c;

                docNumberChanged = chr.Doc_Number__c != oldChr.Doc_Number__c;
            } else {
                docNumberChanged = chr.Doc_Number__c != null;
            }

            if (isNew || hasNullLookup || textChanged) {
                chr.To_be_processed__c = true;
            }

            if (docNumberChanged && String.isNotBlank(chr.Doc_Number__c)) {
                chr.Name = chr.Doc_Number__c;
            }
        }
    }
}