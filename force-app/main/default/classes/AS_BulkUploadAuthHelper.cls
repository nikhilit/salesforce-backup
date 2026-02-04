public without sharing class AS_BulkUploadAuthHelper {
    public static String getAccessToken(Map<String, String> authDetails) {
		
		String result = '';
		try{
			HttpRequest req = new HttpRequest();
			req.setEndpoint(authDetails.get('endpoint'));
			req.setHeader('Content-Type', 'application/json');
			req.setBody(authDetails.get('header')); // Assuming header JSON contains credentials
			req.setMethod('POST');

			Http http = new Http(); 
			HTTPResponse res = http.send(req);

			Integration_Log__c log = new Integration_Log__c();
			log.Related_Record_Id__c = null;
			log.Log_Name__c = 'AS BulkUpload AWS Auth Request';
			log.Endpoint_URL__c = authDetails.get('endpoint');
			log.Status_Code__c = res.getStatusCode();
			log.Request_Body__c = req.getBody();
			log.Response_Body__c = res.getBody();
			//insert log; 

			if (res.getStatusCode() == 200) {
				Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
				result = (String) body.get('access_token');
			}
		}catch(Exception e){
			AS_ErrorLogger.log('AS_BulkUploadAuthHelper', 'getAccessToken', e, null);
		}
        //throw new AuraHandledException('Auth failed: ' + res.getBody());
		return result;
    }
}