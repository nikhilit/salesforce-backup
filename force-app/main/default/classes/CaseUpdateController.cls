public with sharing class CaseUpdateController {

    @AuraEnabled(cacheable=true)
    public static CaseDataWrapper getCaseData(Id caseId) {
        try {
            System.debug('Fetching case data for ID: ' + caseId);
            
            if (caseId == null) {
                throw new AuraHandledException('Case ID is required');
            }

            List<Case> cases = [SELECT Id, Comments, Outgoing_Calls_Count__c, 
                                       Outbound_Call_1_Done_By__c, Outbound_Call_1_Done_Time__c, Outbound_Call_1_Remarks__c,
                                       Outbound_Call_2_Done_By__c, Outbound_Call_2_Done_Time__c, Outbound_Call_2_Remarks__c,
                                       Outbound_Call_3_Done_By__c, Outbound_Call_3_Done_Time__c, Outbound_Call_3_Remarks__c
                                FROM Case 
                                WHERE Id = :caseId 
                                LIMIT 1];
            
            if (cases.isEmpty()) {
                throw new AuraHandledException('Case record not found. Please check if the record exists and you have access to it.');
            }
            
            Case c = cases[0];
            CaseDataWrapper wrapper = new CaseDataWrapper();
            wrapper.caseRecord = c;
            // Disable save if all 3 call slots are filled
            wrapper.isSaveDisabled = (c.Outbound_Call_1_Remarks__c != null && 
                                     c.Outbound_Call_2_Remarks__c != null && 
                                     c.Outbound_Call_3_Remarks__c != null);
            wrapper.hasError = false;
            
            System.debug('Case data fetched successfully: ' + c.Id);
            return wrapper;
            
        } catch (Exception e) {
            System.debug('Error in getCaseData: ' + e.getMessage() + ' - ' + e.getStackTraceString());
            throw new AuraHandledException('Unable to load case data: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String updateRemarksAndCount(Id caseId, String remarks) {
        try {
            System.debug('Updating case: ' + caseId + ' with remarks: ' + remarks);
            
            if (caseId == null) {
                throw new AuraHandledException('Case ID is required');
            }
            
            if (remarks == null || remarks.trim() == '') {
                throw new AuraHandledException('Remarks are required');
            }

            // Get current user info
            User currentUser = [SELECT Id, Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            
            // Get current case with all outbound call fields using list to avoid no rows error
            List<Case> cases = [SELECT Id, Comments, Outgoing_Calls_Count__c, Status, OwnerId, 
                                       Outbound_Call_1_Done_By__c, Outbound_Call_1_Done_Time__c, Outbound_Call_1_Remarks__c,
                                       Outbound_Call_2_Done_By__c, Outbound_Call_2_Done_Time__c, Outbound_Call_2_Remarks__c,
                                       Outbound_Call_3_Done_By__c, Outbound_Call_3_Done_Time__c, Outbound_Call_3_Remarks__c,Department_Responded_On__c
                                FROM Case 
                                WHERE Id = :caseId 
                                LIMIT 1];
            
            if (cases.isEmpty()) {
                throw new AuraHandledException('Case record not found. Please check if the record exists and you have access to it.');
            }
            
            Case c = cases[0];
            
            // Check if all 3 call slots are already filled
            if (c.Outbound_Call_1_Remarks__c != null && 
                c.Outbound_Call_2_Remarks__c != null && 
                c.Outbound_Call_3_Remarks__c != null) {
                throw new AuraHandledException('Maximum of 3 outbound call remarks allowed. No further updates permitted.');
            }
            
            // Call separate method to handle outbound call updates
            updateOutboundCallFields(c, currentUser.Name, remarks.trim());
            
            // Update the call count
            Integer newOutgoingCount;                     
            if (c.Outgoing_Calls_Count__c == null) {      
                newOutgoingCount = 1;                     
            } else {                                      
                newOutgoingCount = (Integer)c.Outgoing_Calls_Count__c + 1; 
            }
            c.Outgoing_Calls_Count__c = newOutgoingCount;
            
            // NEW LOGIC: Save remarks to Comments field
            String timestamp = DateTime.now().format('yyyy-MM-dd HH:mm:ss');
            String commentPrefix = 'Outbound Call - ' + timestamp + ' - ' + currentUser.Name + ':\n';
            
            if (c.Comments == null) {
                c.Comments = commentPrefix + remarks.trim();
            } else {
                c.Comments = c.Comments + '\n\n' + commentPrefix + remarks.trim();
            }
            
            c.Last_Remarks__c = (remarks == null) ? null : remarks.trim();

            createCallCenterSLARecord(c, newOutgoingCount, remarks.trim());

            update c;

            
            System.debug('Case updated successfully with comments');
            return 'SUCCESS';
            
        } catch (Exception e) {
            System.debug('Error in updateRemarksAndCount: ' + e.getMessage() + ' - ' + e.getStackTraceString());
            throw new AuraHandledException('Error updating case: ' + e.getMessage());
        }
    }
    
    // Separate method to handle outbound call fields update
    private static void updateOutboundCallFields(Case c, String userName, String remarks) {
        // Get current datetime
        String currentTime = DateTime.now().format('yyyy-MM-dd HH:mm:ss');
        
        // Determine which call slot to update
        if (c.Outbound_Call_1_Remarks__c == null) {
            // Update Outbound Call 1 fields
            c.Outbound_Call_1_Done_By__c = userName;
            c.Outbound_Call_1_Done_Time__c = currentTime;
            c.Outbound_Call_1_Remarks__c = remarks;
            System.debug('Updated Outbound Call 1 fields');
        } else if (c.Outbound_Call_2_Remarks__c == null) {
            // Update Outbound Call 2 fields
            c.Outbound_Call_2_Done_By__c = userName;
            c.Outbound_Call_2_Done_Time__c = currentTime;
            c.Outbound_Call_2_Remarks__c = remarks;
            System.debug('Updated Outbound Call 2 fields');
        } else if (c.Outbound_Call_3_Remarks__c == null) {
            // Update Outbound Call 3 fields
            c.Outbound_Call_3_Done_By__c = userName;
            c.Outbound_Call_3_Done_Time__c = currentTime;
            c.Outbound_Call_3_Remarks__c = remarks;
            System.debug('Updated Outbound Call 3 fields');
        }
    }

    private static void createCallCenterSLARecord(Case c, Integer outgoingCount, String remarks) {
        if (c.Id == null) return;
        DateTime nowDt = System.now();
        
        Call_Center_SLA__c sla = new Call_Center_SLA__c();
        sla.Status__c               = c.Status;                
        sla.Remarks__c              = remarks;                 
        sla.Outgoing_Count__c       = outgoingCount;           
        sla.Created_Date__c         = nowDt.date();            
        sla.Created_Time__c         = nowDt.time();            
        sla.Case__c                 = c.Id;                        
        sla.Activity__c='Outbound';
        sla.Call_Center_Agent__c    = UserInfo.getUserId();  
        sla.Department_Responded_On__c=c.Department_Responded_On__c; 
        insert sla;
        System.debug('Created Call_Center_SLA__c record: ' + sla.Id);
    }
    
    // Wrapper class to return both case data and save disabled status
    public class CaseDataWrapper {
        @AuraEnabled public Case caseRecord { get; set; }
        @AuraEnabled public Boolean isSaveDisabled { get; set; }
        @AuraEnabled public Boolean hasError { get; set; }
        @AuraEnabled public String errorMessage { get; set; }
        
        public CaseDataWrapper() {
            this.hasError = false;
            this.errorMessage = '';
        }
    }
}