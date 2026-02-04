trigger CaseTrigger on Case (after insert,before insert,before update,after update) {
    if (!TriggerController.isTriggerActive('CaseTrigger')) {
        return;
    }
    String loggedInUserProfileName;

    User u = [
        SELECT Profile.Name
        FROM User
        WHERE Id = :UserInfo.getUserId()
        LIMIT 1
    ];

    loggedInUserProfileName = u.Profile.Name;

    if(trigger.isafter && trigger.isInsert){
        CaseTriggerHandler.populateDocketNumber(Trigger.new);
        CaseTriggerHandler.mergeCases(Trigger.new);
        CaseTriggerHandler.sendCaseCreationSms(Trigger.newMap.keySet());
        CaseTriggerHandler.handleContactDetailsUpdateToSAP(Trigger.new, null);
        //CaseTriggerHandler.createCaseLedgerOnCaseCreation(Trigger.new);
        
    }
    else if(trigger.isafter && (trigger.isInsert ||trigger.isUpdate) ){
        CaseTriggerHandler.updatemilestone(Trigger.new,Trigger.oldMap);
        CaseTriggerHandler.createWorkOrders(Trigger.new,Trigger.oldMap);
        CaseTriggerHandler.createWorkOrdersforOM(Trigger.new,Trigger.oldMap);
    }
     else if (Trigger.isBefore && (Trigger.isInsert || trigger.isUpdate)) { 
        CaseTriggerHandler.convertNameTransferFieldsToUpper(Trigger.new);
         
       	CaseTriggerHandler.handleTAT(Trigger.new, Trigger.oldMap);
       	
      	CaseTriggerHandler.setStatusForQueryCases(Trigger.new, Trigger.oldMap);
        CaseTriggerHandler.SAPAutomations(Trigger.new,Trigger.oldMap);
        CaseTriggerHandler.validateCaseStatus(Trigger.new, Trigger.oldMap);
        CaseTriggerHandler.setStatusForContactDetailsUpdate(Trigger.new);
        CaseTriggerHandler.blockRecentNameCorrectionCases(Trigger.new, loggedInUserProfileName);
        CaseTriggerHandler.setStatusForAMRUpdate(Trigger.new);
         

    }
     if (Trigger.isBefore && Trigger.isInsert) {
         
        CaseTriggerHandler.updateSalutationValues(Trigger.new);
        //CaseTriggerHandler.mapBulkInsertValues(Trigger.new);
         
       
   }
     if (Trigger.isBefore && Trigger.isUpdate) {
        CaseTriggerHandler.captureViolationTimestamps( Trigger.new,Trigger.oldMap);
         CaseTriggerHandler.updateTatWarning(Trigger.new, Trigger.oldMap);
        CaseTriggerHandler.handleDuplicateCheck(Trigger.new,Trigger.oldMap);
         CaseTriggerHandler.handleFRLSentUpdate(Trigger.new, Trigger.oldMap);
         CaseTriggerHandler.mapDepartmentAndSPOC(Trigger.new, loggedInUserProfileName);
         
   }
  

     // Call SMS logic after update
    if (Trigger.isAfter && Trigger.isUpdate) {
        CaseTriggerHandler.handleViolationCases(Trigger.new, Trigger.oldMap);
        CaseTriggerHandler.validateAndTransferInternalComments(Trigger.new, Trigger.oldMap, loggedInUserProfileName);
        CaseTriggerHandler.processCasesAfterUpdate(Trigger.new, Trigger.oldMap);
        CaseTriggerHandler.sendResolvedSms(Trigger.new, Trigger.oldMap, loggedInUserProfileName);
        CaseTriggerHandler.handleDocumentsandOutstandingChanged(Trigger.new, Trigger.oldMap);
        CaseTriggerHandler.handleContactDetailsUpdateToSAP(Trigger.new, Trigger.oldMap);
        CaseTriggerHandler.ccSLAForOwnerChange(Trigger.new, Trigger.oldMap);
       

        //O&M update workorder and account
        OMCaseWorkOrderTriggerHandler.updateOMWorkOrderAndAccount(Trigger.new, Trigger.oldMap);

    }   
}