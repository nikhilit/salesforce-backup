trigger PaymentTrigger on Payment__c (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        
        List<Payment__c> lstPayment = new List<Payment__c>();
        
        for (Payment__c pay : [SELECT Id, Name, Cheque_Amount__c, Work_Order__c, ReceiptNo__c,
                                      Work_Order__r.RecordType.DeveloperName, 
                                      Work_Order__r.RecordTypeId,
                                      Work_Order__r.Record_Type_Developer_Name__c,
                                      Work_Order__r.AccountId, 
                                      Work_Order__r.Account.Phone,
                                      Work_Order__r.Account.CA_Number__c,
                                      Work_Order__r.New_Mobile_Number__c,
                                      Work_Order__r.CA_Number__c,
                                      Work_Order__r.Agency_Name_Formula__c,
                                      Work_Order__r.Agent__r.Name,
                                      Work_Order__r.Payment_Mode__c
                                 FROM Payment__c
                                WHERE Id IN : Trigger.new]) {
            if(pay.Work_Order__r != null && pay.Work_Order__r.RecordType.DeveloperName == 'MGL_R_T' && pay.Cheque_Amount__c != null){
                lstPayment.add(pay);                                    
            }
        }
        if(!lstPayment.isEmpty()) AS_PaymentNotificationService.processNotifications(lstPayment);
    }
}