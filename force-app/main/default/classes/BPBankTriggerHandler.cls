public class BPBankTriggerHandler {
    public static void markBPBankToBeProcessed(
        List<BP_Bank_Details__c> newList,
        Map<Id, BP_Bank_Details__c> oldMap
    ) {
        for (BP_Bank_Details__c bank : newList) {
            
            Boolean isNew = (oldMap == null || !oldMap.containsKey(bank.Id));
            Boolean uniqueIdChanged = !isNew && bank.Unique_ID__c != oldMap.get(bank.Id).Unique_ID__c;
            Boolean bpNumberChanged = !isNew && bank.BP_Number__c != oldMap.get(bank.Id).BP_Number__c;
            
            if (isNew || bpNumberChanged) {
                bank.To_Be_Processed__c = true;
            }

            if (isNew || uniqueIdChanged &&( bank.Unique_ID__c != null)) {
                bank.Name = bank.Unique_ID__c;
            }
        }
    }
}