public without sharing class RandomVisitlWCController {
    
    public class CustomException extends Exception {}
    
    @AuraEnabled
    public static Account getAccountByBPNumber(String bpNumber) {
        
        List<Account> accounts = [SELECT Id, Name, CA_Number__c, BP_Number__c
	   			  FROM Account
				 WHERE BP_Number__c = :bpNumber
				 LIMIT 1];
        if(accounts.isEmpty()) {
            return null;
        }
        return accounts[0];
        
    }
    
    @AuraEnabled
    public static Map<String, String> createRandomPaymentWorkOrder(Map<String, Object> formData, Boolean isFieldSense) {
        Id currentUserId = UserInfo.getUserId();
        
        System.debug('formData: '+ formData);
        
        try {
            String bpNumber = (String) formData.get('BPNumber');
            String remark = (String) formData.get('Remark');
            String workType = (String) formData.get('WorkType');
            String AccountName = (String) formData.get('AccountName');
            String CANumber = (String) formData.get('CANumber');
            
            Decimal paymentAmount = 0;
            
            Object rawAmount = formData.get('PaymentAmount');
            if (rawAmount != null) {
                paymentAmount = Decimal.valueOf((String) rawAmount);
            }
            
            if (!isFieldSense && String.isBlank(bpNumber)) {
                return new Map<String, String>{
                    'status' => 'error',
                    'message' => 'BP Number is required.'
                };
            }
            
            String baseQuery =
                'SELECT Id, Name, BP_Number__c, CA_Number__c, PersonContactId ' +
                'FROM Account WHERE ';
            
            if (isFieldSense) {
                baseQuery += 'CA_Number__c = :CANumber ';
            } else {
                baseQuery += 'BP_Number__c = :bpNumber ';
            }
            
            baseQuery += 'LIMIT 1';
            
            
            List<Account> matchedAccount = Database.query(baseQuery);
            
            // No account found?
            if(matchedAccount.isEmpty()){
                String errorMessage = 'No matching Account found.';
                
                return new Map<String, String>{
                    'status' => 'error',
                    'message' => errorMessage
                };
            }else{
                bpNumber = matchedAccount.get(0).BP_Number__c;
            }
            
            // Choose work type name based on FieldSense
            String workTypeName = !isFieldSense
                ? 'Domestic Customer (R&T)'
                : WorkType;
            
            // Query the WorkType record
            List<WorkType> wtList = [
                SELECT Id, Name
                FROM WorkType
                WHERE Name = :workTypeName
                LIMIT 1
            ];
            
            if (wtList.isEmpty()) {
                String errorMessage = 'Work Type not found for name: ' + workTypeName;
                return new Map<String, String>{
                    'status' => 'error',
                    'message' => errorMessage
                };
            }
            
            WorkType wt = wtList[0];
            
            //Validate existing allocation (same BP Number & today's date)
            Date today = Date.today();
            List<WorkOrder> existingWOs = [
                SELECT Id, StartDate, EndDate, Agent__c, WorkTypeId, Payment_Remark__c, Status
                FROM WorkOrder
                WHERE Customer_BP_Number__c = :bpNumber
                AND DAY_ONLY(StartDate) <= :today
                AND DAY_ONLY(EndDate) >= :today
                AND RecordType.DeveloperName = 'MGL_R_T'
                LIMIT 1
            ];
            
            if(!existingWOs.isEmpty()){
                
                WorkOrder wo = existingWOs[0];
                
                // Rule 1: Not FieldSense → always block
                if (!isFieldSense) {
                    return new Map<String, String>{
                        'status' => 'error',
                        'message' => 'Random Payment not allowed. Customer is already allocated to an agent for today.'
                    };
                }
                
                // Rule 2: FieldSense + Normal Work Order → block
                if (wo.Payment_Remark__c != 'Random Payment') {
                    return new Map<String, String>{
                        'status' => 'error',
                        'message' => 'Random Payment not allowed. Customer is already allocated to an agent for today.'
                    };
                }
                
                // Rule 3: FieldSense + Random Payment + Completed → block
                if (wo.Status == 'Completed') {
                    return new Map<String, String>{
                        'status' => 'error',
                        'message' => 'Random Payment not allowed. Customer is already allocated to an agent for today.'
                    };
                }
                
                delete wo;
            }
            
            Id recordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('MGL_R_T').getRecordTypeId();
            
            // Query Service Territory Member for logged-in user
            List<ServiceTerritoryMember> stmList = [
                SELECT Id, ServiceResourceId, ServiceTerritoryId
                FROM ServiceTerritoryMember
                WHERE ServiceResource.RelatedRecordId = :currentUserId
                LIMIT 1
            ];
            
            // If not found → throw custom error
            if (stmList.isEmpty()) {
                return new Map<String, String>{
                    'status' => 'error',
                    'message' => 'No Service Territory assigned to the current user. Please contact your admin.'
                };
            }
            
            // Safe to use
            ServiceTerritoryMember member = stmList[0];
            Id serviceResource = member.ServiceResourceId;
            Id serviceTerritory = member.ServiceTerritoryId;
            
            String agencyCode;
            
            List<ServiceTerritory> sts = [
                SELECT AgencyCode__c
                FROM ServiceTerritory
                WHERE Id = :serviceTerritory
                LIMIT 1
            ];
            
            if (!sts.isEmpty()) {
                agencyCode = sts[0].AgencyCode__c;
            }
            
            //Date today = Date.today();
            DateTime startDate = DateTime.newInstance(today, Time.newInstance(9, 0, 0, 0));
            DateTime endDate = DateTime.newInstance(today, Time.newInstance(20, 0, 0, 0));
            
            WorkOrder wo = new WorkOrder(
                RecordTypeId = recordTypeId,
            AccountId = matchedAccount.get(0).Id,
            ContactId = matchedAccount.get(0).PersonContactId,
            StartDate = startDate,
            EndDate = endDate,
            WorkTypeId = wt.Id,
            CA_Number__c = matchedAccount.get(0).CA_Number__c,
            Customer_BP_Number__c = bpNumber,
            Customer_Name__c = matchedAccount.get(0).Name,
            R_T_Agency__c = serviceTerritory,
            Agent__c = serviceResource,
            Agency_Name__c = agencyCode,
            Work_Order_Type__c = 'Ad-Hoc',
            Due_Amount__c = paymentAmount,
            Payment_Remark__c = 'Random Payment',
            Remarks__c = remark
                );
            
            insert wo;
            
            // Update Service Appointment (if exists)
            List<ServiceAppointment> saList = [
                SELECT Id, Status
                FROM ServiceAppointment
                WHERE ParentRecordId = :wo.Id
                LIMIT 1
            ];
            
            if (!saList.isEmpty()) {
                ServiceAppointment sa = saList[0];
                sa.Status = 'In Progress';
                sa.Appointment_Type__c = 'Random';
                sa.Random_Visit_Date__c = Date.today();
                sa.SchedStartTime = DateTime.newInstance(Date.today(), Time.newInstance(9, 0, 0, 0));
                sa.SchedEndTime = DateTime.newInstance(Date.today(), Time.newInstance(20, 0, 0, 0));
                update sa;
            }
            
            return new Map<String, String>{
                'status' => 'success',
                'workOrderId' => wo.Id
            };
            
        }catch (Exception e) {
            
            System.debug('Error: ' + e.getMessage());
            AS_ErrorLogger.log('AS_RandomVisitController', 'createRandomPaymentWorkOrder', e.getMessage(), null);
            throw new CustomException(e.getMessage());
        }
        
    }
}

