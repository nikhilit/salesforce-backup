@isTest
public with sharing class GeoServiceHandlerTest {

    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(
                '{ "results": [' +
                '   { "formatted_address": "Bangalore, Karnataka, India" }' +
                ' ] }'
            );
            return res;
        }
    }

    @isTest
    static void testgetLocationFromCoOrdinates() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        String result = GeoServiceHandler.getLocationFromCoOrdinates(12.9716, 77.5946);
        Test.stopTest();

        System.assertEquals('Bangalore, Karnataka, India', result);

    }
}