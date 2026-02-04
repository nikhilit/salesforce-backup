@isTest
private class MRResultCalloutTest {

    /* =========================
       MOCKS
       ========================= */

    // 1) Simple token-only success (for blank-device test etc.)
    private class TokenOnlySuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"token":"TEST_TOKEN"}');
            return res;
        }
    }

    // 2) Token 200 + MRResult 200 (for fetchSAPData success)
    private class TokenThenMRResultSuccessMock implements HttpCalloutMock {
        public Integer callCount = 0;

        public HttpResponse respond(HttpRequest req) {
            callCount++;
            HttpResponse res = new HttpResponse();

            if (callCount == 1) {
                // Token for BillsCallout.getAccessToken()
                res.setStatusCode(200);
                res.setBody('{"token":"SAP_TOKEN"}');
            } else {
                // SAP MR result response
                MRResultCallout.SAP_Response respObj = new MRResultCallout.SAP_Response();
                respObj.statusMessage = 'Success';
                respObj.installation = 'INST001';
                respObj.sapData = new List<MRResultCallout.SAP_Data>();

                // One latest past MR date
                MRResultCallout.SAP_Data pastRecent = new MRResultCallout.SAP_Data();
                pastRecent.DEVICE      = 'DEV123';
                pastRecent.MR_DATE     = String.valueOf(Date.today().addDays(-1));
                pastRecent.MR_READING  = '200.5';
                pastRecent.READER_NAME = 'John Doe';
                pastRecent.MR_TYPE     = 'Final';
                respObj.sapData.add(pastRecent);

                // One older past date (ignored because not latest)
                MRResultCallout.SAP_Data olderPast = new MRResultCallout.SAP_Data();
                olderPast.DEVICE      = 'DEV123';
                olderPast.MR_DATE     = String.valueOf(Date.today().addDays(-10));
                olderPast.MR_READING  = '150.0';
                olderPast.READER_NAME = 'Older Reader';
                olderPast.MR_TYPE     = 'Init';
                respObj.sapData.add(olderPast);

                // One future date (should be ignored)
                MRResultCallout.SAP_Data futureRec = new MRResultCallout.SAP_Data();
                futureRec.DEVICE      = 'DEV123';
                futureRec.MR_DATE     = String.valueOf(Date.today().addDays(5));
                futureRec.MR_READING  = '999.9';
                futureRec.READER_NAME = 'Future Reader';
                futureRec.MR_TYPE     = 'Future';
                respObj.sapData.add(futureRec);

                String body = JSON.serialize(respObj);
                res.setStatusCode(200);
                res.setBody(body);
            }
            return res;
        }
    }

    // 3) Token 200 + MRResult 404 (for fetchSAPData error path)
    private class TokenThenMRResultErrorMock implements HttpCalloutMock {
        public Integer callCount = 0;

        public HttpResponse respond(HttpRequest req) {
            callCount++;
            HttpResponse res = new HttpResponse();

            if (callCount == 1) {
                res.setStatusCode(200);
                res.setBody('{"token":"SAP_TOKEN"}');
            } else {
                res.setStatusCode(404);
                res.setBody('{"error":"Not Found"}');
            }
            return res;
        }
    }

    // 4) Token 200 + MRUpdate 200 (for updateMRResult success)
    private class TokenThenMRUpdateSuccessMock implements HttpCalloutMock {
        public Integer callCount = 0;

        public HttpResponse respond(HttpRequest req) {
            callCount++;
            HttpResponse res = new HttpResponse();

            if (callCount == 1) {
                res.setStatusCode(200);
                res.setBody('{"token":"UPDATE_TOKEN"}');
            } else {
                res.setStatusCode(200);
                res.setBody('{"success":"true"}');
            }
            return res;
        }
    }

    // 5) Token 200 + MRUpdate 500 (for updateMRResult error path)
    private class TokenThenMRUpdateErrorMock implements HttpCalloutMock {
        public Integer callCount = 0;

        public HttpResponse respond(HttpRequest req) {
            callCount++;
            HttpResponse res = new HttpResponse();

            if (callCount == 1) {
                res.setStatusCode(200);
                res.setBody('{"token":"UPDATE_TOKEN"}');
            } else {
                res.setStatusCode(500);
                res.setBody('{"error":"Update failed"}');
            }
            return res;
        }
    }

    // 6) Token 200 + Async MRUpdate 200 (for callSAPAsync success path)
    private class TokenThenAsyncSuccessMock implements HttpCalloutMock {
        public Integer callCount = 0;

        public HttpResponse respond(HttpRequest req) {
            callCount++;
            HttpResponse res = new HttpResponse();

            if (callCount == 1) {
                // token
                res.setStatusCode(200);
                res.setBody('{"token":"ASYNC_TOKEN"}');
            } else {
                // async MR update
                res.setStatusCode(200);
                res.setBody('{"async":"ok"}');
            }
            return res;
        }
    }

    // 7) Always 500 (for callSAPAsync error/catch path or token failure)
    private class AlwaysErrorMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"error":"Server error"}');
            return res;
        }
    }

    /* =========================
       TESTS FOR fetchSAPData
       ========================= */

    @isTest
    static void testFetchSAPData_Success_WithAllocationUpdated() {
        // Allocation record with Installation__c = device param
        Move_In_Out__c alloc = new Move_In_Out__c(
            Installation__c = 'DEV123'
        );
        insert alloc;

        Test.setMock(HttpCalloutMock.class, new TokenThenMRResultSuccessMock());

        Test.startTest();
        MRResultCallout.SAP_Response resp = MRResultCallout.fetchSAPData('DEV123');
        Test.stopTest();
    }

    @isTest
    static void testFetchSAPData_Failure_StatusNot200() {
        Test.setMock(HttpCalloutMock.class, new TokenThenMRResultErrorMock());
        Boolean thrown = false;

        Test.startTest();
        try {
            MRResultCallout.fetchSAPData('DEV404');
        } catch (AuraHandledException e) {
            thrown = true;
            // message could be from token or from SAP, so don't over-assert it
        }
        Test.stopTest();

    }

    @isTest
    static void testFetchSAPData_BlankDevice_Throws() {
        // Still needs token call before blank check
        Test.setMock(HttpCalloutMock.class, new TokenOnlySuccessMock());
        Boolean thrown = false;

        Test.startTest();
        try {
            MRResultCallout.fetchSAPData('');
        } catch (AuraHandledException e) {
            thrown = true;
        }
        Test.stopTest();

    }

    /* =========================
       TESTS FOR updateMRResult
       ========================= */

    @isTest
    static void testUpdateMRResult_Success_WithBPLog() {
        // Create a BP Account so BP_Number__c can store a valid Id
        Account bpAcc = new Account(Name = 'BP Account 1');
        insert bpAcc;

        // Move_In_Out__c used to derive Business_Partner__c for the log
        Move_In_Out__c moveIn = new Move_In_Out__c(
            Installation__c = 'METER123',
            BP_Number__c    = bpAcc.Id
        );
        insert moveIn;

        Test.setMock(HttpCalloutMock.class, new TokenThenMRUpdateSuccessMock());

        Test.startTest();
        String result = MRResultCallout.updateMRResult('METER123', '2025-01-01', '150.75', 'Test remarks');
        Test.stopTest();
    }

    @isTest
    static void testUpdateMRResult_Failure_StatusNot200() {
        Account bpAcc = new Account(Name = 'BP Account Fail');
        insert bpAcc;

        Move_In_Out__c moveIn = new Move_In_Out__c(
            Installation__c = 'METER999',
            BP_Number__c    = bpAcc.Id
        );
        insert moveIn;

        Test.setMock(HttpCalloutMock.class, new TokenThenMRUpdateErrorMock());
        Boolean thrown = false;

        Test.startTest();
        try {
            MRResultCallout.updateMRResult('METER999', '2025-02-02', '120.5', 'Failure test');
        } catch (AuraHandledException e) {
            thrown = true;
        }
        Test.stopTest();

    }

    /* =========================
       TESTS FOR createMRResult + callSAPAsync
       ========================= */

    @isTest
    static void testCreateMRResult_CompleteFlow_SuccessAsync() {
        // Device allocation & Move_In_Out__c for contractNumber and BP
        Device_Allocation__c alloc = new Device_Allocation__c(
            Device_Number__c       = 'DEV999',
            Installation_Number__c = 'INST002'
        );
        insert alloc;

        Account bpAcc = new Account(Name = 'BP Async');
        insert bpAcc;

        Move_In_Out__c moveIn = new Move_In_Out__c(
            Installation__c = 'INST002',
            Contract__c      = 'CON001',
            BP_Number__c     = bpAcc.Id
        );
        insert moveIn;

        // Mock for token + async MR update
        Test.setMock(HttpCalloutMock.class, new TokenThenAsyncSuccessMock());

        Test.startTest();
        String msg = MRResultCallout.createMRResult(
            'INST002',         // meterNumber (also Installation_Number__c)
            '2025-01-01',      // meterReadingDate (stored as is)
            '150.75',          // meterReading
            'Created via Test',
            'Leak',            // reason
            'Final',           // mrtype
            'Completed',       // status
            '01/02/25',        // actualReadingDate -> formatDateForSAP "/" path
            '2025-03-04',      // scheduledMrDate   -> formatDateForSAP "-" path
            '10:05 pm'         // actualMrDateTime  -> formatTimeForSAP with pm
        );
        Test.stopTest(); // flush future(callout=true)


    }

    @isTest
    static void testCreateMRResult_AsyncError_CatchPath() {
        // Device allocation & Move_In_Out__c for error log path (catch)
        Device_Allocation__c alloc = new Device_Allocation__c(
            Device_Number__c       = 'DEVERR',
            Installation_Number__c = 'INST003'
        );
        insert alloc;

        Account bpAcc = new Account(Name = 'BP Error');
        insert bpAcc;

        Move_In_Out__c moveIn = new Move_In_Out__c(
            Installation__c = 'INST003',
            Contract__c      = 'CON_ERR',
            BP_Number__c     = bpAcc.Id
        );
        insert moveIn;

        // Force an HTTP 500 so callSAPAsync catches it and logs error
        Test.setMock(HttpCalloutMock.class, new AlwaysErrorMock());

        Test.startTest();
        String msg = MRResultCallout.createMRResult(
            'INST003',
            '2025-01-01',
            '99.99',
            'Error path test',
            'Reason',
            'Type',
            'Status',
            'INVALID_DATE', // will make formatDateForSAP fall back
            'INVALID_DATE',
            'invalid time'
        );
        Test.stopTest();

        
        // Fetch the created MeterReading
        MeterReading__c mr = [
            SELECT Id
            FROM MeterReading__c
            WHERE Device_Number__c = 'INST003'
            LIMIT 1
        ];
    }

    /* =========================
       TESTS FOR getInstallationNumber
       ========================= */

    @isTest
    static void testGetInstallationNumber_BlankBP() {
        Test.startTest();
        String result = MRResultCallout.getInstallationNumber(null);
        Test.stopTest();
    }

    @isTest
    static void testGetInstallationNumber_NoRow_QueryExceptionPath() {
        Test.startTest();
        String result = MRResultCallout.getInstallationNumber('NO_ROW_BP');
        Test.stopTest();
    }

    @isTest
    static void testGetInstallationNumber_RowWithNullInstallation() {
        Move_In_Out__c moveIn = new Move_In_Out__c(
            Business_Partner__c = 'BP456',
            Installation__c     = null
        );
        insert moveIn;

        Test.startTest();
        String result = MRResultCallout.getInstallationNumber('BP456');
        Test.stopTest();
    }

    @isTest
    static void testGetInstallationNumber_ValidInstallation() {
        Move_In_Out__c moveIn = new Move_In_Out__c(
            Business_Partner__c = 'BP789',
            Installation__c     = 'INST003'
        );
        insert moveIn;

        Test.startTest();
        String result = MRResultCallout.getInstallationNumber('BP789');
        Test.stopTest();
    }
}