public class RTSmsApiCallout {

    @future(callout=true)
    public static void sendSmsFuture(String mobile, String message, String workOrderIdStr, Map<String, String> mergeFields,String templateId) {
        Id workOrderId = Id.valueOf(workOrderIdStr);

        // Replace merge fields in the message
        if (mergeFields != null) {
            for (String key : mergeFields.keySet()) {
                String placeholder = '{!' + key + '}';
                String replacement = mergeFields.get(key) != null ? mergeFields.get(key) : '';
                message = message.replace(placeholder, replacement);
            }
        }

        SmsApiConfig__c config = SmsApiConfig__c.getOrgDefaults();
        if (config == null) {
            return;
        }

        String endpoint = config.EndPoint__c
            + '?username=' + EncodingUtil.urlEncode(config.username__c, 'UTF-8')
            + '&password=' + EncodingUtil.urlEncode(config.password__c, 'UTF-8')
            + '&sender=' + EncodingUtil.urlEncode(config.sender__c, 'UTF-8')
            + '&type=' + EncodingUtil.urlEncode(config.type__c, 'UTF-8')
            + '&mobile=' + EncodingUtil.urlEncode(mobile, 'UTF-8')
            + '&message=' + EncodingUtil.urlEncode(message, 'UTF-8')
            + '&tempId='+EncodingUtil.urlEncode(templateId, 'UTF-8');

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');

        Integration_Log__c log = new Integration_Log__c();
        log.Class_Name__c = 'RTSmsApiCallout';
        log.Method_Name__c = 'sendSmsFuture';

        Integer maxLength = Integration_Log__c.Endpoint_URL__c.getDescribe().getLength();
        log.Endpoint_URL__c = (endpoint.length() > maxLength)
            ? endpoint.substring(0, maxLength - 15) + '...[truncated]'
            : endpoint;

        log.Request_Method__c = 'GET';
        log.Request_Body__c = null;
        log.Message__c = message;
        log.Line_Number__c = 0;
        log.Work_Order__c = workOrderId;

        // Fetch account for log
        try {
            WorkOrder wo = [SELECT AccountId FROM WorkOrder WHERE Id = :workOrderId LIMIT 1];
            if (wo.AccountId != null) {
                log.Business_Partner__c = wo.AccountId;
            }
        } catch (Exception e) {
            log.Message__c += ' | Account fetch error: ' + e.getMessage();
        }

        Http http = new Http();
        try {
            HttpResponse res = http.send(req);
            log.Response_Body__c = res.getBody();
            log.Status__c = (res.getStatusCode() == 200 ? 'Success' : 'Failed');
            log.Status_Code__c = res.getStatusCode();
        } catch (Exception e) {
            log.Response_Body__c = e.getMessage();
            log.Status__c = 'Exception';
            log.Status_Code__c = null;
            log.Message__c += ' | Exception: ' + e.getMessage();
        }

        try {
            insert log;
        } catch (Exception ex) {
            Error_Logger__c err = Error_LoggerClass.createErrorLogger(
                'RTSmsApiCallout',
                'sendSmsFuture',
                null,
                ex.getTypeName(),
                ex.getMessage(),
                ex.getLineNumber(),
                true
            );
            insert err;
        }
    }
}