/**
* @File Name : AS_RazorPayQRCodeModule.cls
* @Description :
* @Author :
* @Last Modified By : Shashank.shekhar@appstrail.com
* @Last Modified On : 07-24-2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | July 11, 2025 |   | Initial Version
**/ 

public class AS_RazorPayQRCodeModule {  
	// Get environment
    public static Boolean isRunningInASandbox = String.valueOf(URL.getOrgDomainUrl()).contains('sandbox');

    public static String generateRandomAlphanumericCustom(Integer length) { 
        String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < length) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randStr += chars.substring(idx, idx+1);
        }
        return randStr; 
    }

	@AuraEnabled
    public static AS_RazorPayQRCodeResponseWrapper payViaQRCode(Id workOrderId, Decimal amtToPay, String payType, String payRemark) {

        AS_RazorPayQRCodeResponseWrapper res = new AS_RazorPayQRCodeResponseWrapper();

        try {
            WorkOrder wo = [SELECT Id, AccountId, Due_Amount__c, Account.Phone, Account.Name, CA_Number__c,
                                   Customer_Full_Name__c, Agent__r.RelatedRecord.Name,
                                   Account.CA_Number__c, Account.BP_Number__c, Customer_BP_Number__c,
                                   New_Mobile_Number__c
							  FROM WorkOrder 
							 WHERE Id = :workOrderId 
							 LIMIT 1];

            // Get Metadata 
            API_Setting__mdt settings = [SELECT Stage_EndPoint__c, Stage_Header__c, Prod_EndPoint__c, Prod_Header__c 
                						   FROM API_Setting__mdt 
                						  WHERE DeveloperName = 'RazorPayQRCodeRequest' 
                						  LIMIT 1];

            String endpoint = isRunningInASandbox ? settings.Stage_EndPoint__c : settings.Prod_EndPoint__c;
            String headerJson = isRunningInASandbox ? settings.Stage_Header__c : settings.Prod_Header__c;

            RequestQRCodeHeaderWrapper headers = (RequestQRCodeHeaderWrapper) JSON.deserialize(headerJson, RequestQRCodeHeaderWrapper.class);

            // Prepare Request
            AS_RazorPayQRCodeRequestWrapper req = new AS_RazorPayQRCodeRequestWrapper();
            req.amount = (amtToPay != null ? amtToPay : wo.Due_Amount__c);
			req.appKey = headers.appKey;
            req.customerMobileNumber = wo.New_Mobile_Number__c == null ? wo.Account.Phone : wo.New_Mobile_Number__c; 
			req.customerName = wo.Account.Name;
            req.externalRefNumber = generateRandomAlphanumericCustom(15);
            req.externalRefNumber2 = wo.CA_Number__c == null ? wo.Account.CA_Number__c : wo.CA_Number__c;
            req.externalRefNumber3 = wo.Customer_BP_Number__c == null ? wo.Account.BP_Number__c : wo.Customer_BP_Number__c;
            req.externalRefNumber4 = 'Collect360';
			req.username = wo.Agent__r.RelatedRecord.Name;
            req.qrCodeType = headers.qrCodeType;

            HttpResponse response = doRequest(endpoint, JSON.serialize(req));


            AS_RazorPayQRCodeResponseWrapper rPayRes = (AS_RazorPayQRCodeResponseWrapper) JSON.deserialize(response.getBody(), AS_RazorPayQRCodeResponseWrapper.class);
            
            //String resSting = '{"success":true,"sessionKey":"67a98300-4d35-428c-8af7-d6b8a40dd90e","username":"1212127800","setting":{"chequePaymentBankNames":[{"code":"ABN_AMRO","codeDescription":"ABN AMRO Bank"},{"code":"ALLAHABAD_BANK","codeDescription":"Allahabad Bank"},{"code":"ANDHRA_BANK","codeDescription":"Andhra Bank"},{"code":"AXIS_BANK","codeDescription":"Axis Bank"},{"code":"BANK_OF_BAHRAIN_AND_KUWAIT","codeDescription":"Bank of Bahrain and Kuwait"},{"code":"BANK_OF_BARODA","codeDescription":"Bank of Baroda"},{"code":"BANK_OF_INDIA","codeDescription":"Bank of India"},{"code":"BANK_OF_KARNATAKA","codeDescription":"Bank of Karnataka"},{"code":"BANK_OF_MAHARASHTRA","codeDescription":"Bank of Maharashtra"},{"code":"CANARA_BANK","codeDescription":"Canara Bank"},{"code":"CENTRAL_BANK_OF_INDIA","codeDescription":"Central Bank of India"},{"code":"CITIBANK","codeDescription":"Citibank"},{"code":"CITY_UNION_BANK_LTD","codeDescription":"City Union Bank Ltd"},{"code":"CORPORATION_BANK","codeDescription":"Corporation Bank"},{"code":"DCB_DEVELOPMENT_CREDIT_BANK","codeDescription":"DCB Development Credit Bank"},{"code":"DENA_BANK","codeDescription":"Dena Bank"},{"code":"HDFC_BANK","codeDescription":"HDFC Bank"},{"code":"HSBC_BANK","codeDescription":"HSBC Bank"},{"code":"ICICI_BANK","codeDescription":"ICICI Bank"},{"code":"IDBI_BANK","codeDescription":"IDBI Bank"},{"code":"INDIAN_BANK","codeDescription":"Indian Bank"},{"code":"INDIAN_OVERSEAS_BANK","codeDescription":"Indian Overseas Bank"},{"code":"INDUSIND_BANK","codeDescription":"IndusInd Bank"},{"code":"ING_VYSYA_BANK_LTD","codeDescription":"ING Vysya Bank Ltd"},{"code":"KARNATAKA_BANK","codeDescription":"Karnataka Bank"},{"code":"KOTAK_MAHINDRA_BANK","codeDescription":"Kotak Mahindra Bank"},{"code":"LAKSHMI_VILAS_BANK","codeDescription":"Lakshmi Vilas Bank"},{"code":"MERCANTILE_BANK","codeDescription":"Mercantile Bank"},{"code":"ORIENTAL_BANK_OF_COMMERCE","codeDescription":"Oriental Bank of Commerce"},{"code":"PUNJAB_NATIONAL_BANK","codeDescription":"Punjab National Bank"},{"code":"RATNAKAR_BANK_LTD","codeDescription":"Ratnakar Bank Ltd"},{"code":"SOUTH_INDIAN_BANK","codeDescription":"South Indian Bank"},{"code":"STANDARD_CHARTERED_BANK","codeDescription":"Standard Chartered Bank"},{"code":"STATE_BANK_OF_BIKANER_JAIPUR","codeDescription":"State Bank of Bikaner and Jaipur"},{"code":"STATE_BANK_OF_HYDERABAD","codeDescription":"State Bank of Hyderabad"},{"code":"STATE_BANK_OF_INDIA","codeDescription":"State Bank of India"},{"code":"STATE_BANK_OF_MYSORE","codeDescription":"State Bank of Mysore"},{"code":"STATE_BANK_OF_PATIALA","codeDescription":"State Bank of Patiala"},{"code":"STATE_BANK_OF_SAURASHTRA","codeDescription":"State Bank of Saurashtra"},{"code":"STATE_BANK_OF_TAMIL_NADU","codeDescription":"State Bank of Tamil Nadu"},{"code":"SYNDICATE_BANK","codeDescription":"Syndicate Bank"},{"code":"THE_ANDHRA_PRADESH_STATE_CO_OP_BANK_LTD","codeDescription":"The Andhra Pradesh State Co Operative Bank Ltd"},{"code":"THE_KARUR_VYSYA_BANK_PVT_LTD","codeDescription":"The Karur Vysya Bank Pvt Ltd"},{"code":"UCO_BANK","codeDescription":"UCO Bank"},{"code":"UNION_BANK_OF_INDIA","codeDescription":"Union Bank of India"},{"code":"UNITED_BANK_OF_INDIA","codeDescription":"United Bank of India"},{"code":"UNIT_TRUST_OF_INDIA","codeDescription":"Unit Trust of India"},{"code":"VIJAYA_BANK","codeDescription":"Vijaya Bank"},{"code":"YES_BANK","codeDescription":"Yes Bank"},{"code":"OTHER","codeDescription":"Other"}],"soundBoxEnabled":true,"tipEnabled":false,"eSignatureForWalletEnabled":true,"rmpayWalletEnabled":false,"smsReceiptEnabledForCnp":true,"minTxnAmount":"1","preFillUsernameOnSessionTimeOut":true,"offeringEmiCashback":"YES","deviceTimeout":"1","autoSyncOfflineInterval":"180","paperReceiptEnabled":false,"pogSettings":"null","sodexoEnabled":false,"preAuthOption":"-1","emiEnabledForClient":false,"barcodeScanningEnabled":false,"aggregatePaymentModesEnabled":false,"brandEmiEnabled":false,"btReceiptEnabled":false,"collectMobileEmailUpfront":false,"p2pEnabled":false,"cashBackEnabled":false,"supportPhoneNumber":"1800212212212","catalogEnabled":false,"customConfigCode":"EZETAP","emiEnabled":true,"settingVer":1752068964729,"omsSettings":{"omsEnabled":false,"catalogEnabled":null,"catalogType":null,"maxOrderItems":20,"dataWindow":45,"orderListMaxRecords":null,"fieldsToIndex":null},"orderNumberInputEnabled":false,"customWebFlowEnabled":false,"refundEnabled":false,"cashBackOption":"-1","automaticSMSPaymentLinkEnabled":true,"chequePaymentEnabled":true,"cnpEnabled":false,"dukptMultiTidEnabled":false,"saleOption":"1","smsReceiptEnabled":true,"walletRefundEnabled":true,"maxBTAttempts":"1","autoSyncOfflineEnabled":false,"notificationCentreLimit":"60","smsReceiptEnabledForUpiBqrRefundPending":true,"smsReceiptEnabledForDD":false,"networkHealthMetrics":"\"{\"weightages\":{\"signalStrength\":{\"weightage\":0.25,\"simRange\":{\"max\":0,\"min\":-85},\"wifiRange\":{\"max\":0,\"min\":-60}},\"packetLoss\":{\"weightage\":0.3,\"range\":{\"min\":0,\"max\":20}},\"rtt\":{\"weightage\":0.45,\"range\":{\"min\":0,\"max\":2000}}},\"version\":2,\"status\":\"OK\"}\"","tipPercentage":"15","merchantBusinessHoursEnd":"12","configFlowEnabled":false,"eSignatureForNonCardEnabled":false,"eSignatureEnabled":false,"notificationEnabled":false,"smsReceiptEnabledForWallet":true,"emailReceiptEnabled":true,"zestRegistrationSmsEnabled":false,"orderNumberLabel":"","customerNameEntryEnabled":false,"crateBasedSearchEnabled":false,"notificationForcedTimeGap":"30","sessionTimeOutForReversal":"28800","smsReceiptEnabledForCash":true,"autoLoginByTokenEnabled":false,"cashPaymentEnabled":true,"prepaidVoucherPaymentEnabled":false,"signatureForCard":"ACQUIRER_BASED","smsReceiptEnabledForBharatQR":true,"devicePairingRequiredForNonCardPaymentModes":false,"maxCashBackAmount":"2000","biEventEmail":"info@ezetap.com","tipAdjustmentEnabled":false,"upiEnabled":true,"clientBaseURL":"DEFAULT","remotePaymentEnabled":false,"automaticEmailPaymentLinkEnabled":true,"clearCardDetailsEnabled":true,"upiEnabledInCNP":true,"cardLastFourDigitsRequired":false,"smsReceiptEnabledForUpi":true,"enableMultilingualForApp":true,"passRegexErrorDisplay":"Password shoud be Alphanumeric and length should be atleast 7 character","maxTxnAmount":"9999999999","communicationRoute":"FCM","languagesForApp":"English,Hindi,Tamil,Telugu,Kannada,Punjabi,Marathi,Malayalam,Oriya,Bengali,Gujarati","cardPaymentEnabled":true,"minCashBackAmount":"100","printMerchantCopy":false,"merchantBusinessHoursStart":"6","smsReceiptEnabledForCheque":false,"addlAuthReqdForCash":false,"zeroValueTransactionAllowed":false,"offlineAPIEnabled":false,"firmwareCheckInterval":"7200","passRegex":"^[a-zA-Z0-9_]*$","merchantAddress":"Bangalore||banglore|Karnataka||IN","primaryLanguageForApp":"English","twoFactorAuthenticationEnabled":true,"pogEnabled":false,"allowAmountOverride":false,"minCheckStatusAttempts":"2"},"apps":[],"enableRki":false,"tid":"87231123","amount":1200,"amountOriginal":1200,"currencyCode":"INR","customerName":"Bala Bala Preethika  BP8768","customerMobile":"0987654321","customerReceiptUrl":"","externalRefNumber":"EZ202012091537110603","txnId":"250711110055621E010055100","merchantName":"Vufto","mid":"87231122","nonceStatus":"PENDING","orgCode":"VUFTO_3846724277","merchantCode":"VUFTO_3846724277","paymentCardType":"UNKNOWN","paymentMode":"UPI","postingDate":1752251455000,"processCode":"_DEF_PROC","settlementStatus":"PENDING","signatureId":"NR","status":"PENDING","states":["PENDING"],"txnType":"CHARGE","dccOpted":false,"cardHolderCurrencyExponent":0,"userAgreement":"","signable":false,"voidable":false,"refundable":false,"chargeSlipDate":"2025-07-11T16:30:55+0530","readableChargeSlipDate":"11/07/2025 16:30:55","issuerCode":"HDFC","maximumPayAttemptsAllowed":1,"maximumSuccessfulPaymentAllowed":1,"noExpiryFlag":false,"receiptUrl":"","signReqd":false,"txnTypeDesc":"Charge","paymentGateway":"HDFC","acquirerCode":"HDFC","createdTime":1752251455000,"customerNameAvailable":false,"callbackEnabled":true,"onlineRefundable":false,"manualRefund":false,"shiftNo":0,"shouldRoundOffExchangeRate":true,"shouldRoundOffConvertedAmount":true,"orderNumber":"EZ202012091537110603","totalAmount":1200,"nameOnCard":"Bala Bala Preethika  BP8768","tipEnabled":false,"callTC":false,"acquisitionId":"","acquisitionKey":"","processCronOutput":false,"externalDevice":false,"tipAdjusted":false,"txnMetadata":[],"middlewareStanNumber":0,"otpRequired":false,"qrCodeUri":"upi://pay?ver=01&mode=22&pa=demoezetaphdfc@hdfcbank&pn=Vufto&tr=250711110055621E010055100&am=1200.00&mc=7399&qrMedium=03&QRexpire=2025-07-11T16:36:55+05:30&QRts=2025-07-11T16:30:55+05:30","vpa":"demoezetaphdfc@hdfcbank","reload":false,"twoStepConfirmPreAuth":false,"redirect":false}';
            //AS_RazorPayQRCodeResponseWrapper rPayRes = (AS_RazorPayQRCodeResponseWrapper) JSON.deserialize(resSting, AS_RazorPayQRCodeResponseWrapper.class);

            AS_APIRequestLogger.logRequestResponse(workOrderId, endpoint, req, response, 'RazorPayQRCode Request Call');

            if (response.getStatusCode() == 200 && rPayRes.success) { 
                WorkOrder woToUpdate = new WorkOrder(
                    Id = workOrderId, 
                    QR_Code_Txn_Id__c = rPayRes.txnId, 
                    QR_Code_URI__c = rPayRes.qrCodeUri,
                    Payment_Type__c = payType,
                    Pay_Remark__c = payRemark
                );
                update woToUpdate;

                res.success = true;
                res.txnId = rPayRes.txnId;
				res.qrCodeUri = rPayRes.qrCodeUri;
            } else {
                res.success = false;
                res.message = rPayRes.errorMessage != null ? rPayRes.errorMessage : 'Failed to send payment request.';
            } 

        } catch (Exception ex) {
            AS_ErrorLogger.log('AS_RazorPayQRCodeModule', 'payViaQRCode', ex, workOrderId);
        }
        return res;
    }

    @AuraEnabled
    public static AS_RazorPayQRCodeStatusWrapper checkStatusQRCode(Id workOrderId) {
        AS_RazorPayQRCodeStatusWrapper responseWrapper = new AS_RazorPayQRCodeStatusWrapper();
        try {
            WorkOrder wo = [SELECT Id, QR_Code_Txn_Id__c, QR_Code_URI__c, Due_Amount__c, Agent__r.RelatedRecord.Name,
                                   Check_In_Location__latitude__s, Check_In_Location__longitude__s 
                              FROM WorkOrder 
                             WHERE Id = :workOrderId LIMIT 1];

            if (String.isBlank(wo.QR_Code_Txn_Id__c)) {
                responseWrapper.success = false;
                responseWrapper.message = 'No QR Code Txn Id found for this WorkOrder.';
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
                                      WHERE DeveloperName = 'RazorPayQRCodeStatus' 
                                      LIMIT 1];

            String endpoint = isRunningInASandbox ? meta.Stage_EndPoint__c : meta.Prod_EndPoint__c;
            String headerJson = isRunningInASandbox ? meta.Stage_Header__c : meta.Prod_Header__c;

            StatusQRCodeHeaderWrapper headers = (StatusQRCodeHeaderWrapper) JSON.deserialize(headerJson, StatusQRCodeHeaderWrapper.class);
            
            AS_RazorPayQRCodeStatusReqWrapper statusRequest = new AS_RazorPayQRCodeStatusReqWrapper();
			statusRequest.txnId = wo.QR_Code_Txn_Id__c;
			statusRequest.username = wo.Agent__r.RelatedRecord.Name;
			statusRequest.appKey = headers.appKey;

            HttpResponse response = doRequest(endpoint, JSON.serialize(statusRequest));
            
            AS_RazorPayQRCodeStatusWrapper statusResponse = (AS_RazorPayQRCodeStatusWrapper) JSON.deserialize(response.getBody(), AS_RazorPayQRCodeStatusWrapper.class);

            //String fakeSuccRes = '{"success":true,"sessionKey":"6efabd7f-a7c7-4781-b7fb-ecc765aed9be","username":"1212127800","setting":{"chequePaymentBankNames":[{"code":"ABN_AMRO","codeDescription":"ABN AMRO Bank"},{"code":"ALLAHABAD_BANK","codeDescription":"Allahabad Bank"},{"code":"ANDHRA_BANK","codeDescription":"Andhra Bank"},{"code":"AXIS_BANK","codeDescription":"Axis Bank"},{"code":"BANK_OF_BAHRAIN_AND_KUWAIT","codeDescription":"Bank of Bahrain and Kuwait"},{"code":"BANK_OF_BARODA","codeDescription":"Bank of Baroda"},{"code":"BANK_OF_INDIA","codeDescription":"Bank of India"},{"code":"BANK_OF_KARNATAKA","codeDescription":"Bank of Karnataka"},{"code":"BANK_OF_MAHARASHTRA","codeDescription":"Bank of Maharashtra"},{"code":"CANARA_BANK","codeDescription":"Canara Bank"},{"code":"CENTRAL_BANK_OF_INDIA","codeDescription":"Central Bank of India"},{"code":"CITIBANK","codeDescription":"Citibank"},{"code":"CITY_UNION_BANK_LTD","codeDescription":"City Union Bank Ltd"},{"code":"CORPORATION_BANK","codeDescription":"Corporation Bank"},{"code":"DCB_DEVELOPMENT_CREDIT_BANK","codeDescription":"DCB Development Credit Bank"},{"code":"DENA_BANK","codeDescription":"Dena Bank"},{"code":"HDFC_BANK","codeDescription":"HDFC Bank"},{"code":"HSBC_BANK","codeDescription":"HSBC Bank"},{"code":"ICICI_BANK","codeDescription":"ICICI Bank"},{"code":"IDBI_BANK","codeDescription":"IDBI Bank"},{"code":"INDIAN_BANK","codeDescription":"Indian Bank"},{"code":"INDIAN_OVERSEAS_BANK","codeDescription":"Indian Overseas Bank"},{"code":"INDUSIND_BANK","codeDescription":"IndusInd Bank"},{"code":"ING_VYSYA_BANK_LTD","codeDescription":"ING Vysya Bank Ltd"},{"code":"KARNATAKA_BANK","codeDescription":"Karnataka Bank"},{"code":"KOTAK_MAHINDRA_BANK","codeDescription":"Kotak Mahindra Bank"},{"code":"LAKSHMI_VILAS_BANK","codeDescription":"Lakshmi Vilas Bank"},{"code":"MERCANTILE_BANK","codeDescription":"Mercantile Bank"},{"code":"ORIENTAL_BANK_OF_COMMERCE","codeDescription":"Oriental Bank of Commerce"},{"code":"PUNJAB_NATIONAL_BANK","codeDescription":"Punjab National Bank"},{"code":"RATNAKAR_BANK_LTD","codeDescription":"Ratnakar Bank Ltd"},{"code":"SOUTH_INDIAN_BANK","codeDescription":"South Indian Bank"},{"code":"STANDARD_CHARTERED_BANK","codeDescription":"Standard Chartered Bank"},{"code":"STATE_BANK_OF_BIKANER_JAIPUR","codeDescription":"State Bank of Bikaner and Jaipur"},{"code":"STATE_BANK_OF_HYDERABAD","codeDescription":"State Bank of Hyderabad"},{"code":"STATE_BANK_OF_INDIA","codeDescription":"State Bank of India"},{"code":"STATE_BANK_OF_MYSORE","codeDescription":"State Bank of Mysore"},{"code":"STATE_BANK_OF_PATIALA","codeDescription":"State Bank of Patiala"},{"code":"STATE_BANK_OF_SAURASHTRA","codeDescription":"State Bank of Saurashtra"},{"code":"STATE_BANK_OF_TAMIL_NADU","codeDescription":"State Bank of Tamil Nadu"},{"code":"SYNDICATE_BANK","codeDescription":"Syndicate Bank"},{"code":"THE_ANDHRA_PRADESH_STATE_CO_OP_BANK_LTD","codeDescription":"The Andhra Pradesh State Co Operative Bank Ltd"},{"code":"THE_KARUR_VYSYA_BANK_PVT_LTD","codeDescription":"The Karur Vysya Bank Pvt Ltd"},{"code":"UCO_BANK","codeDescription":"UCO Bank"},{"code":"UNION_BANK_OF_INDIA","codeDescription":"Union Bank of India"},{"code":"UNITED_BANK_OF_INDIA","codeDescription":"United Bank of India"},{"code":"UNIT_TRUST_OF_INDIA","codeDescription":"Unit Trust of India"},{"code":"VIJAYA_BANK","codeDescription":"Vijaya Bank"},{"code":"YES_BANK","codeDescription":"Yes Bank"},{"code":"OTHER","codeDescription":"Other"}],"soundBoxEnabled":true,"tipEnabled":false,"eSignatureForWalletEnabled":true,"rmpayWalletEnabled":false,"smsReceiptEnabledForCnp":true,"minTxnAmount":"1","preFillUsernameOnSessionTimeOut":true,"offeringEmiCashback":"YES","deviceTimeout":"1","autoSyncOfflineInterval":"180","paperReceiptEnabled":false,"pogSettings":"null","sodexoEnabled":false,"preAuthOption":"-1","emiEnabledForClient":false,"barcodeScanningEnabled":false,"aggregatePaymentModesEnabled":false,"brandEmiEnabled":false,"btReceiptEnabled":false,"collectMobileEmailUpfront":false,"p2pEnabled":false,"cashBackEnabled":false,"supportPhoneNumber":"1800212212212","catalogEnabled":false,"customConfigCode":"EZETAP","emiEnabled":true,"settingVer":1752068965000,"omsSettings":{"omsEnabled":false,"catalogEnabled":null,"catalogType":null,"maxOrderItems":20,"dataWindow":45,"orderListMaxRecords":null,"fieldsToIndex":null},"orderNumberInputEnabled":false,"customWebFlowEnabled":false,"refundEnabled":false,"cashBackOption":"-1","automaticSMSPaymentLinkEnabled":true,"chequePaymentEnabled":true,"cnpEnabled":false,"dukptMultiTidEnabled":false,"saleOption":"1","smsReceiptEnabled":true,"walletRefundEnabled":true,"maxBTAttempts":"1","autoSyncOfflineEnabled":false,"notificationCentreLimit":"60","smsReceiptEnabledForUpiBqrRefundPending":true,"smsReceiptEnabledForDD":false,"networkHealthMetrics":"\"{\"weightages\":{\"signalStrength\":{\"weightage\":0.25,\"simRange\":{\"max\":0,\"min\":-85},\"wifiRange\":{\"max\":0,\"min\":-60}},\"packetLoss\":{\"weightage\":0.3,\"range\":{\"min\":0,\"max\":20}},\"rtt\":{\"weightage\":0.45,\"range\":{\"min\":0,\"max\":2000}}},\"version\":2,\"status\":\"OK\"}\"","tipPercentage":"15","merchantBusinessHoursEnd":"12","configFlowEnabled":false,"eSignatureForNonCardEnabled":false,"eSignatureEnabled":false,"notificationEnabled":false,"smsReceiptEnabledForWallet":true,"emailReceiptEnabled":true,"zestRegistrationSmsEnabled":false,"orderNumberLabel":"","customerNameEntryEnabled":false,"crateBasedSearchEnabled":false,"notificationForcedTimeGap":"30","sessionTimeOutForReversal":"28800","smsReceiptEnabledForCash":true,"autoLoginByTokenEnabled":false,"cashPaymentEnabled":true,"prepaidVoucherPaymentEnabled":false,"signatureForCard":"ACQUIRER_BASED","smsReceiptEnabledForBharatQR":true,"devicePairingRequiredForNonCardPaymentModes":false,"maxCashBackAmount":"2000","mpinFlowCashPaymentEnabled":true,"biEventEmail":"info@ezetap.com","tipAdjustmentEnabled":false,"upiEnabled":true,"clientBaseURL":"DEFAULT","remotePaymentEnabled":false,"automaticEmailPaymentLinkEnabled":true,"clearCardDetailsEnabled":true,"upiEnabledInCNP":true,"cardLastFourDigitsRequired":false,"smsReceiptEnabledForUpi":true,"enableMultilingualForApp":true,"passRegexErrorDisplay":"Password shoud be Alphanumeric and length should be atleast 7 character","maxTxnAmount":"9999999999","communicationRoute":"FCM","languagesForApp":"English,Hindi,Tamil,Telugu,Kannada,Punjabi,Marathi,Malayalam,Oriya,Bengali,Gujarati","cardPaymentEnabled":true,"minCashBackAmount":"100","printMerchantCopy":false,"merchantBusinessHoursStart":"6","smsReceiptEnabledForCheque":false,"addlAuthReqdForCash":false,"zeroValueTransactionAllowed":false,"offlineAPIEnabled":false,"firmwareCheckInterval":"7200","passRegex":"^[a-zA-Z0-9_]*$","merchantAddress":"Bangalore||banglore|Karnataka||IN","primaryLanguageForApp":"English","twoFactorAuthenticationEnabled":true,"pogEnabled":false,"allowAmountOverride":false,"minCheckStatusAttempts":"2"},"apps":[],"enableRki":false,"tid":"87231123","amount":1200.00,"amountOriginal":1200.00,"authCode":"NA","currencyCode":"INR","customerName":"Test Payer","customerMobile":"0987654321","customerReceiptUrl":"http://d.eze.cc/r/o/xym6ocDR/","externalRefNumber":"EZ202012091537110603","txnId":"250711110055621E010055100","merchantName":"Vufto","mid":"87231122","nonceStatus":"OPEN","orgCode":"VUFTO_3846724277","merchantCode":"VUFTO_3846724277","payerName":"Test Payer","paymentCardType":"UNKNOWN","paymentMode":"UPI","postingDate":1752251456000,"processCode":"_DEF_PROC","rrNumber":"2924000","settlementStatus":"SETTLED","signatureId":"NR","status":"AUTHORIZED","states":["SETTLED"],"txnType":"CHARGE","dccOpted":false,"cardHolderCurrencyExponent":0,"userAgreement":"","signable":false,"voidable":false,"refundable":true,"chargeSlipDate":"2025-07-11T16:30:56+0530","readableChargeSlipDate":"11/07/2025 16:30:56","issuerCode":"HDFC","maximumPayAttemptsAllowed":1,"maximumSuccessfulPaymentAllowed":1,"noExpiryFlag":false,"settlementTime":1752251458000,"receiptUrl":"http://d.eze.cc/r/o/xym6ocDR/","signReqd":false,"txnTypeDesc":"Charge","paymentGateway":"HDFC","acquirerCode":"HDFC","createdTime":1752251456000,"customerNameAvailable":true,"callbackEnabled":true,"onlineRefundable":false,"manualRefund":false,"shiftNo":0,"shouldRoundOffExchangeRate":true,"shouldRoundOffConvertedAmount":true,"orderNumber":"EZ202012091537110603","reverseReferenceNumber":"2924000","totalAmount":1200.00,"nameOnCard":"Test Payer","tipEnabled":false,"callTC":false,"acquisitionId":"","acquisitionKey":"","processCronOutput":false,"externalDevice":false,"tipAdjusted":false,"txnMetadata":[],"middlewareStanNumber":0,"otpRequired":false,"reload":false,"twoStepConfirmPreAuth":false,"redirect":false}';
            //AS_RazorPayQRCodeStatusWrapper statusResponse = (AS_RazorPayQRCodeStatusWrapper) JSON.deserialize(fakeSuccRes, AS_RazorPayQRCodeStatusWrapper.class);

            AS_APIRequestLogger.logRequestResponse(workOrderId, endpoint, statusRequest, response, 'RazorPayQRCode Status Call');

              system.debug('Status Code:: '+response.getStatusCode());
            if (response.getStatusCode() == 200 && statusResponse.success &&  statusResponse.status == meta.Status__c) {
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
                    Payment_Mode__c = 'QR Code',
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
            AS_ErrorLogger.log('AS_RazorPayQRCodeStatusWrapper', 'checkStatusQRCode', e, workOrderId);
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
		//request.setTimeout(120000);
        request.setHeader('Content-Type', 'application/json');
        request.setBody(req);
        Http http = new Http();

        return http.send(request);
    }

	public class AS_RazorPayQRCodeRequestWrapper {
		public Decimal amount;
		public String appKey;
		public String customerMobileNumber;
		public String customerName;
		public String externalRefNumber;
        public String externalRefNumber2;
        public String externalRefNumber3;
        public String externalRefNumber4;
		public String username;
        public String qrCodeType;
	}

	public class RequestQRCodeHeaderWrapper {
		public String username;
		public String appKey;
		public String deviceId;
		//public String externalRefNumber;
        public String qrCodeType;
	}

    public class StatusQRCodeHeaderWrapper {
        public String username;
        public String appKey;
    }

	public class AS_RazorPayQRCodeStatusReqWrapper {
		public String username;
		public String appKey;
		public String txnId;
	}

    public class AS_RazorPayQRCodeStatusWrapper {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
        @AuraEnabled public String status;
        @AuraEnabled public String txnId;
		@AuraEnabled public String customerReceiptUrl;
        @AuraEnabled public Decimal amount;
    }

    public class AS_RazorPayQRCodeResponseWrapper {
	    @AuraEnabled public Boolean success;
        @AuraEnabled public String messageCode;
        @AuraEnabled public String message;
        @AuraEnabled public String errorCode;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public String apiMessageText;
        @AuraEnabled public String apiMessage;
        @AuraEnabled public String apiWarning;
        @AuraEnabled public String txnId;
		@AuraEnabled public String qrCodeUri;
    }

}