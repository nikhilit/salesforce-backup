public with sharing class MinimunChargesHistory {

    public class InstallationResponseWrapper {
        @AuraEnabled public String statusMessage {get; set;}
        @AuraEnabled public String installation {get; set;}
        @AuraEnabled public List<InstallationRecord> sapData {get; set;}
    }

    public class InstallationRecord {
        @AuraEnabled public String ANLAGE {get; set;}
        @AuraEnabled public String AB {get; set;}
        @AuraEnabled public String BIS {get; set;}
        @AuraEnabled public String STRING3 {get; set;}
    }

    @AuraEnabled(cacheable=true)
    public static InstallationResponseWrapper fetchInstallationData(String installationId) {
        if (String.isBlank(installationId)) {
            throw new AuraHandledException('Installation Id is required');
        }

        String url = System.label.Minimum_Charges_History + EncodingUtil.urlEncode(installationId, 'UTF-8');
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod('GET');
        if(Middleware_Token_Control__mdt.getInstance('MinimumChargesHistory').Token__c=='true'){
            String token = BillsCallout.getAccessToken();
            req.setHeader('Authorization', 'Bearer ' + token);
        }
        req.setTimeout(120000);
        HttpResponse res = http.send(req);

        // ✅ handle case when no records found
        if (res.getStatusCode() == 500 && res.getBody().contains('No records found for installation Number')) {
            InstallationResponseWrapper responseWrapper = new InstallationResponseWrapper();
            responseWrapper.statusMessage = 'No Minimum Charge History Records Found for this BP.';
            return responseWrapper;
        }

        if (res.getStatusCode() != 200) {
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
            
            throw new AuraHandledException('Failed to fetch Installation data: ' + errorMessage);
        }

        System.debug('SAP Response >>> ' + res.getBody());

        return (InstallationResponseWrapper) JSON.deserialize(res.getBody(), InstallationResponseWrapper.class);
    }

    @AuraEnabled(cacheable=true)
    public static String getInstallationId(Id accountId) {
        List<Move_In_Out__c> moveOut = [
            SELECT Installation__c 
            FROM Move_In_Out__c 
            WHERE BP_Number__c = :accountId
            AND Move_Out__c != NULL
            ORDER BY Move_Out__c DESC
            LIMIT 1
        ];
        return moveOut.size()>0 ? moveOut[0].Installation__c : null;
    }
}