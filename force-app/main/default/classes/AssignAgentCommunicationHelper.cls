/**
 * @description       : Sends SMS to customer when agent is assigned and SA is dispatched
 * @author            :
 * @last modified on  : 2025-06-04
 */
public without sharing class AssignAgentCommunicationHelper {


    private static final String PHOTO_LINK =
    'https://m.mahanagargas.com/PNG/vs.aspx?this=hariram';

    private static final String RATE_CARD_LINK =
    'https://www.mahanagargas.com/residential-png/policies-and-procedures/aftersales-services/png-service-charges';


    /* ==========================================================
       Trigger Entry
       ========================================================== */
    public static void afterUpdate(List<WorkOrder> newList,
                                   Map<Id, WorkOrder> oldMap) {

        Set<Id> candidateWOIds = new Set<Id>();

        /* ------------------ Record Type ------------------ */
        Id rtId = Schema.SObjectType.WorkOrder
            .getRecordTypeInfosByName()
            .get('MGL O&M')
            .getRecordTypeId();

        /* ------------------ Work Type ------------------ */
        // WorkType wt = [
        //     SELECT Id
        //     FROM WorkType
        //     WHERE Name = 'After Sales Service'
        //     LIMIT 1
        // ];

        /* ------------------ WO Level Filters ------------------ */
        for (WorkOrder wo : newList) {

            // Record Type check
            if (wo.RecordTypeId != rtId) {
                continue;
            }

           // Work Type check
            // if (wo.WorkTypeId != wt.Id) {
            //     continue;
            // }

            // Agent must be assigned
            if (wo.Agent__c == null) {
                continue;
            }

            candidateWOIds.add(wo.Id);
        }

        if (candidateWOIds.isEmpty()) {
            return;
        }

        /* ------------------ Service Appointment Check ------------------ */
        Set<Id> eligibleWOIds = new Set<Id>();

        for (ServiceAppointment sa : [
            SELECT ParentRecordId
            FROM ServiceAppointment
            WHERE ParentRecordId IN :candidateWOIds
            AND Status = 'Dispatched'
            AND SchedStartTime != null
            AND SchedEndTime != null
        ]) {
            eligibleWOIds.add(sa.ParentRecordId);
        }

        /* ------------------ Trigger Async SMS ------------------ */
        if (!eligibleWOIds.isEmpty()) {
            sendAssignmentSMS_Future(eligibleWOIds);
        }
    }

    /* ==========================================================
       Async Wrapper
       ========================================================== */
    @future(callout=true)
    public static void sendAssignmentSMS_Future(Set<Id> workOrderIds) {
        executeSendAssignmentSMS(workOrderIds);
    }

    /* ==========================================================
       Core Logic
       ========================================================== */
    private static void executeSendAssignmentSMS(Set<Id> workOrderIds) {

        if (workOrderIds == null || workOrderIds.isEmpty()) return;

        List<IntegrationLogHelper.IntegrationLogWrapper> logs =
            new List<IntegrationLogHelper.IntegrationLogWrapper>();

        /* ------------------ Fetch SMS Config ------------------ */
        Bulk_SMS_Config__mdt cfg = [
            SELECT Api_Key__c, Channel__c, Default_Number__c, For__c, Endpoint__c,
                   Sender__c, Send_to_Default_Number__c, Version__c, Mode__c
            FROM Bulk_SMS_Config__mdt
            WHERE Is_Active__c = true AND For__c = 'Metering'
            LIMIT 1
        ];

        /* ------------------ Fetch SMS Template ------------------ */
//        Case_Type_SMS__c smsTemplate = [
//     SELECT Message__c, Template_Id__c
//     FROM Case_Type_SMS__c
//     WHERE Active__c = true
//     AND Template_Name__c = 'Aftersales Assignment'
//     LIMIT 1
// ];

Case_Type_SMS__c smsTemplate = [
            SELECT Message__c, Template_Id__c
            FROM Case_Type_SMS__c
            WHERE Active__c = true
            LIMIT 1
        ];


        /* ------------------ Fetch WorkOrders ------------------ */
        List<WorkOrder> woList = [
            SELECT Id,
                   Agent__r.Name,
                   AccountId,
                   Account.Phone,
                   CaseId,
           Case.Sub_Type__c
            FROM WorkOrder
            WHERE Id IN :workOrderIds
        ];

        /* ------------------ Fetch Service Appointments ------------------ */
        Map<Id, ServiceAppointment> mapWOToSA =
            new Map<Id, ServiceAppointment>();

        for (ServiceAppointment sa : [
            SELECT Id, ParentRecordId, Status,
                   SchedStartTime, SchedEndTime
            FROM ServiceAppointment
            WHERE ParentRecordId IN :workOrderIds
            AND Status = 'Dispatched'
            AND SchedStartTime != null
            AND SchedEndTime != null
        ]) {
            mapWOToSA.put(sa.ParentRecordId, sa);
        }

        /* ------------------ SMS Body Init ------------------ */
        SmsApiHelper.SMSBodyWrapper smsBody =
            new SmsApiHelper.SMSBodyWrapper();

        smsBody.authentication = new SmsApiHelper.Authentication();
        smsBody.authentication.key = cfg.Api_Key__c;
        smsBody.authentication.version = cfg.Version__c;
        smsBody.authentication.channel = cfg.Channel__c;

        smsBody.message = new SmsApiHelper.Message();
        smsBody.message.smsdata = new List<SmsApiHelper.Smsdata>();

        /* ======================================================
           Build SMS per WorkOrder
           ====================================================== */
        for (WorkOrder wo : woList) {

            if (!mapWOToSA.containsKey(wo.Id)) continue;

            if (String.isBlank(wo.Account.Phone)) {
                addErrorLog('Customer phone missing', wo.Id, logs);
                continue;
            }

            ServiceAppointment sa = mapWOToSA.get(wo.Id);

            String msg = smsTemplate.Message__c;

            msg = msg.replace('{AgentName}',
                wo.Agent__r != null ? wo.Agent__r.Name : '');

            msg = msg.replace('{SchedStartTime}',
                formatDateTime(sa.SchedStartTime));

            msg = msg.replace('{SchedEndTime}',
                formatDateTime(sa.SchedEndTime));


            // Sub Type from Case
            msg = msg.replace('{SubType}',
            (wo.CaseId != null && wo.Case.Sub_Type__c != null)
            ? wo.Case.Sub_Type__c
            : 'service');

             // Fixed Links
            msg = msg.replace('{Photolink}', PHOTO_LINK);
            msg = msg.replace('{Ratecard}', RATE_CARD_LINK);  
            msg = msg.replace ('{Blank}',' ' );  

            SmsApiHelper.Smsdata sd = new SmsApiHelper.Smsdata();
            sd.destination = wo.Account.Phone; //? cfg.Send_to_Default_Number__c : cfg.Default_Number__c;
            sd.source = cfg.Sender__c;
            sd.type = 'TEXT';
            sd.content = msg;
            sd.tempId = smsTemplate.Template_Id__c;

            smsBody.message.smsdata.add(sd);
        }

        /* ------------------ Send SMS ------------------ */
        if (!smsBody.message.smsdata.isEmpty()) {
            SmsApiHelper.listIntegrationLogWrap =
                new List<IntegrationLogHelper.IntegrationLogWrapper>();

            SmsApiHelper.sendBulkSMS(smsBody, cfg);
            logs.addAll(SmsApiHelper.listIntegrationLogWrap);
        }

        if (!logs.isEmpty()) {
            IntegrationLogHelper.createListIntegrationLog(logs);
        }
    }

    /* ==========================================================
       Utilities
       ========================================================== */
    private static void addErrorLog(String message, Id woId,
                                   List<IntegrationLogHelper.IntegrationLogWrapper> logs) {

        IntegrationLogHelper.IntegrationLogWrapper log =
            new IntegrationLogHelper.IntegrationLogWrapper();

        log.className = 'AssignAgentCommunicationHelper';
        log.methodName = 'executeSendAssignmentSMS';
        log.message = message;
        log.status = 'Failed';
        log.workOrderId = woId;

        logs.add(log);
    }

    private static String formatDateTime(DateTime dt) {
        return dt.format('dd-MM-yyyy hh:mm a');
    }
}