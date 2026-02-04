public class CaseTypeSMSTriggerHandler {

    public static void updateQrcId(List<Case_Type_SMS__c> mappings) {
        for (Case_Type_SMS__c m : mappings) {

            // QRC Process
            if (!String.isBlank(m.QRC_Process_Text__c)) {
                m.QRC_Process__c = m.QRC_Process_Text__c;
            }

        }
    }

}