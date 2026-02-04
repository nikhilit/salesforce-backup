/**
* @File Name : AS_PaymentModuleHandler.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : July 10, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | July 10, 2025 |   | Initial Version
**/
public without sharing class AS_PaymentModuleHandler { 
   
    @AuraEnabled 
    public static AS_PaymentStateWrapper getWorkOrderPaymentState(Id workOrderId) {

        try {
            WorkOrder wo = [SELECT Id, P2PRequestId__c, Transaction_Id__c, Due_Amount__c, WorkType.Name,
                                   QR_Code_Txn_Id__c, QR_Code_URI__c, Amount_Received__c,
                                   Account.Inv_No__c, CA_Number__c, Customer_Full_Name__c, Account.BP_Number__c,
                                   Payment_Remark__c, Disable_Amount__c, Invoice__c, Customer_BP_Number__c
                              FROM WorkOrder 
                             WHERE Id = :workOrderId 
                             LIMIT 1];

            AS_PaymentStateWrapper state = new AS_PaymentStateWrapper();
            state.hasP2PRequest = String.isNotBlank(wo.P2PRequestId__c);
            state.hasTransaction = String.isNotBlank(wo.Transaction_Id__c);
            state.qrCodeURI = wo.QR_Code_URI__c == null ? '' : wo.QR_Code_URI__c;
            state.transactionId = (wo.Transaction_Id__c == null ? (wo.QR_Code_Txn_Id__c == null ? '' : wo.QR_Code_Txn_Id__c) : wo.Transaction_Id__c);
            state.amountTotal = (wo.Due_Amount__c == null ? 0 : wo.Due_Amount__c);
            state.amountPaid = (wo.Amount_Received__c == null ? 0 : wo.Amount_Received__c);
            state.workType = wo.WorkType.Name;
            state.caNumber = wo.CA_Number__c;
            state.bpNumber = (wo.Customer_BP_Number__c == null ? wo.Account.BP_Number__c : wo.Customer_BP_Number__c);
            state.invNumber = (wo.Invoice__c == null ? wo.Account.Inv_No__c : wo.Invoice__c);
            state.customerName = wo.Customer_Full_Name__c;
            state.isRandomVisit = wo.Payment_Remark__c == 'Random Payment';
            state.isPaymentValidationDisabled = wo.Disable_Amount__c;

            return state;

        } catch (Exception e) {
            AS_ErrorLogger.log('AS_PaymentModuleHandler', 'getWorkOrderPaymentState', e, workOrderId);
            return null;
        }
    }

    @AuraEnabled
    public static Object payRequest(Id workOrderId, String payMode, Decimal amtToPay, String payType, String payRemark) {

        Object result;

        if(payMode == 'M-POS'){
            result = AS_RazorPayPOSModule.payViaPOS(workOrderId, amtToPay, payType, payRemark);
        }else if(payMode == 'QR Code'){
            result = AS_RazorPayQRCodeModule.payViaQRCode(workOrderId, amtToPay, payType, payRemark);
        }
        return result;
    }

    @AuraEnabled
    public static Object checkStatus(Id workOrderId, String payMode) {

        Object result;

        if(payMode == 'M-POS'){
            result = AS_RazorPayPOSModule.checkStatusPOS(workOrderId);
        }else if(payMode == 'QR Code'){
            result = AS_RazorPayQRCodeModule.checkStatusQRCode(workOrderId);
        }
        return result;
    }

    @AuraEnabled
    public static Boolean cancelRequest(Id workOrderId) {
        Boolean paymentReset = false;
        List<WorkOrder> lstWorkOrder = [SELECT Id, P2PRequestId__c, QR_Code_Txn_Id__c, QR_Code_URI__c 
                                          FROM WorkOrder 
                                         WHERE Id =: workOrderId LIMIT 1];

        if(!lstWorkOrder.isEmpty()){
            lstWorkOrder.get(0).P2PRequestId__c = null;
            lstWorkOrder.get(0).QR_Code_Txn_Id__c = null;
            lstWorkOrder.get(0).QR_Code_URI__c = null;
            
            update lstWorkOrder;
            paymentReset = true;
        }
        return paymentReset;
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
            AS_ErrorLogger.log('AS_PaymentModuleHandler', 'updateGeoLocation', e, workOrderId);
        }
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
 
    public class AS_PaymentStateWrapper {
        @AuraEnabled public Boolean hasP2PRequest;
        @AuraEnabled public Boolean hasTransaction;
        @AuraEnabled public String transactionId;
        @AuraEnabled public String qrCodeURI;
        @AuraEnabled public Decimal amountPaid;
        @AuraEnabled public Decimal amountTotal;
        @AuraEnabled public String workType;
        @AuraEnabled public String caNumber;
        @AuraEnabled public String bpNumber;
        @AuraEnabled public String invNumber;
        @AuraEnabled public String customerName;
        @AuraEnabled public Boolean isRandomVisit;
        @AuraEnabled public Boolean isPaymentValidationDisabled;
    }
}