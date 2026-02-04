global class UnifiedLookupScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        // Comma-separated list of object API names
        String csvObjects = 'Premise__c,Identification_Number__c,Installation__c,Billing__c,Account,Device_Allocation__c';
        List<String> objectNames = csvObjects.split(',');

        if (!objectNames.isEmpty()) {
            // Start with the first object
            System.enqueueJob(new UnifiedLookupQueueable(objectNames, 0));
        }
    }
}