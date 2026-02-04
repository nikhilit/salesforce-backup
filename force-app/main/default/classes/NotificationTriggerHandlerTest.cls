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
private class NotificationTriggerHandlerTest {

    @testSetup
    static void setupTestData() {
        // ✅ Activate NotificationTrigger for tests
        TriggerController.triggerControlMap =
            new Map<String, Boolean>{ 'NotificationTrigger' => true };

        // Optional baseline record to simulate environment
        insert new Notification__c(
            Phone_Number__c = '911234567890',
            Template_Name__c = 'Sample Template',
            Status__c = 'Draft',
            Type__c = 'WhatsApp'
        );
    }

    @isTest
    static void testAfterInsert_SuccessfulWhatsAppNotification() {
        Test.setMock(HttpCalloutMock.class, new WhatsappAPIMockResponse(new List<WhatsappAPIMockResponse.Scenario>{
            WhatsappAPIMockResponse.Scenario.SUCCESS, // auth
            WhatsappAPIMockResponse.Scenario.SUCCESS  // message
        }));

        insert new Notification__c(
            Phone_Number__c = '911234567890',
            Template_Name__c = 'Sample Template',
            Status__c = 'Pending',
            Type__c = 'WhatsApp'
        );
    }

    @isTest
    static void testAfterUpdate_TriggerRunsOnStatusChange() {
        Notification__c notif = new Notification__c(
            Phone_Number__c = '911234567890',
            Template_Name__c = 'Template X',
            Status__c = 'Draft',
            Type__c = 'WhatsApp'
        );
        insert notif;

        notif.Status__c = 'Pending';
        Test.setMock(HttpCalloutMock.class, new WhatsappAPIMockResponse(new List<WhatsappAPIMockResponse.Scenario>{
            WhatsappAPIMockResponse.Scenario.SUCCESS, // auth
            WhatsappAPIMockResponse.Scenario.SUCCESS  // message
        }));
        update notif;
    }

    @isTest
    static void testAfterInsert_SkipIfNotWhatsapp() {
        insert new Notification__c(
            Phone_Number__c = '911234567890',
            Template_Name__c = 'Other',
            Status__c = 'Pending',
            Type__c = 'Email' // Not WhatsApp
        );
    }

    @isTest
    static void testAfterUpdate_StatusUnchanged_NoCallout() {
        Notification__c notif = new Notification__c(
            Phone_Number__c = '911234567890',
            Template_Name__c = 'Same',
            Status__c = 'Pending',
            Type__c = 'WhatsApp'
        );
        insert notif;

        notif.Template_Name__c = 'Modified But Status Same';
        Test.setMock(HttpCalloutMock.class, new WhatsappAPIMockResponse(new List<WhatsappAPIMockResponse.Scenario>{
            WhatsappAPIMockResponse.Scenario.SUCCESS // won't be used
        }));
        update notif;
    }

    @isTest
    static void testAfterInsert_HandlesAuthFailureGracefully() {
        Test.setMock(HttpCalloutMock.class, new WhatsappAPIMockResponse(new List<WhatsappAPIMockResponse.Scenario>{
            WhatsappAPIMockResponse.Scenario.ACCESS_TOKEN_FAILURE
        }));
        insert new Notification__c(
            Phone_Number__c = '911234567890',
            Template_Name__c = 'Auth Fail Test',
            Status__c = 'Pending',
            Type__c = 'WhatsApp'
        );
    }

    @isTest
    static void testTriggerInactiveScenario() {
        // Make sure map is initialised first
        if (TriggerController.triggerControlMap == null) {
            TriggerController.triggerControlMap = new Map<String, Boolean>();
        }
        TriggerController.triggerControlMap.put('NotificationTrigger', false);

        insert new Notification__c(
            Phone_Number__c = '911234567890',
            Template_Name__c = 'Inactive Test',
            Status__c = 'Pending',
            Type__c = 'WhatsApp'
        );
    }
}