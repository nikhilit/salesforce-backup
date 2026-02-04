public with sharing class TinyUrlService {
    public class TinyResponse {
        public String data;
    }

    public static String shorten(String longUrl) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://tinyurl.com/api-create.php?url=' + EncodingUtil.urlEncode(longUrl, 'UTF-8'));
        req.setMethod('GET');
        req.setTimeout(2000);
        
        HttpResponse res = http.send(req);
        if (res.getStatusCode() == 200) {
            return res.getBody(); // TinyURL returns plain short URL
        } else {
            System.debug('TinyURL error: ' + res.getBody());
            return longUrl; // fallback
        }
    }
}