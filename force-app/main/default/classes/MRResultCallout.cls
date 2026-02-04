public with sharing class MRResultCallout {
    
    @AuraEnabled
    public static SAP_Response fetchSAPData(String device){
        
        if (String.isBlank(device)) {
            throw new AuraHandledException('Device Id is required');
        }

        // --- Call SAP and get response
        String url = System.label.MRResultCallout + EncodingUtil.urlEncode(device, 'UTF-8');
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(url);
        request.setMethod('GET');
        if(Middleware_Token_Control__mdt.getInstance('GetMRResult').Token__c=='true'){
         String token = BillsCallout.getAccessToken();
        request.setHeader('Authorization', 'Bearer ' + token);
        }
        request.setTimeout(120000);
        HttpResponse response = http.send(request);

        // --- Check response status
        if (response.getStatusCode() != 200) {
            String errorMessage = response.getBody();
            
            // Try to parse the JSON error message
            try {
                Map<String, Object> errorResponse = (Map<String, Object>) JSON.deserializeUntyped(errorMessage);
                if (errorResponse.containsKey('message')) {
                    errorMessage = (String) errorResponse.get('message');
                }
            } catch (Exception e) {
                // If parsing fails, use the raw response body or status
                if (String.isBlank(errorMessage)) {
                    errorMessage = response.getStatus();
                }
            }
            
            throw new AuraHandledException('Failed to fetch SAP data: ' + errorMessage);
        }

        SAP_Response sapResp = (SAP_Response) JSON.deserialize(response.getBody(), SAP_Response.class);

        // --- Find the record with the latest past MR_DATE
        SAP_Data matchedRecord = null;
        Date latestDate = null;
        for (SAP_Data rec : sapResp.sapData) {
            try {
                Date mrDate = Date.valueOf(rec.MR_DATE);
                // Only consider past dates (not future dates)
                if (mrDate <= Date.today()) {
                    if (latestDate == null || mrDate > latestDate) {
                        latestDate = mrDate;
                        matchedRecord = rec;
                    }
                }
            } catch (Exception e) {}
        }

        // --- Update Device Allocation record
        List<Move_In_Out__c> allocations = [
            SELECT Id, Latest_MR_Date__c, Latest_Meter_Reading__c, Latest_MR_Person__c, BP_Number__c, Latest_MR_Type__c
            FROM Move_In_Out__c
            WHERE Installation__c = :device And Move_Out__c !=null ORDER BY Move_Out__c DESC
            LIMIT 1
        ];

        if (!allocations.isEmpty()) {
            Move_In_Out__c alloc = allocations[0];
            alloc.Latest_MR_Date__c = Date.valueOf(matchedRecord.MR_DATE);
            alloc.Latest_Meter_Reading__c = matchedRecord.MR_READING;
            alloc.Latest_MR_Person__c = matchedRecord.READER_NAME;
            alloc.Latest_MR_Type__c = matchedRecord.MR_TYPE;
            update alloc;
        }
        return (SAP_Response) JSON.deserialize(response.getBody(), SAP_Response.class);
    }

    @AuraEnabled
    public static String updateMRResult(String meterNumber, String meterReadingDate, String meterReading, String remarks) {
        String url = System.label.MeterReadingUpdate;
         
        // Build JSON body
        Map<String, Object> reqBody = new Map<String, Object>();
        reqBody.put('Meter_Number__c', meterNumber);
        reqBody.put('Reading_Recorded__c', meterReading);
        reqBody.put('Remarks', remarks);
        reqBody.put('MR Date', meterReadingDate);
        
        String jsonBody = JSON.serialize(reqBody);

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(url);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        if(Middleware_Token_Control__mdt.getInstance('UpdateMRResult').Token__c=='true'){
            String token = BillsCallout.getAccessToken();
        request.setHeader('Authorization', 'Bearer ' + token);
        }
        request.setTimeout(120000);
        request.setBody(jsonBody);

        HttpResponse response = http.send(request);
        String responseBody = response.getBody();
        Integer statusCode = response.getStatusCode();

        // 🔹 Fetch BP_Number__c from Move_In_Out__c
        String businessPartnerId;
        if (String.isNotBlank(meterNumber)) {
            List<Move_In_Out__c> moveInList = [
                SELECT BP_Number__c 
                FROM Move_In_Out__c 
                WHERE Installation__c = :meterNumber And Move_Out__c !=null ORDER BY Move_Out__c DESC
                LIMIT 1
            ];
            if (!moveInList.isEmpty() && moveInList[0].BP_Number__c != null) {
                businessPartnerId = moveInList[0].BP_Number__c;
            }
        }

        // 🔹 Create Integration Log
        Integration_Log__c log = new Integration_Log__c();
        log.Class_Name__c = 'MRResultCallout';
        log.Endpoint_URL__c = url;
        log.Request_Body__c = jsonBody;
        log.Response_Body__c = responseBody;
        log.Status_Code__c = statusCode;
        if (businessPartnerId != null) {
            log.Business_Partner__c = businessPartnerId;
        }
        insert log;

        if (statusCode == 200 || statusCode == 201) {
            return 'Success: ' + response.getBody();
        } else {
            // Parse error message from response
            String errorMessage = responseBody;
            try {
                Map<String, Object> errorResponse = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                if (errorResponse.containsKey('message')) {
                    errorMessage = (String) errorResponse.get('message');
                }
            } catch (Exception e) {
                // If parsing fails, use the raw response body or status
                if (String.isBlank(errorMessage)) {
                    errorMessage = response.getStatus();
                }
            }
            
            throw new AuraHandledException('Failed to update MR Result: ' + errorMessage);
        }
    }

    @AuraEnabled
    public static String createMRResult(
        String meterNumber, 
        String meterReadingDate, 
        String meterReading, 
        String remarks, 
        String reason, 
        String mrtype, 
        String status, 
        String actualReadingDate, 
        String scheduledMrDate, 
        String actualMrDateTime
    ) {
        try {
            MeterReading__c newMeterReading = new MeterReading__c(
                Device_Number__c = meterNumber,
                Meter_Reading__c = meterReading,
                Meter_Reading_Date__c = meterReadingDate,
                Reading_Recorded__c = meterReading,
                Remarks__c = remarks,
                MR_Reason__c = reason,
                MR_Type__c = mrtype,
                Status__c = status,
                Actual_Reading_Date__c = actualReadingDate,
                Scheduled_MR_Date__c = scheduledMrDate,
                Actual_MR_Date_Time__c = actualMrDateTime
            );
            
            insert newMeterReading;

            String installationNumber = '';
            String contractNumber = '';
            String devicenumber = '';

            List<Device_Allocation__c> deviceAllocations = [
                SELECT Id, Installation__c,Device_Number__c,Installation_Number__c 
                FROM Device_Allocation__c 
                WHERE Installation_Number__c = :meterNumber 
                LIMIT 1
            ];
            if (!deviceAllocations.isEmpty()) {
                installationNumber = deviceAllocations[0].Installation_Number__c;
                devicenumber = deviceAllocations[0].Device_Number__c;

                if (String.isNotBlank(installationNumber)) {
                    List<Move_In_Out__c> moveInOuts = [
                        SELECT Id, Contract__c 
                        FROM Move_In_Out__c 
                        WHERE Installation__c = :installationNumber And Move_Out__c !=null ORDER BY Move_Out__c DESC
                        LIMIT 1
                    ];
                    if (!moveInOuts.isEmpty()) {
                        contractNumber = moveInOuts[0].Contract__c;
                    }
                }
            }

            callSAPAsync(
                newMeterReading.Id,
                meterNumber,
                meterReading,
                remarks,
                reason,
                mrtype,
                status,
                actualReadingDate,
                scheduledMrDate,
                actualMrDateTime,
                devicenumber,
                contractNumber
            );

            return 'Meter Reading created successfully. SAP update will process shortly.';
        
        } catch (Exception e) {
            throw new AuraHandledException('Error creating meter reading: ' + e.getMessage());
        }
    }

    // --------------------------
    // 🔹 Asynchronous Callout Logic
    // --------------------------
    @future(callout=true)
    private static void callSAPAsync(
        Id meterReadingId,
        String meterNumber,
        String meterReading,
        String remarks,
        String reason,
        String mrtype,
        String status,
        String actualReadingDate,
        String scheduledMrDate,
        String actualMrDateTime,
        String devicenumber,
        String contractNumber
    ) {
        try {
                 
            String url = System.label.MeterReadingUpdate;
            String recordId15 = String.valueOf(meterReadingId).substring(0,15);

            String formattedScheduledMrDate = formatDateForSAP(scheduledMrDate);
            String formattedActualReadingDate = formatDateForSAP(actualReadingDate);
            String formattedActualMrTime = formatTimeForSAP(actualMrDateTime);

            if (String.isBlank(meterReading)) {
                meterReading = '0';
            }

            // Build JSON
            JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartObject();
            gen.writeStringField('record_id', recordId15);
            gen.writeStringField('mridnumber', devicenumber);
            gen.writeStringField('installation', meterNumber);
            gen.writeStringField('readingresult', meterReading);
            gen.writeStringField('meterreadingnote', '');
            gen.writeStringField('meterreader', '');
            gen.writeStringField('mrdateforbilling', '');
            gen.writeStringField('mrtimeforbilling', '');
            gen.writeStringField('actualmrdate', formattedActualReadingDate);
            gen.writeStringField('actualmrtime', formattedActualMrTime);
            gen.writeStringField('istablart', String.isNotBlank(mrtype) ? mrtype : '');
            gen.writeStringField('schedule_mrdate', formattedScheduledMrDate);
            gen.writeStringField('no_of_attempt', '');
            gen.writeStringField('mr_reason', String.isNotBlank(reason) ? reason : '');
            gen.writeStringField('mr_agency_code', '');
            gen.writeStringField('consmpt_mrent', '');
            gen.writeEndObject();
            
            String jsonBody = gen.getAsString();

            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(url);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            if(Middleware_Token_Control__mdt.getInstance('CreateMRResult').Token__c=='true'){
                String token = BillsCallout.getAccessToken();
            request.setHeader('Authorization', 'Bearer ' + token);
            }
            request.setTimeout(120000);
            request.setBody(jsonBody);

            HttpResponse response = http.send(request);
            String responseBody = response.getBody();
            Integer statusCode = response.getStatusCode();

            // 🔹 Fetch BP_Number__c from Move_In_Out__c
            String businessPartnerId;
            if (String.isNotBlank(meterNumber)) {
                List<Move_In_Out__c> moveInList = [
                    SELECT BP_Number__c 
                    FROM Move_In_Out__c 
                    WHERE Installation__c = :meterNumber And Move_Out__c !=null ORDER BY Move_Out__c DESC
                    LIMIT 1
                ];
                if (!moveInList.isEmpty() && moveInList[0].BP_Number__c != null) {
                    businessPartnerId = moveInList[0].BP_Number__c;
                }
            }

            Integration_Log__c log = new Integration_Log__c();
            log.Class_Name__c = 'MRResultCallout';
            log.Endpoint_URL__c = url;
            log.Request_Body__c = jsonBody;
            log.Response_Body__c = responseBody;
            log.Status_Code__c = statusCode;
            log.Meter_Reading__c = meterReadingId;
            if (businessPartnerId != null) {
                log.Business_Partner__c = businessPartnerId;
            }
            insert log;

        } catch (Exception e) {
            // 🔹 Fetch BP_Number__c for error logs too
            String businessPartnerId;
            if (String.isNotBlank(meterNumber)) {
                List<Move_In_Out__c> moveInList = [
                    SELECT BP_Number__c 
                    FROM Move_In_Out__c 
                    WHERE Installation__c = :meterNumber And Move_Out__c !=null ORDER BY Move_Out__c DESC
                    LIMIT 1
                ];
                if (!moveInList.isEmpty() && moveInList[0].BP_Number__c != null) {
                    businessPartnerId = moveInList[0].BP_Number__c;
                }
            }

            Integration_Log__c errorLog = new Integration_Log__c();
            errorLog.Class_Name__c = 'MRResultCallout';
            errorLog.Endpoint_URL__c = System.label.MeterReadingUpdate;
            errorLog.Request_Body__c = 'Error: ' + e.getMessage();
            errorLog.Response_Body__c = e.getStackTraceString();
            errorLog.Status_Code__c = 500;
            errorLog.Meter_Reading__c = meterReadingId;
            if (businessPartnerId != null) {
                errorLog.Business_Partner__c = businessPartnerId;
            }
            insert errorLog;
        }
    }

    private static String formatDateForSAP(String dateString) {
        if (String.isBlank(dateString)) {
            return '';
        }
        try {
            Date d;
            if (dateString.contains('-')) {
                d = Date.valueOf(dateString);
            } else if (dateString.contains('/')) {
                String[] parts = dateString.split('/');
                if (parts.size() == 3) {
                    Integer day = Integer.valueOf(parts[0]);
                    Integer month = Integer.valueOf(parts[1]);
                    Integer year = Integer.valueOf(parts[2]);
                    if (year < 100) year = 2000 + year;
                    d = Date.newInstance(year, month, day);
                }
            }
            if (d != null) {
                return String.valueOf(d.year()) + 
                       String.valueOf(d.month()).leftPad(2, '0') + 
                       String.valueOf(d.day()).leftPad(2, '0');
            }
        } catch (Exception e) {}
        return dateString;
    }

    private static String formatTimeForSAP(String dateTimeString) {
        if (String.isBlank(dateTimeString)) {
            return '';
        }
        try {
            Integer hour = 0;
            Integer minute = 0;
            if (dateTimeString.contains(':')) {
                String timePart = dateTimeString;
                if (dateTimeString.contains(' ')) {
                    String[] spaceParts = dateTimeString.split(' ');
                    for (String part : spaceParts) {
                        if (part.contains(':')) {
                            timePart = part;
                            break;
                        }
                    }
                }
                String cleanTime = timePart.replace('am', '').replace('pm', '').replace('AM', '').replace('PM', '').trim();
                String[] timeParts = cleanTime.split(':');
                if (timeParts.size() >= 2) {
                    hour = Integer.valueOf(timeParts[0].trim());
                    minute = Integer.valueOf(timeParts[1].replaceAll('[^0-9]', '').trim());
                    if (dateTimeString.toLowerCase().contains('pm') && hour < 12) {
                        hour += 12;
                    } else if (dateTimeString.toLowerCase().contains('am') && hour == 12) {
                        hour = 0;
                    }
                }
            }
            return String.valueOf(hour).leftPad(2, '0') + String.valueOf(minute).leftPad(2, '0');
        } catch (Exception e) {}
        return '';
    }

    @AuraEnabled(cacheable=true)
    public static String getInstallationNumber(String bpNumber) {
        if (String.isBlank(bpNumber)) return null;
        try{
        List<Move_In_Out__c> moveInList = [
    SELECT Id, Installation__c
    FROM Move_In_Out__c
    WHERE Business_Partner__c = :bpNumber
    AND Move_Out__c != NULL
    ORDER BY Move_Out__c DESC
    LIMIT 1
];

if (moveInList.isEmpty() || moveInList[0].Installation__c == null) {
    return null;
}

return moveInList[0].Installation__c;
    } catch (QueryException e) {
            return null;
        }
    }

    public class SAP_Response {
        @AuraEnabled public String statusMessage;
        @AuraEnabled public String installation;
        @AuraEnabled public List<SAP_Data> sapData;
    }

    public class SAP_Data {
        @AuraEnabled public String INSTALLATION;
        @AuraEnabled public String DEVICE;
        @AuraEnabled public String MR_DATE;
        @AuraEnabled public String MR_RSN;
        @AuraEnabled public String MR_RSN_TXT;
        @AuraEnabled public String MR_TYPE;
        @AuraEnabled public String MR_TYPE_TXT;
        @AuraEnabled public String MR_STATUS;
        @AuraEnabled public String MR_STATUS_TXT;
        @AuraEnabled public String MR_READING;
        @AuraEnabled public String SCH_MR_DATE;
        @AuraEnabled public String ACTUAL_MR_DATE;
        @AuraEnabled public String ACTUAL_MR_TIME;
        @AuraEnabled public String METER_READER;
        @AuraEnabled public String READER_NAME;
        @AuraEnabled public String MR_NOTE;
        @AuraEnabled public String MR_NOTE_TXT;
        @AuraEnabled public String MULTIPLE;
    }
}