/**
 * @description       :
 * @author            : Kartik Patkar Appstrail
 * @group             :
 * @last modified on  : 18-11-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   07-07-2025   Kartik Patkar, Appstrail   Initial Version
 **/
public with sharing class ContentVersionTriggerHandler {

    public static void afterInsert(List<ContentVersion> newList){
        indirectMeterImage(newList, null);
    }
    
    public static void afterUpdate(List<ContentVersion> newList,Map<Id,ContentVersion> oldMap){
        indirectMeterImage(newList, oldMap);
    }
    
    public static void indirectMeterImage(List<ContentVersion> newList,Map<Id,ContentVersion> oldMap){
        List<ContentVersion> contVerList = new List<ContentVersion>();
        for(ContentVersion contentVersion : newList){
            if(contentVersion.In_Direct_Meter_Reading__c == true && contentVersion.BP_Number__c!=null
                && (oldMap==null || (contentVersion.In_Direct_Meter_Reading__c != oldMap.get(contentVersion.Id).In_Direct_Meter_Reading__c
                || contentVersion.BP_Number__c != oldMap.get(contentVersion.Id).BP_Number__c))){

                contVerList.add(contentVersion);
            }
        }

        if(!contVerList.isEmpty()){
            IndirectMeterImageTaggingHelper.attachFileToWorkOrder(contVerList);
        }
    }
}