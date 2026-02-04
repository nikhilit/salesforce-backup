public with sharing class FollowUpNotificationService {
    public static void sendFollowUpReminder(Id workOrderId) {
        WorkOrder wo = [
            SELECT Id, Follow_Up_Appointment_Date__c, 
                   Assigned_Meter_Reader__r.RelatedRecordId
            FROM WorkOrder
            WHERE Id = :workOrderId
            LIMIT 1
        ];
        System.debug('get WorkOrder: ' + wo);

        Id userId = wo.Assigned_Meter_Reader__r.RelatedRecordId;

		if (userId == null) {
            System.debug('⚠️ No User found for assigned meter reader.');
            return;
        }

        CustomNotificationType cnt = [
            SELECT Id
            FROM CustomNotificationType
            WHERE DeveloperName = 'Follow_up_Reminder'
            LIMIT 1
        ];

		Id loggedUserId = UserInfo.getUserId();

        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setNotificationTypeId(cnt.Id);
        notification.setTitle('Follow-Up Date Updated');
        notification.setBody('Work Order follow-up date was changed to ' + String.valueOf(wo.Follow_Up_Appointment_Date__c));
        notification.setSenderId(loggedUserId);
        notification.setTargetId(workOrderId);

        Set<String> recipients = new Set<String>{ String.valueOf(userId) };
        try {
            notification.send(recipients);
        } catch (Exception e) {
            System.debug('Failed to send CustomNotification: ' + e.getMessage());
        }
    }
}