@isTest
private class ChangeHistoryCalloutTest {

    // Mock for a successful SAP response
    private class MockSuccessResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody(
                '{"statusMessage":"OK","bpId":"BP123","sapData":['+
                '{"UDATE": "2019-12-26","UTIME": "10:47:30","OBJECTID": "1101256369","USERNAME": "PM01404","FLDNAME": "IS-U data","TFLDNAME": "EKUN","F_NEW": "*** Created ***","F_OLD": "","KEYVAL": ""}]}'
            );
            return res;
        }
    }
    
    // Mock for a failure SAP response
    private class MockFailureResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"error":"Internal Server Error"}');
            return res;
        }
    }

    @isTest
    static void testFetchSAPData_Success() {
        Test.setMock(HttpCalloutMock.class, new MockSuccessResponse());
        
        Test.startTest();
        ChangeHistoryCallout.SAP_Response result =
            ChangeHistoryCallout.fetchSAPData('BP123');
        Test.stopTest();
    }

    @isTest
    static void testFetchSAPData_Failure() {
        Test.setMock(HttpCalloutMock.class, new MockFailureResponse());
        Boolean exceptionThrown = false;
        try {
            Test.startTest();
            ChangeHistoryCallout.fetchSAPData('BP999');
            Test.stopTest();
        } catch (AuraHandledException e) {
            exceptionThrown = true;
           // System.assert(e.getMessage().contains('Failed to fetch SAP data'), 'Message should indicate failure');
        }
    }
}