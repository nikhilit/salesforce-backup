public class PremiseTriggerHandler {

    public static void markPremisesToBeProcessed(List<Premise__c> newList, Map<Id, Premise__c> oldMap) {
        for (Premise__c prem : newList) {

            Boolean isNew = (oldMap == null || !oldMap.containsKey(prem.Id));
            Boolean connectionCodeChanged = false;
            Boolean premiseCodeChanged = false;

            if (!isNew) {
                Premise__c oldPrem = oldMap.get(prem.Id);

                connectionCodeChanged = prem.Connection_Name__c != oldPrem.Connection_Name__c;

                premiseCodeChanged = prem.Premise_Code__c != oldPrem.Premise_Code__c;
            }

            if (isNew || connectionCodeChanged) {
                prem.To_be_processed__c = true;
            }

            if (isNew || premiseCodeChanged) {
                if (prem.Premise_Code__c != null) {
                    prem.Name = prem.Premise_Code__c;
                }
            }
        }
    }
}