/**
* @File Name       : WorkOrderNotificationService.cls
* @Description     : Centralized notifications for WorkOrders (create/update + follow-up).
* @Last Modified On: September 6, 2025
*/
public class WorkOrderNotificationService {
 
    public static void processNotifications(List<WorkOrder> newList, Map<Id, WorkOrder> oldMap) {
        if (newList == null || newList.isEmpty()) {
            System.debug('No WorkOrders to process.');
            return;
        }
 
        // === 1) Preload WorkOrders ===
        Map<Id, WorkOrder> woMap = new Map<Id, WorkOrder>([
            SELECT Id, WorkOrderNumber, Record_Type_Developer_Name__c,
                   AccountId, Account.CA_Number__c, Account.Phone, Account.Preferance__c,R_T_Agency__c,
                   Agent__c,Agent__r.Name, R_T_Agency__r.Name, Agency_Name_Formula__c,
                   Amount_Received__c, Transaction_Id__c, Payment_Mode__c,
                   StartDate, EndDate, Status, Due_Amount__c,New_Mobile_Number__c,
                   Customer_CA_Number__c, Remarks__c, Follow_up_Remarks__c, TodayDate__c,
                   Start_Date_Formula__c,End_Date__c, New_Remark__c, Receipt_No__c
            FROM WorkOrder
            WHERE Id IN :newList
        ]);
 
        // === 2) Load all metadata (includes Create, Update, Follow-ups) ===
        Map<String, Go_Collect_Follow_Up__mdt> allMdtMap = Go_Collect_Follow_Up__mdt.getAll();
        Map<String, Go_Collect_Follow_Up__mdt> mdtMap = new Map<String, Go_Collect_Follow_Up__mdt>();
        
        for(String key : allMdtMap.keySet()){
            mdtMap.put(allMdtMap.get(key).label, allMdtMap.get(key));
        }
 
        // Resolve Create & Update templates from metadata
        String createTemplateId = (mdtMap.containsKey('WorkOrder Allocation')) ? mdtMap.get('WorkOrder Allocation').Template_Id__c : null;
        String updateTemplateId = (mdtMap.containsKey('Payment Confirmation')) ? mdtMap.get('Payment Confirmation').Template_Id__c : null;
 
        // === 3) Collect all needed template IDs in advance ===
        Set<String> neededTemplateIds = new Set<String>();
        if (!String.isBlank(createTemplateId)) neededTemplateIds.add(createTemplateId);
        if (!String.isBlank(updateTemplateId)) neededTemplateIds.add(updateTemplateId);
 
        for (WorkOrder wo : woMap.values()) {
            if (!String.isBlank(wo.New_Remark__c)) {
                Go_Collect_Follow_Up__mdt remarkMdt = mdtMap.get(wo.New_Remark__c);
                if (remarkMdt != null && !String.isBlank(remarkMdt.Template_Id__c)) {
                    neededTemplateIds.add(remarkMdt.Template_Id__c);
                }
            }
        }
 
        // === 4) Preload all Case_Type_SMS__c messages ===
        Map<String, Case_Type_SMS__c> templatesById = new Map<String, Case_Type_SMS__c>();
        if (!neededTemplateIds.isEmpty()) {
            for (Case_Type_SMS__c t : [
                SELECT Template_Id__c, Message__c
                FROM Case_Type_SMS__c
                WHERE Template_Id__c IN :neededTemplateIds
            ]) {
                templatesById.put(t.Template_Id__c, t);
            }
        }
        
        List<WorkOrderNotificationWrapper> notificationWrapperList = new List<WorkOrderNotificationWrapper>();
        // === 5) Process each WorkOrder ===
        for (WorkOrder partial : newList) {
            WorkOrder wo = woMap.get(partial.Id);
            if (wo == null) continue;
 
            if (wo.Record_Type_Developer_Name__c != 'MGL_R_T') continue;
            if (wo.AccountId == null) continue;
            if (wo.Due_Amount__c == null || wo.Due_Amount__c <= 0) continue;
 
            // --- INSERT ---
            if (oldMap == null && !String.isBlank(createTemplateId)) {
                WorkOrderNotificationWrapper wrap = new WorkOrderNotificationWrapper();
                wrap.wo = wo;
                wrap.tmpl = templatesById.get(createTemplateId);
                wrap.templateId = createTemplateId;
                wrap.followUpRemarksOpt = null;
                notificationWrapperList.add(wrap);
            }
            // --- UPDATE ---
            else {
                WorkOrder oldWO = oldMap.containsKey(wo.Id) ? oldMap.get(wo.Id) : new WorkOrder();
                if (oldWO == null) continue;
 
                Boolean amountChanged = wo.Amount_Received__c != oldWO.Amount_Received__c;
                Boolean txnChanged    = wo.Transaction_Id__c   != oldWO.Transaction_Id__c;
                Boolean validPayment  = (wo.Payment_Mode__c == 'M-POS' || wo.Payment_Mode__c == 'QR Code');
                //|| wo.Payment_Mode__c == 'Cheque'
 
                if ((amountChanged || txnChanged) && validPayment && !String.isBlank(updateTemplateId)) {
                    WorkOrderNotificationWrapper wrap = new WorkOrderNotificationWrapper();
                    wrap.wo = wo;
                    wrap.tmpl = templatesById.get(updateTemplateId);
                    wrap.templateId = updateTemplateId;
                    wrap.followUpRemarksOpt = null;
                    notificationWrapperList.add(wrap);
                }

                // Agent/Agency change check 
                Boolean agentChanged  = wo.Agent__c != oldWO.Agent__c && wo.Agent__c != null;
                Boolean agencyChanged = wo.R_T_Agency__c != oldWO.R_T_Agency__c && wo.R_T_Agency__c != null;

                if ((agentChanged || agencyChanged) && !String.isBlank(createTemplateId)) {
                    WorkOrderNotificationWrapper wrap = new WorkOrderNotificationWrapper();
                    wrap.wo = wo;
                    wrap.tmpl = templatesById.get(createTemplateId);
                    wrap.templateId = createTemplateId;
                    wrap.followUpRemarksOpt = null;
                    notificationWrapperList.add(wrap);
                }
 
                // Follow-up check
                if (wo.New_Remark__c != oldWO.New_Remark__c) {
                    WorkOrderNotificationWrapper wrap = sendFollowUpNotification(wo, wo.New_Remark__c, mdtMap, templatesById);
                    if (wrap != null) {
                        notificationWrapperList.add(wrap);
                    }
                }
            }
        }
        
        // === 6) Call Batch instead of inline callout ===
        // if (!notificationWrapperList.isEmpty() && !(System.isBatch() || System.isFuture())) {
        //     Database.executeBatch(new WorkOrderSMSBatch(notificationWrapperList), 200);
        // }
         if (!notificationWrapperList.isEmpty() && !(System.isBatch() || System.isFuture())) {
            System.debug('notificationWrapperList size = ' + notificationWrapperList.size());
            Integer holdingJobsCountbefore = [
                SELECT COUNT() 
                FROM AsyncApexJob 
                WHERE JobType = 'BatchApex' AND Status = 'Holding'
            ];
            System.debug('Current jobs in Flex Queue (Holding status): Before ' + holdingJobsCountbefore);
            
            System.debug('Heap used before: ' + Limits.getHeapSize());
            System.debug('Heap limit: ' + Limits.getLimitHeapSize());

            System.debug('CPU time used before: ' + Limits.getCpuTime());
            System.debug('CPU time limit: ' + Limits.getLimitCpuTime());

            System.debug('Callouts limit before: ' + Limits.getLimitCallouts());

            
            Database.executeBatch(new WorkOrderSMSBatch(notificationWrapperList), 200);
            Integer holdingJobsCountafter = [
                SELECT COUNT() 
                FROM AsyncApexJob 
                WHERE JobType = 'BatchApex' AND Status = 'Holding'
            ];
            System.debug('Current jobs in Flex Queue (Holding status): After ' + holdingJobsCountafter);

            System.debug('getHeapSize after: '+Limits.getHeapSize());
            System.debug('getLimitHeapSize after: '+ Limits.getLimitHeapSize());
            System.debug('getCpuTime after: '+ Limits.getCpuTime());
            System.debug('getLimitCpuTime after: '+ Limits.getLimitCpuTime());
            System.debug('getLimitCallouts after: '+ Limits.getLimitCallouts());
        }
    }
    
