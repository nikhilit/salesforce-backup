public with sharing class GeoServiceHandler {
    @AuraEnabled(cacheable=false)
    public static String getLocationFromCoOrdinates(Decimal lat, Decimal lng) {

        String latlng = String.valueOf(lat) + ',' + String.valueOf(lng);
        String apiKey = System.Label.Get_Address_API_Key;
        String baseEndpoint = System.Label.Get_Address_Endpoint; 

        String endpoint = baseEndpoint + latlng + '&key=' + apiKey;

        System.debug('Final Endpoint => ' + endpoint);

        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('GET'); 
        Http http = new Http();
        
        try {
            HttpResponse response = http.send(request);
            String responseBody = response.getBody();
            System.debug('Response: ' + response.getBody());

            Integration_Log__c log = new Integration_Log__c(
                    Log_Name__c = 'Get address API call',
                    Endpoint_URL__c = endpoint,
                    Status_Code__c = response.getStatusCode(),
                    Request_Body__c = String.valueOf(request),
                    Response_Body__c = responseBody
                );
                insert log;
            
            if (response.getStatusCode() == 200) {
                Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                List<Object> results = (List<Object>) body.get('results');
                
                if (!results.isEmpty()) {
                    Map<String, Object> firstResult = (Map<String, Object>) results[0];
                    String formattedAddress = (String) firstResult.get('formatted_address');
                    return formattedAddress;
                }
            }
            return null;
            
        } catch (Exception e) {
            AS_ErrorLogger.log('GeoService', 'reverseGeocode','Unable to get location:',null);
            return null;
        }
    }
}