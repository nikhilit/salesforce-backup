public with sharing class ReceivableController {

    @AuraEnabled
    public static void updateAccountBalances(String bpNumber, String openingBalance, String due, String securityDeposit, String lastAmountPaid, String lastPaymentDate) {
        if (String.isBlank(bpNumber)) {
            throw new AuraHandledException('Missing BP Number');
        }

        List<Account> accs = [
            SELECT Id, BP_Number__c
            FROM Account
            WHERE BP_Number__c = :bpNumber
            LIMIT 1
        ];

        if (accs.isEmpty()) {
            throw new AuraHandledException('No Account found for BP Number ' + bpNumber);
        }

        Account accToUpdate = accs[0];
        if(Decimal.valueof(due)>0){
            accToUpdate.Open__c = due;
            accToUpdate.Credit__c='0.00';
            accToUpdate.Due__c = openingBalance;
        } else {
            accToUpdate.Credit__c=due;
            accToUpdate.Open__c ='0.00';
            accToUpdate.Due__c='0.00';
        }
        accToUpdate.Last_Amount_Paid__c = lastAmountPaid;
        accToUpdate.Security_Deposit__c = securityDeposit;
        accToUpdate.Last_Paid_Date__c = lastPaymentDate;
       
        update accToUpdate;
    }

    @AuraEnabled
    public static SAP_Response fetchSAPDataReceivables(String bpId) {
        String url = System.Label.ReceivableCallout + EncodingUtil.urlEncode(bpId, 'UTF-8');
        System.debug('url'+url);
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(url);
        request.setMethod('GET');
        if(Middleware_Token_Control__mdt.getInstance('GetReceivables').Token__c=='true'){
            String token = BillsCallout.getAccessToken();
            request.setHeader('Authorization', 'Bearer ' + token);
        }
        request.setTimeout(120000);

        HttpResponse response = http.send(request);
        
        if (response.getStatusCode() == 200) {
            SAP_Response sapResp = (SAP_Response) JSON.deserialize(response.getBody().replace('"CURRENCY"', '"CurrencyCode"'), SAP_Response.class);
            return sapResp;
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

    @AuraEnabled
    public static ChronologyWrapper fetchSAPDataChronologies(String bpId) {
        String url = System.Label.ChronologyCallout + EncodingUtil.urlEncode(bpId, 'UTF-8');
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(url);
        request.setMethod('GET');
        if(Middleware_Token_Control__mdt.getInstance('GetChronology').Token__c=='true'){
            String token = BillsCallout.getAccessToken();
            request.setHeader('Authorization', 'Bearer ' + token);
        }
        request.setTimeout(120000);

        HttpResponse response = http.send(request);

        if (response.getStatusCode() != 200) {
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

        ChronologyWrapper sapResp;
        if (response.getStatusCode() == 200) {
            sapResp = (ChronologyWrapper) JSON.deserialize(response.getBody().replace('"CURRENCY"', '"CURRENCYCODE"'), ChronologyWrapper.class);
        }
        return sapResp;
    }

    public class ChronologyWrapper {
        @AuraEnabled public String statusMessage;
        @AuraEnabled public String bpId;
        @AuraEnabled public List<Chronology> sapData;
    }

    public class Chronology {
        @AuraEnabled public String BUSPARTNER {get;set;}
        @AuraEnabled public String CONT_ACCT {get;set;}
        @AuraEnabled public String DOC_NO {get;set;}
        @AuraEnabled public String HTEXT {get;set;}
        @AuraEnabled public String BUDAT {get;set;}
        @AuraEnabled public String BLDAT {get;set;}
        @AuraEnabled public String NET_DATE {get;set;}
        @AuraEnabled public Decimal DEBIT {get;set;}
        @AuraEnabled public Decimal CREDIT {get;set;}
        @AuraEnabled public Decimal DOWN {get;set;}
        @AuraEnabled public String CURRENCYCODE {get;set;}
        @AuraEnabled public String GUID_C {get;set;}
        @AuraEnabled public String CHCKN {get;set;}
        @AuraEnabled public String ZSOP {get;set;}
        @AuraEnabled public String ZSOP_TEXT {get;set;}
        @AuraEnabled public String Z_CH_DATE {get;set;}
        @AuraEnabled public String Z_CH_REC_DATE {get;set;}
        @AuraEnabled public String Z_BANK_NAME {get;set;}
        @AuraEnabled public Decimal AMOUNT {get;set;}
        @AuraEnabled public String DDATE {get;set;}
        @AuraEnabled public String PDATE {get;set;}
        @AuraEnabled public String NDATE {get;set;}
        @AuraEnabled public String RTEXT {get;set;}
        @AuraEnabled public String MENGE {get;set;}
        @AuraEnabled public String MEINS {get;set;}
        @AuraEnabled public String OFFSET_GPART {get;set;}
        @AuraEnabled public String HVORG {get;set;}
        @AuraEnabled public String TVORG {get;set;}
        @AuraEnabled public String TXT30 {get;set;}
    }

    public class SAP_Response {
        @AuraEnabled public String statusMessage;
        @AuraEnabled public String bpId;
        @AuraEnabled public List<SAP_Data> sapData;
    }

    public class SAP_Data {
        @AuraEnabled public String BUSPARTNER { get; set; }
        @AuraEnabled public String CONT_ACCT { get; set; }
        @AuraEnabled public String DOC_NO { get; set; }
        @AuraEnabled public String HTEXT { get; set; }
        @AuraEnabled public Date BUDAT { get; set; }
        @AuraEnabled public Date BLDAT { get; set; }
        @AuraEnabled public Date NET_DATE { get; set; }
        @AuraEnabled public Decimal AMOUNT { get; set; }
        @AuraEnabled public String CurrencyCode { get; set; }
        @AuraEnabled public String GUID_R { get; set; }
        @AuraEnabled public Date NDATE { get; set; }
    }
}