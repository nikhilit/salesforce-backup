/**
 * @description       :
 * @author            : Kartik Patkar Appstrail
 * @group             :
 * @last modified on  : 08-10-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   09-09-2025   Kartik Patkar, Appstrail   Initial Version
 **/
public without sharing class UpdateCustomerDataMappingBatch implements Database.Batchable<sObject>, Database.Stateful{
    
    public String query='SELECT Id,Meter_Number__c,Location__c,Road_name__c,Building_name__c,Other_City__c,Street_Line_5__c,Building_Name_Conn__c,Landmark__c,Street_Line_2__c,Street__c,Society_Name__c,'+
                            'Connection__r.Street_3__c,Connection__c,Flat__c,Room__c,Connection__r.House_Number__c,Plot__c,City__c,Postal_Code__c,Connection__r.Region_Name__c,'+
                            'Type_Desc__c,Category__c '+
                        ' FROM Account'+
                        ' WHERE Category__c = \'Domestic\' OR Category__c = \'Non-MRS Commercial\'';
    
    public UpdateCustomerDataMappingBatch() {}
    
    public UpdateCustomerDataMappingBatch(String query) {
        this.query = query;
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<Account> scope) {
        
        Set<Id> setAccountIds = new Set<Id>();
        for(Account acc : scope){
            setAccountIds.add(acc.Id);
        }
        
        Map<Id,Id> mapAccIdInstId = new Map<Id,Id>();
        for(Move_In_Out__c mio : [SELECT Id,BP_Number__c,Installation__c,Installation_Name__c 
                                    FROM Move_In_Out__c 
                                    WHERE BP_Number__c !=null AND Installation_Name__c!=null 
                                        AND BP_Number__c IN : setAccountIds]){
            mapAccIdInstId.put(mio.BP_Number__c, mio.Installation_Name__c);
        }
        
        Map<Id,Device_Allocation__c> mapInstIdDeviceAlloc = new Map<Id,Device_Allocation__c>();
        if(!mapAccIdInstId.values().isEmpty()){
            for(Device_Allocation__c deviceAlloc:[SELECT Id,Device__r.Name,Installation__c,Device__r.Manuf_Serial_No__c
                                                    FROM Device_Allocation__c WHERE Device__c !=null AND Installation__c!=null
                                                        AND Installation__c IN : mapAccIdInstId.values()]){
                
                mapInstIdDeviceAlloc.put(deviceAlloc.Installation__c, deviceAlloc);
            }
        }
        
        List<Account> listAccToUpdate = new List<Account>();
        Set<String> setDomesticTypes = new Set<String>{'MGL Domestic Customer'};
        for(Account acc : scope){
            acc.Location__c = acc.Other_City__c;
            acc.Road_name__c = acc.Street_Line_5__c;
            acc.Building_name__c = acc.Building_Name_Conn__c;
            acc.Flat__c = acc.Room__c;
            acc.Colony__c = acc.Street_Line_2__c;
            acc.Society_Name__c = acc.Street__c;
            if(acc.Type_Desc__c != null && setDomesticTypes.contains(acc.Type_Desc__c)) {
                acc.Category__c = 'Domestic';
            }
            if(acc.Connection__c!=null){
                acc.Landmark__c = acc.Connection__r.Street_3__c;
                acc.Plot__c = acc.Connection__r.House_Number__c;
                acc.BillingState = acc.Connection__r.Region_Name__c;
            }
            if(mapAccIdInstId.containsKey(acc.Id) && mapInstIdDeviceAlloc.containsKey(mapAccIdInstId.get(acc.Id))){
                acc.Meter_Number__c = mapInstIdDeviceAlloc.get(mapAccIdInstId.get(acc.Id)).Device__r.Manuf_Serial_No__c;
            }else{
                acc.Meter_Number__c = '';
            }
            acc.BillingStreet = generateAddress(acc.Plot__c, acc.Building_name__c, acc.Colony__c, acc.Road_name__c, acc.Landmark__c, acc.Location__c);
            acc.BillingCity = acc.City__c;
            acc.BillingPostalCode = acc.Postal_Code__c;
            acc.BillingCountry = 'India';
            listAccToUpdate.add(acc);
        }
        
        if(!listAccToUpdate.isEmpty()){
            update listAccToUpdate;
        }
    }

    public static String generateAddress(String plot,String buildingName,String colony,String roadName,String landmark,String location){
        String address='';
        if(plot!=null) address+=plot+', ';
        if(buildingName!=null) address+=buildingName+', ';
        if(colony!=null) address+=colony+', ';
        if(roadName!=null) address+=roadName+', ';
        if(landmark!=null) address+=landmark+', ';
        if(location!=null) address+=location;
        
        if(address.endsWith(', ')){
            address=address.substring(0,address.length()-2);
        }
        return address;
    }
    
    public void finish(Database.BatchableContext BC) {
        // Optional: Add any post-processing logic here
    }
}