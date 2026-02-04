public without sharing class PaymentCancelController {
        
        private static Map<String, List<String>> PATH_TOKEN_CACHE = new Map<String, List<String>>();
        
        @AuraEnabled
        public static Boolean checkValidity(Id recordId){
            try{
                WorkOrder wo = [
                SELECT Id, Payment_Date__c 
                FROM WorkOrder 
                WHERE Id = :recordId 
                LIMIT 1
            ];
                
                if (wo.Payment_Date__c == null) return false;
                
                // Parse dd/MM/yyyy string
                String dateString = wo.Payment_Date__c;
                List<String> parts = dateString.split('/');
                
                Integer day = Integer.valueOf(parts[0]);
                Integer month = Integer.valueOf(parts[1]);
                Integer year = Integer.valueOf(parts[2]);
                
                Date paymentDate = Date.newInstance(year, month, day);
                
                // VALID if payment date is NOT older than 7 days
                Boolean validity = paymentDate >= Date.today().addDays(-7);
                
                return validity;
                
            } catch(Exception e){
                AS_ErrorLogger.log('PaymentCancelController', 'checkValidity', e, recordId);
                return false;
            }
        }
        
        @AuraEnabled
        public static void cancelReceiptMethod(Map<String, Object> formData, Id recordId){
            try{
                String cancellationReason = (String) formData.get('cancelReason');
                String remarks = (String) formData.get('remarks');
                
                WorkOrder workOrder = [SELECT Id, Status, New_Mobile_Number__c, Remarks__c, Cancel_Reason__c, Check_Out_Date_Time__c, Check_Out_Location__Latitude__s, Check_Out_Location__Longitude__s, Appointment_Status__c FROM WorkOrder WHERE Id =: recordId];
                updateWorkOrder(workOrder, remarks, cancellationReason);
                
                ServiceAppointment serviceAppointment = [SELECT Id, Status FROM ServiceAppointment WHERE ParentRecordId =: recordId ORDER BY CreatedDate DESC limit 1];
                serviceAppointment.Status = 'In Progress';
                serviceAppointment.Appointment_Type__c = 'In Progress';
                update serviceAppointment;
                
                updateWorkSteps(recordId);
                updatePayments(recordId, cancellationReason);
                
                sendSms(workOrder.New_Mobile_Number__c, recordId);
            }catch(Exception e){
                System.debug('Exception message: '+ e.getMessage());
                System.debug('Exception line: '+ e.getLineNumber());
                AS_ErrorLogger.log('PaymentCancelController', 'cancelReceiptMethod', e, recordId);
            }
        }
        
        public static void updateWorkOrder(WorkOrder wo,String remarks, String cancellationReason){
            WorkOrder workOrder = new WorkOrder(
                Id = wo.Id,
            Transaction_Id__c = null,
            Amount_Received__c = null,
            Payment_Mode__c = null,
            Payment_Date__c = null,
            Payment_Type__c = null,
            Pay_Remark__c = null,
            Status = 'In Progress',
            Check_Out_Date_Time__c = null,
            Check_Out_Location__Latitude__s = null,
            Check_Out_Location__Longitude__s = null,
            Appointment_Status__c = 'In Progress',
            Remarks__c = remarks,
            Cancel_Reason__c = cancellationReason
                );
            
            update workOrder;
        }
        
        public static void updatePayments(Id recordId, String cancellationReason){
            try{
                Id currentUserId = UserInfo.getUserId();
                
                List<Payment__c> payments = [SELECT Id, Payment_Status__c, Payment_Mode__c, Payment_Date__c 
            FROM Payment__c 
            WHERE Work_Order__c =: recordId
            AND Payment_Status__c = 'Pending' 
            ];
                
                List<Payment__c> updatePayments = new List<Payment__c>();
                for(Payment__c p: payments){
                    Payment__c payment = new Payment__c(
                        Id = p.Id,
                    Payment_Status__c = 'Cancelled',
                    CancelledByUser__c = currentUserId,
                    Cancelled_Date_Time__c = System.now(),
                    Cancel_Reason_c__c = cancellationReason
                        );
                    
                    updatePayments.add(payment);
                }
                System.debug('updatePayments: '+ updatePayments);
                
                update updatePayments;
            }catch(Exception e){
                System.debug('Exception message: '+ e.getMessage());
                System.debug('Exception line: '+ e.getLineNumber());
            }
        }
        
        public static void updateWorkSteps(Id recordId) {
            List<String> names = new List<String>{ 'Check In' };
            List<WorkStep> steps = [SELECT Id FROM WorkStep
            WHERE ParentRecordId  =: recordId AND Name NOT IN :names];
            for (WorkStep ws : steps) {
                ws.Status = 'New';
            }
            update steps;
        }
        
        // @AuraEnabled
        public static String sendSms(String phoneNumber, String workOrderId) {
            System.debug('sendSMS Called');
            if (String.isBlank(phoneNumber)) {
                throw new AuraHandledException('Phone number is required to send SMS.');
            }
            
            List<Payment__c> lstPayment = new List<Payment__c>();
            
            for (Payment__c pay : [SELECT Id, Name, Cheque_Amount__c, Work_Order__c, ReceiptNo__c,CAN_Receipt_No__c,
                                      Work_Order__r.RecordType.DeveloperName, 
                                      Work_Order__r.RecordTypeId,
                                      Work_Order__r.Record_Type_Developer_Name__c,
                                      Work_Order__r.AccountId, 
                                      Work_Order__r.Account.Phone,
                                      Work_Order__r.Account.CA_Number__c,
                                      Work_Order__r.New_Mobile_Number__c,
                                      Work_Order__r.CA_Number__c,
                                      Work_Order__r.Agency_Name_Formula__c,
                                      Work_Order__r.Agent__r.Name,
                                      Work_Order__r.Payment_Mode__c,
                                      Work_Order__r.Cancel_Reason__c
                                 FROM Payment__c
                                WHERE Work_Order__c = : workOrderId 
                                ORDER BY Createddate DESC
                                Limit 1 ]) {
                lstPayment.add(pay);
            }
            
            System.debug('lstPayment: '+lstPayment);
            
            // Receipt Cancellation
            Go_Collect_Follow_Up__mdt mdt = [
            SELECT Id, Template_Id__c
            FROM Go_Collect_Follow_Up__mdt
            WHERE DeveloperName = 'Cheque_Cancel'
            LIMIT 1
        ];
            
            if (mdt == null || String.isBlank(mdt.Template_Id__c)) {
                throw new AuraHandledException('No active SMS template found in metadata.');
            }
            
            List<Case_Type_SMS__c> tmplList = [
            SELECT Status__c, Template_Id__c, Message__c
            FROM Case_Type_SMS__c
            WHERE Template_Id__c = :mdt.Template_Id__c
            LIMIT 1
        ];

        System.debug('tmplList:'+tmplList);
            
            if (tmplList.isEmpty()) {
                throw new AuraHandledException('No matching SMS template record found for Template Id: ' + mdt.Template_Id__c);
            }
            
            Case_Type_SMS__c tmpl = tmplList[0];
            
            Map<String, String> staticFieldMap = new Map<String, String>{
                'CAN_Receipt_No__c' => 'CAN_Receipt_No__c',
                'workOrder.Amount_Received__c'    => 'Cheque_Amount__c',
                'ReceiptNo__c' => 'ReceiptNo__c',
                'workOrder.Account.CA_Number__c'  => 'Work_Order__r.CA_Number__c',
                'workOrder.Cancel_Reason__c' => 'Work_Order__r.Cancel_Reason__c'
            };
            
            // 🔹 NEW: SMS Case using Bulk API
            if (!String.isBlank(phoneNumber)) {
                // Build correlation fields
                
                String woIdsJson = JSON.serialize(new List<Id>{ workOrderId });
                String phonesJson = JSON.serialize(new List<String>{ phoneNumber });
                Map<String, List<Integer>> mapPhoneToIdx = new Map<String, List<Integer>>{ phoneNumber => new List<Integer>{ 0 } };
                String phoneToIndicesJson = JSON.serialize(mapPhoneToIdx);
                
                SmsApiConfigLTD__c config = SmsApiConfigLTD__c.getOrgDefaults();
                
                // Build JSON payload
                Map<String,Object> auth = new Map<String,Object>{
                    'key' => config.API_Key__c,
                    'version' => '1.0',
                    'channel' => '0'
                };
                
                System.debug('auth: '+auth);
                
                
                List<Object> smsdataList = new List<Object>();
                List<String> phonesInOrder = new List<String>();
                List<Id> payIdsInOrder = new List<Id>();
                Map<String, List<Integer>> phoneToIndices = new Map<String, List<Integer>>();
                
                for (Payment__c p : lstPayment) {
                    
                    WorkOrder wo = p.Work_Order__r;
                    if (wo == null) continue;
                    
                    String candidatePhone = phoneNumber;
                    
                    if (String.isBlank(candidatePhone)) continue;
                    
                    Map<String, String> mergeFields = new Map<String, String>();
                    
                    System.debug('KeySet : '+staticFieldMap.keySet());
                    for (String key : staticFieldMap.keySet()) {
                        String fieldPath = staticFieldMap.get(key);
                        Object val = getFieldValueByPath(p, fieldPath);
                        System.debug('val: '+val);
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
                    
                    String content = tmpl.Message__c;
                    System.debug('mergeFields KeySet : '+mergeFields.keySet());
                    for (String key : mergeFields.keySet()) {
                    String placeholder = '{!' + key + '}';
                    if (content.contains(placeholder)) {
                        content = content.replace(placeholder, mergeFields.get(key));
                    }
                }
                
                system.debug('========content=======>'+content);
                
                String dest = candidatePhone;
                
                Map<String, Object> smsEntry = new Map<String, Object>{
                    'destination' => dest,
                    'source' => 'MGLLTD',
                    'type' => 'TEXT',
                    'content' => content,
                    'tempId' => mdt.Template_Id__c
                };
                
                System.debug('smsEntry: '+smsEntry);
                smsdataList.add(smsEntry);
                
                payIdsInOrder.add(p.Id);
                phonesInOrder.add(dest);
                
                if (!phoneToIndices.containsKey(dest)) phoneToIndices.put(dest, new List<Integer>());
                phoneToIndices.get(dest).add(phonesInOrder.size() - 1);
            }
            
            
            Map<String,Object> payload = new Map<String,Object>{
                'authentication' => auth,
                'message' => new Map<String,Object>{ 'smsdata' => smsdataList }
            };
            
            String smsJson = JSON.serialize(payload);
            
            System.debug('smsJson : '+smsJson);
            // Call Bulk SMS API
            SmsBulkAPICallout.sendBulkSmsWithUpdate(
                smsJson,
            woIdsJson,
            phonesJson,
            phoneToIndicesJson
                );
        }
        return 'Success';
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
        System.debug('current: '+current);
        return current;
    }
    
}