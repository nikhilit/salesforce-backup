public class BillingQRCBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    private Set<String> existingKeys;
    private Integer totalInserted = 0;
    private Integer totalSkipped = 0;
    private List<QRC_Process__c> activeQrcs;
    
    public BillingQRCBatch() {
        // Initialize in constructor to avoid governor limits in start method
        this.existingKeys = new Set<String>();
        this.activeQrcs = [SELECT Id FROM QRC_Process__c WHERE Department__c = 'Billing' AND IsActive__c = true];
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        // Query all Billing source mappings to process
        return Database.getQueryLocator([
            SELECT Id, Department__c, DRS__c, SPOC_Id__c, SPOC_Id_2__c, SPOC_Id_3__c, SPOC_Id_4__c
            FROM Departments_SPOC_Mapping__c
            WHERE Department__c = 'Billing'
        ]);
    }
    
    public void execute(Database.BatchableContext BC, List<Departments_SPOC_Mapping__c> sourceMappings) {
        
        // Build existing keys set for this batch scope
        if (existingKeys.isEmpty()) {
            for (Departments_SPOC_Mapping__c e : [
                SELECT DRS__c, QRC_Process__c
                FROM Departments_SPOC_Mapping__c
                WHERE Department__c = 'Billing' AND QRC_Process__c != null
            ]) {
                String k = String.valueOf(e.DRS__c) + '|' + String.valueOf(e.QRC_Process__c);
                existingKeys.add(k);
            }
        }
        
        List<Departments_SPOC_Mapping__c> recordsToInsert = new List<Departments_SPOC_Mapping__c>();
        
        // Process each source mapping against all active QRCs
        for (Departments_SPOC_Mapping__c baseRec : sourceMappings) {
            for (QRC_Process__c qrc : activeQrcs) {
                String key = String.valueOf(baseRec.DRS__c) + '|' + String.valueOf(qrc.Id);
                
                if (existingKeys.contains(key)) {
                    totalSkipped++;
                    continue;
                }
                
                recordsToInsert.add(new Departments_SPOC_Mapping__c(
                    Department__c = baseRec.Department__c,
                    DRS__c = baseRec.DRS__c,
                    SPOC_Id__c = baseRec.SPOC_Id__c,
                    SPOC_Id_2__c = baseRec.SPOC_Id_2__c,
                    SPOC_Id_3__c = baseRec.SPOC_Id_3__c,
                    SPOC_Id_4__c = baseRec.SPOC_Id_4__c,
                    QRC_Process__c = qrc.Id
                ));
                
                existingKeys.add(key);
            }
        }
        
        // Insert records in chunks to avoid DML limits
        if (!recordsToInsert.isEmpty()) {
            List<Database.SaveResult> results = Database.insert(recordsToInsert, false);
            
            // Count successful inserts
            for (Database.SaveResult sr : results) {
                if (sr.isSuccess()) {
                    totalInserted++;
                }
            }
        }
        
        System.debug('Batch processed. Inserted in this batch: ' + recordsToInsert.size());
    }
    
    public void finish(Database.BatchableContext BC) {
        System.debug('✅ Billing QRC Batch completed!');
        System.debug('Total Inserted: ' + totalInserted);
        System.debug('Total Skipped: ' + totalSkipped);
        
        // Optional: Send email notification
        //sendCompletionEmail();
    }
    
}