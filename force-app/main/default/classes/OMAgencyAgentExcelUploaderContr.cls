public without sharing class OMAgencyAgentExcelUploaderContr {

    /* =========================================================
     * OBJECT PICKLIST
     * ========================================================= */
    @AuraEnabled(cacheable=true)
    public static List<Map<String,String>> getObjectList() {
        return new List<Map<String,String>>{
            new Map<String,String>{
                'label' => 'Work Order',
                'value' => 'WorkOrder'
            }
        };
    }

    @AuraEnabled
    public static Map<String, Object> uploadCSVBatch(
        String objectName,
        List<Map<String,String>> csvRecords
    ) {
        return processChunk(csvRecords);
    }

    /* =========================================================
     * CORE PROCESSING LOGIC
     * ========================================================= */
    public static Map<String,Object> processChunk(List<Map<String,String>> csvRecords) {

        List<Map<String,String>> errors = new List<Map<String,String>>();
        List<Map<String,String>> successes = new List<Map<String,String>>();
        List<WorkOrder> updateList = new List<WorkOrder>();

        /* -----------------------------------
         * 1. Collect CSV values
         * ----------------------------------- */
        Set<String> woNumbers = new Set<String>();
        Set<String> agencyNames = new Set<String>();
        Set<String> agentNames = new Set<String>();

        for (Map<String,String> row : csvRecords) {
            if (!String.isBlank(row.get('Work Order Number')))
                woNumbers.add(row.get('Work Order Number').trim());

            if (!String.isBlank(row.get('Agency')))
                agencyNames.add(row.get('Agency').trim());

            if (!String.isBlank(row.get('Agent')))
                agentNames.add(row.get('Agent').trim());
        }

        /* -----------------------------------
         * 2. Resolve Work Orders
         * ----------------------------------- */
        Map<String, WorkOrder> woMap = new Map<String, WorkOrder>();
        for (WorkOrder wo : [
            SELECT Id, WorkOrderNumber, ServiceTerritoryId, Agent__c, OwnerId
            FROM WorkOrder
            WHERE WorkOrderNumber IN :woNumbers
        ]) {
            woMap.put(wo.WorkOrderNumber, wo);
        }

        /* -----------------------------------
         * 3. Resolve Agencies (After Sales Service only)
         * ----------------------------------- */
        Map<String, ServiceTerritory> agencyMap = new Map<String, ServiceTerritory>();
        for (ServiceTerritory st : [
            SELECT Id, Name
            FROM ServiceTerritory
            WHERE Name IN :agencyNames
              AND IsActive = true
              AND Work_Type__r.Name = 'After Sales Service'
        ]) {
            agencyMap.put(st.Name, st);
        }

        /* -----------------------------------
         * 4. Resolve Agents (ServiceResource)
         * ----------------------------------- */
        Map<String, ServiceResource> agentMap = new Map<String, ServiceResource>();
        for (ServiceResource sr : [
            SELECT Id, Name, RelatedRecordId
            FROM ServiceResource
            WHERE Name IN :agentNames
        ]) {
            agentMap.put(sr.Name, sr);
        }

        /* -----------------------------------
         * 5. Build Agency → Agent Mapping
         * ----------------------------------- */
        Map<String, Set<Id>> agencyToAgentsMap = new Map<String, Set<Id>>();

        if (!agencyMap.isEmpty() && !agentMap.isEmpty()) {
            for (ServiceTerritoryMember stm : [
                SELECT ServiceTerritory.Name, ServiceResourceId
                FROM ServiceTerritoryMember
                WHERE ServiceTerritoryId IN :agencyMap.values()
                  AND ServiceResourceId IN :agentMap.values()
            ]) {
                String agencyNameKey = stm.ServiceTerritory.Name;

                if (!agencyToAgentsMap.containsKey(agencyNameKey)) {
                    agencyToAgentsMap.put(agencyNameKey, new Set<Id>());
                }
                agencyToAgentsMap.get(agencyNameKey).add(stm.ServiceResourceId);
            }
        }

        // User loggedInUser = [
        //     SELECT Id
        //     FROM User
        //     WHERE Id = :UserInfo.getUserId()
        // ];

        /* -----------------------------------
         * 6. Row Validation & Processing
         * ----------------------------------- */
        for (Map<String,String> row : csvRecords) {

            String woNumber   = row.get('Work Order Number');
            String agencyName = row.get('Agency');
            String agentName  = row.get('Agent');

            if (String.isBlank(woNumber)) {
                row.put('Error', 'Work Order Number is mandatory');
                errors.add(row);
                continue;
            }

            if (!woMap.containsKey(woNumber)) {
                row.put('Error', 'Work Order not found');
                errors.add(row);
                continue;
            }

            if (!agencyMap.containsKey(agencyName)) {
                row.put('Error', 'Invalid Agency or not After Sales Service');
                errors.add(row);
                continue;
            }

            ServiceResource agentSR = agentMap.get(agentName);
            if (agentSR == null) {
                row.put('Error', 'Agent not found');
                errors.add(row);
                continue;
            }

            if (!agencyToAgentsMap.containsKey(agencyName) ||
                !agencyToAgentsMap.get(agencyName).contains(agentSR.Id)) {
                row.put('Error', 'Agent does not belong to selected Agency');
                errors.add(row);
                continue;
            }

            WorkOrder wo = woMap.get(woNumber);

            wo.ServiceTerritoryId = agencyMap.get(agencyName).Id;
            wo.Agent__c           = agentSR.Id;
            //wo.OwnerId            = loggedInUser.Id;
			if (agentSR.RelatedRecordId != null) {
             wo.OwnerId = agentSR.RelatedRecordId;
             } else {
             row.put('Error', 'Agent is not linked to a User');
            errors.add(row);
            continue;
             }
 

            updateList.add(wo);

            successes.add(new Map<String,String>{
                'Work Order Number' => woNumber,
                'Agency'            => agencyName,
                'Agent'             => agentName
            });
        }

        /* -----------------------------------
         * 7. DML
         * ----------------------------------- */
        if (!updateList.isEmpty()) {
            Database.SaveResult[] srList = Database.update(updateList, false);

            for (Integer i = 0; i < srList.size(); i++) {
                if (!srList[i].isSuccess()) {
                    errors.add(new Map<String,String>{
                        'Work Order Number' => updateList[i].WorkOrderNumber,
                        'Error'             => srList[i].getErrors()[0].getMessage()
                    });
                }
            }
        }

        

        return new Map<String,Object>{
            'successCount' => successes.size(),
            'errors'       => errors,
            'successes'    => successes
        };
    }

    /* =========================================================
     * LARGE CSV SUPPORT
     * ========================================================= */
    @AuraEnabled
    public static void uploadLargeCSVChunk(List<Map<String,String>> records, String objectName) {
        String recordsJson = JSON.serialize(records);
        System.enqueueJob(new AS_CaseCSVChunkProcessor(objectName, recordsJson));
    }
}