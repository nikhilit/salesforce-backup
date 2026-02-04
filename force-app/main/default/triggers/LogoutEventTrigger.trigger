trigger LogoutEventTrigger on LogoutEventStream (after insert) {
    LogoutEventHandler.handle(Trigger.new);
}