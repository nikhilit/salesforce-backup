public with sharing class WorkOrderCreatorController {

    @AuraEnabled
    public static List<Id> createWorkOrders(List<String> reactiveValue) {
        System.debug('📌 INSIDE BULK WORK ORDER CREATION:::');

        List<WorkOrder> workOrdersToInsert = new List<WorkOrder>();
        List<WorkOrder> workOrdersToUpdate = new List<WorkOrder>();
        List<ServiceAppointment> serviceAppointmentsToInsert = new List<ServiceAppointment>();
        List<Id> createdWorkOrderIds = new List<Id>();

        try {
            if (reactiveValue == null || reactiveValue.isEmpty()) {
                throw new AuraHandledException('No Account IDs provided.');
            }

            System.debug('🧾 Input Account IDs (String): ' + reactiveValue);

            RecordType rt = [
                SELECT Id 
                FROM RecordType 
                WHERE SObjectType = 'WorkOrder' 
                AND Name = 'MGL O&M' 
                LIMIT 1
            ];
            System.debug('📋 RecordTypeId for MGL O&M: ' + rt.Id);

            Set<Id> accountIds = new Set<Id>();
            for (String accIdStr : reactiveValue) {
                if (String.isNotBlank(accIdStr)) {
                    accountIds.add(Id.valueOf(accIdStr));
                }
            }
            System.debug('✅ Converted Account IDs: ' + accountIds);

            // Fetch Accounts and DRS Master info
            List<Account> accounts = [
                SELECT Id, Name, DRS_Master__r.Name
                FROM Account
                WHERE Id IN :accountIds
            ];

            Map<Id, String> accountIdToDrsCode = new Map<Id, String>();
            Set<String> drsCodeSet = new Set<String>();

            for (Account acc : accounts) {
                if (acc.DRS_Master__r != null && String.isNotBlank(acc.DRS_Master__r.Name)) {
                    accountIdToDrsCode.put(acc.Id, acc.DRS_Master__r.Name);
                    drsCodeSet.add(acc.DRS_Master__r.Name);
                }
            }

            // Fetch ServiceTerritories with Work Type
            List<ServiceTerritory> serviceTerritories = [
                SELECT Id, Name, DRS__c, Work_Type__c
                FROM ServiceTerritory
                WHERE DRS__c IN :drsCodeSet
            ];

            Map<String, ServiceTerritory> drsCodeToTerritoryMap = new Map<String, ServiceTerritory>();
            for (ServiceTerritory st : serviceTerritories) {
                if (String.isNotBlank(st.DRS__c)) {
                    drsCodeToTerritoryMap.put(st.DRS__c, st);
                }
            }

            // Fetch Contractor Users from ServiceTerritoryMember
            Set<Id> matchedTerritoryIds = new Set<Id>();
            for (ServiceTerritory st : drsCodeToTerritoryMap.values()) {
                matchedTerritoryIds.add(st.Id);
            }

            List<ServiceTerritoryMember> members = [
                SELECT ServiceTerritoryId, ServiceResource.RelatedRecordId, ServiceResource.Role__c
                FROM ServiceTerritoryMember
                WHERE ServiceTerritoryId IN :matchedTerritoryIds
            ];

            System.debug('👥 ServiceTerritoryMembers fetched: ' + members);

            Map<Id, Id> territoryToOwnerMap = new Map<Id, Id>();
            for (ServiceTerritoryMember member : members) {
                if (member.ServiceResource.Role__c == 'Contractor') {
                    territoryToOwnerMap.put(member.ServiceTerritoryId, member.ServiceResource.RelatedRecordId);
                    System.debug('✅ Mapped Territory to Owner → ' + member.ServiceTerritoryId + ' → ' + member.ServiceResource.RelatedRecordId);
                }
            }

            // Step 1: Create WorkOrders with basic fields
            for (Account acc : accounts) {
                WorkOrder wo = new WorkOrder();
                wo.Subject = 'Auto-created Work Order - MGL O&M';
                wo.Status = 'New';
                wo.RecordTypeId = rt.Id;
                wo.AccountId = acc.Id;
                workOrdersToInsert.add(wo);
            }

            System.debug('📦 Work Orders prepared for insert: ' + workOrdersToInsert.size());

            insert workOrdersToInsert;
            System.debug('✅ Inserted ' + workOrdersToInsert.size() + ' Work Orders');

            // Step 2: Query back inserted WorkOrders
            List<WorkOrder> insertedWorkOrders = [
                SELECT Id, AccountId, Subject
                FROM WorkOrder 
                WHERE Id IN :workOrdersToInsert
            ];

            Map<Id, Account> accountMap = new Map<Id, Account>();
            for (Account acc : accounts) {
                accountMap.put(acc.Id, acc);
            }

            for (WorkOrder wo : insertedWorkOrders) {
                Account acc = accountMap.get(wo.AccountId);
                String drsCode = accountIdToDrsCode.get(acc.Id);

                if (String.isNotBlank(drsCode) && drsCodeToTerritoryMap.containsKey(drsCode)) {
                    ServiceTerritory matchedTerritory = drsCodeToTerritoryMap.get(drsCode);
                    Id ownerId = territoryToOwnerMap.get(matchedTerritory.Id);

                    if (matchedTerritory != null) {
                        wo.ServiceTerritoryId = matchedTerritory.Id;
                        wo.WorkTypeId = matchedTerritory.Work_Type__c;  // ✅ NEW: Set WorkTypeId
                        System.debug('🗺️ Updating WO ' + wo.Id + ' with Territory: ' + matchedTerritory.Id);
                        System.debug('🛠️ Setting WorkTypeId: ' + matchedTerritory.Work_Type__c);
                    }

                    if (ownerId != null) {
                        wo.OwnerId = ownerId;
                        System.debug('👤 Updating WO ' + wo.Id + ' with Owner: ' + ownerId);
                    } else {
                        System.debug('⚠️ No Owner found for territory: ' + matchedTerritory.Id);
                    }

                    workOrdersToUpdate.add(wo);
                } else {
                    System.debug('⚠️ No ServiceTerritory match for Account: ' + acc.Id);
                }
            }

            if (!workOrdersToUpdate.isEmpty()) {
                update workOrdersToUpdate;
                System.debug('🔄 Updated ' + workOrdersToUpdate.size() + ' Work Orders with Owner, Territory & WorkType');
            }

            // Step 3: Create ServiceAppointments
            /*
            for (WorkOrder wo : workOrdersToUpdate) {
                ServiceAppointment sa = new ServiceAppointment();
                sa.ParentRecordId = wo.Id;
                sa.Status = 'New';
                sa.Subject = 'Initial Appointment for WO: ' + wo.Subject;
                sa.SchedStartTime = System.now().addHours(1);
                sa.SchedEndTime = System.now().addHours(2);
                sa.OwnerId = wo.OwnerId;
                sa.ServiceTerritoryId = wo.ServiceTerritoryId;

                if (sa.OwnerId == null) {
                    System.debug('⚠️ WARNING: SA OwnerId is null for WO: ' + wo.Id);
                }
                if (sa.ServiceTerritoryId == null) {
                    System.debug('⚠️ WARNING: SA TerritoryId is null for WO: ' + wo.Id);
                }

                serviceAppointmentsToInsert.add(sa);
                createdWorkOrderIds.add(wo.Id);
            }

            System.debug('📅 Service Appointments prepared for insert: ' + serviceAppointmentsToInsert.size());

            insert serviceAppointmentsToInsert;
            System.debug('✅ Inserted ' + serviceAppointmentsToInsert.size() + ' Service Appointments');
            */
            return createdWorkOrderIds;

        } catch (Exception e) {
            System.debug('❌ ERROR: ' + e.getMessage());
            throw new AuraHandledException('Failed to create Work Orders: ' + e.getMessage());
        }
    }
}