public without sharing class AS_CaseCSVChunkProcessor implements Queueable, Database.AllowsCallouts {
    private String objectName;
    private String recordsJson;

    public AS_CaseCSVChunkProcessor(String objectName, String recordsJson) {
        this.objectName = objectName;
        this.recordsJson = recordsJson;
    }

    public void execute(QueueableContext context) {
        try {
            // Deserialize JSON back to List<Map<String,String>>
            List<Map<String,String>> records = new List<Map<String,String>>();
            if (String.isNotBlank(recordsJson)) {
                records = (List<Map<String,String>>) JSON.deserialize(recordsJson, List<Map<String,String>>.class);
            }

            Map<String, Object> result = AS_CaseCSVUploaderController.processChunk(this.objectName, records);

            System.debug('Chunk processing completed: ' + result.get('successCount') + ' successes, ' +
                        ((List<Map<String,String>>)result.get('errors')).size() + ' errors');

        } catch (Exception ex) {
            AS_ErrorLogger.log('AS_CaseCSVChunkProcessor', 'execute', ex, null);
        }
    }
}