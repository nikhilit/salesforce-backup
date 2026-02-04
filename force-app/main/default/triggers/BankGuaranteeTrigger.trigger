trigger BankGuaranteeTrigger on Bank_Guarantee__c (after insert) {
	BankGuaranteeTriggerHandler.shareWithDealer(Trigger.new);
}