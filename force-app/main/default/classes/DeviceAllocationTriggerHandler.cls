public class DeviceAllocationTriggerHandler {

    public static void handleInactiveAllocations(List<Device_Allocation__c> newList, Map<Id, Device_Allocation__c> oldMap) {

        Set<String> installationNumbers = new Set<String>();

        // Collect Device_Allocation__c records to process
        for (Device_Allocation__c da : newList) {
            Boolean isNew = (oldMap == null || !oldMap.containsKey(da.Id));
            Boolean inactiveChangedToTrue = false;

            if (!isNew) {
                Device_Allocation__c oldDa = oldMap.get(da.Id);
                inactiveChangedToTrue = (oldDa.Inactive__c == 'false' && da.Inactive__c == 'true');
            }

            // If inactive is false or changed from true → false
            if (da.Inactive__c == 'true' || inactiveChangedToTrue) {
                 if (da.Installation_Number__c != null) {
                    installationNumbers.add(da.Installation_Number__c);
                }
                // Clear installation fields directly (allowed in before trigger)
                da.Installation__c = null;
                da.Installation_Number__c = null;

               
            }
        }

        if (installationNumbers.isEmpty()) return;

        // Get related BP Numbers from Move_In_Out__c
        Set<String> bpNumbers = new Set<String>();
        for (Move_In_Out__c mio : [
           SELECT Business_Partner__c
            FROM Move_In_Out__c
            WHERE Installation__c IN :installationNumbers
            AND Move_Out__c != NULL
            ORDER BY Move_Out__c DESC]){
            if (mio.Business_Partner__c != null) {
                bpNumbers.add(mio.Business_Partner__c);
            }
        }

        if (bpNumbers.isEmpty()) return;

        // Fetch Accounts related to those BP Numbers
        List<Account> accountsToUpdate = new List<Account>();
        for (Account acc : [
            SELECT Id, Meter_Number__c
            FROM Account
            WHERE BP_Number__c IN :bpNumbers
        ]) {
            acc.Meter_Number__c = null;
            accountsToUpdate.add(acc);
        }

        // Safe DML on related Accounts
        if (!accountsToUpdate.isEmpty()) {
            try {
                update accountsToUpdate;
            } catch (DmlException e) {
                System.debug('Error updating accounts in DeviceAllocationTriggerHandler: ' + e.getMessage());
            }
        }
    }
}