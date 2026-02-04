public with sharing class ClickToCallController {
    @AuraEnabled(cacheable=true)
    public static String getCurrentUserAgentId() {
        String agentId = [SELECT Agent_Id__c FROM User WHERE Id = :UserInfo.getUserId()].Agent_Id__c;
        return agentId;
    }

    @AuraEnabled
    public static String initiateCall(String agentId, String phoneNumber) {
        try {
            // Make the call
            HttpRequest req = new HttpRequest();
            req.setEndpoint(System.label.Asttecs);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            
            C2CWrapper requestBody = new C2CWrapper();
            requestBody.user = agentId;
            requestBody.number_ToDial = phoneNumber;
            req.setBody(JSON.serialize(requestBody));
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            Integration_Log__c log = new Integration_Log__c();
            log.Class_Name__c = 'SmsApiCallout';
            log.Endpoint_URL__c =System.label.Asttecs;
            log.Method_Name__c ='initiateCall';
            log.Status_Code__c=res.getStatusCode();
            log.Response_Body__c=res.getBody();
            log.Request_Method__c='POST';
            log.Request_Body__c=String.valueOf(requestBody);
            insert log;
            if (res.getBody().trim().startsWith('{') || res.getBody().trim().startsWith('[')) {
                CallResponse result = (CallResponse) JSON.deserialize(res.getBody(), CallResponse.class);
                return result.message;
            }
            else{
                return 'Error Occurred';
            }
        } catch(Exception ex){
			Error_Logger__c err=Error_LoggerClass.createErrorLogger('ClickToCallController', 'initiateCall',null,ex.getTypeName(), ex.getMessage(),ex.getLineNumber(),true);
            insert err;
            return 'Error Occurred';
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Account> getAccountsByPhone(String phoneNumber) {
            // Search for accounts with matching phone number
            List<Account> accounts = [
                SELECT Id, Name, Phone 
                FROM Account 
                WHERE Phone = :phoneNumber
            ];
            return accounts;
    }

    public class C2CWrapper {
        public string user;
        public string number_ToDial;
    }
    
    public class CallResponse {
        public Boolean success;
        public String message;
    }
    
 
    @AuraEnabled(cacheable=true)
    public static String getPhoneByRecordId(Id recordId) {
        if (String.isBlank(recordId) || !string.valueof(recordId).startsWith('001')) {
    return null;
}

        Account acc = [
            SELECT Phone 
            FROM Account 
            WHERE Id = :recordId 
            LIMIT 1
        ];

        return acc != null ? acc.Phone : null;
    }
}