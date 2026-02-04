/**
         * @description       : Metering Communication Helper
         * @author            : Kartik Patkar
         * @last modified on  : 30-01-2026
         */
        public without sharing class MeteringCommunicationHelper {
            
            /* ------------------------------------------
            MODE ENGINE: Determines SMS / WhatsApp
                ------------------------------------------ */
            public static Map<String, Boolean> getCommunicationMode(String configMode, String customerPref) {
                
                Map<String, Boolean> out = new Map<String, Boolean>{
                    'sendSMS' => false,
                    'sendWhatsApp' => false
                };
                
                configMode = (configMode == null) ? 'Preference' : configMode;
                
                switch on configMode {
                    
                    when 'SMS' {
                        out.put('sendSMS', true);
                    }
                    
                    when 'WhatsApp' {
                        out.put('sendWhatsApp', true);
                    }
                    
                    when 'Preference' {
                        if (customerPref == 'Whatsapp')
                            out.put('sendWhatsApp', true);
                        else
                            out.put('sendSMS', true);
                    }
                    
                    when 'Both' {
                        out.put('sendSMS', true);
                        out.put('sendWhatsApp', true);
                    }
                    
                    when else {
                        // default = Preference
                        if (customerPref == 'Whatsapp')
                            out.put('sendWhatsApp', true);
                        else
                            out.put('sendSMS', true);
                    }
                }
                
                return out;
            }
            
            /* ------------------------------------------
            Shared Helper: Log creation
                ------------------------------------------ */
            private static void addErrorLog(String message, Id woId, List<IntegrationLogHelper.IntegrationLogWrapper> logs) {
                IntegrationLogHelper.IntegrationLogWrapper log = new IntegrationLogHelper.IntegrationLogWrapper();
                log.className = 'MeteringCommunicationHelper';
                log.methodName = 'sendWorkOrderSMS';
                log.message = message;
                log.status = 'Failed';
                log.workOrderId = woId;
                logs.add(log);
            }
            
            /* ------------------------------------------
            Trigger Handler: WorkOrder After Update
                ------------------------------------------ */
            public static void afterUpdate(List<WorkOrder> newList, Map<Id, WorkOrder> oldMap) {
                
                Set<Id> sendIds = new Set<Id>();
                String rtId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName()
                    .get('MGL_Metering').getRecordTypeId();
                
                for (WorkOrder wo : newList) {
                    
                    if (
                        wo.RecordTypeId == rtId &&
                        wo.Customer_Category__c == 'Domestic' &&
                        (wo.Appointment_Status__c == 'Completed' || wo.Appointment_Status__c == 'Incomplete') &&
                        (oldMap == null || oldMap.get(wo.Id).Appointment_Status__c != wo.Appointment_Status__c)
                    ) {
                        sendIds.add(wo.Id);
                    }
                }
                
                if (!sendIds.isEmpty())
                    sendWorkOrderSMS_Future(sendIds);
            }
            
            /* ------------------------------------------
            Trigger Handler: Meter Reading Schedule
                ------------------------------------------ */
                public static void afterInsertUpdateMRS(List<Meter_Reading_Schedule__c> newList,
            Map<Id, Meter_Reading_Schedule__c> oldMap) {
                
                Set<Id> mrsIds = new Set<Id>();
                
                for (Meter_Reading_Schedule__c m : newList) {
                    if (m.Status__c == 'Approved' &&
                    (oldMap == null || oldMap.get(m.Id).Status__c != m.Status__c)) {
                        
                        mrsIds.add(m.Id);
                    }
                }
                
                System.debug('MRS IDs for SMS: ' + mrsIds);
                if (!mrsIds.isEmpty()) {
                    
                    Set<Id> woIds = new Set<Id>();
                    
                    for (WorkOrder wo : [
                SELECT Id FROM WorkOrder
                WHERE Meter_Reading_Schedule__c IN :mrsIds
                AND Appointment_Status__c='Unattempted'
                AND Customer_Category__c='Domestic'
            ]) {
                        woIds.add(wo.Id);
                    }
                    
                    if (!woIds.isEmpty()) {
                        System.enqueueJob(new MeteringSendSMSQueueable(woIds));
                        // sendMRSApprovalSMS_Future(woIds);
                    }
                }
            }
            
            // Future method for MRS Approval SMS
            @future(callout=true)
            public static void sendMRSApprovalSMS_Future(Set<Id> workOrderIds) {
                executeSendMRSApprovalSMS(workOrderIds);
            }
            
            /* ------------------------------------------
            MAIN: Send SMS/WhatsApp for MRS Approval
                Uses 'Visit Notification' template
                ------------------------------------------ */
            public static void executeSendMRSApprovalSMS(Set<Id> workOrderIds) {
                
                if (workOrderIds == null || workOrderIds.isEmpty()) return;
                
                List<IntegrationLogHelper.IntegrationLogWrapper> logs = new List<IntegrationLogHelper.IntegrationLogWrapper>();
                
                /* Fetch Config */
                List<Bulk_SMS_Config__mdt> config = [
            SELECT Api_Key__c, Channel__c, Default_Number__c, For__c, Endpoint__c,
                   Sender__c, Send_to_Default_Number__c, Version__c, Mode__c
            FROM Bulk_SMS_Config__mdt
            WHERE Is_Active__c = true AND For__c='Metering'
            LIMIT 1
        ];
                
                if (config.isEmpty()) {
                    return;
                }
                
                Bulk_SMS_Config__mdt cfg = config[0];
                
                /* Merge Field Mapping */
                Map<String, Message_Template_Field_Mapping_Config__mdt> mergeFields =
                    new Map<String, Message_Template_Field_Mapping_Config__mdt>();
                
                List<Message_Template_Field_Mapping_Config__mdt> mergeFieldsWhatsApp =
                    new List<Message_Template_Field_Mapping_Config__mdt>();
                
                List<String> fieldList = new List<String>{
                    'Customer_Category__c','Id','Customer_Contact_Number__c',
                    'AccountId','Account.preferance__c'
                };
                
                for (Message_Template_Field_Mapping_Config__mdt mf :
                [SELECT Placeholder__c, Field_API_Name__c, Value__c, Type__c,WhatsApp__c,Order__c
             FROM Message_Template_Field_Mapping_Config__mdt
             WHERE Active__c = true AND Object_API_Name__c='WorkOrder' ORDER BY Order__c ASC]) {
                    
                    mergeFields.put(mf.Placeholder__c, mf);
                    if(mf.WhatsApp__c == true){
                        mergeFieldsWhatsApp.add(mf);
                    }
                    if (String.isNotBlank(mf.Field_API_Name__c))
                        fieldList.add(mf.Field_API_Name__c);
                }
                
                /* Query WorkOrders */
                String soql = 'SELECT ' + String.join(fieldList, ',') +
                    ' FROM WorkOrder WHERE Id IN :workOrderIds';
                
                List<WorkOrder> woList = Database.query(soql);
                
                /* Get Visit Notification Template */
                List<Case_Type_SMS__c> mapTemplate = [
            SELECT Id, Template_Name__c, Template_Id__c, Message__c, Whatsapp_Template_Name__c
            FROM Case_Type_SMS__c
            WHERE Template_Name__c='Visit Notification' AND Active__c = true
            LIMIT 1
        ];
                
                if (mapTemplate.isEmpty()) {
                    IntegrationLogHelper.IntegrationLogWrapper log = new IntegrationLogHelper.IntegrationLogWrapper();
                    log.className = 'MeteringCommunicationHelper';
                    log.methodName = 'executeSendMRSApprovalSMS';
                    log.message = 'Visit Notification SMS Template not found.';
                    log.status = 'Failed';
                    logs.add(log);
                    IntegrationLogHelper.createListIntegrationLog(logs);
                    return;
                }
                
                Case_Type_SMS__c tmpl = mapTemplate[0];
                
                /* Init SMS Body */
                SmsApiHelper.SMSBodyWrapper smsBody = new SmsApiHelper.SMSBodyWrapper();
                smsBody.authentication = new SmsApiHelper.Authentication();
                smsBody.authentication.key = cfg.Api_Key__c;
                smsBody.authentication.version = cfg.Version__c;
                smsBody.authentication.channel = cfg.Channel__c;
                smsBody.message = new SmsApiHelper.Message();
                smsBody.message.smsdata = new List<SmsApiHelper.Smsdata>();
                
                List<Notification__c> notifyInsert = new List<Notification__c>();
                
                /* Process each WorkOrder */
                for (WorkOrder wo : woList) {
                    
                    Map<String, Boolean> mode =
                        getCommunicationMode(cfg.Mode__c, wo.Account.preferance__c);
                    
                    /* Determine phone numbers */
                    String smsPhone = cfg.Send_to_Default_Number__c ? cfg.Default_Number__c : wo.Customer_Contact_Number__c;
                    String waPhone = cfg.Send_to_Default_Number__c ? cfg.Default_Number__c : wo.Customer_Contact_Number__c;
                    
                    /* Validate phone number if not using default */
                    if (!cfg.Send_to_Default_Number__c && String.isBlank(wo.Customer_Contact_Number__c)) {
                        addErrorLog('Customer contact number is not available.', wo.Id, logs);
                        continue;
                    }
                    
                    /* --------------------- WHATSAPP ------------------------ */
                    if (mode.get('sendWhatsApp')) {
                        
                        if (tmpl.Whatsapp_Template_Name__c == null) {
                            addErrorLog('WhatsApp template missing', wo.Id, logs);
                        } else {
                            String comp = buildMergeFieldJsonMRS(tmpl.Message__c, wo, mergeFieldsWhatsApp);
                            
                            notifyInsert.add(new Notification__c(
                                Work_Order__c = wo.Id,
                            Type__c = 'WhatsApp',
                            Sent_Timestamp__c = System.now(),
                            Status__c = 'Pending',
                            Phone_Number__c = waPhone,
                            Business_Partner__c = wo.AccountId,
                            Template_Name__c = tmpl.Whatsapp_Template_Name__c,
                            Dynamic_Components__c = comp
                                ));
                        }
                    }
                    
                    /* ---------------------- SMS --------------------------- */
                    if (mode.get('sendSMS')) {
                        
                        if (String.isBlank(tmpl.Message__c)) {
                            addErrorLog('SMS content missing', wo.Id, logs);
                        } else {
                            
                            String msg = tmpl.Message__c;
                            
                            for (String key : mergeFields.keySet()) {
                                Message_Template_Field_Mapping_Config__mdt f = mergeFields.get(key);
                            String ph = '{!' + key + '}';
                            String val;
                            
                            if (f.Type__c == 'Field') {
                                val = String.valueOf(wo.get(f.Field_API_Name__c));
                            } else {
                                val = f.Value__c;
                            }
                            
                            msg = msg.replace(ph, val == null ? '' : val);
                        }
                        
                        SmsApiHelper.Smsdata sd = new SmsApiHelper.Smsdata();
                        sd.destination = smsPhone;
                        sd.source = cfg.Sender__c;
                        sd.type = 'TEXT';
                        sd.content = msg;
                        sd.tempId = tmpl.Template_Id__c;
                        
                        smsBody.message.smsdata.add(sd);
                    }
                }
            }
            
            /* Send SMS */
            if (!smsBody.message.smsdata.isEmpty()) {
                SmsApiHelper.listIntegrationLogWrap = new List<IntegrationLogHelper.IntegrationLogWrapper>();
                SmsApiHelper.sendBulkSMS(smsBody, cfg);
                logs.addAll(SmsApiHelper.listIntegrationLogWrap);
            }
            
            /* Send WhatsApp (sync) */
            if (!notifyInsert.isEmpty()) {
                WhatsappAPIHelper.sendNotificationSync(notifyInsert);
            }
            
            /* Insert Logs */
            if (!logs.isEmpty()) {
                IntegrationLogHelper.createListIntegrationLog(logs);
            }
        }
        
        // Wrapper method (NOT future)
        public static void sendWorkOrderSMS_Async(Set<Id> workOrderIds) {
            sendWorkOrderSMS_Future(workOrderIds);
        }
        
        // Actual logic - FUTURE
        @future(callout=true)
        public static void sendWorkOrderSMS_Future(Set<Id> workOrderIds) {
            executeSendWorkOrderSMS(workOrderIds);
        }
        
        /* ------------------------------------------
        MAIN: Send SMS/WhatsApp after Completion
            ------------------------------------------ */
        public static void executeSendWorkOrderSMS(Set<Id> workOrderIds) {
            
            if (workOrderIds == null || workOrderIds.isEmpty()) return;
            
            List<IntegrationLogHelper.IntegrationLogWrapper> logs = new List<IntegrationLogHelper.IntegrationLogWrapper>();
            
            /* Fetch Config */
            Bulk_SMS_Config__mdt cfg = [
            SELECT Api_Key__c, Channel__c, Default_Number__c, For__c, Endpoint__c,
                   Sender__c, Send_to_Default_Number__c, Version__c, Mode__c
            FROM Bulk_SMS_Config__mdt
            WHERE Is_Active__c = true AND For__c='Metering'
            LIMIT 1
        ];
            
            /* Merge Field Mapping */
            Map<String, Message_Template_Field_Mapping_Config__mdt> mergeFields =
                new Map<String, Message_Template_Field_Mapping_Config__mdt>();
            
            List<String> fieldList = new List<String>{
                'Customer_Category__c','Id','Group_Code__c','Customer_Contact_Number__c',
                'AccountId','Account.preferance__c'
            };
            
            for (Message_Template_Field_Mapping_Config__mdt mf :
            [SELECT Placeholder__c, Field_API_Name__c, Value__c, Type__c
             FROM Message_Template_Field_Mapping_Config__mdt
             WHERE Active__c = true AND Object_API_Name__c='WorkOrder']) {
                
                mergeFields.put(mf.Placeholder__c, mf);
                if (String.isNotBlank(mf.Field_API_Name__c))
                    fieldList.add(mf.Field_API_Name__c);
            }
            
            /* Query WorkOrders */
            String soql = 'SELECT ' + String.join(fieldList, ',') +
                ' FROM WorkOrder WHERE Id IN :workOrderIds';
            
            List<WorkOrder> woList = Database.query(soql);
            
            /* Group Code → Template map */
            Set<Id> gcIds = new Set<Id>();
            for (WorkOrder wo : woList) if (wo.Group_Code__c != null) gcIds.add(wo.Group_Code__c);
            
            Map<Id, Group_Code__c> mapGC = new Map<Id, Group_Code__c>(
                [SELECT Id, SMS_Template__c FROM Group_Code__c WHERE Id IN :gcIds]
                );
            
            Set<Id> templateIds = new Set<Id>();
            for (Group_Code__c gc : mapGC.values()) templateIds.add(gc.SMS_Template__c);
            
            Map<Id, Case_Type_SMS__c> mapTemplate = new Map<Id, Case_Type_SMS__c>(
                [SELECT Id, Template_Name__c, Template_Id__c, Message__c, Whatsapp_Template_Name__c
             FROM Case_Type_SMS__c
             WHERE Id IN :templateIds AND Active__c = true]
                );
            
            /* Init SMS Body */
            SmsApiHelper.SMSBodyWrapper smsBody = new SmsApiHelper.SMSBodyWrapper();
            smsBody.authentication = new SmsApiHelper.Authentication();
            smsBody.authentication.key = cfg.Api_Key__c;
            smsBody.authentication.version = cfg.Version__c;
            smsBody.authentication.channel = cfg.Channel__c;
            smsBody.message = new SmsApiHelper.Message();
            smsBody.message.smsdata = new List<SmsApiHelper.Smsdata>();
            
            List<Notification__c> notifyInsert = new List<Notification__c>();
            
            /* -----------------------------------------------------------
            LOOP WorkOrders: Perform Mode Logic (Core!)
                ----------------------------------------------------------- */
            for (WorkOrder wo : woList) {
                
                if (!mapGC.containsKey(wo.Group_Code__c)) {
                    addErrorLog('Group code template missing', wo.Id, logs);
                    continue;
                }
                
                Case_Type_SMS__c tmpl = mapTemplate.get(mapGC.get(wo.Group_Code__c).SMS_Template__c);
                
                if (tmpl == null) {
                    addErrorLog('SMS Template missing', wo.Id, logs);
                    continue;
                }
                
                Map<String, Boolean> mode =
                    getCommunicationMode(cfg.Mode__c, wo.Account.preferance__c);
                
                /* Always override numbers due to your rule (Q3) */
                String smsPhone = cfg.Default_Number__c;
                String waPhone = cfg.Default_Number__c;
                
                /* --------------------- WHATSAPP ------------------------ */
                if (mode.get('sendWhatsApp')) {
                    
                    if (tmpl.Whatsapp_Template_Name__c == null) {
                        addErrorLog('WhatsApp template missing', wo.Id, logs);
                    } else {
                        String comp = buildMergeFieldJson(tmpl.Message__c, wo, mergeFields);
                        
                        notifyInsert.add(new Notification__c(
                            Work_Order__c = wo.Id,
                        Type__c = 'WhatsApp',
                        Sent_Timestamp__c = System.now(),
                        Status__c = 'Pending',
                        Phone_Number__c = waPhone,
                        Business_Partner__c = wo.AccountId,
                        Template_Name__c = tmpl.Whatsapp_Template_Name__c,
                        Dynamic_Components__c = comp
                            ));
                    }
                }
                
                /* ---------------------- SMS --------------------------- */
                if (mode.get('sendSMS')) {
                    
                    if (String.isBlank(tmpl.Message__c)) {
                        addErrorLog('SMS content missing', wo.Id, logs);
                    } else {
                        
                        String msg = tmpl.Message__c;
                        
                        for (String key : mergeFields.keySet()) {
                            Message_Template_Field_Mapping_Config__mdt f = mergeFields.get(key);
                        String ph = '{!' + key + '}';
                        String val;
                        
                        if (f.Type__c == 'Field') {
                            val = String.valueOf(wo.get(f.Field_API_Name__c));
                        } else {
                            val = f.Value__c;
                        }
                        
                        msg = msg.replace(ph, val == null ? '' : val);
                    }
                    
                    SmsApiHelper.Smsdata sd = new SmsApiHelper.Smsdata();
                    sd.destination = smsPhone;
                    sd.source = cfg.Sender__c;
                    sd.type = 'TEXT';
                    sd.content = msg;
                    sd.tempId = tmpl.Template_Id__c;
                    
                    smsBody.message.smsdata.add(sd);
                }
            }
        }
        
        /* Send SMS */
        if (!smsBody.message.smsdata.isEmpty()) {
            SmsApiHelper.listIntegrationLogWrap = new List<IntegrationLogHelper.IntegrationLogWrapper>();
            SmsApiHelper.sendBulkSMS(smsBody, cfg);
            logs.addAll(SmsApiHelper.listIntegrationLogWrap);
        }
        
        /* Send WhatsApp (sync) */
        if (!notifyInsert.isEmpty()) {
            WhatsappAPIHelper.sendNotificationSync(notifyInsert);
        }
        
        /* Insert Logs */
        if (!logs.isEmpty()) {
            IntegrationLogHelper.createListIntegrationLog(logs);
        }
    }
    
    
    /* ==========================================================
    Merge Field JSON Builder (WhatsApp)
        ========================================================== */
        public static String buildMergeFieldJson(String smsTemplate,
    SObject record,
    Map<String, Message_Template_Field_Mapping_Config__mdt> mergeFields) {
        
        List<Map<String, String>> jsonList = new List<Map<String, String>>();
        
        Pattern p = Pattern.compile('\\{!([a-zA-Z0-9_]+)\\}');
        Matcher m = p.matcher(smsTemplate);
        
        while (m.find()) {
            
            String key = m.group(1);
            
            if (mergeFields.containsKey(key)) {
                
                Message_Template_Field_Mapping_Config__mdt cfg = mergeFields.get(key);
                String val = ' ';
                
                if (cfg.Type__c == 'Field') {
                    Object v = record.get(cfg.Field_API_Name__c);
                    val = v == null ? ' ' : String.valueOf(v);
                } else {
                    val = cfg.Value__c;
                }
                
                jsonList.add(new Map<String, String>{ key => val });
            }
        }
        
        return JSON.serialize(jsonList);
    }
    
    public static String buildMergeFieldJsonMRS(String smsTemplate,
    SObject record,
    List<Message_Template_Field_Mapping_Config__mdt> mergeFields) {
        
        List<Map<String, String>> jsonList = new List<Map<String, String>>();
        
        // Create a sortable wrapper to maintain Order__c
        List<OrderedField> orderedFields = new List<OrderedField>();
        for(Message_Template_Field_Mapping_Config__mdt cfg : mergeFields) {
            orderedFields.add(new OrderedField(cfg));
        }
        
        // Sort by Order__c field
        orderedFields.sort();
        
        // Iterate through sorted fields and build JSON
        for(OrderedField orderedField : orderedFields){
            Message_Template_Field_Mapping_Config__mdt cfg = orderedField.field;
            String val = ' ';
            
            if (cfg.Type__c == 'Field') {
                Object v = record.get(cfg.Field_API_Name__c);
                val = v == null ? ' ' : String.valueOf(v);
            } else {
                val = cfg.Value__c;
            }
            
            jsonList.add(new Map<String, String>{ cfg.Placeholder__c => val });
        }
        
        return JSON.serialize(jsonList);
    }
    
    // Inner wrapper class to handle sorting by Order__c
    private class OrderedField implements Comparable {
        Message_Template_Field_Mapping_Config__mdt field;
        Decimal orderValue;
        
        OrderedField(Message_Template_Field_Mapping_Config__mdt f) {
            this.field = f;
            this.orderValue = f.Order__c;
        }
        
        public Integer compareTo(Object obj) {
            OrderedField other = (OrderedField) obj;
            if(this.orderValue == null) return 1;
            if(other.orderValue == null) return -1;
            if(this.orderValue > other.orderValue) return 1;
            if(this.orderValue < other.orderValue) return -1;
            return 0;
        }
    }
}