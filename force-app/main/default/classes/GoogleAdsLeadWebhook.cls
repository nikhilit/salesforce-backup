@RestResource(urlMapping='/googleleads')
global class GoogleAdsLeadWebhook {
    @HttpPost
    global static void handleLead() {
        try {
            // Parse incoming JSON payload
            RestRequest req = RestContext.request;
            String requestBody = req.requestBody.toString();
            Map<String, Object> leadData = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
            
            // Extract lead fields from payload
            String name = (String) leadData.get('name');
            String email = (String) leadData.get('email');
            String phone = (String) leadData.get('phone');
            
            // Split name into first and last name
            String[] nameParts = name != null ? name.split(' ', 2) : new String[]{};
            String firstName = nameParts.size() > 0 ? nameParts[0] : '';
            String lastName = nameParts.size() > 1 ? nameParts[1] : 'Unknown';

            // Create a new Lead record in Salesforce
            Lead newLead = new Lead(
                FirstName = firstName,
                LastName = lastName,
                Email = email,
                Phone = phone,
                Company = 'Google Ads Lead' // Default value for Company field
            );

            // Insert the lead into Salesforce
            insert newLead;

            // Return success response
            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf('Lead successfully created.');
        } catch (Exception e) {
            // Log errors for debugging
            System.debug('Error in GoogleAdsLeadWebhook: ' + e.getMessage());
            RestContext.response.statusCode = 500; // Internal server error
            RestContext.response.responseBody = Blob.valueOf('Error: ' + e.getMessage());
        }
    }
}