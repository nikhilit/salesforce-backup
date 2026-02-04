public class SecurityDepositLwcHandler {

    @AuraEnabled
    public static SAP_Response fetchSAPData(String bpId) {
        if (String.isBlank(bpId)) {
            throw new AuraHandledException('BP Number is required');
        }

        String url = System.Label.SecurityDepositCallout + EncodingUtil.urlEncode(bpId, 'UTF-8');
        System.debug('SAP URL: ' + url);

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(url);
        request.setMethod('GET');
        if(Middleware_Token_Control__mdt.getInstance('GetSecurityDeposit').Token__c=='true'){
            String token = BillsCallout.getAccessToken();
            request.setHeader('Authorization', 'Bearer ' + token);
        }
        request.setTimeout(120000);

        HttpResponse response = http.send(request);

        if (response.getStatusCode() == 200) {
            SAP_Response sapResponse = (SAP_Response) JSON.deserialize(response.getBody(), SAP_Response.class);
            return sapResponse;
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
        @AuraEnabled public String GPART { get; set; }
        @AuraEnabled public String SECURITY { get; set; }
        @AuraEnabled public Date SEC_START { get; set; }
        @AuraEnabled public Date SEC_END { get; set; }
        @AuraEnabled public String WAERS { get; set; }
        @AuraEnabled public Decimal REQUEST { get; set; }
        @AuraEnabled public Decimal PAID { get; set; }
        @AuraEnabled public String STATUS  { get; set; }
        @AuraEnabled public String NON_CASH  { get; set; }
        @AuraEnabled public String GUID_R  { get; set; }
        @AuraEnabled public String VKONT  { get; set; }
    }
}