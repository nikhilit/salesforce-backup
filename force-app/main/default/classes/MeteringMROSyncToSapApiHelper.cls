/**
 * @description       :
 * @author            : Kartik Patkar Appstrail
 * @group             :
 * @last modified on  : 22-09-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   21-09-2025   Kartik Patkar, Appstrail   Initial Version
 **/
public without sharing class MeteringMROSyncToSapApiHelper {
    
    // Logging wrapper used for capturing integration logs
    public static List<IntegrationLogHelper.IntegrationLogWrapper> listIntegrationLogWrap = new List<IntegrationLogHelper.IntegrationLogWrapper>();
    
    public static String syncToSAP(String payload, Id mroId,MRO_Sync_to_SAP_API_Config__mdt config) {
        IntegrationLogHelper.IntegrationLogWrapper integrationLogWrap = new IntegrationLogHelper.IntegrationLogWrapper();
        integrationLogWrap.className = 'MeteringMROSyncToSapApiHelper';
        integrationLogWrap.methodName = 'syncToSAP';
        integrationLogWrap.meterReadingOrderId = mroId;
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        try {
            if (config == null) {
                integrationLogWrap.message = 'SAP API Configuration not found.';
                integrationLogWrap.status='Failed';
                listIntegrationLogWrap.add(integrationLogWrap);
                return null;
            }
            
            String endpoint = config.Endpoint_URL__c;
            request.setEndpoint(endpoint);
            request.setMethod('POST');
            request.setHeader('Content-Type', config.Content_Type__c);
            request.setHeader('X-CSRF-Token', config.X_CSRF_Token__c);
            request.setBody(payload);
            
            HttpResponse response = http.send(request);
            
            // Capture request and response details in the log
            integrationLogWrap.endPointURL = request.getEndpoint();
            integrationLogWrap.requestMethod = request.getMethod();
            integrationLogWrap.requestJSON = request.getBody();
            integrationLogWrap.statusCode = response.getStatusCode();
            integrationLogWrap.responseJSON = response.getBody();
            
            if (response.getStatusCode() == 200) {
                integrationLogWrap.message = 'Synced to SAP successfully.';
                integrationLogWrap.status='Success';
                listIntegrationLogWrap.add(integrationLogWrap);
                return 'Success';
            } else {
                integrationLogWrap.message = 'Failed to sync to SAP.';
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
    
    public static String payloadBuilder(Meter_Reading_Order__c mroRec,List<MRO_Sync_to_SAP_Field_Mapping__c> fieldMappingList){
        Map<String, Object> payloadMap = new Map<String, Object>();
        
        for (MRO_Sync_to_SAP_Field_Mapping__c mapping : fieldMappingList) {
            if (mapping.Active__c && mapping.Object_Api_Name__c == 'Meter_Reading_Order__c') {
                
                // Get field value dynamically from record
                Object fieldValue = mroRec.get(mapping.Field_Api_Name__c);
                
                // Only include non-null values
                payloadMap.put(mapping.External_Field_Name__c, fieldValue==null ? '' : fieldValue);
            }
        }
        
        // Convert map to JSON
        return JSON.serialize(payloadMap);
    }
}