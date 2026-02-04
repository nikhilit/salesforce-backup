/**
 * @File Name       : WorkOrderSMSBatch.cls
 * @Description     : Batch processor for sending WorkOrder SMS notifications in bulk.
 * @Last Modified On: September 22, 2025
 */
public class WorkOrderSMSBatch
    implements Database.Batchable<WorkOrderNotificationService.WorkOrderNotificationWrapper>,
Database.AllowsCallouts {
    
    private List<WorkOrderNotificationService.WorkOrderNotificationWrapper> wrapperList;
    
    public WorkOrderSMSBatch(List<WorkOrderNotificationService.WorkOrderNotificationWrapper> wrapperList){
        // System.debug('WorkOrderSMSBatch called');
        this.wrapperList = wrapperList;
    }
    
    // Start method returns the wrapper list for processing
    public Iterable<WorkOrderNotificationService.WorkOrderNotificationWrapper> start(Database.BatchableContext bc) {
        return wrapperList;
    }
    
    // Execute method processes each batch chunk
    public void execute(Database.BatchableContext bc, List<WorkOrderNotificationService.WorkOrderNotificationWrapper> scope) {
        if (!TriggerController.isTriggerActive('SmsBulkAPICallout')) return;
        
        
        // Build one bulk payload for this scope
        SmsBulkAPICallout.SmsBulkPayload payload = SmsBulkAPICallout.buildBulkSmsPayload(scope);
        if (payload == null || String.isBlank(payload.json)) {
            System.debug('WorkOrderSMSBatch: No valid payload built for this scope.');
            return;
        }
        
        // Send synchronously (safe inside batch)
        SmsBulkAPICallout.sendBulkSmsWithUpdateSync(
            payload.json,
        JSON.serialize(payload.woIdsInOrder),
        JSON.serialize(payload.destPhonesInOrder),
        JSON.serialize(payload.phoneToIndices)
            );
    }
    
    // Finish method for logging or notifications
    public void finish(Database.BatchableContext bc) {
        System.debug('✅ WorkOrderSMSBatch completed successfully.');
    }
}