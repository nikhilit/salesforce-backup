/**
* @File Name : AS_CSVChunkProcessor.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : July 14, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | July 14, 2025 |   | Initial Version
**/
public class AS_CSVChunkProcessor implements Queueable {

    private List<Map<String, String>> records;
    private String objectName;
    private String externalIdField;

    public AS_CSVChunkProcessor(List<Map<String, String>> records, String objectName, String externalIdField) {
        this.records = records;
        this.objectName = objectName;
        this.externalIdField = externalIdField;
    }

    public void execute(QueueableContext context) {
        try {
            //AS_CSVUploaderController.uploadCSVBatch(records, objectName, externalIdField);
            AS_CSVUploaderController.uploadCSVBatch(objectName, records);
        } catch (Exception e) {
			//String id = !records.isEmpty() ? records[0].get('Id') : null;
			AS_ErrorLogger.log('AS_CSVChunkProcessor', 'execute', e, '');
        }
    }
}