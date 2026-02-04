/**
* @File Name : RubberHoseReplacementExecutionDetaContr.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : August 6, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | August 6, 2025 |   | Initial Version
**/

public without sharing class RubberHoseReplacementExecutionDetaContr {
    
    
    @AuraEnabled
    public static ServiceAppointment getCheckInStatus(string recordId) {
        
        try {
            
            
            ServiceAppointment sa = [
                SELECT Id, O_MCheckInTimestamp__c,O_MCheckOutTimestamp__c,Check_In_Lat_Long__c,Check_Out_Lat_Long__c	
                FROM ServiceAppointment
                WHERE Id = :recordId OR ParentRecordId =:recordId limit 1
                
            ];
            System.debug('checkin and out data::>>' + sa);
            return sa;
            
            
            
            
        } catch (Exception e) {
            //return null;
            throw new AuraHandledException('Error fetching appointment data: ' + e.getMessage());
            
            
        }
        
        
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Account> getAccountInfoFromSA(Id workOrderId) {
        System.debug('Start: getAccountInfoFromWO called with Work Order Id: ' + workOrderId);
        
        try {
            if (workOrderId == null) {
                throw new AuraHandledException('Work Order Id is null');
            }
            
            // WorkOrder wo = [
            //     SELECT Id, AccountId, Account.Name, Account.Phone
            //     FROM WorkOrder
            //     WHERE Id = :workOrderId
            //     LIMIT 1
            // ];
             List<WorkOrder> woList = [
            SELECT Id, AccountId, Account.Name, Account.Phone
            FROM WorkOrder
            WHERE Id = :workOrderId
            LIMIT 1
        ];

        if (woList.isEmpty()) {
            throw new AuraHandledException('No Work Order found with the provided Id.');
        }

        WorkOrder wo = woList[0];
            
            if (wo.AccountId == null) {
                System.debug('wo.AccountId : '+wo.AccountId);
                throw new AuraHandledException('No Account associated with this Work Order.');
            }
            
          List<Account> accList = [
                SELECT Id, Name, Phone, Secondary_Telephone__c, Account_Email__c,
                Account_Type__c,MRU_Code__c,BP_Number__c, CA_Number__c,
                Meter_Number__c,Plot__c,Customer_Contact_no__c,
                Building_name__c, Street__c, Colony__c, Wing__c,
                Floor__c, Flat__c, Road_name__c,Society_Name__c,Location__c,City__c,Postal_Code__c,
                RH_Due_Date__c
                FROM Account
                WHERE Id = :wo.AccountId
                LIMIT 1
            ];

            if (accList.isEmpty()) {
            throw new AuraHandledException('No Account found for the provided Work Order.');
            }

            Account acc = accList[0];
            
            return new Map<String, Account>{
                'acc' => acc
                    };
                        
                        } catch (Exception ex) {
                            System.debug('Exception caught: ' + ex.getMessage());
                            System.debug('Exception Line Number: '+ex.getLineNumber());
                            System.debug('Exception Stack Trace: '+ex.getStackTraceString());
                            throw new AuraHandledException('Apex error: ' + ex.getMessage());
                        }
    }
    
    
    
    @AuraEnabled
    public static String updateServiceAppoinment(String recordId, Double lat, Double lon,Boolean checkIn, DateTime currentDateTime) {
        System.debug('==== markCheckIn Called ====');
        System.debug('Appointment ID: ' + recordId);
        System.debug('Input Lat: ' + lat);
        System.debug('Input Lon: ' + lon);
        
        
        
        try {
            
            
            // Validate input
            if (recordId == null || lat == null || lon == null) {
                system.debug('inside missing value');
                return 'MISSING_VALUES';
            }
            
            String message = 'Success';
            
            
            
            // Fetch appointment
            ServiceAppointment sa = [
                SELECT Id,ParentRecordId, O_MCheckInTimestamp__c,O_MCheckOutTimestamp__c,Check_In_Lat_Long__c,
                Check_Out_Lat_Long__c,
                ServiceTerritoryId
                FROM ServiceAppointment WHERE Id = :recordId OR ParentRecordId = :recordId LIMIT 1
            ];
            
            
            WorkOrder wOrderUpd = [Select id,ServiceTerritoryId,Appointment_Status__c,Completion_Datetime__c from WorkOrder Where Id=: sa.ParentRecordId];
            
            system.debug('Work order ::'+ wOrderUpd);
            
            /* This is for calculated distance is customer in correct location or not but now no need 

           //Scheduled_Location__latitude__s, Scheduled_Location__longitude__s

// Calculate distance
Double distanceKm = calculateHaversineDistance(
(Double) sa.Scheduled_Location__latitude__s,
(Double) sa.Scheduled_Location__longitude__s,
lat,lon); 
System.debug('Distance (km): ' + distanceKm);
Double distanceMeters = distanceKm * 1000;
System.debug('Distance (meters): ' + distanceMeters);
Double allowedRadius = 1000.0;
System.debug('Scheduled Lat: ' + sa.Scheduled_Location__latitude__s);
System.debug('Scheduled Lon: ' + sa.Scheduled_Location__longitude__s);

if (distanceMeters > allowedRadius) {
system.debug('insdie too far location');
message = 'TOO_FAR_FROM_LOCATION';
return 'TOO_FAR_FROM_LOCATION';

}  */
            
            // Update check-in info
            // if(sa.Check_In_Lat_Long__c == null){
            
            system.debug('check in ::'+ checkIn);
            if(checkIn){
                system.debug('inside if');
                sa.O_MCheckInTimestamp__c=currentDateTime ;
                sa.Check_In_Lat_Long__latitude__s= lat;
                sa.Check_In_Lat_Long__longitude__s=lon;
                sa.Status='In Progress';
                // sa.ServiceTerritoryId = wOrderUpd.ServiceTerritoryId;
                
                //  wOrderUpd.Appointment_Status__c='In Progress';
                update wOrderUpd;
                
                message = 'Check In Successfully';
            }
            
            
            
            else if(checkIn==false) {
                system.debug('inside else if');
                sa.O_MCheckOutTimestamp__c= currentDateTime;
                sa.Check_Out_Lat_Long__latitude__s = lat;
                sa.Check_Out_Lat_Long__longitude__s=lon;
                sa.Status='Completed';
                // wOrderUpd.Appointment_Status__c='Completed';
                wOrderUpd.Completion_Datetime__c= System.now();
                
                
                update wOrderUpd;
                system.debug('update work order::'+wOrderUpd);
                
                message = 'Check Out Successfully';
                
            }
            
            update sa;
            // sa.Status='Completed';
            // update sa;
            system.debug('Service appointment ::'+ sa);
            // if(message=='Check In Successfully'){
            //     updateWorkStepStatus(sa.ParentRecordId,'Check-in');
            // }else if(message=='Check Out Successfully'){
            //     updateWorkStepStatus(sa.ParentRecordId,'Check-out');
            // }
            return message;
            // }
            
            // 			else {
            //     // Already checked in, optionally handle this scenario
            //     return 'ALREADY_CHECKED_IN';
            // }
            
            
            
        } catch (Exception e) {
            System.debug('Check-in Error: ' + e.getMessage() + e.getLineNumber());
            return e.getMessage();
        }
    }
    
    
    //       @AuraEnabled
    //     public static List<OptionsWrapper> fieldPicklistValue(String objectName,String fieldName){
    //     List<OptionsWrapper> optionList=new List<OptionsWrapper>();
    //     Schema.SObjectType s = Schema.getGlobalDescribe().get(objectName) ;
    //     Schema.DescribeSObjectResult r = s.getDescribe();
    //     Map<String,Schema.SObjectField> fields = r.fields.getMap() ;
    //     Schema.DescribeFieldResult fieldResult = fields.get(fieldName).getDescribe();
    //     List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    //     for( Schema.PicklistEntry pickListVal : ple){
    //         OptionsWrapper option=new OptionsWrapper();
    //         option.label=pickListVal.getLabel();
    //         option.value=pickListVal.getValue();
    //         optionList.add(option);
    //     }
    //     return optionList;
    // }
    
    // public class OptionsWrapper{
    //     @AuraEnabled public String label{get;set;}
    //     @AuraEnabled public String value{get;set;}
    // }
    
    
    @AuraEnabled
    public static void saveImage(List<FileWrapper> listFiles,String recordId,String reasonUnavailability, String otherRemarkValue,DateTime selectedDateTime){
        try {
            
            system.debug('Record id ::'+ recordId);
            system.debug('Reason  ::'+ reasonUnavailability);
            //  System.debug('listFiles::'+ listFiles);
            
            String childWOId='';
            
            List<WorkOrder> childWorkOrder = [Select Id,ParentWorkOrderId from workorder Where ParentWorkOrderId =:recordId];
            system.debug('childWorkOrder::'+ childWorkOrder);
            system.debug('childWorkOrder Size::'+ childWorkOrder.size());
            
            WorkOrder wOrder = [Select id,Reason_ForUnavilability__c,Reason_Other_Remark__c,WorkTypeId,
                                AccountId,OwnerId,Check_Customer_Availability__c
                                from WorkOrder where id =:recordId];
            
            
            wOrder.Reason_ForUnavilability__c=reasonUnavailability;
            wOrder.Reason_Other_Remark__c = otherRemarkValue;
            wOrder.Check_Customer_Availability__c='No';
            //  wOrder.RM_Closer_Remark__c =rMCloserRemark;  RM_Closer_Remark__c
            update wOrder;
            
            if(reasonUnavailability =='House locked' && selectedDateTime !=null && childWorkOrder.size() < 2){
                
                system.debug('inside premises locked and start date time not empty');
                
                Id woOMRecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('MGL O&M').getRecordTypeId();
                
                WorkOrder wo = new WorkOrder();
                
                wo.ParentWorkOrderId = recordId;
                wo.WorkTypeId = wOrder.WorkTypeId;
                wo.AccountId = wOrder.AccountId;
                wo.RecordTypeId = woOMRecordTypeId;
                wo.OwnerId = wOrder.OwnerId;
                
                insert wo;
                
                system.debug('Child Work order::'+ wo);
                
                childWOId = wo.Id;
                
                
                ServiceAppointment updChildServiApp = [Select id,SchedStartTime,SchedEndTime from ServiceAppointment Where ParentRecordId =:wo.Id];
                
                
                
                updChildServiApp.SchedStartTime=selectedDateTime;
                
                updChildServiApp.SchedEndTime = updChildServiApp.SchedStartTime.addDays(3);
                
                
                update updChildServiApp;
                
                
                
                
                
            }
            
            
            
            //  for (FileWrapper fw : listFiles) {
            //     ContentVersion cv = new ContentVersion();
            //     cv.Title = fw.label;
            //     cv.PathOnClient = fw.fileName +'.jpg';
            //     cv.VersionData = EncodingUtil.base64Decode(fw.base64Data);
            //     cv.OwnerId = userInfo.getUserId();
            //     cv.FirstPublishLocationId = recordId;
            //     cv.ContentLocation= 'S';
            
            //     insert cv;
            // }
            
            
            List<ContentVersion> contentVersions = new List<ContentVersion>();
            
            for (FileWrapper fw : listFiles) {
                ContentVersion cv = new ContentVersion();
                cv.Title = fw.label;
                cv.PathOnClient = fw.fileName +'.jpg';
                cv.VersionData = EncodingUtil.base64Decode(fw.base64Data);
                contentVersions.add(cv);
            }
            
            insert contentVersions;
            
            // Map ContentVersion Id to ContentDocumentId
            Map<Id, Id> versionToDocMap = new Map<Id, Id>();
            for (ContentVersion cv : [
                SELECT Id, ContentDocumentId 
                FROM ContentVersion 
                WHERE Id IN :contentVersions
            ]) {
                versionToDocMap.put(cv.Id, cv.ContentDocumentId);
            }
            
            // Create ContentDocumentLinks to associate files with the given record
            List<ContentDocumentLink> links = new List<ContentDocumentLink>();
            for (Id versionId : versionToDocMap.keySet()) {
                links.add(new ContentDocumentLink(
                    ContentDocumentId = versionToDocMap.get(versionId),
                    LinkedEntityId = recordId,
                    ShareType = 'V', // View permission
                    Visibility = 'AllUsers'
                ));
            }
            
            insert links;
            
            
            system.debug('Create child workorder id::'+ childWOId);
            
            
            
            //   ServiceAppointment updSerApp = [Select Id,ParentRecordId,SchedStartTime,SchedEndTime from ServiceAppointment Where ParentRecordId =:childWOId];
            
            
            // system.debug('update serviceappointment record::'+ updSerApp);
            // if(updSerApp !=null){
            
            //     updSerApp.SchedStartTime=selectedDateTime;
            
            //     if(selectedEndDateTime !=null){
            
            //             updSerApp.SchedEndTime = selectedEndDateTime;
            //     }
            //     else {
            
            //         updSerApp.SchedEndTime = updSerApp.SchedStartTime.addDays(3);
            //     }
            // }
            
            // update updSerApp;
            
            updateWorkStepStatus(recordId,'Rubber Hose Execution Details');
            
            
            
            
        } catch (Exception ex) {
            System.debug('❌ Exception: ' + ex.getMessage() + ' ' + ex.getLineNumber());
            throw new AuraHandledException('Error updating work order: ' + ex.getMessage());
            
        }
    }
    
    public class FileWrapper{
        @AuraEnabled public String base64Data{get;set;}
        @AuraEnabled public String fileName{get;set;}
        @AuraEnabled public String label{get;set;}
    }
    
    public static void updateWorkStepStatus(Id workOrderId,String name){
        List<WorkStep> steps = [
            SELECT Id, Status
            FROM WorkStep
            WHERE ParentRecordId = :workOrderId
            AND Name = :name
            LIMIT 1
        ];
        
        if (!steps.isEmpty()) {
            WorkStep ws = steps[0];
            ws.Status = 'Completed'; // Or whatever picklist value you use
            update ws;
        }
    }
    
}