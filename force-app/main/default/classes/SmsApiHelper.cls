/**
 * @description       :
 * @author            : Kartik Patkar Appstrail
 * @group             :
 * @last modified on  : 22-09-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   22-08-2025   Kartik Patkar, Appstrail   Initial Version
 **/
public without sharing class SmsApiHelper {
    
    // Logging wrapper used for capturing integration logs
    public static List<IntegrationLogHelper.IntegrationLogWrapper> listIntegrationLogWrap = new List<IntegrationLogHelper.IntegrationLogWrapper>();
    
    /**
     * @description
     * @author Kartik Patkar, Appstrail | 22-08-2025
     * @param String mobile
     * @param String message
     * @param Map<String String> mergeFields
     * @param String templateId
     * @return String
     **/
    public static String sendSMS(String mobile, String message,String templateId,Id workOrderId) {
        IntegrationLogHelper.IntegrationLogWrapper integrationLogWrap = new IntegrationLogHelper.IntegrationLogWrapper();
        integrationLogWrap.className = 'SmsApiHelper';
        integrationLogWrap.methodName = 'sendSMS';
        integrationLogWrap.workOrderId = workOrderId;
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        try {
            SmsApiConfig__c config = SmsApiConfig__c.getOrgDefaults();
            if (config == null) {
                integrationLogWrap.message = 'SMS Configuration not found.';
                integrationLogWrap.status='Failed';
                listIntegrationLogWrap.add(integrationLogWrap);
                return null;
            }
            
            if(config.Send_to_Default__c){
                mobile = config.Default_Number__c;
            }
            
            if(mobile==null || mobile==''){
                integrationLogWrap.message = 'Mobile number is empty.';
                integrationLogWrap.status='Failed';
                listIntegrationLogWrap.add(integrationLogWrap);
                return null;
            }
            
            String endpoint = config.EndPoint__c
                + '?username=' + EncodingUtil.urlEncode(config.username__c, 'UTF-8')
                + '&password=' + EncodingUtil.urlEncode(config.password__c, 'UTF-8')
                + '&sender=' + EncodingUtil.urlEncode(config.Sender_Metering__c, 'UTF-8')
                + '&type=' + EncodingUtil.urlEncode(config.type__c, 'UTF-8')
                + '&mobile=' + EncodingUtil.urlEncode(mobile, 'UTF-8')
                + '&message=' + EncodingUtil.urlEncode(message, 'UTF-8')
                + '&tempId='+EncodingUtil.urlEncode(templateId, 'UTF-8');
            System.debug(endpoint);
            
            // String endpoint='https://webpostservice.com/sendsms_v2.0/sendsms.php?username=mglsf&password=5o94V3iu&sender=MGLCRM&type=TEXT&mobile=7875987035&message=Dear%20MGL%20customer%20,%20we%20made%20multiple%20attempts%20to%20contact%20you%20regarding%20docket%20number%20123%20raised%20by%20you%20,%20the%20case%20has%20been%20closed%20in%20accordance%20with%20our%20standard%20process%20.%20if%20you%20concern%20remain%20unresolved%20,%20please%20contact%20us%20at%2061564500/68674500%20for%20further%20assistance.&tempId=1007717450788253506';
            request.setEndpoint(endpoint);
            request.setMethod('GET');
            HttpResponse response = http.send(request);
            
            // Capture request and response details in the log
            integrationLogWrap.endPointURL = request.getEndpoint();
            integrationLogWrap.requestJSON = endpoint;
            integrationLogWrap.responseJSON = response.getBody();
            integrationLogWrap.statusCode = response.getStatusCode();
            integrationLogWrap.requestMethod = request.getMethod();
            
            if (response.getStatusCode() == 200) {
                integrationLogWrap.message = 'SMS sent successfully.';
                integrationLogWrap.status='Success';
                // Return the parsed response body
                // return response.getBody();
                listIntegrationLogWrap.add(integrationLogWrap);
                return 'Success';
            } else {
                integrationLogWrap.message = 'Failed to send SMS.';
                integrationLogWrap.status='Failed';
                listIntegrationLogWrap.add(integrationLogWrap);
                return null;
            }
        } catch (Exception e) {
            // Log any unexpected errors
            integrationLogWrap.message = e.getMessage();
            integrationLogWrap.lineNumber = e.getLineNumber();
            integrationLogWrap.status='Failed';
            listIntegrationLogWrap.add(integrationLogWrap);
            return null;
        }
    }
    
    public static String sendBulkSMS(SMSBodyWrapper smsBodyWrapper,Bulk_SMS_Config__mdt config) {
        IntegrationLogHelper.IntegrationLogWrapper integrationLogWrap = new IntegrationLogHelper.IntegrationLogWrapper();
        integrationLogWrap.className = 'SmsApiHelper';
        integrationLogWrap.methodName = 'sendBulkSMS';
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        try {
            if (config == null) {
                integrationLogWrap.message = 'Bulk SMS Configuration not found.';
                integrationLogWrap.status='Failed';
                listIntegrationLogWrap.add(integrationLogWrap);
                return null;
            }
            
            String endpoint = config.EndPoint__c;
            request.setEndpoint(endpoint);
            request.setMethod('GET');
            request.setHeader('Content-Type', 'application/json');
            String body = smsBodyWrapper.serialize();
            System.debug('Request Body: ' + body);
            request.setBody(body);
            HttpResponse response = http.send(request);
            
            // Capture request and response details in the log
            integrationLogWrap.endPointURL = request.getEndpoint();
            integrationLogWrap.requestJSON = body;
            integrationLogWrap.responseJSON = response.getBody();
            integrationLogWrap.statusCode = response.getStatusCode();
            integrationLogWrap.requestMethod = request.getMethod();
            
            if (response.getStatusCode() == 200) {
                integrationLogWrap.message = 'Bulk SMS sent successfully.';
                integrationLogWrap.status='Success';
                // Return the parsed response body
                // return response.getBody();
                listIntegrationLogWrap.add(integrationLogWrap);
                return 'Success';
            } else {
                integrationLogWrap.message = 'Failed to send Bulk SMS.';
                integrationLogWrap.status='Failed';
                listIntegrationLogWrap.add(integrationLogWrap);
                return null;
            }
        } catch (Exception e) {
            // Log any unexpected errors
            integrationLogWrap.message = e.getMessage();
            integrationLogWrap.lineNumber = e.getLineNumber();
            integrationLogWrap.status='Failed';
            listIntegrationLogWrap.add(integrationLogWrap);
            return null;
        }
        
    }
    
    public class SMSBodyWrapper{
        
        public Authentication authentication { get; set; }
        public Message message { get; set; }
        
        public String serialize() {
            try {
                return System.JSON.serialize(this);
            } catch (Exception e) {
                System.debug('JSON serialization error: ' + e.getMessage());
                return null;
            }
        }
    }
    
    public class Authentication {
        public String key { get; set; }
        public String version { get; set; }
        public String channel { get; set; }
    }
    
    public class Smsdata {
        public String destination { get; set; }
        public String source { get; set; }
        public String type { get; set; }
        public String content { get; set; }
        public String tempId { get; set; }
    }
    
    public class Message {
        public List<Smsdata> smsdata { get; set; }
    }
}