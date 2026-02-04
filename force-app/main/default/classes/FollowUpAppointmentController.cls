/**
 * @description       : 
 * @author            : Shashank.shekhar@appstrail.com
 * @group             : 
 * @last modified on  : 07-27-2025
 * @last modified by  : Shashank.shekhar@appstrail.com
**/
public without sharing class FollowUpAppointmentController {
  
    @AuraEnabled
    public static FollowUpResponse createFollowUp(
        Id parentRecordId, 
        Datetime followUpDate, 
        String followUpRemarks, 
        String otherRemarks) {

        FollowUpResponse response = new FollowUpResponse();
        try {

            // Fetch Work Order directly
            WorkOrder oldWO = [
                SELECT Id, Subject, Description, AccountId, Account.Phone,
                    Agent__r.Name, R_T_Agency__r.Name, Status, Address, Due_Amount__c,
                    ServiceTerritoryId, WorkTypeId, RecordTypeId, Invoice__c, StartDate,
                    EndDate, Customer_CA_Number__c, WorkOrderNumber, Follow_up_Remarks__c,
                    Account.CA_Number__c, WorkOrder.Amount_Received__c, WorkOrder.Payment_Mode__c,
                    WorkOrder.Agency_Name_Formula__c, TodayDate__c, NOTDUE__c, B4DUE__c, X0_30__c,
                    X31_60__c, X61_90__c, X91_180__c, X181_365__c, X1_2YR__c, X2_3YR__c, GR3YR__c,
                    ServiceAppointmentCount__c,Check_In_Location__Latitude__s,Check_In_Location__Longitude__s,
                    New_Remark__c
                FROM WorkOrder
                WHERE Id = :parentRecordId
            ];

            //oldWO.Status = 'Completed';
            //oldWO.Appointment_Status__c = 'Completed';
            oldWO.New_Remark__c = followUpRemarks;
            //oldWO.Other_Follow_Up_Remark__c = otherRemarks;

            System.debug('Fetched old Work Order: ' + oldWO);

            // Fetch the most recent Service Appointment related to this Work Order
            List<ServiceAppointment> relatedSAs = [
                SELECT Id, ParentRecordId, SchedStartTime, SchedEndTime, Subject, Description,
                    Meter_Number__c, Customer_Address__c,Status, Appointment_Type__c, ContactId, 
                    Address, ServiceTerritoryId, WorkTypeId, Check_In_Location__latitude__s,
                    Check_In_Location__longitude__s
                FROM ServiceAppointment
                WHERE ParentRecordId = :oldWO.Id
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];

            if (relatedSAs.isEmpty()) {
                response.success = false;
                response.message = 'No related Service Appointments found for the Work Order.';
                return response;
            }else{
                ServiceAppointment sa = relatedSAs[0];

                sa.Status = 'Completed'; 
                sa.Appointment_Type__c = 'Completed';
                sa.FollowUpRemarks__c = followUpRemarks;
                sa.Other_Follow_Up_Remark__c = otherRemarks;
            }

            if (followUpDate != null) {

                oldWO.Status = 'Follow Up';
                oldWO.Appointment_Status__c = 'Follow Up';
                oldWO.Follow_up_Date__c = followUpDate.date();
                //oldWO.StartDate = followUpDate.date();
                //oldWO.EndDate = followUpDate.date();
                oldWO.Follow_up_Remarks__c = followUpRemarks;
                oldWO.Other_Follow_Up_Remark__c = otherRemarks;

                oldWO.Check_In_Location__Latitude__s = null;
                oldWO.Check_In_Location__Longitude__s = null;
                oldWO.Check_In_Date_Time__c = null;
                

                Decimal count = oldWO.ServiceAppointmentCount__c == null ? 0 : oldWO.ServiceAppointmentCount__c;
                oldWO.ServiceAppointmentCount__c = count + 1;

                update oldWO;

                ServiceAppointment oldSA = relatedSAs[0];
                oldSA.Status = 'Completed'; 
                oldSA.Appointment_Type__c = 'Completed';
                oldSA.Check_Out_Timestamp__c = Datetime.now();
                oldSA.Check_Out_Location__latitude__s = oldSA.Check_In_Location__latitude__s;
                oldSA.Check_Out_Location__longitude__s = oldSA.Check_In_Location__longitude__s;

                // Normalize start to a business-friendly hour (e.g., 9 AM)
                DateTime startDateTime = DateTime.newInstance(followUpDate.date(), Time.newInstance(6, 0, 0, 0));
                DateTime endDateTime   = DateTime.newInstance(followUpDate.date(), Time.newInstance(23, 59, 59, 0));

                oldSA.Follow_Up_Visit_Date__c = followUpDate.date();

                System.debug('==========followUpDate=>>>>>>>>>>>>>' + followUpDate);

                // Clone and insert new Service Appointment
                ServiceAppointment newSA = oldSA.clone(false, true, false, false);
                //newSA.ParentRecordId = newWO.Id;
                newSA.ParentRecordId = oldWO.Id;
                newSA.FollowUpRemarks__c = null;
                newSA.Other_Follow_Up_Remark__c = null;
                newSA.Follow_Up_Visit_Date__c = null;
                newSA.ServiceTerritoryId = oldSA.ServiceTerritoryId;
                newSA.WorkTypeId = oldSA.WorkTypeId;
                //newSA.Due_Amount__c = newWO.Due_Amount__c;
                newSA.Due_Amount__c = oldWO.Due_Amount__c;
                newSA.Appointment_Type__c = 'Follow Up';
                newSA.ContactId = oldSA.ContactId;
                newSA.Status = 'In Progress';
                //newSA.SchedStartTime = followUpDate;
                //newSA.SchedEndTime = followUpDate;

                insert newSA;

                // Copy Assigned Resources
                // Copy Assigned Resources without duplicates
                List<AssignedResource> oldARs = [
                    SELECT ServiceResourceId
                    FROM AssignedResource
                    WHERE ServiceAppointmentId = :oldSA.Id
                ];
                Set<Id> existingRes = new Set<Id>();
                for (AssignedResource arExisting : [
                    SELECT ServiceResourceId
                    FROM AssignedResource
                    WHERE ServiceAppointmentId = :newSA.Id
                ]) {
                    existingRes.add(arExisting.ServiceResourceId);
                }
                List<AssignedResource> toInsert = new List<AssignedResource>();
                for (AssignedResource ar : oldARs) {
                    if (!existingRes.contains(ar.ServiceResourceId)) {
                        toInsert.add(new AssignedResource(
                            ServiceAppointmentId = newSA.Id,
                            ServiceResourceId    = ar.ServiceResourceId
                        ));
                    }
                }
                //if (!toInsert.isEmpty()) insert toInsert;

                clearWorkStepStatus(oldWO.Id);
                response.message = 'Follow-up appointment created for ' + followUpDate.format() + '.';
            }else{

                oldWO.Status = 'Completed';
                oldWO.Appointment_Status__c = 'Completed';
                oldWO.Check_Out_Date_Time__c = Datetime.now();
                oldWO.Follow_up_Remarks__c = followUpRemarks;
                oldWO.Other_Follow_Up_Remark__c = otherRemarks;
                oldWO.Check_Out_Location__Latitude__s = oldWO.Check_In_Location__Latitude__s;
                oldWO.Check_Out_Location__Longitude__s = oldWO.Check_In_Location__Longitude__s;
                
                update oldWO;

                //updateWorkStepStatus(oldWO.Id, 'Follow Up Visit');
                updateWorkStepStatuses(oldWO.Id, new List<String>{
                    'Follow Up Visit', 
                    'Check Out', 
                    'Disconnection Activity',
                    'Disconnection Notice',
                    'Billing Distribution',
                    'Reconnection Activity',
                    'Payment Capture'
                });

                response.message = 'Work Order updated.';
            }

            update relatedSAs;
            
            response.success = true;

        } catch (Exception e) {
            AS_ErrorLogger.log('FollowUpAppointmentController', 'createFollowUp', e, ParentRecordId);
            response.success = false;
            response.message = 'Error creating follow-up: ' + e.getMessage();
        } 
        return response;
    }


    @AuraEnabled
    public static FollowUpResponse createFollowUpWithImages(
            String parentRecordId, 
            Datetime followUpDate,
            String followUpRemarks, 
            String otherRemark, 
            Boolean smsRequired,
            List<String> base64Images) {

        FollowUpResponse response = new FollowUpResponse();
        WorkOrder oldWO;

        try {
            
            if (String.isBlank(parentRecordId)) {
                response.success = false;
                response.message = 'Parent Work Order ID is missing.';
                return response;
            }

            oldWO = [
                SELECT Id, Subject, Description, AccountId, ContactId, Status, Address, Due_Amount__c,Customer_CA_Number__c,EndDate,StartDate,
                    ServiceTerritoryId, WorkTypeId, RecordTypeId, Invoice__c,Agent__r.Name, R_T_Agency__r.Name,Account.Phone, WorkOrderNumber,
                    Account.CA_Number__c, Follow_up_Remarks__c, WorkOrder.Amount_Received__c, WorkOrder.Payment_Mode__c, WorkOrder.Agency_Name_Formula__c,
                    NOTDUE__c, B4DUE__c, X0_30__c,X31_60__c, X61_90__c, X91_180__c, X181_365__c, X1_2YR__c, X2_3YR__c, GR3YR__c,
                ServiceAppointmentCount__c,
                    Check_In_Location__Latitude__s,Check_In_Location__Longitude__s,New_Remark__c
                FROM WorkOrder
                WHERE Id = :parentRecordId
                LIMIT 1
            ];
            
            //oldWO.Status = 'Completed';
            //oldWO.Appointment_Status__c = 'Completed';
            
            oldWO.New_Remark__c = followUpRemarks;
            // oldWO.Other_Follow_Up_Remark__c = otherRemark;
            
            
            List<ServiceAppointment> relatedSAs = [
                SELECT Id, ParentRecordId, SchedStartTime, SchedEndTime, Subject, Description,
                    Meter_Number__c, Customer_Address__c, Status, Appointment_Type__c, ContactId,
                    Address, ServiceTerritoryId, WorkTypeId, Check_In_Location__latitude__s,
                    Check_In_Location__longitude__s
                FROM ServiceAppointment
                WHERE ParentRecordId = :oldWO.Id
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];

            if (relatedSAs.isEmpty()) {
                response.success = false;
                response.message = 'No related Service Appointments found for the Work Order.';
                return response;
            }else{
                ServiceAppointment sa = relatedSAs[0];

                sa.Status = 'Completed'; 
                sa.Appointment_Type__c = 'Completed';
                sa.FollowUpRemarks__c = followUpRemarks;
                sa.Other_Follow_Up_Remark__c = otherRemark;
            }

            if (followUpDate != null) {

                oldWO.Status = 'Follow Up';
                oldWO.Appointment_Status__c = 'Follow Up';
                oldWO.Follow_up_Date__c = followUpDate.date();
                //oldWO.StartDate = followUpDate.date();
                //oldWO.EndDate = followUpDate.date();

                oldWO.Follow_up_Remarks__c = followUpRemarks;
                oldWO.Other_Follow_Up_Remark__c = otherRemark;

                oldWO.Check_In_Location__Latitude__s = null;
                oldWO.Check_In_Location__Longitude__s = null;
                oldWO.Check_In_Date_Time__c = null;


                Decimal count = oldWO.ServiceAppointmentCount__c == null ? 0 : oldWO.ServiceAppointmentCount__c;
                oldWO.ServiceAppointmentCount__c = count + 1;

                update oldWO;
                

                ServiceAppointment oldSA = relatedSAs[0];
                oldSA.Status = 'Completed'; 
                oldSA.Appointment_Type__c = 'Completed';
                oldSA.Check_Out_Timestamp__c = Datetime.now();
                oldSA.Check_Out_Location__latitude__s = oldSA.Check_In_Location__latitude__s;
                oldSA.Check_Out_Location__longitude__s = oldSA.Check_In_Location__longitude__s;

                //DateTime startDateTime = DateTime.newInstance(followUpDate, Time.newInstance(09, 0, 0, 0));
                DateTime startDateTime = followUpDate;
                DateTime endDateTime = DateTime.newInstance(followUpDate.date(), Time.newInstance(23, 59, 0, 0));

                oldSA.Follow_Up_Visit_Date__c = followUpDate.date();

                ServiceAppointment newSA = oldSA.clone(false, true, false, false);
                //newSA.ParentRecordId = newWO.Id;
                newSA.ParentRecordId = oldWO.Id;
                newSA.FollowUpRemarks__c = null;
                newSA.Other_Follow_Up_Remark__c = null;
                newSA.Follow_Up_Visit_Date__c = null;
                newSA.ServiceTerritoryId = oldSA.ServiceTerritoryId;
                newSA.WorkTypeId = oldSA.WorkTypeId;
                //newSA.Due_Amount__c = newWO.Due_Amount__c;
                newSA.Due_Amount__c = oldWO.Due_Amount__c;
                newSA.Appointment_Type__c = 'Follow Up';
                newSA.ContactId = oldSA.ContactId;
                newSA.Status = 'In Progress';
                //newSA.SchedStartTime = startDateTime;
                //newSA.SchedEndTime = endDateTime;

                insert newSA;
                System.debug('Inserted new Service Appointment: ' + newSA.Id);

                // 🔁 Assign resources *before* status update
                List<AssignedResource> oldARs = [
                    SELECT ServiceResourceId FROM AssignedResource
                    WHERE ServiceAppointmentId = :oldSA.Id
                ];

                Set<Id> existingRes = new Set<Id>();
                for (AssignedResource arExisting : [
                    SELECT ServiceResourceId
                    FROM AssignedResource
                    WHERE ServiceAppointmentId = :newSA.Id
                ]) {
                    existingRes.add(arExisting.ServiceResourceId);
                }

                List<AssignedResource> newARs = new List<AssignedResource>();
                for (AssignedResource ar : oldARs) {
                    if (!existingRes.contains(ar.ServiceResourceId)) {
                        newARs.add(new AssignedResource(
                            ServiceAppointmentId = newSA.Id,
                            ServiceResourceId    = ar.ServiceResourceId
                        ));
                    }
                }
                //insert newARs;  

                clearWorkStepStatus(oldWO.Id);  
                response.message = 'Follow-up appointment created for ' + followUpDate.format() + '.';
            }else{

                oldWO.Status = 'Completed';
                oldWO.Appointment_Status__c = 'Completed';
                oldWO.Check_Out_Date_Time__c = Datetime.now();
                oldWO.Follow_up_Remarks__c = followUpRemarks;
                oldWO.Other_Follow_Up_Remark__c = otherRemark;
                oldWO.Check_Out_Location__Latitude__s = oldWO.Check_In_Location__Latitude__s;
                oldWO.Check_Out_Location__Longitude__s = oldWO.Check_In_Location__Longitude__s;
                
                update oldWO;

                //updateWorkStepStatus(oldWO.Id, 'Follow Up Visit');
                updateWorkStepStatuses(oldWO.Id, new List<String>{
                    'Follow Up Visit', 
                    'Check Out', 
                    'Disconnection Activity',
                    'Disconnection Notice',
                    'Billing Distribution',
                    'Reconnection Activity',
                    'Payment Capture'
                });

                response.message = 'Work Order updated.';
            }

            if (base64Images != null && !base64Images.isEmpty()) {    
                saveImage(base64Images, oldWO.Id, relatedSAs[0].Id);
            } else {
                System.debug('No images to save.');
            }

            update relatedSAs;
            
            response.success = true;

        } catch (Exception e) {
            AS_ErrorLogger.log('FollowUpAppointmentController', 'createFollowUpWithImages', e, parentRecordId);
            response.success = false;
            response.message = 'Error: ' + e.getMessage();
        }

        return response;
    }


    @AuraEnabled
    public static WorkOrder getWorkOrderDetail(String recId) {
        return [SELECT Id, Check_In_Date_Time__c, Status, Check_Out_Date_Time__c, Follow_up_Date__c, Payment_Remark__c
                  FROM WorkOrder
                 WHERE Id =: recId];
    }

    @AuraEnabled
    public static List<Map<String, String>> getPicklistValues(String objectName, String fieldName) {

        List<Map<String, String>> result = new List<Map<String, String>>();
        

        List<String> picklistValues = new List<String>();
        Schema.SObjectType sobjectType = Schema.getGlobalDescribe().get(objectName);

        if (sobjectType != null) {
            Schema.DescribeSObjectResult sobjectDescribe = sobjectType.getDescribe();
            Schema.SObjectField field = sobjectDescribe.fields.getMap().get(fieldName);

            if (field != null) {
                Schema.DescribeFieldResult fieldResult = field.getDescribe();
                if (fieldResult.getType() == Schema.DisplayType.PICKLIST) {
                    List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();
                    for (Schema.PicklistEntry picklistEntry : picklistEntries) {

                        Map<String, String> mapPicklistValues = new Map<String, String>();
                        
                        mapPicklistValues.put('label', picklistEntry.getLabel());
                        mapPicklistValues.put('value', picklistEntry.getValue());

                        result.add(mapPicklistValues);
                    }
                }
            }
        }
        return result;
    }

    public static void saveImage(List<String> base64Images, String woRecId, String saRecId) {
        try {
            List<ContentVersion> contentVersions = new List<ContentVersion>();
            Integer index = 1;
            for (String base64 : base64Images) {
                ContentVersion cv = new ContentVersion();
                cv.Title = 'FollowUp_Image_' + index;
                cv.PathOnClient = 'Door Image' + index + '.jpg';
                cv.VersionData = EncodingUtil.base64Decode(base64);
                contentVersions.add(cv);
                index++;
            }
            insert contentVersions;
            String firstImageTitle = contentVersions.isEmpty() ? null : contentVersions[0].Title;


            // Step 4: Map ContentVersion Ids to ContentDocumentIds
            Map<Id, Id> versionToDocMap = new Map<Id, Id>();
            for (ContentVersion cv : [
                SELECT Id, ContentDocumentId
                FROM ContentVersion
                WHERE Id IN :contentVersions
            ]) {
                versionToDocMap.put(cv.Id, cv.ContentDocumentId);
            }
            
            // Step 7: Link ContentDocuments to Document__c
            List<ContentDocumentLink> links = new List<ContentDocumentLink>();
            for (Id versionId : versionToDocMap.keySet()) {
                links.add(new ContentDocumentLink(
                    ContentDocumentId = versionToDocMap.get(versionId),
                    LinkedEntityId = woRecId,
                    ShareType = 'V',
                    Visibility = 'AllUsers'
                ));
                links.add(new ContentDocumentLink(
                    ContentDocumentId = versionToDocMap.get(versionId),
                    LinkedEntityId = saRecId,
                    ShareType = 'V',
                    Visibility = 'AllUsers'
                ));
            }
            insert links;

        } catch (Exception ex) {
            AS_ErrorLogger.log('FollowUpAppointmentController', 'saveImage', ex, woRecId);
        }
    }

    public static void updateWorkStepStatus(Id workOrderId, String name) {
        List<WorkStep> steps = [
            SELECT Id FROM WorkStep
            WHERE ParentRecordId = :workOrderId AND Name = :name
            LIMIT 1
        ];
        if (!steps.isEmpty()) {
            steps[0].Status = 'Completed';
            update steps;
        }
    }

    public static void updateWorkStepStatuses(Id workOrderId, List<String> name) {
        List<WorkStep> steps = [SELECT Id FROM WorkStep
            WHERE ParentRecordId = :workOrderId AND Name IN :name];
        for (WorkStep ws : steps) {
            ws.Status = 'Completed';
        }
        update steps;
    }

    public static void clearWorkStepStatus(Id workOrderId) {
        List<WorkStep> steps = [SELECT Id FROM WorkStep
                                 WHERE ParentRecordId = :workOrderId];
        for (WorkStep ws : steps) {
            ws.Status = 'New';
        }
        update steps;
    }

    public class FileWrapper {
        @AuraEnabled public String fileName;
        @AuraEnabled public String base64Data;
        @AuraEnabled public String label;
    }

    public class FollowUpResponse {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
    }

    //For Domestic customer
    @AuraEnabled(cacheable=true)
    public static List<Go_Collect_Follow_Up__mdt> getFollowUpReasonsFromMetadata() {
        return [SELECT Label, Image_Required__c, Image_Optional__c, Image_Count__c, SMS_requried__c, Follow_Up_Required__c FROM Go_Collect_Follow_Up__mdt];
    }

    //For Field Sense customer
    @AuraEnabled(cacheable=true)
    public static List<Field_Sense_Follow_Up__mdt> getFieldSenseFollowUpReasonsFromMetadata() {
        return [SELECT Label, Image_Required__c, Image_Optional__c, Image_Count__c, SMS_required__c, Follow_Up_Required__c FROM Field_Sense_Follow_Up__mdt];
    }

    @AuraEnabled
    public static void updateGeoLocation(String workOrderId, Double latitude, Double longitude){
        
        try {
            List<sObject> lstObjToUpdate = new List<sObject>();

            ServiceAppointment serApp = [SELECT Id, Check_In_Timestamp__c, 
                                                Check_Out_Timestamp__c, ParentRecordId 
                                           FROM ServiceAppointment 
                                          WHERE ParentRecordId = :workOrderId
                                       ORDER BY CreatedDate DESC
                                          LIMIT 1];
            
            WorkOrder wO = new WorkOrder(Id = serApp.ParentRecordId);
            
            wO.Check_In_Date_Time__c = Datetime.now();
            wO.Check_In_Location__Latitude__s = latitude;
            wO.Check_In_Location__Longitude__s = longitude;
            lstObjToUpdate.add(wO);
            
            if (serApp != null) {
                serApp.Check_In_Timestamp__c = Datetime.now();
                serApp.Check_In_Location__Latitude__s = latitude;
                serApp.Check_In_Location__Longitude__s = longitude;
                serApp.Status='In Progress';
                
                lstObjToUpdate.add(serApp);
            }
            
            update lstObjToUpdate;
        }
        catch(Exception e) {
            AS_ErrorLogger.log('FollowUpAppointmentController', 'updateGeoLocation', e, workOrderId);
        }
    }
}