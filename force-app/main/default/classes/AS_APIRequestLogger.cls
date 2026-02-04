/**
* @File Name : AS_APIRequestLogger.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : July 10, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | July 10, 2025 |   | Initial Version
**/
public class AS_APIRequestLogger {
    public static void logRequestResponse(Id workOrderId, String endpoint, Object request, HttpResponse response, String name) {
        Integration_Log__c log = new Integration_Log__c();
        log.Related_Record_Id__c = workOrderId;
		log.Log_Name__c = name;
        log.Endpoint_URL__c = endpoint;
        //log.Status__c = response.getStatus();
        log.Status_Code__c = response.getStatusCode();
        log.Request_Body__c = JSON.serialize(request);
        log.Response_Body__c = response.getBody();
        insert log;
    }
}