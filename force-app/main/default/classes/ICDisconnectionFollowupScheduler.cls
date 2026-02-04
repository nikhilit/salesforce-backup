global class ICDisconnectionFollowupScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        System.debug('🕒 ICDisconnectionFollowupScheduler triggered');
        ICDisconnectionFollowupHandler batch = new ICDisconnectionFollowupHandler();
        Database.executeBatch(batch, 100);
    }
}