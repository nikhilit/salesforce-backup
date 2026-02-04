public with sharing class UrlShortenerService {
    private static final String BITLY_API = 'https://api-ssl.bitly.com/v4/shorten';
    private static final String ACCESS_TOKEN = 'YOUR_BITLY_ACCESS_TOKEN'; // Secure in Named Credential
 
    public class BitlyRequest {
        public String long_url;
    }
 
    public class BitlyResponse {
        public String link;
    }
 
    public static String shortenUrl(String longUrl) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(BITLY_API);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + ACCESS_TOKEN);
 
        BitlyRequest body = new BitlyRequest();
        body.long_url = longUrl;
 
        req.setBody(JSON.serialize(body));
 
        HttpResponse res = http.send(req);
        if(res.getStatusCode() == 200) {
            BitlyResponse br = (BitlyResponse)JSON.deserialize(res.getBody(), BitlyResponse.class);
            
            return br.link;
        } else {
            System.debug('Error: ' + res.getBody());
            return longUrl; // fallback
        }
    }
}