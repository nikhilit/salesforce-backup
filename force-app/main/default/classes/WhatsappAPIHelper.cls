/**
 * @description       : Helper class to integrate with WhatsApp API – includes token generation and message sending.
 * @author            : Kartik Patkar, Appstrail
 * @last modified on  : 10-10-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   04-06-2025   Kartik Patkar, Appstrail   Initial Version
 **/
public without sharing class WhatsappAPIHelper {
    
    // Logging wrapper used for capturing integration logs
    public static List<IntegrationLogHelper.IntegrationLogWrapper> listIntegrationLogWrap = new List<IntegrationLogHelper.IntegrationLogWrapper>();
    
    /**
     * @description Authenticates with WhatsApp API and retrieves an access token
     * @author Kartik Patkar, Appstrail | 04-06-2025
     * @param Whatsapp_Integration_Api_Config__mdt whatsappConfig record containing API credentials and endpoint
     * @return ResponseBodyWrapper containing the token, or null on failure
     **/
    public static ResponseBodyWrapper generateAccessToken(Id notificationId,Whatsapp_Integration_Api_Config__mdt whatsappConfig) {
        IntegrationLogHelper.IntegrationLogWrapper integrationLogWrap = new IntegrationLogHelper.IntegrationLogWrapper();
        integrationLogWrap.className = 'WhatsappAPIHelper';
        integrationLogWrap.methodName = 'generateAccessToken';
        integrationLogWrap.notificationId = notificationId;
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        try {
            // Prepare the authentication request
            request.setEndpoint(whatsappConfig.Auth_Endpoint_URL__c);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            request.setHeader('cache-control', 'no-cache');
            
            // Set the request body with encoded credentials
            String body = 'grant_type=password&' +
                'client_id=' + EncodingUtil.urlEncode(whatsappConfig.Client_ID__c, 'UTF-8') +
                '&username=' + EncodingUtil.urlEncode(whatsappConfig.Username__c, 'UTF-8') +
                '&password=' + EncodingUtil.urlEncode(whatsappConfig.Password__c, 'UTF-8');
            
            request.setBody(body);
            HttpResponse response = http.send(request);
            
            // Capture request and response details in the log
            integrationLogWrap.endPointURL = request.getEndpoint();
            integrationLogWrap.requestJSON = body;
            integrationLogWrap.responseJSON = response.getBody();
            integrationLogWrap.statusCode = response.getStatusCode();
            integrationLogWrap.requestMethod = request.getMethod();
            
            if (response.getStatusCode() == 200) {
                integrationLogWrap.message = 'Access token generated successfully.';
                integrationLogWrap.status='Success';
                // Return the parsed response body
                return parse(response.getBody());
            } else {
                integrationLogWrap.message = 'Failed to get access token.';
                integrationLogWrap.status='Failed';
                listIntegrationLogWrap.add(integrationLogWrap);
                return null;
            }
        } catch (Exception e) {
            // Log any unexpected errors
            integrationLogWrap.message = e.getMessage();
            integrationLogWrap.lineNumber = e.getLineNumber();
            integrationLogWrap.status='Failed';
            listIntegrationLogWrap.add(integrationLogWrap);
            return null;
        }
    }
    
    /**
     * @description
     * @author Kartik Patkar, Appstrail | 04-06-2025
     * @param String templateName
     * @param String phoneNumber
     * @return ResponseBodyWrapper
     **/
    public static ResponseBodyWrapper sendTextMessage(Id notificationId,String templateName, String phoneNumber,String dynamiccomponents) {
        IntegrationLogHelper.IntegrationLogWrapper integrationLogWrap = new IntegrationLogHelper.IntegrationLogWrapper();
        integrationLogWrap.className = 'WhatsappAPIHelper';
        integrationLogWrap.methodName = 'sendTextMessage';
        integrationLogWrap.notificationId = notificationId;
        
        try {
            if (phoneNumber==null || phoneNumber=='') {
                integrationLogWrap.message = 'Phone Number is empty.';
                integrationLogWrap.status='Failed';
                listIntegrationLogWrap.add(integrationLogWrap);
                return null;
            }
            
            // Load WhatsApp API configuration and template from metadata
            List<Whatsapp_Integration_Api_Config__mdt> configList = [
                SELECT MasterLabel, Auth_Endpoint_URL__c, Client_ID__c, Endpoint_URL__c, Password__c, Username__c,
                       (SELECT Id, MasterLabel, Template_Name__c, Language_Policy__c, Language_Code__c
                        FROM Whatsapp_Message_Template_Configs__r
                        WHERE Active__c = true AND MasterLabel = :templateName)
                FROM Whatsapp_Integration_Api_Config__mdt
                WHERE Active__c = true
                LIMIT 1
            ];
            
            if (configList.isEmpty()) {
                integrationLogWrap.message = 'WhatsApp Configuration not found.';
                integrationLogWrap.status='Failed';
                listIntegrationLogWrap.add(integrationLogWrap);
                return null;
            }
            
            if (configList[0].Whatsapp_Message_Template_Configs__r.isEmpty()) {
                integrationLogWrap.message = 'WhatsApp Message Template not found.';
                integrationLogWrap.status='Failed';
                listIntegrationLogWrap.add(integrationLogWrap);
                return null;
            }
            
            // Get access token
            ResponseBodyWrapper tokenResponse = generateAccessToken(notificationId,configList[0]);
            if (tokenResponse == null) {
                //listIntegrationLogWrap.add(integrationLogWrap);
                return null;
            }
            
            // Reset log for message sending
            integrationLogWrap = new IntegrationLogHelper.IntegrationLogWrapper();
            integrationLogWrap.notificationId = notificationId;
            integrationLogWrap.className = 'WhatsappAPIHelper';
            integrationLogWrap.methodName = 'sendTextMessage';
            
            // Prepare message body using template
            WhatsappRequestBodyWrapper message = new WhatsappRequestBodyWrapper();
            message.to = phoneNumber;
            message.recipient_type = 'individual';
            message.type = 'template';
            message.template = new WhatsappRequestBodyWrapper.Template();
            message.template.name = configList[0].Whatsapp_Message_Template_Configs__r[0].Template_Name__c;
            message.template.language = new WhatsappRequestBodyWrapper.Language();
            message.template.language.policy = configList[0].Whatsapp_Message_Template_Configs__r[0].Language_Policy__c;
            message.template.language.code = configList[0].Whatsapp_Message_Template_Configs__r[0].Language_Code__c;
            
            if (!String.isBlank(dynamiccomponents)) {
                try {
                    // Deserialize as a list since dynamiccomponents is now a JSON array
                    List<Object> dynList = (List<Object>) JSON.deserializeUntyped(dynamiccomponents);
                    List<WhatsappRequestBodyWrapper.Parameter> params = new List<WhatsappRequestBodyWrapper.Parameter>();

                    for (Object itemObj : dynList) {
                        Map<String, Object> itemMap = (Map<String, Object>) itemObj;
                        for (String key : itemMap.keySet()) {
                            params.add(new WhatsappRequestBodyWrapper.Parameter('text', String.valueOf(itemMap.get(key))));
                        }
                    }

                    WhatsappRequestBodyWrapper.Component bodyComp = new WhatsappRequestBodyWrapper.Component();
                    bodyComp.type = 'body';
                    bodyComp.parameters = params;

                    message.template.components = new List<WhatsappRequestBodyWrapper.Component>{ bodyComp };
                } catch (Exception ex) {
                    System.debug('Failed to parse dynamiccomponents: ' + ex.getMessage());
                }
            }


            
            // Send message request
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(configList[0].Endpoint_URL__c + 'messages');
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('Authorization', 'Bearer ' + tokenResponse.access_token);
            request.setBody(message.serialize());
            
            HttpResponse response = http.send(request);
            
            // Log and return response
            integrationLogWrap.requestMethod = request.getMethod();
            integrationLogWrap.endPointURL = request.getEndpoint();
            integrationLogWrap.requestJSON = message.serialize();
            integrationLogWrap.responseJSON = response.getBody();
            integrationLogWrap.statusCode = response.getStatusCode();
            
            if (response.getStatusCode() == 200) {
                integrationLogWrap.message = 'Message sent successfully.';
                integrationLogWrap.status='Success';
                listIntegrationLogWrap.add(integrationLogWrap);
                return parse(response.getBody());
            } else {
                integrationLogWrap.message = 'Failed to send WhatsApp message.';
                integrationLogWrap.status='Failed';
                listIntegrationLogWrap.add(integrationLogWrap);
                return null;
            }
        } catch (Exception e) {
            integrationLogWrap.message = e.getMessage();
            integrationLogWrap.lineNumber = e.getLineNumber();
            integrationLogWrap.status='Failed';
            listIntegrationLogWrap.add(integrationLogWrap);
            return null;
        }
    }
    
    /**
    * @description 
    * @author Kartik Patkar, Appstrail | 05-06-2025 
    * @param Set<Id> setPendingNotificationId 
    **/
    @future(callout=true)
    public static void sendNotification(Set<Id> setPendingNotificationId) {
        List<Notification__c> listUpdateNotifications = new List<Notification__c>();
        for(Notification__c notificationRec:[SELECT Id, Name, Phone_Number__c, Template_Name__c, Status__c,Response_ID__c,Success__c,Dynamic_Components__c
                                                FROM Notification__c 
                                                WHERE Id IN: setPendingNotificationId]) {
            
            ResponseBodyWrapper responseRec=sendTextMessage(notificationRec.Id,notificationRec.Template_Name__c,notificationRec.Phone_Number__c,notificationRec.Dynamic_Components__c);
            if(responseRec!=null && responseRec.success=='true'){
                notificationRec.Status__c='Sent';
                notificationRec.Response_ID__c=responseRec.responseId;
                notificationRec.Success__c=responseRec.success=='true'?true:false;
            }else{
                notificationRec.Status__c='Failed';
            }
            listUpdateNotifications.add(notificationRec);
        }

        if(!listUpdateNotifications.isEmpty()){
            update listUpdateNotifications;
        }
        
        if(!listIntegrationLogWrap.isEmpty()){
            IntegrationLogHelper.createListIntegrationLog(listIntegrationLogWrap);
        }
    }


    public static void sendNotificationSync(List<Notification__c> listUpdateNotifications) {
        for(Notification__c notificationRec:listUpdateNotifications) {
            ResponseBodyWrapper responseRec=sendTextMessage(notificationRec.Id,notificationRec.Template_Name__c,notificationRec.Phone_Number__c,notificationRec.Dynamic_Components__c);
            if(responseRec!=null && responseRec.success=='true'){
                notificationRec.Status__c='Sent';
                notificationRec.Response_ID__c=responseRec.responseId;
                notificationRec.Success__c=responseRec.success=='true'?true:false;
            }else{
                notificationRec.Status__c='Failed';
            }
        }

        if(!listUpdateNotifications.isEmpty()){
            insert listUpdateNotifications;
        }
        
        if(!listIntegrationLogWrap.isEmpty()){
            IntegrationLogHelper.createListIntegrationLog(listIntegrationLogWrap);
        }
    }
    
    /**
     * Wrapper class to parse token and message response body
     */
    public class ResponseBodyWrapper {
        public String access_token { get; set; }
        public Integer expires_in { get; set; }
        public Integer refresh_expires_in { get; set; }
        public String refresh_token { get; set; }
        public String token_type { get; set; }
        public String session_state { get; set; }
        public String scope { get; set; }
        public String responseId { get; set; }
        public String success { get; set; }
    }
    
    /**
     * @description Converts raw JSON string to the ResponseBodyWrapper object
     * @author Kartik Patkar, Appstrail | 04-06-2025
     * @param String json from API response
     * @return Deserialized ResponseBodyWrapper object
     **/
    public static ResponseBodyWrapper parse(String json) {
        return (ResponseBodyWrapper) System.JSON.deserialize(json, ResponseBodyWrapper.class);
    }
}