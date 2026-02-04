public class DeptSPOCMappingTriggerHandler {
    
    public static void updateQrcDrsSpocIds(List<Departments_SPOC_Mapping__c> mappings) {
        for (Departments_SPOC_Mapping__c m : mappings) {

            // DRS
            if (!String.isBlank(m.DRS_ID_Text__c)) {
                m.DRS__c = m.DRS_ID_Text__c;
            }

            // QRC Process
            if (!String.isBlank(m.QRC_ID_Text__c)) {
                m.QRC_Process__c = m.QRC_ID_Text__c;
            }

            // SPOC 1
            if (!String.isBlank(m.SPOC_1_ID_Text__c)) {
                m.SPOC_Id__c = m.SPOC_1_ID_Text__c;
            }

            // SPOC 2
            if (!String.isBlank(m.SPOC_2_ID_Text__c)) {
                m.SPOC_Id_2__c = m.SPOC_2_ID_Text__c;
            }

            // SPOC 3
            if (!String.isBlank(m.SPOC_3_ID_Text__c)) {
                m.SPOC_Id_3__c = m.SPOC_3_ID_Text__c;
            }

            // SPOC 4
            if (!String.isBlank(m.SPOC_4_ID_Text__c)) {
                m.SPOC_Id_4__c = m.SPOC_4_ID_Text__c;
            }
        }
    }

}