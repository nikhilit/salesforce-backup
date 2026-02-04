public with sharing class SAPCalloutService {
    
    @AuraEnabled(cacheable=true)
    public static SAP_Response fetchSAPData(String bpId) {
        String url = System.label.ChangeHistoryCallout + EncodingUtil.urlEncode(bpId, 'UTF-8');
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(url);
        request.setMethod('GET');
        request.setTimeout(60000); // optional: timeout in ms

        HttpResponse response = http.send(request);
        
        if (response.getStatusCode() == 200) {
            System.debug((SAP_Response) JSON.deserialize(response.getBody(), SAP_Response.class));
            return (SAP_Response) JSON.deserialize(response.getBody(), SAP_Response.class);
        } else {
            throw new AuraHandledException('Failed to fetch SAP data: ' + response.getStatus());
        }
    }

    public class SAP_Response {
        @AuraEnabled public String statusMessage;
        @AuraEnabled public String bpId;
        @AuraEnabled public List<SAP_Data> sapData;
    }

    public class SAP_Data {
        @AuraEnabled public String OBJECTID;
        @AuraEnabled public String USERNAME;
        @AuraEnabled public String UDATE;
        @AuraEnabled public String CHNGIND_DESC;
        @AuraEnabled public String FIELD_NAME;
        @AuraEnabled public String VALUE_NEW;
        @AuraEnabled public String VALUE_OLD;
    }
}