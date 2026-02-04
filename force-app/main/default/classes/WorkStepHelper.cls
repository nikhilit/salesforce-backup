public class WorkStepHelper {
    public static void processWorkOrders(Set<Id> workOrderIds) {
        List<WorkOrder> ordersToUpdate = new List<WorkOrder>();
        List<WorkStep> stepsToUpdate = new List<WorkStep>();

        Map<Id, List<WorkStep>> workOrderToStepsMap = new Map<Id, List<WorkStep>>();

        // Query all work steps for these work orders
        List<WorkStep> allSteps = [
            SELECT Id, Status, WorkOrderId
            FROM WorkStep
            WHERE WorkOrderId IN :workOrderIds
        ];

        // Organize work steps by work order
        for (WorkStep step : allSteps) {
            if (!workOrderToStepsMap.containsKey(step.WorkOrderId)) {
                workOrderToStepsMap.put(step.WorkOrderId, new List<WorkStep>());
            }
            workOrderToStepsMap.get(step.WorkOrderId).add(step);
        }

        for (Id workOrderId : workOrderToStepsMap.keySet()) {
            List<WorkStep> steps = workOrderToStepsMap.get(workOrderId);
            Boolean allCompleted = true;
            Boolean anyNotApplicable = false;

            for (WorkStep step : steps) {
                if (step.Status != 'Completed') {
                    allCompleted = false;
                }
                if (step.Status == 'Not Applicable') {
                    anyNotApplicable = true;
                }
            }

            // If all steps are Completed
            if (allCompleted) {
                ordersToUpdate.add(new WorkOrder(
                    Id = workOrderId,
                    Status = 'Completed'
                ));
            }
            // If any step is Not Applicable, cancel all 'New' steps and cancel order
            else if (anyNotApplicable) {
                for (WorkStep step : steps) {
                    if (step.Status == 'New') {
                        WorkStep s = new WorkStep(
                            Id = step.Id,
                            Status = 'Not Applicable'
                        );
                        stepsToUpdate.add(s);
                    }
                }

                ordersToUpdate.add(new WorkOrder(
                    Id = workOrderId,
                    Status = 'Canceled'
                ));
            }
        }

        if (!stepsToUpdate.isEmpty()) {
            update stepsToUpdate;
        }

        if (!ordersToUpdate.isEmpty()) {
            update ordersToUpdate;
        }
    }
}