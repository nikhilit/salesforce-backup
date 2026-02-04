/**
 * @description       : 
 * @author            : Shashank.shekhar@appstrail.com
 * @group             : 
 * @last modified on  : 06-25-2025
 * @last modified by  : Shashank.shekhar@appstrail.com
**/
public with sharing class iCAccount360Controller {
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getAccountInfoFromSA(Id workOrderId) {
        System.debug('Start: getAccountInfoFromSA called with Work Order Id: ' + workOrderId);
        
        try {
            if (workOrderId == null) {
                throw new AuraHandledException('Work Order Id is null');
            }

            // Fetch WorkOrder with related Account
            WorkOrder wo = [
                SELECT Id, AccountId, Customer_BP_Number__c, CA_Number__c, Invoice__c, Customer_Name__c, Due_Amount__c,
                       Outstanding_Amount__c, New_Road_Name__c, New_Landmark__c, New_Location__c, City__c, 
                       Postal_Code__c, New_Mobile_Number__c, Phone__c, Email_ID__c, Meter_No_SR__c, Billing_portion__c, 
                       MRU__c, Bill_Date__c, StartDate, EndDate, Payment_Mode__c, Follow_up_Remarks__c, Follow_up_Date__c,
                       Amount_Received__c
                FROM WorkOrder
                WHERE Id = :workOrderId
                LIMIT 1
            ];
            
            if (wo.AccountId == null) {
                throw new AuraHandledException('No Account associated with this Work Order.');
            }

            // Fetch Account details
            Account acc = [
                SELECT Id, Name, Phone, Secondary_Telephone__c, Account_Email__c,
                       Account_Type__c, Type, MRU_Code__c, BP_Number__c, CA_Number__c,
                       Building_name__c, Street__c, Colony__c, Wing__c,
                       Floor__c, Flat__c, Road_name__c, Street_Line_2__c, Room__c, Street_Line_5__c, Street_Line_3__c,
                        Landmark__c, Location__c, Postal_Code__c, Plot__c, District__c, City__c
                FROM Account
                WHERE Id = :wo.AccountId
                LIMIT 1
            ];

            // Fetch related Service Appointment(s)
            List<ServiceAppointment> saList = [
                SELECT Id, ParentRecordId, SchedStartTime, SchedEndTime, 
                       Follow_up_Remarks__c, Status
                FROM ServiceAppointment
                WHERE ParentRecordId = :workOrderId
            ];

            String detailAccountSummary;

            detailAccountSummary = formatAddress(
                String.isNotBlank(acc.Building_name__c) ? acc.Building_name__c : '',
            String.isNotBlank(acc.Flat__c) ? acc.Flat__c : '',
            String.isNotBlank(acc.Floor__c) ? acc.Floor__c : '',
            String.isNotBlank(acc.Wing__c) ? acc.Wing__c : '',
            String.isNotBlank(acc.Plot__c) ? acc.Plot__c : '',
            String.isNotBlank(acc.Street_Line_5__c) ? acc.Street_Line_5__c : '',
            String.isNotBlank(acc.Landmark__c) ? acc.Landmark__c : '',
            String.isNotBlank(acc.Colony__c) ? acc.Colony__c : '',
            String.isNotBlank(acc.Location__c) ? acc.Location__c : '',
            String.isNotBlank(acc.City__c) ? acc.City__c : '',
            String.isNotBlank(acc.District__c) ? acc.District__c : '',
            String.isNotBlank(acc.Postal_Code__c) ? acc.Postal_Code__c : ''
                );

            // Return both Account and Service Appointment(s)
            return new Map<String, Object>{
                'acc' => acc,
                'workOrder' => wo,
                'serviceAppointments' => saList,
                'detailAccountSummary' => detailAccountSummary
            };

        } catch (Exception ex) {
            System.debug('Exception caught: ' + ex.getMessage());
            System.debug('Exception Line Number: ' + ex.getLineNumber());
            System.debug('Exception Stack Trace: ' + ex.getStackTraceString());
            throw new AuraHandledException('Apex error: ' + ex.getMessage());
        }
    }

    // Helper method to format address
    private static String formatAddress(
        String building,
    String flat,
    String floor,
    String wing,
    String plot,
    String road,
    String landmark,
    String colony,
    String location,
    String city,
    String district,
    String postalCode
    ) {
        List<String> parts = new List<String>();
        if (String.isNotBlank(building)) parts.add(building);
        if (String.isNotBlank(flat)) parts.add(flat);
        if (String.isNotBlank(floor)) parts.add(floor);
        if (String.isNotBlank(wing)) parts.add(wing);
        if (String.isNotBlank(plot)) parts.add(plot);
        if (String.isNotBlank(road)) parts.add(road);
        if (String.isNotBlank(landmark)) parts.add(landmark);
        if (String.isNotBlank(colony)) parts.add(colony);
        if (String.isNotBlank(location)) parts.add(location);
        if (String.isNotBlank(city)) parts.add(city);
        if (String.isNotBlank(district)) parts.add(district);
        if (String.isNotBlank(postalCode)) parts.add(postalCode);
        
        return parts.isEmpty() ? 'No address available' : String.join(parts, ', ');
    }
}