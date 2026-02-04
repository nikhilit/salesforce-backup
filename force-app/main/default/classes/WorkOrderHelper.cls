public class WorkOrderHelper {
  public static void createFollowUpAppointments(List<WorkOrder> workOrders) {
        List<ServiceAppointment> followUps = new List<ServiceAppointment>();
        System.debug('Starting createFollowUpAppointments for ' + workOrders.size() + ' work orders');
		  String gsRecordTypeID = Schema.getGlobalDescribe().get('WorkOrder').getDescribe().getRecordTypeInfosByDeveloperName()
              	.get('MGL_Metering').getRecordTypeId();
        String getOMRecordTypeID = Schema.getGlobalDescribe().get('WorkOrder').getDescribe().getRecordTypeInfosByDeveloperName()
              	.get('MGL_O_M').getRecordTypeId();
        for (WorkOrder wo : workOrders) {
            System.debug('Processing WorkOrder: ' + wo.Id + ' | Status: ' + wo.Status + ' | Attempt Count: ' + wo.Attempt_Count__c);

            if (wo.RecordTypeId!=gsRecordTypeID && wo.RecordTypeId!=getOMRecordTypeID &&
                wo.Status == 'Customer Unavailable' &&
                (wo.Attempt_Count__c == null || wo.Attempt_Count__c < 4)
            ) {
                System.debug('WorkOrder ' + wo.Id + ' is eligible for follow-up');

                List<ServiceAppointment> saList = [
                    SELECT Id, SchedStartTime, SchedEndTime
                    FROM ServiceAppointment
                    WHERE ParentRecordId = :wo.Id
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];

                System.debug('Found ' + saList.size() + ' latest ServiceAppointment(s) for WorkOrder ' + wo.Id);

                if (!saList.isEmpty()) {
                    ServiceAppointment lastSA = saList[0];
                    System.debug('Last Appointment: ' + lastSA.Id + 
                                 ' | Start: ' + lastSA.SchedStartTime + 
                                 ' | End: ' + lastSA.SchedEndTime);

                    ServiceAppointment followUp = new ServiceAppointment();
                    followUp.ParentRecordId = wo.Id;
                    followUp.Status = 'None';
                    followUp.SchedStartTime = DateTime.now().addDays(7);
                    followUp.SchedEndTime = DateTime.now().addDays(7).addHours(1);
                    followUp.Subject = 'Follow-Up Visit for Customer Unavailable';
                    followUp.Description = 'Auto-created due to status "Customer Unavailable" on WorkOrder: ' + wo.Id;
                    followUp.Attempt_Count__c = (wo.Attempt_Count__c == null ? 1 : wo.Attempt_Count__c + 1);

                    System.debug('Creating Follow-Up Appointment: ' +
                        'WorkOrderId=' + wo.Id +
                        ', Attempt=' + followUp.Attempt_Count__c +
                        ', Start=' + followUp.SchedStartTime +
                        ', End=' + followUp.SchedEndTime);

                    followUps.add(followUp);
                } else {
                    System.debug('No ServiceAppointment found for WorkOrder ' + wo.Id);
                }
            } else {
                System.debug('Skipping WorkOrder ' + wo.Id + ' due to ineligible status or attempt count');
            }
        }

        if (!followUps.isEmpty()) {
            System.debug('Inserting ' + followUps.size() + ' follow-up appointments');
            insert followUps;
        } else {
            System.debug('No follow-up appointments to insert');
        }

        System.debug('createFollowUpAppointments execution completed.');
        
    }
}