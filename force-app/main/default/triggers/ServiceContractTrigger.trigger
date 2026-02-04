trigger ServiceContractTrigger on ServiceContract (before insert,before update) {
    if (!TriggerController.isTriggerActive('serviceContractTrigger')) {
        return;
    }
        ServiceContractHandler.populateContractDetails(Trigger.new,Trigger.oldMap);
}