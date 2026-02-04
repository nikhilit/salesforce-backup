/**
* @File Name : AS_RazorPayPOSModule.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : July 11, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | July 11, 2025 |   | Initial Version
**/
  
public class AS_RazorPayPOSModule {  

	// Get environment
    public static Boolean isRunningInASandbox = String.valueOf(URL.getOrgDomainUrl()).contains('sandbox');

	@AuraEnabled
    public static AS_RazorPayPOSResponseWrapper payViaPOS(Id workOrderId, Decimal amtToPay, String payType, String payRemark) { 

        AS_RazorPayPOSResponseWrapper res = new AS_RazorPayPOSResponseWrapper();

        try {

            User currentUser = [SELECT Id, Device_Id__c FROM User WHERE Id = :UserInfo.getUserId()];
            
            if(currentUser == null || (currentUser != null && currentUser.Device_Id__c == null)){
                res.success = false;
                res.message = 'Device Id is missing on User.';

                return res;
            }

            WorkOrder wo = [SELECT Id, AccountId, Due_Amount__c, Account.Phone, CA_Number__c,
                                   Customer_Full_Name__c, Agent__r.RelatedRecord.Name,
                                   Account.CA_Number__c, Account.BP_Number__c, Customer_BP_Number__c,
                                   New_Mobile_Number__c
							  FROM WorkOrder 
							 WHERE Id = :workOrderId 
							 LIMIT 1];

            // Get Metadata
            API_Setting__mdt settings = [SELECT Stage_EndPoint__c, Stage_Header__c, Prod_EndPoint__c, Prod_Header__c
                						   FROM API_Setting__mdt 
                						  WHERE DeveloperName = 'RazorPayPOSRequest' 
                						  LIMIT 1];

            String endpoint = isRunningInASandbox ? settings.Stage_EndPoint__c : settings.Prod_EndPoint__c;
            String headerJson = isRunningInASandbox ? settings.Stage_Header__c : settings.Prod_Header__c;

            RequestPOSHeaderWrapper headers = (RequestPOSHeaderWrapper) JSON.deserialize(headerJson, RequestPOSHeaderWrapper.class);

            // Prepare Request
            AS_RazorPayRequestWrapper req = new AS_RazorPayRequestWrapper();
            req.username = wo.Agent__r.RelatedRecord.Name;
            req.appKey = headers.appKey;
            req.amount = (amtToPay != null ? String.valueOf(amtToPay) : String.valueOf(wo.Due_Amount__c));
            req.customerMobileNumber = wo.New_Mobile_Number__c == null ? wo.Account.Phone : wo.New_Mobile_Number__c; 
            req.externalRefNumber = AS_RazorPayQRCodeModule.generateRandomAlphanumericCustom(15);
            req.externalRefNumber2 = wo.CA_Number__c == null ? wo.Account.CA_Number__c : wo.CA_Number__c;
            req.externalRefNumber3 = wo.Customer_BP_Number__c == null ? wo.Account.BP_Number__c : wo.Customer_BP_Number__c;
            req.externalRefNumber4 = 'Collect360'; 
            req.mode = 'CARD';
			req.pushTo = new AS_RazorPayRequestWrapper.PushTo(currentUser == null ? headers.deviceId : currentUser.Device_Id__c);
            
            HttpResponse response = doRequest(endpoint, JSON.serialize(req));


            AS_RazorPayPOSResponseWrapper rPayRes = (AS_RazorPayPOSResponseWrapper) JSON.deserialize(response.getBody(), AS_RazorPayPOSResponseWrapper.class);
            
            //String resSting = '{"p2pRequestId":"1231241312","success":true,"messageCode":null,"message":"passed","errorCode":"","errorMessage":"","realCode":"","apiMessageTitle":null,"apiMessage":null,"apiMessageText":null,"apiWarning":null}';
            //AS_RazorPayPOSResponseWrapper rPayRes = (AS_RazorPayPOSResponseWrapper) JSON.deserialize(resSting, AS_RazorPayPOSResponseWrapper.class);

            AS_APIRequestLogger.logRequestResponse(workOrderId, endpoint, req, response, 'RazorPayPOS Request Call');

            if (response.getStatusCode() == 200 && rPayRes.success) {
                WorkOrder woToUpdate = new WorkOrder(
                    Id = workOrderId, 
                    P2PRequestId__c = rPayRes.p2pRequestId,
                    Payment_Type__c = payType,
                    Pay_Remark__c = payRemark
                );
                update woToUpdate;

                res.success = true;
                res.message = 'Payment request is successfully made to POS machine. Please collect the payment.';
            } else {
                res.success = false;
                res.message = rPayRes.errorMessage != null ? rPayRes.errorMessage : 'Failed to send payment request.';
            } 

        } catch (Exception ex) {
            AS_ErrorLogger.log('AS_RazorPayPOSModule', 'payViaPOS', ex, workOrderId);
        }
        return res;
    }

