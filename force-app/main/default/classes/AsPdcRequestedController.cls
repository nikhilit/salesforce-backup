/**
 * @description       : 
 * @author            : Shashank.shekhar@appstrail.com
 * @group             : 
 * @last modified on  : 07-27-2025
 * @last modified by  : Shashank.shekhar@appstrail.com
**/
public without sharing class AsPdcRequestedController {  

    private static Map<String, List<String>> PATH_TOKEN_CACHE = new Map<String, List<String>>();
 
    public class ChequeWrapper {
        @AuraEnabled public String micrCode { get; set; }
        @AuraEnabled public String bankName { get; set; }
        @AuraEnabled public String branchName { get; set; }
        @AuraEnabled public String chequeNumber { get; set; }
        @AuraEnabled public Date chequeDate { get; set; }
        @AuraEnabled public Decimal chequeAmount { get; set; }
        @AuraEnabled public String ifscCode { get; set; }
        @AuraEnabled public String base64Image { get; set; }
        @AuraEnabled public Id recordId { get; set; }
        @AuraEnabled public String paymentMode { get; set; }
        @AuraEnabled public String workStepName { get; set; }
        @AuraEnabled public Boolean micrFound { get; set; }
    } 
    
    @AuraEnabled
    public static String saveChequeDetails(List<ChequeWrapper> chequeData, String payType, String payRemark) {
        try {

            Boolean isFieldSense = false;

            if (chequeData == null || chequeData.isEmpty()) {
                throw new AuraHandledException('No cheque details provided.');
            }

            // --- 1. Collect WorkOrders & Accounts ---
            Set<Id> workOrderIds = new Set<Id>();
            for (ChequeWrapper chq : chequeData) {
                if (String.isBlank(chq.recordId)) {
                    throw new AuraHandledException('Missing WorkOrder Id for cheque.');
                }
                workOrderIds.add(chq.recordId);
            }

            Map<Id, WorkOrder> woMap = new Map<Id, WorkOrder>(
                [SELECT Id, AccountId, Check_In_Location__latitude__s, 
                        Check_In_Location__longitude__s, WorkType.Name
                   FROM WorkOrder 
                  WHERE Id IN :workOrderIds]
            );

            if(!woMap.isEmpty()){
                String workTypeName = woMap.values().get(0).WorkType.Name; 
                String asFieldSenseFlowLabel = System.Label.AS_FieldSenseFlowLabel;
                isFieldSense = asFieldSenseFlowLabel.split(',').contains(workTypeName.toLowerCase());
            }

            System.debug('=======isFieldSense=====>>>'+isFieldSense);
            
            List<ServiceAppointment> relatedSAs = [
                SELECT Id, Status, Appointment_Type__c
                  FROM ServiceAppointment
                 WHERE ParentRecordId IN : woMap.keySet()
              ORDER BY CreatedDate DESC
                 LIMIT 1
            ];

            Set<Id> accIds = new Set<Id>();
            for (WorkOrder wo : woMap.values()) {
                accIds.add(wo.AccountId);
            }

            Map<Id, Account> accMap = new Map<Id, Account>(
                [SELECT Id, BP_Number__c FROM Account WHERE Id IN :accIds]
            );

            // --- 2. Preload existing cheque documents to prevent duplicates ---
            Map<String, Id> chequeKeyToDocId = new Map<String, Id>(); 
            for (ContentDocumentLink cdl : [
                SELECT ContentDocumentId, LinkedEntityId, 
                    ContentDocument.LatestPublishedVersion.Title
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :workOrderIds
            ]) {
                // Key = WO + ChequeNumber (parse cheque number from Title if present)
                String title = cdl.ContentDocument.LatestPublishedVersion.Title;
                if (title != null && title.startsWith('Cheque_Image_')) {
                    // Extract cheque number part after prefix
                    String chequeNum = title.replace('Cheque_Image_', '');
                    String key = cdl.LinkedEntityId + '_' + chequeNum;
                    chequeKeyToDocId.put(key, cdl.ContentDocumentId);
                }
            }

            // --- 3. Build Payment__c + ContentVersion ---
            List<Payment__c> payments = new List<Payment__c>();
            List<ContentVersion> cvsToInsert = new List<ContentVersion>();
            Map<String, Id> titleToWoId = new Map<String, Id>();

            for (ChequeWrapper chq : chequeData) {

                Boolean isValid = isFieldSense ? (String.isBlank(chq.chequeNumber) ||
                    chq.chequeDate == null || chq.chequeAmount == null || String.isBlank(chq.base64Image)) : (String.isBlank(chq.micrCode) || String.isBlank(chq.chequeNumber) ||
                    chq.chequeDate == null || chq.chequeAmount == null || String.isBlank(chq.base64Image));
                if (isValid) {
                    throw new AuraHandledException('Cheque ' + chq.chequeNumber + ': Missing required fields.');
                }

                WorkOrder wo = woMap.get(chq.recordId);
                Account acc = accMap.get(wo.AccountId);

                // Build Payment
                Payment__c pay = new Payment__c(
                    Name                = 'Payment - ' + chq.chequeNumber,
                    Cheque_Amount__c    = chq.chequeAmount,
                    Cheque_Date__c      = chq.chequeDate,
                    Payment_Mode__c     = chq.paymentMode,
                    Cheque_Number__c    = chq.chequeNumber,
                    Branch_Name__c      = chq.branchName,
                    Bank_Name__c        = chq.bankName,
                    IFSC_Code__c        = chq.ifscCode,
                    Work_Order__c       = chq.recordId,
                    Business_Partner__c = acc.Id
                );

                if(!isFieldSense){
                    pay.MICR_Code__c = chq.micrCode;
                    pay.MICR_Found__c = chq.micrFound;
                }

                payments.add(pay);

                // Clean base64 string
                String cleanImage = chq.base64Image;
                if (cleanImage != null && cleanImage.startsWith('data:image')) {
                    cleanImage = cleanImage.substring(cleanImage.indexOf(',') + 1);
                }

                // Build cheque key
                String chequeKey = chq.recordId + '_' + chq.chequeNumber;

                // If document exists, add a new version under same ContentDocument
                if (chequeKeyToDocId.containsKey(chequeKey)) {
                    cvsToInsert.add(new ContentVersion(
                        ContentDocumentId = chequeKeyToDocId.get(chequeKey),
                        Title             = 'Cheque_Image_' + chq.chequeNumber,
                        PathOnClient      = 'Cheque_Image_' + chq.chequeNumber + '.jpg',
                        VersionData       = EncodingUtil.base64Decode(cleanImage),
                        BP_Number__c      = acc.BP_Number__c
                    ));
                } else {
                    // First time → new ContentDocument
                    ContentVersion cv = new ContentVersion(
                        Title        = 'Cheque_Image_' + chq.chequeNumber,
                        PathOnClient = 'Cheque_Image_' + chq.chequeNumber + '.jpg',
                        VersionData  = EncodingUtil.base64Decode(cleanImage),
                        BP_Number__c = acc.BP_Number__c
                    );
                    cvsToInsert.add(cv);
                    titleToWoId.put(cv.Title, chq.recordId);
                }
            }

            // --- 4. Insert Payments & CVs ---
            if (!payments.isEmpty()) insert payments;

            Set<Id> insertedCvIds = new Set<Id>();
            if (!cvsToInsert.isEmpty()) {
                Database.SaveResult[] results = Database.insert(cvsToInsert, false);
                for (Integer i = 0; i < results.size(); i++) {
                    if (results[i].isSuccess()) {
                        insertedCvIds.add(results[i].getId());
                    } else {
                        System.debug('CV insert failed: ' + results[i].getErrors()[0].getMessage());
                    }
                }
            }

            // --- 5. Link new ContentDocuments to WorkOrders ---
            if (!titleToWoId.isEmpty()) {
                Map<String, ContentVersion> cvByTitle = new Map<String, ContentVersion>();
                for (ContentVersion cv : [
                    SELECT Id, Title, ContentDocumentId
                    FROM ContentVersion
                    WHERE Id IN :insertedCvIds
                ]) {
                    cvByTitle.put(cv.Title, cv);
                }

                List<ContentDocumentLink> links = new List<ContentDocumentLink>();
                for (String title : titleToWoId.keySet()) {
                    ContentVersion cv = cvByTitle.get(title);
                    if (cv != null) {
                        links.add(new ContentDocumentLink(
                            ContentDocumentId = cv.ContentDocumentId,
                            LinkedEntityId    = titleToWoId.get(title),
                            ShareType         = 'V',
                            Visibility        = 'AllUsers'
                        ));
                    }
                }
                if (!links.isEmpty()) {
                    insert links;
                }
            }

            
            // --- 6. Update WorkOrders with amount received ---
            Map<Id, Decimal> woIdToAmt = new Map<Id, Decimal>();
            for (Payment__c pay : [
                SELECT Work_Order__c, Cheque_Amount__c
                FROM Payment__c
                WHERE Work_Order__c IN :workOrderIds
                AND Cheque_Amount__c != null
                AND Payment_Status__c != 'Cancelled'
                AND Payment_Status__c != 'Rejected'
            ]) {
                Decimal running = woIdToAmt.containsKey(pay.Work_Order__c) ? woIdToAmt.get(pay.Work_Order__c) : 0;
                woIdToAmt.put(pay.Work_Order__c, running + pay.Cheque_Amount__c);
            }

            List<WorkOrder> woToUpdate = new List<WorkOrder>();
            for (Id woId : woIdToAmt.keySet()) {
                WorkOrder wo = new WorkOrder(
                    Id                 = woId,
                    Amount_Received__c = woIdToAmt.get(woId),
                    Payment_Mode__c    = 'Cheque',
                    Payment_Date__c    = String.valueOf(Date.today().format()),
                    Payment_Type__c = payType,
                    Pay_Remark__c = payRemark
                );

                if(!isFieldSense){
                    wo.Check_Out_Date_Time__c = Datetime.now();
                    wo.Check_Out_Location__Latitude__s = woMap.get(woId).Check_In_Location__Latitude__s;
                    wo.Check_Out_Location__Longitude__s = woMap.get(woId).Check_In_Location__Longitude__s;
                    wo.Status = 'Completed';
                    wo.Appointment_Status__c = 'Completed';
                }

                woToUpdate.add(wo);
            }

            if (!woToUpdate.isEmpty()) {
                update woToUpdate;
            }

            System.debug('=======isFieldSense=====>>>'+isFieldSense);

            if(!isFieldSense){
                if (!relatedSAs.isEmpty()) {
                    ServiceAppointment sa = relatedSAs[0];
                    sa.Status = 'Completed'; 
                    sa.Appointment_Type__c = 'Completed';

                    update relatedSAs;
                }

                // --- 7. Update WorkSteps ---
                updateWorkStepStatuses(workOrderIds, new List<String>{'Collect Payment', 'Check Out'});
            }

            return 'Success';

        } catch (Exception ex) {
            System.debug('Exception in saveChequeDetails: ' + ex.getMessage() + '\nStackTrace: ' + ex.getStackTraceString());
            AS_ErrorLogger.log('AsPdcRequestedController', 'saveChequeDetails', ex, '');
            return 'Exception';
        }
    }

    public static void updateWorkStepStatuses(Set<Id> workOrderIds, List<String> name) {
        List<WorkStep> steps = [SELECT Id FROM WorkStep
            WHERE ParentRecordId IN :workOrderIds AND Name IN :name];
        for (WorkStep ws : steps) {
            ws.Status = 'Completed';
        }
        update steps;
    }

    public static void updateWorkStepStatus(Set<Id> workOrderIds, String workStepName) {
        try{
            List<WorkStep> stepsToUpdate = [SELECT Id, Status FROM WorkStep WHERE Name = :workStepName AND ParentRecordId IN :workOrderIds];

            for (WorkStep step : stepsToUpdate) {
                step.Status = 'Completed';
            }

            if (!stepsToUpdate.isEmpty()) {
                update stepsToUpdate;
            }
        } catch (Exception ex) {
            AS_ErrorLogger.log('AsPdcRequestedController', 'updateWorkStepStatus', ex, '');
        }
    }

    @AuraEnabled
    public static String sendSms(String phoneNumber, String workOrderId) {

        if (String.isBlank(phoneNumber)) {
            throw new AuraHandledException('Phone number is required to send SMS.');
        }
        
        List<Payment__c> lstPayment = new List<Payment__c>();
        
        for (Payment__c pay : [SELECT Id, Name, Cheque_Amount__c, Work_Order__c, ReceiptNo__c,
                                      Work_Order__r.RecordType.DeveloperName, 
                                      Work_Order__r.RecordTypeId,
                                      Work_Order__r.Record_Type_Developer_Name__c,
                                      Work_Order__r.AccountId, 
                                      Work_Order__r.Account.Phone,
                                      Work_Order__r.Account.CA_Number__c,
                                      Work_Order__r.New_Mobile_Number__c,
                                      Work_Order__r.CA_Number__c,
                                      Work_Order__r.Agency_Name_Formula__c,
                                      Work_Order__r.Agent__r.Name,
                                      Work_Order__r.Payment_Mode__c
                                 FROM Payment__c
                                WHERE Work_Order__c = : workOrderId]) {
            lstPayment.add(pay);                                    
        }

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

        Map<String, String> staticFieldMap = new Map<String, String>{
            'workOrder.WorkOrderNumber'       => 'ReceiptNo__c',
            'workOrder.Account.CA_Number__c'  => 'Work_Order__r.CA_Number__c',
            'workOrder.Amount_Received__c'    => 'Cheque_Amount__c',
            'workOrder.Payment_Mode__c'       => 'Work_Order__r.Payment_Mode__c',
            'workOrder.Agent__r.Name'         => 'Work_Order__r.Agent__r.Name',
            'workOrder.Agency_Name_Formula__c'=> 'Work_Order__r.Agency_Name_Formula__c'
        };

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

            
            List<Object> smsdataList = new List<Object>();
            List<String> phonesInOrder = new List<String>();
            List<Id> payIdsInOrder = new List<Id>();
            Map<String, List<Integer>> phoneToIndices = new Map<String, List<Integer>>();

            for (Payment__c p : lstPayment) {

                WorkOrder wo = p.Work_Order__r;
                if (wo == null) continue;

                String candidatePhone = phoneNumber;

                if (String.isBlank(candidatePhone)) continue;

                Map<String, String> mergeFields = new Map<String, String>();

                for (String key : staticFieldMap.keySet()) {
                    String fieldPath = staticFieldMap.get(key);
                    Object val = getFieldValueByPath(p, fieldPath);
                    
                    String formatted;
                    if (val == null || String.valueOf(val) == '') formatted = 'N/A';
                    else if (val instanceof Date) formatted = ((Date)val).format();
                    else if (val instanceof Datetime) formatted = ((Datetime)val).format();
                    else formatted = String.valueOf(val);
                    
                    if(key == 'workOrder.Payment_Mode__c'){
                        mergeFields.put(key, 'Cheque');
                    }else{
                        mergeFields.put(key, formatted);
                    }
                    
                }

                String content = tmpl.Message__c;

                for (String key : mergeFields.keySet()) {
                    String placeholder = '{!' + key + '}';
                    if (content.contains(placeholder)) {
                        content = content.replace(placeholder, mergeFields.get(key));
                    }
                }
                
                system.debug('========content=======>'+content);

                String dest = candidatePhone;

                Map<String, Object> smsEntry = new Map<String, Object>{
                    'destination' => dest,
                    'source' => 'MGLLTD',
                    'type' => 'TEXT',
                    'content' => content,
                    'tempId' => mdt.Template_Id__c
                };
                smsdataList.add(smsEntry);

                payIdsInOrder.add(p.Id);
                phonesInOrder.add(dest);

                if (!phoneToIndices.containsKey(dest)) phoneToIndices.put(dest, new List<Integer>());
                phoneToIndices.get(dest).add(phonesInOrder.size() - 1);
            }
            

            Map<String,Object> payload = new Map<String,Object>{
                'authentication' => auth,
                'message' => new Map<String,Object>{ 'smsdata' => smsdataList }
            };

            String smsJson = JSON.serialize(payload);

            System.debug('smsJson : '+smsJson);
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

    private static Object getFieldValueByPath(SObject record, String path) {
        if (record == null || String.isBlank(path)) return null;
        if (!PATH_TOKEN_CACHE.containsKey(path)) {
            PATH_TOKEN_CACHE.put(path, path.split('\\.'));
        }
        List<String> parts = PATH_TOKEN_CACHE.get(path);

        Object current = record;
        for (String part : parts) {
            if (current == null) return null;
            if (current instanceof SObject) {
                SObject sobj = (SObject) current;
                try {
                    if (sobj.getSObjectType().getDescribe().fields.getMap().containsKey(part)) {
                        current = sobj.get(part);
                        continue;
                    }
                } catch (Exception e) { }
                try {
                    current = sobj.getSObject(part);
                    continue;
                } catch (Exception e) {
                    return null;
                }
            } else {
                return current; // primitive
            }
        }
        return current;
    }
}