/**
 * @description       :
 * @author            : Kartik Patkar Appstrail
 * @group             :
 * @last modified on  : 21-01-2026
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   17-06-2025   Kartik Patkar, Appstrail   Initial Version
 **/
public without sharing class MRSMeterReadingController {
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getAccountInfoFromSA(Id workOrderId,Boolean refreshTrigger) {
        System.debug('Start: getAccountInfoFromWO called with Work Order Id: ' + workOrderId);
        
        try {
            if (workOrderId == null) {
                throw new AuraHandledException('Work Order Id is null');
            }
            
            WorkOrder wo = [ SELECT Id, AccountId, Account.Name, Account.Phone,Appointment_Status__c,
                    Turbine_Meter_Reading__c,Pressure__c,Corrected_Volume__c,Uncorrected_Volume__c,
                    Correction_Factor__c,Temperature__c,Meter_Image_Remark__c
                FROM WorkOrder
                WHERE Id = :workOrderId
                LIMIT 1
            ];
            
            if (wo.AccountId == null) {
                System.debug('wo.AccountId : '+wo.AccountId);
                throw new AuraHandledException('No Account associated with this Work Order.');
            }
            
            Account acc = [
                SELECT Id, Name, Phone, Secondary_Telephone__c, Account_Email__c,
                       Account_Type__c,MRU_Code__c,BP_Number__c, CA_Number__c,
                       Meter_Number__c,Plot__c,Customer_Contact_no__c,
                       Building_name__c, Street__c, Colony__c, Wing__c,Geolocation__c,
                       Floor__c, Flat__c, Road_name__c,Society_Name__c,Location__c,City__c,Postal_Code__c
                FROM Account
                WHERE Id = :wo.AccountId
                LIMIT 1
            ];
            
            List<Document_Master__c> documentMasters = [
                SELECT Id, Document_Name__c,Type__c,Order__c,Compress_Image__c
                FROM Document_Master__c
                WHERE Active__c = true AND Type__c='MRS Start Metering' ORDER BY Order__c ASC
            ];
            
            List<PhotoWrapper> listImages=new List<PhotoWrapper>();
            for(Document_Master__c docMaster:documentMasters){
                PhotoWrapper photoWrapper=new PhotoWrapper();
                photoWrapper.label=docMaster.Document_Name__c;
                photoWrapper.id=docMaster.Id;
                photoWrapper.name=docMaster.Document_Name__c;
                photoWrapper.uploaded=false;
                photoWrapper.previewUrl='';
                photoWrapper.fileName='';
                photoWrapper.compress=docMaster.Compress_Image__c;
                listImages.add(photoWrapper);
            }

            List<Metering_GEO_Fence_Config__mdt> geoFenceConfig=[SELECT Id,For_CNG__c,For_CNG_Distance_in_Meter__c,For_Domestic__c,
                                                                For_Domestic_Distance_in_Meter__c,For_MRS__c,
                                                                For_MRS_Distance_in_Meter__c,For_Non_MRS_Distance_in_Meter__c
                                                            FROM Metering_GEO_Fence_Config__mdt 
                                                            WHERE Active__c=true LIMIT 1];
            
            return new Map<String, Object>{
                'acc' => acc,
                'listImages' => listImages,
                'workOrder' => wo,
                'geoFenceConfig' => geoFenceConfig.isEmpty() ? null : geoFenceConfig[0]
            };
            
        } catch (Exception ex) {
            System.debug('Exception caught: ' + ex.getMessage());
            System.debug('Exception Line Number: '+ex.getLineNumber());
            System.debug('Exception Stack Trace: '+ex.getStackTraceString());
            throw new AuraHandledException('Apex error: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String, Object> getGeoFenceData(Id workOrderId) {
        System.debug('Start: getAccountInfoFromWO called with Work Order Id: ' + workOrderId);
        
        try {
            if (workOrderId == null) {
                throw new AuraHandledException('Work Order Id is null');
            }

            WorkOrder wo = [ SELECT Id, AccountId, Account.Name, Account.Phone,Appointment_Status__c,
                    Turbine_Meter_Reading__c,Pressure__c,Corrected_Volume__c,Uncorrected_Volume__c,
                    Correction_Factor__c,Temperature__c,Meter_Image_Remark__c
                FROM WorkOrder
                WHERE Id = :workOrderId
                LIMIT 1
            ];
            
            if (wo.AccountId == null) {
                System.debug('wo.AccountId : '+wo.AccountId);
                throw new AuraHandledException('No Account associated with this Work Order.');
            }
            
            Account acc = [
                SELECT Id, Name, Phone, Secondary_Telephone__c, Account_Email__c,
                       Account_Type__c,MRU_Code__c,BP_Number__c, CA_Number__c,
                       Meter_Number__c,Plot__c,Customer_Contact_no__c,
                       Building_name__c, Street__c, Colony__c, Wing__c,Geolocation__c,
                       Floor__c, Flat__c, Road_name__c,Society_Name__c,Location__c,City__c,Postal_Code__c
                FROM Account
                WHERE Id = :wo.AccountId
                LIMIT 1
            ];

            List<Metering_GEO_Fence_Config__mdt> geoFenceConfig=[SELECT Id,For_CNG__c,For_CNG_Distance_in_Meter__c,For_Domestic__c,
                                                                For_Domestic_Distance_in_Meter__c,For_MRS__c,
                                                                For_MRS_Distance_in_Meter__c,For_Non_MRS_Distance_in_Meter__c
                                                            FROM Metering_GEO_Fence_Config__mdt 
                                                            WHERE Active__c=true LIMIT 1];
            
            return new Map<String, Object>{
                'acc' => acc,
                'geoFenceConfig' => geoFenceConfig.isEmpty() ? null : geoFenceConfig[0]
            };
            
        } catch (Exception ex) {
            System.debug('Exception caught: ' + ex.getMessage());
            System.debug('Exception Line Number: '+ex.getLineNumber());
            System.debug('Exception Stack Trace: '+ex.getStackTraceString());
            throw new AuraHandledException('Apex error: ' + ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static string updateWorkOrder(DataWrapper dataRec,String recordId){
        try {
            WorkOrder workOrderRec=[SELECT Id FROM WorkOrder WHERE Id = :recordId];
            workOrderRec.Turbine_Meter_Reading__c=dataRec.turbineMeterReading;
            workOrderRec.Pressure__c=dataRec.pressure;
            workOrderRec.Temperature__c=dataRec.temperature;
            workOrderRec.Corrected_Volume__c=dataRec.correctedVolume;
            workOrderRec.Uncorrected_Volume__c=dataRec.uncorrectedVolume;
            workOrderRec.Correction_Factor__c=dataRec.correctionFactor;
            workOrderRec.Meter_Image_Remark__c=dataRec.meterImageRemark;
            workOrderRec.Check_Out__c=true;
            workOrderRec.Check_Out_Date_Time__c=System.now();
            workOrderRec.Check_Out_Location__Latitude__s=dataRec.latitude;
            workOrderRec.Check_Out_Location__Longitude__s=dataRec.longitude;    
            workOrderRec.Approval_Status__c='Submitted For Approval';
            workOrderRec.Appointment_Status__c='Completed';
            update workOrderRec;

            List<ServiceAppointment> listServiceAppointments=[SELECT Id FROM ServiceAppointment WHERE ParentRecordId=:recordId];

            if(listServiceAppointments.size()==0){
                return 'No Service Appointment found for this Work Order';
            }
            ServiceAppointment serAppoinment = new ServiceAppointment();
            serAppoinment.Id=listServiceAppointments[0].Id;
            serAppoinment.Status='Completed';
            // serAppoinment.Check_Out_Timestamp__c=System.now();
            // serAppoinment.Check_Out_Location__latitude__s = dataRec.latitude;
            // serAppoinment.Check_Out_Location__longitude__s = dataRec.longitude;
            update serAppoinment;

            Set<Id> setContentDocIds=new Set<Id>();
            // List<ContentDocumentLink> listContentDocumentLinks = [SELECT Id, LatestPublishedVersionId FROM ContentDocumentLink WHERE LinkedEntityId = :recordId];
            for(ContentDocumentLink contentDocumentLink:[SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :recordId]){
                setContentDocIds.add(contentDocumentLink.ContentDocumentId);
            }
            
            List<ContentDocument> listContentDocuments = [SELECT Id FROM ContentDocument WHERE Id IN :setContentDocIds];
            if(listContentDocuments.size()>0){
                delete listContentDocuments;
            }

            List<Document__c> listDocuments = [SELECT Id, Name FROM Document__c WHERE Work_Order__c=:recordId];
            if(listDocuments.size()>0){
                delete listDocuments;
            }

            updateWorkStepsStatus(recordId, System.label.Start_Metering_Step_Name,'Completed');
            return 'success';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static void updateWorkStepsStatus(Id workOrderId,String name,String status){
        List<WorkStep> steps = [
			SELECT Id, Status
			FROM WorkStep
			WHERE ParentRecordId = :workOrderId
			AND Name = :name
			LIMIT 1
		];
        
        if (!steps.isEmpty()) {
            WorkStep ws = steps[0];
            ws.Status = status; // Or whatever picklist value you use
            update ws;
        }
    }
    
    @AuraEnabled
    public static void saveImage(List<FileWrapper> listFiles,String recordId){
        try {
            
            WorkOrder workOrderRecord=[SELECT Id,AccountId,BP_Number__c,Meter_Reading_Doc_Number__c,
                                            WorkOrderNumber,Scheduled_Date__c,Account.AMR_Name__c
                                        FROM WorkOrder WHERE Id=:recordId];

            String fileName = DocumentHelper.generateDocumentKey(workOrderRecord.Meter_Reading_Doc_Number__c,
                    workOrderRecord.BP_Number__c,workOrderRecord.Scheduled_Date__c,workOrderRecord.WorkOrderNumber);
            
            List<ContentVersion> contentVersions = new List<ContentVersion>();
            List<Document__c> listDocuments=new List<Document__c>();
            for (FileWrapper fw : listFiles) {
                ContentVersion cv = new ContentVersion();
                cv.Title = fw.label;
                cv.PathOnClient = fileName+'.jpg';
                cv.VersionData = EncodingUtil.base64Decode(fw.base64Data);
                contentVersions.add(cv);
                
                Document__c docRec=new Document__c();
                docRec.File_Name__c=cv.PathOnClient;
                docRec.File_Type__c=fw.label;
                docRec.Work_Order__c=recordId;
                docRec.Type__c='Metering';
                docRec.BP_Number__c=workOrderRecord.BP_Number__c;
                listDocuments.add(docRec);
            }
            
            if(!contentVersions.isEmpty()){
                insert contentVersions;
                
                // Map ContentVersion Id to ContentDocumentId
                Map<Id, Id> versionToDocMap = new Map<Id, Id>();
                Map<String, Id> fileNameToDocMap = new Map<String, Id>();
                for (ContentVersion cv : [SELECT Id,Title,PathOnClient, ContentDocumentId FROM ContentVersion WHERE Id IN :contentVersions ORDER BY CreatedDate ASC]) {
                    versionToDocMap.put(cv.Id, cv.ContentDocumentId);
                    fileNameToDocMap.put(cv.Title,cv.ContentDocumentId);
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
                
                if(!listDocuments.isEmpty()){
                    insert listDocuments;
                    
                    for(Document__c doc:listDocuments){
                        links.add(new ContentDocumentLink(
                            ContentDocumentId = fileNameToDocMap.get(doc.File_Type__c),
                            LinkedEntityId = doc.Id,
                            ShareType = 'V', // View permission
                            Visibility = 'AllUsers'
                        ));
                    }
                }
                
                if(!links.isEmpty()){
                    insert links;
                }
            }
        } catch (Exception ex) {
            System.debug('❌ Exception: ' + ex.getMessage());
            throw new AuraHandledException('Error updating Service Appointment: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static string workOrderCheckIn(String workOrderId,Decimal latitude,Decimal longitude){
        try {
            List<WorkOrder> listWorkOrders=[SELECT Id FROM WorkOrder WHERE Id=:workOrderId AND Check_In__c=false];
            if(listWorkOrders.size()==0){
                return 'Already CheckIn';
            }
            WorkOrder workOrderRec=new WorkOrder();
            workOrderRec.Id=workOrderId;
            workOrderRec.Check_In__c=true;
            workOrderRec.Check_In_Date_Time__c=System.now();
            workOrderRec.Check_In_Location__Latitude__s=latitude;
            workOrderRec.Check_In_Location__Longitude__s=longitude;
            update workOrderRec;

            List<ServiceAppointment> listServiceAppointments=[SELECT Id FROM ServiceAppointment WHERE ParentRecordId=:workOrderId];

            if(listServiceAppointments.size()==0){
                return 'No Service Appointment found for this Work Order';
            }
            ServiceAppointment serAppoinment = new ServiceAppointment();
            serAppoinment.Id=listServiceAppointments[0].Id;
            serAppoinment.Status='In Progress';
            // serAppoinment.Check_In_Timestamp__c=System.now();
            // serAppoinment.Check_In_Location__latitude__s = latitude;
            // serAppoinment.Check_In_Location__longitude__s = longitude;
            update serAppoinment;

            return 'success';
                
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public class FileWrapper{
        @AuraEnabled public String base64Data{get;set;}
        @AuraEnabled public String fileName{get;set;}
        @AuraEnabled public String label{get;set;}
    }
    
    public class PhotoWrapper{
        @AuraEnabled public String id;
        @AuraEnabled public String index;
        @AuraEnabled public String label;
        @AuraEnabled public String name;
        @AuraEnabled public String fileName;
        @AuraEnabled public Boolean uploaded;
        @AuraEnabled public String previewUrl;
        @AuraEnabled public Boolean compress;
    }
    
    public class DataWrapper{
        @AuraEnabled public String turbineMeterReading{get;set;}
        @AuraEnabled public String pressure{get;set;}
        @AuraEnabled public String correctedPressure{get;set;}
        @AuraEnabled public String correctedVolume{get;set;}
        @AuraEnabled public String uncorrectedVolume{get;set;}
        @AuraEnabled public String correctionFactor{get;set;}
        @AuraEnabled public String temperature{get;set;}
        @AuraEnabled public String meterImageRemark{get;set;}
        @AuraEnabled public Decimal latitude{get; set;}
        @AuraEnabled public Decimal longitude{get; set;}
    }
}