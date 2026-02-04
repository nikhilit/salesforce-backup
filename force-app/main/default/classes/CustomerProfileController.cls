/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 02-01-2026
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   19-12-2025   Kartik Patkar, Appstrail   Initial Version
**/
public with sharing class CustomerProfileController {
    @AuraEnabled(cacheable=true)
    public static CustomerProfileWrapper getCustomerProfile(Id workOrderId) {
        CustomerProfileWrapper wrapper = new CustomerProfileWrapper();

        try {
            List<WorkOrder> woList = [
                SELECT Id, AccountId 
                FROM WorkOrder 
                WHERE Id = :workOrderId 
                LIMIT 1
            ];
            if (woList.isEmpty()) return wrapper;

            Id accountId = woList[0].AccountId;

            List<Account> accList = [
                SELECT Id, Name, BP_Number__c, CA_Number__c, Dispenser_Number__c, Category__c,Geolocation__latitude__s, Geolocation__longitude__s,
                       Road_name__c, Location__c, Floor__c, Flat__c, Building_name__c,Geolocation__c
                FROM Account 
                WHERE Id = :accountId AND Category__c = 'CNG/LNG' 
                LIMIT 1
            ];
            if (accList.isEmpty()) return wrapper;

            Metering_GEO_Fence_Config__mdt geoFenceConfig=[SELECT Id,For_CNG__c,For_CNG_Distance_in_Meter__c,For_Domestic__c,
                                                                For_Domestic_Distance_in_Meter__c,For_MRS__c,
                                                                For_MRS_Distance_in_Meter__c,For_Non_MRS_Distance_in_Meter__c
                                                            FROM Metering_GEO_Fence_Config__mdt 
                                                            WHERE Active__c=true LIMIT 1];

            Account acc = accList[0];

            wrapper.customerName = acc.Name;
            wrapper.bpNumber = acc.BP_Number__c;
            wrapper.caNumber = acc.CA_Number__c;
            wrapper.dispenserNumber = acc.Dispenser_Number__c;
            wrapper.location = acc.Building_name__c + ', ' + acc.Flat__c + ', ' +
                               acc.Floor__c + ' ' + acc.Location__c + ' ' + acc.Road_name__c;
            wrapper.geoFenceConfig = geoFenceConfig;
            wrapper.account = acc;
            if (acc.Geolocation__c != null) {
                wrapper.actualLatitude = acc.Geolocation__latitude__s;
                wrapper.actualLongitude = acc.Geolocation__longitude__s;
            }
        }
        catch (Exception e) {
            System.debug('Error fetching customer profile: ' + e.getMessage());
        }

        return wrapper;
    }

    @AuraEnabled
    public static CustomerProfileWrapper getLocationInfo(Id workOrderId) {
        CustomerProfileWrapper wrapper = new CustomerProfileWrapper();

        try {
            List<WorkOrder> woList = [
                SELECT Id, AccountId 
                FROM WorkOrder 
                WHERE Id = :workOrderId 
                LIMIT 1
            ];
            if (woList.isEmpty()) return wrapper;

            Id accountId = woList[0].AccountId;

            List<Account> accList = [
                SELECT Id, Name, BP_Number__c, CA_Number__c, Dispenser_Number__c, Category__c,Geolocation__latitude__s, Geolocation__longitude__s,
                       Road_name__c, Location__c, Floor__c, Flat__c, Building_name__c,Geolocation__c
                FROM Account 
                WHERE Id = :accountId AND Category__c = 'CNG/LNG' 
                LIMIT 1
            ];
            if (accList.isEmpty()) return wrapper;

            Metering_GEO_Fence_Config__mdt geoFenceConfig=[SELECT Id,For_CNG__c,For_CNG_Distance_in_Meter__c,For_Domestic__c,
                                                                For_Domestic_Distance_in_Meter__c,For_MRS__c,
                                                                For_MRS_Distance_in_Meter__c,For_Non_MRS_Distance_in_Meter__c
                                                            FROM Metering_GEO_Fence_Config__mdt 
                                                            WHERE Active__c=true LIMIT 1];

            Account acc = accList[0];

            wrapper.customerName = acc.Name;
            wrapper.bpNumber = acc.BP_Number__c;
            wrapper.caNumber = acc.CA_Number__c;
            wrapper.dispenserNumber = acc.Dispenser_Number__c;
            wrapper.location = acc.Building_name__c + ', ' + acc.Flat__c + ', ' +
                               acc.Floor__c + ' ' + acc.Location__c + ' ' + acc.Road_name__c;
            wrapper.geoFenceConfig = geoFenceConfig;
            wrapper.account = acc;
            if (acc.Geolocation__c != null) {
                wrapper.actualLatitude = acc.Geolocation__latitude__s;
                wrapper.actualLongitude = acc.Geolocation__longitude__s;
            }
        }
        catch (Exception e) {
            System.debug('Error fetching customer profile: ' + e.getMessage());
        }

        return wrapper;
    }

    public class CustomerProfileWrapper {
        @AuraEnabled public String customerName;
        @AuraEnabled public String bpNumber;
        @AuraEnabled public String caNumber;
        @AuraEnabled public String dispenserNumber;
        @AuraEnabled public String location;
        @AuraEnabled public Decimal actualLatitude;
        @AuraEnabled public Decimal actualLongitude;
        @AuraEnabled public Metering_GEO_Fence_Config__mdt geoFenceConfig;
        @AuraEnabled public Account account;
    }
}