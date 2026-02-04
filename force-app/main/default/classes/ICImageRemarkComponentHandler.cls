/**
     * @description       :
     * @author            : Shashank.shekhar@appstrail.com
     * @group             :
     * @last modified on  : 07-24-2025
     * @last modified by  : Shashank.shekhar@appstrail.com
     **/
    public without sharing class ICImageRemarkComponentHandler {

        @AuraEnabled
        public static Boolean checkAllocation(Id recordId) {
            try{
                Id currentUserId = UserInfo.getUserId();

                // Get Service Appointment linked to WorkOrder
                List<ServiceAppointment> saList = [
                    SELECT Id
                    FROM ServiceAppointment
                    WHERE ParentRecordId = :recordId
                    LIMIT 1
                ];

                // No Service Appointment found
                if (saList.isEmpty()) {
                    return null;
                }

                // Get Assigned Resource for Service Appointment
                List<AssignedResource> arList = [
                    SELECT ServiceResource.RelatedRecordId
                    FROM AssignedResource
                    WHERE ServiceAppointmentId = :saList[0].Id
                    LIMIT 1
                ];

                // No Assigned Resource found
                if (arList.isEmpty() || arList[0].ServiceResource == null) {
                    return null;
                }

                // Return true if assigned to current user
                if (arList[0].ServiceResource.RelatedRecordId == currentUserId) {
                    return true;
                }

                return false; // not assigned to current user
            }catch(Exception e){
                AS_ErrorLogger.log('ICImageRemarkComponentHandler', 'checkAllocation', e, recordId);
                return null;
            }
        }
 
        @AuraEnabled
        public static VisitDetail getServiceAppoinment(string recordId){
            try{
                ServiceAppointment serAppoinment;
                List<WorkOrder> lstWO = new List<WorkOrder>();
                List<ServiceAppointment> lstSerAppoinment = [SELECT ParentRecordId, Check_In_Timestamp__c, Check_Out_Timestamp__c, 
                                                       Check_In_Location__c, Check_Out_Location__c, Follow_Up_Visit_Date__c
                                                  FROM ServiceAppointment 
                                                 WHERE (Id = :recordId OR ParentRecordId=:recordId)
                                              ORDER BY CreatedDate DESC
                                                 LIMIT 1];
                if(!lstSerAppoinment.isEmpty()){
                    serAppoinment = lstSerAppoinment.get(0);
                    lstWO = [SELECT Check_In_Date_Time__c, Check_Out_Date_Time__c, Check_In_Location__c, 
                                Check_Out_Location__c, Follow_up_Date__c, Status, Amount_Received__c,
                                Payment_Mode__c, Due_Amount__c, Remarks__c, New_Mobile_Number__c, Phone__c,
                                Email_Id__c, Account.RT_Phone_1__c, Account.RT_Phone_2__c, Account.RT_Email__c
                           FROM WorkOrder
                          WHERE Id =: serAppoinment.ParentRecordId];
                }
                
                if(!lstWO.isEmpty()){
                    WorkOrder wo = lstWO.get(0);
                    VisitDetail vd = new VisitDetail(
                        serAppoinment.Id,
                    serAppoinment.Follow_Up_Visit_Date__c,
                    wo
                        );
                    
                    return vd;
                }else{
                    return null;
                }
            }catch(Exception e){
                AS_ErrorLogger.log('ICImageRemarkComponentHandler', 'getServiceAppoinment', e, recordId);
                return null;
            }
        }
        
        @AuraEnabled
        public static void saveImage(
            List<FileWrapper> listFiles,
        String recordId,
        String remarks,
        String mobileNumber,
        String secondaryNumber,
        String emailId,
        String workStepName,
        String signatureBase64){
            
            try {
                
                system.debug('Record id ::'+ recordId);
                System.debug('listFiles::'+ listFiles);
                
                
                List<ContentVersion> contentVersions = new List<ContentVersion>();
                //String firstImageTitle = contentVersions.isEmpty() ? null : contentVersions[0].Title;
                
                
                // Step Fetch WorkOrder to get AccountId
                WorkOrder wo = [
                SELECT Id, AccountId, Signature__c, Check_In_Location__Latitude__s,
                       Check_In_Location__Longitude__s, StartDate, EndDate
                FROM WorkOrder
                WHERE Id = :recordId
                LIMIT 1
            ];
                
                List<ServiceAppointment> relatedSAs = [
                SELECT Id, Status, Appointment_Type__c,
                       SchedStartTime, SchedEndTime
                  FROM ServiceAppointment
                 WHERE ParentRecordId = :recordId
              ORDER BY CreatedDate DESC
                 LIMIT 1
            ];
                
                // Step Fetch Account to get BP Number
                Account acc = [
                SELECT Id, BP_Number__c, RT_Phone_1__c, RT_Phone_2__c, RT_Email__c
                FROM Account
                WHERE Id = :wo.AccountId
                LIMIT 1
            ];
                
                //Step 3 Get work step with given name
                WorkStep workStep;
                List<workStep> Steps = [SELECT Id, Name ,ParentRecordId FROM WorkStep 
                WHERE Name =: workStepName AND ParentRecordId =: recordId LIMIT 1];
                if (!steps.isEmpty()) {
                    workStep = steps[0];
                }
                
                // Step 6: Create Document__c record
                /*
                Document__c doc = new Document__c();
                doc.Work_Order__c = recordId;
                doc.BP_Number__c = acc.BP_Number__c;
                doc.File_Name__c = firstImageTitle;
                doc.Remark__c = remarks;
                
                if (workStep != null) {
                    doc.Work_Step__c = workStep.Id;
                }
                insert doc;
                 */
                
                for (FileWrapper fw : listFiles) {
                    if(fw.fileName != null){
                        ContentVersion cv = new ContentVersion();
                        cv.Title = fw.label;
                        cv.PathOnClient = fw.fileName;
                        cv.VersionData = EncodingUtil.base64Decode(fw.base64Data);
                        cv.BP_Number__c = acc.BP_Number__c;
                        cv.Remarks__c = remarks;
                        contentVersions.add(cv);
                    }
                }
                insert contentVersions;
                
                // Map ContentVersion Id to ContentDocumentId
                Map<Id, Id> versionToDocMap = new Map<Id, Id>();
                for (ContentVersion cv : [SELECT Id, ContentDocumentId 
                                        FROM ContentVersion 
                                       WHERE Id IN :contentVersions]) {
                    versionToDocMap.put(cv.Id, cv.ContentDocumentId);
                }
                
                // Step 5: Link files to Document__c  record
                List<ContentDocumentLink> links = new List<ContentDocumentLink>();
                for (Id versionId : versionToDocMap.keySet()) {
                    links.add(new ContentDocumentLink(
                        ContentDocumentId = versionToDocMap.get(versionId),
                    LinkedEntityId = wo.Id,
                    ShareType = 'V',
                    Visibility = 'AllUsers'
                        ));
                }
                insert links;
                
                //doc.Upload_Status__c = 'Pending';
                //update doc;
                
                if (String.isNotBlank(signatureBase64)) {
                    String base64Prefix = 'data:image/png;base64,';
                    if (!signatureBase64.startsWith(base64Prefix)) {
                        signatureBase64 = base64Prefix + signatureBase64;
                    }
                    String imageHtml = '<img src="' + signatureBase64 + '" style="max-width:100%;" />';
                    
                    wo.Signature__c = imageHtml;
                    wo.Check_Out_Date_Time__c = Datetime.now();
                    wo.Check_Out_Location__Latitude__s = wo.Check_In_Location__Latitude__s;
                    wo.Check_Out_Location__Longitude__s = wo.Check_In_Location__Longitude__s;
                    if(remarks != null) wo.Remarks__c = remarks;
                    // if(mobileNumber != null) wo.New_Mobile_Number__c = mobileNumber;
                    // if(secondaryNumber != null) wo.Phone__c = secondaryNumber;
                    // if(emailId != null) wo.Email_ID__c = emailId;
                    wo.Status = 'Completed';
                    wo.Appointment_Status__c = 'Completed';
                    
                    update wo;
                    
                    if (!relatedSAs.isEmpty()) {
                        ServiceAppointment sa = relatedSAs[0];
                        sa.Status = 'Completed';
                        sa.Appointment_Type__c = 'Completed';
                        
                        update relatedSAs;
                    }
                    
                    updateWorkStepStatus(recordId, workStepName);

                    // 🔹 Update Account fields
                    Account updateAcc = new Account(Id = acc.Id);
                    if (String.isNotBlank(mobileNumber)) {
                        updateAcc.RT_Phone_1__c = mobileNumber;
                    }

                    if (String.isNotBlank(secondaryNumber)) {
                        updateAcc.RT_Phone_2__c = secondaryNumber;
                    }

                    if (String.isNotBlank(emailId)) {
                        updateAcc.RT_Email__c = emailId;
                    }

                    // Update only if at least one value was provided
                    if (
                        updateAcc.RT_Phone_1__c != null ||
                        updateAcc.RT_Phone_2__c != null ||
                        updateAcc.RT_Email__c != null
                    ) {
                        update updateAcc;
                    }
                }
                
            } catch (Exception e) {
                AS_ErrorLogger.log('ICImageRemarkComponentHandler', 'saveImage', e, recordId);
            }
        }
        
        @AuraEnabled
        public static void savePaymentDetail(List<FileWrapper> listFiles,String recordId, String remarks, String workStepName, String signatureBase64){
            try {
                
                system.debug('Record id ::'+ recordId);
                System.debug('listFiles::'+ listFiles);
                
                
                List<ContentVersion> contentVersions = new List<ContentVersion>();
                //String firstImageTitle = contentVersions.isEmpty() ? null : contentVersions[0].Title;
                
                // Step Fetch WorkOrder to get AccountId
                WorkOrder wo = [
                SELECT Id, AccountId, Signature__c
                FROM WorkOrder
                WHERE Id = :recordId
                LIMIT 1
            ];
                
                // Step Fetch Account to get BP Number
                Account acc = [
                SELECT Id, BP_Number__c
                FROM Account
                WHERE Id = :wo.AccountId
                LIMIT 1
            ];
                
                //Step 3 Get work step with given name
                WorkStep workStep;
                List<workStep> Steps = [SELECT Id, Name ,ParentRecordId FROM WorkStep 
                WHERE Name =: workStepName AND ParentRecordId =: recordId LIMIT 1];
                if (!steps.isEmpty()) {
                    workStep = steps[0];
                }
                
                // Step 6: Create Document__c record
                // Document__c doc = new Document__c();
                // doc.Work_Order__c = recordId;
                // doc.BP_Number__c = acc.BP_Number__c;
                // doc.File_Name__c = firstImageTitle;
                // doc.Mode_Of_Payment__c = modeOfPayment;
                // doc.Amound_Paid__c = amount;
                // doc.Remark__c = remarks;
                // if (workStep != null) {
                    //     doc.Work_Step__c = workStep.Id;
                // }
                // insert doc;
                
                for (FileWrapper fw : listFiles) {
                    if(fw.fileName != null){
                        ContentVersion cv = new ContentVersion();
                        cv.Title = fw.label;
                        cv.PathOnClient = fw.fileName;
                        cv.VersionData = EncodingUtil.base64Decode(fw.base64Data);
                        cv.BP_Number__c = acc.BP_Number__c;
                        cv.Remarks__c = remarks;
                        contentVersions.add(cv);
                    }
                }
                insert contentVersions;
                
                // Map ContentVersion Id to ContentDocumentId
                Map<Id, Id> versionToDocMap = new Map<Id, Id>();
                for (ContentVersion cv : [SELECT Id, ContentDocumentId 
                                        FROM ContentVersion 
                                       WHERE Id IN :contentVersions]) {
                    versionToDocMap.put(cv.Id, cv.ContentDocumentId);
                }
                
                // Step 5: Link files to Document__c  record
                List<ContentDocumentLink> links = new List<ContentDocumentLink>();
                for (Id versionId : versionToDocMap.keySet()) {
                    links.add(new ContentDocumentLink(
                        ContentDocumentId = versionToDocMap.get(versionId),
                    LinkedEntityId = wo.Id,
                    ShareType = 'V',
                    Visibility = 'AllUsers'
                        ));
                }
                insert links;
                
                updateWorkStepStatus(recordId, workStepName);
                
                // doc.Upload_Status__c = 'Pending';
                // update doc;
                
                if (String.isNotBlank(signatureBase64)) {
                    String base64Prefix = 'data:image/png;base64,';
                    if (!signatureBase64.startsWith(base64Prefix)) {
                        signatureBase64 = base64Prefix + signatureBase64;
                    }
                    String imageHtml = '<img src="' + signatureBase64 + '" style="max-width:100%;" />';
                    wo.Signature__c = imageHtml;
                    
                    update wo;
                }
                
            } catch (Exception ex) {
                System.debug('❌ Exception: ' + ex.getMessage() + ' ' + ex.getLineNumber());
                throw new AuraHandledException('Error updating work order: ' + ex.getMessage());
                
            }
        }
        
        public static void updateWorkStepStatus(Id workOrderId,String name){
            System.debug('workOrderId: '+workOrderId);
            System.debug('name: '+name);
            List<WorkStep> steps = [
                SELECT Id, Status
                FROM WorkStep
                WHERE ParentRecordId = :workOrderId
                AND Name = :name
                LIMIT 1
            ];

            
            if (!steps.isEmpty()) {
                WorkStep ws = steps[0];
                ws.Status = 'Completed';
                
                update ws;
            }
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
                
                WorkOrder workOrder = [Select Id, accountId from WorkOrder WHERE Id =: serApp.ParentRecordId];
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
                
                List<Account> accList = [
                    SELECT Id
                    FROM Account
                    WHERE Id = :workOrder.AccountId
                    AND (Geolocation__Latitude__s = NULL
                        OR Geolocation__Longitude__s = NULL)
                    LIMIT 1
                ];
                
                if (!accList.isEmpty()) {
                    accList[0].Geolocation__Latitude__s = latitude;
                    accList[0].Geolocation__Longitude__s = longitude;
                    update accList;
                }
            }
            catch(Exception e) {
                AS_ErrorLogger.log('ICImageRemarkComponentHandler', 'updateGeoLocation', e, workOrderId);
            }
        }
        
        @AuraEnabled
        public static Decimal paymentReceived(String workOrderId, Decimal amtReceived){
            WorkOrder woToUpdate = new WorkOrder(
                Id = workOrderId,
            Amount_Received__c = amtReceived,
            Payment_Mode__c = 'QR Code',
            Payment_Date__c = String.valueOf(Date.today().format())
                );
            
            update woToUpdate;
            return amtReceived;
        }
        
        @AuraEnabled
        public static String sendSms(String phoneNumber, String workOrderId) {
            
            if (String.isBlank(phoneNumber)) {
                throw new AuraHandledException('Phone number is required to send SMS.');
            }
            
            WorkOrder order = [
            SELECT Id, Receipt_No__c, CA_Number__c, Amount_Received__c,
                 Payment_Mode__c, Agent__r.Name, Agency_Name_Formula__c
            FROM WorkOrder 
            WHERE Id = :workOrderId
            LIMIT 1
        ];
            
            Go_Collect_Follow_Up__mdt mdt = [
            SELECT Id, Template_Id__c
            FROM Go_Collect_Follow_Up__mdt
            WHERE DeveloperName = 'Payment_Confirmation'
            LIMIT 1
        ];
            
            if (mdt == null || String.isBlank(mdt.Template_Id__c)) {
                throw new AuraHandledException('No active SMS template found in metadata.');
            }
            
            List<Case_Type_SMS__c> tmplList = [
            SELECT Status__c, Template_Id__c, Message__c
            FROM Case_Type_SMS__c
            WHERE Template_Id__c = :mdt.Template_Id__c
            LIMIT 1
        ];
            
            if (tmplList.isEmpty()) {
                throw new AuraHandledException('No matching SMS template record found for Template Id: ' + mdt.Template_Id__c);
            }
            
            Case_Type_SMS__c tmpl = tmplList[0];
            
            Map<String, String> mergeFields = new Map<String, String>{
                'workOrder.WorkOrderNumber'         => (order.Receipt_No__c != null) ? order.Receipt_No__c : 'N/A',
                'workOrder.Account.CA_Number__c'    => (order.CA_Number__c != null) ? order.CA_Number__c : 'N/A',
                'workOrder.Amount_Received__c'      => (order.Amount_Received__c != null) ? String.valueOf(order.Amount_Received__c) : '0.00',
                'workOrder.Payment_Mode__c'         => (order.Payment_Mode__c != null) ? order.Payment_Mode__c : '',
                'workOrder.Agent__r.Name'           => (order.Agent__r.Name != null) ? order.Agent__r.Name : '',
                'workOrder.Agency_Name_Formula__c'  => (order.Agency_Name_Formula__c != null) ? order.Agency_Name_Formula__c : ''
            };
            
            List<Notification__c> notificationsInsert = new List<Notification__c>();
            
            // 🔹 NEW: SMS Case using Bulk API
            if (!String.isBlank(phoneNumber)) {
                // Build correlation fields
                String woIdsJson = JSON.serialize(new List<Id>{ workOrderId });
                String phonesJson = JSON.serialize(new List<String>{ phoneNumber });
                Map<String, List<Integer>> mapPhoneToIdx = new Map<String, List<Integer>>{ phoneNumber => new List<Integer>{ 0 } };
                String phoneToIndicesJson = JSON.serialize(mapPhoneToIdx);
                
                SmsApiConfigLTD__c config = SmsApiConfigLTD__c.getOrgDefaults();
                
                // Build JSON payload
                Map<String,Object> auth = new Map<String,Object>{
                    'key' => config.API_Key__c,
                    'version' => '1.0',
                    'channel' => '0'
                };
                
                String finalMessage = tmpl.Message__c;
                
                for (String key : mergeFields.keySet()) {
                String placeholder = '{!' + key + '}';
                String replacement = mergeFields.get(key) != null ? mergeFields.get(key) : '';
                finalMessage = finalMessage.replace(placeholder, replacement);
            }
            
            Map<String,Object> sms = new Map<String,Object>{
                'destination' => phoneNumber,
                'source' => 'MGLLTD',
                'type' => 'TEXT',
                'content' => finalMessage,
                'tempId' => mdt.Template_Id__c
            };
            
            Map<String,Object> payload = new Map<String,Object>{
                'authentication' => auth,
                'message' => new Map<String,Object>{ 'smsdata' => new List<Object>{ sms } }
            };
            
            String smsJson = JSON.serialize(payload);
            
            // Call Bulk SMS API
            SmsBulkAPICallout.sendBulkSmsWithUpdate(
                smsJson,
            woIdsJson,
            phonesJson,
            phoneToIndicesJson
                );
        }
        return 'Success';
    }
    
    @AuraEnabled
    public static Map<String, Double> getAccountGeoCoordinates(Id accountId) {
        
        Map<String, Double> result = new Map<String, Double>();
        
        if (accountId == null) {
            return result;
        }
        
        Account acc = [
            SELECT Geolocation__Latitude__s,
                   Geolocation__Longitude__s
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];
        
        if (acc.Geolocation__Latitude__s != null &&
            acc.Geolocation__Longitude__s != null) {
            
            result.put('lat', acc.Geolocation__Latitude__s);
            result.put('lon', acc.Geolocation__Longitude__s);
        }
        System.debug('result : '+result);
        return result;
    }
    
    public class GeoConfigDTO {
        @AuraEnabled public Boolean geoEnabled{get;set;}
        @AuraEnabled public Decimal geoRadius{get;set;}
    }
    
    /**
     * @description Fetch GeoFencing config from Custom Metadata
     */
    @AuraEnabled(cacheable = true)
    public static GeoConfigDTO getGeoConfig() {
        GeoConfigDTO dto = new GeoConfigDTO();
        dto.geoEnabled = false;
        dto.geoRadius = 300;
        
        try {
            // Fetch metadata: R_T_GeoFencing_Service__mdt
            R_T_GeoFencing_Service__mdt mdt = [
                                SELECT Is_Active__c, Radius_Meters__c
                                FROM R_T_GeoFencing_Service__mdt
                                WHERE DeveloperName = 'Default'
                                LIMIT 1
                            ];
            
            dto.geoEnabled = mdt.Is_Active__c;
            if (mdt.Radius_Meters__c != null || mdt.Radius_Meters__c != '')
                dto.geoRadius = Decimal.valueOf(mdt.Radius_Meters__c);
        } catch (Exception e) {
            AS_ErrorLogger.log('ICImageRemarkComponentHandler', 'getGeoConfig', e, null);
        }
        return dto;
    }
    
    
    public class FileWrapper{
        @AuraEnabled public String base64Data{get;set;}
        @AuraEnabled public String fileName{get;set;}
        @AuraEnabled public String label{get;set;}
    }
    
    public class VisitDetail{
        @AuraEnabled public String serviceAppId;
        @AuraEnabled public Date followUpDate;
        @AuraEnabled public String status;
        @AuraEnabled public Datetime checkInDateTime;
        @AuraEnabled public Datetime checkOutDateTime;
        @AuraEnabled public String checkInLocation;
        @AuraEnabled public String checkOutLocation;
        @AuraEnabled public Decimal amountReceived;
        @AuraEnabled public String payType;
        @AuraEnabled public Decimal dueAmt;
        @AuraEnabled public String remarks;
        @AuraEnabled public String mobileNumber;
        @AuraEnabled public String secondaryNumber;
        @AuraEnabled public String emailId;
        
        public VisitDetail(String serviceAppId, Date followUpDate, WorkOrder wo){
            this.serviceAppId = serviceAppId;
            this.followUpDate = followUpDate;
            this.status = wo.Status;
            this.checkInDateTime = wo.Check_In_Date_Time__c;
            this.checkOutDateTime = wo.Check_Out_Date_Time__c;
            this.checkInLocation = String.valueOf(wo.Check_In_Location__c);
            this.checkOutLocation = String.valueOf(wo.Check_Out_Location__c);
            this.amountReceived = wo.Amount_Received__c;
            this.payType = wo.Payment_Mode__c;
            this.dueAmt = wo.Due_Amount__c;
            this.remarks = wo.Remarks__c;
            // this.mobileNumber = wo.New_Mobile_Number__c;
            // this.secondaryNumber = wo.Phone__c;
            // this.emailId = wo.Email_ID__c;

            this.mobileNumber = wo.Account.RT_Phone_1__c;
            this.secondaryNumber = wo.Account.RT_Phone_2__c;
            this.emailId = wo.Account.RT_Email__c;
        }
    }
}