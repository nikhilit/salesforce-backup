public with sharing class EbillPdfService {
    private static final String BASE_URL = 'https://ebill.mahanagargas.com/api/ebill/ebill/get-pdf-path-by-billNo/';
    
    private static final String BEARER_TOKEN = 'REPLACE_WITH_SECURE_TOKEN';

    public class EbillResponse {
        public String message;
        public List<String> data;
        public String status;
    }

    /**
     * Fetch PDF URL by Bill Number
     * @param billNo The bill number for which to fetch the PDF
     * @return PDF URL if found, else null
     */
    public static String getPdfUrl(String billNo) {
        if (String.isBlank(billNo)) {
            throw new AuraHandledException('Bill Number cannot be blank.');
        }

        Http http = new Http();
        HttpRequest req = new HttpRequest();

        req.setEndpoint(BASE_URL + EncodingUtil.urlEncode(billNo, 'UTF-8'));
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + BEARER_TOKEN);
        req.setTimeout(5000); // 5 seconds timeout

        HttpResponse res;
        try {
            res = http.send(req);
        } catch (Exception e) {
            System.debug('HTTP Callout Exception: ' + e.getMessage());
            throw new AuraHandledException('Failed to connect to Ebill Service.');
        }

        if (res.getStatusCode() == 200) {
            EbillResponse ebillRes;
            try {
                ebillRes = (EbillResponse) JSON.deserialize(res.getBody(), EbillResponse.class);
            } catch (Exception ex) {
                System.debug('JSON Parse Error: ' + ex.getMessage());
                throw new AuraHandledException('Invalid response from Ebill API.');
            }
            
            if (ebillRes != null && ebillRes.status == 'SUCCESS' && !ebillRes.data.isEmpty()) {
                return ebillRes.data[0];
            } else {
                throw new AuraHandledException('Ebill API returned no data for Bill: ' + billNo);
            }
        } else {
            System.debug('Ebill API Error: ' + res.getBody());
            throw new AuraHandledException('Ebill API Call Failed: ' + res.getStatusCode());
        }
    }
}