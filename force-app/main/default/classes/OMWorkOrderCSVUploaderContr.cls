public without sharing class OMWorkOrderCSVUploaderContr {

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
    public static Map<String, Object> uploadCSVBatch(String objectName, List<Map<String,String>> csvRecords) {

        if (csvRecords == null || csvRecords.isEmpty()) {
            return new Map<String,Object>{
                'successCount' => 0,
                'errors' => new List<Map<String,String>>{
                    new Map<String,String>{ 'Error' => 'No records found in the uploaded file.' }
                },
                'successes' => new List<Map<String,String>>()
            };
        }

        try {
            // FIXED ➝ Fully qualified method call
            return OMWorkOrderCSVUploaderContr.processChunk(csvRecords);

        } catch (Exception ex) {
            return new Map<String,Object>{
                'successCount' => 0,
                'errors' => new List<Map<String,String>>{
                    new Map<String,String>{ 'Error' => 'System error: ' + ex.getMessage() }
                },
                'successes' => new List<Map<String,String>>()
            };
        }
    }

    // Must be PUBLIC and STATIC so queueable job can call it
    public static Map<String,Object> processChunk(List<Map<String,String>> csvRecords) {

        Set<Id> woIds = new Set<Id>();
        for (Map<String,String> row : csvRecords) {
            String idValue = row.get('Work Order ID');
            if (!String.isBlank(idValue)) {
                woIds.add(idValue);
            }
        }

        Map<Id, WorkOrder> woMap = new Map<Id, WorkOrder>(
            [SELECT Id, Appointment_Status__c, AICRemark__c,  ServiceTerritoryId, Agent__c, OwnerId 
             FROM WorkOrder 
             WHERE Id IN :woIds]
        );

        List<WorkOrder> updateList = new List<WorkOrder>();
        List<Map<String,String>> errors = new List<Map<String,String>>();
        List<Map<String,String>> successes = new List<Map<String,String>>();

        for (Map<String,String> row : csvRecords) {
            String woId = row.get('Work Order ID');
            String remark = row.get('AIC Remark');

            if (String.isBlank(woId)) {
                row.put('Error', 'Work Order ID cannot be blank');
                errors.add(row);
                continue;
            }
            if (!woMap.containsKey(woId)) {
                row.put('Error', 'Work Order not found: ' + woId);
                errors.add(row);
                continue;
            }

            WorkOrder wo = woMap.get(woId);
            wo.Appointment_Status__c = 'Completed';
            wo.AICRemark__c = remark;

            // ⭐ NEW MERGED LOGIC - BEGIN
            User usr = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

            wo.ServiceTerritoryId = null;
            wo.Agent__c = null;
            wo.OwnerId = usr.Id;
            // ⭐ NEW MERGED LOGIC - END

            updateList.add(wo);

            successes.add(new Map<String,String>{
                'Work Order ID' => woId,
                'Appointment_Status__c' => 'Completed',
                'AICRemark__c' => remark
            });
        }

        if (!updateList.isEmpty()) {
            Database.SaveResult[] results = Database.update(updateList, false);

            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    errors.add(new Map<String,String>{
                        'Work Order ID' => updateList[i].Id,
                        'Error' => results[i].getErrors()[0].getMessage()
                    });
                }
            }
        }


        // ⭐⭐⭐ ADDITIONAL BACK-END UPDATES FOR WORK ORDERS ⭐⭐⭐

        if (!updateList.isEmpty()) {
            Set<Id> updatedWOIds = new Set<Id>();
            for (WorkOrder w : updateList) updatedWOIds.add(w.Id);

            User userDetail = [SELECT Id, Profile.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

            // DELETE WORK ORDER SHARE RECORDS
            List<WorkOrderShare> sharesToDelete = [
                SELECT Id, UserOrGroup.Profile.Name
                FROM WorkOrderShare
                WHERE ParentId IN :updatedWOIds
                AND UserOrGroup.Id != :userDetail.Id
                AND UserOrGroup.Profile.Name IN (
                    'Field Agent Riser',
                    'O&M Field Agent Riser Activity',
                    'O&M Supervisor IPD',
                    'Field Agent(O&M)- IPD',
                    'O&M Supervisor DOMESTIC METER CHECKING',
                    'O&M Rubber Hose Supervisor',
                    'Rubber Hose Field Agent',
                    'Field Agent(O&M)- AfterSalesService'
                )
            ];
            delete sharesToDelete;

            // UPDATE SERVICE APPOINTMENTS
            List<ServiceAppointment> saList = [
                SELECT Id 
                FROM ServiceAppointment 
                WHERE ParentRecordId IN :updatedWOIds
            ];

            for (ServiceAppointment sa : saList) {
                sa.SchedStartTime = null;
                sa.SchedEndTime = null;
            }
            update saList;

            // DELETE ASSIGNED RESOURCES
            List<AssignedResource> arList = [
                SELECT Id 
                FROM AssignedResource 
                WHERE ServiceAppointmentId IN :saList
            ];
            delete arList;
        }


        return new Map<String,Object>{
            'successCount' => successes.size(),
            'errors' => errors,
            'successes' => successes
        };
    }

    @AuraEnabled
    public static void uploadLargeCSVChunk(List<Map<String,String>> records, String objectName) {
        String recordsJson = JSON.serialize(records);
        System.enqueueJob(new AS_CaseCSVChunkProcessor(objectName, recordsJson));
    }
}