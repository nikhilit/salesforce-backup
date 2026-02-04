public class SmsApiCallout {
    @future(callout=true)
    public static void sendSmsFuture(String mobile, String message, String recordIdStr, Map<String, String> mergeFields,String templateId,String Sender) {
        if (!TriggerController.isTriggerActive('SmsApiCallout')) {
        return;
    }
        Id recordId = Id.valueOf(recordIdStr);
        
        // Replace merge fields in message
        if (mergeFields != null) {
            for (String key : mergeFields.keySet()) {
                String placeholder = '{!' + key + '}';
                String replacement = mergeFields.get(key) != null ? mergeFields.get(key) : '';
                message = message.replace(placeholder, replacement);
            }
        }

        SmsApiConfig__c config = SmsApiConfig__c.getOrgDefaults();
       // SmsApiConfigLTD__c config = SmsApiConfigLTD__c.getOrgDefaults();
        if (config == null) {
            return;
        }
        String username  = config.username__c   != null ? config.username__c   : '';
        String password  = config.password__c   != null ? config.password__c   : '';
        String type      = config.type__c       != null ? config.type__c       : '';
        String endpointUrl = config.EndPoint__c != null ? config.EndPoint__c   : '';
        String msgsender    = Sender               != null ? Sender               : '';
        String mobileNo  = mobile               != null ? mobile               : '';
        String msg       = message              != null ? message              : '';
        String tempId    = templateId           != null ? templateId           : '';

        String endpoint = endpointUrl
            + '?username=' + EncodingUtil.urlEncode(username, 'UTF-8')
            + '&password=' + EncodingUtil.urlEncode(password, 'UTF-8')
            + '&sender='   + EncodingUtil.urlEncode(msgsender, 'UTF-8')
            + '&type='     + EncodingUtil.urlEncode(type, 'UTF-8')
            + '&mobile='   + EncodingUtil.urlEncode(mobileNo, 'UTF-8')
            + '&message='  + EncodingUtil.urlEncode(msg, 'UTF-8')
            + '&tempId='   + EncodingUtil.urlEncode(tempId, 'UTF-8');



        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');

        Integration_Log__c log = new Integration_Log__c();
        log.Class_Name__c = 'SmsApiCallout';
        log.Method_Name__c = 'sendSmsFuture';

        Integer maxLength = Integration_Log__c.Endpoint_URL__c.getDescribe().getLength();
        if (endpoint.length() > maxLength) {
            log.Endpoint_URL__c = endpoint.substring(0, maxLength - 15) + '...[truncated]';
        } else {
            log.Endpoint_URL__c = endpoint;
        }

        log.Request_Method__c = 'GET';
        log.Request_Body__c = null;
        log.Message__c = message;
        log.Phone_Number__c = mobile;
        log.Line_Number__c = 0;

        Schema.SObjectType objType = recordId.getSObjectType();
        
        if (objType == Case.SObjectType) {
            log.Case__c = recordId;
            Case caseRecord = [SELECT AccountId FROM Case WHERE Id = :recordId LIMIT 1];
            log.Business_Partner__c = caseRecord.AccountId;
        } else if (objType == WorkOrder.SObjectType) {
            log.Work_Order__c = recordId;
            WorkOrder wo = [SELECT AccountId FROM WorkOrder WHERE Id = :recordId LIMIT 1];
            log.Business_Partner__c = wo.AccountId;
        }

        Http http = new Http();
        try {
            HttpResponse res = http.send(req);
            log.Response_Body__c = res.getBody();
            log.Status__c = (res.getStatusCode() == 200 ? 'Success' : 'Failed');
            System.debug('log::'+log.Status__c);
            log.Status_Code__c = res.getStatusCode();
        } catch (Exception e) {
            log.Response_Body__c = e.getMessage();
            log.Status__c = 'Exception';
            log.Status_Code__c = null;
            log.Message__c += ' | Exception: ' + e.getMessage();
        }
        System.debug('log::'+log);
        try {
            insert log;
        } catch (Exception ex) {
            Error_Logger__c err=Error_LoggerClass.createErrorLogger('SmsApiCallout', 'sendSmsFuture',null,ex.getTypeName(), ex.getMessage(),ex.getLineNumber(),true);
            insert err;
        }
    }
    
    
    
     public static Integration_Log__c sendSmsFutureWorkOrder(String accountId,String mobile, String message, String recordIdStr, Map<String, String> mergeFields,String templateId,String Sender) {   
		//WorkOrderNotificationService.LoggerWrapper  logWrap = new WorkOrderNotificationService.LoggerWrapper();
        Id recordId = Id.valueOf(recordIdStr);
        Integration_Log__c log = new Integration_Log__c();
        // Replace merge fields in message
        if (mergeFields != null) {
            for (String key : mergeFields.keySet()) {
                String placeholder = '{!' + key + '}';
                String replacement = mergeFields.get(key) != null ? mergeFields.get(key) : '';
                message = message.replace(placeholder, replacement);
            }
        }

        SmsApiConfig__c config = SmsApiConfig__c.getOrgDefaults();
         system.debug('config::'+config);
       // SmsApiConfigLTD__c config = SmsApiConfigLTD__c.getOrgDefaults();
        if (config == null) {
            log.Response_Body__c = 'Empty SMS API Config';
            log.Status__c = 'Exception';
            log.Status_Code__c = null;
            //log.Message__c += ' | Exception: ' + e.getMessage();
            return log;
        }

System.debug('data'+EncodingUtil.urlEncode(config.username__c, 'UTF-8'));
        String endpoint = config.EndPoint__c
            + '?username=' + EncodingUtil.urlEncode(config.username__c, 'UTF-8')
            + '&password=' + EncodingUtil.urlEncode(config.password__c, 'UTF-8')
            + '&sender=' + EncodingUtil.urlEncode(Sender, 'UTF-8')
            + '&type=' + EncodingUtil.urlEncode(config.type__c, 'UTF-8')
            + '&mobile=' + EncodingUtil.urlEncode(mobile, 'UTF-8')
            + '&message=' + EncodingUtil.urlEncode(message, 'UTF-8')
            + '&tempId='+EncodingUtil.urlEncode(templateId, 'UTF-8');
System.debug(endpoint);

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');

        
        //logWrap.integrationLog = log;
        log.Class_Name__c = 'SmsApiCallout';
        log.Method_Name__c = 'sendSmsFuture';

        Integer maxLength = Integration_Log__c.Endpoint_URL__c.getDescribe().getLength();
        if (endpoint.length() > maxLength) {
            log.Endpoint_URL__c = endpoint.substring(0, maxLength - 15) + '...[truncated]';
        } else {
            log.Endpoint_URL__c = endpoint;
        }

        log.Request_Method__c = 'GET';
        log.Request_Body__c = null;
        log.Message__c = message;
        log.Phone_Number__c = mobile;
        log.Line_Number__c = 0;

        Schema.SObjectType objType = recordId.getSObjectType();
        
         if (objType == WorkOrder.SObjectType) {
            log.Work_Order__c = recordId;
            log.Business_Partner__c = accountId;
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
        
        return log;

        /*try {
            //insert log;
        } catch (Exception ex) {
            Error_Logger__c err=Error_LoggerClass.createErrorLogger('SmsApiCallout', 'sendSmsFuture',null,ex.getTypeName(), ex.getMessage(),ex.getLineNumber(),true);
            logWrap.errorLog = err;
            //insert err;
        }*/
    }
    
    
    
}