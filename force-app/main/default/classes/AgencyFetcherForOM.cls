public without sharing class AgencyFetcherForOM {

    @AuraEnabled(cacheable=true)
public static List<ServiceTerritory> getOMAgencies() {
    try {
        Id rtId = [
            SELECT Id FROM RecordType 
            WHERE SObjectType = 'ServiceTerritory' AND DeveloperName = 'O_M' 
            LIMIT 1
        ].Id;

        // Id rtId = '012fs0000000HbzAAE';
        System.debug('✅ Fetched RecordTypeId: ' + rtId);

        List<ServiceTerritory> agencies = [
            SELECT Id, Name 
            FROM ServiceTerritory 
            WHERE IsActive = TRUE AND RecordTypeId = :rtId
        ];

        System.debug('✅ Agencies Fetched: ' + agencies);

        return agencies;

    } catch (Exception e) {
        System.debug('❌ Error in getOMAgencies: ' + e.getMessage());
        throw new AuraHandledException('getOMAgencies ERROR: ' + e.getMessage());
    }
}


    @AuraEnabled
    public static void assignOMAgency(List<String> reactiveValue, Id agencyId) {
        if (reactiveValue == null || reactiveValue.isEmpty()) {
            throw new AuraHandledException('No WorkOrder IDs provided.');
        }

        // Convert List<String> to Set<Id>
        Set<Id> workOrderIds = new Set<Id>();
        for (String woId : reactiveValue) {
            if (woId != null) {
                workOrderIds.add((Id)woId);
            }
        }

        // Fetch a contractor user from selected agency
        Id contractorUserId = null;
        List<ServiceResource> contractors = [
            SELECT RelatedRecordId
            FROM ServiceResource
            WHERE Agency__c = :agencyId AND Role__c = 'Contractor'
            LIMIT 1
        ];

        if (!contractors.isEmpty()) {
            contractorUserId = contractors[0].RelatedRecordId;
        }

        if (contractorUserId == null) {
            throw new AuraHandledException('No contractor found for the selected agency.');
        }

        // Update WorkOrders
        List<WorkOrder> workOrdersToUpdate = [
            SELECT Id FROM WorkOrder WHERE Id IN :workOrderIds
        ];

        for (WorkOrder wo : workOrdersToUpdate) {
            wo.ServiceTerritoryId = agencyId; 
            wo.OwnerId = contractorUserId;
            wo.Assiged_to_Agency__c = true;
        }

        update workOrdersToUpdate;
    }
}