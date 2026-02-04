public class AS_PaymentNotificationService {

    public static void processNotifications(List<Payment__c> newList) {
        
        system.debug('========newList=======>'+newList);

        if (newList == null || newList.isEmpty()) return;

        // === 1) Preload Payments with related WorkOrder info ===
        Map<Id, Payment__c> payMap = new Map<Id, Payment__c>(newList);
        
        system.debug('========payMap=======>'+payMap);

        // === 2) Load Metadata (Template for "Payment Confirmation") ===
        Map<String, Go_Collect_Follow_Up__mdt> allMdtMap = Go_Collect_Follow_Up__mdt.getAll();
        String templateId;
        for (Go_Collect_Follow_Up__mdt m : allMdtMap.values()) {
            if (m.Label == 'Payment Confirmation' && !String.isBlank(m.Template_Id__c)) {
                templateId = m.Template_Id__c;
                break;
            }
        }

        if (String.isBlank(templateId)) {
            System.debug('PaymentNotificationService: No Payment Confirmation template found.');
            return;
        }
        
        system.debug('========templateId=======>'+templateId);

        // === 3) Load SMS Template by Template_Id__c ===
        Case_Type_SMS__c smsTemplate;
        List<Case_Type_SMS__c> tmplList = [
            SELECT Template_Id__c, Message__c
            FROM Case_Type_SMS__c
            WHERE Template_Id__c = :templateId
            LIMIT 1
        ];
        if (!tmplList.isEmpty()) smsTemplate = tmplList[0];

        if (smsTemplate == null) {
            System.debug('PaymentNotificationService: SMS Template missing for TemplateId = ' + templateId);
            return;
        }
        
        system.debug('========smsTemplate=======>'+smsTemplate);

        // === 4) Prepare Wrappers ===
        List<WorkOrderNotificationWrapper> wrapperList = new List<WorkOrderNotificationWrapper>();

        for (Payment__c payPartial : newList) {
            Payment__c pay = payMap.get(payPartial.Id);
            if (pay == null) continue;

            if (pay.Work_Order__r == null || pay.Work_Order__r.RecordType.DeveloperName != 'MGL_R_T') continue;
            if (pay.Cheque_Amount__c == null) continue;

            WorkOrderNotificationWrapper wrap = new WorkOrderNotificationWrapper();
            wrap.pay = pay;
            wrap.tmpl = smsTemplate;
            wrap.templateId = templateId;
            wrap.followUpRemarksOpt = null;
            wrapperList.add(wrap);
        }
        
        system.debug('========wrapperList=======>'+wrapperList);

        if (wrapperList.isEmpty()) {
            System.debug('PaymentNotificationService: No payments qualified for SMS.');
            return;
        }

        // === 5) Trigger Batch to send SMS ===
        if (!(System.isBatch() || System.isFuture())) {
            Database.executeBatch(new AS_PaymentSMSBatch(wrapperList), 200);
        }
    }

    // === Wrapper ===
    public class WorkOrderNotificationWrapper {
        public Payment__c pay;
        public Case_Type_SMS__c tmpl;
        public String templateId;
        public String followUpRemarksOpt;
    }
}