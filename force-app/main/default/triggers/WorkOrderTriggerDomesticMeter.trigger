trigger WorkOrderTriggerDomesticMeter on WorkOrder (after insert, after update) {
    System.debug('Inside work order trigger domestic meter');
    if (Trigger.isAfter) {
        WorkOrderHelper.createFollowUpAppointments(Trigger.new);
    } 
}