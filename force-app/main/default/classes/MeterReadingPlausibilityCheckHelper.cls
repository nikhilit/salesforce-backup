/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 16-10-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   17-09-2025   Kartik Patkar, Appstrail   Initial Version
**/
public without sharing class MeterReadingPlausibilityCheckHelper {
    
    /**
    * @description 
    * @author Kartik Patkar, Appstrail | 23-09-2025 
    * @param Decimal previousReading 
    * @param Decimal currentReading 
    * @param Date lastReadingDate 
    * @param Decimal averageConsumption 
    * @return Map<String, Object> 
    **/
    @AuraEnabled
    public static Map<String,Object> plausibilityCheckLogic(Decimal previousReading, Decimal currentReading, Date lastReadingDate, Decimal averageConsumption) {
        Map<String,Object> result = new Map<String,Object>{'valid' => true, 'message' => '', 'check' => 'Plausible'};
        if (previousReading != null && currentReading != null) {
            if (previousReading > currentReading) {
                result.put('valid', false);
                result.put('message', 'Negative consumption');
                result.put('check', 'Negative');
                return result;
            }

            if(previousReading == currentReading){
                result.put('valid', false);
                result.put('message', 'Zero consumption');
                result.put('check', 'Zero');
                return result;
            }

            if(lastReadingDate != null){
                Integer daysDiff = lastReadingDate.daysBetween(Date.today());
                System.debug(daysDiff+'daysDiff');
                System.debug(averageConsumption+'averageConsumption');
                Decimal consumption = currentReading - previousReading;
                Decimal highThreshold = 2 * (averageConsumption * daysDiff); 
                Decimal lowThreshold = 0.25 * (averageConsumption * daysDiff);

                if (consumption > highThreshold) {     
                    result.put('valid', false);
                    result.put('message', 'High consumption');
                    result.put('check', 'High');
                    return result;
                }
                if (consumption < lowThreshold) {
                    result.put('valid', false);
                    result.put('message', 'Low consumption');
                    result.put('check', 'Low');
                    return result;
                }
            }
        }
        return result;
        
    }

    /**
    * @description 
    * @author Kartik Patkar, Appstrail | 23-09-2025 
    * @param List<WorkOrder> newList 
    * @param Map<Id WorkOrder> oldMap 
    **/
    public static void checkWorkOrderPlausibility(List<WorkOrder> newList, Map<Id, WorkOrder> oldMap){
        String meteringRecordType = Schema.getGlobalDescribe().get('WorkOrder').getDescribe().getRecordTypeInfosByDeveloperName().get('MGL_Metering').getRecordTypeId();
        Set<String> setCategory=new Set<String>{'Domestic','Non-MRS Commercial'};
        
        for(WorkOrder wo : newList){
            if(wo.RecordTypeId == meteringRecordType && setCategory.contains(wo.Customer_Category__c)  
                && wo.Appointment_Status__c == 'Completed' && (oldMap==null || oldMap.get(wo.Id).Appointment_Status__c != wo.Appointment_Status__c)){
                Decimal previousReading = (wo.Previous_Meter_Reading__c!=null)?Decimal.valueOf(wo.Previous_Meter_Reading__c.replaceAll(',', '')):0;
                Decimal currentReading = (wo.Current_Meter_Reading__c!=null)?Decimal.valueOf(wo.Current_Meter_Reading__c):0;
                Decimal averageConsumption = (wo.Average_Consumption__c!=null)?wo.Average_Consumption__c:0;
                Map<String,Object> result = plausibilityCheckLogic(previousReading, currentReading, wo.Last_Meter_Reading_Date__c, averageConsumption);
                if(result.get('valid') == true){
                    wo.Implausible__c = false;
                    wo.Plausibility_Check_Remark__c = (String)result.get('check');
                }else{
                    wo.Implausible__c = true;
                    wo.Implausibility_Check__c = (String)result.get('check');
                    wo.Plausibility_Check_Remark__c = (String)result.get('message');
                }
            }
        }
    }

}