/**
 * @description       :
 * @author            : Kartik Patkar Appstrail
 * @group             :
 * @last modified on  : 14-08-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   18-05-2025   Kartik Patkar, Appstrail   Initial Version
 * 2.0   19-05-2025   Shruthi, Appstrail
 **/
public without sharing class ServiceAppointmentTriggerHandler {

    
    public static void beforeInsert(List<ServiceAppointment> newList){
        meteringAppointmentFieldMapping(newList,null);
        updateServiceAppointment(newList);
    }
    public static void beforeUpdate(List<ServiceAppointment> newList,Map<Id,ServiceAppointment> oldMap){
        meteringAppointmentFieldMapping(newList,oldMap);  
    }
    
    public static void afterInsert(List<ServiceAppointment> newList){
        //serviceResourceAssignment(newList);
        appointmentStatusUpdate(newList,null);
        
        
        //updateServiceResource(newList);
        
        if(newList.isEmpty()) return;
        
        // Collect only Ids for async processing
        List<Id> saIds = new List<Id>();
        
        for(ServiceAppointment sa : [SELECT Id
                                       FROM ServiceAppointment 
                                      WHERE Id IN :newList 
                                        AND ParentRecord.RecordType.DeveloperName = 'MGL_R_T']){
            saIds.add(sa.Id);
        }
        if(!saIds.isEmpty()){
        	ServiceAppointmentAsyncHandler.updateServiceResourceFuture(saIds);    
        }
    }
    
    public static void afterUpdate(List<ServiceAppointment> newList,Map<Id,ServiceAppointment> oldMap){

         
        appointmentStatusUpdate(newList,oldMap);
    }
    
    public static void meteringAppointmentFieldMapping(List<ServiceAppointment> newList,Map<Id,ServiceAppointment> oldMap){
        Set<Id> setWorkOrderId=new Set<Id>();
        Set<Id> setAccountId=new Set<Id>();
        for(ServiceAppointment serAppointRec:newList){
            if(serAppointRec.ParentRecordId!=null && (oldMap==null || serAppointRec.ParentRecordId!=oldMap.get(serAppointRec.Id).ParentRecordId)){
                setWorkOrderId.add(serAppointRec.ParentRecordId);
                if(serAppointRec.AccountId!=null){
                    setAccountId.add(serAppointRec.AccountId);
                }
            }
        }
        
        Map<Id,Contact> mapAccIdVSContactRec=new Map<Id,Contact>();
        for(Contact contRec:[SELECT Id,AccountId FROM Contact WHERE AccountId IN:setAccountId]){
            mapAccIdVSContactRec.put(contRec.AccountId,contRec);
        }
        
        String gsRecordTypeID = Schema.getGlobalDescribe().get('WorkOrder')
            .getDescribe().getRecordTypeInfosByDeveloperName().get('MGL_Metering').getRecordTypeId();
        
        Map<Id,WorkOrder> mapIdVSWorkOrderRec=new Map<Id,WorkOrder>(
            [SELECT Id,Assigned_Meter_Reader__c,Scheduled_Date__c,Work_Order_Type__c,AccountId,ContactId,
             	Account.BillingStreet,Account.BillingCity,Account.BillingState,Account.BillingPostalCode,Account.BillingCountry,StartDate,EndDate
             FROM WorkOrder WHERE Id IN:setWorkOrderId AND RecordTypeId=:gsRecordTypeID]);
        
        for(ServiceAppointment serAppointRec:newList){
            if(serAppointRec.ParentRecordId!=null && mapIdVSWorkOrderRec.containsKey(serAppointRec.ParentRecordId)
                && (oldMap==null || serAppointRec.ParentRecordId!=oldMap.get(serAppointRec.Id).ParentRecordId)){
                WorkOrder workOrderRec=mapIdVSWorkOrderRec.get(serAppointRec.ParentRecordId);
                serAppointRec.Assigned_Meter_Reader__c=workOrderRec.Assigned_Meter_Reader__c;
                // serAppointRec.SchedStartTime=serAppointRec.SchedStartTime==null?workOrderRec.Scheduled_Date__c:serAppointRec.SchedStartTime;
                // if(serAppointRec.SchedStartTime!=null){
                //     serAppointRec.SchedEndTime=serAppointRec.SchedStartTime.addHours(5);
                // }

                if (workOrderRec.StartDate != null) {
                    // Always assign 9:00 AM start time on the assigned date
                    Date startDate = workOrderRec.StartDate.date(); // Extract Date only
                    Date endDate = workOrderRec.EndDate!=null ? workOrderRec.EndDate.date():startDate; // Extract Date only
                    Time startTime = Time.newInstance(9, 0, 0, 0); // 9:00 AM
                    Time endTime = Time.newInstance(19, 30, 0, 0); // 7:30 PM

                    serAppointRec.SchedStartTime = DateTime.newInstance(startDate, startTime);
                    serAppointRec.SchedEndTime = DateTime.newInstance(endDate, endTime);
                }else if(workOrderRec.Scheduled_Date__c!=null){
                    Date startDate = workOrderRec.Scheduled_Date__c.date(); // Extract Date only
                    Time startTime = Time.newInstance(9, 0, 0, 0); // 9:00 AM
                    Time endTime = Time.newInstance(19, 30, 0, 0); // 7:30 PM

                    serAppointRec.SchedStartTime = DateTime.newInstance(startDate, startTime);
                    serAppointRec.SchedEndTime = DateTime.newInstance(startDate, endTime);
                }
                serAppointRec.Appointment_Type__c=workOrderRec.Work_Order_Type__c;
                if(mapAccIdVSContactRec.containsKey(serAppointRec.AccountId) && workOrderRec.ContactId==null){
                    serAppointRec.ContactId=mapAccIdVSContactRec.get(serAppointRec.AccountId).Id;
                }else{
                    serAppointRec.ContactId=workOrderRec.ContactId;
                }
                if(workOrderRec.AccountId!=null){
                    serAppointRec.Street=workOrderRec.Account.BillingStreet;
                    serAppointRec.City=workOrderRec.Account.BillingCity;
                    serAppointRec.State=workOrderRec.Account.BillingState;
                    serAppointRec.PostalCode=workOrderRec.Account.BillingPostalCode;
                    serAppointRec.Country=workOrderRec.Account.BillingCountry;
                }
            }
        }
    }
    
    public static void serviceResourceAssignment(List<ServiceAppointment> newList){
        List<AssignedResource> listNewAssignResource=new List<AssignedResource>();
        for(ServiceAppointment servAppointRec:newList){
            if(servAppointRec.Assigned_Meter_Reader__c!=null){
                AssignedResource assignRes=new AssignedResource();
                assignRes.ServiceAppointmentId=servAppointRec.Id;
                assignRes.ServiceResourceId=servAppointRec.Assigned_Meter_Reader__c;
                System.debug('assignRes.ServiceResourceId::'+assignRes.ServiceResourceId);
                listNewAssignResource.add(assignRes);
            }
        }
        
        if(!listNewAssignResource.isEmpty()){
            INSERT listNewAssignResource;
        }
    }
    
    public static void appointmentStatusUpdate(List<ServiceAppointment> newList, Map<Id,ServiceAppointment> oldMap){
        String gsRecordTypeID = Schema.getGlobalDescribe().get('WorkOrder').getDescribe().getRecordTypeInfosByDeveloperName().get('MGL_Metering').getRecordTypeId();

        Map<String,String> mapStatusValue=new Map<String,String>();
        for (Metering_Dashboard_Config__mdt meta : [
                SELECT Label__c, Field_API_Name__c, Values__c, Order__c,Card_Color__c,Icon_URL__c
                FROM Metering_Dashboard_Config__mdt
                WHERE Active__c = true AND Department__c='Metering' AND DeveloperName!='Metering_Ad_hoc_Label'
                ORDER BY Order__c ASC]
        ) {
            List<String> values = meta.Values__c != null ? new List<String>(meta.Values__c.split(',')) : new List<String>();
            for (String val : values) {
                if(!mapStatusValue.containsKey(val)){
                    mapStatusValue.put(val,meta.Label__c);
                }
            }
        }

        Set<Id> setWorkOrderId=new Set<Id>();
        for(ServiceAppointment serAppointRec:newList){
            if(serAppointRec.Status!=null && serAppointRec.ParentRecordId!=null && (oldMap==null || serAppointRec.Status!=oldMap.get(serAppointRec.Id).Status)){
                setWorkOrderId.add(serAppointRec.ParentRecordId);
            }
        }

        Map<Id,WorkOrder> mapWorkOrderRec=new Map<Id,WorkOrder>([SELECT Id,Appointment_Status__c FROM WorkOrder WHERE Id IN:setWorkOrderId AND RecordTypeId=:gsRecordTypeID]);
        
        List<WorkOrder> listWorkOrderUpdate=new List<WorkOrder>();
        for(ServiceAppointment serAppointRec:newList){
            if(serAppointRec.Status!=null && serAppointRec.ParentRecordId!=null && (oldMap==null || serAppointRec.Status!=oldMap.get(serAppointRec.Id).Status)){
                if(mapStatusValue.containsKey(serAppointRec.Status) && mapWorkOrderRec.containsKey(serAppointRec.ParentRecordId)){
                    WorkOrder workOrderRec=mapWorkOrderRec.get(serAppointRec.ParentRecordId);
                    workOrderRec.Appointment_Status__c=mapStatusValue.get(serAppointRec.Status);
                    listWorkOrderUpdate.add(workOrderRec);
                }
            }
        }
        
        if(listWorkOrderUpdate.size()>0){
            update listWorkOrderUpdate;
        }
    }

    public static void updateServiceAppointment(List<ServiceAppointment> newList){
        Map<String, String> mapWoIdToSaId = new Map<String, String>();
        Map<String, WorkOrder> mapWorkOrder = new Map<String, WorkOrder>();
        List<AssignedResource> lstAssignedResourceToCreate = new List<AssignedResource>();

        for(ServiceAppointment sA : newList){
            if(sA.ParentRecordId != null){
                mapWoIdToSaId.put(sA.ParentRecordId, sA.Id);
            }
        }

        for(WorkOrder wo : [SELECT Id, StartDate, EndDate, Due_Amount__c
                              FROM WorkOrder 
                             WHERE Id IN :mapWoIdToSaId.keySet() 
                               AND Agent__c != null 
                               AND R_T_Agency__c != null
                               AND StartDate  != null 
                               AND EndDate != null
                               AND RecordType.DeveloperName = 'MGL_R_T']){
            mapWorkOrder.put(wo.Id, wo);
        }

        for(ServiceAppointment sA : newList){
            if(sA.ParentRecordId != null && mapWorkOrder.containsKey(sA.ParentRecordId)){                
                sA.SchedStartTime = DateTime.newInstance(
	                mapWorkOrder.get(sA.ParentRecordId).StartDate.date(), 
    	            Time.newInstance(9, 0, 0, 0) // 9:00 AM
        	    );
                sA.SchedEndTime = DateTime.newInstance(
                    mapWorkOrder.get(sA.ParentRecordId).EndDate.date(), 
                    Time.newInstance(20, 0, 0, 0) // 8:00 PM
                );
                sA.Status = 'In Progress';
                sA.Due_Amount__c = mapWorkOrder.get(sA.ParentRecordId).Due_Amount__c;
            }
        }
    }
    
    /*------------------------------Added by shruthi--------------------------*/
    // Method to update the WorkOrder's ServiceTerritoryId based on newly inserted ServiceAppointments
    // private static final String TARGET_RECORD_TYPE = 'MGL_R_T';
    // public static void mapWorkOrderDatesToAppointments(List<ServiceAppointment> newAppointments) {
    //     Set<Id> workOrderIds = new Set<Id>();
    //     Set<Id> accountIds = new Set<Id>();
        
    //     // Collect WorkOrder Ids (ParentRecordId) from ServiceAppointments
    //     for (ServiceAppointment sa : newAppointments) {
    //         if (sa.ParentRecordId != null && String.valueOf(sa.ParentRecordId).startsWith('0WO')) {
    //             workOrderIds.add(sa.ParentRecordId);
    //         }
    //     }
        
    //     if (workOrderIds.isEmpty()) return;
    //     // Query WorkOrders for Scheduled_Date__c and RecordType.DeveloperName
    //     Map<Id, WorkOrder> woMap = new Map<Id, WorkOrder>([
    //         SELECT Id, Scheduled_Date__c, RecordType.DeveloperName, AccountId,StartDate,EndDate,OwnerId,Due_Amount__c
    //         FROM WorkOrder
    //         WHERE Id IN :workOrderIds
    //     ]);
        
    //     // Step 3: Collect AccountIds
    //     for (WorkOrder wo : woMap.values()) {
    //         if (wo.AccountId != null) {
    //             accountIds.add(wo.AccountId);
    //         }
    //     }
        
    //     // Step 4: Query Accounts with related Contacts (LIMIT 1 per account)
    //     Map<Id, Contact> accountToContactMap = new Map<Id, Contact>();
    //     for (Account acc : [
    //         SELECT Id, (SELECT Id, LastName, Phone FROM Contacts LIMIT 1)
    //         FROM Account
    //         WHERE Id IN :accountIds
    //     ]) {
    //         if (!acc.Contacts.isEmpty()) {
    //             accountToContactMap.put(acc.Id, acc.Contacts[0]);
    //         }
    //     }
        
    //     // Map SchedStartTime and SchedEndTime only if RecordType is MGL_R_T
    //     for (ServiceAppointment sa : newAppointments) {
    //         if (sa.ParentRecordId != null && woMap.containsKey(sa.ParentRecordId)) {
    //             WorkOrder wo = woMap.get(sa.ParentRecordId);
    //             if (wo.RecordType.DeveloperName == TARGET_RECORD_TYPE) {
    //                 sa.SchedStartTime = wo.StartDate;
    //                 sa.SchedEndTime   = wo.EndDate;
    //                 sa.Due_Amount__c = wo.Due_Amount__c;
    //                 sa.OwnerId=wo.OwnerId;
                    
    //                 // Attach Contact from related Account
    //                 if (wo.AccountId != null && accountToContactMap.containsKey(wo.AccountId)) {
    //                     sa.ContactId = accountToContactMap.get(wo.AccountId).Id;
    //                 }
    //             }
    //         }
    //     }
    // }

}