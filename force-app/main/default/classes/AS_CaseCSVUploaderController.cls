public without sharing class AS_CaseCSVUploaderController {

    @AuraEnabled(cacheable=true)
    public static List<Map<String,String>> getObjectList() {
        List<Map<String,String>> objectList = new List<Map<String,String>>();
        objectList.add(new Map<String,String>{
            'label' => 'Case',
            'value' => 'Case'
        });
        return objectList;
    }

    @AuraEnabled
    public static Map<String, Object> uploadCSVBatch(String objectName, List<Map<String,String>> csvRecords) {
        if (csvRecords.isEmpty()) {
            AS_ErrorLogger.log('AS_CaseCSVUploaderController', 'uploadCSVBatch', 'No records found in the uploaded file.', null);
            return new Map<String,Object>{
                'successCount' => 0,
                'errors' => new List<Map<String,String>>{
                    new Map<String,String>{ 'Error' => 'No records found in the uploaded file.' }
                },
                'successes' => new List<Map<String,String>>()
            };
        }

        // Validate headers - Only Docket_Number__c is required
        Set<String> headers = new Set<String>(csvRecords[0].keySet());
        if (!headers.contains('Docket_Number__c')) {
            return new Map<String,Object>{
                'successCount' => 0,
                'errors' => new List<Map<String,String>>{
                    new Map<String,String>{ 'Error' => 'CSV must contain Docket_Number__c column. Optional columns: Standard_Remarks__c, Planned_Start_date__c, Planned_End_Date__c' }
                },
                'successes' => new List<Map<String,String>>()
            };
        }

        try {
            return processChunk(objectName, csvRecords);
        } catch (Exception ex) {
            AS_ErrorLogger.log('AS_CaseCSVUploaderController', 'uploadCSVBatch', ex, null);
            return new Map<String,Object>{
                'successCount' => 0,
                'errors' => new List<Map<String,String>>{
                    new Map<String,String>{ 'Error' => 'System error: ' + ex.getMessage() }
                },
                'successes' => new List<Map<String,String>>()
            };
        }
    }

    public static Map<String,Object> processChunk(String objectName, List<Map<String,String>> csvRecords) {
        Set<String> docketNumbers = new Set<String>();
        for (Map<String,String> row : csvRecords) {
            if (row.containsKey('Docket_Number__c') && String.isNotBlank(row.get('Docket_Number__c'))) {
                docketNumbers.add(row.get('Docket_Number__c'));
            }
        }

        Map<String, Case> caseMap = new Map<String, Case>();
        for (Case c : [SELECT Id, Docket_Number__c, Status, Standard_Remarks__c, Planned_Start_date__c, Planned_End_Date__c, Planned_Start_Time__c, Planned_End_Time__c
                       FROM Case WHERE Docket_Number__c IN :docketNumbers]) {
            caseMap.put(c.Docket_Number__c, c);
        }

        List<Case> casesToUpdate = new List<Case>();
        List<Map<String,String>> errors = new List<Map<String,String>>();
        List<Map<String,String>> successes = new List<Map<String,String>>();

        for (Map<String,String> row : csvRecords) {
            String docketNumber = row.get('Docket_Number__c');
            String standardRemarks = row.get('Standard_Remarks__c');
            String plannedStartDate = row.get('Planned_Start_date__c');
            String plannedEndDate = row.get('Planned_End_Date__c');
            String plannedStartTime = row.get('Planned_Start_Time__c');
            String plannedEndTime   = row.get('Planned_End_Time__c');


            if (String.isBlank(docketNumber)) {
                row.put('Error', 'Docket_Number__c cannot be blank');
                errors.add(row);
                continue;
            }

            if (!caseMap.containsKey(docketNumber)) {
                row.put('Error', 'Case not found with Docket Number: ' + docketNumber);
                errors.add(row);
                continue;
            }

            Case existingCase = caseMap.get(docketNumber);
            
            // Update fields - all fields are optional except Docket_Number__c
            // Status is always set to 'Actioned by Department'
            existingCase.Status = 'Actioned by Department';
            
            boolean hasValidationError = false;
            
            if (String.isNotBlank(standardRemarks)) {
                existingCase.Standard_Remarks__c = standardRemarks;
            }
            
            if (String.isNotBlank(plannedStartDate)) {
                try {
                    existingCase.Planned_Start_date__c = Date.valueOf(plannedStartDate);
                } catch (Exception e) {
                    row.put('Error', 'Invalid Planned_Start_date__c format. Use YYYY-MM-DD');
                    errors.add(row);
                    hasValidationError = true;
                }
            }
            
            if (String.isNotBlank(plannedEndDate)) {
                try {
                    existingCase.Planned_End_Date__c = Date.valueOf(plannedEndDate);
                } catch (Exception e) {
                    row.put('Error', 'Invalid Planned_End_Date__c format. Use YYYY-MM-DD');
                    errors.add(row);
                    hasValidationError = true;
                }
            }

            if (String.isNotBlank(plannedStartTime)) {
                try {
                    existingCase.Planned_Start_Time__c = parseTime(plannedStartTime);
                } catch (Exception e) {
                    row.put('Error', 'Invalid Planned_Start_Time__c format. Use HH:mm or HH:mm:ss');
                    errors.add(row);
                    hasValidationError = true;
                }
            }

            if (String.isNotBlank(plannedEndTime)) {
                try {
                    existingCase.Planned_End_Time__c = parseTime(plannedEndTime);
                } catch (Exception e) {
                    row.put('Error', 'Invalid Planned_End_Time__c format. Use HH:mm or HH:mm:ss');
                    errors.add(row);
                    hasValidationError = true;
                }
            }



            // Skip adding to update list if there were validation errors
            if (hasValidationError) {
                continue;
            }

            casesToUpdate.add(existingCase);

            // Prepare success response
            Map<String, String> successRecord = new Map<String, String>{
                'Docket_Number__c' => docketNumber,
                'Status' => 'Actioned by Department', // Always include status in response
                'Id' => existingCase.Id
            };
            
            // Only include fields that were provided in the CSV
            if (String.isNotBlank(standardRemarks)) {
                successRecord.put('Standard_Remarks__c', standardRemarks);
            }
            if (String.isNotBlank(plannedStartDate)) {
                successRecord.put('Planned_Start_date__c', plannedStartDate);
            }
            if (String.isNotBlank(plannedEndDate)) {
                successRecord.put('Planned_End_Date__c', plannedEndDate);
            }
            if (String.isNotBlank(plannedStartTime)) {
                successRecord.put('Planned_Start_Time__c', plannedStartTime);
            }
            if (String.isNotBlank(plannedEndTime)) {
                successRecord.put('Planned_End_Time__c', plannedEndTime);
            }

            
            successes.add(successRecord);
        }

        if (!casesToUpdate.isEmpty()) {
            Database.SaveResult[] results = Database.update(casesToUpdate, false);
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    String errorMessage = results[i].getErrors().isEmpty() ? 'Unknown error' : results[i].getErrors()[0].getMessage();
                    
                    Map<String, String> errorRecord = new Map<String, String>{
                        'Docket_Number__c' => casesToUpdate[i].Docket_Number__c,
                        'Status' => 'Actioned by Department', // Always include status in error response
                        'Error' => errorMessage
                    };
                    
                    // Include optional fields in error response if they exist
                    if (casesToUpdate[i].Standard_Remarks__c != null) {
                        errorRecord.put('Standard_Remarks__c', casesToUpdate[i].Standard_Remarks__c);
                    }
                    if (casesToUpdate[i].Planned_Start_date__c != null) {
                        errorRecord.put('Planned_Start_date__c', String.valueOf(casesToUpdate[i].Planned_Start_date__c));
                    }
                    if (casesToUpdate[i].Planned_End_Date__c != null) {
                        errorRecord.put('Planned_End_Date__c', String.valueOf(casesToUpdate[i].Planned_End_Date__c));
                    }
                    if (casesToUpdate[i].Planned_Start_Time__c != null) {
                        errorRecord.put('Planned_Start_Time__c',String.valueOf(casesToUpdate[i].Planned_Start_Time__c));
                    }
                    if (casesToUpdate[i].Planned_End_Time__c != null) {
                        errorRecord.put('Planned_End_Time__c',String.valueOf(casesToUpdate[i].Planned_End_Time__c));
                    }

                    
                    errors.add(errorRecord);

                    // Remove from successes
                    for (Integer j = 0; j < successes.size(); j++) {
                        if (successes[j].get('Id') == casesToUpdate[i].Id) {
                            successes.remove(j);
                            break;
                        }
                    }
                }
            }
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

    private static Time parseTime(String timeStr) {
        // Accept HH:mm or HH:mm:ss
        List<String> parts = timeStr.split(':');
        
        if (parts.size() < 2 || parts.size() > 3) {
            throw new IllegalArgumentException('Invalid time format');
        }

        Integer hour = Integer.valueOf(parts[0]);
        Integer minute = Integer.valueOf(parts[1]);
        Integer second = parts.size() == 3 ? Integer.valueOf(parts[2]) : 0;

        if (hour < 0 || hour > 23 || minute < 0 || minute > 59 || second < 0 || second > 59) {
            throw new IllegalArgumentException('Invalid time value');
        }

        return Time.newInstance(hour, minute, second, 0);
    }


}