public with sharing class CaseReassignmentController {

    @AuraEnabled
    public static void reassignCaseToPreviousSpoc(Id caseId, String remarks) {
        if (caseId == null) {
            throw new AuraHandledException('No Case ID provided.');
        }

        try {
            // Step 1: Fetch Case and related Account
            Case cs = [
                SELECT Id, Department__c, SPOC__c, TAT_in_minutes__c, Status,
                       Case_Violation__c, Remaining_TAT__c,
                       Remaining_Tat_2__c, Remaining_Tat_3__c,
                       Case_Violation1__c, Case_Violation2__c,
                       Account.DRS_Master__c, Comments
                FROM Case
                WHERE Id = :caseId
                LIMIT 1
            ];

            // Step 2: Validation - Check if case is resolved
            if (cs.Status == 'Resolved') {
                throw new AuraHandledException('Re-assignment cannot be done for resolved cases.');
            }

            // Step 3: Other validations
            if (cs.Department__c == null) {
                throw new AuraHandledException('Department is missing for Case Id: ' + cs.Id);
            }
            if (cs.Account == null) {
                throw new AuraHandledException('No Account linked to this Case.');
            }
            if (cs.Account.DRS_Master__c == null) {
                throw new AuraHandledException('DRS is missing on the BP for Case Id: ' + cs.Id);
            }

            // Step 4: Fetch SPOC mapping
            Departments_SPOC_Mapping__c mapping = [
                SELECT Department__c, DRS__c, SPOC_Id__c, SPOC_Id_2__c, SPOC_Id_3__c, SPOC_Id_4__c
                FROM Departments_SPOC_Mapping__c
                WHERE Department__c = :cs.Department__c AND DRS__c = :cs.Account.DRS_Master__c
                LIMIT 1
            ];

            // Step 5: Determine previous SPOC
            Id currentSpoc = cs.SPOC__c;
            Id newSpoc;

            if (currentSpoc == mapping.SPOC_Id_4__c) {
                newSpoc = mapping.SPOC_Id_3__c;
                cs.Case_Violation2__c = false;
                cs.Remaining_Tat_3__c = '540';
            } else if (currentSpoc == mapping.SPOC_Id_3__c) {
                newSpoc = mapping.SPOC_Id_2__c;
                cs.Case_Violation1__c = false;
                cs.Remaining_Tat_2__c = '540';
            } else if (currentSpoc == mapping.SPOC_Id_2__c) {
                newSpoc = mapping.SPOC_Id__c;
                cs.Case_Violation__c = false;
                cs.Remaining_TAT__c = cs.TAT_in_minutes__c;
            } else {
                throw new AuraHandledException('Unable to determine previous SPOC');
            }

            if (newSpoc == null) {
                throw new AuraHandledException('Previous SPOC not found in mapping for Case');
            }

            // Step 6: Update Case
            cs.SPOC__c = newSpoc;
            cs.Comments = remarks;

            // Update status and tracking fields
            cs.Status = 'In-Progress';
            cs.Current_Work_Type__c = '1';
            cs.Assigned_To__c = newSpoc;

            update cs;

        } catch (AuraHandledException ahe) {
            // Re-throw AuraHandledExceptions directly without logging
            throw ahe;
        } catch (Exception ex) {
            // Log and throw generic error for other exceptions
            Error_Logger__c err = Error_LoggerClass.createErrorLogger(
                'CaseReassignmentController', 'reassignCaseToPreviousSpoc',
                caseId, ex.getTypeName(), ex.getMessage(),
                ex.getLineNumber(), true
            );
            insert err;

            throw new AuraHandledException('An error occurred while reassigning the Case. Please contact your admin.');
        }
    }
}