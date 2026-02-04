trigger WorkOrder_Update_SendReminder on WorkOrder (after update) {
    System.debug('✅ WorkOrderTrigger fired');
    
    for (WorkOrder wo : Trigger.new) {
        WorkOrder oldWO = Trigger.oldMap.get(wo.Id);
        System.debug(' old: ' + oldWO.Follow_Up_Appointment_Date__c + 'changed :' + wo.Follow_Up_Appointment_Date__c);
        if (wo.Follow_Up_Appointment_Date__c != oldWO.Follow_Up_Appointment_Date__c){
            System.debug('🔁 Follow_Up_Appointment_Date__c changed: ' + wo.Id);
            FollowUpNotificationService.sendFollowUpReminder(wo.Id);
        }
    } 
}