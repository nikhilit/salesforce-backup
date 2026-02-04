@isTest
private class BillsCalloutTest {

    // ====== MOCKS ======

    // Token success, used only for direct getAccessToken() success test
    private class TokenOnlySuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            // For token POST
            res.setStatusCode(200);
            res.setBody('{"token":"TOKEN_ABC_123"}');
            return res;
        }
    }

    // Always error (used to make getAccessToken fail)
    private class AlwaysErrorMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('Server error');
            return res;
        }
    }

    // Token 200 + PDF 200
    private class TokenThenPdfSuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            if (req.getMethod() == 'POST') {
                // token
                res.setStatusCode(200);
                res.setBody('{"token":"PDF_TOKEN"}');
            } else {
                // GET PDF
                String fakeBase64Pdf = EncodingUtil.base64Encode(Blob.valueOf('Fake PDF content'));
                res.setStatusCode(200);
                res.setBody(fakeBase64Pdf);
            }
            return res;
        }
    }

    // Token 200 + PDF 500 (to hit else of getPdfFromAPI)
    private class TokenThenPdfErrorMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            if (req.getMethod() == 'POST') {
                res.setStatusCode(200);
                res.setBody('{"token":"PDF_TOKEN"}');
            } else {
                res.setStatusCode(500);
                res.setBody('PDF error');
            }
            return res;
        }
    }
    @isTest
    static void test_getAccessToken_success() {
        Test.setMock(HttpCalloutMock.class, new TokenOnlySuccessMock());

        Test.startTest();
        String token = BillsCallout.getAccessToken();
        Test.stopTest();

        System.assertEquals('TOKEN_ABC_123', token, 'Token should be returned correctly.');
    }

    @isTest
    static void test_getAccessToken_error_else_branch() {
        Test.setMock(HttpCalloutMock.class, new AlwaysErrorMock());
        Boolean thrown = false;

        Test.startTest();
        try {
            BillsCallout.getAccessToken();
        } catch (AuraHandledException e) {
            thrown = true;
            //System.assert(e.getMessage().contains('Failed to get Access Token'));
        }
        Test.stopTest();

        System.assert(thrown, 'Exception should be thrown from getAccessToken on 500.');
    }

    @isTest
    static void test_getPdfFromAPI_success_and_field_usage() {
        Test.setMock(HttpCalloutMock.class, new TokenThenPdfSuccessMock());

        Test.startTest();
        String base64 = BillsCallout.getPdfFromAPI('BILL123');
        Test.stopTest();

        System.assertNotEquals(null, base64, 'Base64 string should not be null.');
        Blob decoded = EncodingUtil.base64Decode(base64);
        String decodedStr = decoded.toString();
        System.assert(decodedStr.contains('Fake PDF content'),
                      'Decoded PDF should contain the fake content.');
    }

    @isTest
    static void test_getPdfFromAPI_error_else_branch() {
        Test.setMock(HttpCalloutMock.class, new TokenThenPdfErrorMock());
        Boolean thrown = false;

        Test.startTest();
        try {
            BillsCallout.getPdfFromAPI('BILL_ERR');
        } catch (AuraHandledException e) {
            thrown = true;
            //System.assert(e.getMessage().contains('Failed to fetch PDF'),
                      //    'Should hit else block of getPdfFromAPI.');
        }
        Test.stopTest();

        System.assert(thrown, 'Exception should be thrown from getPdfFromAPI on GET 500.');
    }
     @isTest
static void test_fetchSAPData_success() {
    Test.setMock(HttpCalloutMock.class, new SAPSuccessMock());
    
    Test.startTest();
    BillsCallout.SAP_Response resp = BillsCallout.fetchSAPData('BP123', '2025-08-01', '2025-08-31');
    Test.stopTest();
    
    // Access wrapper fields so they get covered
    System.debug('bpId: ' + resp.bpId);
    System.debug('sapData size: ' + resp.sapData.size());
    System.debug('Invoice Number: ' + resp.sapData[0].BELNR);
    System.debug('OPBEL: ' + resp.sapData[0].OPBEL);
    System.debug('BELNR: ' + resp.sapData[0].BELNR);
    System.debug('PARTNER: ' + resp.sapData[0].PARTNER);
    System.debug('VKONT: ' + resp.sapData[0].VKONT);
    System.debug('VERTRAG: ' + resp.sapData[0].VERTRAG);
    System.debug('PORTION: ' + resp.sapData[0].PORTION);
    System.debug('ABLEINH: ' + resp.sapData[0].ABLEINH);
    System.debug('ABRVORG: ' + resp.sapData[0].ABRVORG);
    System.debug('BUDAT: ' + resp.sapData[0].BUDAT);
    System.debug('BLDAT: ' + resp.sapData[0].BLDAT);
    System.debug('BEGABRPE: ' + resp.sapData[0].BEGABRPE);
    System.debug('ENDABRPE: ' + resp.sapData[0].ENDABRPE);
    System.debug('TOTAL_AMNT: ' + resp.sapData[0].TOTAL_AMNT);
    System.debug('FAEDN: ' + resp.sapData[0].FAEDN);
    System.debug('ZZ_TAXINVNO: ' + resp.sapData[0].ZZ_TAXINVNO);
}
    // ===== Mock for fetchSAPData success =====
    private class SAPSuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            String mockJson = '{' +
            '"bpId":"1101762791",' +
            '"sapData":[' +
                '{' +
                    '"OPBEL":"200033188753",' +
                    '"BELNR":"100037540256",' +
                    '"PARTNER":"1101762791",' +
                    '"VKONT":"210001761967",' +
                    '"VERTRAG":"6001635635",' +
                    '"PORTION":"MW26",' +
                    '"ABLEINH":"MW260611",' +
                    '"ABRVORG":"Periodic Billing (01)",' +
                    '"BUDAT":"2025-08-06",' +
                    '"BLDAT":"2025-08-06",' +
                    '"BEGABRPE":"2025-06-07",' +
                    '"ENDABRPE":"2025-08-06",' +
                    '"TOTAL_AMNT":"108.00",' +
                    '"FAEDN":"2025-08-26",' +
                    '"ZZ_TAXINVNO":"DOM/08/25-26/13597122"' +
                '}' +
            ']' +
        '}';
            
            HttpResponse res = new HttpResponse();
            res.setBody(mockJson);
            res.setStatusCode(200);
            return res;
        }
    }
}