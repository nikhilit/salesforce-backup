public class CaseUpdateToSAP implements Queueable, Database.AllowsCallouts {

    private List<String> caseIdStrings;

    // Payload wrapper
    public class CaseSAPPayload {
        public String COMPNO;
        public String SAPCOMPNO;
        public String locationcode;
        public String agentname;
        public String remarks;
        public String complaintDate;
        public String complaintTime;
        public String PARTNER;
        public String complaintby;
        public String ctype;
        public String f_coming;
        public String priority;
        public String custinfo;
        public String mob_number;
        public String telephone;
        public String vendname;
        public String department;
        public String areaIncharge;
        public String category;
        public String complainttype;
        public String status;
    }

    // Constructor
    public CaseUpdateToSAP(List<String> caseIdStrings) {
        this.caseIdStrings = caseIdStrings;
    }

    public void execute(QueueableContext qc) {
        if (caseIdStrings == null || caseIdStrings.isEmpty()) return;

        // 2) Build field set dynamically
        Set<String> fieldSet = new Set<String>{'Origin','Priority','IsClosedOnCreate','Created_Date_Old__c','Customer_Information__c','Telephone_Number__c','Area_In_Charge_Name__c',
            'Department__c','Category__c','Contact_Directions__c','Created_By__r.Name','Account.Phone__c','Status','Sub_Type__c','SPOC__r.Name','IsClosed','SAP_Docket_Number__c',
            'Docket_Number__c','Customer_BP_Number__c','Contacted_By__c','Attendance__r.Block__c','Remarks__c','Created_Date__c','Created_Time__c',
            'Send_SMS_to__c','Account_email__c','Sub_Type__c','Email__c','Agent_Location_Code__c','Agent_Id__c','Created_Date_Old__c','Complaint_Time__c','Telephone_Number__c'};

        // 3) Dynamic SOQL to fetch cases
        String soql = 'SELECT ' + String.join(new List<String>(fieldSet), ',') +
            ' FROM Case WHERE Id IN :caseIdStrings';
        List<Case> caseList = Database.query(soql);
        if (caseList.isEmpty()) return;

        Map<String, String> locationMapping = new Map<String, String>();
        for (Case_Location_SAP_Mapping__c  om : [SELECT Location_Code__c, SF_Value__c FROM Case_Location_SAP_Mapping__c]) {
            if (!String.isBlank(om.SF_Value__c) && !String.isBlank(om.Location_Code__c)) {
                locationMapping.put(om.SF_Value__c, om.Location_Code__c);
            }
        }

        // 5) Build payloads
        List<CaseSAPPayload> payloadList = new List<CaseSAPPayload>();
        for (Case c : caseList) {
            CaseSAPPayload payload = new CaseSAPPayload();
            if(c.Created_Date_Old__c!=null){
                payload.SAPCOMPNO = c.Docket_Number__c;
                payload.custinfo    = c.Customer_Information__c;
                payload.vendname    = c.Email__c;
                payload.locationcode = c.Agent_Location_Code__c;
                payload.agentname = c.Agent_Id__c;
                payload.complaintDate = String.valueOf(c.Created_Date_Old__c);
                payload.complaintTime = c.Complaint_Time__c;   
                payload.telephone = c.Telephone_Number__c;
                payload.areaIncharge =c.Area_In_Charge_Name__c;
            }else{
                payload.SAPCOMPNO = c.SAP_Docket_Number__c;
                payload.custinfo    = (c.IsClosedOnCreate) ? 'SL' : 'FD';
                payload.vendname    = c.Account_email__c;
                payload.locationcode = (c.Attendance__c!=null && c.Attendance__r.Block__c !=null) ? locationMapping.get(c.Attendance__r.Block__c):'';
                payload.agentname = c.Created_By__c!=null?c.Created_By__r.name:'';
                payload.complaintDate = String.valueOf(c.Created_Date__c);
                payload.complaintTime = String.valueOf(c.Created_Time__c);  
                payload.telephone = c.Account.Phone__c;
                payload.areaIncharge =c.SPOC__c!=null?c.SPOC__r.Name:'';
            }
            payload.COMPNO   = c.Docket_Number__c;
            payload.PARTNER     = c.Customer_BP_Number__c;
            payload.complaintby = c.Contacted_By__c;
            payload.ctype       = c.Origin;
            payload.f_coming    = c.Contact_Directions__c;
            payload.priority    = c.Priority;
            payload.mob_number  = c.Send_SMS_to__c;
            payload.department  = c.Department__c;
            payload.remarks = c.Remarks__c;
            payload.complainttype =c.Sub_Type__c;
            if(payload.custinfo=='SL'){
                payload.status='';
            }else{
                if(c.Status=='Actioned by Department'){
                    payload.status='TSRL';
                }else if(c.IsClosed){
                    payload.status='TSCO';
                }else{
                    payload.status='TSOS';
                }
            }
            payload.category=c.Category__c;
            payloadList.add(payload);
        }

        // 6) Serialize JSON array
        String requestBody = serializePayloadList(payloadList);

        // 7) Single HTTP call
        String endpointUrl = System.Label.ReverseAPIURL + 'sap/caseCreation/push';
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpointUrl);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        if(Middleware_Token_Control__mdt.getInstance('UpdateCase').Token__c=='true'){
            String token = BillsCallout.getAccessToken();
        req.setHeader('Authorization', 'Bearer ' + token);
        }
        req.setHeader('X-CSRF-Token', 'Fetch');
        req.setBody(requestBody);

        Http http = new Http();
        String responseBody;
        Integer statusCode;

        try {
            HttpResponse resp = http.send(req);
            responseBody = resp.getBody();
            statusCode = resp.getStatusCode();
        } catch (Exception callEx) {
            responseBody = callEx.getMessage();
            statusCode = null;
        }

        // 8) Insert integration log (one record for the bulk call)
        try {
            insert new Integration_Log__c(
                Class_Name__c = 'Case Update to SAP',
                Endpoint_URL__c = endpointUrl,
                Request_Body__c = requestBody,
                Response_Body__c = responseBody,
                Status_Code__c = statusCode
            );
        } catch (Exception e) {
            System.debug('Failed to insert integration logs: ' + e.getMessage());
        }
    }

    // Serialize List<CaseSAPPayload> into JSON array with field order
    private String serializePayloadList(List<CaseSAPPayload> payloadList) {
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartArray();

        for (CaseSAPPayload payload : payloadList) {
            gen.writeStartObject();
            gen.writeStringField('SF_CASE', payload.COMPNO != null ? payload.COMPNO : '');
            gen.writeStringField('COMPNO', payload.SAPCOMPNO != null ? payload.SAPCOMPNO : '');
            gen.writeStringField('AGENT', payload.agentname != null ? payload.agentname : '');
            gen.writeStringField('LOCATION', payload.locationcode != null ? payload.locationcode : '');
            gen.writeStringField('PARTNER', payload.PARTNER != null ? payload.PARTNER : '');
            gen.writeStringField('COMPDT', payload.complaintDate != null ? payload.complaintDate : null);
			gen.writeStringField('COMPTIME', payload.complaintTime != null ? payload.complaintTime : null);
            gen.writeStringField('COMPLAINTBY', payload.complaintby != null ? payload.complaintby : '');
            gen.writeStringField('CTYPE', payload.ctype != null ? payload.ctype : '');
            gen.writeStringField('F_COMING', payload.f_coming != null ? payload.f_coming : '');
            gen.writeStringField('PRIORITY', payload.priority != null ? payload.priority : '');
            gen.writeStringField('CUSTINFO', payload.custinfo != null ? payload.custinfo : '');
            gen.writeStringField('MOB_NUMBER', payload.mob_number != null ? payload.mob_number : '');
            gen.writeStringField('TEL_NUMBER', payload.telephone != null ? payload.telephone : '');
            gen.writeStringField('VENDNAME', payload.vendname != null ? payload.vendname : '');
            gen.writeStringField('DEPARTMENT', payload.department != null ? payload.department : '');
            gen.writeStringField('INCH_NAME', payload.areaIncharge != null ? payload.areaIncharge : '');
            gen.writeStringField('CATEGORY', payload.category != null ? payload.category : '');
            gen.writeStringField('COMPTYPE', payload.complainttype != null ? payload.complainttype : '');
            gen.writeStringField('STTXT', payload.status != null ? payload.status : '');
            gen.writeStringField('REMARKS', payload.remarks != null ? payload.remarks : '');
            gen.writeEndObject();
        }

        gen.writeEndArray();
        return gen.getAsString();
    }
}