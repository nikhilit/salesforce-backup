trigger WorkOrderTriggerAgent on WorkOrder (after insert, after update) {
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        WorkOrderTriggerHandlerAgent.handleTechnicianAssignment(Trigger.new, Trigger.oldMap);
    }
}