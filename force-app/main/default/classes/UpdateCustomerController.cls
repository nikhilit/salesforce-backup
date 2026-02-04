/**
 * @description       :
 * @author            : Kartik Patkar Appstrail
 * @group             :
 * @last modified on  : 29-07-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   07-05-2025   Kartik Patkar, Appstrail   Initial Version
 **/
public without sharing class UpdateCustomerController {
    
    @AuraEnabled
    public static WorkOrder getAccountRec(String recordId){
        try {
            return [SELECT Id, AccountId FROM WorkOrder WHERE Id = :recordId LIMIT 1];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String,Object> getAccountRecordDetails(String recordId){
        try {
            Map<String,Object> response = new Map<String,Object>();
            List<WorkOrder> listWorkOrders=[SELECT Id,AccountId,Old_Meter_Number__c,New_Residence_Telephone__c,New_Office_Telephone__c,New_Mobile_Number__c,New_Email__c 
                                            FROM WorkOrder WHERE Id=:recordId LIMIT 1];
            if(!listWorkOrders.isEmpty()){
                Account accRec=[SELECT Id, Name,Account_Email__c, Phone,Meter_Number__c,PersonOtherPhone,Secondary_Telephone__c 
                                FROM Account WHERE Id = :listWorkOrders[0].AccountId LIMIT 1];
                response.put('workOrder',listWorkOrders[0]);
                response.put('accRec',accRec);
                return response;
            }
            return null;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String updateCustomerMeterNumber(String recordId, String meterNumber,String remark,String accountId){
        try {
            // List<Account> listAcc = [SELECT Id, Meter_Number__c FROM Account WHERE Id = :accountId LIMIT 1];
            // acc.Meter_Number__c = meterNumber;
            // acc.Remark__c = remark;
            // update acc;

            List<WorkOrder> listWorkOrders=[SELECT Id,Old_Meter_Number__c,New_Meter_Number__c,Description,
                                                AccountId,Account.Meter_Number__c
                                            FROM WorkOrder WHERE Id = :recordId LIMIT 1];

            if(!listWorkOrders.isEmpty()){
                WorkOrder workRec = listWorkOrders[0];
                if(workRec.AccountId!=null){
                    workRec.Old_Meter_Number__c = workRec.Account.Meter_Number__c;
                }
                workRec.New_Meter_Number__c = meterNumber;
                workRec.Update_Meter_Number_Remark__c=remark;
                update workRec;
            }
            
            updateWorkStepStatus(recordId, Label.Update_Meter_Number_Step_Name);
            return 'success';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static string updateCustomerContact(String recordId, String phone, String otherPhone, String secondaryPhone,String remark,String accountId,String newEmail){
        try {
            // Account acc = [SELECT Id, Phone, PersonOtherPhone, Secondary_Telephone__c FROM Account WHERE Id = :accountId LIMIT 1];
            // acc.Phone = phone;
            // acc.PersonOtherPhone = otherPhone;
            // acc.Secondary_Telephone__c = secondaryPhone;
            // acc.Remark__c = remark;
            // update acc;

            List<WorkOrder> listWorkOrders=[SELECT Id,Old_Mobile_Number__c,Old_Residence_Telephone__c,Old_Office_Telephone__c,
                                                New_Mobile_Number__c,New_Residence_Telephone__c,New_Office_Telephone__c,Description,
                                                AccountId,Account.Phone,Account.PersonOtherPhone,Account.Secondary_Telephone__c
                                            FROM WorkOrder WHERE Id = :recordId LIMIT 1];

            if(!listWorkOrders.isEmpty()){
                WorkOrder workRec = listWorkOrders[0];
                if(workRec.AccountId!=null){
                    workRec.Old_Mobile_Number__c = workRec.Account.Phone;
                    workRec.Old_Office_Telephone__c = workRec.Account.PersonOtherPhone;
                    workRec.Old_Residence_Telephone__c = workRec.Account.Secondary_Telephone__c;
                }
                workRec.New_Email__c=newEmail;
                workRec.New_Email__c=newEmail;
                workRec.New_Mobile_Number__c = phone;
                workRec.New_Office_Telephone__c = otherPhone;
                workRec.New_Residence_Telephone__c = secondaryPhone;
                workRec.Update_Contact_Remark__c=remark;
                update workRec;
            }
            
            updateWorkStepStatus(recordId, Label.Update_Customer_Contact_Step_Name);
            return 'success';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public static void updateWorkStepStatus(Id workOrderId,String name){
        List<WorkStep> steps = [
			SELECT Id, Status
			FROM WorkStep
			WHERE ParentRecordId = :workOrderId
			AND Name = :name
			LIMIT 1
		];
        
        if (!steps.isEmpty()) {
            WorkStep ws = steps[0];
            ws.Status = 'Completed'; // Or whatever picklist value you use
            update ws;
        }
    }
}