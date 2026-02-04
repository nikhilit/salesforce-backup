/**
* @description       : 
* @author            : Kartik Patkar Appstrail
* @group             : 
* @last modified on  : 29-01-2026
* @last modified by  : Kartik Patkar, Appstrail
* Modifications Log
* Ver   Date         Author                     Modification
* 1.0   14-05-2025   Kartik Patkar, Appstrail   Added TriggerController to check if the trigger is active (Line #13)
* 2.0   19-05-2025   Shruthi S D, Appstrail     Added  Initial trigger to assign agency on WorkOrder before insert (Line #29)
* 3.0   05-10-2025   Kartik Patkar, Appstrail   Added  MeterReadingSchedule Count Logic
**/
trigger WorkOrderTrigger on WorkOrder (before insert, after insert, after update,before update, after delete) {
    
    if (!TriggerController.isTriggerActive('WorkOrderTrigger')) { 
        return;
    }
    
    // Handling address assignment and other updates before the insert operation
    if (Trigger.isBefore && Trigger.isInsert) {
        //WorkOrderTriggerHandler.assignAddressesAndCreateAppointments(Trigger.new);
        WorkOrderTriggerHandler.beforeInsert(Trigger.new);
        MeterReadingPlausibilityCheckHelper.checkWorkOrderPlausibility(Trigger.new, null);
        
        // RtWorkOrderHandler.assignAccountFromBPNumber(Trigger.new);
        
        /*List<WorkOrder> workOrder = new List<WorkOrder>();
        for (WorkOrder wo : Trigger.new) {
            if(wo.RecordType.DeveloperName == 'MGL_Metering'){
                workOrder.add(wo);
            }           
        }
        if (!workOrder.isEmpty()) {
            WorkOrderTriggerHandler.createDispenserPoints(workOrder);
        }*/
    }
    
    // updates before the update operation
    if (Trigger.isBefore && Trigger.isUpdate) {
        MeterReadingPlausibilityCheckHelper.checkWorkOrderPlausibility(Trigger.new, Trigger.oldMap);
    }
    
    // Handling ServiceAppointment creation after the WorkOrder is inserted
    if (Trigger.isAfter && Trigger.isInsert) {
        
        WorkOrderTriggerHandler.handleAfterSave(Trigger.new, null);
        
        O_MWorkOrderAssignmentContr.assignWorkOrder(Trigger.new);
        O_MRiserWOAssignResource.assignWorkOrder(Trigger.new); //Assign resource for riser apps
        // RtWorkOrderHandler.sendSmsAfterCreation(Trigger.new); //shashank
        WorkOrderTriggerHandler.createDispenserPoints(Trigger.new);
        WorkTypeAssignmentHandler.createWorkPlan(Trigger.new);
        //RtWorkOrderHandler.createNotificationAfterWorkOrderCreation(Trigger.new);  shashank
        
        //WorkOrderTriggerHandler.createServiceAppointmentsAfterInsert(Trigger.new);
    }
    // After insert: assign Agency (ServiceTerritory) to WorkOrder
    if (Trigger.isAfter && Trigger.isInsert) {
        //AgencyAssignmentHandler.handleAfterInsert(Trigger.new);
    }
    
    if(Trigger.isAfter && Trigger.isUpdate){

        MeteringCommunicationHelper.afterUpdate(Trigger.new, Trigger.oldMap);
        AssignAgentCommunicationHelper.afterUpdate(Trigger.new,Trigger.oldMap);

        WorkOrderTriggerHandler.handleAfterSave(Trigger.new, Trigger.oldMap);

		WorkOrderTriggerHandler.syncOfflineSaStatus(Trigger.new, Trigger.oldMap);

        //O&M After update Total Number of risers

        CreateWOLItemBasedOnRiserNumber.afterUpdate(Trigger.new, Trigger.oldMap);

        
        // RtWorkOrderHandler.sendSmsAfterCompletion(Trigger.new, Trigger.oldMap);
        
        List<Id> rejectedWorkOrderIds = new List<Id>();
        List<Id> approvedWorkOrderIds = new List<Id>();
        
        
        
        
        for (WorkOrder wo : Trigger.new) {
            WorkOrder oldWo = Trigger.oldMap.get(wo.Id);
            
            if (wo.Approval_Status__c == 'Rejected' &&
                oldWo.Approval_Status__c != 'Rejected') {
                    rejectedWorkOrderIds.add(wo.Id);
                }
            if (
                wo.Approval_Status__c == 'Approved' &&
                oldWo.Approval_Status__c != 'Approved' &&
                wo.Record_Type_Developer_Name__c == 'MGL_Metering' &&
                wo.Customer_Category__c == 'CNG/LNG'
            ) {
                System.debug('Inside PDF logic for Approved & MGL_Metering');
                approvedWorkOrderIds.add(wo.Id);
            }
        }
        WorkOrderTriggerHandler.handleStatusUpdate(Trigger.new, Trigger.oldMap);
        
        if (!approvedWorkOrderIds.isEmpty()) {
            // Pass jobKey from controller context (set during bulk approval UI flow)
            String jobKey = WorkOrderBulkApprovalController.currentJobKey;
            System.debug(LoggingLevel.WARN, '[WO Progress] Trigger approvedWorkOrderIds=' + approvedWorkOrderIds.size() + ', jobKey=' + jobKey);
            WorkOrderTriggerHandler.attachPDFsAsync(approvedWorkOrderIds, jobKey);

            //Update metering readings on work order approval
            WorkOrderTriggerHandler.updateMeterReadings(approvedWorkOrderIds);
        }
        if (!rejectedWorkOrderIds.isEmpty()) {
            O_MWorkOrderUpdateContr.deleteDocumentsAfterReject(rejectedWorkOrderIds);
        } 
    }

    // COUNTING MRS LOGIC
    if(Trigger.isAfter){
        if (Trigger.isInsert)
            MeterReadingScheduleHelper.updateScheduleCounts(Trigger.new, null);
        else if (Trigger.isUpdate){
            MeterReadingScheduleHelper.updateScheduleCounts(Trigger.new, Trigger.old);
            WorkOrderBulkApprovalController.reassignServiceAppointment(Trigger.new, Trigger.oldMap);
        }
        else if (Trigger.isDelete){
            MeterReadingScheduleHelper.updateScheduleCounts(null, Trigger.old);
            MeterReadingScheduleHelper.mROtoUnallocatedBucket(Trigger.old);
        }
    }
}