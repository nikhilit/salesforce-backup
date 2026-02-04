/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 29-01-2026
 * @last modified by  : Kartik Patkar Appstrail 
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   29-01-2026   Kartik Patkar, Appstrail   Initial Version
**/
public class DispenserPointHandler {

    public static void handleLiveFlag(
        List<Dispenser_Point__c> newList,
        Map<Id, Dispenser_Point__c> oldMap
    ) {

        Set<Id> workOrderIds = new Set<Id>();
        Map<String, Id> baseNameToLatestId = new Map<String, Id>(); // Map base name to latest record Id

        for (Dispenser_Point__c dp : newList) {

            // INSERT → Live__c = true
            if (oldMap == null && dp.Live__c == true && dp.WorkOrderID__c != null) {
                workOrderIds.add(dp.WorkOrderID__c);
                String baseName = extractBaseName(dp.Dispenser_Name__c);
                baseNameToLatestId.put(baseName, dp.Id);
            }

            // UPDATE → false → true
            if (
                oldMap != null &&
                dp.Live__c == true &&
                oldMap.get(dp.Id).Live__c == false &&
                dp.WorkOrderID__c != null
            ) {

                workOrderIds.add(dp.WorkOrderID__c);
                String baseName = extractBaseName(dp.Dispenser_Name__c);
                baseNameToLatestId.put(baseName, dp.Id);
            }
        }

        if (baseNameToLatestId.isEmpty()) return;

        // Single bulkified query - only for affected work orders
        Set<String> baseNames = baseNameToLatestId.keySet();
        
        List<Dispenser_Point__c> recordsToUpdate = [
            SELECT Id, Live__c, Dispenser_Name__c
            FROM Dispenser_Point__c
            WHERE WorkOrderID__c IN :workOrderIds
            AND Live__c = true AND Id NOT IN :baseNameToLatestId.values()
            LIMIT 10000
        ];

        // Process and filter in memory
        List<Dispenser_Point__c> toDeactivate = new List<Dispenser_Point__c>();
        
        for (Dispenser_Point__c dp : recordsToUpdate) {
            String baseName = extractBaseName(dp.Dispenser_Name__c);
            
            // If this record is NOT the latest for its base name, deactivate it
            if (baseNames.contains(baseName) && baseNameToLatestId.get(baseName) != dp.Id) {
                dp.Live__c = false;
                toDeactivate.add(dp);
            }
        }

        // Single bulk update DML
        if (!toDeactivate.isEmpty()) {
            update toDeactivate;
        }
    }

    private static String extractBaseName(String dispenserName) {
        // Extract base name from patterns like:
        // "Point_1" -> "Point_1"
        // "Point_1_New_1" -> "Point_1"
        // "Point_1_New_2" -> "Point_1"
        Pattern p = Pattern.compile('^(Point_\\d+)(?:_New_\\d+)?$');
        Matcher m = p.matcher(dispenserName);
        
        if (m.matches()) {
            return m.group(1);
        }
        
        return dispenserName;
    }
}