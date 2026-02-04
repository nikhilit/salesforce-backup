public class AS_BulkUploadProcessQueueable implements Queueable, Database.AllowsCallouts {
    private Id bulkImportId;
    private Id contentVersionId;
    private String mode;
    
    public AS_BulkUploadProcessQueueable(Id bulkImportId, Id contentVersionId, String mode) {
        this.bulkImportId = bulkImportId;
        this.contentVersionId = contentVersionId;
        this.mode = mode;
    }
    
    public void execute(QueueableContext context) {
        try {
            // Get API details
            Map<String,String> authDetails = getApiDetails('BulkUploadAuthRequest');
            Map<String,String> processDetails;
            
            if(mode == 'Collect360')
                processDetails = getApiDetails('BulkUploadProcessRequest');
            if(mode == 'Field Sense')
                processDetails = getApiDetails('BulkUploadProcessRequestFS');
            
            // Get access token
            String accessToken = AS_BulkUploadAuthHelper.getAccessToken(authDetails);
            
            // Build JSON payload
            // Map<String, Object> payload = new Map<String, Object>{
                //     'Id' => bulkImportId,
                //     'version_id' => contentVersionId,
                //     'RecordTypeId' => '012fs0000000Hc2AAE',
                //     'WorkTypeId' => new List<Object>{
                    //         new Map<String,String>{'For Collection' => '08qfs000000063pAAA'},
                    //         new Map<String,String>{'Under Disconnection' => '08qfs000000063qAAA'}
                //     },
                // 	'access_token' => accessToken
            // };
            
            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(processDetails.get('header'));
            payload.put('Id', bulkImportId);
            payload.put('version_id', contentVersionId);
            payload.put('access_token', accessToken);
            
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(processDetails.get('endpoint'));
            //req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(payload));
            req.setMethod('POST');
            
            Http http = new Http();
            HTTPResponse res = http.send(req);
            
            Integration_Log__c log = new Integration_Log__c();
            log.Related_Record_Id__c = bulkImportId;
            log.Log_Name__c = 'AS BulkUpload AWS Processing Request';
            log.Endpoint_URL__c = authDetails.get('endpoint');
            log.Status_Code__c = res.getStatusCode();
            log.Request_Body__c = req.getBody();
            log.Response_Body__c = res.getBody();
            
            
            // Update BulkImportStatus__c based on response
            BulkImportStatus__c bis = [SELECT Id, Status__c FROM BulkImportStatus__c WHERE Id = :bulkImportId];
            if(res.getStatusCode() == 200){
                bis.Status__c = 'In Progress';
            } else {
                bis.Status__c = 'Failed';
                bis.Error__c = res.getBody();
            }
            update bis;
            insert log;
        } catch(Exception e){
            AS_ErrorLogger.log('AS_BulkUploadProcessQueueable', 'execute', e, bulkImportId);
        }
    }
    
    public static Map<String, String> getApiDetails(String name) {
        API_Setting__mdt mdt = [
            SELECT Prod_EndPoint__c, Prod_Header__c, Stage_EndPoint__c, Stage_Header__c
            FROM API_Setting__mdt WHERE DeveloperName = :name LIMIT 1
        ];
        
        Boolean isProd = !Test.isRunningTest() && !String.valueOf(URL.getOrgDomainUrl()).contains('sandbox');
        return new Map<String, String>{
            'endpoint' => isProd ? mdt.Prod_EndPoint__c : mdt.Stage_EndPoint__c,
            'header'   => isProd ? mdt.Prod_Header__c   : mdt.Stage_Header__c
        };
    }
}