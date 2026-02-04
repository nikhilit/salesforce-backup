global class MilestoneCalculation implements Support.MilestoneTriggerTimeCalculator {   
    global Integer calculateMilestoneTriggerTime(String caseId, String milestoneTypeId) {
        Integer calculatedTime = 1; // Default in minutes

        try {
            // Get Case fields
            Case c = [
                SELECT Remaining_TAT__c
                FROM Case 
                WHERE Id = :caseId 
                LIMIT 1
            ];
             if (String.isNotBlank(c.Remaining_TAT__c)) {
                calculatedTime = Integer.valueOf(c.Remaining_TAT__c);
            } 

        } catch (Exception ex) {
            Error_Logger__c err=Error_LoggerClass.createErrorLogger('MilestoneCalculation', 'calculateMilestoneTriggerTime',null,ex.getTypeName(), ex.getMessage(),ex.getLineNumber(),true);
            insert err;
        }
        return calculatedTime;
    }
}