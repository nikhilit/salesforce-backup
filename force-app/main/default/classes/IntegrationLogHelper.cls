/**
 * @description       :
 * @author            : Kartik Patkar Appstrail
 * @group             :
 * @last modified on  : 21-09-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   04-06-2025   Kartik Patkar, Appstrail   Initial Version
 **/
public with sharing class IntegrationLogHelper {
    
    /**
     * @description
     * @author Kartik Patkar, Appstrail | 17-01-2023
     * @param IntegrationLogWrapper integrationLogData
     **/
    public static void createIntegrationLog(IntegrationLogWrapper integrationLogData){
        insert fieldMapping(integrationLogData);
    }
    
    /**
     * @description
     * @author Kartik Patkar, Appstrail | 02-04-2023
     * @param List<IntegrationLogWrapper> integrationLogData
     **/
    public static void createListIntegrationLog(List<IntegrationLogWrapper> integrationLogData){
        List<Integration_Log__c> integrationLogRecord=new List<Integration_Log__c>();
        for(IntegrationLogWrapper integrationData:integrationLogData){
            if((integrationData.status=='Success' && System.label.Enable_Success_Integration_Log=='TRUE') ||
            (integrationData.status=='Failed' && System.label.Enable_Error_Integration_Log=='TRUE')){
                integrationLogRecord.add(fieldMapping(integrationData));
            }
        }
        if(integrationLogRecord.size()>0){
            insert integrationLogRecord;
        }
    }
    
    /**
     * @description
     * @author Kartik Patkar, Appstrail | 02-04-2023
     * @param IntegrationLogWrapper integrationLogData
     * @return Integration_Log__c
     **/
    public static Integration_Log__c fieldMapping(IntegrationLogWrapper integrationLogData){
        Integration_Log__c integrationLogRec=new Integration_Log__c();
        integrationLogRec.Request_Body__c=safeTruncate(integrationLogData.requestJSON,131072);
        integrationLogRec.Response_Body__c=safeTruncate(integrationLogData.responseJSON,131072);
        integrationLogRec.Class_Name__c=integrationLogData.className;
        integrationLogRec.Endpoint_URL__c=safeTruncate(integrationLogData.endPointURL,255);
        integrationLogRec.Line_Number__c=integrationLogData.lineNumber;
        integrationLogRec.Request_Method__c=integrationLogData.requestMethod;
        integrationLogRec.Status_Code__c=integrationLogData.statusCode;
        integrationLogRec.Method_Name__c=integrationLogData.methodName;
        integrationLogRec.Message__c=integrationLogData.message;
        integrationLogRec.Notification__c=integrationLogData.notificationId;
        integrationLogRec.Meter_Reading_OCR__c=integrationLogData.meterReadingOCRID;
        integrationLogRec.Document__c=integrationLogData.documentId;
        integrationLogRec.Status__c=integrationLogData.status;
        integrationLogRec.Work_Order__c=integrationLogData.workOrderId;
        integrationLogRec.Meter_Reading_Order__c=integrationLogData.meterReadingOrderId;
        return integrationLogRec;
    }
    
    public static String safeTruncate(String input, Integer maxLength) {
        if (String.isBlank(input)) return input;
        
        if (maxLength == null || maxLength <= 3) maxLength = 255;
        
        if (input.length() > maxLength) {
            return input.substring(0, maxLength - 3) + '...';
        }
        return input;
    }
    
    //WRAPPER CLASS
    public class IntegrationLogWrapper{
        public Decimal statusCode;
        public String status;
        public String requestJSON;
        public String responseJSON;
        public String className;
        public Decimal lineNumber;
        public String requestMethod;
        public String endPointURL;
        public String methodName;
        public String message;
        public String notificationId;
        public String workOrderId;
        public String meterReadingOCRID;
        public String documentId;
        public String meterReadingOrderId;
    }
    
}