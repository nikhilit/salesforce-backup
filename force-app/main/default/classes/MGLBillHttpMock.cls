@IsTest
global class MGLBillHttpMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);
        
        // Set the body to your sample JSON
        res.setBody(
            '{' +
                '"message": "Ebill  Pdf successfully retrieved!",' +
                '"data": ["https://ebill.mahanagargas.com/pdf_rep/2025/Apr/10/MC02/206001329392_1101708428.pdf"],' +
                '"status": "SUCCESS"' +
            '}'
        );
        
        return res;
    }
}