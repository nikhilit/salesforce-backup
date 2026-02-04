/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 21-09-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   21-09-2025   Kartik Patkar, Appstrail   Initial Version
**/
public without sharing class MeterReadingOrderTriggerHandler {

    public static void afterInsert(List<Meter_Reading_Order__c> newList){
        checkMeterReadingOrder(newList, null);
    }
    
    public static void afterUpdate(List<Meter_Reading_Order__c> newList, Map<Id, Meter_Reading_Order__c> oldMap){
        checkMeterReadingOrder(newList, oldMap);
    }

    public static void checkMeterReadingOrder(List<Meter_Reading_Order__c> newList, Map<Id, Meter_Reading_Order__c> oldMap){
        Set<Id> mroToSyncList = new Set<Id>();
        for(Meter_Reading_Order__c mroRec : newList){
            if(mroRec.Sync_Status__c == 'Ready for Sync' && (oldMap==null || oldMap.get(mroRec.Id).Sync_Status__c != mroRec.Sync_Status__c)){
                mroToSyncList.add(mroRec.Id);
            }
        }
        
        if(mroToSyncList.size()>0){
            syncMROToSAP(mroToSyncList);
        }
    }

    @future(callout=true)
    public static void syncMROToSAP(Set<Id> mroToSyncList){
        List<MRO_Sync_to_SAP_Field_Mapping__c> fieldMappingList = [SELECT Field_Api_Name__c, External_Field_Name__c, Object_Api_Name__c, Active__c 
                                                                    FROM MRO_Sync_to_SAP_Field_Mapping__c 
                                                                    WHERE Active__c = TRUE];

        if(fieldMappingList.size()==0){
            System.debug('MRO Sync to SAP Field Mapping not found.');
            return;
        }

        Set<String> fieldApiNames = new Set<String>();
        for(MRO_Sync_to_SAP_Field_Mapping__c fieldMapping : fieldMappingList){
            fieldApiNames.add(fieldMapping.Field_Api_Name__c);
        }

        String soql = 'SELECT Id';
        for(String fieldName : fieldApiNames){
            soql += ', ' + fieldName;
        }
        soql += ' FROM Meter_Reading_Order__c WHERE Id IN :mroToSyncList';
        List<Meter_Reading_Order__c> mroList = Database.query(soql);
        
        MRO_Sync_to_SAP_API_Config__mdt config = [SELECT Endpoint_URL__c, Content_Type__c, X_CSRF_Token__c 
                                                FROM MRO_Sync_to_SAP_API_Config__mdt 
                                                WHERE Active__c = TRUE 
                                                LIMIT 1];
        if(config == null){
            System.debug('MRO Sync to SAP API Configuration not found.');
            return;
        }
        
        for(Meter_Reading_Order__c mroRec : mroList){
            String payload = MeteringMROSyncToSapApiHelper.payloadBuilder(mroRec, fieldMappingList);
            String result = MeteringMROSyncToSapApiHelper.syncToSAP(payload, mroRec.Id, config);
            if(result == 'Success'){
                mroRec.Sync_Status__c = 'Success';
            } else {
                mroRec.Sync_Status__c = 'Failed';
            }
        }
        
        if(mroList.size()>0){
            update mroList;
        }
        
        // Create integration logs
        IntegrationLogHelper.createListIntegrationLog(MeteringMROSyncToSapApiHelper.listIntegrationLogWrap);
        MeteringMROSyncToSapApiHelper.listIntegrationLogWrap.clear();
    }
}