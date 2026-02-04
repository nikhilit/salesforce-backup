trigger ContentVersionStatusTrigger on ContentVersion (
    after update, after delete, after insert, before insert, before update
) {
    if (!TriggerController.isTriggerActive('ContentVersionStatusTrigger')) {
        return;
    }

    // ✅ Only call handleInsert for insert contexts
    if (!System.isFuture() && ((Trigger.isAfter && Trigger.isInsert) || (Trigger.isBefore && Trigger.isInsert))) {
        ContentVersionStatusHandler.handleInsert(Trigger.new);
    }
}