trigger TruncateDecimalOnAccountDispensor on Account_Dispensor__c (before insert, before update) {
    for (Account_Dispensor__c AD : Trigger.new) {
       
        if (AD.Opening_Reading__c != null) {
            AD.Opening_Reading__c = Decimal.valueOf(AD.Opening_Reading__c.intValue());
        }
            
         if (AD.Closing_Reading__c != null) {
            AD.Closing_Reading__c = Decimal.valueOf(AD.Closing_Reading__c.intValue());
        }
        
        
        
    }
}