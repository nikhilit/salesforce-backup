/**
* @File Name : CreateWOFromConnectionContr.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : August 17, 2025
* @Modification Log :
*==============================================================================||
* Ver | Date | Author | Modification
*==============================================================================||
* 1.0 | August 17, 2025 |   | Initial Version
**/

public without sharing class CreateWOFromConnectionContr {

    @AuraEnabled
     public static WorkOrder getLatestRiserMaintenanceWO(String recordId) {

        System.debug('connection record id::'+ recordId);
        try {
        WorkOrder wo = [
            SELECT Id, CreatedDate
            FROM WorkOrder
            WHERE Connection__c = :recordId
              AND WorkType.Name = 'Riser Maintenance'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        
        return wo; 
        }
        catch(Exception e){

            system.debug('Error ::'+ e.getLineNumber() + e.getMessage());

            return new WorkOrder();
        }
    }
    @AuraEnabled
    public static List<ServiceTerritory> getServiceTerritories(){
        
        try{
            
            // List<ServiceTerritory> lstServiceTerritory = [select id,name,Work_Type__r.name from ServiceTerritory
            //                                               where Work_Type__r.name='Riser Maintenance' OR Work_Type__r.name='Riser Replacement'
            //                                               OR Work_Type__r.name='Riser Painting'];

            List<ServiceTerritory> lstServiceTerritory = [select id,Name from ServiceTerritory Where Name='Jangid Engineering' OR Name='DG Enterprises'
            
                                                                OR Name='Sky Blue Infra Project' OR Name='MS Enterprises' OR Name='Shreeram Enterprises' 
                                                                OR Name='Shreeram Enterprises' OR Name='Marc Engineering' OR Name='Kohinoor Infra Project' 
                                                                OR Name='Preet Engineering' OR Name='Swaara Enterprises' OR Name='Deepa Enterprises' 
                                                                OR Name='Preet Engg Works' OR Name='Fixo Fit Well' OR Name='Dinesh Enterprises' Or Name='Aarti Enterprises'
                                                                OR Name='Shreeram Enterprises' OR Name='Chauhan Engineering' OR Name='Singh Services' 
                                                                OR Name='Sainvesta Enterprises'];
            
            return lstServiceTerritory;												  
        }
        catch(Exception e){
            
            system.debug('Error getting serviceterritory::'+ e.getLineNumber() + e.getMessage());
            
            return new List<ServiceTerritory>();
        }
    }
    
    @AuraEnabled
    public static string createWorkOrder(String recordId, String selectedActivity, DateTime selectedDateTime, String selectedTerritory, String supervisorName, String plumberName, String contractorWorkOrderNumber){
        system.debug('selectedDateTime==============>>>>>'+selectedDateTime);
        
        try {
            
            system.debug('selectedTerritory::'+ selectedTerritory);
            
            WorkType wType = [Select Id,Name from WorkType Where Name=: selectedActivity];
            
            Connection__c conneRecord = [Select id,Building_Name__c,Street__c,City__c,District__c,Postal_Code__c,
                                            Activity_Month__c,Activity_Year__c	 from Connection__c where id=: recordId];
            
            Id woRecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('MGL O&M').getRecordTypeId();
            
            WorkOrder wo = new WorkOrder();
            
            wo.WorkTypeId = wType.Id;
            wo.RecordTypeId = woRecordTypeId;
            wo.ServiceTerritoryId = selectedTerritory;
            wo.Plumber_Name__c	= plumberName;
           // wo.Contractor_Work_Order_Number__c = contractorWorkOrderNumber;
            wo.Connection__c=recordId;
            wo.Scheduled_Date__c = selectedDateTime;
            wo.Riser_Supervisor_Name__c = supervisorName;
           // wo.Building_Name__c = conneRecord.Building_Name__c;
          //  wo.Address_1__c = conneRecord.Street__c + ' ' + conneRecord.City__c + ' ' + conneRecord.District__c + ' ' + conneRecord.Postal_Code__c;
           //  wo.Maintenance_year__c =  (!String.isBlank(conneRecord.Activity_Month__c) && !String.isBlank(conneRecord.Activity_Year__c)) 
                            //              ? conneRecord.Activity_Month__c + ' ' + conneRecord.Activity_Year__c 
                                       //           : '';
            // wo.Move_indate__c = conneRecord.Move_InDate__c;
            
            insert wo;
            
            system.debug('After wo insert ::'+ wo);
            
            ServiceAppointment serApp = [select id,ParentRecordId,SchedStartTime,SchedEndTime,Status,CreatedById from ServiceAppointment where ParentRecordId =: wo.Id];
            system.debug('ServiceAppointment :::'+ serApp );
            system.debug('ServiceAppointment 1:::'+ serApp.SchedStartTime );
            serApp.SchedStartTime = selectedDateTime;
            system.debug('ServiceAppointment2 :::'+ serApp.SchedStartTime );
            serApp.SchedEndTime = serApp.SchedStartTime.addDays(3);
           // serApp.Status ='Dispatched';
            
                        update serApp;
            
            
            ServiceResource serResource = [select id,Name,RelatedRecordId  from ServiceResource where RelatedRecordId=:serApp.CreatedById];
            
            AssignedResource assResource = new AssignedResource();
            
            assResource.ServiceAppointmentId = serApp.Id;
            assResource.ServiceResourceId = serResource.Id;
            
            insert assResource;
            
            
            WorkOrder updateWO = [Select id,Agent__c from WorkOrder Where Id=: wo.Id];
            
            
            updateWO.Agent__c=serResource.Id;
            
            Update updateWO;
            
            
            // Connection__c connectionRecord = [Select id,Riser_Maintenance_WorkOrder_Created__c from Connection__c where id=: recordId];
            
            // connectionRecord.Riser_Maintenance_WorkOrder_Created__c = true;
            
            // update connectionRecord;
            // 

            serApp.Status ='Dispatched';
            
            update serApp;
            return wo.Id;
            
            
            
        }
        
        catch(Exception e){
            
            system.debug('error in createWorkOrder method ::'+ e.getLineNumber() + e.getMessage());
            
            return 'error';
        }
    }
}