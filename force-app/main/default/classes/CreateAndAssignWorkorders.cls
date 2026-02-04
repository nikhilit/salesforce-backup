public with sharing class CreateAndAssignWorkorders {

    public static void assignWorkOrders(
        List<WorkOrderAllocation__c> allocList,
        Map<String, Id> mapKeyAgentId,
        Map<Id, Integer> agencyCapacityTracker
    ) {
        if (allocList.isEmpty()) {
            System.debug('Exiting: allocList is empty');
            return;
        }

        String meteringRecordTypeId = Schema.getGlobalDescribe().get('WorkOrder').getDescribe()
            .getRecordTypeInfosByDeveloperName().get('MGL_R_T').getRecordTypeId();
        String agencyRecordTypeId = Schema.getGlobalDescribe().get('ServiceTerritory').getDescribe()
            .getRecordTypeInfosByDeveloperName().get('R_T').getRecordTypeId();

        Set<String> bpNumbers = new Set<String>();
        Set<String> customerWorkTypes = new Set<String>();

        for (WorkOrderAllocation__c alloc : allocList) {
            bpNumbers.add(alloc.BP_Numbers__c);
            if (alloc.RT_Customer_work_Type__c != null) {
                customerWorkTypes.add(alloc.RT_Customer_work_Type__c);
            }
        }

        Map<String, Account> bpToAccountMap = getAccountsByBP(bpNumbers);
        Map<String, WorkType> workTypeMap = getWorkTypes(customerWorkTypes);

        Map<Id, Id> agencyToUserMap = new Map<Id, Id>();
        Map<Id, List<Id>> drsToAgencyMap = new Map<Id, List<Id>>();
        Map<Id, Decimal> agencyToCapacityMap = new Map<Id, Decimal>();
        Map<Id, String> agencyToCustomerTypeMap = new Map<Id, String>();

        Set<Id> drsIds = new Set<Id>();
        for (Account acc : bpToAccountMap.values()) {
            if (acc.DRS_Master__c != null) {
                drsIds.add(acc.DRS_Master__c);
            }
        }

        getAgencyMappings(drsIds, agencyRecordTypeId, drsToAgencyMap, agencyToCapacityMap, agencyToCustomerTypeMap);
        agencyToUserMap = getAgencyToUserMap(agencyToCapacityMap.keySet());

        for (Id agencyId : agencyToCapacityMap.keySet()) {
            if (!agencyCapacityTracker.containsKey(agencyId)) {
                agencyCapacityTracker.put(agencyId, 0);
            }
        }

        List<WorkOrder> workOrdersToInsert = new List<WorkOrder>();
        Map<Id, WorkOrderAllocation__c> allocToUpdateMap = new Map<Id, WorkOrderAllocation__c>();
        Map<Id, Id> accountIdToAllocIdMap = new Map<Id, Id>();

        for (WorkOrderAllocation__c alloc : allocList) {
            Account acc = bpToAccountMap.get(alloc.BP_Numbers__c);
            if (acc == null || acc.DRS_Master__c == null || !drsToAgencyMap.containsKey(acc.DRS_Master__c)) {
                continue;
            }

            WorkType wt = workTypeMap.get(alloc.RT_Customer_work_Type__c);
            if (wt == null) {
                continue;
            }

            for (Id agencyId : drsToAgencyMap.get(acc.DRS_Master__c)) {
                String customerType = agencyToCustomerTypeMap.get(agencyId);
                if (customerType == null || !customerType.equalsIgnoreCase(alloc.Work_orders_Type__c)) {
                    continue;
                }

                Integer currentCount = agencyCapacityTracker.get(agencyId);
                Decimal maxCapacity = agencyToCapacityMap.get(agencyId);

                if (maxCapacity != null && currentCount < maxCapacity) {
                    WorkOrder wo = new WorkOrder(
                        RecordTypeId = meteringRecordTypeId,
                        R_T_Agency__c = agencyId,
                        AccountId = acc.Id,
                        StartDate = alloc.Bill_Date__c,
                        EndDate = alloc.Due_Date__c,
                        WorkTypeId = wt.Id,
                        CA_Number__c = acc.CA_Number__c,
                        Due_Amount__c = alloc.Total__c,
                        Customer_Name__c = acc.Name,
                        X91_180__c = alloc.X91_180__c,
                        X61_90__c = alloc.X61_90__c,
                        X31_60__c = alloc.X31_60__c,
                        X2_3YR__c = alloc.X2_3YR__c,
                        X181_365__c = alloc.X181_365__c,
                        X1_2YR__c = alloc.X1_2YR__c,
                        X0_30__c = alloc.X0_30__c,
                        NOTDUE__c = alloc.NOTDUE__c,
                        B4DUE__c = alloc.B4DUE__c,
                        Colony__c = alloc.Colony__c,
                        Invoice__c = alloc.Invoice_No__c,
                        Net_Payment_upto_Due_Date__c = alloc.Net_Payment_upto_Due_Date__c
                    );

                    if (agencyToUserMap.containsKey(agencyId)) {
                        wo.OwnerId = agencyToUserMap.get(agencyId);
                    }

                    workOrdersToInsert.add(wo);
                    agencyCapacityTracker.put(agencyId, currentCount + 1);
                    alloc.Assigned_Agency__c = agencyId;
                    allocToUpdateMap.put(acc.Id, alloc);
                    accountIdToAllocIdMap.put(acc.Id, alloc.Id);
                    break;
                }
            }
        }

        List<WorkOrder> insertedWorkOrders = new List<WorkOrder>();

        if (!workOrdersToInsert.isEmpty()) {
            try {
                insert workOrdersToInsert;
                insertedWorkOrders = workOrdersToInsert;
            } catch (Exception ex) {
                System.debug('Error inserting WorkOrders: ' + ex.getMessage());
                for (WorkOrder wo : workOrdersToInsert) {
                    System.debug('Failed WO: ' + JSON.serialize(wo));
                }
            }
        }

        if (!insertedWorkOrders.isEmpty()) {
            for (WorkOrder wo : insertedWorkOrders) {
                Id accId = wo.AccountId;
                if (accountIdToAllocIdMap.containsKey(accId)) {
                    WorkOrderAllocation__c allocToUpdate = allocToUpdateMap.get(accId);
                    allocToUpdate.Created_WorkOrder__c = true;
                }
            }

            try {
                update allocToUpdateMap.values();
                System.debug('✅ Updated ' + allocToUpdateMap.size() + ' WorkOrderAllocation__c records');
            } catch (Exception ex) {
                System.debug('Error updating allocations: ' + ex.getMessage());
                for (WorkOrderAllocation__c alloc : allocToUpdateMap.values()) {
                    System.debug('Failed Allocation: ' + JSON.serialize(alloc));
                }
            }
        } else {
            System.debug('⚠️ No WorkOrders inserted, so no allocations updated.');
        }
    }

    private static Map<String, WorkType> getWorkTypes(Set<String> types) {
        Map<String, WorkType> result = new Map<String, WorkType>();
        for (WorkType wt : [SELECT Id, Name, Work_Order_Type__c FROM WorkType WHERE Work_Order_Type__c IN :types]) {
            result.put(wt.Work_Order_Type__c, wt);
        }
        return result;
    }

    private static Map<String, Account> getAccountsByBP(Set<String> bpNumbers) {
        Map<String, Account> result = new Map<String, Account>();
        for (Account acc : [
            SELECT Id, Name, CA_Number__c, DRS_Master__c, BP_Number__c
            FROM Account
            WHERE BP_Number__c IN :bpNumbers
        ]) {
            result.put(acc.BP_Number__c, acc);
        }
        return result;
    }

    private static void getAgencyMappings(
        Set<Id> drsIds,
        String recordTypeId,
        Map<Id, List<Id>> drsToAgencyMap,
        Map<Id, Decimal> agencyToCapacityMap,
        Map<Id, String> agencyToCustomerTypeMap
    ) {
        for (DRS_Contractor_Mapping_Master__c mapping : [
            SELECT DRS__c, Agency__c, Agency__r.Capacity__c, Agency__r.Customer_Type__c
            FROM DRS_Contractor_Mapping_Master__c
            WHERE DRS__c IN :drsIds AND Agency__r.RecordTypeId = :recordTypeId
        ]) {
            if (!drsToAgencyMap.containsKey(mapping.DRS__c)) {
                drsToAgencyMap.put(mapping.DRS__c, new List<Id>());
            }
            drsToAgencyMap.get(mapping.DRS__c).add(mapping.Agency__c);
            agencyToCapacityMap.put(mapping.Agency__c, mapping.Agency__r.Capacity__c);
            agencyToCustomerTypeMap.put(mapping.Agency__c, mapping.Agency__r.Customer_Type__c);
        }
    }

    private static Map<Id, Id> getAgencyToUserMap(Set<Id> agencyIds) {
        Map<Id, Id> result = new Map<Id, Id>();
        for (ServiceResource sr : [
            SELECT Agency__c, RelatedRecordId
            FROM ServiceResource
            WHERE Agency__c IN :agencyIds
              AND Service_Resource_Type__c = 'Contractor'
        ]) {
            result.put(sr.Agency__c, sr.RelatedRecordId);
        }
        return result;
    }
}