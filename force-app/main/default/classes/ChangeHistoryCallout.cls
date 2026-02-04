public with sharing class ChangeHistoryCallout {
    
    @AuraEnabled
    public static SAP_Response fetchSAPData(String bpId) {
        String url = System.label.ChangeHistoryCallout + EncodingUtil.urlEncode(bpId, 'UTF-8');
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(url);
        request.setMethod('GET');
        if(Middleware_Token_Control__mdt.getInstance('Changehistory').Token__c=='true'){
            String token = BillsCallout.getAccessToken();
            request.setHeader('Authorization', 'Bearer ' + token);
        }
        request.setTimeout(120000);

        HttpResponse response = http.send(request);
        
        if (response.getStatusCode() == 200) {
            System.debug((SAP_Response) JSON.deserialize(response.getBody(), SAP_Response.class));
            return (SAP_Response) JSON.deserialize(response.getBody(), SAP_Response.class);
        } else {
            String errorMessage = response.getBody();
            
            try {
                Map<String, Object> errorResponse = (Map<String, Object>) JSON.deserializeUntyped(errorMessage);
                if (errorResponse.containsKey('message')) {
                    errorMessage = (String) errorResponse.get('message');
                }
            } catch (Exception e) {
                if (String.isBlank(errorMessage)) {
                    errorMessage = response.getStatus();
                }
            }
            
            throw new AuraHandledException('Failed to fetch SAP data: ' + errorMessage);
        }
    }

    public class SAP_Response {
        @AuraEnabled public String statusMessage;
        @AuraEnabled public String bpId;
        @AuraEnabled public List<SAP_Data> sapData;
    }

    public class SAP_Data {
        @AuraEnabled public String TFLDNAME;
        @AuraEnabled public String USERNAME;
        @AuraEnabled public String UDATE;
        @AuraEnabled public String UTIME;
        @AuraEnabled public String KEYVAL;
        @AuraEnabled public String FLDNAME;
        @AuraEnabled public String F_NEW;
        @AuraEnabled public String F_OLD;
    }
}