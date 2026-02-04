public class SecurityDepositTriggerHandler {

    public static void assignValues(List<Security_Deposit__c> newList, Map<Id, Security_Deposit__c> oldMap) {
        for (Security_Deposit__c dep : newList) {

            Boolean isNew = (oldMap == null || !oldMap.containsKey(dep.Id));
            Boolean securityNumberChanged = false;
            Boolean businessPartnerChanged = false;
            if (!isNew) {
                Security_Deposit__c oldDep = oldMap.get(dep.Id);
                businessPartnerChanged = dep.Business_Partner__c != oldDep.Business_Partner__c;
                securityNumberChanged = dep.Security_Number__c != oldDep.Security_Number__c;
            }

            if (isNew || businessPartnerChanged) {
                dep.To_be_processed__c = true;
            }

            if ((isNew || securityNumberChanged) && !String.isBlank(dep.Security_Number__c)) {
                dep.Name = dep.Security_Number__c;
            }
        }
    }
}