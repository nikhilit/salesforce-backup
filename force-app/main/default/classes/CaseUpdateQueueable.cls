public class CaseUpdateQueueable implements Queueable, Database.AllowsCallouts {

    private Map<String, Object> fieldValues;
    private List<String> caseIds;

    public CaseUpdateQueueable(Map<String, Object> fieldValues, List<String> caseIds) {
        this.fieldValues = fieldValues;
        this.caseIds = caseIds;
    }

    public void execute(QueueableContext context) {
        String status;
        String message;

        try {
            if (fieldValues == null || fieldValues.isEmpty() || caseIds == null || caseIds.isEmpty()) {
                throw new AuraHandledException('No field values or case IDs provided.');
            }

            Map<String, Object> processedFieldValues = new Map<String, Object>();
Set<String> picklistFields = new Set<String>{'Department__c', 'Origin', 'Category__c', 'Priority'};

            for (String key : fieldValues.keySet()) {
                Object value = fieldValues.get(key);
                if (value != null) {
                    if (picklistFields.contains(key)) {
                        processedFieldValues.put(key, getPicklistApiValue('Case', key, (String)value));
                    } else {
                        processedFieldValues.put(key, value);
                    }
                }
            }

            List<Case> casesToUpdate = new List<Case>();
            for (Case c : [SELECT Id FROM Case WHERE Id IN :caseIds]) {
                Case caseRec = new Case(Id = c.Id);
                for (String key : processedFieldValues.keySet()) {
                    Object val = processedFieldValues.get(key);
                    if (val != null) caseRec.put(key, val);
                }
                casesToUpdate.add(caseRec);
            }

            if (!casesToUpdate.isEmpty()) {
                update casesToUpdate;
                status = 'Success';
                message = casesToUpdate.size() + ' cases updated successfully.';
            } else {
                status = 'Skipped';
                message = 'No cases found for update.';
            }

        } catch (Exception e) {
            status = 'Failed';
            message = e.getMessage();
        }

        // Publish platform event after processing
        Bulk_Update_Result__c res = new Bulk_Update_Result__c(
            JobId__c = context.getJobId(),   // ✔ CORRECT WAY to get jobId
            Status__c = status,
            Message__c = message
        );
        insert res;
    }

    private static String getPicklistApiValue(String sObjectName, String fieldName, String label) {
        Schema.DescribeFieldResult fieldResult = 
            Schema.getGlobalDescribe().get(sObjectName).getDescribe().fields.getMap().get(fieldName).getDescribe();
        for (Schema.PicklistEntry ple : fieldResult.getPicklistValues()) {
            if (ple.getLabel() == label) return ple.getValue();
        }
        return label;
    }
}