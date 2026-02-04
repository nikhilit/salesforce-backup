/**
 * @description       :
 * @author            : Kartik Patkar Appstrail
 * @group             :
 * @last modified on  : 22-01-2026
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   22-01-2026   Kartik Patkar, Appstrail   Initial Version
 **/
@restResource(urlMapping='/otherSourceWebService/*')
global class MeteringOtherSourceWebService {
    
    @HttpGet
    global static void handleGet() {
        RestRequest req = RestContext.request;
        IntegrationLogHelper.IntegrationLogWrapper logData = new IntegrationLogHelper.IntegrationLogWrapper();
        logData.className = 'MeteringOtherSourceWebService';
        logData.methodName = 'handleGet';
        logData.requestMethod = 'GET';
        logData.endPointURL = req.requestURI;
        
        try{
            // Get query parameters from URL
            Map<String, String> params = req.params;
            
            String responseBody = 'Request received successfully.';
            ResponseWrapper responseWrapper = new ResponseWrapper(responseBody, 200);
            // Set the response status code
            RestContext.response.statusCode = responseWrapper.statusCode;
            // Set the response body
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseWrapper));
            
            // Log the received request parameters for debugging
            System.debug('Received Query Parameters: ' + JSON.serialize(params));
            logData.requestJSON = JSON.serialize(params);
            logData.status = 'Success';
            logData.message = 'GET request processed successfully.';
            logData.statusCode = 200;
            logData.responseJSON = JSON.serialize(responseWrapper);
            
            // Process the request body based on source
            
            // Log completion of processing
            System.debug('Processing completed for the received request.');
        }catch(Exception e){
            System.debug('Error: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
            logData.status = 'Failed';
            logData.message = e.getMessage();
            logData.statusCode = 500;
            logData.responseJSON = JSON.serialize(new ResponseWrapper(e.getMessage(), 500));
            logData.lineNumber = e.getLineNumber();

            RestContext.response.statusCode = 500;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(new ResponseWrapper(e.getMessage(), 500)));
        }finally{
            IntegrationLogHelper.createIntegrationLog(logData);
        }
    }
    
    @HttpPost
    global static void post() {
        RestRequest req = RestContext.request;
        IntegrationLogHelper.IntegrationLogWrapper logData = new IntegrationLogHelper.IntegrationLogWrapper();
        logData.className = 'MeteringOtherSourceWebService';
        logData.methodName = 'post';
        logData.requestMethod = 'POST';
        logData.endPointURL = req.requestURI;
        
        try{
            String requestBody = req.requestBody.toString();
            String apiKey = req.headers.get('x-api-key');
            
            if (!isValidApiKey('MeteringOtherSourceWebService', apiKey)) {
                RestContext.response.statusCode = 401;
                RestContext.response.responseBody = Blob.valueOf('Unauthorized');
                logData.status = 'Failed';
                logData.message = 'Unauthorized: Invalid API Key';
                logData.statusCode = 401;
                return;
            }
            
            String responseBody = 'Request received successfully.';
            ResponseWrapper responseWrapper = new ResponseWrapper(responseBody, 200);
            
            // Set the response status code
            RestContext.response.statusCode = responseWrapper.statusCode;
            
            // Set the response body
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseWrapper));
            
            // Log the received request body for debugging
            System.debug('Received Request Body: ' + requestBody);
            logData.requestJSON = requestBody;
            logData.status = 'Success';
            logData.message = responseWrapper.message;
            logData.statusCode = 200;
            logData.responseJSON = JSON.serialize(responseWrapper);
            
            // Log completion of processing
            System.debug('Processing completed for the received request.');
        }
        catch(Exception e){
            System.debug('Error: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
            logData.className = 'MeteringOtherSourceWebService';
            logData.status = 'Failed';
            logData.message = e.getMessage();
            logData.statusCode = 500;
            logData.responseJSON = JSON.serialize(new ResponseWrapper(e.getMessage(), 500));
            logData.lineNumber = e.getLineNumber();
            RestContext.response.statusCode = 500;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(new ResponseWrapper(e.getMessage(), 500)));
        }
        finally{
            IntegrationLogHelper.createIntegrationLog(logData);
        }
    }
    
    public static Boolean isValidApiKey(String developerName,String receivedKey) {
        if (String.isBlank(receivedKey)) return false;
        
        Webhook_Config__mdt cfg =
            Webhook_Config__mdt.getInstance(developerName);
        
        return cfg != null
            && cfg.Active__c
            && receivedKey == cfg.Api_Key__c;
    }
    
    global class ResponseWrapper {
        public String message;
        public Integer statusCode;
        
        public ResponseWrapper(String message, Integer statusCode) {
            this.message = message;
            this.statusCode = statusCode;
        }
    }
}