/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 22-01-2026
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   03-07-2025   Kartik Patkar, Appstrail   Initial Version
**/
public with sharing class AWSS3FileUploadAPI {
    public static final String CLASS_NAME = 'AWSS3FileUploadAPI';
    public static List<IntegrationLogHelper.IntegrationLogWrapper> listIntegrationLogWrap = new List<IntegrationLogHelper.IntegrationLogWrapper>();
   
    public static ResponseBodyWrapper getPresignedURL(String recordId, String fileName, String BPNumber,Boolean forOCR,Boolean isMRS) {
        IntegrationLogHelper.IntegrationLogWrapper integrationLogWrap = new IntegrationLogHelper.IntegrationLogWrapper();
        integrationLogWrap.className = CLASS_NAME;
        integrationLogWrap.methodName = 'getPresignedURL';
        if(forOCR){
            integrationLogWrap.meterReadingOCRID = recordId;
        }else{
            integrationLogWrap.documentId = recordId;
        }
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        try {
            
            if (BPNumber==null || BPNumber=='') {
                integrationLogWrap.message = 'BP Number is empty.';
                integrationLogWrap.status='Error';
                listIntegrationLogWrap.add(integrationLogWrap);
                return null;
            }
            
            List<Meter_Reading_OCR_API_Config__mdt> documentOcrSettings = [SELECT Id,Generate_Presigned_URL_Endpoint__c,API_Key__c 
                                                                        FROM Meter_Reading_OCR_API_Config__mdt 
                                                                        WHERE Active__c=TRUE LIMIT 1];
            
            if(documentOcrSettings.isEmpty()){
                integrationLogWrap.message = 'There is no active AWS S3 API Config found';
                integrationLogWrap.status='Error';
                listIntegrationLogWrap.add(integrationLogWrap);
                return null;
            }
            
            String endpoint = documentOcrSettings[0].Generate_Presigned_URL_Endpoint__c;
            String apiKey = documentOcrSettings[0].API_Key__c != null ? documentOcrSettings[0].API_Key__c.trim() : '';
            
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('x-api-key', apiKey);
            request.setEndpoint(endpoint);
            
            RequestBodyWrapper requestBody = new RequestBodyWrapper();
            requestBody.Id = recordId;
            requestBody.filename = fileName;
            requestBody.BPNO = BPNumber;
            requestBody.source = 'salesforce';
            requestBody.ocr = forOCR;
            requestBody.ismrs = isMRS;
            request.setTimeout(120000);
            request.setBody(requestBody.serialize());
            
            // System.debug('=== REQUEST DETAILS ===');
            // System.debug('Endpoint: ' + endpoint);
            // System.debug('Method: POST');
            // System.debug('API Key: ' + apiKey);
            // System.debug('API Key Length: ' + apiKey.length());
            // System.debug('Content-Type: ' + request.getHeader('Content-Type'));
            // System.debug('x-api-key: ' + request.getHeader('x-api-key'));
            // System.debug('Request Body: ' + request.getBody());
            // System.debug('======================');
            
            HTTPResponse response = http.send(request);
            
            // Log and return response
            integrationLogWrap.requestMethod = request.getMethod();
            integrationLogWrap.endPointURL = request.getEndpoint();
            integrationLogWrap.requestJSON = request.getBody();
            integrationLogWrap.responseJSON = response.getBody();
            integrationLogWrap.statusCode = response.getStatusCode();
            
            if (response.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                String responseBody = (String)responseMap.get('body');
                ResponseBodyWrapper responseBodyWrapper = parse(responseBody);
                
                integrationLogWrap.message = 'Message sent successfully.';
                integrationLogWrap.status='Success';
                listIntegrationLogWrap.add(integrationLogWrap);
                return responseBodyWrapper;
            }else{
                System.debug('API Failed - Status Code: ' + response.getStatusCode());
                System.debug('Response Body: ' + response.getBody());
                System.debug('Response Status: ' + response.getStatus());
                integrationLogWrap.message = 'API Failed - Status: ' + response.getStatusCode() + ', Body: ' + response.getBody();
                integrationLogWrap.status='Failed';
                listIntegrationLogWrap.add(integrationLogWrap);
                return null;
            }
        } catch(Exception e) {
            integrationLogWrap.message = e.getMessage();
            integrationLogWrap.lineNumber = e.getLineNumber();
            integrationLogWrap.status='Failed';
            listIntegrationLogWrap.add(integrationLogWrap);
            return null;
        }
    }
    
    public static Map<String, Object> sendDocument(String recordId,ResponseBodyWrapper responseBodyWrapper,Blob file,String fileExtension,Boolean ocr) {
        IntegrationLogHelper.IntegrationLogWrapper integrationLogWrap = new IntegrationLogHelper.IntegrationLogWrapper();
        integrationLogWrap.className = CLASS_NAME;
        integrationLogWrap.methodName = 'sendDocumentToOCR';
        if(ocr){
            integrationLogWrap.meterReadingOCRID = recordId;
        }else{
             integrationLogWrap.documentId = recordId;
        }
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        Map<String, Object> resultMap = new Map<String, Object>();
        
        try {
            String endpoint = responseBodyWrapper.uploadUrl;
            request.setMethod('PUT');
            
            // Dynamically set Content-Type
            String contentType = getContentTypeFromExtension(fileExtension);
            request.setHeader('Content-Type', contentType);
            request.setHeader('x-amz-meta-source', 'salesforce');
            request.setHeader('x-amz-meta-bpno', responseBodyWrapper.metadata.bpno);
            request.setHeader('x-amz-meta-customerid', responseBodyWrapper.metadata.customerid);
            request.setHeader('x-amz-meta-ocr', String.valueOf(responseBodyWrapper.ocr));
            request.setHeader('x-amz-meta-ismrs', String.valueOf(responseBodyWrapper.ismrs));
            request.setTimeout(120000);
            request.setBodyAsBlob(file);
            request.setEndpoint(responseBodyWrapper.uploadUrl);
            HTTPResponse response = http.send(request);
            
            // Log and return response
            integrationLogWrap.requestMethod = request.getMethod();
            integrationLogWrap.endPointURL = request.getEndpoint();
            integrationLogWrap.requestJSON = request.getBody();
            integrationLogWrap.responseJSON = response.getBody();
            integrationLogWrap.statusCode = response.getStatusCode();
            
            if (response.getStatusCode() == 200) {
                integrationLogWrap.message = 'Message sent successfully.';
                integrationLogWrap.status='Success';
                listIntegrationLogWrap.add(integrationLogWrap);
                resultMap.put('status', 'success');
                resultMap.put('response',responseBodyWrapper);
                return resultMap;
            }else{
                integrationLogWrap.message = 'API Failed.';
                integrationLogWrap.status='Failed';
                listIntegrationLogWrap.add(integrationLogWrap);
                resultMap.put('status', 'failed');
                return resultMap;
            }
        } catch(Exception e) {
            integrationLogWrap.message = e.getMessage();
            integrationLogWrap.lineNumber = e.getLineNumber();
            integrationLogWrap.status='Failed';
            listIntegrationLogWrap.add(integrationLogWrap);
            return null;
        }
    }

    public static ResponseBodyWrapper getS3ImagePreviewURL(String recordId,String s3Key,String bucketName){
        IntegrationLogHelper.IntegrationLogWrapper integrationLogWrap = new IntegrationLogHelper.IntegrationLogWrapper();
        integrationLogWrap.className = CLASS_NAME;
        integrationLogWrap.methodName = 'getS3ImagePreviewURL';
        integrationLogWrap.documentId = recordId;
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        HTTPResponse response = new HTTPResponse();
        
        try {
            List<Meter_Reading_OCR_API_Config__mdt> documentOcrSettings = [SELECT Id,Image_Preview_URL_Endpoint__c 
                                                                        FROM Meter_Reading_OCR_API_Config__mdt 
                                                                        WHERE Active__c=TRUE LIMIT 1];
            
            if(documentOcrSettings.isEmpty()){
                integrationLogWrap.message = 'There is no active OCR API Config found';
                integrationLogWrap.status='Error';
                IntegrationLogHelper.createIntegrationLog(integrationLogWrap);
                return null;
            }
            
            String endpoint = documentOcrSettings[0].Image_Preview_URL_Endpoint__c;
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            request.setEndpoint(endpoint);
            RequestBodyWrapper requestBody = new RequestBodyWrapper();
            requestBody.bucket_name = bucketName;
            requestBody.object_key = s3Key;
            request.setTimeout(120000);
            request.setBody(requestBody.serialize());
            response = http.send(request);
            // Log and return response
            integrationLogWrap.requestMethod = request.getMethod();
            integrationLogWrap.endPointURL = request.getEndpoint();
            integrationLogWrap.requestJSON = request.getBody();
            integrationLogWrap.responseJSON = response.getBody();
            integrationLogWrap.statusCode = response.getStatusCode();

            if (response.getStatusCode() == 200) {
                integrationLogWrap.message = 'Image Preview URL fetched successfully.';
                integrationLogWrap.status='Success';
                listIntegrationLogWrap.add(integrationLogWrap);
                Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                String responseBody = (String)responseMap.get('body');
                ResponseBodyWrapper responseBodyWrapper = parse(responseBody);

                return responseBodyWrapper;
            }else{
                integrationLogWrap.message = 'API Failed.';
                integrationLogWrap.status='Failed';
                listIntegrationLogWrap.add(integrationLogWrap);
                return null;
            }
        } catch(Exception e) {
            integrationLogWrap.message = e.getMessage();
            integrationLogWrap.lineNumber = e.getLineNumber();
            integrationLogWrap.status='Failed';
            listIntegrationLogWrap.add(integrationLogWrap);
            return null;
        }
    }

    public static ResponseBodyWrapper getS3ImageOCRPreviewURL(String recordId,String s3Key,String bucketName){
        IntegrationLogHelper.IntegrationLogWrapper integrationLogWrap = new IntegrationLogHelper.IntegrationLogWrapper();
        integrationLogWrap.className = CLASS_NAME;
        integrationLogWrap.methodName = 'getS3ImagePreviewURL';
        integrationLogWrap.meterReadingOCRID = recordId;
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        HTTPResponse response = new HTTPResponse();
        
        try {
            List<Meter_Reading_OCR_API_Config__mdt> documentOcrSettings = [SELECT Id,Image_Preview_URL_Endpoint__c 
                                                                        FROM Meter_Reading_OCR_API_Config__mdt 
                                                                        WHERE Active__c=TRUE LIMIT 1];
            
            if(documentOcrSettings.isEmpty()){
                integrationLogWrap.message = 'There is no active OCR API Config found';
                integrationLogWrap.status='Error';
                IntegrationLogHelper.createIntegrationLog(integrationLogWrap);
                return null;
            }
            
            String endpoint = documentOcrSettings[0].Image_Preview_URL_Endpoint__c;
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            request.setEndpoint(endpoint);
            RequestBodyWrapper requestBody = new RequestBodyWrapper();
            requestBody.bucket_name = bucketName;
            requestBody.object_key = s3Key;
            request.setTimeout(120000);
            request.setBody(requestBody.serialize());
            response = http.send(request);
            // Log and return response
            integrationLogWrap.requestMethod = request.getMethod();
            integrationLogWrap.endPointURL = request.getEndpoint();
            integrationLogWrap.requestJSON = request.getBody();
            integrationLogWrap.responseJSON = response.getBody();
            integrationLogWrap.statusCode = response.getStatusCode();

            if (response.getStatusCode() == 200) {
                integrationLogWrap.message = 'Image Preview URL fetched successfully.';
                integrationLogWrap.status='Success';
                listIntegrationLogWrap.add(integrationLogWrap);
                Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                String responseBody = (String)responseMap.get('body');
                ResponseBodyWrapper responseBodyWrapper = parse(responseBody);

                return responseBodyWrapper;
            }else{
                integrationLogWrap.message = 'API Failed.';
                integrationLogWrap.status='Failed';
                listIntegrationLogWrap.add(integrationLogWrap);
                return null;
            }
        } catch(Exception e) {
            integrationLogWrap.message = e.getMessage();
            integrationLogWrap.lineNumber = e.getLineNumber();
            integrationLogWrap.status='Failed';
            listIntegrationLogWrap.add(integrationLogWrap);
            return null;
        }
    }

    public class RequestBodyWrapper{
        public String Id { get; set; }
        public String filename { get; set; }
        public String source { get; set; }
        public String BPNO { get; set; }
        public Boolean ocr {get;set;}
        public String bucket_name { get; set; }
        public String object_key { get; set; }
        public Boolean ismrs { get; set; }
        
        public String serialize() {
            try {
                return System.JSON.serialize(this);
            } catch (Exception e) {
                System.debug('JSON serialization error: ' + e.getMessage());
                return null;
            }
        }
    }
    
    public class ResponseBodyWrapper{
        public String uploadUrl { get; set; }
        public String viewURL { get; set; }
        public String source { get; set; }
        public String s3Key { get; set; }
        public String bucket { get; set; }
        public Metadata metadata { get; set; }
        public Integer expiresIn { get; set; }
        public String url { get; set; }
        public Boolean ocr {get;set;}
        public Boolean ismrs {get;set;}
    }
    
    public class Metadata {
        public String customerid { get; set; }
        public String bpno { get; set; }
        public String source { get; set; }
    }
    
    public static ResponseBodyWrapper parse(String json) {
        try {
            return (ResponseBodyWrapper) System.JSON.deserialize(json, ResponseBodyWrapper.class);
        } catch (Exception e) {
            System.debug('JSON parsing error: ' + e.getMessage());
            throw new JSONException('Invalid JSON format for ResponseBodyWrapper');
        }
    }
    
    private static String getContentTypeFromExtension(String ext) {
        String extension = ext != null ? ext.trim().toLowerCase() : '';
        Map<String, String> contentTypeMap = new Map<String, String>{
            'jpg' => 'image/jpeg',
            'jpeg' => 'image/jpeg',
            'png' => 'image/png',
            'pdf' => 'application/pdf'
        };
        
        return contentTypeMap.containsKey(extension) ? contentTypeMap.get(extension) : 'image/jpeg';
    }
}