public class WorkOrderTriggerHandlerAgent {
    public static void handleTechnicianAssignment(List<WorkOrder> workOrders, Map<Id, WorkOrder> oldMap) {
        Set<Id> agentIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        Set<Id> workTypeIds = new Set<Id>();

        Map<Id, WorkOrder> notifyWOMap = new Map<Id, WorkOrder>();

        for (WorkOrder wo : workOrders) {
            if (wo.Agent__c != null) {
                WorkOrder oldWO = (oldMap != null) ? oldMap.get(wo.Id) : null;

                // Send SMS only if agent was newly assigned or changed
                if (oldWO == null || wo.Agent__c != oldWO.Agent__c) {
                    agentIds.add(wo.Agent__c);
                    if (wo.AccountId != null) {
                        accountIds.add(wo.AccountId);
                        notifyWOMap.put(wo.Id, wo);
                    }
                    if (wo.WorkTypeId != null) {
                        workTypeIds.add(wo.WorkTypeId);
                    }
                }
            }
        }

        if (agentIds.isEmpty() || accountIds.isEmpty()) return;

        // Fetch Agents
        Map<Id, User> agentMap = new Map<Id, User>(
            [SELECT Id, Name FROM User WHERE Id IN :agentIds]
        );

        // Fetch Customer Accounts
        Map<Id, Account> accountMap = new Map<Id, Account>(
            [SELECT Id, Name, Phone__c FROM Account WHERE Id IN :accountIds]
        );

        // Fetch Work Types
        Map<Id, WorkType> workTypeMap = new Map<Id, WorkType>();
        if (!workTypeIds.isEmpty()) {
            workTypeMap = new Map<Id, WorkType>(
                [SELECT Id, Name FROM WorkType WHERE Id IN :workTypeIds]
            );
        }

        for (WorkOrder wo : notifyWOMap.values()) {
            User agent = agentMap.get(wo.Agent__c);
            Account acc = accountMap.get(wo.AccountId);
            WorkType wt = workTypeMap.get(wo.WorkTypeId);

            if (agent == null || acc == null || String.isBlank(acc.Phone__c)) {
                continue;
            }

            // Message with merge fields
            String message = 'Dear {!CustomerName}, Mr. {!TechnicianName} will visit your house between - to - to carry out the {!WorkType} requested by you.';

            // Send SMS
            SmsApiCallout.sendSmsFuture(
                acc.Phone__c,
                message,
                (wo.CaseId != null ? String.valueOf(wo.CaseId) : ''),
                new Map<String, String>{
                    'TechnicianName' => agent.Name,
                    'CustomerName'   => acc.Name,
                    'WorkType'       => (wt != null ? wt.Name : 'requested work')
                },
                'TEMPLATE_ID_HERE',
                'MGLCRM'// Replace with actual SMS template ID
            );
        }
    }
}