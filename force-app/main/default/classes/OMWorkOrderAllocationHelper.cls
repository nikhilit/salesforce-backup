public without sharing class OMWorkOrderAllocationHelper {

    public static void createWorkOrders(List<O_M_Appointment_Request__c> listRequests) {
        System.debug('createWorkOrders called with ' + listRequests.size() + ' records');

        List<WorkOrder> listWorkOrders = new List<WorkOrder>();
        Map<String, O_M_Appointment_Request__c> reqNameToRequest = new Map<String, O_M_Appointment_Request__c>();

        Id workOrderRecordTypeId = Schema.getGlobalDescribe().get('WorkOrder')
            .getDescribe().getRecordTypeInfosByDeveloperName()
            .get('MGL_O_M')
            .getRecordTypeId();

        Map<String, Id> workTypeNameToIdMap = new Map<String, Id>();
        for (WorkType wt : [SELECT Id, Name FROM WorkType]) {
            workTypeNameToIdMap.put(wt.Name.trim().toLowerCase(), wt.Id);
        }

        List<String> skippedLabels = new List<String>();

        for (O_M_Appointment_Request__c req : listRequests) {
            System.debug('Processing Request: ' + req.Id);

            if (req.Account__c == null || String.isBlank(req.Activity_Type__c)) {
                System.debug('Skipped: Missing Account or Activity_Type__c for ' + req.Id);
                continue;
            }

            String activityLabel = req.Activity_Type__c.trim().toLowerCase();

            if (!workTypeNameToIdMap.containsKey(activityLabel)) {
                System.debug('Skipped: No matching WorkType for label: ' + activityLabel);
                skippedLabels.add(req.Activity_Type__c);
                continue;
            }

            WorkOrder wo = new WorkOrder();
            wo.Subject = 'O&M Request - ' + req.Name;
            wo.AccountId = req.Account__c;
            wo.Building_Name__c = req.Building_Name__c;
            wo.Marketing_BP_Status__c = req.Marketing_BP_Status__c;
            wo.Address_Line_1__c = req.Address1__c;
            wo.Address_Line_2__c = req.Address2__c;
            wo.Move_In_Date__c = req.Move_In_Date__c;
            wo.Move_Out_Date__c = req.Move_Out_Date__c;
            wo.Amount_Received__c = req.Amount_Received__c;
            wo.WorkTypeId = workTypeNameToIdMap.get(activityLabel);
            wo.Department__c = 'O&M';
            wo.Status = 'New';
            wo.RecordTypeId = workOrderRecordTypeId;

            listWorkOrders.add(wo);
            reqNameToRequest.put(req.Name.trim(), req);
        }

        if (!listWorkOrders.isEmpty()) {
            try {
                insert listWorkOrders;
                System.debug('Inserted ' + listWorkOrders.size() + ' WorkOrders');

                Map<String, WorkOrder> reqNameToWorkOrder = new Map<String, WorkOrder>();
                for (WorkOrder wo : listWorkOrders) {
                    String reqName = wo.Subject != null ? wo.Subject.replace('O&M Request - ', '').trim() : null;
                    if (reqName != null) {
                        reqNameToWorkOrder.put(reqName, wo);
                    }
                }

                for (String reqName : reqNameToRequest.keySet()) {
                    O_M_Appointment_Request__c req = reqNameToRequest.get(reqName);
                    if (reqNameToWorkOrder.containsKey(reqName)) {
                        WorkOrder wo = reqNameToWorkOrder.get(reqName);
                        req.Created_Order__c = true;
                        req.Created_Work_Order__c = wo.Id;
                        System.debug('Linked WorkOrder ' + wo.Id + ' to request ' + req.Id);
                    }
                }

                update listRequests;
                System.debug('Updated ' + listRequests.size() + ' Appointment Requests');

                // Create Service Appointments safely
                List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>();
                for (String reqName : reqNameToWorkOrder.keySet()) {
                    WorkOrder wo = reqNameToWorkOrder.get(reqName);
                    O_M_Appointment_Request__c req = reqNameToRequest.get(reqName);

                    Date startDate = req.Start_Date__c != null ? req.Start_Date__c.date() : null;
                    Date endDate = startDate != null ? startDate.addDays(3) : null;

                    ServiceAppointment sa = new ServiceAppointment();
                    sa.ParentRecordId = wo.Id;
                    sa.Status = 'New';
                    sa.Subject = wo.Subject;
                    sa.Description = 'Auto-created for O&M Appointment';

                    if (startDate != null && endDate != null) {
                        sa.Start_Date__c = DateTime.newInstance(startDate, Time.newInstance(9, 0, 0, 0));
                        sa.End_Date__c = DateTime.newInstance(endDate, Time.newInstance(18, 0, 0, 0));
                    } else {
                        sa.Start_Date__c = System.now();
                        sa.End_Date__c = System.now().addHours(1);
                    }

                    serviceAppointments.add(sa);
                }

                insert serviceAppointments;
                System.debug('Created ' + serviceAppointments.size() + ' Service Appointments');

            } catch (DmlException e) {
                System.debug('DMLException: ' + e.getMessage());
                for (Integer i = 0; i < e.getNumDml(); i++) {
                    System.debug('DML Error: ' + e.getDmlMessage(i));
                }
            }
        } else {
            System.debug('No WorkOrders to insert — all records failed condition checks.');
        }

        if (!skippedLabels.isEmpty()) {
            System.debug('Skipped Activity_Type__c labels that didn’t match WorkTypes: ' + skippedLabels);
        }
    }
}