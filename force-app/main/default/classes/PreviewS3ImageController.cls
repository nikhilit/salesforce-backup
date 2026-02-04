/**
 * @description       :
 * @author            : Kartik Patkar Appstrail
 * @group             :
 * @last modified on  : 18-11-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   08-07-2025   Kartik Patkar, Appstrail   Initial Version
 **/
public with sharing class PreviewS3ImageController {
    
    @AuraEnabled
    public static String getS3URL(String recordId) {
        try {
            if (String.isBlank(recordId)) {
                throw new AuraHandledException('Record ID cannot be blank.');
            }
            
            // Extract 3-char prefix
            String prefix = recordId.substring(0, 3);
            
            // Map prefixes → object names
            Map<String, String> prefixToObject = new Map<String, String>{
                'a0h' => 'Document__c',
                'a0i' => 'Meter_Reading_OCR__c'
            };
            
            // Identify the object
            if (!prefixToObject.containsKey(prefix)) {
                throw new AuraHandledException(
                    'Unsupported RecordId prefix ' + prefix + '. Cannot determine object.'
                    );
            }
            
            String objectName = prefixToObject.get(prefix);
            
            // Build dynamic SOQL
            String q = 'SELECT Id, S3_Key__c, View_URL__c, S3_Bucket_Name__c' +
                ' FROM ' + objectName +
                ' WHERE Id = :recordId LIMIT 1';
            
            SObject rec = Database.query(q);
            
            if (rec == null) {
                throw new AuraHandledException('Record not found for the provided ID.');
            }
            
            String s3Key = (String)rec.get('S3_Key__c');
            String bucket = (String)rec.get('S3_Bucket_Name__c');
            
            if (String.isBlank(s3Key) || String.isBlank(bucket)) {
                throw new AuraHandledException(
                    'S3 Key or Bucket is missing on the record.'
                    );
            }
            
            // Call API to generate preview URL
            AWSS3FileUploadAPI.ResponseBodyWrapper response = new AWSS3FileUploadAPI.ResponseBodyWrapper();
            if(objectName == 'Meter_Reading_OCR__c'){
                response=AWSS3FileUploadAPI.getS3ImageOCRPreviewURL(recordId, s3Key, bucket);
            }else{
                response=AWSS3FileUploadAPI.getS3ImagePreviewURL(recordId, s3Key, bucket);
            }
            
            // Log integration calls
            if (AWSS3FileUploadAPI.listIntegrationLogWrap != null &&
            !AWSS3FileUploadAPI.listIntegrationLogWrap.isEmpty()) {
                IntegrationLogHelper.createListIntegrationLog(
                    AWSS3FileUploadAPI.listIntegrationLogWrap
                    );
            }
            
            if (response == null || String.isBlank(response.url)) {
                throw new AuraHandledException('Failed to retrieve S3 preview URL.');
            }
            
            // Update the record with View_URL__c
            rec.put('View_URL__c', response.url);
            update rec;
            
            return response.url;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }
    
    
}