trigger DocumentContentVersionTrigger on Document__c (after insert, after update) {
       if(Trigger.isAfter) {
           if(Trigger.isInsert) {
             //  DocumentContentVersionHandler.afterInsert(Trigger.new);
           }
           if(Trigger.isUpdate) {
             //  DocumentContentVersionHandler.afterUpdate(Trigger.new, Trigger.oldMap);
           } 
       } 
   }