    public static WorkOrderNotificationWrapper sendFollowUpNotification(
        WorkOrder wo,
        String followUpRemarks,
        Map<String, Go_Collect_Follow_Up__mdt> mdtMap,
        Map<String, Case_Type_SMS__c> templatesById
    ) {
        if (String.isBlank(followUpRemarks)) return null;
 
        Go_Collect_Follow_Up__mdt mdt = mdtMap.get(followUpRemarks);
        if (mdt == null) {
            // fallback to case-insensitive label
            String keyLower = followUpRemarks.trim().toLowerCase();
            for (Go_Collect_Follow_Up__mdt r : mdtMap.values()) {
                if (r.Label != null && r.Label.trim().toLowerCase() == keyLower) {
                    mdt = r; break;
                }
            }
        }
        if (mdt == null || !mdt.SMS_requried__c || String.isBlank(mdt.Template_Id__c)) return null;
        
        WorkOrderNotificationWrapper wrap = new WorkOrderNotificationWrapper();
        wrap.wo = wo;
        wrap.tmpl = templatesById.get(mdt.Template_Id__c);
        wrap.templateId = mdt.Template_Id__c;
        wrap.followUpRemarksOpt = followUpRemarks;
        return wrap;
    }
    
 
    public class WorkOrderNotificationWrapper {
        public WorkOrder wo;
        public Case_Type_SMS__c tmpl;
        public String templateId;
        public String followUpRemarksOpt;
    }
}