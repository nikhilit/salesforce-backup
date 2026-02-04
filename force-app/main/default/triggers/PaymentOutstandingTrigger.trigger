trigger PaymentOutstandingTrigger on Payment_Outstanding__c (after update, after insert) {
    
    if (!TriggerController.isTriggerActive('PaymentOutstandingTrigger')) { 
        return;
    }
    
    if(Trigger.isAfter && Trigger.isInsert){
        
        List<Payment_Outstanding__c> payOut = new List<Payment_Outstanding__c>();
        
        for(Payment_Outstanding__c newPO : Trigger.new){
            if(newPO.BP_Number__c != null && 
               newPO.Last_Payment_Amount_Paid__c != null &&
			   newPO.Last_Payment_Date__c != null){
               //&& newPO.LastModifiedBy.Name == 'Automated User'
               payOut.add(newPO);
            }
        }
        if(!payOut.isEmpty()) AS_PaymentOutstandingHandler.handleAfterUpdate(payOut);   
    }
    
    if(Trigger.isAfter && Trigger.isUpdate){
        
        List<Payment_Outstanding__c> payOut = new List<Payment_Outstanding__c>();
        
        for(Payment_Outstanding__c newPO : Trigger.newMap.values()){
            Payment_Outstanding__c oldPO = Trigger.oldMap.get(newPO.Id);
            
            if((newPO.BP_Number__c != oldPO.BP_Number__c || 
                newPO.Last_Payment_Date__c != oldPO.Last_Payment_Date__c || 
                newPO.Last_Payment_Amount_Paid__c != oldPO.Last_Payment_Amount_Paid__c) && 
                newPO.BP_Number__c != null && 
                newPO.Last_Payment_Date__c != null &&
                newPO.Last_Payment_Amount_Paid__c != null){                
               //&& newPO.LastModifiedBy.Name == 'Automated User'
               payOut.add(newPO);    
            }
        }
        if(!payOut.isEmpty()) AS_PaymentOutstandingHandler.handleAfterUpdate(payOut);  
    }
}