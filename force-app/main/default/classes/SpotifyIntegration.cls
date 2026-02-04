public with sharing class SpotifyIntegration {

    @AuraEnabled
    public static String searchWithSpotify(String trackName) {
        // Create the instance of HTTP Class
        Http http = new Http();

        // Create the instance of HTTPRequest Class
        HttpRequest request = new HttpRequest();

        // Populate the attributes of Request
        request.setMethod('GET');

        // URL encode the track name
        String encodedName = EncodingUtil.urlEncode(trackName, 'UTF-8');

        // Set the Spotify API endpoint (Ensure you replace `Spotify` with the actual Named Credential reference)
        request.setEndpoint('callout:Spotify/v1/search?q=' + encodedName + '&type=track&limit=1&offset=0');

        HttpResponse response; // Declare the variable outside the try block

        try {
            // Send the request
            response = http.send(request);

            // Debug and return the response
            System.debug('Response: ' + response.getBody());
            System.debug('Response status code: ' + response.getStatusCode());
            System.debug('Response status: ' + response.getStatus());

            if (response.getStatusCode() == 200) {
                return response.getBody();
            } else {
                throw new AuraHandledException('Error: ' + response.getBody());
            }
        } catch (Exception ex) {
            // Debug and handle exceptions
            System.debug('Error occurred: ' + ex.getMessage());
            throw new AuraHandledException('Error while calling Spotify API: ' + ex.getMessage());
        }
    }
}