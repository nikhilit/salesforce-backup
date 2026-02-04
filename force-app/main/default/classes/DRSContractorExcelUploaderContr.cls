public without sharing class DRSContractorExcelUploaderContr {

    /* =========================================================
     * OBJECT PICKLIST (for UI reuse)
     * ========================================================= */
    @AuraEnabled(cacheable=true)
    public static List<Map<String,String>> getObjectList() {
        return new List<Map<String,String>>{
            new Map<String,String>{
                'label' => 'DRS Contractor Mapping Master',
                'value' => 'DRS_Contractor_Mapping_Master__c'
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
     * CORE LOGIC
     * ========================================================= */
    public static Map<String,Object> processChunk(List<Map<String,String>> csvRecords) {

        List<Map<String,String>> errors    = new List<Map<String,String>>();
        List<Map<String,String>> successes = new List<Map<String,String>>();

        Set<String> excelWOSet = new Set<String>();

        /* -----------------------------------
         * 1. Collect Old & New WO numbers
         * ----------------------------------- */
        for (Map<String,String> row : csvRecords) {

            String oldWO = row.get('Old Contractor Work Order Number');
            String newWO = row.get('New Contractor Work Order Number');

            if (!String.isBlank(oldWO))
                excelWOSet.add(oldWO.trim());

            if (!String.isBlank(newWO))
                excelWOSet.add(newWO.trim());
        }

        /* -----------------------------------
         * 2. Fetch all DCMs by WO number
         * ----------------------------------- */
        Map<String, DRS_Contractor_Mapping_Master__c> woToDCMMap =
            new Map<String, DRS_Contractor_Mapping_Master__c>();

        for (DRS_Contractor_Mapping_Master__c dcm : [
            SELECT Id,
                   DRS__c,
                   Agency__c,
                   Contractor_Work_Order_No__c,
                   Contractor_Name__c,
                   Activity_Name__c
            FROM DRS_Contractor_Mapping_Master__c
            WHERE Contractor_Work_Order_No__c IN :excelWOSet
        ]) {
            woToDCMMap.put(dcm.Contractor_Work_Order_No__c, dcm);
        }

        /* -----------------------------------
         * 3. Validate rows + build updates
         * ----------------------------------- */
        Map<Id, DRS_Contractor_Mapping_Master__c> uniqueUpdateMap =
            new Map<Id, DRS_Contractor_Mapping_Master__c>();

        for (Map<String,String> row : csvRecords) {

            String excelDRS      = row.get('DRS');
            String excelOldWO    = row.get('Old Contractor Work Order Number');
            String excelNewWO    = row.get('New Contractor Work Order Number');
            String excelActivity = row.get('Activity Name');

            /* ---- Mandatory check ---- */
            if (String.isBlank(excelOldWO) || String.isBlank(excelNewWO)) {
                row.put(
                    'Error',
                    'Both Old and New Contractor Work Order Numbers are mandatory'
                );
                errors.add(row);
                continue;
            }

            excelOldWO = excelOldWO.trim();
            excelNewWO = excelNewWO.trim();

            /* ---- WO existence check ---- */
            if (!woToDCMMap.containsKey(excelOldWO)) {
                row.put(
                    'Error',
                    'No DCM record found for Old Contractor Work Order Number'
                );
                errors.add(row);
                continue;
            }

            if (!woToDCMMap.containsKey(excelNewWO)) {
                row.put(
                    'Error',
                    'No DCM record found for New Contractor Work Order Number'
                );
                errors.add(row);
                continue;
            }

            DRS_Contractor_Mapping_Master__c targetDCM =
                woToDCMMap.get(excelOldWO);

            DRS_Contractor_Mapping_Master__c sourceDCM =
                woToDCMMap.get(excelNewWO);

            /* ---- Prevent self mapping ---- */
            if (targetDCM.Id == sourceDCM.Id) {
                row.put(
                    'Error',
                    'Old and New Contractor Work Order Numbers belong to the same record'
                );
                errors.add(row);
                continue;
            }

            /* ---- Activity Name safety ---- */
            if (targetDCM.Activity_Name__c != sourceDCM.Activity_Name__c) {
                row.put(
                    'Error',
                    'Activity Name does not match between source and target records'
                );
                errors.add(row);
                continue;
            }

            /* ---- Prevent duplicate Excel overwrite ---- */
            if (uniqueUpdateMap.containsKey(targetDCM.Id)) {
                row.put(
                    'Error',
                    'Same Old Contractor Work Order Number appears multiple times in Excel'
                );
                errors.add(row);
                continue;
            }

            /* -----------------------------------
             * APPLY ONE-WAY COPY (FINAL LOGIC)
             * ----------------------------------- */
            targetDCM.Agency__c          = sourceDCM.Agency__c;
            targetDCM.Contractor_Name__c = sourceDCM.Contractor_Name__c;
            targetDCM.Contractor_Work_Order_No__c = sourceDCM.Contractor_Work_Order_No__c;

            

            uniqueUpdateMap.put(targetDCM.Id, targetDCM);

            successes.add(new Map<String,String>{
                'DRS'                      => excelDRS,
                'Old Contractor WO'        => excelOldWO,
                'New Contractor WO'        => excelNewWO,
                'Updated DCM Id'           => targetDCM.Id
            });
        }

        /* -----------------------------------
         * 4. DML
         * ----------------------------------- */
        if (!uniqueUpdateMap.isEmpty()) {

            Database.SaveResult[] srList =
                Database.update(uniqueUpdateMap.values(), false);

            Integer idx = 0;
            for (Database.SaveResult sr : srList) {
                if (!sr.isSuccess()) {
                    errors.add(new Map<String,String>{
                        'Error' => sr.getErrors()[0].getMessage()
                    });
                }
                idx++;
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
    public static void uploadLargeCSVChunk(
        List<Map<String,String>> records,
        String objectName
    ) {
        String recordsJson = JSON.serialize(records);
        System.enqueueJob(
            new AS_CaseCSVChunkProcessor(objectName, recordsJson)
        );
    }
}