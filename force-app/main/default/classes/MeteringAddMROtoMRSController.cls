/**
 * @description       :
 * @author            : Kartik Patkar Appstrail
 * @group             :
 * @last modified on  : 09-01-2026
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   29-09-2025   Kartik Patkar, Appstrail   Initial Version
 **/
public without sharing class MeteringAddMROtoMRSController {
    
    @AuraEnabled
    public static List<Meter_Reading_Order__c> getMeterReadingOrderList(Integer limitValue, Integer offset){
        return [SELECT Id, Customer__c, Meter_Reading_Date__c, Scheduled_Meter_Reading_Date__c, MRU__c,Name,
                    Customer_Location__c,Customer_Road_Name__c,Building__c,Customer_Postal_Code__c,Meter_Reading_Doc_Number__c,
                    Customer_Category__c,Agent__c,Scheduled_Meter_Reading_End_Date__c,Meter_Reader_Name__c,Business_Partner_Consumer_ID__c
                FROM Meter_Reading_Order__c 
                WHERE Created_Order__c=FALSE AND Customer__c != null
                LIMIT :limitValue 
                OFFSET :offset];
    }
    
    @AuraEnabled
    public static Meter_Reading_Schedule__c getCurrentMRURecord(String recordId){
        try {
            List<Meter_Reading_Schedule__c> listMRU=[SELECT Id,MRS_Custom_Name__c,Agency__c,Agent__c,Meter_Reading_Start_Date__c,
                                                        Meter_Reading_Completion_Date__c 
                                                    FROM Meter_Reading_Schedule__c 
                                                    WHERE Id=:recordId LIMIT 1];
            if(!listMRU.isEmpty()){
                return listMRU[0];
            }
            return null;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static string addMRO(List<Meter_Reading_Order__c> listMROs,Meter_Reading_Schedule__c mruRec){
        try {
            List<WorkOrder> listWorkOrders=new List<WorkOrder>();
            String meteringRecordTypeId = Schema.getGlobalDescribe().get('WorkOrder').getDescribe().getRecordTypeInfosByDeveloperName().get('MGL_Metering').getRecordTypeId();
            if(!listMROs.isEmpty()){
                
                Set<String> setMRU = new Set<String>();
                Set<Id> setAccountId=new Set<Id>();
                Set<Id> setPortionsId = new Set<Id>();
                for(Meter_Reading_Order__c mroRec:listMROs){
                    setMRU.add(mroRec.MRU__c);
                    setAccountId.add(mroRec.Customer__c);
                }
                
                // Fetch Meter Reading Units and their Portions
                Map<String, Meter_Reading_Unit__c> mapMruCodeVSRecord = new Map<String, Meter_Reading_Unit__c>();
                for(Meter_Reading_Unit__c mruMasterRec:[SELECT Id, Name,Portion__c FROM Meter_Reading_Unit__c 
                                                    WHERE Name IN :setMRU AND Portion__c!=null]) {
                    
                    setPortionsId.add(mruMasterRec.Portion__c);
                    if(!mapMruCodeVSRecord.containsKey(mruMasterRec.Name)) {
                        mapMruCodeVSRecord.put(mruMasterRec.Name, mruMasterRec);
                    }
                }
                
                // Contact records for Person Accounts
                Map<Id,Contact> mapAccountIdVSContactRec=new Map<Id,Contact>();
                for(Contact contactRec:[SELECT Id,AccountId FROM Contact WHERE AccountId IN:setAccountId 
                                            AND AccountId!=null AND IsPersonAccount=TRUE]){
                    if(!mapAccountIdVSContactRec.containsKey(contactRec.AccountId)){
                        mapAccountIdVSContactRec.put(contactRec.AccountId,contactRec);
                    }
                }

                Meter_Reading_Schedule__c mrs=new Meter_Reading_Schedule__c();
                mrs.Id=mruRec.Id;
                mrs.Status__c='Pending';
                update mrs;
                
                for(Meter_Reading_Order__c mroRec:listMROs){
                    WorkOrder workOrderRec = new WorkOrder();
                    workOrderRec.Meter_Reading_Order__c = mroRec.Id;
                    workOrderRec.Meter_Reading_Schedule__c = mruRec.Id;
                    workOrderRec.AccountId = mroRec.Customer__c;
                    workOrderRec.StartDate = mruRec.Meter_Reading_Start_Date__c;
                    workOrderRec.EndDate = mruRec.Meter_Reading_Completion_Date__c;
                    workOrderRec.Status = 'New';
                    workOrderRec.Subject = 'Meter Reading for ' + mroRec.Name;
                    workOrderRec.RecordTypeId = meteringRecordTypeId;
                    workOrderRec.MRU__c = mroRec.MRU__c;
                    workOrderRec.Work_Order_Type__c='Scheduled';
                    workOrderRec.Location__c = mroRec.Customer_Location__c;
                    workOrderRec.Road_Name__c = mroRec.Customer_Road_Name__c;
                    workOrderRec.Building_Name__c = mroRec.Building__c;
                    workOrderRec.Postal_Code__c = mroRec.Customer_Postal_Code__c;
                    workOrderRec.Meter_Reading_Doc_Number__c = mroRec.Meter_Reading_Doc_Number__c;
                    workOrderRec.BP_Category__c = mroRec.Customer_Category__c;
                    workOrderRec.Meter_Reader_Name__c = mroRec.Meter_Reader_Name__c;
                    workOrderRec.Scheduled_Date__c = mruRec.Meter_Reading_Start_Date__c;
                    workOrderRec.Assigned_Meter_Reader__c = mruRec.Agent__c;
                    workOrderRec.Metering_Agency__c = mruRec.Agency__c;
                    workOrderRec.ServiceTerritoryId = mruRec.Agency__c;
                    if(mapAccountIdVSContactRec.containsKey(workOrderRec.AccountId)){
                        workOrderRec.contactId=mapAccountIdVSContactRec.get(workOrderRec.AccountId).Id;
                    }
                    if(mapMruCodeVSRecord.containsKey(workOrderRec.MRU__c)) {
                        workOrderRec.Portion__c = mapMruCodeVSRecord.get(workOrderRec.MRU__c).Portion__c;
                        workOrderRec.Meter_Reading_Unit__c = mapMruCodeVSRecord.get(workOrderRec.MRU__c).Id;
                    }
                    listWorkOrders.add(workOrderRec);

                    mroRec.Created_Order__c = true;
                }
                update listMROs;

                // Enable bypass
                Metering_Bypass_Validation__c bs = Metering_Bypass_Validation__c.getInstance(UserInfo.getUserId());
                if (bs == null) {
                    bs = new Metering_Bypass_Validation__c();
                    bs.SetupOwnerId = UserInfo.getUserId();
                }
                bs.Bypass__c = true;
                upsert bs;
                
                if(!listWorkOrders.isEmpty()){
                    insert listWorkOrders;
                }

                mrs.Status__c='Approved';
                update mrs;

                // Disable bypass
                bs.Bypass__c = false;
                upsert bs;
                return 'success';
            }
            return 'No MROs found';
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage()+':::'+e.getLineNumber());
        }
    }
}