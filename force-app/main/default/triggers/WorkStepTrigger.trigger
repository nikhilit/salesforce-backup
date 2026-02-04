trigger WorkStepTrigger on WorkStep (after update) {
    if (!TriggerController.isTriggerActive('WorkStepTrigger')) {
        return;
    }
Set<Id> workOrderIds = new Set<Id>();

    for (WorkStep step : Trigger.new) {
        WorkStep oldStep = Trigger.oldMap.get(step.Id);

        // Track only if status has changed
        if (step.Status != oldStep.Status) {
            if (step.Status == 'Completed' || step.Status == 'Not Applicable') {
                if (step.WorkOrderId != null) {
                    workOrderIds.add(step.WorkOrderId);
                }
            }
        }
    }

    if (!workOrderIds.isEmpty()) {
        WorkStepHelper.processWorkOrders(workOrderIds);
    }
}