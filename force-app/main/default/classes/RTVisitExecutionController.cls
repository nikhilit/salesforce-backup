/**
* @description       : 
* @author            : Shashank.shekhar@appstrail.com
* @group             : 
* @last modified on  : 07-11-2025
* @last modified by  : Shashank.shekhar@appstrail.com
**/
public without sharing class RTVisitExecutionController {

    public class MyCustomException extends Exception {}

    @AuraEnabled 
    public static Map<String, Object> getAccountInfoFromSA(Id workOrderId) {
        System.debug('Start: getAccountInfoFromSA called with Work Order Id: ' + workOrderId);
        
        try {
            if (workOrderId == null) {
                AS_ErrorLogger.log('RTVisitExecutionController', 'getAccountInfoFromSA', 'Work Order Id is null', workOrderId);
                return null;
            } 

            // Fetch WorkOrder with related Account
            WorkOrder wo = [SELECT Id, AccountId, Account.Name, Account.Phone, Due_Amount__c, Customer_CA_Number__c,
                                    X0_30__c, X31_60__c, X61_90__c, X91_180__c, X181_365__c, X1_2YR__c, X2_3YR__c,
                                    B4DUE__c, NOTDUE__c, WorkType.Name, Customer_Full_Name__c, New_Mobile_Number__c,
                                    Customer_BP_Number__c, CA_Number__c, Building_Name__c, New_Floor__c, New_Flat__c,
                                    New_Wing__c, New_Colony__c, Check_In_Date_Time__c, Status, Check_Out_Date_Time__c,
                                    Follow_up_Date__c, Amount_Received__c, Payment_Mode__c, Disconnection_Notice_No__c,
                                    Disconnection_Notice_Date__c, Follow_up_Remarks__c
                               FROM WorkOrder 
                              WHERE Id = :workOrderId 
                              LIMIT 1];
                 
            if (wo.AccountId == null) {
                AS_ErrorLogger.log('RTVisitExecutionController', 'getAccountInfoFromSA', 'No Account associated with this Work Order.', workOrderId);
                return null;
            }

            // Fetch Account details
            Account acc = [
                SELECT Id, Name, Phone, Secondary_Telephone__c, Account_Email__c, Account_Type__c, Type, MRU_Code__c, BP_Number__c, 
                        CA_Number__c, Building_name__c, Street__c, Colony__c, Wing__c, Floor__c, Flat__c, Road_name__c, Inv_No__c, 
                        Portion__c, BillingPostalCode, Location__c, Email_Id__c, Full_Name__c, Room__c
                FROM Account
                WHERE Id = :wo.AccountId
                LIMIT 1
            ];

            // Fetch related Service Appointment(s)
            List<ServiceAppointment> saList = [
                SELECT Id, ParentRecordId, SchedStartTime, SchedEndTime, 
                        FollowUpRemarks__c, Appointment_Type__c, Status,
                        Other_Follow_Up_Remark__c, Random_Visit_Date__c
                FROM ServiceAppointment
                WHERE ParentRecordId = :workOrderId
             ORDER BY CreatedDate DESC
            ];

            // List<Billing> lstBill = new List<Billing>();
            // for(Billing__c bill : [SELECT Id, Print_Doc_Number__c, Bill_Date__c, 
            //                               Due_Amount__c , Document_Date__c
            //                          FROM Billing__c 
            //                         WHERE Account__c = :wo.AccountId 
            //                      ORDER BY Posting_Date__c DESC 
            //                         LIMIT 3]){
            //     lstBill.add(new Billing(bill.Print_Doc_Number__c, bill.Document_Date__c, bill.Due_Amount__c));
            // }
            
            List<Payment__c> lstPay = [SELECT Id,Transaction_Id__c, Amount_Paid__c,Payment_Mode__c,Bank_Name__c, Payment_Date__c FROM Payment__c WHERE Work_Order__c =: wo.Id ORDER BY Payment_Date__c DESC LIMIT 3];

            // Return both Account and Service Appointment(s)
            return new Map<String, Object>{
                'acc' => acc,
                'workOrder' => wo,
                'serviceAppointments' => saList,
                //'billing' => lstBill,
                'payment' => lstPay
            };

        } catch (Exception ex) {
            AS_ErrorLogger.log('RTVisitExecutionController', 'getAccountInfoFromSA', ex, workOrderId);
            //throw new AuraHandledException('Apex error: ' + ex.getMessage());
            return null;
        }
    }
	
    /*
    public class Billing {
        @AuraEnabled public String Print_Doc_Number; 
        @AuraEnabled public String Document_Date;     
        @AuraEnabled public Decimal Due_Amount;   

        Billing(String DocNum, Date DocDate, Decimal DueAmt){
            this.Print_Doc_Number = DocNum;
            this.Document_Date = DocDate.format();
            this.Due_Amount = DueAmt;
        }     
    }*/

    @AuraEnabled
    public static Id saveChequeDetails(
        Id workOrderId,
        String micrCode,
        String workStepName,
        String bankName,
        String branchName,
        String chequeNumber,
        String ModeofPayment,
        Date chequeDate,
        String caNumber,
        Decimal chequeAmount,
        List<String> base64Images, String signatureBase64
    ) {
        try {
            // Step 1: Get Business Partner from Work Order
            WorkOrder wo = [
                SELECT Id, AccountId, Signature__c
                FROM WorkOrder
                WHERE Id = :workOrderId
                LIMIT 1
            ];
        
            Account acc = [
                SELECT Id, BP_Number__c
                FROM Account
                WHERE Id = :wo.AccountId
                LIMIT 1
            ];

            // Step 2: Create Payment__c record
            Payment__c payment = new Payment__c();
            payment.CA_Number__c       = caNumber;
            payment.Cheque_Amount__c   = chequeAmount;
            payment.Cheque_Date__c     = chequeDate;
            payment.Payment_Mode__c    = ModeofPayment;
            payment.Cheque_Number__c   = chequeNumber;
            payment.Branch_Name__c     = branchName;
            payment.Bank_Name__c       = bankName;
            payment.MICR_Code__c       = micrCode;
            payment.Work_Order__c      = workOrderId;
            payment.Business_Partner__c = wo.AccountId;
            insert payment;

            //String firstImageTitle = contentVersions.isEmpty() ? null : contentVersions[0].Title;

            // Step 5: Get WorkStep record'
            WorkStep workStep;
            List<WorkStep> steps = [
                SELECT Id, Name, ParentRecordId
                FROM WorkStep
                WHERE Name = :workStepName AND ParentRecordId = :workOrderId
                LIMIT 1
            ];
            if (!steps.isEmpty()) {
                workStep = steps[0];
            }

            // Step 6: Create Document__c record
            // Document__c doc = new Document__c();
            // doc.Payment__c = payment.Id;
            // doc.Work_Order__c = workOrderId;
            // doc.BP_Number__c = acc.BP_Number__c;
            // doc.File_Name__c = firstImageTitle;
            // if (workStep != null) {
            //     doc.Work_Step__c = workStep.Id;
            // }
            // insert doc;
            // doc.Upload_Status__c = 'Pending'; 
            // update doc;

            // Step 3: Convert base64 to ContentVersion list
            List<ContentVersion> contentVersions = new List<ContentVersion>();
            Integer index = 1;
            for (String base64 : base64Images) {
                ContentVersion cv = new ContentVersion();
                cv.Title = 'Cheque_Image_' + index;
                cv.PathOnClient = 'Cheque_Image_' + index + '.jpg';
                cv.VersionData = EncodingUtil.base64Decode(base64);
                cv.BP_Number__c = acc.BP_Number__c;
                contentVersions.add(cv);
                index++;
            }
            insert contentVersions;

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
                    LinkedEntityId = wo.Id,
                    ShareType = 'V',
                    Visibility = 'AllUsers'
                ));
            }
            insert links;

            // Step 8: Mark WorkStep as Completed
            updateWorkStepStatus(workOrderId, workStepName);

            if (String.isNotBlank(signatureBase64)) {
                String base64Prefix = 'data:image/png;base64,';
                if (!signatureBase64.startsWith(base64Prefix)) {
                    signatureBase64 = base64Prefix + signatureBase64;
                }
                String imageHtml = '<img src="' + signatureBase64 + '" style="max-width:100%;" />';
                wo.Signature__c = imageHtml;
                
                update wo;
            }

            // ✅ Return Payment Id
            return payment.Id;

        } catch (Exception ex) {
            System.debug('❌ Apex Exception: ' + ex.getMessage());
            throw new AuraHandledException('Error saving cheque payment: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static String savePdfFiles(String billPrintNumbers, String billDate, String phoneNumber, String accName, String preference, String workOrderId) {
        if (billPrintNumbers == null) {
            AS_ErrorLogger.log('RTVisitExecutionController', 'savePdfFiles', 'No Bill Print Numbers provided.', workOrderId);
            throw new AuraHandledException('No Bill Print Numbers provided.');
        }

        String resultPdf = '';

        String resultUrl=savePdfFile(billPrintNumbers, workOrderId);

        if(string.isBlank(resultUrl)){
            return 'Error';
        }

        if(!String.isBlank(phoneNumber)) {
            resultPdf = sendSms(accName, phoneNumber, workOrderId, preference, billPrintNumbers, billDate);
        }
        return resultPdf;
    }

    // 🔹 Call Ebill API and get response
    // private static EbillResponse callEbillApi(String billNo) {
    //     Http http = new Http();
    //     HttpRequest req = new HttpRequest();
    //     req.setEndpoint(System.Label.Get_Duplicate_PDF + EncodingUtil.urlEncode(billNo, 'UTF-8'));
    //     req.setMethod('GET');
    //     req.setHeader('Content-Type', 'application/json');
    //     req.setHeader('Authorization', 'Bearer ' + System.Label.Get_Bill_Token);
    //     req.setTimeout(60000);

    //     HttpResponse res = http.send(req);
    //     System.debug('Status Code: ' + res.getStatusCode());
    //     System.debug('Response Body: ' + res.getBody());

    //     AS_APIRequestLogger.logRequestResponse(null, System.Label.Get_Duplicate_PDF + EncodingUtil.urlEncode(billNo, 'UTF-8'), null, res, 'EbillApi Request Call');

    //     if (res.getStatusCode() != 200) {
    //         AS_ErrorLogger.log('RTVisitExecutionController', 'callEbillApi', 'API call failed for bill ' + billNo + ' (Status ' + res.getStatus() + ')', billNo);
    //         throw new AuraHandledException('API call failed for bill ' + billNo + ' (Status ' + res.getStatus() + ')');
    //     }

    //     String body = res.getBody();

    //     // ✅ Only try to parse if it looks like JSON
    //     if (body.startsWith('{') || body.startsWith('[')) {
    //         return (EbillResponse) JSON.deserialize(body, EbillResponse.class);
    //     } else {
    //         AS_ErrorLogger.log('RTVisitExecutionController', 'callEbillApi', 'Unexpected non-JSON response for bill ' + billNo + ': ' + body.left(100), billNo);
    //         throw new AuraHandledException('Unexpected non-JSON response for bill ' + billNo + ': ' + body.left(100));
    //     }
    // }

    // // 🔹 Helper Class for Response Parsing
    // public class EbillResponse {
    //     public String message;
    //     public List<String> data;
    //     public String status;
    // }

    public static String sendSms(String accName, String phoneNumber, String workOrderId, String preference, String billPrintNumbers, String billDate) {
        if (String.isBlank(phoneNumber)) {
            throw new AuraHandledException('Phone number is required to send SMS.');
        }

        WorkOrder order = [
            SELECT Id, Bill_Date__c, Due_Amount__c, Account.Name, CaseId
            FROM WorkOrder 
            WHERE Id = :workOrderId
            LIMIT 1
        ];

        Send_Pdf_to_Customer__mdt mdt = [
            SELECT Id, Template_Id__c, Sender__c, Bill_URL__c, API_key__c
            FROM Send_Pdf_to_Customer__mdt
            WHERE Is_Active__c = true
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

        //String pdfLink = String.join(pdfUrls, ',');
        Map<String, String> mergeFields = new Map<String, String>{
            //'BillDate'    => (order.Bill_Date__c != null) ? order.Bill_Date__c.format() : 'Bill Date',
            'BillDate'    => billDate,
            'Amount'      => (order.Due_Amount__c != null) ? String.valueOf(order.Due_Amount__c) : '0.00',
            'AccountName' => (order.Account != null) ? order.Account.Name : '',
            'pdfLink'     => mdt.Bill_URL__c+'id='+workOrderId +'&bNo='+billPrintNumbers
        };

        List<Notification__c> notificationsInsert = new List<Notification__c>();

        if (preference == 'Whatsapp' && !String.isBlank(phoneNumber)) {
            List<Map<String, String>> dynamicComponents = extractDynamicComponents(tmpl.Message__c, mergeFields);
            notificationsInsert.add(new Notification__c(
                Work_Order__c = workOrderId,
                Type__c = 'WhatsApp',
                Sent_Timestamp__c = System.now(),
                Status__c = 'Pending',
                Dynamic_Components__c = JSON.serialize(dynamicComponents),
                Phone_Number__c = phoneNumber,
                Template_Name__c = 'bill_pay'
            ));
        }

        if (!notificationsInsert.isEmpty()) {
            insert notificationsInsert;
            return 'Success';
        }

        // 🔹 NEW: SMS Case using Bulk API
        if (preference == 'SMS' && !String.isBlank(phoneNumber)) {
            // Build correlation fields
            String woIdsJson = JSON.serialize(new List<Id>{ workOrderId });
            String phonesJson = JSON.serialize(new List<String>{ phoneNumber });
            Map<String, List<Integer>> mapPhoneToIdx = new Map<String, List<Integer>>{ phoneNumber => new List<Integer>{ 0 } };
            String phoneToIndicesJson = JSON.serialize(mapPhoneToIdx);
            
            // Build JSON payload
            Map<String,Object> auth = new Map<String,Object>{
                'key' => mdt.API_key__c,
                'version' => '1.0',
                'channel' => '0'
            };
            String finalMessage = tmpl.Message__c;  // start with original message
                for (String key : mergeFields.keySet()) { 
                String placeholder = '{!' + key + '}';
                String replacement = mergeFields.get(key) != null ? mergeFields.get(key) : '';
                finalMessage = finalMessage.replace(placeholder, replacement);
                }
                
                Map<String,Object> sms = new Map<String,Object>{
                'destination' => phoneNumber,
                'source' => mdt.Sender__c,
                'type' => 'TEXT',
                'content' => finalMessage,  // raw message with placeholders already resolved
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

    public static List<Map<String, String>> extractDynamicComponents(String message, Map<String, String> mergeFields) {
        List<Map<String, String>> orderedComponents = new List<Map<String, String>>();

        if (String.isBlank(message)) return orderedComponents;

        Pattern tokenPattern = Pattern.compile('\\{!([^}]+)\\}');
        Matcher matcher = tokenPattern.matcher(message);

        while (matcher.find()) {
            String token = matcher.group(1);
            if (mergeFields.containsKey(token)) {
                orderedComponents.add(new Map<String, String>{ token => mergeFields.get(token) });
            }
        }

        return orderedComponents;
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getPreferencePicklistValues() {
        List<String> values = new List<String>();

        // Describe the field
        Schema.DescribeFieldResult fieldResult = Account.preferance__c.getDescribe();
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            values.add(entry.getValue());
        }
        return values;
    }

    @AuraEnabled
    public static void updateGeoLocation(String workOrderId, Double latitude, Double longitude, String activityType){
        
        try {
            List<sObject> lstObjToUpdate = new List<sObject>();
            
            ServiceAppointment serApp = [SELECT Id, Check_In_Timestamp__c, Check_Out_Timestamp__c, ParentRecordId FROM ServiceAppointment WHERE ParentRecordId = :workOrderId];
            List<WorkStep> steps = [SELECT Id, Status FROM WorkStep WHERE ParentRecordId = :workOrderId AND Name =: activityType LIMIT 1];

            WorkOrder wO = new WorkOrder(Id = serApp.ParentRecordId);
            
            if(activityType == 'Check Out'){

                wO.Check_Out_Date_Time__c = Datetime.now();
                wO.Check_Out_Location__Latitude__s = latitude;
                wO.Check_Out_Location__Longitude__s = longitude;
                lstObjToUpdate.add(wO);
                
                if (serApp != null) {
                    serApp.Check_Out_Timestamp__c = Datetime.now();
                    serApp.Check_Out_Location__Latitude__s = latitude;
                    serApp.Check_Out_Location__Longitude__s = longitude;
                    serApp.Status = 'Completed';
                    
                    lstObjToUpdate.add(serApp);
                }
            }else if(activityType == 'Check In'){
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
            }

            if (!steps.isEmpty()) {
                WorkStep ws = steps[0];
                ws.Status = 'Completed';

                lstObjToUpdate.add(ws);
            }
            
            update lstObjToUpdate;
        }
        catch(Exception e) {
            system.debug('Exception Occurred:: '+ 'LineNumber:: '+e.getLineNumber()+' Message:: '+e.getMessage());
            AS_ErrorLogger.log('RTVisitExecutionController', 'updateGeoLocation', e, workOrderId);
        }
    }

    @AuraEnabled
    public static void updateWorkStepStatus(Id workOrderId, String name) {
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

    // Optional if you want to reuse file info
    public class FileWrapper {
        @AuraEnabled public String base64Data { get; set; }
        @AuraEnabled public String fileName { get; set; }
        @AuraEnabled public String label { get; set; }
    }

    @AuraEnabled
    public static Bank_Detail__c getBankDetailsByMicr(String micrCode) {
        try {
            return [SELECT BANK__c, BRANCH__c,IFSC__c FROM Bank_Detail__c WHERE Name = :micrCode LIMIT 1];
        } catch (Exception e) {
            throw new AuraHandledException('No matching bank details found for MICR: ' + micrCode);
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Receivable__c> getReceivables(Id accountId) {
        return [
            SELECT
                Id,
                Doc_Number__c,
                Document_Date__c
            FROM Receivable__c
            WHERE Business_Partner__c = :accountId
        ];
    }

    @AuraEnabled
    public static String savePdfFile(String billPrintNumber, Id workOrderId) {
        try {
            System.debug('savePdfFile called with billPrintNumber: ' + billPrintNumber + ', workOrderId: ' + workOrderId);
            
            String fileTitle = 'Bill_' + billPrintNumber;
            // --- 1. Check if the file already exists in Salesforce ---
            List<ContentVersion> existingVersions = [
                SELECT Id, ContentDocumentId 
                FROM ContentVersion 
                WHERE Title = :fileTitle AND IsLatest = true
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];

            ContentVersion cvToDistribute;
            Boolean isNewFile = false;

            if (!existingVersions.isEmpty()) {
                // If the file exists, we'll use it.
                cvToDistribute = existingVersions[0];
                
                // Boolean resultPdf=getBillPdf(billPrintNumber,workOrderId);

                // if(!resultPdf){
                //     return 'false';
                // }
                
                System.debug('Using existing file: ' + cvToDistribute.Id);
            } else {
                // --- 2. If it doesn't exist, fetch it from the external service ---
                System.debug('Fetching PDF from external service: ' + System.label.Get_BIll_PDF + billPrintNumber);
                
                Http http = new Http();
                HttpRequest request = new HttpRequest();
                request.setEndpoint(System.label.Get_BIll_PDF + EncodingUtil.urlEncode(billPrintNumber, 'UTF-8'));
                String endpoint = System.label.Get_BIll_PDF + EncodingUtil.urlEncode(billPrintNumber, 'UTF-8');
                request.setMethod('GET');
                if(Middleware_Token_Control__mdt.getInstance('rTGetPDF').Token__c=='true'){
                    String token = BillsCallout.getAccessToken();
                    System.debug('token: '+ token);
                    request.setHeader('Authorization', 'Bearer ' + token);
                }
                request.setTimeout(120000);

                HttpResponse response = http.send(request);
                System.debug('response: '+response);
                System.debug('HTTP Response Status: ' + response.getStatusCode());

                String responseBody = response.getBody();
                if (responseBody != null && responseBody.length() > 13107) {
                    responseBody = responseBody.substring(0, 13107);
                }

                System.debug('responseBody: '+responseBody);

                Integration_Log__c log = new Integration_Log__c(
                    Log_Name__c = 'Bill Print Request Call',
                    Endpoint_URL__c = endpoint,
                    Status_Code__c = response.getStatusCode(),
                    Request_Body__c = String.valueOf(request),
                    Response_Body__c = responseBody
                );
                insert log;

                if (response.getStatusCode() == 200) {
                    String base64Data = response.getBody();
                    System.debug('PDF fetched successfully, data length: ' + (base64Data != null ? base64Data.length() : 0));
                    // Boolean resultPdf=getBillPdf(billPrintNumber,workOrderId);

                    // if(!resultPdf){
                    //     return 'false';
                    // }

                    // Create the new file version
                    ContentVersion newCv = new ContentVersion();
                    newCv.Title = fileTitle;
                    newCv.PathOnClient = fileTitle + '.pdf';
                    newCv.VersionData = EncodingUtil.base64Decode(base64Data);
                    insert newCv;
                    System.debug('New ContentVersion created: ' + newCv.Id);

                    // We need to re-query to get the ContentDocumentId for the next step
                    cvToDistribute = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :newCv.Id];
                    isNewFile = true;
                } else {
                    System.debug('Failed to fetch PDF: ' + response.getStatus());
                    AS_ErrorLogger.log('RTVisitExecutionController', 'savePdfFile', 'Network/Server issue: Unable to open the Bill due. Please try after sometime.' + response.getStatus() + ' - ' + response.getBody(), workOrderId);
                    // throw new AuraHandledException('Network/Server issue: Unable to open the Bill due. Please try after sometime.');
                }
            }

            // --- 3. Link the file to the Work Order (ALWAYS do this if workOrderId is provided) ---
            if (workOrderId != null) {
                // Check if link already exists
                List<ContentDocumentLink> existingLinks = [
                    SELECT Id 
                    FROM ContentDocumentLink 
                    WHERE ContentDocumentId = :cvToDistribute.ContentDocumentId 
                    AND LinkedEntityId = :workOrderId
                    LIMIT 1
                ];

                // List<Billing__c> lstBill = [SELECT Id, Document_Date__c 
                //                     FROM Billing__c 
                //                     WHERE Print_Doc_Number__c =: billPrintNumber
                //                         AND Document_Date__c != null];  
                
                // if(!lstBill.isEmpty()){
                //     update new WorkOrder(Id = workOrderId, Bill_Date__c = lstBill.get(0).Document_Date__c);
                // }
                if (existingLinks.isEmpty()) {
                    // Create link to Work Order
                    ContentDocumentLink workOrderLink = new ContentDocumentLink(
                        ContentDocumentId = cvToDistribute.ContentDocumentId,
                        LinkedEntityId = workOrderId,
                        ShareType = 'V',
                        Visibility = 'AllUsers'
                    );
                    insert workOrderLink;
                }

                
            }

            // 4. Now check for an existing PUBLIC LINK for our file ---
            List<ContentDistribution> existingDistributions = [
                SELECT DistributionPublicUrl, ExpiryDate 
                FROM ContentDistribution 
                WHERE ContentVersionId = :cvToDistribute.Id
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];

            // Check if a link exists and hasn't expired.
            if (!existingDistributions.isEmpty() && (existingDistributions[0].ExpiryDate == null || existingDistributions[0].ExpiryDate > System.now())) {
                // A valid, non-expired link exists. Return it.
                System.debug('Using existing distribution: ' + existingDistributions[0].DistributionPublicUrl);
                Boolean resultPdf=getBillPdf(billPrintNumber,workOrderId,existingDistributions[0].DistributionPublicUrl);
                return existingDistributions[0].DistributionPublicUrl;
            } else {
                // --- 5. If no valid link exists, create a new one ---
                ContentDistribution newDist = new ContentDistribution();
                newDist.Name = fileTitle;
                newDist.ContentVersionId = cvToDistribute.Id;
                newDist.PreferencesAllowOriginalDownload = true;
                newDist.PreferencesAllowPDFDownload = true;
                newDist.PreferencesAllowViewInBrowser = true;
                insert newDist;
                System.debug('New ContentDistribution created: ' + newDist.Id);

                // Query for the newly created link to return the URL
                ContentDistribution result = [
                    SELECT DistributionPublicUrl 
                    FROM ContentDistribution 
                    WHERE Id = :newDist.Id
                ];
                System.debug('New distribution URL: ' + result.DistributionPublicUrl);
                Boolean resultPdf=getBillPdf(billPrintNumber,workOrderId,result.DistributionPublicUrl);
                return result.DistributionPublicUrl;
            }
        } catch (Exception ex) {
            System.debug('Exception in savePdfFile: ' + ex.getMessage() + ' at line ' + ex.getLineNumber());
            System.debug('Stack trace: ' + ex.getStackTraceString());
            AS_ErrorLogger.log('RTVisitExecutionController', 'savePdfFile', ex, workOrderId);
            return null;
            //throw new AuraHandledException('Error processing PDF: ' + ex.getMessage());
        }
    }

    //@future(callout=true)
    public static Boolean getBillPdf(String billPrintNumber, String workOrderId,String pdfUrl) {
        Boolean dataPresent=true;
        try {
            

        //     Case 2: Data present but PDF URL is blank
        //    String pdfUrl = resp.data[0];
        //     if (String.isBlank(pdfUrl)) {
        //         throw new AuraHandledException('PDF URL is missing for Bill: ' + billPrintNumber);
        //     }
                //Load existing JSON from WorkOrder
                WorkOrder wo = [
                    SELECT Id, Bill_URL__c
                    FROM WorkOrder
                    WHERE Id = :workOrderId
                    LIMIT 1
                ];

                // Parse existing JSON into a List<Map<String, String>>
                List<Object> rawList = new List<Object>();
                Map<String, String> newEntry = new Map<String, String>();
                if (String.isNotBlank(wo.Bill_URL__c)) {
                    try {
                        rawList = (List<Object>) JSON.deserializeUntyped(wo.Bill_URL__c);
                        for(Object url : rawList){
                            Map<String, Object> urlMap = (Map<String, Object>) url;

                            urlMap.put(billPrintNumber,pdfUrl);
                            // if (urlMap.containsKey(billNumber)) {
                            //     billUrl = (String) urlMap.get(billNumber);
                            //     break;
                            // }    
                        }
                    } catch (Exception e) {
                        System.debug('Failed to parse existing Bill_URL__c JSON: ' + e.getMessage());
                        rawList = new List<Object>();
                    }
                }else{
                    newEntry.put(billPrintNumber, pdfUrl);
                    rawList.add(newEntry);
                }

                // Save back JSON
                update new WorkOrder(
                    Id = wo.Id,
                    Bill_URL__c = JSON.serialize(rawList)
                );
                return dataPresent;
                   
        } catch (Exception e) {
            AS_ErrorLogger.log('RTVisitExecutionController', 'getBillPdf', e, workOrderId);
            System.debug('Error in getBillPdf: ' + e.getMessage());
            dataPresent=false;
            return dataPresent;
        }
    }
    public class BillWrapper {
        @AuraEnabled public String id; 
        @AuraEnabled public String printDocNumber;      // OPBEL - Document Number
        @AuraEnabled public String paymentMode;         // Z_LOCATION
        @AuraEnabled public String transactionId;       // CHCKN
        @AuraEnabled public String postingDate;         // Z_CH_REC_DATE
        @AuraEnabled public String paymentAmount;       // PSWBT
        @AuraEnabled public String sourceOfPayment;     // ZSOP
        @AuraEnabled public String bankName;            // Z_BANK_NAME
        
    }

    /**
     * Parse Billing API response JSON into BillWrapper objects.
     */
    private static List<BillWrapper> parseBillingResponse(String jsonResponse) {
        List<BillWrapper> bills = new List<BillWrapper>();

        try {
            Map<String, Object> responseMap = 
                (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
            System.debug('API response keys: ' + responseMap.keySet());

            if (responseMap.containsKey('sapData')) {
                Object sapData = responseMap.get('sapData');

                if (sapData instanceof List<Object>) {
                    List<Object> billList = (List<Object>) sapData;
                    System.debug('Found ' + billList.size() + ' bills in sapData');

                    Integer index = 0;
                    for (Object billObj : billList) {
                        Map<String, Object> billMap = (Map<String, Object>) billObj;

                        BillWrapper bw = new BillWrapper();

                        bw.printDocNumber      = billMap.containsKey('OPBEL') 
                                               ? String.valueOf(billMap.get('OPBEL')) 
                                               : '';
                        bw.paymentMode         = billMap.containsKey('Z_LOCATION') 
                                               ? String.valueOf(billMap.get('Z_LOCATION')) 
                                               : '';
                        bw.transactionId       = billMap.containsKey('CHCKN') 
                                               ? String.valueOf(billMap.get('CHCKN')) 
                                               : '';
                        bw.postingDate         = billMap.containsKey('Z_CH_REC_DATE') 
                                               ? String.valueOf(billMap.get('Z_CH_REC_DATE')) 
                                               : '';
                        bw.paymentAmount       = billMap.containsKey('PSWBT') 
                                               ? String.valueOf(billMap.get('PSWBT')).replaceAll('[-\\s]', '') 
                                               : '';
                        bw.sourceOfPayment     = billMap.containsKey('ZSOP') 
                                               ? String.valueOf(billMap.get('ZSOP')) 
                                               : '';
                        bw.bankName            = billMap.containsKey('Z_BANK_NAME') 
                                               ? String.valueOf(billMap.get('Z_BANK_NAME')) 
                                               : '';

                        // Amount field with fallback
                        // try {
                        //     if (billMap.containsKey('TOTAL_AMNT') && billMap.get('TOTAL_AMNT') != null) {
                        //         bw.dueAmount = Decimal.valueOf(String.valueOf(billMap.get('TOTAL_AMNT')));
                        //     } else if (billMap.containsKey('PSWBT') && billMap.get('PSWBT') != null) {
                        //         bw.dueAmount = Decimal.valueOf(String.valueOf(billMap.get('PSWBT')));
                        //     } else {
                        //         bw.dueAmount = 0;
                        //     }
                        // } catch (Exception innerEx) {
                        //     bw.dueAmount = 0;
                        //     AS_ErrorLogger.log('RTVisitExecutionController', 'parseBillingResponse', innerEx, null);
                        // }

                        bw.id = 'api-bill-' + index;
                        bills.add(bw);
                        index++;
                    }
                }
            }
        } catch (Exception ex) {
            System.debug('Error parsing billing response: ' + ex.getMessage());
            AS_ErrorLogger.log('RTVisitExecutionController', 'parseBillingResponse', ex, null);
        }

        return bills;
    }

    /**
     * Fetch billing history from API for given by Business Partner.
     */
    private static List<BillWrapper> getBillingHistoryFromAPI(String bpNumber) {
        try {
            // Build endpoint from custom label
            String endpointTemplate = System.Label.BillingAPI_Endpoint;
            String endpoint = String.format(endpointTemplate, 
                                new String[]{ EncodingUtil.urlEncode(bpNumber, 'UTF-8') });

            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            if(Middleware_Token_Control__mdt.getInstance('rTPaymentHistory').Token__c=='true'){
                String token = BillsCallout.getAccessToken();
                System.debug('token: '+ token);
                req.setHeader('Authorization', 'Bearer ' + token);
            }
            req.setTimeout(120000);
            System.debug('getBillingHistoryFromAPI: '+req);
            Http http = new Http();
            HttpResponse res = http.send(req);

            Integration_Log__c log = new Integration_Log__c();
            log.Log_Name__c = 'Payment History Request Call';
            log.Endpoint_URL__c = endpoint;
            log.Status_Code__c = res.getStatusCode();
            log.Request_Body__c = String.valueOf(req);
            log.Response_Body__c = res.getBody();
            log.Related_Record_Id__c = bpNumber;
            insert log;

            if (res.getStatusCode() == 200) {
                Map<String, Object> responseMap = 
                    (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

                if (responseMap.containsKey('error')) {
                    System.debug('API returned an error: ' + responseMap.get('error'));
                    System.debug('Message: ' + responseMap.get('message'));
                    return new List<BillWrapper>();
                }

                return parseBillingResponse(res.getBody());
            }

            return new List<BillWrapper>();

        } catch (Exception ex) {
            System.debug('Error in getBillingHistoryFromAPI: ' + ex.getMessage());
            System.debug('Exception Line Number: '+ ex.getLineNumber());
            AS_ErrorLogger.log('RTVisitExecutionController', 'getBillingHistoryFromAPI', ex, bpNumber);
            return new List<BillWrapper>();
        }
    }

    @AuraEnabled
    public static List<BillWrapper> fetchPaymentByBP(String bpNumber) {
        try {
            return getBillingHistoryFromAPI(bpNumber);
        } catch (Exception ex) {
            System.debug('Error in fetchPaymentByBP: ' + ex.getMessage());
            AS_ErrorLogger.log('RTVisitExecutionController', 'fetchPaymentByBP', ex.getMessage(), bpNumber);
            return new List<BillWrapper>();
        }
    }


    // Fetch cheque bounce history.
    @AuraEnabled
    public static List<ChequeBounceWrapper> fetchChequeBounceByBP(String bpNumber) {
        try {
            return getChequeBounceHistoryFromAPI(bpNumber);
        } catch (Exception ex) {
            System.debug('Error in fetchChequeBounceByBP: ' + ex.getMessage());
            return new List<ChequeBounceWrapper>();
        }
    }


    /**
     * Fetch cheque bounce history from API for given Business Partner.
     */
    private static List<ChequeBounceWrapper> getChequeBounceHistoryFromAPI(String bpNumber) {


        
            //Build endpoint from custom label
            String endpointTemplate = System.Label.ChronologyAPI_Endpoint;
            String endpoint = String.format(endpointTemplate, 
                                new String[]{ EncodingUtil.urlEncode(bpNumber, 'UTF-8') });
            endpoint = endpoint + bpNumber;
            System.debug('Endpoint====>'+endpoint);

            HttpRequest req = new HttpRequest();
            req.setHeader('Content-Type', 'application/json');
            req.setEndpoint(endpoint);
            
            req.setMethod('GET');
            if(Middleware_Token_Control__mdt.getInstance('rTCheckBounce').Token__c=='true'){
                String token = BillsCallout.getAccessToken();
                System.debug('token: '+ token);
                req.setHeader('Authorization', 'Bearer ' + token);
            }
            req.setTimeout(120000);

            Http http = new Http();

            try {
                HttpResponse res = http.send(req);
                String responseBody = res.getBody();
                if (responseBody != null && responseBody.length() > 131072) {
                    responseBody = responseBody.substring(0, 131072);
                }
                Integration_Log__c log = new Integration_Log__c(
                    Log_Name__c = 'Cheque Bounce Request Call',
                    Endpoint_URL__c = endpoint,
                    Status_Code__c = res.getStatusCode(),
                    Request_Body__c = String.valueOf(req),
                    Response_Body__c = responseBody,
                    Related_Record_Id__c = bpNumber
                );
                insert log;

                if (res.getStatusCode() == 200) {
                    Map<String, Object> responseMap = 
                        (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

                    if (responseMap.containsKey('error')) {
                        System.debug('API returned an error: ' + responseMap.get('error'));
                        System.debug('Message: ' + responseMap.get('message'));
                        return new List<ChequeBounceWrapper>();
                    }
                    System.debug('Status code: ' + res.getStatusCode());
                    System.debug('Response Body: ' + res.getBody());

                    List<ChequeBounceWrapper> chequeBounceWrapList = new List<ChequeBounceWrapper>();
                    if(!responseMap.containsKey('sapData') || responseMap.get('sapData') == null){
                        return new List<ChequeBounceWrapper>();
                    }

                    List<Object> sapDataList = (List<Object>) responseMap.get('sapData');

                    if(sapDataList.isEmpty()) return new List<ChequeBounceWrapper>();

                    for (Object obj : sapDataList) {
                        Map<String, Object> row = (Map<String, Object>) obj;
                        ChequeBounceWrapper cb = new ChequeBounceWrapper();

                        if (row.get('NET_DATE') != null && String.valueOf(row.get('NET_DATE')).trim() != '') {
                            cb.dueDate = Date.valueOf((String)row.get('NET_DATE'));
                        }

                        cb.currentBalance = (Decimal) row.get('AMOUNT');

                        cb.postingDate = (String) row.get('PDATE');

                        cb.documentDate = (String) row.get('DDATE');

                        cb.chequeNumber = (String) row.get('CHCKN');

                        cb.chequeDate = (String) row.get('Z_CH_DATE');

                        cb.chequeRecDate = (String) row.get('Z_CH_REC_DATE');

                        cb.returnReason = (String) row.get('RTEXT');

                        chequeBounceWrapList.add(cb);

                    }

                    //Filter cheque bounce history to only those with return reason
                    List<ChequeBounceWrapper> filteredList = new List<ChequeBounceWrapper>();

                    for (ChequeBounceWrapper cb : chequeBounceWrapList) {
                        if (cb.returnReason != null && cb.returnReason.trim() != '') {
                            filteredList.add(cb);
                        }
                    }

                    chequeBounceWrapList = filteredList;

                    System.debug('chequeBounceWrapList: ' + chequeBounceWrapList);
                    chequeBounceWrapList.sort(new SortByDueDate());

                    List<ChequeBounceWrapper> top3chequeBounceWrapList = new List<ChequeBounceWrapper>();

                    if(chequeBounceWrapList.size() < 3){
                        return chequeBounceWrapList;
                    }

                    for (Integer i = 0; i < 3;i++){
                        top3chequeBounceWrapList.add(chequeBounceWrapList.get(i));
                    }

                    return top3chequeBounceWrapList;
                }

                return new List<ChequeBounceWrapper>();

            } catch (Exception ex) {
            System.debug('Exception Line Number: '+ex.getLineNumber());
            System.debug('Error in getChequeBounceHistoryFromAPI: ' + ex.getMessage());
            return null;
        }
    }

    public class ChequeBounceWrapper {

        @AuraEnabled public Date dueDate;
        @AuraEnabled public Decimal currentBalance;
        @AuraEnabled public String postingDate;      
        @AuraEnabled public String documentDate;         
        @AuraEnabled public String chequeNumber;      
        @AuraEnabled public String chequeDate;         
        @AuraEnabled public String chequeRecDate;
        @AuraEnabled public String returnReason;
    }

    public class SortByDueDate implements Comparator<ChequeBounceWrapper> {
        public Integer compare(ChequeBounceWrapper a, ChequeBounceWrapper b) {
            if (a.dueDate == null && b.dueDate == null) return 0;
            if (a.dueDate == null) return 1;  // null goes last
            if (b.dueDate == null) return -1;

            if (a.dueDate > b.dueDate) {
                return -1;
            } else if (a.dueDate < b.dueDate) {
                return 1;
            } else {
                return 0;
            }
        }
    }


    @AuraEnabled
    public static SAP_Response fetchBillByBP(String bpNumber, String fromDate, String toDate) {
        try {
            String url = System.Label.BillAPI_Endpoint + EncodingUtil.urlEncode(bpNumber, 'UTF-8') + '&fromDate=' + EncodingUtil.urlEncode(fromDate, 'UTF-8') + '&toDate=' + EncodingUtil.urlEncode(toDate, 'UTF-8');
            System.debug('url: '+url);
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(url);
            request.setMethod('GET');
            if(Middleware_Token_Control__mdt.getInstance('rTBillHistory').Token__c=='true'){
                String token = BillsCallout.getAccessToken();
                System.debug('token: '+ token);
                request.setHeader('Authorization', 'Bearer ' + token);
            }
            request.setTimeout(120000); 

            HttpResponse response = http.send(request);

            Integration_Log__c log = new Integration_Log__c();
            log.Log_Name__c = 'Bill History Request Call';
            log.Endpoint_URL__c = url;
            log.Status_Code__c = response.getStatusCode();
            log.Request_Body__c = String.valueOf(request);
            log.Response_Body__c = response.getBody();
            log.Related_Record_Id__c = bpNumber;
            insert log;
            
            if (response.getStatusCode() == 200) {
                return (SAP_Response) JSON.deserialize(response.getBody(), SAP_Response.class);
            }else{
                throw new AuraHandledException('Failed to fetch Bill data: ' + response.getStatus());
            }
        } catch (Exception ex) {
            AS_ErrorLogger.log('RTVisitExecutionController', 'fetchBillByBP', ex, bpNumber);
            return null;
        }
    }

    public class SAP_Response {
        @AuraEnabled public String salesforceStatus;
        @AuraEnabled public String bpId;
        @AuraEnabled public List<SAP_Data> sapData;
    }

    public class SAP_Data {
        @AuraEnabled public String OPBEL { get; set; }          // Document number
        @AuraEnabled public String BELNR { get; set; }          // Invoice number
        @AuraEnabled public String PARTNER { get; set; }        // Business partner
        @AuraEnabled public String VKONT { get; set; }          // Contract account
        @AuraEnabled public String VERTRAG { get; set; }        // Contract
        @AuraEnabled public String PORTION { get; set; }        // Portion
        @AuraEnabled public String ABLEINH { get; set; }        // Division/Unit
        @AuraEnabled public String ABRVORG { get; set; }        // Billing type
        @AuraEnabled public Date BUDAT { get; set; }            // Posting date
        @AuraEnabled public Date BLDAT { get; set; }            // Document date
        @AuraEnabled public Date BEGABRPE { get; set; }         // Billing period start
        @AuraEnabled public Date ENDABRPE { get; set; }         // Billing period end
        @AuraEnabled public Decimal TOTAL_AMNT { get; set; }    // Total amount
        @AuraEnabled public Date FAEDN { get; set; }            // Due date
        @AuraEnabled public String ZZ_TAXINVNO { get; set; }    // Tax invoice number
    }
}