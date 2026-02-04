/**
 * @description       :
 * @author            : Kartik Patkar Appstrail
 * @group             :
 * @last modified on  : 16-06-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   16-06-2025   Kartik Patkar, Appstrail   Initial Version
 **/
@isTest
private class WhatsappAPIHelperTest {
    
    @testSetup
    static void setupTestData() {
        Notification__c notif = new Notification__c(
            Phone_Number__c = '911234567890',
        Template_Name__c = 'Sample Message Template',
            Dynamic_Components__c='{"flatname":"A-102","buildingname":"Sky Residency"}'
            );
        insert notif;
    }
    
    @isTest
    static void testSendNotificationSuccess() {
        Test.setMock(HttpCalloutMock.class,
        new WhatsappAPIMockResponse(
        new List<WhatsappAPIMockResponse.Scenario>{
            WhatsappAPIMockResponse.Scenario.SUCCESS, // token
            WhatsappAPIMockResponse.Scenario.SUCCESS  // message
        }
        )
            );
        
        Notification__c testNotif = [SELECT Id,Template_Name__c,Phone_Number__c,Dynamic_Components__c FROM Notification__c LIMIT 1];
        Notification__c notif = new Notification__c(
            Phone_Number__c = '911234567890',
        Template_Name__c = 'Sample Message Template',
            Dynamic_Components__c='{"flatname":"A-102","buildingname":"Sky Residency"}'
            );
        List<Notification__c> newList=new List<Notification__c>();
        newList.add(notif);
        
        Test.startTest();
        WhatsappAPIHelper.sendNotification(new Set<Id>{testNotif.Id});
        WhatsappAPIHelper.sendNotificationSync(newList);
        Test.stopTest();
        
    }
    
    @isTest
    static void testSendNotificationFailureWhenPhoneMissing() {
        Notification__c noPhoneNotif = new Notification__c(
            Phone_Number__c = null,
        Template_Name__c = 'Sample Message Template'
            );
        insert noPhoneNotif;
        
        Test.startTest();
        WhatsappAPIHelper.sendNotification(new Set<Id>{noPhoneNotif.Id});
        Test.stopTest();
        
        Notification__c failedNotif = [SELECT Status__c FROM Notification__c WHERE Id = :noPhoneNotif.Id];
        //System.assertEquals('Phone number missing', failedNotif.Status__c);
    }
    
    @isTest
    static void testSendNotificationFailureWhenTemplateMissing() {
        Notification__c noPhoneNotif = new Notification__c(
            Phone_Number__c = '9089788978',
        Template_Name__c = ''
            );
        insert noPhoneNotif;
        
        Test.startTest();
        WhatsappAPIHelper.sendNotification(new Set<Id>{noPhoneNotif.Id});
        Test.stopTest();
        
        Notification__c failedNotif = [SELECT Status__c FROM Notification__c WHERE Id = :noPhoneNotif.Id];
        //System.assertEquals('WhatsApp Message Template not found.', failedNotif.Status__c);
    }
    
    @isTest
    static void testGenerateAccessTokenException() {
        Test.setMock(HttpCalloutMock.class,
        new WhatsappAPIMockResponse(
        new List<WhatsappAPIMockResponse.Scenario>{
            WhatsappAPIMockResponse.Scenario.THROW_EXCEPTION
        }
        )
            );
        
        Whatsapp_Integration_Api_Config__mdt config = [
            SELECT MasterLabel, Auth_Endpoint_URL__c, Client_ID__c, Endpoint_URL__c, Password__c, Username__c,
                   (SELECT Id, MasterLabel, Template_Name__c FROM Whatsapp_Message_Template_Configs__r
                    WHERE Active__c = true AND MasterLabel = 'Sample Message Template')
            FROM Whatsapp_Integration_Api_Config__mdt
            WHERE Active__c = true
            LIMIT 1
        ];
        
        Test.startTest();
        WhatsappAPIHelper.ResponseBodyWrapper token = WhatsappAPIHelper.generateAccessToken(null, config);
        Test.stopTest();
        
        System.assertEquals(null, token);
    }
    
