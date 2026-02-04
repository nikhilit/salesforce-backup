public class NameTransferUpdate {
     
    @future(callout=true)
    public static void sendToSAPAsync(Set<Id> caseIds) {

        if (caseIds == null || caseIds.isEmpty()) {
            return;
        }
        List<Case> cases = [
            SELECT Id, New_email_id__c, New_Contact__c, New_First_Name__c, 
                   New_Middle_Name__c, New_Last_Name__c, New_Name__c, 
                   New_Salutation__c, Account.BP_Number__c, Move_Out_Date__c, 
                   Account.CA_Number__c, Docket_Number__c, SPOC__r.Name, 
                   Transfer_Type__c, Account.FirstName__c, Account.LastName__c,
                   Account.Middle_Name__c, Account.Account_Email__c, Account.Phone__c,
                   Account.Person_Title__c, Account.Full_Name__c,type__c,Sub_Type__c
            FROM Case 
            WHERE Id IN :caseIds
        ];
        Map<String, String> metaMap = new Map<String, String>();
        for (Case_New_Salutation__mdt meta : [
            SELECT Label__c, API_Name__c
            FROM Case_New_Salutation__mdt
        ]) {
            metaMap.put(meta.Label__c, meta.API_Name__c);
        }

        String endpointUrl = System.label.ReverseAPIURL + 'sap/nameTransfer/push';
        List<Integration_Log__c> logs = new List<Integration_Log__c>();

        // Prepare JSON array using JSONGenerator to maintain order
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartArray();

        for (Case c : cases) {
            String moveOutDateStr = c.Move_Out_Date__c != null ?
                DateTime.newInstance(c.Move_Out_Date__c, Time.newInstance(0, 0, 0, 0)).format('yyyy-MM-dd') : '';
            String postedDateStr = DateTime.newInstance(System.today(), Time.newInstance(0, 0, 0, 0)).format('yyyy-MM-dd');
            String value='X';
            String amount = System.Label.Amount_CRM;
            if(c.Transfer_Type__c =='Demise of Registered Customer'||c.Transfer_Type__c=='Builder Transfer' || c.Transfer_Type__c==null){
                value='';
                amount='';
            }
            
            // Use existing account data if new fields are empty
String title = !String.isBlank(c.New_Salutation__c)&&c.New_Salutation__c!='Dr.'
    ? c.New_Salutation__c
    : (c.Account != null && metaMap.containsKey(c.Account.Person_Title__c)
        ? metaMap.get(c.Account.Person_Title__c)
        : '');
            String firstName = !String.isBlank(c.New_First_Name__c) ? c.New_First_Name__c : c.Account?.FirstName__c;
            String middleName = !String.isBlank(c.New_Middle_Name__c) ? c.New_Middle_Name__c : c.Account?.Middle_Name__c;
            String lastName = !String.isBlank(c.New_Last_Name__c) ? c.New_Last_Name__c : c.Account?.LastName__c;
            String mobile = !String.isBlank(c.New_Contact__c) ? c.New_Contact__c : c.Account?.Phone__c;
            String email = !String.isBlank(c.New_email_id__c) ? c.New_email_id__c : c.Account?.Account_Email__c;

            // Use JSONGenerator to maintain exact field order
            gen.writeStartObject();
            gen.writeStringField('PARTNER', c.Account?.BP_Number__c != null ? c.Account.BP_Number__c : '');
            gen.writeStringField('VKONT', c.Account?.CA_Number__c != null ? c.Account.CA_Number__c : '');
            if(c.type__c=='Name Transfer Processed'){
                gen.writeStringField('TITLE', !String.isBlank(c.New_Salutation__c)&&c.New_Salutation__c!='Dr.'
    ? c.New_Salutation__c:'');
                gen.writeStringField('FNAME', !String.isBlank(c.New_First_Name__c) ? c.New_First_Name__c :'');
                gen.writeStringField('MNAME', !String.isBlank(c.New_Middle_Name__c) ? c.New_Middle_Name__c : '');
                gen.writeStringField('LNAME', !String.isBlank(c.New_Last_Name__c) ? c.New_Last_Name__c : '');
                gen.writeStringField('MOBILE', !String.isBlank(c.New_Contact__c) ? c.New_Contact__c : '');
                gen.writeStringField('EMAIL', !String.isBlank(c.New_email_id__c) ? c.New_email_id__c : '');
            }else{
                gen.writeStringField('TITLE', title != null ? title : '');
                gen.writeStringField('FNAME', firstName != null ? firstName : '');
                if(c.type__c=='Name Correction' && c.Sub_Type__c == 'Name Correction'){
                gen.writeStringField('MNAME', !String.isBlank(c.New_Middle_Name__c) ? c.New_Middle_Name__c : '');
            }
            else{
                gen.writeStringField('MNAME', middleName != null ? middleName : '');
            }
                gen.writeStringField('LNAME', lastName != null ? lastName : '');
                gen.writeStringField('MOBILE', mobile != null ? mobile : '');
            	gen.writeStringField('EMAIL', email != null ? email : '');
            }
            gen.writeStringField('BUDAT', postedDateStr);
            gen.writeStringField('AMOUNT', amount);
            gen.writeStringField('FI_POSTING', value);
            gen.writeEndObject();
        }

        gen.writeEndArray();
        String requestBody = gen.getAsString();
       
        System.debug('SAP Request Body: ' + requestBody);

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpointUrl);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        if(Middleware_Token_Control__mdt.getInstance('NameTransfer').Token__c=='true'){
            String token = BillsCallout.getAccessToken();
        req.setHeader('Authorization', 'Bearer ' + token);
        }
        req.setBody(requestBody);

        HttpResponse res;
        String responseBody;
        Integer statusCode;
        Boolean successFlag = false;

        try {
            res = http.send(req);
            responseBody = res.getBody();
            statusCode = res.getStatusCode();
            successFlag = (statusCode >= 200 && statusCode < 300);
        } catch (Exception e) {
            responseBody = e.getMessage();
            statusCode = null;
            successFlag = false;
        }

        // Create integration logs for each case
        for (Case c : cases) {
            Integration_Log__c log = new Integration_Log__c();
            log.Class_Name__c = 'Name Transfer to SAP';
            log.Endpoint_URL__c = endpointUrl;
            log.Request_Body__c = requestBody;
            log.Response_Body__c = responseBody;
            log.Status_Code__c = statusCode;
            log.Case__c = c.Id;
            logs.add(log);
        }

        if (!logs.isEmpty()) insert logs;
    }
}