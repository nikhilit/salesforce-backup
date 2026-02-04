/**
 * @description       :
 * @author            : Shashank.shekhar@appstrail.com
 * @group             :
 * @last modified on  : 05-12-2025
 * @last modified by  : Kartik Patkar, Appstrail
 **/
public without sharing class WorkOrderAccountInfoController {
    
    @AuraEnabled
    public static Map<String, Object> getAccountInfoFromSA(Id workOrderId) {
        System.debug('Start: getAccountInfoFromWO called with Work Order Id: ' + workOrderId);
        
        try {
            if (workOrderId == null) {
                throw new AuraHandledException('Work Order Id is null');
            }
            
            WorkOrder wo = [
                SELECT Id, AccountId, Account.Name, Account.Phone,Appointment_Status__c,Group_Master__c,Group_Code__c,
                    Group_Message__c,Current_Meter_Reading__c,Final_Attempt__c,Meter_Serial_Number_Correct__c,
                    Meter_Serial_Number_Visible__c,Premise_Correct__c,Follow_Up_Remarks__c,Follow_Up_Appointment_Date__c,
                    Customer_Category__c,Remarks__c,Previous_Meter_Reading__c,Last_Meter_Reading_Date__c,Average_Consumption__c,
                    Meter_Reading__c,Landmark__c
                FROM WorkOrder
                WHERE Id = :workOrderId
                LIMIT 1
            ];
            
            if (wo.AccountId == null) {
                System.debug('wo.AccountId : '+wo.AccountId);
                throw new AuraHandledException('No Account associated with this Work Order.');
            }
            
            Account acc = [
                SELECT Id, Name, Phone, Secondary_Telephone__c, Account_Email__c,Customer_Contact_No_Office__c,
                    Account_Type__c,MRU_Code__c,BP_Number__c, CA_Number__c,Street_formula__c,
                    Meter_Number__c,Plot__c,Customer_Contact_no__c,Full_Name__c,Phone__c,Secondary_Phone__c,
                    Building_name__c, Street__c, Colony__c, Wing__c,Previous_Meter_Reading__c,Landmark__c,
                    Floor__c, Flat__c, Road_name__c,Society_Name__c,Location__c,City__c,Postal_Code__c
                FROM Account
                WHERE Id = :wo.AccountId
                LIMIT 1
            ];

            Metering_GEO_Fence_Config__mdt geoFenceConfig=[SELECT Id,For_CNG__c,For_CNG_Distance_in_Meter__c,For_Domestic__c,
                                                                For_Domestic_Distance_in_Meter__c,For_MRS__c,For_Non_MRS__c,
                                                                For_MRS_Distance_in_Meter__c,For_Non_MRS_Distance_in_Meter__c
                                                            FROM Metering_GEO_Fence_Config__mdt 
                                                            WHERE Active__c=true LIMIT 1];
            
            return new Map<String, Object>{
                'acc' => acc,
                'mglGasBurntMeterStatusOptions' => fieldPicklistValue('WorkOrder', 'MGL_gas_burnt_Meter_status__c'),
                'lpgSupplierOptions' => fieldPicklistValue('WorkOrder', 'LPG_Supplier__c'),
                'workOrder' => wo,
                'geoFenceConfig' => geoFenceConfig
            };
            
        } catch (Exception ex) {
            System.debug('Exception caught: ' + ex.getMessage());
            System.debug('Exception Line Number: '+ex.getLineNumber());
            System.debug('Exception Stack Trace: '+ex.getStackTraceString());
            throw new AuraHandledException('Apex error: ' + ex.getMessage());
        }
    }
    
    /**
     * @description
     *
     * @param objectName
     * @param fieldName
     * @return  `List<OptionsWrapper>`
     */
    public static List<OptionsWrapper> fieldPicklistValue(String objectName,String fieldName){
        List<OptionsWrapper> optionList=new List<OptionsWrapper>();
        Schema.SObjectType s = Schema.getGlobalDescribe().get(objectName) ;
        Schema.DescribeSObjectResult r = s.getDescribe();
        Map<String,Schema.SObjectField> fields = r.fields.getMap() ;
        Schema.DescribeFieldResult fieldResult = fields.get(fieldName).getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            OptionsWrapper option=new OptionsWrapper();
            option.label=pickListVal.getLabel();
            option.value=pickListVal.getValue();
            optionList.add(option);
        }
        return optionList;
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getGroupDataForTodayAppointments(String workOrderId) {
        
        System.debug('indide method getGroupDataForTodayAppointments:' +workOrderId);
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            // Debugging the input workOrderId
            System.debug('🔍 Work Order Id passed: ' + workOrderId);
            
            if (workOrderId == null) {
                throw new AuraHandledException('Work Order Id is null');
            }
            
            Date today = Date.today();
            Date startDate = today;
            Date endDate = today.addDays(1);
            
            // Debugging date range
            System.debug('📅 Date range: ' + startDate + ' to ' + endDate);
            
            List<ServiceAppointment> appointments = [
                SELECT Id
                FROM ServiceAppointment
                WHERE ParentRecordId = :workOrderId
                //AND SchedStartTime >= :startDate AND SchedStartTime < :endDate
            ];
            
            // Debugging the fetched appointments
            System.debug('📝 Fetched Appointments: ' + appointments);
            result.put('appointments', appointments);
            
            return result;
            
        } catch (Exception ex) {
            // Debugging the error
            System.debug('❌ Error: ' + ex.getMessage());
            throw new AuraHandledException('Apex error: ' + ex.getMessage());
        }
    }
    
    
    
    
    @AuraEnabled
    public static void updateServiceAppointment(
        String serviceAppointmentId,
    String groupMasterId,
    String groupCodeId,
    String groupMsgId,
    String workOrderId,
    Decimal currentMeterReading,
    Decimal amrReading,
    String additionalComment,
    String followUpRemarks,
    Boolean finalAttempt,
    Boolean premiseCorrect,
    Boolean meterSerialCorrect,
    Boolean meterSerialVisible,
    Date followUpDate,
    Decimal latitude,
    Decimal longitude,
    Boolean mglGasBurningPossible,
    String mglGasBurntMeterStatus,
    Boolean defaultGroupCode,
    Decimal sealReading,
    Boolean isSealInstalled,
    Boolean AMRDeviceInstalled,
    Boolean sealNumberVisible,
    Boolean amrReadingVisible,
    String lpgSupplierValue
    ) {
        
        if (String.isEmpty(serviceAppointmentId)) {
            throw new AuraHandledException('❌ Service Appointment ID is required.');
        }
        
        try {
            ServiceAppointment sa = [
                SELECT Id,ParentRecordId
                FROM ServiceAppointment 
                WHERE Id = :serviceAppointmentId
                LIMIT 1
            ];
            System.debug('✅ Found ServiceAppointment: ' + sa.Id);
            
            // Update fields
            //sa.Group_Details__c = groupDetailId;
            // sa.Group_Message__c = groupMsgId;
            //sa.Current_meter_reading__c = currentMeterReading;
            // sa.Follow_up_Remarks__c = followUpRemarks;
            // sa.Final_Attempt__c = finalAttempt;
            // sa.Additional_Comments__c = additionalComment;
            // sa.Visit_Status__c = 'Success';
            // sa.Permise_correcrt__c = premiseCorrect;
            // sa.Meter_Serail_Number_Correct__c = meterSerialCorrect;
            // sa.Serial_Number_Visible__c = meterSerialVisible;
            // sa.Status='Completed';
            if(finalAttempt || defaultGroupCode){
                sa.Status='Completed';
            }else{
                sa.Status='Cannot Complete';
            }
            update sa;
            
            WorkOrder workOrderRec=new WorkOrder();
            workOrderRec.Id=sa.ParentRecordId;
            workOrderRec.Group_Master__c=groupMasterId;
            workOrderRec.Group_Code__c=groupCodeId;
            workOrderRec.Group_Message__c=groupMsgId;
            workOrderRec.Remarks__c=additionalComment;
            workOrderRec.Final_Attempt__c=finalAttempt;
            workOrderRec.Meter_Reading__c=currentMeterReading;
            workOrderRec.AMR_Reading__c=amrReading;
            workOrderRec.Seal_Reading__c=sealReading;
            workOrderRec.Meter_Serial_Number_Visible__c=meterSerialVisible;
            workOrderRec.Meter_Serial_Number_Correct__c=meterSerialCorrect;
            workOrderRec.Premise_Correct__c=premiseCorrect;
            workOrderRec.Check_Out_Location__Latitude__s = latitude;
            workOrderRec.Check_Out_Location__Longitude__s = longitude;
            workOrderRec.Check_Out_Date_Time__c=System.now();
            workOrderRec.Check_Out__c=true;
            workOrderRec.Follow_Up_Appointment_Date__c = followUpDate;
            workOrderRec.Follow_up_Remarks__c = followUpRemarks;
            if(finalAttempt || defaultGroupCode){
                workOrderRec.Approval_Status__c='Submitted For Approval';
                workOrderRec.Appointment_Status__c='Completed';
            }else{
                workOrderRec.Appointment_Status__c='Incomplete';
            }
            // workOrderRec.Approval_Status__c='Submitted For Approval';
            // workOrderRec.Appointment_Status__c='Completed';
            workOrderRec.Gas_Burning_Possible__c=mglGasBurningPossible;
            workOrderRec.MGL_gas_burnt_Meter_status__c=mglGasBurntMeterStatus;
            workOrderRec.AMR_Device_Installed__c=amrDeviceInstalled;
            workOrderRec.Is_Seal_Installed__c=isSealInstalled;
            workOrderRec.Seal_Number_Visible__c=sealNumberVisible;
            workOrderRec.Is_AMR_Reading_Visible__c=amrReadingVisible;
            workOrderRec.LPG_Supplier__c=lpgSupplierValue;
            update workOrderRec;
            
            updateWorkStepStatus(sa.ParentRecordId, 'Start Metering');
            
            System.debug('✅ ServiceAppointment updated successfully');
        } catch (Exception ex) {
            System.debug('❌ Exception: ' + ex.getMessage());
            throw new AuraHandledException('Error updating Service Appointment: ' + ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static void saveImage(List<FileWrapper> listFiles,String serviceAppointmentId,Boolean defaultGroupCode,Account accRec,String workOrderId){
        try {
            ServiceAppointment sa = [
                SELECT Id,ParentRecordId,Work_Order__c,Work_Order__r.Group_Code__r.Default__c,
                    Work_Order__r.AccountId,Work_Order__r.BP_Number__c,Work_Order__r.Meter_Reading_Doc_Number__c,
                    Work_Order__r.WorkOrderNumber,Work_Order__r.Scheduled_Date__c
                FROM ServiceAppointment 
                WHERE Id = :serviceAppointmentId
                LIMIT 1
            ];
            
            WorkOrder wo = [SELECT Id,Meter_Reading_Doc_Number__c,WorkOrderNumber,Scheduled_Date__c,BP_Number__c 
                            FROM WorkOrder WHERE Id=:workOrderId LIMIT 1];
            
            String fileName = DocumentHelper.generateDocumentKey(wo.Meter_Reading_Doc_Number__c,wo.BP_Number__c,
            wo.Scheduled_Date__c, wo.WorkOrderNumber);
            
            List<ContentVersion> contentVersions = new List<ContentVersion>();
            List<Document__c> listDocuments=new List<Document__c>();
            List<Meter_Reading_OCR__c> listMeterReadingOCR = new List<Meter_Reading_OCR__c>();
            for (FileWrapper fw : listFiles) {
                ContentVersion cv = new ContentVersion();
                cv.Title = fw.label;
                cv.PathOnClient = fileName+'.jpg';
                cv.VersionData = EncodingUtil.base64Decode(fw.base64Data);
                contentVersions.add(cv);
                
                Document__c docRec=new Document__c();
                docRec.File_Name__c=fileName;
                docRec.Work_Order__c=workOrderId;
                docRec.Service_Appointment__c=serviceAppointmentId;
                docRec.Type__c=fw.label;
                docRec.BP_Number__c=accRec.BP_Number__c;
                listDocuments.add(docRec);
                
                if(fw.ocr){
                    Meter_Reading_OCR__c meterReadingOCR = new Meter_Reading_OCR__c(
                        Status__c = 'Draft',
                    Work_Order__c = workOrderId,
                    Business_Partner__c = accRec.Id,
                    BP_Number__c = accRec.BP_Number__c,
                    File_Name__c = fileName,
                    Type__c = fw.label
                        );
                    listMeterReadingOCR.add(meterReadingOCR);
                }
            }
            
            insert contentVersions;
            
            // Map ContentVersion Id to ContentDocumentId
            Map<Id, Id> versionToDocMap = new Map<Id, Id>();
            Map<String, Id> fileNameToDocMap = new Map<String, Id>();
            for (ContentVersion cv : [SELECT Id,Title,PathOnClient, ContentDocumentId FROM ContentVersion WHERE Id IN :contentVersions]) {
                versionToDocMap.put(cv.Id, cv.ContentDocumentId);
                fileNameToDocMap.put(cv.Title,cv.ContentDocumentId);
            }
            
            // Create ContentDocumentLinks to associate files with the given record
            List<ContentDocumentLink> links = new List<ContentDocumentLink>();
            for (Id versionId : versionToDocMap.keySet()) {
                links.add(new ContentDocumentLink(
                    ContentDocumentId = versionToDocMap.get(versionId),
                LinkedEntityId = workOrderId,
                ShareType = 'V', // View permission
                Visibility = 'AllUsers'
                    ));
            }
            
            if(!listDocuments.isEmpty()){
                insert listDocuments;
                
                for(Document__c doc:listDocuments){
                    links.add(new ContentDocumentLink(
                        ContentDocumentId = fileNameToDocMap.get(doc.Type__c),
                    LinkedEntityId = doc.Id,
                    ShareType = 'V', // View permission
                    Visibility = 'AllUsers'
                        ));
                }
            }
            
            if(!listMeterReadingOCR.isEmpty()){
                insert listMeterReadingOCR;
                
                for(Meter_Reading_OCR__c ocr:listMeterReadingOCR){
                    links.add(new ContentDocumentLink(
                        ContentDocumentId = fileNameToDocMap.get(ocr.Type__c),
                    LinkedEntityId = ocr.Id,
                    ShareType = 'V', // View permission
                    Visibility = 'AllUsers'
                        ));
                }
            }
            
            // Meter_Reading_OCR__c meterReadingOCR = new Meter_Reading_OCR__c();
            // if(defaultGroupCode){
                //     meterReadingOCR = new Meter_Reading_OCR__c(
                //         Status__c = 'Draft',
                //     Work_Order__c = workOrderId,
                //     Business_Partner__c = accRec.Id,
                //     BP_Number__c = accRec.BP_Number__c,
                //     File_Name__c = fileName
                //         );
                //     insert meterReadingOCR;
                
                //     for (Id versionId : versionToDocMap.keySet()) {
                    //         links.add(new ContentDocumentLink(
                    //             ContentDocumentId = versionToDocMap.get(versionId),
                    //         LinkedEntityId = meterReadingOCR.Id,
                    //         ShareType = 'V', // View permission
                    //         Visibility = 'AllUsers'
                    //             ));
                //     }
            // }
            
            insert links;
            
            if(!listDocuments.isEmpty()){
                for(Document__c doc:listDocuments){
                    doc.Upload_Status__c='Pending';
                }
                
                update listDocuments;
            }
            
            if(!listMeterReadingOCR.isEmpty()){
                for(Meter_Reading_OCR__c ocr:listMeterReadingOCR){
                    ocr.Status__c='Pending';
                }
                update listMeterReadingOCR;
            }
        } catch (Exception ex) {
            System.debug('❌ Exception: ' + ex.getMessage());
            throw new AuraHandledException('Error updating Service Appointment: ' + ex.getMessage()+'; Line number:'+ex.getLineNumber());
        }
    }
    
    public class FileWrapper{
        @AuraEnabled public String base64Data{get;set;}
        @AuraEnabled public String fileName{get;set;}
        @AuraEnabled public String label{get;set;}
        @AuraEnabled public Boolean ocr{get;set;}
        
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
    
    
    
    // Apex method to search for Group Details based on the search key
    // @AuraEnabled(cacheable=true)
    // public static List<Group_Details__c> searchGroupDetails(String searchKey) {
        //     if (String.isEmpty(searchKey)) {
            //         return [
            //                 SELECT Id, Name, No_of_Photos__c
            //                 FROM Group_Details__c
            //             ];
        //     }
        
        //     try {
            //         // Perform a case-insensitive search on the Name field of Group_Details__c
            //         List<Group_Details__c> groupDetails = [
            //                 SELECT Id, Name, No_of_Photos__c
            //                 FROM Group_Details__c
            //                 WHERE Name LIKE :('%' + searchKey + '%')
            //             ];
            //         return groupDetails;
        //     } catch (Exception ex) {
            //         throw new AuraHandledException('Apex error: ' + ex.getMessage());
        //     }
    // }
    
    // @AuraEnabled(cacheable=true)
    // // public static List<Group_Message__c> searchGroupMessage(String groupDetailId) {
        // //     if (String.isEmpty(groupDetailId)) {
            // //         return [
            // //                 SELECT Id, Name ,Description__c,No_of_Photos__c
            // //                 FROM Group_Message__c
            // //             ];
        // //     }
        
        // //     try {
            // //         // Perform a case-insensitive search on the Name field of Group_Details__c
            // //         List<Group_Message__c> groupDetails = [
            // //                 SELECT Id, Name ,Description__c,No_of_Photos__c
            // //                 FROM Group_Message__c
            // //                 WHERE Group_Details__c = :groupDetailId
            // //             ];
            // //         return groupDetails;
        // //     } catch (Exception ex) {
            // //         throw new AuraHandledException('Apex error: ' + ex.getMessage());
        // //     }
    // // }
    
    @AuraEnabled
    public static List<OptionsWrapper> getGroupMasterOptions(){
        try {
            List<OptionsWrapper> listGroupMasterOptions = new List<OptionsWrapper>();
            List<Group_Master__c> ListGroupMasters = [SELECT Id, Name,Default__c,Group_Code__c
                                                        FROM Group_Master__c
                                                        WHERE Active__c=true
                                                        ORDER BY Group_Code__c ASC];
            
            for (Group_Master__c groupMasterRec : ListGroupMasters) {
                OptionsWrapper groupWrapper = new OptionsWrapper();
                groupWrapper.label = groupMasterRec.Group_Code__c +' - '+ groupMasterRec.Name;
                groupWrapper.value = groupMasterRec.Id;
                groupWrapper.record = groupMasterRec;
                listGroupMasterOptions.add(groupWrapper);
            }
            return listGroupMasterOptions;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<OptionsWrapper> getGroupCodeOptions(String groupMasterId,String type,Boolean plausibleOption){
        try {
            String query='SELECT Id,Name,Description__c,Default__c,Show_Meter_Reading_Option__c,Code__c,Testing_Not_possible__c,Plausibility_Check_Options__c,'+
                'Testing_Possible_Default__c,Meter_not_working__c,Meter_working__c, '+
                '(SELECT Id,Document_Name__c,Order__c,Type__c,Compress_Image__c,OCR__c FROM Document_Masters__r '+
                'WHERE Active__c=TRUE AND Type__c=:type ORDER BY Order__c ASC) '+
                'FROM Group_Code__c WHERE Active__c=true AND Plausibility_Check_Options__c=:plausibleOption';
            
            if(!String.isBlank(groupMasterId)){
                query+=' AND Group_Master__c=:groupMasterId';
            }
            List<Group_Code__c> listGroupCodes = Database.query(query);
            
            List<OptionsWrapper> listGroupCodeOptions = new List<OptionsWrapper>();
            for(Group_Code__c groupCodeRec:listGroupCodes){
                OptionsWrapper groupWrapper = new OptionsWrapper();
                groupWrapper.label = groupCodeRec.Code__c+' - '+ groupCodeRec.Description__c;
                groupWrapper.value = groupCodeRec.Id;
                groupWrapper.record = groupCodeRec;
                groupWrapper.listDocumentWrapper = new List<DocumentWrapper>();
                if(groupCodeRec.Document_Masters__r!=null && groupCodeRec.Document_Masters__r.size()>0){
                    for(Document_Master__c docMaster:groupCodeRec.Document_Masters__r){
                        groupWrapper.listDocumentWrapper.add(new DocumentWrapper(docMaster));
                    }
                }
                listGroupCodeOptions.add(groupWrapper);
            }
            return listGroupCodeOptions;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String workOrderCheckIn(String workOrderId, String serviceAppointId, Decimal latitude, Decimal longitude) {
        try {
            // Prepare lists for bulk update
            List<WorkOrder> workOrdersToUpdate = new List<WorkOrder>();
            List<ServiceAppointment> appointmentsToUpdate = new List<ServiceAppointment>();
            
            // Query WorkOrder only if needed
            WorkOrder wo = [
                SELECT Id, Check_In__c 
                FROM WorkOrder 
                WHERE Id = :workOrderId 
                LIMIT 1
            ];
            
            if (wo.Check_In__c == true) {
                return 'Already Check-In done';
            }
            
            // Prepare WorkOrder update
            wo.Check_In__c = true;
            wo.Check_In_Date_Time__c = System.now();
            wo.Check_In_Location__Latitude__s = latitude;
            wo.Check_In_Location__Longitude__s = longitude;
            wo.Appointment_Status__c = 'Unattempted';
            workOrdersToUpdate.add(wo);
            
            // Prepare ServiceAppointment update
            ServiceAppointment sa = new ServiceAppointment(
                Id = serviceAppointId,
            Status = 'In Progress'
                );
            appointmentsToUpdate.add(sa);
            
            // Do both updates together
            if (!workOrdersToUpdate.isEmpty()) update workOrdersToUpdate;
            if (!appointmentsToUpdate.isEmpty()) update appointmentsToUpdate;
            
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
    public static List<OptionsWrapper> getGroupMessageOptions(String groupCodeId,Boolean plausibleOption,Boolean highConsumptions,Boolean lowConsumptions,Boolean forDomestic,Boolean forNonMRS){
        try {
            String query = 'SELECT Id,Name,Description__c,Show_Meter_Reading_Option__c,No_of_Photos__c ,Group_Message_Code__c,LPG_Supplier__c '+
                'FROM Group_Message__c WHERE Active__c=true AND Plausible_Options__c=:plausibleOption AND High_Consumption_Options__c=:highConsumptions AND Low_Consumption_Options__c=:lowConsumptions AND (For_Domestic__c=:forDomestic OR For_Non_MRS__c=:forNonMRS)';
            
            
            if(!String.isBlank(groupCodeId)){
                query+=' AND Group_Code__c=: groupCodeId';
            }
            List<Group_Message__c> listGroupMessages = Database.query(query);
            
            List<OptionsWrapper> listGroupMessageOptions = new List<OptionsWrapper>();
            for(Group_Message__c groupMessageRec:listGroupMessages){
                OptionsWrapper groupWrapper = new OptionsWrapper();
                groupWrapper.label = groupMessageRec.Description__c;
                groupWrapper.value = groupMessageRec.Id;
                groupWrapper.record = groupMessageRec;
                listGroupMessageOptions.add(groupWrapper);
            }
            return listGroupMessageOptions;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<WorkOrderWrapper> getNextWorkOrder(String workOrderId){
        List<WorkOrderWrapper> listWorkOrderWrappers = new List<WorkOrderWrapper>();
        List<WorkOrder> listWorkOrders = [SELECT Id,Building_Name_DMC__c,Assigned_Meter_Reader__c FROM WorkOrder WHERE Id=:workOrderId];
        if(!listWorkOrders.isEmpty()){
            String buildingName = listWorkOrders[0].Building_Name_DMC__c;
            Id meterReaderId = listWorkOrders[0].Assigned_Meter_Reader__c;
            String recordType = Schema.getGlobalDescribe().get('WorkOrder').getDescribe().getRecordTypeInfosByDeveloperName().get('MGL_Metering').getRecordTypeId();
            List<WorkOrder> listNextWorkOrders = [SELECT Id,Building_Name_DMC__c,Customer_Meter_Number__c,Account.Name,
                                                        Account.Building_name__c,Appointment_Status__c,Account.BP_Number__c,
                                                        Account.Location__c,Account.Plot__c,Account.Flat__c,Account.Floor__c,
                                                        Account.Wing__c 
                                                    FROM WorkOrder 
                                                    WHERE Building_Name_DMC__c=:buildingName 
                                                        AND Appointment_Status__c='Unattempted'
                                                        AND RecordTypeId=:recordType
                                                        AND Assigned_Meter_Reader__c=:meterReaderId
                                                        AND Id!=:workOrderId
                                                        AND Expired__c = false
                                                        AND Indirect_Reading_Received__c=false
                                                    ORDER BY Account.Building_name__c NULLS LAST,
                                                        Account.Floor__c NULLS LAST, 
                                                        Account.Flat__c NULLS LAST];
            if(!listNextWorkOrders.isEmpty()){
                // Set<Id> setAppointIds = new Set<Id>();
                // for(WorkOrder wo:listNextWorkOrders){
                //     setAppointIds.add(wo.Id);
                // }
                // Map<Id,ServiceAppointment> mapAppointIdVSServiceAppointment = new Map<Id,ServiceAppointment>();
                // List<ServiceAppointment> listAppointments = [SELECT Id,ParentRecordId FROM ServiceAppointment WHERE ParentRecordId IN :setAppointIds];
                
                // for(ServiceAppointment sa:listAppointments){
                //     mapAppointIdVSServiceAppointment.put(sa.ParentRecordId,sa);
                // }
                for(WorkOrder wo:listNextWorkOrders){
                    WorkOrderWrapper workOrderWrapper = new WorkOrderWrapper(wo);
                    // if(mapAppointIdVSServiceAppointment.containsKey(wo.Id)){
                    //     workOrderWrapper.appointId = mapAppointIdVSServiceAppointment.get(wo.Id).Id;
                    // }
                    listWorkOrderWrappers.add(workOrderWrapper);
                }
            }
        }
        return listWorkOrderWrappers;
    }
    
    public class WorkOrderWrapper {
        @AuraEnabled public Id id;
        @AuraEnabled public Id appointId;
        @AuraEnabled public String meterNumber;
        @AuraEnabled public String accountName;
        @AuraEnabled public String buildingName;
        @AuraEnabled public String buildingStreet;
        @AuraEnabled public String appointmentType;
        @AuraEnabled public String customerName;
        @AuraEnabled public String BPNumber;
        @AuraEnabled public String location;
        @AuraEnabled public String plot;
        @AuraEnabled public String flat;
        @AuraEnabled public String floor;
        @AuraEnabled public String wing;
        
        public WorkOrderWrapper(WorkOrder wo) {
            this.id = wo.Id;
            this.meterNumber = wo.Customer_Meter_Number__c;
            this.accountName = wo.Account.Name;
            this.buildingName = wo.Account.Building_name__c;
            this.appointmentType = wo.Appointment_Status__c;
            this.customerName = wo.Account.Name;
            this.BPNumber = wo.Account.BP_Number__c;
            this.location = wo.Account.Location__c;
            this.plot = wo.Account.Plot__c;
            this.flat = wo.Account.Flat__c;
            this.floor = wo.Account.Floor__c;
            this.wing = wo.Account.Wing__c;
        }
    }
    
    public class OptionsWrapper{
        @AuraEnabled public String label{get;set;}
        @AuraEnabled public String value{get;set;}
        @AuraEnabled public SObject record {get;set;}
        List<OptionsWrapper> listSubOptionsWrapper {get;set;}
        @AuraEnabled public List<DocumentWrapper> listDocumentWrapper {get;set;}
    }
    
    public class DocumentWrapper{
        @AuraEnabled public String previewUrl{get;set;}
        @AuraEnabled public String fileName{get;set;}
        @AuraEnabled public String id{get;set;}
        @AuraEnabled public String label{get;set;}
        @AuraEnabled public String name{get;set;}
        @AuraEnabled public Boolean uploaded{get;set;}
        @AuraEnabled public Decimal index{get;set;}
        @AuraEnabled public Boolean compress{get;set;}
        @AuraEnabled public Boolean ocr{get;set;}
        @AuraEnabled public String base64Data;
        
        public DocumentWrapper(){
            this.previewUrl = '';
            this.fileName = '';
            this.id = '';
            this.label = '';
            this.name = '';
            this.uploaded = false;
            this.index = null;
            this.compress = false;
            this.ocr = false;
        }
        
        public DocumentWrapper(Document_Master__c docMaster){
            this.index = docMaster.Order__c;
            this.label = docMaster.Document_Name__c;
            this.name = docMaster.Document_Name__c;
            this.id = docMaster.Id;
            this.fileName = '';
            this.previewUrl = '';
            this.uploaded = false;
            this.compress = docMaster.Compress_Image__c;
            this.ocr = docMaster.OCR__c;
        }
    }
    @AuraEnabled(cacheable=true)
    public static Map<String, Decimal> getAccountLocation(Id accountId) {
        // Prepare map to return
        Map<String, Decimal> locationMap = new Map<String, Decimal>{
            'Latitude' => null,
            'Longitude' => null
        };

        if(accountId == null) return locationMap;

        // Query the custom geolocation field
        Account acc = [
            SELECT Geolocation__c,Geolocation__Latitude__s,Geolocation__Longitude__s 
            FROM Account 
            WHERE Id = :accountId
            LIMIT 1
        ];

        if(acc != null && acc.Geolocation__c != null) {
            locationMap.put('Latitude', acc.Geolocation__Latitude__s);
            locationMap.put('Longitude', acc.Geolocation__Longitude__s);
        }

        return locationMap;
    }
    
}