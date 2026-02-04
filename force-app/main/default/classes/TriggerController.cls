/**
 * @description       :
 * @author            : Kartik Patkar Appstrail
 * @group             :
 * @last modified on  : 14-05-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   14-05-2025   Kartik Patkar, Appstrail   Initial Version
 **/
public class TriggerController {
    @TestVisible
    private static Map<String, Boolean> triggerControlMap;
    
    private static void loadMetadata() {
        triggerControlMap = new Map<String, Boolean>();
        
        Map<String, Trigger_Control_Config__mdt> allRecords = Trigger_Control_Config__mdt.getAll();
        for (String devName : allRecords.keySet()) {
            Trigger_Control_Config__mdt record = allRecords.get(devName);
            String triggerName = record.Trigger_Name__c;
            Boolean isActive = record.Active__c;
            
            // Add each trigger configuration to the map
            triggerControlMap.put(triggerName, isActive);
        }
    }
    
    public static Boolean isTriggerActive(String developerName) {
        if (triggerControlMap == null) {
            loadMetadata();
        }
        // Manually checking if the key exists
        if (triggerControlMap.containsKey(developerName)) {
            return triggerControlMap.get(developerName);
        }
        
        // Default to true if the key doesn't exist
        return true;
    }
}