/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 25-07-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   18-05-2025   Kartik Patkar, Appstrail   Initial Version
**/
trigger ServiceAppointmentTrigger on ServiceAppointment (before insert,after insert,before update, after Update) {
    if (!TriggerController.isTriggerActive('ServiceAppointmentTrigger')) {
        return;
    }

    if(Trigger.isInsert && Trigger.isBefore) {
        ServiceAppointmentTriggerHandler.beforeInsert(Trigger.new);
         //ServiceAppointmentTriggerHandler.mapWorkOrderDatesToAppointments(Trigger.new);
    }
    if(Trigger.isUpdate && Trigger.isBefore) {

    }
    if(Trigger.isInsert && Trigger.isAfter){
        ServiceAppointmentTriggerHandler.afterInsert(Trigger.new);
    }
    
   
    
   
    
    
}