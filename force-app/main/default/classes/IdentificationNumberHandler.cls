public class IdentificationNumberHandler {

    public static void markIdentificationsToBeProcessed(
        List<Identification_Number__c> newList,
        Map<Id, Identification_Number__c> oldMap
    ) {
        for (Identification_Number__c ident : newList) {
            Boolean isNew = (oldMap == null || !oldMap.containsKey(ident.Id));
            Boolean identificationCodeChanged = false;
            Boolean businessPartnerChanged = false;
            Boolean hasNullBP = (ident.BP__c == null);

            if (!isNew) {
                Identification_Number__c oldIdent = oldMap.get(ident.Id);
                identificationCodeChanged = ident.Unique_Id__c != oldIdent.Unique_Id__c;
                businessPartnerChanged = ident.Business_Partner__c != oldIdent.Business_Partner__c;
            } else {
                identificationCodeChanged = (ident.Unique_Id__c != null);
            }

            if (isNew || identificationCodeChanged || businessPartnerChanged || hasNullBP) {
                ident.To_be_processed__c = true;
            }

            if (isNew || identificationCodeChanged && String.isNotBlank(ident.Unique_Id__c)) {
                ident.Name = ident.Unique_Id__c;
            }
        }
    }
}