    @AuraEnabled
    public static AS_RazorPayPOSStatusWrapper checkStatusPOS(Id workOrderId) {
        AS_RazorPayPOSStatusWrapper responseWrapper = new AS_RazorPayPOSStatusWrapper();
        try {
            WorkOrder wo = [SELECT Id, P2PRequestId__c, Due_Amount__c, Agent__r.RelatedRecord.Name,
                                   Check_In_Location__latitude__s, Check_In_Location__longitude__s
                              FROM WorkOrder 
                             WHERE Id = :workOrderId LIMIT 1];
            if (String.isBlank(wo.P2PRequestId__c)) {
                responseWrapper.success = false;
                responseWrapper.message = 'No P2P Request Id found for this WorkOrder.';
                return responseWrapper;
            }

            List<ServiceAppointment> relatedSAs = [
                SELECT Id, Status, Appointment_Type__c
                  FROM ServiceAppointment
                 WHERE ParentRecordId = :wo.Id
              ORDER BY CreatedDate DESC
                 LIMIT 1
            ];

            // Fetch Metadata
            API_Setting__mdt meta = [SELECT Stage_EndPoint__c, Stage_Header__c, Prod_EndPoint__c, Prod_Header__c, Status__c
                                       FROM API_Setting__mdt 
                                      WHERE DeveloperName = 'RazorPayPOSStatus' 
                                      LIMIT 1];

            String endpoint = isRunningInASandbox ? meta.Stage_EndPoint__c : meta.Prod_EndPoint__c;
            String headerJson = isRunningInASandbox ? meta.Stage_Header__c : meta.Prod_Header__c;

            StatusPOSHeaderWrapper headers = (StatusPOSHeaderWrapper) JSON.deserialize(headerJson, StatusPOSHeaderWrapper.class);
            headers.origP2pRequestId = wo.P2PRequestId__c;
            headers.username = wo.Agent__r.RelatedRecord.Name;

            AS_RazorPayStatusReqWrapper statusRequest = new AS_RazorPayStatusReqWrapper(headers.username, headers.appKey, headers.origP2pRequestId);
            HttpResponse response = doRequest(endpoint, JSON.serialize(statusRequest));
            
            AS_RazorPayPOSStatusWrapper statusResponse = (AS_RazorPayPOSStatusWrapper) JSON.deserialize(response.getBody(), AS_RazorPayPOSStatusWrapper.class);

            //String fakeSuccRes = '{"amount":"1200","success":true,"message":"Transaction done on device, Please look at Txn status.","txnId":"250709120536516E010081597","paymentMode":"CARD","abstractPaymentStatus":"SUCCESS"}';
            //AS_RazorPayPOSStatusWrapper statusResponse = (AS_RazorPayPOSStatusWrapper) JSON.deserialize(fakeSuccRes, AS_RazorPayPOSStatusWrapper.class);

            AS_APIRequestLogger.logRequestResponse(workOrderId, endpoint, statusRequest, response, 'RazorPayPOS Status Call');

            if (response.getStatusCode() == 200 && statusResponse.success && statusResponse.status == meta.Status__c) {
                responseWrapper.success = true;
                responseWrapper.message = statusResponse.message;
                responseWrapper.txnId = statusResponse.txnId;
                responseWrapper.amount = statusResponse.amount;

                // Update workorder with txnId
                update new WorkOrder(
                    Id = workOrderId, 
                    Transaction_Id__c = statusResponse.txnId, 
                    //Status = 'Completed',
                    //Appointment_Status__c = 'Completed',
                    //Due_Amount__c = wo.Due_Amount__c - (Decimal) statusResponse.amount,
                    Amount_Received__c = (Decimal) statusResponse.amount,
                    Payment_Mode__c = 'M-POS',
                    Payment_Date__c = String.valueOf(Date.today().format()),
                    Check_Out_Date_Time__c = Datetime.now(),
                    Check_Out_Location__Latitude__s = wo.Check_In_Location__Latitude__s,
                    Check_Out_Location__Longitude__s = wo.Check_In_Location__Longitude__s,
                    Status = 'Completed',
                    Appointment_Status__c = 'Completed'
                );

                if (!relatedSAs.isEmpty()) {
                    ServiceAppointment sa = relatedSAs[0];
                    sa.Status = 'Completed'; 
                    sa.Appointment_Type__c = 'Completed';

                    update relatedSAs;
                }

                //updateWorkStepStatus(workOrderId, 'Collect Payment');
                updateWorkStepStatuses(workOrderId, new List<String>{'Collect Payment', 'Check Out'});

            } else {
                responseWrapper.success = false;
                responseWrapper.message = statusResponse.message != null ? statusResponse.message : 'Status check failed.';
            }
        } catch (Exception e) {
            AS_ErrorLogger.log('AS_RazorPayPOSModule', 'checkStatusPOS', e, workOrderId);
        }

        return responseWrapper;
    }

    public static void updateWorkStepStatus(Id workOrderId, String name) {
        List<WorkStep> steps = [SELECT Id, Status FROM WorkStep WHERE ParentRecordId = :workOrderId AND Name = :name LIMIT 1];
        
        if (!steps.isEmpty()) {
            WorkStep ws = steps[0];
            ws.Status = 'Completed';
            update ws;
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

    private static HttpResponse doRequest(String endpoint, String req) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setBody(req);
        Http http = new Http();

        return http.send(request);
    }

	public class RequestPOSHeaderWrapper {
		public String username;
		public String appKey;
		public String externalRefNumber;
		public String deviceId;
	}

    public class StatusPOSHeaderWrapper {
        public String username;
        public String appKey;
        public String origP2pRequestId;
    }

    public class AS_RazorPayPOSStatusWrapper {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
        @AuraEnabled public String txnId;
        @AuraEnabled public String paymentMode;
        @AuraEnabled public String status;
        @AuraEnabled public String abstractPaymentStatus;
        @AuraEnabled public Decimal amount;
    }

    public class AS_RazorPayPOSResponseWrapper {
	    @AuraEnabled public Boolean success;
        @AuraEnabled public String messageCode;
        @AuraEnabled public String message;
        @AuraEnabled public String errorCode;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public String apiMessageText;
        @AuraEnabled public String apiMessage;
        @AuraEnabled public String apiWarning;
        @AuraEnabled public String p2pRequestId;
    }
}