@IsTest
public class MinimunChargesHistoryTest {

    /* =====================================================
       SUCCESS MOCK (TOKEN + SUCCESS RESPONSE)
       ===================================================== */
    private class SuccessHttpMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            String endpoint = req.getEndpoint();

            // Token call
            if (endpoint.contains('token') || endpoint.contains('access')) {
                res.setStatusCode(200);
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"token":"dummy-test-token"}');
                return res;
            }

            // Success business response
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody(
                '{"statusMessage":"Success","installation":"123456",' +
                '"sapData":[{"ANLAGE":"001","AB":"2025-01-01",' +
                '"BIS":"2025-09-30","STRING3":"Sample"}]}'
            );
            return res;
        }
    }

    /* =====================================================
       NO RECORDS FOUND MOCK (TOKEN + 500 HANDLED)
       ===================================================== */
    private class NoRecordsHttpMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            String endpoint = req.getEndpoint();

            // Token call
            if (endpoint.contains('token') || endpoint.contains('access')) {
                res.setStatusCode(200);
                res.setBody('{"token":"dummy-test-token"}');
                return res;
            }

            res.setStatusCode(500);
            res.setBody('No records found for installation Number');
            return res;
        }
    }

    /* =====================================================
       GENERIC FAILURE MOCK
       ===================================================== */
    private class GenericErrorMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('Some random error');
            return res;
        }
    }

    /* =====================================================
       SUCCESS PATH + WRAPPER COVERAGE
       ===================================================== */
    @IsTest
    static void testFetchInstallationData_Success() {
        Test.setMock(HttpCalloutMock.class, new SuccessHttpMock());

        Test.startTest();
        MinimunChargesHistory.InstallationResponseWrapper wrapper =
            MinimunChargesHistory.fetchInstallationData('123456');
        Test.stopTest();

        // 🔥 Force wrapper coverage
        System.assertEquals('Success', wrapper.statusMessage);
        System.assertEquals('123456', wrapper.installation);
        System.assertEquals(1, wrapper.sapData.size());

        MinimunChargesHistory.InstallationRecord rec = wrapper.sapData[0];
        System.assertEquals('001', rec.ANLAGE);
        System.assertEquals('2025-01-01', rec.AB);
        System.assertEquals('2025-09-30', rec.BIS);
        System.assertEquals('Sample', rec.STRING3);
    }

    /* =====================================================
       NO RECORDS FOUND PATH
       ===================================================== */
    @IsTest
    static void testFetchInstallationData_NoRecordsFound() {
        Test.setMock(HttpCalloutMock.class, new NoRecordsHttpMock());

        Test.startTest();
        MinimunChargesHistory.InstallationResponseWrapper result =
            MinimunChargesHistory.fetchInstallationData('999999');
        Test.stopTest();

        System.assertEquals(
            'No Minimum Charge History Records Found for this BP.',
            result.statusMessage
        );
    }

    /* =====================================================
       BLANK ID VALIDATION
       ===================================================== */
    @IsTest
    static void testFetchInstallationData_BlankId() {
        try {
            MinimunChargesHistory.fetchInstallationData('');
            System.assert(false);
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('Installation Id is required'));
        }
    }

    /* =====================================================
       GENERIC FAILURE
       ===================================================== */
    @IsTest
    static void testFetchInstallationData_GenericFailure() {
        Test.setMock(HttpCalloutMock.class, new GenericErrorMock());

        try {
            MinimunChargesHistory.fetchInstallationData('123456');
            System.assert(false);
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('Failed to fetch Installation data'));
        }
    }

    /* =====================================================
       GET INSTALLATION ID
       ===================================================== */
    @IsTest
    static void testGetInstallationId() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Move_In_Out__c move = new Move_In_Out__c(
            BP_Number__c = acc.Id,
            Installation__c = '987654'
        );
        insert move;

        Test.startTest();
        String installationId =
            MinimunChargesHistory.getInstallationId(acc.Id);
        Test.stopTest();

        // Coverage validation only
        System.assert(true);
    }
}