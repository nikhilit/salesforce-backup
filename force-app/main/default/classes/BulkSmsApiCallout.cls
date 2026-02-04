public class BulkSmsApiCallout {
    
    @future(callout=true)
    public static void sendBulkSmsFuture(String mobileNumbersJson, String messagesJson, String recordIdsJson, 
                                        String mergeFieldsListJson, String templateIdsJson) {
        
        if (!TriggerController.isTriggerActive('BulkSmsApiCallout')) {
            return;
        }
        
        // Deserialize the JSON parameters
        List<String> mobileNumbers = (List<String>)JSON.deserialize(mobileNumbersJson, List<String>.class);
        List<String> messages = (List<String>)JSON.deserialize(messagesJson, List<String>.class);
        List<String> recordIds = (List<String>)JSON.deserialize(recordIdsJson, List<String>.class);
        List<Map<String, String>> mergeFieldsList = (List<Map<String, String>>)JSON.deserialize(mergeFieldsListJson, List<Map<String, String>>.class);
        List<String> templateIds = (List<String>)JSON.deserialize(templateIdsJson, List<String>.class);
                                            
        if (mobileNumbers == null || mobileNumbers.isEmpty() || recordIds == null || recordIds.isEmpty()) {
            return;
        }
        
        // Get configuration from Custom Metadata - Use Label 1 specifically
        Bulk_SMS_Config__mdt config;
        try {
            config = [
                SELECT Endpoint__c, Sender__c, Api_Key__c, Is_Active__c
                FROM Bulk_SMS_Config__mdt 
                WHERE DeveloperName = 'MGL_Bulk_SMS' 
                AND Is_Active__c = true 
                LIMIT 1
            ];
            
            System.debug('Bulk SMS Config Found: ' + config);
            System.debug('Sender: ' + config.Sender__c);
            System.debug('API Key: ' + config.Api_Key__c);
            System.debug('Endpoint: ' + config.Endpoint__c);
            System.debug('Is Active: ' + config.Is_Active__c);
            
        } catch (Exception e) {
            createErrorLog('BulkSmsApiCallout', 'sendBulkSmsFuture', 'Configuration error: ' + e.getMessage());
            return;
        }

        // Prepare SMS data for bulk API
        List<Map<String, String>> smsDataList = new List<Map<String, String>>();
        List<String> processedMessages = new List<String>();

        for (Integer i = 0; i < mobileNumbers.size(); i++) {
            if (i < messages.size() && i < templateIds.size()) {
                String processedMessage = messages[i];
                Map<String, String> mergeFields = mergeFieldsList != null && i < mergeFieldsList.size() ? mergeFieldsList[i] : null;
                
                // Replace merge fields in message
                if (mergeFields != null) {
                    for (String key : mergeFields.keySet()) {
                        String placeholder = '{!' + key + '}';
                        String replacement = mergeFields.get(key) != null ? mergeFields.get(key) : '';
                        processedMessage = processedMessage.replace(placeholder, replacement);
                    }
                }
                
                Map<String, String> smsData = new Map<String, String>{
                    'destination' => mobileNumbers[i],
                    'source' => config.Sender__c, // Use from Label 1 metadata
                    'type' => 'TEXT',
                    'content' => processedMessage,
                    'tempId' => templateIds[i]
                };
                
                smsDataList.add(smsData);
                processedMessages.add(processedMessage);
            }
        }
        
        if (smsDataList.isEmpty()) {
            return;
        }
        
        // Prepare the JSON request body
        Map<String, Object> requestBody = new Map<String, Object>{
            'authentication' => new Map<String, String>{
                'key' => config.Api_Key__c, // Use from Label 1 metadata
                'version' => '1.0',
                'channel' => '0'
            },
            'message' => new Map<String, Object>{
                'smsdata' => smsDataList
            }
        };
        
        String jsonBody = JSON.serialize(requestBody);
        System.debug('Bulk SMS Request Body: ' + jsonBody);
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(config.Endpoint__c); // Use from Label 1 metadata
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Sender', config.Sender__c); // Use from Label 1 metadata
        req.setBody(jsonBody);
        req.setTimeout(120000);
        
        // Create integration logs for each record
        List<Integration_Log__c> logsToInsert = new List<Integration_Log__c>();
        
        for (Integer i = 0; i < recordIds.size(); i++) {
            if (i < mobileNumbers.size()) {
                Integration_Log__c log = createIntegrationLog(
                    config.Endpoint__c, 
                    'POST', 
                    'Bulk SMS Send', 
                    'BulkSmsApiCallout', 
                    'sendBulkSmsFuture',
                    recordIds[i],
                    mobileNumbers[i],
                    processedMessages[i]
                );
                logsToInsert.add(log);
            }
        }
        
        Http http = new Http();
        try {
            HttpResponse res = http.send(req);
            System.debug('Bulk SMS Response Status: ' + res.getStatusCode());
            System.debug('Bulk SMS Response Body: ' + res.getBody());
            
            // Update all logs with the response
            for (Integration_Log__c log : logsToInsert) {
                log.Response_Body__c = res.getBody();
                log.Status__c = (res.getStatusCode() == 200 ? 'Success' : 'Failed');
                log.Status_Code__c = res.getStatusCode();
            }
            
        } catch (Exception e) {
            System.debug('Bulk SMS Exception: ' + e.getMessage());
            // Update all logs with the exception
            for (Integration_Log__c log : logsToInsert) {
                log.Response_Body__c = e.getMessage();
                log.Status__c = 'Exception';
                log.Status_Code__c = null;
                log.Message__c += ' | Exception: ' + e.getMessage();
            }
        }
        
        try {
            if (!logsToInsert.isEmpty()) {
                insert logsToInsert;
            }
        } catch (Exception ex) {
            createErrorLog('BulkSmsApiCallout', 'sendBulkSmsFuture', 'Log insertion error: ' + ex.getMessage());
        }
    }
    
    private static Integration_Log__c createIntegrationLog(String endpoint, String method, String message, 
                                                         String className, String methodName, String recordId, 
                                                         String phoneNumber, String smsMessage) {
        Integration_Log__c log = new Integration_Log__c();
        log.Class_Name__c = className;
        log.Method_Name__c = methodName;
        
        Integer maxLength = Integration_Log__c.Endpoint_URL__c.getDescribe().getLength();
        if (endpoint.length() > maxLength) {
            log.Endpoint_URL__c = endpoint.substring(0, maxLength - 15) + '...[truncated]';
        } else {
            log.Endpoint_URL__c = endpoint;
        }
        
        log.Request_Method__c = method;
        log.Message__c = smsMessage;
        log.Phone_Number__c = phoneNumber;
        log.Line_Number__c = 0;
        
        // Tag to Case and Account like in SmsApiCallout
        if (String.isNotBlank(recordId)) {
            try {
                Id recId = Id.valueOf(recordId);
                Schema.SObjectType objType = recId.getSObjectType();
                
                if (objType == Case.SObjectType) {
                    log.Case__c = recId;
                    // Query AccountId from Case
                    List<Case> caseRecords = [SELECT AccountId FROM Case WHERE Id = :recId LIMIT 1];
                    if (!caseRecords.isEmpty()) {
                        log.Business_Partner__c = caseRecords[0].AccountId;
                    }
                } else if (objType == WorkOrder.SObjectType) {
                    log.Work_Order__c = recId;
                    // Query AccountId from WorkOrder
                    List<WorkOrder> workOrders = [SELECT AccountId FROM WorkOrder WHERE Id = :recId LIMIT 1];
                    if (!workOrders.isEmpty()) {
                        log.Business_Partner__c = workOrders[0].AccountId;
                    }
                }
            } catch (Exception e) {
                System.debug('Error tagging log to record: ' + e.getMessage());
            }
        }
        
        return log;
    }
    
    private static void createErrorLog(String className, String methodName, String errorMessage) {
        try {
            Error_Logger__c err = Error_LoggerClass.createErrorLogger(className, methodName, null, 'Exception', errorMessage, 0, true);
            insert err;
        } catch (Exception ex) {
            System.debug('Failed to create error log: ' + ex.getMessage());
        }
    }
}