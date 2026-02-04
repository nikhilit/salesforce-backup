public without sharing class AS_CaseOMCSVUploaderController {

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
    public static Map<String, Object> uploadCSVBatch(String objectName, String approvalStatus, List<Map<String,String>> csvRecords) {
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
        // if (!headers.contains('Docket_Number__c')) {
        //     return new Map<String,Object>{
        //         'successCount' => 0,
        //         'errors' => new List<Map<String,String>>{
        //             new Map<String,String>{ 'Error' => 'CSV must contain Docket_Number__c column. Optional columns: Standard_Remarks__c, Planned_Start_date__c, Planned_End_Date__c' }
        //         },
        //         'successes' => new List<Map<String,String>>()
        //     };
        // }

        try {
            if(approvalStatus =='Approved'){
            return processChunk(objectName,csvRecords);
            }
            else {

                return processChunkRejected(objectName,approvalStatus,csvRecords);

            }
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
      

        Set<String> caseId = new Set<String>();
        for (Map<String,String> row : csvRecords) {
            if (row.containsKey('Case Id') && String.isNotBlank(row.get('Case Id'))) {
                caseId.add(row.get('Case Id'));
            }
        }

        Map<String, Case> caseMap = new Map<String, Case>();
        for (Case c : [SELECT Id, Status, Standard_Remarks__c, Work_Order_ID__c,Move_Out_Date_BP__c,
								Approval_Status_AIC__c,Move_Out_Date__c
                       FROM Case WHERE Id IN :caseId]) {
            caseMap.put(c.Id, c);
        }

        List<Case> casesToUpdate = new List<Case>();
        List<Map<String,String>> errors = new List<Map<String,String>>();
        List<Map<String,String>> successes = new List<Map<String,String>>();

        for (Map<String,String> row : csvRecords) {
            String csId = row.get('Case Id');
            String standardRemarks = row.get('Standard_Remarks__c');
            String status = row.get('Status');
            String woId = row.get('Work_Order_ID__c');
			String moveOutBP = row.get('Move_Out_Date_BP__c');
			String approvalStatusAIC = 'Approved';

            //String approvalStatusAIC = row.get('Approval_Status_AIC__c');
            String casenumber =row.get('Case Number');
            String bpnumber =row.get('BP Number');
            String woNumber =row.get('Work Order Number');
             String customerName = row.get('Customer Name');

            if (String.isBlank(csId)) {
                row.put('Error', 'Id cannot be blank');
                errors.add(row);
                continue;
            }

            if (!caseMap.containsKey(csId)) {
                row.put('Error', 'Case not found with ID: ' + csId);
                errors.add(row);
                continue;
            }

            Case existingCase = caseMap.get(csId);
            
            // Update fields - all fields are optional except Docket_Number__c
            // Status is always set to 'Actioned by Department'
                    
        //   if (String.isNotBlank(status)) {

        //     existingCase.Status = status;
        //   }
            
            boolean hasValidationError = false;
            
            if (String.isNotBlank(standardRemarks)) {
                existingCase.Standard_Remarks__c = standardRemarks;
            }
            
          //  if (String.isNotBlank(approvalStatusAIC)) {
             //   try {
                    existingCase.Approval_Status_AIC__c = approvalStatusAIC;
                   // if(approvalStatusAIC =='Approved'){
                        
                      existingCase.Status = 'Actioned by Department';

                 //   }
                    //  if(approvalStatusAIC =='Rejected'){
                        
                    //   existingCase.Status = 'In-Progress';

                    // }
              //  } catch (Exception e) {
                    // row.put('Error', 'Invalid Planned_Start_date__c format. Use YYYY-MM-DD');
                    // errors.add(row);
                    // hasValidationError = true;
              //  }
          //  }

            if (String.isNotBlank(woId)) {
                try {
                    existingCase.Work_Order_ID__c = woId;
                } catch (Exception e) {
                    // row.put('Error', 'Invalid Planned_Start_date__c format. Use YYYY-MM-DD');
                    // errors.add(row);
                    // hasValidationError = true;
                }
            }
			
            
            if (String.isNotBlank(moveOutBP)) {
                try {
                    existingCase.Move_Out_Date_BP__c = Date.valueOf(moveOutBP);
                    existingCase.Move_Out_Date__c = Date.valueOf(moveOutBP);

                } catch (Exception e) {
                    row.put('Error', 'Invalid Move_Out_Date_BP__c format. Use YYYY-MM-DD');
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
                
                'Case Id' => existingCase.Id
            };
            
            // Only include fields that were provided in the CSV
            if (String.isNotBlank(standardRemarks)) {
                successRecord.put('Standard_Remarks__c', standardRemarks);
            }
            if (String.isNotBlank(status)) {
                successRecord.put('Status', status);
            }
            if (String.isNotBlank(moveOutBP)) {
                successRecord.put('Move_Out_Date_BP__c', moveOutBP);
            }
            //  if (String.isNotBlank(approvalStatusAIC)) {
            //     successRecord.put('Approval_Status_AIC__c', approvalStatusAIC);
            // }
              if (String.isNotBlank(woId)) {
                successRecord.put('Work_Order_ID__c', woId);
            }

               if (String.isNotBlank(caseNumber)) {
                successRecord.put('Case Number', caseNumber);
            }
             if (String.isNotBlank(bpnumber)) {
                successRecord.put('BP Number', bpnumber);
            }
             if (String.isNotBlank(bpnumber)) {
                successRecord.put('BP Number', bpnumber);
            }
             if (String.isNotBlank(woNumber)) {
                successRecord.put('Work Order Number', woNumber);
            }
             if (String.isNotBlank(csId)) {
                successRecord.put('Case Id', csId);
            }
             if (String.isNotBlank(customerName)) {
                successRecord.put('Customer Name', customerName);
            }
            
            successes.add(successRecord);
        }

        if (!casesToUpdate.isEmpty()) {
            Database.SaveResult[] results = Database.update(casesToUpdate, false);
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    String errorMessage = results[i].getErrors().isEmpty() ? 'Unknown error' : results[i].getErrors()[0].getMessage();
                    
                    Map<String, String> errorRecord = new Map<String, String>{
                        'Error' => errorMessage
                    };
                    
                    // Include optional fields in error response if they exist
                    if (casesToUpdate[i].Standard_Remarks__c != null) {
                        errorRecord.put('Standard_Remarks__c', casesToUpdate[i].Standard_Remarks__c);
                    }
                    // if (casesToUpdate[i].Planned_Start_date__c != null) {
                    //     errorRecord.put('Planned_Start_date__c', String.valueOf(casesToUpdate[i].Planned_Start_date__c));
                    // }
                    if (casesToUpdate[i].Move_Out_Date_BP__c != null) {
                        errorRecord.put('Move_Out_Date_BP__c', String.valueOf(casesToUpdate[i].Move_Out_Date_BP__c));
                    }
                      if (casesToUpdate[i].Status != null) {
                        errorRecord.put('Status', String.valueOf(casesToUpdate[i].Status));
                    }
                    //   if (casesToUpdate[i].Approval_Status_AIC__c != null) {
                    //     errorRecord.put('Approval_Status_AIC__c', String.valueOf(casesToUpdate[i].Approval_Status_AIC__c));
                    // }
                        if (casesToUpdate[i].Work_Order_ID__c != null) {
                        errorRecord.put('Work_Order_ID__c', String.valueOf(casesToUpdate[i].Work_Order_ID__c));
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

    public static Map<String,Object> processChunkRejected(String objectName,String approvalStatus, List<Map<String,String>> csvRecords) {
      
              system.debug('Approval status value :::'+ approvalStatus);

     

         Set<String> woIds = new Set<String>();
        for (Map<String,String> row : csvRecords) {
            if (row.containsKey('Case Id') && String.isNotBlank(row.get('Case Id'))) {
                woIds.add(row.get('Work_Order_ID__c'));
            }
        }

        system.debug('work order ids::'+ woIds);

        Map<String, WorkOrder> workorderMap = new Map<String, WorkOrder>();
        
        for (WorkOrder wo : [SELECT Id,CaseId,Approval_Status_AIC__c,AICRemark__c 
                       FROM WorkOrder WHERE Id IN :woIds]) {
            workorderMap.put(wo.Id, wo);
        }

        system.debug('workorderMap::'+ workorderMap);

        List<WorkOrder> workOrderToUpdate = new List<WorkOrder>();
        List<Map<String,String>> errors = new List<Map<String,String>>();
        List<Map<String,String>> successes = new List<Map<String,String>>();

        for (Map<String,String> row : csvRecords) {

            system.debug('inside for loop to assing value to field');

             String csId = row.get('Case Id');
             String standardRemarks = row.get('Standard_Remarks__c');
            // String status = row.get('Status');
			// String moveOutBP = row.get('Move_Out_Date_BP__c');
			String approvalStatusAIC = 'Rejected';
             String woId = row.get('Work_Order_ID__c');
             String customerName = row.get('Customer Name');


            //String approvalStatusAIC = row.get('Approval_Status_AIC__c');
             String casenumber =row.get('Case Number');
             String bpnumber =row.get('BP Number');
            String woNumber =row.get('Work Order Number');

            if (String.isBlank(csId)) {
                system.debug('inside csid blank');
                row.put('Error', 'Id cannot be blank');
                errors.add(row);
                continue;
            }

            Id caseSafeWoId = Id.valueOf(woId);

             



            if (!workorderMap.containsKey(caseSafeWoId)) {
                system.debug('inside work order id founded if condition'+ caseSafeWoId);
                row.put('Error', 'Work Order not found with ID: ' + woId);
                errors.add(row);
                continue;
            }

                WorkOrder existingWorkOrder = workorderMap.get(caseSafeWoId);

            existingWorkOrder.Approval_Status_AIC__c = 'Rejected';

            system.debug('existingWorkOrder.Approval_Status_AIC__c::'+ existingWorkOrder.Approval_Status_AIC__c);
            
            if (String.isNotBlank(standardRemarks)) {

                system.debug('standard remark not empty::'+ standardRemarks);
                        existingWorkOrder.AICRemark__c = standardRemarks;
                    }
            		
            
            system.debug('before assign to list existingWorkOrder::'+ existingWorkOrder);

            workOrderToUpdate.add(existingWorkOrder);


            system.debug('workOrderToUpdate::'+ workOrderToUpdate);

            // Prepare success response
            Map<String, String> successRecord = new Map<String, String>{
                
                'Case Id' => existingWorkOrder.CaseId
            };
            
            // Only include fields that were provided in the CSV
            if (String.isNotBlank(standardRemarks)) {
                successRecord.put('Standard_Remarks__c', standardRemarks);
            }
           
              if (String.isNotBlank(woId)) {
                successRecord.put('Work_Order_ID__c', woId);
            }

               if (String.isNotBlank(caseNumber)) {
                successRecord.put('Case Number', caseNumber);
            }
             if (String.isNotBlank(bpnumber)) {
                successRecord.put('BP Number', bpnumber);
            }
          
             if (String.isNotBlank(woNumber)) {
                successRecord.put('Work Order Number', woNumber);
            }
             if (String.isNotBlank(customerName)) {
                successRecord.put('Customer Name', customerName);
            }
             if (String.isNotBlank(csId)) {
                successRecord.put('Case Id', csId);
            }
            
            successes.add(successRecord);
        }

        if (!workOrderToUpdate.isEmpty()) {
            Database.SaveResult[] results = Database.update(workOrderToUpdate, false);
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    String errorMessage = results[i].getErrors().isEmpty() ? 'Unknown error' : results[i].getErrors()[0].getMessage();
                    
                    Map<String, String> errorRecord = new Map<String, String>{
                        'Error' => errorMessage
                    };
                    
                    
                    errors.add(errorRecord);

                    // Remove from successes
                    for (Integer j = 0; j < successes.size(); j++) {
                        if (successes[j].get('Id') == workOrderToUpdate[i].Id) {
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
}