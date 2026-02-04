/**
 * @description       :
 * @author            : Kartik Patkar Appstrail
 * @group             :
 * @last modified on  : 10-10-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   05-06-2025   Kartik Patkar, Appstrail   Initial Version
 **/
public with sharing class NotificationTriggerHandler {
    
    /**
    * @description 
    * @author Kartik Patkar, Appstrail | 05-06-2025 
    * @param List<Notification__c> newList 
    **/
    public static void afterInsert(List<Notification__c> newList) {
        checkNotification(newList,null);
    }

    /**
    * @description 
    * @author Kartik Patkar, Appstrail | 05-06-2025 
    * @param List<Notification__c> newList 
    * @param Map<Id Notification__c> oldMap 
    **/
    public static void afterUpdate(List<Notification__c> newList, Map<Id,Notification__c> oldMap) {
        checkNotification(newList,oldMap);
    }
    
    /**
    * @description 
    * @author Kartik Patkar, Appstrail | 05-06-2025 
    * @param List<Notification__c> newList 
    * @param Map<Id Notification__c> oldMap 
    **/
    public static void checkNotification(List<Notification__c> newList, Map<Id,Notification__c> oldMap) {
        Set<Id> setPendingNotificationId=new set<Id>();
        for(Notification__c notification : newList) {
            if(notification.Status__c=='Pending' && notification.Type__c=='WhatsApp' && (oldMap==null 
                || notification.Status__c!=oldMap.get(notification.Id).Status__c)) {
                
                setPendingNotificationId.add(notification.Id);
            }
        }
        
        if(!setPendingNotificationId.isEmpty() && !(System.isFuture() || System.isBatch() ||
            System.isQueueable() || System.isScheduled() )) {
            WhatsappAPIHelper.sendNotification(setPendingNotificationId);
        }
    }
}