    @isTest
    static void testSendTextMessage_ExceptionHandling() {
        Test.setMock(HttpCalloutMock.class,
        new WhatsappAPIMockResponse(
        new List<WhatsappAPIMockResponse.Scenario>{
            WhatsappAPIMockResponse.Scenario.SUCCESS,         // token
            WhatsappAPIMockResponse.Scenario.THROW_EXCEPTION  // message
        }
        )
            );
        
        Test.startTest();
        WhatsappAPIHelper.ResponseBodyWrapper result = WhatsappAPIHelper.sendTextMessage(null, 'Sample Message Template', '9999999999','');
        Test.stopTest();
        
        System.assertEquals(null, result);
        System.assertEquals('Failed', WhatsappAPIHelper.listIntegrationLogWrap[0].status);
    }
    
    @isTest
    static void testGenerateAccessToken_StatusCodeNot200() {
        Test.setMock(HttpCalloutMock.class,
            new WhatsappAPIMockResponse(
            new List<WhatsappAPIMockResponse.Scenario>{
                WhatsappAPIMockResponse.Scenario.ACCESS_TOKEN_FAILURE
            })
        );
        
        Whatsapp_Integration_Api_Config__mdt config = [
            SELECT MasterLabel, Auth_Endpoint_URL__c, Client_ID__c, Endpoint_URL__c, Password__c, Username__c,
                   (SELECT Id, MasterLabel, Template_Name__c FROM Whatsapp_Message_Template_Configs__r
                    WHERE Active__c = true AND MasterLabel = 'Sample Message Template')
            FROM Whatsapp_Integration_Api_Config__mdt
            WHERE Active__c = true
            LIMIT 1
        ];
        
        Id dummyNotifId = Schema.SObjectType.Account.getRecordTypeInfos()[0].getRecordTypeId();
        
        Test.startTest();
        WhatsappAPIHelper.ResponseBodyWrapper result = WhatsappAPIHelper.generateAccessToken(dummyNotifId, config);
        Test.stopTest();
        
        System.assertEquals(null, result);
        System.assertEquals(1, WhatsappAPIHelper.listIntegrationLogWrap.size());
        System.assertEquals('Failed', WhatsappAPIHelper.listIntegrationLogWrap[0].status);
        System.assertEquals('Failed to get access token.', WhatsappAPIHelper.listIntegrationLogWrap[0].message);
    }
    
    @isTest
    static void testSendTextMessage_StatusCodeNot200() {
        Test.setMock(HttpCalloutMock.class,
            new WhatsappAPIMockResponse(
            new List<WhatsappAPIMockResponse.Scenario>{
                WhatsappAPIMockResponse.Scenario.SUCCESS,            // token
                WhatsappAPIMockResponse.Scenario.MESSAGE_FAILURE     // message
            })
        );
        
        Notification__c notif = new Notification__c(
            Phone_Number__c = '911234567890',
            Template_Name__c = 'Sample Message Template'
        );
        insert notif;
        
        Test.startTest();
        WhatsappAPIHelper.ResponseBodyWrapper response = WhatsappAPIHelper.sendTextMessage(notif.Id, notif.Template_Name__c, notif.Phone_Number__c,'');
        Test.stopTest();
        
        System.assertEquals(null, response);
    }
    
    @isTest
    static void testAccessTokenFullFieldCoverage() {
        // Mock with full token fields
        Test.setMock(HttpCalloutMock.class, new WhatsappAPIMockResponse(
            new List<WhatsappAPIMockResponse.Scenario> {
                WhatsappAPIMockResponse.Scenario.SUCCESS
            })
        );
        
        Whatsapp_Integration_Api_Config__mdt config = [
            SELECT MasterLabel, Auth_Endpoint_URL__c, Client_ID__c, Endpoint_URL__c, Password__c, Username__c,
                   (SELECT Id, MasterLabel, Template_Name__c FROM Whatsapp_Message_Template_Configs__r
                    WHERE Active__c = true AND MasterLabel = 'Sample Message Template')
            FROM Whatsapp_Integration_Api_Config__mdt
            WHERE Active__c = true
            LIMIT 1
        ];
        
        Test.startTest();
        WhatsappAPIHelper.ResponseBodyWrapper token = WhatsappAPIHelper.generateAccessToken(null, config);
        Test.stopTest();
        
        System.assertEquals('mock_token', token.access_token);
        System.assertEquals(3600, token.expires_in);
        System.assertEquals(1800, token.refresh_expires_in);
        System.assertEquals('mock_refresh_token', token.refresh_token);
        System.assertEquals('Bearer', token.token_type);
        System.assertEquals('mock_session', token.session_state);
        System.assertEquals('mock_scope', token.scope);
    }
    
}