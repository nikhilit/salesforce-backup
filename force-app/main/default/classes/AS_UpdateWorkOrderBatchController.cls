public with sharing class AS_UpdateWorkOrderBatchController {
    @AuraEnabled
    public static String startBatchUpdate(String batchLot, Date endDate) {
        if (String.isBlank(batchLot) || endDate == null) {
            throw new AuraHandledException('Both Batch Lot and End Date are required.');
        }

        // Get batch size from custom label
        Integer batchSize;
        try {
            batchSize = Integer.valueOf(Label.Batch_Size_WorkOrder_Update);
        } catch (Exception e) { batchSize = 200; }

		AS_UpdateWorkOrderEndDateBatch batch = new AS_UpdateWorkOrderEndDateBatch(batchLot, endDate);
        Database.executeBatch(batch, batchSize);
        return 'Batch job started successfully for Batch Lot: ' + batchLot +
                                   ' (Batch size: ' + batchSize + ')';

    }
}