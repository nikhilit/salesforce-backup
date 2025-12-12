trigger AccountCheckboxTrigger on Account (After insert) {
    AccountCheckboxTrigger.createcontanddesc(Trigger.new);
}