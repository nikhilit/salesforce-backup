@isTest
global class EbillApiMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);

        // Mock response body (same format as real API)
        String mockBody = '{' +
            '"message": "Ebill  Pdf successfully retrieved!",' +
            '"data": ["https://ebill.mahanagargas.com/pdf_rep/2025/Jul/18/MW12/203010855427_1100924625.pdf"],' +
            '"status": "SUCCESS"' +
        '}';

        res.setBody(mockBody);
        return res;
    }
}