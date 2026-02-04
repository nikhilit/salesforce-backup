/**
         * @File Name       : SmsBulkAPICallout.cls
         * @Description     : Builds bulk SMS payloads and performs HTTP callouts for WorkOrders.
         * @Last Modified On: September 22, 2025
         */
        public class SmsBulkAPICallout {
            
            // 🔹 Cached config / mapping
            private static SmsApiConfigLTD__c CONFIG_CACHE;
            private static Map<String, Object> FIELD_MAP_CACHE;
            private static Map<String, List<String>> PATH_TOKEN_CACHE = new Map<String, List<String>>();
            
            // ===============================================================
            // Caching Helpers
            // ===============================================================
            private static void ensureCaches() {
                if (CONFIG_CACHE == null) {
                    CONFIG_CACHE = SmsApiConfigLTD__c.getOrgDefaults();
                }
                if (FIELD_MAP_CACHE == null) {
                    try {
                        MGL_Setting__mdt mappingMdt = [
                    SELECT Expected_Value_Mappings__c
                    FROM MGL_Setting__mdt
                    WHERE DeveloperName = 'SMS_Template_Mappings'
                    LIMIT 1
                ];
                        if (mappingMdt != null && !String.isBlank(mappingMdt.Expected_Value_Mappings__c)) {
                            FIELD_MAP_CACHE = (Map<String, Object>) JSON.deserializeUntyped(mappingMdt.Expected_Value_Mappings__c);
                        } else {
                            FIELD_MAP_CACHE = new Map<String, Object>();
                        }
                    } catch (Exception e) {
                        FIELD_MAP_CACHE = new Map<String, Object>();
                    }
                }
            }
            
            // ===============================================================
            // Bulk SMS Payload Builder
            // ===============================================================
            public static SmsBulkPayload buildBulkSmsPayload(List<WorkOrderNotificationService.WorkOrderNotificationWrapper> wrappers) {
                ensureCaches();
                if (CONFIG_CACHE == null || String.isBlank(CONFIG_CACHE.API_Key__c)) {
                    System.debug('SmsBulkAPICallout.buildBulkSmsPayload: Missing API Key in SmsApiConfigLTD__c org defaults.');
                    return null;
                }
                
                Map<String, Object> root = new Map<String, Object>();
                root.put('authentication', new Map<String, Object>{
                    'key' => CONFIG_CACHE.API_Key__c,
                    'version' => '1.0',
                    'channel' => '0'
                });
                
                List<Object> smsdataList = new List<Object>();
                List<Id> idsInOrder = new List<Id>();
                List<String> phonesInOrder = new List<String>();
                Map<String, List<Integer>> phoneToIndices = new Map<String, List<Integer>>();
                
                for (WorkOrderNotificationService.WorkOrderNotificationWrapper wrap : wrappers) {
                    if (wrap == null || wrap.wo == null || wrap.tmpl == null || String.isBlank(wrap.tmpl.Message__c)) continue;
                    WorkOrder wo = wrap.wo;
                    // Skip if no phone available at all
                    String candidatePhone = String.isBlank(wo.New_Mobile_Number__c)
                        ? (wo.Account != null ? wo.Account.Phone : null)
                        : wo.New_Mobile_Number__c;
                    
                    if (String.isBlank(candidatePhone)) continue;
                    
                    // Build merge fields
                    Map<String, String> mergeFields = new Map<String, String>();
                    for (String key : FIELD_MAP_CACHE.keySet()) {
                        String fieldPath = String.valueOf(FIELD_MAP_CACHE.get(key));
                        Object val = (key == 'Remark' && !String.isBlank(wrap.followUpRemarksOpt))
                            ? wrap.followUpRemarksOpt
                            : getFieldValueByPath(wo, fieldPath);
                        
                        String formatted;
                        if (val == null || String.valueOf(val) == '') formatted = 'N/A';
                        else if (val instanceof Date) formatted = ((Date)val).format();
                        else if (val instanceof Datetime) formatted = ((Datetime)val).format();
                        else formatted = String.valueOf(val);
                        
                        mergeFields.put(key, formatted);
                    }
                    
                    // Replace placeholders
                    String content = wrap.tmpl.Message__c;
                    for (String key : mergeFields.keySet()) {
                    String placeholder = '{!' + key + '}';
                    if (content.contains(placeholder)) {
                        content = content.replace(placeholder, mergeFields.get(key));
                    }
                }
                
                String dest = normalizePhone(candidatePhone);
                
                Map<String, Object> smsEntry = new Map<String, Object>{
                    'destination' => dest,
                    'source' => 'MGLLTD',
                    'type' => 'TEXT',
                    'content' => content,
                    'tempId' => wrap.templateId
                };
                smsdataList.add(smsEntry);
                idsInOrder.add(wo.Id);
                phonesInOrder.add(dest);
                
                if (!phoneToIndices.containsKey(dest)) phoneToIndices.put(dest, new List<Integer>());
                phoneToIndices.get(dest).add(phonesInOrder.size() - 1);
            }
            
            root.put('message', new Map<String, Object>{ 'smsdata' => smsdataList });
            
            SmsBulkPayload out = new SmsBulkPayload();
            out.json = JSON.serialize(root);
            out.woIdsInOrder = idsInOrder;
            out.destPhonesInOrder = phonesInOrder;
            out.phoneToIndices = phoneToIndices;
            
            System.debug('SmsBulkAPICallout.buildBulkSmsPayload Final JSON → ' + JSON.serializePretty(root));
            return out;
        }
        
        // --- NEW METHOD for Payment context ---
        public static SmsBulkPayload buildBulkSmsPayloadForPayment(List<AS_PaymentNotificationService.WorkOrderNotificationWrapper> wrappers) {
            ensureCaches();
            if (CONFIG_CACHE == null || String.isBlank(CONFIG_CACHE.API_Key__c)) {
                System.debug('SmsBulkAPICallout.buildBulkSmsPayloadForPayment: Missing API Key.');
                return null;
            }
            
            Map<String, Object> root = new Map<String, Object>();
            root.put('authentication', new Map<String, Object>{
                'key' => CONFIG_CACHE.API_Key__c,
                'version' => '1.0',
                'channel' => '0'
            });
            
            List<Object> smsdataList = new List<Object>();
            List<Id> payIdsInOrder = new List<Id>();
            List<String> phonesInOrder = new List<String>();
            Map<String, List<Integer>> phoneToIndices = new Map<String, List<Integer>>();
            
            system.debug('========wrappers=======>'+wrappers);
            
            Map<String, String> staticFieldMap = new Map<String, String>{
                'workOrder.WorkOrderNumber'       => 'ReceiptNo__c',
                'workOrder.Account.CA_Number__c'  => 'Work_Order__r.CA_Number__c',
                'workOrder.Amount_Received__c'    => 'Cheque_Amount__c',
                'workOrder.Payment_Mode__c'       => 'Work_Order__r.Payment_Mode__c',
                'workOrder.Agent__r.Name'         => 'Work_Order__r.Agent__r.Name',
                'workOrder.Agency_Name_Formula__c'=> 'Work_Order__r.Agency_Name_Formula__c'
            };
            
            for (AS_PaymentNotificationService.WorkOrderNotificationWrapper wrap : wrappers) {
                if (wrap == null || wrap.pay == null || wrap.tmpl == null || String.isBlank(wrap.tmpl.Message__c)) continue;
                
                Payment__c pay = wrap.pay;
                WorkOrder wo = pay.Work_Order__r;
                if (wo == null) continue;
                
                String candidatePhone = String.isBlank(wo.New_Mobile_Number__c)
                    ? (wo.Account != null ? wo.Account.Phone : null)
                    : wo.New_Mobile_Number__c;
                if (String.isBlank(candidatePhone)) continue;
                
                Map<String, String> mergeFields = new Map<String, String>();
                for (String key : staticFieldMap.keySet()) {
                    String fieldPath = staticFieldMap.get(key);
                    Object val = getFieldValueByPath(pay, fieldPath);
                    
                    String formatted;
                    if (val == null || String.valueOf(val) == '') formatted = 'N/A';
                    else if (val instanceof Date) formatted = ((Date)val).format();
                    else if (val instanceof Datetime) formatted = ((Datetime)val).format();
                    else formatted = String.valueOf(val);
                    
                    if(key == 'workOrder.Payment_Mode__c'){
                        mergeFields.put(key, 'Cheque');
                    }else{
                        mergeFields.put(key, formatted);
                    }
                    
                }
                
                system.debug('========mergeFields=======>'+mergeFields);
                
                String content = wrap.tmpl.Message__c;
                for (String key : mergeFields.keySet()) {
                String placeholder = '{!' + key + '}';
                if (content.contains(placeholder)) {
                    content = content.replace(placeholder, mergeFields.get(key));
                }
            }
            
            system.debug('========content=======>'+content);
            
            String dest = normalizePhone(candidatePhone);
            Map<String, Object> smsEntry = new Map<String, Object>{
                'destination' => dest,
                'source' => 'MGLLTD',
                'type' => 'TEXT',
                'content' => content,
                'tempId' => wrap.templateId
            };
            smsdataList.add(smsEntry);
            payIdsInOrder.add(pay.Id);
            phonesInOrder.add(dest);
            
            system.debug('========smsdataList=======>'+smsdataList);
            
            if (!phoneToIndices.containsKey(dest)) phoneToIndices.put(dest, new List<Integer>());
            phoneToIndices.get(dest).add(phonesInOrder.size() - 1);
        }
        
        root.put('message', new Map<String, Object>{ 'smsdata' => smsdataList });
        
        SmsBulkPayload out = new SmsBulkPayload();
        out.json = JSON.serialize(root);
        out.woIdsInOrder = payIdsInOrder;
        out.destPhonesInOrder = phonesInOrder;
        out.phoneToIndices = phoneToIndices;
        
        return out;
    }
    
    // ===============================================================
    // Callout Handlers
    // ===============================================================
    @future(callout=true)
    public static void sendBulkSmsWithUpdate(String bulkJsonPayload, String woIdsJson, String phonesJson, String phoneToIndicesJson) {
        doBulkSmsWithUpdate(bulkJsonPayload, woIdsJson, phonesJson, phoneToIndicesJson);
    }
    
    // Synchronous twin (for batch execution)
    public static void sendBulkSmsWithUpdateSync(String bulkJsonPayload, String woIdsJson, String phonesJson, String phoneToIndicesJson) {
        doBulkSmsWithUpdate(bulkJsonPayload, woIdsJson, phonesJson, phoneToIndicesJson);
    }
    
    private static void doBulkSmsWithUpdate(String bulkJsonPayload, String woIdsJson, String phonesJson, String phoneToIndicesJson) {
        if (!TriggerController.isTriggerActive('SmsBulkAPICallout')) return;
        
        // Deserialize correlation JSON
        List<Object> idObjs = (List<Object>) (String.isBlank(woIdsJson) ? new List<Object>() : JSON.deserializeUntyped(woIdsJson));
        Map<String, Object> p2iRaw = (Map<String, Object>) (String.isBlank(phoneToIndicesJson) ? new Map<String, Object>() : JSON.deserializeUntyped(phoneToIndicesJson));
        
        List<Id> woIdsInOrder = new List<Id>();
        for (Object obj : idObjs) if (obj != null) woIdsInOrder.add((Id) String.valueOf(obj));
        if (woIdsInOrder.isEmpty()) return;
        
        Map<String, List<Integer>> phoneToIndices = new Map<String, List<Integer>>();
        for (String key : p2iRaw.keySet()) {
            List<Object> li = (List<Object>) p2iRaw.get(key);
            List<Integer> casted = new List<Integer>();
            for (Object o : li) casted.add(Integer.valueOf(String.valueOf(o)));
            phoneToIndices.put(key, casted);
        }
        
        ensureCaches();
        if (CONFIG_CACHE == null || String.isBlank(CONFIG_CACHE.EndPoint__c)) return;
        
        // HTTP Callout
        HttpRequest req = new HttpRequest();
        req.setEndpoint(CONFIG_CACHE.EndPoint__c);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(bulkJsonPayload);
        
        Integration_Log__c apiLog = new Integration_Log__c(
            Class_Name__c = 'SmsBulkAPICallout',
        Method_Name__c = 'doBulkSmsWithUpdate',
        Endpoint_URL__c = CONFIG_CACHE.EndPoint__c,
        Request_Body__c = bulkJsonPayload,
        Request_Method__c = 'POST',
        Work_Order__c = !woIdsInOrder.isEmpty() && woIdsInOrder.size() == 1 ? woIdsInOrder.get(0) : null
            );
        
        try {
            Http http = new Http();
            HttpResponse resp = http.send(req);
            // HttpResponse resp = new HttpResponse();
            // resp.setStatusCode(200);
            // resp.setStatus('OK');
            // resp.setBody(
            //     '[{"code":"200","cause":"SUCCESS","destination":"9021743879",' +
            //     '"uuid":"0217a2cb-7493-d5b9-9328-120b20034e62","sms_id":""}]'
            //     );
            
            System.debug('resp.getBody(): ' + resp.getBody());
            System.debug('resp.getStatusCode(): ' + resp.getStatusCode());
            System.debug('resp.getStatus(): ' + resp.getStatus());
            
            apiLog.Response_Body__c = resp.getBody();
            apiLog.Status_Code__c = resp.getStatusCode();
            apiLog.Status__c = resp.getStatusCode() == 200 ? 'Success' : 'Failed';
            
            if (resp.getStatusCode() == 200 && String.isNotBlank(resp.getBody())) {
                
                List<Object> results = (List<Object>) JSON.deserializeUntyped(resp.getBody());
                System.debug('results: ' + results);
                System.debug('results.size(): ' + results.size());
                System.debug('results[0]: ' + results[0]);
                if (results != null) {
                    List<WorkOrder> updates = new List<WorkOrder>();
                    List<Integration_Log__c> logs = new List<Integration_Log__c>();
                    Set<Integer> used = new Set<Integer>();
                    
                    Map<String, Object> payloadMap =
                        (Map<String, Object>) JSON.deserializeUntyped(bulkJsonPayload);
                    
                    List<Object> smsData =
                        (List<Object>) ((Map<String, Object>) payloadMap.get('message'))
                        .get('smsdata');
                    
                    for (Object ob : results) {
                        System.debug('ob: ' + ob);
                        Map<String, Object> item = (Map<String, Object>) ob;
                        
                        String code = (String) item.get('code');
                        String destination = normalizePhone((String) item.get('destination'));
                        String smsId = (String) item.get('uuid');
                        if (String.isBlank(smsId)) smsId = (String) item.get('sms_id');
                        
                        if (!'200'.equals(code) || String.isBlank(destination) || !phoneToIndices.containsKey(destination)) continue;
                        
                        Integer picked = null;
                        for (Integer idx : phoneToIndices.get(destination)) {
                            if (idx != null && idx >= 0 && idx < woIdsInOrder.size() && !used.contains(idx)) { picked = idx; break; }
                        }
                        if (picked == null) continue;
                        used.add(picked);
                        
                        if(String.valueOf(woIdsInOrder[picked]).startsWith('0WO')){
                            
                            Map<String, Object> smsReq = null;
                            String smsContent = null;
                            
                            if (picked < smsData.size()) {
                                smsReq = (Map<String, Object>) smsData[picked];
                            }
                            
                            if (smsReq != null && smsReq.containsKey('content')) {
                                smsContent = (String) smsReq.get('content');
                            }
                            
                            String smsRequestJson = smsReq != null
                                ? JSON.serialize(smsReq)
                                : null;
                            
                            updates.add(new WorkOrder(
                                Id = woIdsInOrder[picked],
                            SMS_Sent__c = true,
                            SMS_Success_Id__c = (smsId == null ? '' : smsId)
                                ));
                            
                            logs.add(new Integration_Log__c(
                                Class_Name__c = 'SmsBulkAPICallout',
                            Method_Name__c = 'doBulkSmsWithUpdate',
                            Endpoint_URL__c = CONFIG_CACHE.EndPoint__c,
                            Request_Body__c = smsRequestJson,
                            Message__c = smsContent,
                            Request_Method__c = 'POST',
                            Work_Order__c = woIdsInOrder[picked],
                            Response_Body__c = JSON.serialize(item),
                            Status_Code__c = resp.getStatusCode(),
                            Status__c = resp.getStatusCode() == 200 ? 'Success' : 'Failed'
                                ));
                        }
                    }
                    
                    if (!updates.isEmpty()) Database.update(updates, false);
                    if (!logs.isEmpty()) Database.insert(logs, false);
                }
            }
        } catch (Exception ex) {
            apiLog.Status__c = 'Exception';
            apiLog.Response_Body__c = ex.getMessage();
        }
        
        try {
            insert apiLog;
        }
        catch (Exception ex) {
            Error_Logger__c err = Error_LoggerClass.createErrorLogger(
                'SmsBulkAPICallout','doBulkSmsWithUpdate', null, ex.getTypeName(), ex.getMessage(), ex.getLineNumber(), true
                );
            insert err;
        }
    }
    
    // ===============================================================
    // Helpers
    // ===============================================================
    private static String normalizePhone(String phone) {
        return phone == null ? null : phone.replaceAll('[^0-9]', '');
    }
    
    private static Object getFieldValueByPath(SObject record, String path) {
        if (record == null || String.isBlank(path)) return null;
        if (!PATH_TOKEN_CACHE.containsKey(path)) {
            PATH_TOKEN_CACHE.put(path, path.split('\\.'));
        }
        List<String> parts = PATH_TOKEN_CACHE.get(path);
        
        Object current = record;
        for (String part : parts) {
            if (current == null) return null;
            if (current instanceof SObject) {
                SObject sobj = (SObject) current;
                try {
                    if (sobj.getSObjectType().getDescribe().fields.getMap().containsKey(part)) {
                        current = sobj.get(part);
                        continue;
                    }
                } catch (Exception e) { }
                try {
                    current = sobj.getSObject(part);
                    continue;
                } catch (Exception e) {
                    return null;
                }
            } else {
                return current; // primitive
            }
        }
        return current;
    }
    
    // ===============================================================
    // DTO
    // ===============================================================
    public class SmsBulkPayload {
        public String json;
        public List<Id> woIdsInOrder;
        public List<String> destPhonesInOrder;
        public Map<String, List<Integer>> phoneToIndices;
    }
}