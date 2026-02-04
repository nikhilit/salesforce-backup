/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 27-06-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   26-06-2025   Kartik Patkar, Appstrail   Initial Version
**/
public with sharing class MeterReadingScheduleApprovalBatch implements Database.Batchable<sObject>, Database.Stateful{

    public String mrsId;
    public String query='SELECT Id, WorkOrderNumber, CreatedDate, AccountId, Meter_Reading__c, Customer_BP_Number__c,'+
                            'Assigned_Meter_Reader__c, Scheduled_Date__c, Customer_Category__c,'+
                            'Meter_Reading_Order__c, Meter_Reading_Schedule__c, MRU__c, Appointment_Status__c, BP_Number__c,'+
                            'Metering_Agency__c, Portion__c, Meter_Reading_Unit__c, Building_Name__c, Postal_Code__c, '+
                            'Location__c, Road_Name__c '+
                        'FROM WorkOrder WHERE Assigned_Meter_Reader__c!=null';
    public Boolean customQuery = false;

    public MeterReadingScheduleApprovalBatch() {

    }

    public MeterReadingScheduleApprovalBatch(String mrsId, String query, Boolean customQuery) {
        this.mrsId = mrsId;
        if(query != null) {
            this.query = query;
        }
        this.customQuery = customQuery;
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        if(!customQuery && mrsId != null){
            query += ' AND Meter_Reading_Schedule__c = :mrsId';
        }
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<WorkOrder> scope) {
        MeteringWorkOrderAllocationHelper.approvalMRSAssignResource(scope,mrsId);
    }
    
    public void finish(Database.BatchableContext BC) {
        Meter_Reading_Schedule__c mrsRec=new Meter_Reading_Schedule__c();
        mrsRec.Id=mrsId;
		mrsRec.Status__c='Approved';
        update mrsRec;
        // Optional: Add any post-processing logic here
    }
}