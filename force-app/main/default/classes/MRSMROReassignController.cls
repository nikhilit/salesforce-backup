/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 24-10-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   07-10-2025   Kartik Patkar, Appstrail   Initial Version
**/
public without sharing class MRSMROReassignController {
    
    @AuraEnabled
    public static Meter_Reading_Schedule__c getCurrentMRURecord(String recordId){
        try {
            List<Meter_Reading_Schedule__c> listMRU=[SELECT Id,MRS_Custom_Name__c,Agency__c,Agent__c,Meter_Reading_Start_Date__c,
                                                        Meter_Reading_Completion_Date__c 
                                                    FROM Meter_Reading_Schedule__c 
                                                    WHERE Id=:recordId LIMIT 1];
            if(!listMRU.isEmpty()){
                return listMRU[0];
            }
            return null;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<WorkOrder> getMRSRelatedWorkOrders(String mrsId,Integer limitValue, Integer offset){
        return [SELECT Id, AccountId,Customer_BP_Number__c,Building_Name__c,Account.Name,StartDate,EndDate,        
                    Appointment_Status__c,WorkOrderNumber,Customer_Full_Name__c,BP_Number__c,Start_Date_Formula__c,
                    End_Date__c
                FROM WorkOrder 
                WHERE Meter_Reading_Schedule__c=:mrsId AND Appointment_Status__c='Unattempted'
                LIMIT :limitValue 
                OFFSET :offset];
    }

    @AuraEnabled
    public static List<WorkOrder> getMRSRelatedWorkOrdersNoOffset(String mrsId){
        return [SELECT Id, AccountId,Customer_BP_Number__c,Building_Name__c,Account.Name,StartDate,EndDate,        
                    Appointment_Status__c,WorkOrderNumber,Customer_Full_Name__c,BP_Number__c,Start_Date_Formula__c,
                    End_Date__c
                FROM WorkOrder 
                WHERE Meter_Reading_Schedule__c=:mrsId AND Appointment_Status__c='Unattempted'];
    }
}