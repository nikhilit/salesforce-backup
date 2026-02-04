public class InstallationTriggerHandler {

    public static void markInstallationToBeProcessed(
        List<Installation__c> newList, 
        Map<Id, Installation__c> oldMap
    ) {
        for (Installation__c ins : newList) {
            Boolean isNew = (oldMap == null || !oldMap.containsKey(ins.Id));
            Boolean premiseChanged = false;
            Boolean installationChanged = false;

            if (!isNew) {
                Installation__c oldIns = oldMap.get(ins.Id);

                premiseChanged = ins.Premise__c != oldIns.Premise__c;
                installationChanged = ins.Installation__c != oldIns.Installation__c;
            }

            if (isNew || premiseChanged) {
                ins.To_Be_Processed__c = true;
            }

            if (isNew || installationChanged) {
                if (ins.Installation__c != null) {
                    ins.Name = ins.Installation__c;
                }
            }
        }
    }
}