// public without sharing class RandomVisitlWCController {
    
    //     public class CustomException extends Exception {}
    
    //     @AuraEnabled
    //     public static Account getAccountByBPNumber(String bpNumber) {
        //         try{
            //             List<Account> accounts = [SELECT Id, Name, CA_Number__c, BP_Number__c
// 	   			  FROM Account
// 				 WHERE BP_Number__c = :bpNumber
// 				 LIMIT 1];
            //             if(accounts.isEmpty()) {
                //                 return null;
            //             }
            //             return accounts[0];
        //         }catch(Exception e){
            //             AS_ErrorLogger.log('AS_RandomVisitController', 'getAccountByBPNumber', e.getMessage(), null);
            //             System.debug('Error: ' + e.getMessage());
            //             return null;
        //         }
    //     }
    
    //     @AuraEnabled
    //     public static Map<String, String> createRandomPaymentWorkOrder(Map<String, Object> formData, Boolean isFieldSense) {
        //         Id currentUserId = UserInfo.getUserId();
        
        //         System.debug('formData: '+ formData);
        
        //         try {
            //             String bpNumber = (String) formData.get('BPNumber');
            //             String remark = (String) formData.get('Remark');
            //             String workType = (String) formData.get('WorkType');
            //             String AccountName = (String) formData.get('AccountName');
            //             String CANumber = (String) formData.get('CANumber');
            
            //             System.debug('isFieldSense: '+ isFieldSense);
            //             System.debug('workType: '+ workType);
            //             System.debug('AccountName: '+ AccountName);
            //             System.debug('CANumber: '+ CANumber);
            
            //             Decimal paymentAmount = 0;
            
            //             Object rawAmount = formData.get('PaymentAmount');
            //             if (rawAmount != null) {
                //                 paymentAmount = Decimal.valueOf((String) rawAmount);
            //             }
            
            //             if (!isFieldSense && String.isBlank(bpNumber)) {
                //                 // AS_ErrorLogger.log('AS_RandomVisitController', 'createRandomPaymentWorkOrder', 'BP Number is required.', (String)formData.get('BPNumber'));
                //                 return new Map<String, String>{
                    //                     'status' => 'error',
                    //                     'message' => 'BP Number is required.'
                //                 };
            //             }
            
            //             String baseQuery =
            //                 'SELECT Id, Name, BP_Number__c, CA_Number__c, PersonContactId ' +
            //                 'FROM Account WHERE ';
            
            //             if (isFieldSense) {
                //                 baseQuery += 'CA_Number__c = :CANumber ';
            //             } else {
                //                 baseQuery += 'BP_Number__c = :bpNumber ';
            //             }
            
            //             baseQuery += 'LIMIT 1';
            
            
            //             List<Account> matchedAccount = Database.query(baseQuery);
            //             System.debug('matchedAccount: '+ matchedAccount);
            
            //             // No account found?
            //             if(matchedAccount.isEmpty()){
                //                 String errorMessage = 'No matching Account found.';
                
                //                 // AS_ErrorLogger.log('AS_RandomVisitController', 'createRandomPaymentWorkOrder', errorMessage, (String)formData.get('BPNumber'));
                //                 return new Map<String, String>{
                    //                     'status' => 'error',
                    //                     'message' => errorMessage
                //                 };
            //             }else{
                //                 bpNumber = matchedAccount.get(0).BP_Number__c;
            //             }
            
            //             //Validate existing allocation (same BP Number & today's date)
            //             Date today = Date.today();
            //             List<WorkOrder> existingWOs = [
            //                 SELECT Id, StartDate, EndDate, Agent__c
            //                 FROM WorkOrder
            //                 WHERE Customer_BP_Number__c = :bpNumber
            //                 AND DAY_ONLY(StartDate) <= :today
            //                 AND DAY_ONLY(EndDate) >= :today
            //                 AND RecordType.DeveloperName = 'MGL_R_T'
            //                 LIMIT 1
            //             ];
            
            //             if (!existingWOs.isEmpty()) {
                //                 return new Map<String, String>{
                    //                     'status' => 'error',
                    //                     'message' => 'Random Payment not allowed. Customer is already allocated to an agent for today.'
                //                 };
            //             }
            
            //             Id recordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('MGL_R_T').getRecordTypeId();
            
            //             // Query Service Territory Member for logged-in user
            //             List<ServiceTerritoryMember> stmList = [
            //                 SELECT Id, ServiceResourceId, ServiceTerritoryId
            //                 FROM ServiceTerritoryMember
            //                 WHERE ServiceResource.RelatedRecordId = :currentUserId
            //                 LIMIT 1
            //             ];
            
            //             // If not found → throw custom error
            //             if (stmList.isEmpty()) {
                //                 // AS_ErrorLogger.log('AS_RandomVisitController', 'createRandomPaymentWorkOrder', 'No Service Territory assigned to the current user.', (String)formData.get('BPNumber'));
                //                 return new Map<String, String>{
                    //                     'status' => 'error',
                    //                     'message' => 'No Service Territory assigned to the current user. Please contact your admin.'
                //                 };
            //             }
            
            //             // Safe to use
            //             ServiceTerritoryMember member = stmList[0];
            //             Id serviceResource = member.ServiceResourceId;
            //             Id serviceTerritory = member.ServiceTerritoryId;
            
            //             //Date today = Date.today();
            //             DateTime startDate = DateTime.newInstance(today, Time.newInstance(9, 0, 0, 0));
            //             DateTime endDate = DateTime.newInstance(today, Time.newInstance(20, 0, 0, 0));
            
            //             // Choose work type name based on FieldSense
            //             String workTypeName = !isFieldSense
            //                 ? 'Domestic Customer (R&T)'
            //                 : WorkType;
            
            //             // Query the WorkType record
            //             List<WorkType> wtList = [
            //                 SELECT Id, Name
            //                 FROM WorkType
            //                 WHERE Name = :workTypeName
            //                 LIMIT 1
            //             ];
            
            //             if (wtList.isEmpty()) {
                //                 String errorMessage = 'Work Type not found for name: ' + workTypeName;
                //                 // AS_ErrorLogger.log('AS_RandomVisitController', 'createRandomPaymentWorkOrder', errorMessage, (String)formData.get('BPNumber'));
                //                 return new Map<String, String>{
                    //                     'status' => 'error',
                    //                     'message' => errorMessage
                //                 };
            //             }
            
            //             WorkType wt = wtList[0];
            
            //             System.debug('Selected WorkType: ' + wt.Name);
            
            
            //             WorkOrder wo = new WorkOrder(
            //                 RecordTypeId = recordTypeId,
            //             AccountId = matchedAccount.get(0).Id,
            //             ContactId = matchedAccount.get(0).PersonContactId,
            //             StartDate = startDate,
            //             EndDate = endDate,
            //             WorkTypeId = wt.Id,
            //             CA_Number__c = matchedAccount.get(0).CA_Number__c,
            //             Customer_BP_Number__c = bpNumber,
            //             Customer_Name__c = matchedAccount.get(0).Name,
            //             R_T_Agency__c = serviceTerritory,
            //             Agent__c = serviceResource,
            //             Work_Order_Type__c = 'Ad-Hoc',
            //             Due_Amount__c = paymentAmount,
            //             Payment_Remark__c = 'Random Payment',
            //             Remarks__c = remark
            //                 );
            
            //             System.debug('WorkOrder: ' + wo);
            //             insert wo;
            
            //             // Update Service Appointment (if exists)
            //             List<ServiceAppointment> saList = [
            //                 SELECT Id, Status
            //                 FROM ServiceAppointment
            //                 WHERE ParentRecordId = :wo.Id
            //                 LIMIT 1
            //             ];
            
            //             if (!saList.isEmpty()) {
                //                 ServiceAppointment sa = saList[0];
                //                 sa.Status = 'In Progress';
                //                 sa.Appointment_Type__c = 'Random';
                //                 sa.Random_Visit_Date__c = Date.today();
                //                 sa.SchedStartTime = DateTime.newInstance(Date.today(), Time.newInstance(9, 0, 0, 0));
                //                 sa.SchedEndTime = DateTime.newInstance(Date.today(), Time.newInstance(20, 0, 0, 0));
                //                 update sa;
            //             }
            
            //             return new Map<String, String>{
                //                 'status' => 'success',
                //                 'workOrderId' => wo.Id
            //             };
            
        //         }catch (Exception e) {
            
            //             System.debug('Error: ' + e.getMessage());
            //             AS_ErrorLogger.log('AS_RandomVisitController', 'createRandomPaymentWorkOrder', e.getMessage(), null);
            //             throw new CustomException(e.getMessage());
        //         }
        
    //     }
// }