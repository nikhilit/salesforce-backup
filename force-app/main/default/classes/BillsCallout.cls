public with sharing class BillsCallout {
    public static String getAccessToken() {
        Http http = new Http();
        HttpRequest req = new HttpRequest();

        req.setEndpoint(System.Label.Bill_access_Token);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(120000);

        Map<String, String> body = new Map<String, String>{
            'username' => System.Label.Username,
            'password' => System.Label.Password
        };

        req.setBody(JSON.serialize(body));

        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            return (String) responseMap.get('token');
        } else {
            String errorMessage = res.getBody();
            
            try {
                Map<String, Object> errorResponse = (Map<String, Object>) JSON.deserializeUntyped(errorMessage);
                if (errorResponse.containsKey('message')) {
                    errorMessage = (String) errorResponse.get('message');
                }
            } catch (Exception e) {
                if (String.isBlank(errorMessage)) {
                    errorMessage = res.getStatus();
                }
            }
            
            throw new AuraHandledException('Failed to get Access Token: ' + errorMessage);
        }
    }
    
    @AuraEnabled
    public static String getPdfFromAPI(String billPrintNumber) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(System.label.Get_BIll_PDF + EncodingUtil.urlEncode(billPrintNumber, 'UTF-8'));
        request.setMethod('GET');
        if(Middleware_Token_Control__mdt.getInstance('GetBillPDF').Token__c=='true'){
            String token = getAccessToken();
            request.setHeader('Authorization', 'Bearer ' + token);
        }
        request.setTimeout(120000);
        
        HttpResponse response = http.send(request);
        
        if (response.getStatusCode() == 200) {
            return response.getBody();
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
            
            throw new AuraHandledException('Failed to fetch PDF: ' + errorMessage);
        }
    }
    
    @AuraEnabled
    public static SAP_Response fetchSAPData(String bpId, String fromDate, String toDate) {
        String url = System.Label.BillCallout + EncodingUtil.urlEncode(bpId, 'UTF-8') + '&fromDate=' + EncodingUtil.urlEncode(fromDate, 'UTF-8') + '&toDate=' + EncodingUtil.urlEncode(toDate, 'UTF-8');
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(url);
        request.setMethod('GET');
        if(Middleware_Token_Control__mdt.getInstance('GetBillsByDate').Token__c=='true'){
            String token = getAccessToken();
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
        @AuraEnabled public String salesforceStatus;
        @AuraEnabled public String bpId;
        @AuraEnabled public List<SAP_Data> sapData;
    }

    public class SAP_Data {
        @AuraEnabled public String OPBEL { get; set; }
        @AuraEnabled public String BELNR { get; set; }
        @AuraEnabled public String PARTNER { get; set; }
        @AuraEnabled public String VKONT { get; set; }
        @AuraEnabled public String VERTRAG { get; set; }
        @AuraEnabled public String PORTION { get; set; }
        @AuraEnabled public String ABLEINH { get; set; }
        @AuraEnabled public String ABRVORG { get; set; }
        @AuraEnabled public Date BUDAT { get; set; }
        @AuraEnabled public Date BLDAT { get; set; }
        @AuraEnabled public Date BEGABRPE { get; set; }
        @AuraEnabled public Date ENDABRPE { get; set; }
        @AuraEnabled public Decimal TOTAL_AMNT { get; set; }
        @AuraEnabled public Date FAEDN { get; set; }
        @AuraEnabled public String ZZ_TAXINVNO { get; set; }
    }
}