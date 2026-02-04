/**
 * @description       :
 * @author            : Kartik Patkar Appstrail
 * @group             :
 * @last modified on  : 06-11-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   23-05-2025   Kartik Patkar, Appstrail   Initial Version
 **/
public class AccountTriggerHandler {    
    public static void fillName(List<Account> newList, Map<Id, Account> oldMap) {
        String gsRecordTypeID = Schema.getGlobalDescribe()
            .get('Account').getDescribe()
            .getRecordTypeInfosByDeveloperName()
            .get('Agency_Account').getRecordTypeId();

        String bsRecordTypeID = Schema.getGlobalDescribe()
            .get('Account').getDescribe()
            .getRecordTypeInfosByDeveloperName()
            .get('Business_Account').getRecordTypeId();

        for (Account acc : newList) {
            Boolean isNew = (oldMap == null || !oldMap.containsKey(acc.Id));
            Boolean drsChanged = false;
            Boolean connectionChanged = false;
            Boolean nameFieldsChanged = false;

            if(acc.Category__c=='CNG/LNG' || acc.Category__c=='MRS'){
                continue;
            }

            if (!isNew) {
                Account oldAcc = oldMap.get(acc.Id);

                // Compare DRS and Connection fields
                drsChanged = acc.DRS__c != oldAcc.DRS__c;
                connectionChanged = acc.Connection__c != oldAcc.Connection__c;

                // Compare name-building fields
                nameFieldsChanged = acc.Full_Name__c != oldAcc.Full_Name__c
                    || acc.BP_Number__c != oldAcc.BP_Number__c
                    || acc.FirstName__c != oldAcc.FirstName__c
                    || acc.Middle_Name__c != oldAcc.Middle_Name__c
                    || acc.LastName__c != oldAcc.LastName__c;
            }

            // Mark for processing if new OR drs/connection changed OR any of them is null
            if (isNew || drsChanged || connectionChanged 
                || acc.DRS__c == null || acc.Connection__c == null) {
                acc.To_be_processed__c = true;
            }

            // Rebuild name if new OR relevant name fields changed
            if (isNew || nameFieldsChanged) {
                String namePart = '';

                if (acc.Full_Name__c != null) {
                    namePart += acc.Full_Name__c;
                } else {
                    // Build name from FirstName__c, Middle_Name__c, and LastName__c
                    if (acc.FirstName__c != null) {
                        namePart += acc.FirstName__c;
                    }
                    
                    if (acc.Middle_Name__c != null) {
                        if (!namePart.equals('')) {
                            namePart += ' ';
                        }
                        namePart += acc.Middle_Name__c;
                    }
                    
                    if (acc.LastName__c != null) {
                        if (!namePart.equals('')) {
                            namePart += ' ';
                        }
                        namePart += acc.LastName__c;
                    }
                }
                
                if (acc.BP_Number__c != null) {
                    if (!namePart.equals('')) {
                        namePart += ' - ';
                    }
                    namePart += acc.BP_Number__c;
                }

                if (!namePart.equals('')) {
                    if (acc.RecordTypeId != gsRecordTypeID) {
                        if (acc.RecordTypeId == bsRecordTypeID) {
                            acc.Name = namePart;
                        } else {
                            if (namePart.length() > 80) {
                                acc.LastName = namePart.substring(0, 79);
                            } else {
                                acc.LastName = namePart;
                            }
                        }
                    } 
                }
            }
        }
    }
    public static void handleInsert(List<Account> newAccounts) {
        List<Account_Dispensor__c> dispensersToCreate = new List<Account_Dispensor__c>();

        for (Account acc : newAccounts) {
            Decimal dispenserCount = acc.No_of_Dispensers__c;
            for (Decimal i = 1; i <= dispenserCount; i++) {
                dispensersToCreate.add(new Account_Dispensor__c(
                    Name = 'Point_' + i,
                    Business_Partner__c=acc.Id
                ));
            }
        }

        if (!dispensersToCreate.isEmpty()) {
            insert dispensersToCreate;
        }
    }
    
    public static void handleUpdate(List<Account> newList, Map<Id, Account> oldMap) {
        List<Account_Dispensor__c> dispensersToCreate = new List<Account_Dispensor__c>();

        // Query existing dispensers to find the last number per account
        Map<Id, Integer> accountMaxPointNumMap = new Map<Id, Integer>();
        for (Account_Dispensor__c disp : [
            SELECT Name, Business_Partner__c
            FROM Account_Dispensor__c
            WHERE Business_Partner__c IN :newList
        ]) {
            Integer num = 0;
            if (disp.Name != null && disp.Name.startsWith('Point_')) {
                String suffix = disp.Name.replace('Point_', '');
                // ✅ Apex way to check numeric
                if (Pattern.matches('^[0-9]+$', suffix)) {
                    num = Integer.valueOf(suffix);
                }
            }
            Integer currentMax = accountMaxPointNumMap.get(disp.Business_Partner__c);
            accountMaxPointNumMap.put(
                disp.Business_Partner__c,
                currentMax == null ? num : Math.max(currentMax, num)
            );
        }
        
        for (Account acc : newList) {
            Account oldAcc = oldMap.get(acc.Id);

            Decimal oldCount = oldAcc.No_of_Dispensers__c;
            Decimal newCount = acc.No_of_Dispensers__c;
            if (oldCount == null) oldCount = 0;
            if (newCount == null) newCount = 0;

            if (newCount > oldCount) {
                Decimal additional = newCount - oldCount;
                Integer startIndex = accountMaxPointNumMap.containsKey(acc.Id)
                    ? accountMaxPointNumMap.get(acc.Id) + 1
                    : 1;

                for (Integer i = 0; i < additional; i++) {
                    dispensersToCreate.add(new Account_Dispensor__c(
                        Name = 'Point_' + (startIndex + i),
                        Business_Partner__c = acc.Id
                    ));
                }
            }
        }

        if (!dispensersToCreate.isEmpty()) {
            insert dispensersToCreate;
        }
    }
    public static void updateBillingLatLong(List<Account> newList, Map<Id, Account> oldMap) {
        for (Account acc : newList) {
            Boolean isNew = (acc.Id == null);
            Boolean geoChanged = false;
            if (isNew) {
                geoChanged = (acc.Geolocation__Longitude__s != null && acc.Geolocation__Latitude__s!=null);
            } else {
                Account oldAcc = oldMap.get(acc.Id);
                geoChanged = ((acc.Geolocation__Longitude__s != oldAcc.Geolocation__Longitude__s) && (acc.Geolocation__Latitude__s != oldAcc.Geolocation__Latitude__s));
            }
            if (geoChanged) {
                acc.BillingLatitude  = acc.Geolocation__Latitude__s;
                acc.BillingLongitude = acc.Geolocation__Longitude__s;
            }
        }
    }

    public static void lastModifiedBySAP(List<Account> newList) {
        // Username of SAP Automated User
        String SAP_USER_NAME = 'Automated User';

        if (UserInfo.getName() != SAP_USER_NAME) {
            return;
        }

        Datetime nowDt = System.now();

        for (Account acc : newList) {
            acc.Last_Modified_By_SAP__c = nowDt;
        }
    }


}