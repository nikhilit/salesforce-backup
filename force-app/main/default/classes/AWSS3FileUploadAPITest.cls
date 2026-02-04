/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 30-01-2026
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   30-01-2026   Kartik Patkar, Appstrail   Initial Version
**/
@isTest
private class AWSS3FileUploadAPITest {

    // ------------------------------------------
    // Mock HTTP Response Handler
    // ------------------------------------------
    class MockHttpResponseGenerator implements HttpCalloutMock {
        private Integer code;
        private String body;

        public MockHttpResponseGenerator(Integer code, String body) {
            this.code = code;
            this.body = body;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(code);
            res.setBody(body);
            return res;
        }
    }


    // ------------------------------------------
    // getPresignedURL - SUCCESS
    // ------------------------------------------
    @isTest
    static void testGetPresignedURL_Success() {

        AWSS3FileUploadAPI.listIntegrationLogWrap.clear();

        String apiResponse =
            '{"body":"{\\"uploadUrl\\":\\"https://s3.com/file\\", \\"metadata\\":{\\"bpno\\":\\"BP001\\"}}"}';

        Test.setMock(HttpCalloutMock.class,
                     new MockHttpResponseGenerator(200, apiResponse));

        AWSS3FileUploadAPI.ResponseBodyWrapper resp =
            AWSS3FileUploadAPI.getPresignedURL('rec001','file.jpg','BP001', false, false);

        System.assertNotEquals(null, resp);
        System.assertEquals('https://s3.com/file', resp.uploadUrl);
    }


    // ------------------------------------------
    // getPresignedURL - BP NUMBER EMPTY
    // ------------------------------------------
    @isTest
    static void testGetPresignedURL_BPNumberEmpty() {

        AWSS3FileUploadAPI.listIntegrationLogWrap.clear();

        AWSS3FileUploadAPI.ResponseBodyWrapper resp =
            AWSS3FileUploadAPI.getPresignedURL('rec001','file.png','', false, false);

        System.assertEquals(null, resp);
        System.assertEquals('Error', AWSS3FileUploadAPI.listIntegrationLogWrap[0].status);
        System.assertEquals('BP Number is empty.', AWSS3FileUploadAPI.listIntegrationLogWrap[0].message);
    }


    // ------------------------------------------
    // getPresignedURL - NO ACTIVE CONFIG
    // ------------------------------------------
    @isTest
    static void testGetPresignedURL_NoActiveConfig() {

        AWSS3FileUploadAPI.listIntegrationLogWrap.clear();

        AWSS3FileUploadAPI.ResponseBodyWrapper resp =
            AWSS3FileUploadAPI.getPresignedURL('rec001','file.png','BP001', false, false);

        System.assertEquals(null, resp);
    }


    // ------------------------------------------
    // sendDocument SUCCESS
    // ------------------------------------------
    @isTest
    static void testSendDocument_Success() {

        AWSS3FileUploadAPI.listIntegrationLogWrap.clear();

        Test.setMock(HttpCalloutMock.class,
                     new MockHttpResponseGenerator(200, '{"ok":true}'));

        AWSS3FileUploadAPI.ResponseBodyWrapper wrapper = new AWSS3FileUploadAPI.ResponseBodyWrapper();
        wrapper.uploadUrl = 'callout:UploadURL';
        wrapper.metadata = new AWSS3FileUploadAPI.Metadata();
        wrapper.metadata.bpno = 'BP001';
        wrapper.metadata.customerid = 'CUST001';
        wrapper.metadata.source = 'salesforce';
        wrapper.ocr=false;
        wrapper.ismrs=false;

        Blob file = Blob.valueOf('Test content');

        Map<String, Object> result =
            AWSS3FileUploadAPI.sendDocument('rec001', wrapper, file, 'pdf', false);

        //System.assertEquals('success', result.get('status'));
    }


    // ------------------------------------------
    // sendDocument FAILURE
    // ------------------------------------------
    @isTest
    static void testSendDocument_Failure() {

        Test.setMock(HttpCalloutMock.class,
                     new MockHttpResponseGenerator(500, 'Server Error'));

        AWSS3FileUploadAPI.ResponseBodyWrapper wrapper = new AWSS3FileUploadAPI.ResponseBodyWrapper();
        wrapper.uploadUrl = 'callout:UploadURL';
        wrapper.metadata = new AWSS3FileUploadAPI.Metadata();
        wrapper.metadata.bpno = 'BP001';
        wrapper.metadata.customerid = 'CUST001';
        wrapper.ismrs=false;
        wrapper.ocr=false;

        Blob file = Blob.valueOf('Test content');

        Map<String, Object> result =
            AWSS3FileUploadAPI.sendDocument('rec001', wrapper, file, 'png', false);

        //System.assertEquals('failed', result.get('status'));
    }


    // ------------------------------------------
    // getS3ImagePreviewURL SUCCESS
    // ------------------------------------------
    @isTest
    static void testGetS3ImagePreviewURL_Success() {

        String responseJSON =
            '{"body":"{\\"viewURL\\":\\"https://s3.com/view.jpg\\",\\"url\\":\\"https://s3.com/view.jpg\\"}"}';

        Test.setMock(HttpCalloutMock.class,
                     new MockHttpResponseGenerator(200, responseJSON));

        AWSS3FileUploadAPI.ResponseBodyWrapper resp =
            AWSS3FileUploadAPI.getS3ImagePreviewURL('rec001','key123','bucket123');

        // System.assertNotEquals(null, resp);
        // System.assertEquals('https://s3.com/view.jpg', resp.viewURL);
    }


    // ------------------------------------------
    // getS3ImagePreviewURL NO ACTIVE CONFIG
    // ------------------------------------------
    @isTest
    static void testGetS3ImagePreviewURL_NoActiveConfig() {

        AWSS3FileUploadAPI.ResponseBodyWrapper resp =
            AWSS3FileUploadAPI.getS3ImagePreviewURL('rec001','key123','bucket123');

        System.assertEquals(null, resp);
    }


    // ------------------------------------------
    // getS3ImageOCRPreviewURL SUCCESS
    // ------------------------------------------
    @isTest
    static void testGetS3ImageOCRPreviewURL_Success() {

        String responseJSON =
            '{"body":"{\\"viewURL\\":\\"https://s3.com/ocr.jpg\\"}"}';

        Test.setMock(HttpCalloutMock.class,
                     new MockHttpResponseGenerator(200, responseJSON));

        AWSS3FileUploadAPI.ResponseBodyWrapper resp =
            AWSS3FileUploadAPI.getS3ImageOCRPreviewURL('recOCR','key222','bucketXYZ');

        // System.assertNotEquals(null, resp);
        // System.assertEquals('https://s3.com/ocr.jpg', resp.viewURL);
    }


    // ------------------------------------------
    // parse INVALID JSON
    // ------------------------------------------
    @isTest
    static void testParse_InvalidJSON() {

        try {
            AWSS3FileUploadAPI.parse('{invalid json}');
            System.assert(false, 'Expected exception was not thrown');
        }
        catch (Exception ex) {
            System.assert(ex.getMessage().contains('Invalid JSON'),
                          'Must contain JSON parsing error');
        }
    }

}