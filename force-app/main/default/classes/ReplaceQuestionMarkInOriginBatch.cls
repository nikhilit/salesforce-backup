global class ReplaceQuestionMarkInOriginBatch implements Database.Batchable<SObject> {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, Origin FROM Case WHERE Origin LIKE \'%--%\''
        );
    }

    global void execute(Database.BatchableContext bc, List<Case> scope) {
        for (Case c : scope) {
            if (c.Origin != null && c.Origin.contains('--')) {
                c.Origin = c.Origin.replace('--', '–');
            }
        }
        if (!scope.isEmpty()) {
            update scope;
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Batch completed: Case Origin updated where "?" was found.');
    }
}