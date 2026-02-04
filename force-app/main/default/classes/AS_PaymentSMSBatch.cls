public class AS_PaymentSMSBatch
    implements Database.Batchable<AS_PaymentNotificationService.WorkOrderNotificationWrapper>,
Database.AllowsCallouts {
    
    private List<AS_PaymentNotificationService.WorkOrderNotificationWrapper> wrapperList;
    
    public AS_PaymentSMSBatch(List<AS_PaymentNotificationService.WorkOrderNotificationWrapper> wrapperList) {
        this.wrapperList = wrapperList;
    }
    
    public Iterable<AS_PaymentNotificationService.WorkOrderNotificationWrapper> start(Database.BatchableContext bc) {
        return wrapperList;
    }
    
    public void execute(Database.BatchableContext bc, List<AS_PaymentNotificationService.WorkOrderNotificationWrapper> scope) {
        
        system.debug('========scope=======>'+scope);
        
        if (!TriggerController.isTriggerActive('SmsBulkAPICallout')) return;
        
        SmsBulkAPICallout.SmsBulkPayload payload = SmsBulkAPICallout.buildBulkSmsPayloadForPayment(scope);
        
        system.debug('========payload=======>'+payload);
        
        if (payload == null || String.isBlank(payload.json)) {
            System.debug('PaymentSMSBatch: No payload built for this scope.');
            return;
        }
        
        SmsBulkAPICallout.sendBulkSmsWithUpdateSync(
            payload.json,
        JSON.serialize(payload.woIdsInOrder),
        JSON.serialize(payload.destPhonesInOrder),
        JSON.serialize(payload.phoneToIndices)
            );
    }
    
    public void finish(Database.BatchableContext bc) {
        System.debug('✅ PaymentSMSBatch completed successfully.');
    }
}