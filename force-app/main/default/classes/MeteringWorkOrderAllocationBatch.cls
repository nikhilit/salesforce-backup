/**
 * @description       :
 * @author            : Kartik Patkar Appstrail
 * @group             :
 * @last modified on  : 16-09-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   15-05-2025   Kartik Patkar, Appstrail   Initial Version
 **/
public with sharing class MeteringWorkOrderAllocationBatch implements Database.Batchable<sObject>, Database.Stateful{
    
    public String query='SELECT Id, Customer__c, Portion__c,Meter_Reading_Date__c, Scheduled_Meter_Reading_Date__c, MRU__c,Name,'+
                            'Customer_Location__c,Customer_Road_Name__c,Building__c,Customer_Postal_Code__c,Meter_Reading_Doc_Number__c,Customer_Category__c,Agent__c,Scheduled_Meter_Reading_End_Date__c,Meter_Reader_Name__c '+
                        'FROM Meter_Reading_Order__c '+
                        'WHERE Created_Order__c = FALSE AND Customer__c != null '+
                            'AND Scheduled_Meter_Reading_Date__c != null '+
                        'ORDER BY Customer_Location__c,Customer_Postal_Code__c,Customer_Road_Name__c,Building__c ASC';

    public MeteringWorkOrderAllocationBatch() {}
    public Map<String,Id> mapKeyAgentId=new Map<String,Id>();
    public Map<Id,Integer> mapAgencyUtilizedCapacity = new Map<Id,Integer>();

    Map<String,MeteringWorkOrderAllocationHelper.MRU_Wrapper> mapMRU = new Map<String,MeteringWorkOrderAllocationHelper.MRU_Wrapper>();
    
    public MeteringWorkOrderAllocationBatch(String query) {
        this.query = query;
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<Meter_Reading_Order__c> scope) {
        // MeteringWorkOrderAllocationHelper.mapKeyAgentId=mapKeyAgentId;
        // MeteringWorkOrderAllocationHelper.mapAgencyUtilizedCapacity = mapAgencyUtilizedCapacity;
        mapMRU=MeteringWorkOrderAllocationHelper.workOrderCreationAndScheduling(scope,mapMRU);
    }
    
    public void finish(Database.BatchableContext BC) {
        
        
    }
}