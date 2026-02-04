/**
 * @description       :
 * @author            : Kartik Patkar Appstrail
 * @group             :
 * @last modified on  : 30-01-2026
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   03-07-2025   Kartik Patkar, Appstrail   Initial Version
 **/
public without sharing class WorkOrderBulkApprovalController {
    
    // Static variable to pass jobKey to trigger context
    public static String currentJobKey;
    
    @AuraEnabled
    public static string updateWorkOrder(List<String> workOrderList, String approvalStatus){
        try {
            if(!workOrderList.isEmpty()){
                System.debug(LoggingLevel.WARN, '[WO Progress] updateWorkOrder start. workOrders=' + workOrderList.size() + ', approvalStatus=' + approvalStatus);
                List<WorkOrder> updateWorkOrderList=[SELECT Id,Approval_Status__c,Approvar_Date__c,Approvar_User__c,Send_Email__c,
                                                        Approval_Date_Time__c 
                                                    FROM WorkOrder WHERE Id IN:workOrderList];
                for(WorkOrder workOrderRec:updateWorkOrderList){
                    workOrderRec.Approval_Status__c='Pending';
                    if(approvalStatus=='Approved'){
                        workOrderRec.Approvar_Date__c=system.today();
                        workOrderRec.Approval_Date_Time__c=system.now();
                        workOrderRec.Approvar_User__c=UserInfo.getUserId();
                        workOrderRec.Send_Email__c=false;
                    }
                }

                // Enable bypass
                Metering_Bypass_Validation__c bs = Metering_Bypass_Validation__c.getInstance(UserInfo.getUserId());
                if (bs == null) {
                    bs = new Metering_Bypass_Validation__c();
                    bs.SetupOwnerId = UserInfo.getUserId();
                }
                bs.Bypass__c = true;
                upsert bs;
                
                // Initialize job tracking and store in static variable for trigger access
                String jobKey = initializeJobTracking(workOrderList);
                currentJobKey = jobKey;
                System.debug(LoggingLevel.WARN, '[WO Progress] Generated jobKey=' + jobKey + ' and set currentJobKey');

                // Initialize cache with starting status (so LWC polling has data immediately)
                updateJobStatus(jobKey, 'Initializing...', 0, 4);

                update updateWorkOrderList;

                for(WorkOrder workOrderRec:updateWorkOrderList){
                    workOrderRec.Approval_Status__c=approvalStatus;
                }

                upsert updateWorkOrderList;

                // Disable bypass
                bs.Bypass__c = false;
                upsert bs;
                
                // Clear static variable after trigger execution
                currentJobKey = null;
                System.debug(LoggingLevel.WARN, '[WO Progress] Cleared currentJobKey for jobKey=' + jobKey);
                
                return jobKey;
            }
            return 'error';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static string sendEmail(List<String> workOrderList){
        try {
            List<WorkOrder> updateWorkOrderList=[SELECT Id,Approval_Status__c,Approvar_Date__c,Approvar_User__c,Send_Email__c,
                                                        Approval_Date_Time__c 
                                                    FROM WorkOrder WHERE Id IN:workOrderList
                                                        AND Approval_Status__c='Approved'];
            if(!updateWorkOrderList.isEmpty()){
                List<Id> setWOIds=new List<Id>();
                for(WorkOrder workOrderRec:updateWorkOrderList){
                    workOrderRec.Send_Email__c=false;
                    setWOIds.add(workOrderRec.Id);
                }
                
                // Enable bypass
                Metering_Bypass_Validation__c bs = Metering_Bypass_Validation__c.getInstance(UserInfo.getUserId());
                if (bs == null) {
                    bs = new Metering_Bypass_Validation__c();
                    bs.SetupOwnerId = UserInfo.getUserId();
                }
                bs.Bypass__c = true;
                upsert bs;

                update updateWorkOrderList;

                // Disable bypass
                bs.Bypass__c = false;
                upsert bs;
                
                Database.executeBatch(new WO_UpdateSendEmail_Batch(setWOIds), 40);
                return 'success';
            }
            return 'error';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static DataWrapper getCreatedSchedule(String memberId){
        try {
            List<ServiceTerritoryMember> agentMemberList=[SELECT Id,ServiceResourceId,ServiceTerritoryId,ServiceTerritory.Name
                                                            FROM ServiceTerritoryMember
                                                            WHERE Id=:memberId LIMIT 1];
            
            if(!agentMemberList.isEmpty()){
                DataWrapper dataWrapper=new DataWrapper();
                dataWrapper.agentId=agentMemberList[0].ServiceResourceId;
                dataWrapper.agencyId=agentMemberList[0].ServiceTerritoryId;
                dataWrapper.agencyName=agentMemberList[0].ServiceTerritory.Name;
                List<Meter_Reading_Schedule__c> listMRS=[SELECT Id,Meter_Reading_Start_Date__c,Meter_Reading_Completion_Date__c 
                                                            FROM Meter_Reading_Schedule__c 
                                                            WHERE Agent__c=:dataWrapper.agentId
                                                            ORDER BY Meter_Reading_Completion_Date__c DESC
                                                            LIMIT 1];
                
                if(!listMRS.isEmpty()){
                    dataWrapper.startDate=listMRS[0].Meter_Reading_Start_Date__c;
                    dataWrapper.endDate=listMRS[0].Meter_Reading_Completion_Date__c;
                    if(listMRS[0].Meter_Reading_Completion_Date__c!=null){
                        dataWrapper.fromDate=listMRS[0].Meter_Reading_Completion_Date__c.addDays(1);
                    }
                }
                return dataWrapper;
            }
            return null;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static string updateWorkOrdersAgent(List<WorkOrder> workOrderList, String agentId, String agencyId,
    Date startDate,Date endDate,String mrsId,Boolean newSchedule){
        try {
            List<ServiceTerritoryMember> listMember=[SELECT Id,ServiceResourceId,ServiceTerritoryId FROM ServiceTerritoryMember 
                                                    WHERE Id=:agentId LIMIT 1];
            if(!workOrderList.isEmpty() && !listMember.isEmpty()){
                
                Meter_Reading_Schedule__c mrs=new Meter_Reading_Schedule__c();
                if(newSchedule){
                    mrs.Agent__c=listMember[0].ServiceResourceId;
                    mrs.Agency__c=listMember[0].ServiceTerritoryId;
                    mrs.Meter_Reading_Start_Date__c=startDate;
                    mrs.Meter_Reading_Completion_Date__c=endDate;
                    mrs.No_of_Customer__c=workOrderList.size();
                    mrs.Status__c='Pending';
                    insert mrs;
                }else{
                    mrs=[SELECT Id,Meter_Reading_Start_Date__c,Meter_Reading_Completion_Date__c,No_of_Customer__c 
                        FROM Meter_Reading_Schedule__c WHERE Id=:mrsId LIMIT 1];
                    mrs.No_of_Customer__c+=workOrderList.size();
                    mrs.Status__c='Pending';
                    update mrs;
                }
                for(WorkOrder workOrder:workOrderList){
                    workOrder.Assigned_Meter_Reader__c=listMember[0].ServiceResourceId;
                    workOrder.Metering_Agency__c=agencyId;
                    workOrder.Meter_Reading_Schedule__c=mrs.Id;
                    workOrder.StartDate=mrs.Meter_Reading_Start_Date__c;
                    workOrder.EndDate=mrs.Meter_Reading_Completion_Date__c;
                    workOrder.Scheduled_Date__c=mrs.Meter_Reading_Start_Date__c;
                }

                // Enable bypass
                Metering_Bypass_Validation__c bs = Metering_Bypass_Validation__c.getInstance(UserInfo.getUserId());
                if (bs == null) {
                    bs = new Metering_Bypass_Validation__c();
                    bs.SetupOwnerId = UserInfo.getUserId();
                }
                bs.Bypass__c = true;
                upsert bs;

                update workOrderList;

                mrs.Status__c='Approved';
                update mrs;

                // Disable bypass
                bs.Bypass__c = false;
                upsert bs;
                return 'success';
            }
            return 'error';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage()+'-Line:'+e.getLineNumber());
        }
    }
    
    @AuraEnabled
    public static String initializeJobTracking(List<String> workOrderList){
        String jobKey = 'WO_ASYNC_' + UserInfo.getUserId() + '_' + System.now().getTime();
        // Don't publish initial event here - let the first Queueable do it
        return jobKey;
    }
    
    @AuraEnabled
    public static JobStatus getJobStatus(String jobKey){
        try {
            if (String.isBlank(jobKey)) {
                System.debug('[WO Progress] jobKey is null or empty');
                return null;
            }
            
            // Use MeteringCNG Platform Cache partition
            Cache.OrgPartition cachePart = Cache.Org.getPartition('local.MeteringCNG');
            
            // Sanitize jobKey to alphanumeric only (remove underscores)
            String cacheKey = jobKey.replaceAll('[^a-zA-Z0-9]', '');
            System.debug('[WO Progress] Retrieving cache with jobKey=' + jobKey + ', sanitized cacheKey=' + cacheKey);
            
            // Retrieve as JSON string from cache
            String statusJson = (String) cachePart.get(cacheKey);
            System.debug('[WO Progress] Retrieved JSON from cache: ' + statusJson);
            
            if (String.isNotBlank(statusJson)) {
                Map<String, Object> statusMap = (Map<String, Object>) JSON.deserializeUntyped(statusJson);
                JobStatus status = new JobStatus(
                    (String) statusMap.get('stepName'),
                    Integer.valueOf(statusMap.get('currentStep')),
                    Integer.valueOf(statusMap.get('totalSteps')),
                    DateTime.now()
                );
                System.debug('[WO Progress] Retrieved from cache for ' + jobKey + ': ' + status.stepName);
                return status;
            }
            
            System.debug('[WO Progress] No cache entry found for jobKey: ' + jobKey + ', cacheKey: ' + cacheKey);
            return null;
        } catch (Exception e) {
            System.debug('[WO Progress] Error getting job status: ' + e.getMessage() + ' | jobKey=' + jobKey + ' | Stack: ' + e.getStackTraceString());
            return null;
        }
    }
    
    public static void updateJobStatus(String jobKey, String stepName, Integer currentStep, Integer totalSteps){
        try {
            if (String.isBlank(jobKey)) {
                System.debug('[WO Progress] Cannot update status - jobKey is null or empty');
                return;
            }
            
            // Use MeteringCNG Platform Cache partition
            Cache.OrgPartition cachePart = Cache.Org.getPartition('local.MeteringCNG');
            
            // Store as JSON string in cache (most reliable)
            Map<String, Object> statusMap = new Map<String, Object>{
                'stepName' => stepName,
                'currentStep' => currentStep,
                'totalSteps' => totalSteps,
                'isComplete' => currentStep >= totalSteps
            };
            String statusJson = JSON.serialize(statusMap);
            
            // Sanitize jobKey to alphanumeric only (remove underscores)
            String cacheKey = jobKey.replaceAll('[^a-zA-Z0-9]', '');
            System.debug('[WO Progress] Storing cache with jobKey=' + jobKey + ', sanitized cacheKey=' + cacheKey + ', step=' + stepName);
            System.debug('[WO Progress] Storing JSON: ' + statusJson);
            
            // TTL: 600 seconds (10 minutes) - enough for job completion
            cachePart.put(cacheKey, statusJson, 600);
            System.debug('[WO Progress] Successfully cached job status for ' + jobKey + ': ' + stepName + ' (' + currentStep + '/' + totalSteps + ')');
        } catch (Exception e) {
            System.debug('[WO Progress] Error updating job status: ' + e.getMessage() + ' | jobKey=' + jobKey + ' | step=' + stepName + ' | Stack: ' + e.getStackTraceString());
        }
    }
    
    public class JobStatus{
        @AuraEnabled public String stepName;
        @AuraEnabled public Integer currentStep;
        @AuraEnabled public Integer totalSteps;
        @AuraEnabled public DateTime lastUpdated;
        @AuraEnabled public Boolean isComplete;
        
        public JobStatus(String stepName, Integer currentStep, Integer totalSteps, DateTime lastUpdated){
            this.stepName = stepName;
            this.currentStep = currentStep;
            this.totalSteps = totalSteps;
            this.lastUpdated = lastUpdated;
            this.isComplete = currentStep >= totalSteps;
        }
    }
    
    public class DataWrapper{
        @AuraEnabled public Date startDate{get;set;}
        @AuraEnabled public Date endDate{get;set;}
        @AuraEnabled public Date fromDate{get;set;}
        @AuraEnabled public Meter_Reading_Schedule__c mrsRec{get;set;}
        @AuraEnabled public String agentId{get;set;}
        @AuraEnabled public String agencyId{get;set;}
        @AuraEnabled public String agencyName{get;set;}
        
        public DataWrapper(){
            this.mrsRec=new Meter_Reading_Schedule__c();
        }
        
        public DataWrapper(Meter_Reading_Schedule__c mrsRec){
            this.startDate=mrsRec.Meter_Reading_Start_Date__c;
            this.endDate=mrsRec.Meter_Reading_Completion_Date__c;
            this.fromDate=mrsRec.Meter_Reading_Completion_Date__c.addDays(1);
            this.mrsRec=mrsRec;
            
        }
    }
    
    /**
     * @description
     * @author Kartik Patkar, Appstrail | 07-10-2025
     * @param List<WorkOrder> newList
     * @param Map<Id WorkOrder> oldMap
     **/
    public static void reassignServiceAppointment(List<WorkOrder> newList, Map<Id, WorkOrder> oldMap){
        
        String gsRecordTypeID = Schema.getGlobalDescribe().get('WorkOrder').getDescribe().getRecordTypeInfosByDeveloperName().get('MGL_Metering').getRecordTypeId();
        Set<Id> setWorkOrderIds=new Set<Id>();
        for(WorkOrder wo:newList){
            if(wo.RecordTypeId==gsRecordTypeID && (oldMap==null
            || oldMap.get(wo.Id).Assigned_Meter_Reader__c!=wo.Assigned_Meter_Reader__c)){
                setWorkOrderIds.add(wo.Id);
            }
        }
        
        if(!setWorkOrderIds.isEmpty()){
            Map<Id,ServiceAppointment> mapWorkOrderIdVSServiceAppointment=new Map<Id,ServiceAppointment>();
            for(ServiceAppointment sa:[SELECT Id,ServiceTerritoryId,ParentRecordId,
                                            (SELECT Id FROM ServiceResources) 
                                        FROM ServiceAppointment 
                                        WHERE ParentRecordId IN :setWorkOrderIds]){
                
                if(!mapWorkOrderIdVSServiceAppointment.containsKey(sa.ParentRecordId)){
                    mapWorkOrderIdVSServiceAppointment.put(sa.ParentRecordId,sa);
                }
            }
            
            if(!mapWorkOrderIdVSServiceAppointment.isEmpty()){
                List<AssignedResource> listAssignedResources=new List<AssignedResource>();
                List<AssignedResource> deleteList=new List<AssignedResource>();
                for(WorkOrder wo:newList){
                    if(mapWorkOrderIdVSServiceAppointment.containsKey(wo.Id)){
                        ServiceAppointment sa=mapWorkOrderIdVSServiceAppointment.get(wo.Id);
                        if(wo.Assigned_Meter_Reader__c!=null){
                            AssignedResource assignRes=new AssignedResource();
                            assignRes.ServiceAppointmentId=sa.Id;
                            assignRes.ServiceResourceId=wo.Assigned_Meter_Reader__c;
                            if(sa.ServiceResources.size()>0){
                                assignRes.Id=sa.ServiceResources[0].Id;
                            }
                            listAssignedResources.add(assignRes);
                        }else{
                            if(sa.ServiceResources.size()>0){
                                deleteList.add(sa.ServiceResources[0]);
                            }
                        }
                    }
                }
                
                if(deleteList.size()>0){
                    delete deleteList;
                }
                
                if(listAssignedResources.size()>0){
                    upsert listAssignedResources;
                }
            }
        }
    }
    
}