global class UpdateAccountDispenserOnApproval implements Database.Batchable<SObject> {
    
    public String query='SELECT Id, WorkOrderNumber, CreatedDate, AccountId, Meter_Reading__c, Customer_BP_Number__c,'+
                            'Assigned_Meter_Reader__c, Scheduled_Date__c, Customer_Category__c,'+
                            'Meter_Reading_Order__c, Meter_Reading_Schedule__c, MRU__c, Appointment_Status__c, BP_Number__c,'+
                            'Metering_Agency__c, Portion__c, Meter_Reading_Unit__c, Building_Name__c, Postal_Code__c, '+
                            'Location__c, Road_Name__c '+
                        'FROM WorkOrder WHERE Account.Category__c =\'CNG/LNG\' AND Approval_Status__c =\'Approved\' ORDER BY CreatedDate ASC ';

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Id> listWorkOrderIds=new List<Id>();
        for(WorkOrder wo:(List<WorkOrder>)scope){
            if(!listWorkOrderIds.contains(wo.Id)){
                listWorkOrderIds.add(wo.Id);
            }
        }
        
        if(!listWorkOrderIds.IsEmpty()){
            UpdateAccountDispenserOnApproval.updateMeterReadings(listWorkOrderIds);
        }
    }
    
    public static void updateMeterReadings(List<Id> workOrderIds){
        List<Dispenser_Point__c> dispenserPoints = [select id,Account_Dispensor__c,Closing_Reading__c from Dispenser_Point__c where Live__c = true and WorkOrderID__c IN:workOrderIds order by WorkOrderID__c, CreatedDate ASC];

        Map<Id, Dispenser_Point__c> accDispPointMap = new Map<Id, Dispenser_Point__c>();

        if(!dispenserPoints.isEmpty()){
            for (Dispenser_Point__c dp : dispenserPoints) {
                if (!accDispPointMap.containsKey(dp.Account_Dispensor__c)) {
                    accDispPointMap.put(dp.Account_Dispensor__c, dp);
                }
            }
        }

        if(!accDispPointMap.isEmpty()){
            List<Account_Dispensor__c> accDispensers = [select id,Closing_Reading__c from Account_Dispensor__c where id IN:accDispPointMap.keyset()];


            for(Account_Dispensor__c accDisp:accDispensers){
                accDisp.SCADA_Closing_Reading__c = accDisp.Closing_Reading__c??.0;
                accDisp.Opening_Reading__c = accDispPointMap.get(accDisp.id).Closing_Reading__c;
                accDisp.Closing_Reading__c = accDispPointMap.get(accDisp.id).Closing_Reading__c;
            }

            if(!accDispensers.isEmpty()){
                update accDispensers;
            }
        }
    }

    global void finish(Database.BatchableContext bc) {
        // Optional logging or chaining
    }

}