/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 17-06-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   06-06-2025   Kartik Patkar, Appstrail   Initial Version
**/
public with sharing class ServiceTerritoryTriggerHandler {

    public static void beforeInsert(List<ServiceTerritory> newList){
        mapOperatingHours(newList);
    }
    
    public static void mapOperatingHours(List<ServiceTerritory> newList) {
        Map<Id,OperatingHours> mapOperatingHoursRec = new Map<Id,OperatingHours>([
            SELECT Id,Name FROM OperatingHours WHERE Name =:System.label.Default_Operating_Hours_Name
        ]);

        String gsRecordTypeID = Schema.getGlobalDescribe().get('ServiceTerritory').getDescribe()
                                    .getRecordTypeInfosByDeveloperName().get('Metering').getRecordTypeId();

        if(!mapOperatingHoursRec.values().isEmpty()){
            for(ServiceTerritory territory : newList){
                if(territory.RecordTypeId == gsRecordTypeID && territory.OperatingHoursId == null){
                    territory.OperatingHoursId = mapOperatingHoursRec.values()[0].Id;
                }
            }
        }
    }
}