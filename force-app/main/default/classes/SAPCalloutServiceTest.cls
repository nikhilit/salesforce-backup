@isTest
private class SAPCalloutServiceTest {

    // --- Mock class for successful SAP response ---
    private class SAPSuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Simulate a realistic JSON payload from SAP
            String mockJson = '{' +
                '"statusMessage":"Data fetched successfully",' +
                '"bpId":"BP123",' +
                '"sapData":[' +
                    '{' +
                        '"OBJECTID":"OBJ001",' +
                        '"USERNAME":"testuser",' +
                        '"UDATE":"2025-08-13",' +
                        '"CHNGIND_DESC":"Changed",' +
                        '"FIELD_NAME":"Phone",' +
                        '"VALUE_NEW":"1234567890",' +
                        '"VALUE_OLD":"0987654321"' +
                    '}' +
                ']' +
            '}';

            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(mockJson);
            res.setStatusCode(200);
            return res;
        }
    }

    // --- Mock class for error response ---
    private class SAPErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('Internal Server Error');
            return res;
        }
    }

    @isTest
    static void test_fetchSAPData_success() {
        Test.setMock(HttpCalloutMock.class, new SAPSuccessMock());

        Test.startTest();
        SAPCalloutService.SAP_Response result = SAPCalloutService.fetchSAPData('BP123');
        Test.stopTest();

        // Validate returned object
        System.assertNotEquals(null, result, 'Response should not be null');
        System.assertEquals('Data fetched successfully', result.statusMessage);
        System.assertEquals('BP123', result.bpId);
        System.assertEquals(1, result.sapData.size(), 'Should return one SAP_Data record');

        // Validate nested SAP_Data object
        SAPCalloutService.SAP_Data data = result.sapData[0];
        System.assertEquals('OBJ001', data.OBJECTID);
        System.assertEquals('testuser', data.USERNAME);
        System.assertEquals('Phone', data.FIELD_NAME);
        System.assertEquals('1234567890', data.VALUE_NEW);
        System.assertEquals('0987654321', data.VALUE_OLD);
    }

    @isTest
    static void test_fetchSAPData_error() {
        Test.setMock(HttpCalloutMock.class, new SAPErrorMock());

        Boolean exceptionThrown = false;
        try {
            Test.startTest();
            SAPCalloutService.fetchSAPData('BP999');
            Test.stopTest();
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            //System.assertContains('Failed to fetch SAP data', e.getMessage(), 'Exception message should match');
        }
        System.assertEquals(true, exceptionThrown, 'Expected exception not thrown');
    }
}