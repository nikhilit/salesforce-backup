trigger DispenserPoint_Update_ValidateReading on Dispenser_Point__c (after update,after insert) {
     if (Trigger.isAfter && Trigger.isUpdate) {
    for (Dispenser_Point__c dp : Trigger.new) {
        Dispenser_Point__c oldDP = Trigger.oldMap.get(dp.Id);
        if (dp.Closing_Reading__c != oldDP.Closing_Reading__c) {
            if (dp.Closing_Reading__c != null && dp.SCADA_Closing_Reading__c != null) {
                System.debug('🧮 Both Closing and SCADA readings are present, calling validation service');
                MeterReadingValidationService.validateClosingReading(dp.Id);
            }
        }
    }
     }
    if (Trigger.isAfter) {
        DispenserPointHandler.handleLiveFlag(
            Trigger.new,
            Trigger.isUpdate ? Trigger.oldMap : null
        );
    }
}