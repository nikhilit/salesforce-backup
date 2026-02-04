/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 14-10-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   07-07-2025   Kartik Patkar, Appstrail   Initial Version
**/
trigger ContentVersionTrigger on ContentVersion (before insert,after insert,after update) {

    if (!TriggerController.isTriggerActive('ContentVersionTrigger')) {
        return;
    }

    if(Trigger.isBefore){
        if(Trigger.isInsert){
            for (ContentVersion cv : Trigger.new) {
                if (cv.In_Direct_Meter_Reading__c && (cv.Title == null || cv.Title == '')) {
                    cv.Title = 'File_' + DateTime.now().format('yyyyMMdd_HHmmss');
                    cv.PathOnClient = cv.Title + '.' + (cv.FileExtension != null ? cv.FileExtension : 'jpeg');
                    cv.ContentLocation = 'S';
                }
            }
        }
    }

    if(Trigger.isAfter){
        if(Trigger.isInsert){
            ContentVersionTriggerHandler.afterInsert(Trigger.new);
        }
        if(Trigger.isUpdate){
            ContentVersionTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}