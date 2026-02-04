public with sharing class CaseQuickActionController {
@AuraEnabled
public static String getCaseStatus(Id caseId) {
    return [SELECT Status FROM Case WHERE Id = :caseId LIMIT 1].Status;
}
@AuraEnabled(cacheable=true)
public static Case getCaseDepartmentAndType(Id caseId) {
    return [
        SELECT Department__c, Type__c
        FROM Case
        WHERE Id = :caseId
        LIMIT 1
    ];
}
   @AuraEnabled
    public static String saveCaseData(Id caseId, String newStatus, String commentBody) {
            try {
                if (caseId == null) {
                    throw new AuraHandledException('Case Id is required.');
                }

                // Determine the status we will store in SLA
                String effectiveStatus;

                if (String.isNotBlank(newStatus)) {
                    Case c = new Case(Id = caseId, Status = newStatus);
                    c.Last_Remarks__c = (commentBody == null) ? null : commentBody.trim();
                    update c;
                    effectiveStatus = newStatus;
                } else {
                    // If no new status passed, use existing status from Case
                    effectiveStatus = [
                        SELECT Status
                        FROM Case
                        WHERE Id = :caseId
                        LIMIT 1
                    ].Status;
                }

                String trimmedComment = (commentBody == null) ? null : commentBody.trim();

                if (String.isNotBlank(trimmedComment)) {
                    CaseComment cc = new CaseComment(
                        ParentId = caseId,
                        CommentBody = trimmedComment
                    );
                    insert cc;
                }

                User currentUser = [
                    SELECT Id, Profile.Name
                    FROM User
                    WHERE Id = :UserInfo.getUserId()
                    LIMIT 1
                ];
                
                if (currentUser.Profile.Name == 'CRM CallCenter Agent') { 
                    createCallCenterSLAForQuickAction(caseId, effectiveStatus, trimmedComment);  
                }

                return 'SUCCESS';
            } catch (Exception e) {
                // Throw as AuraHandledException so LWC gets your custom message
                throw new AuraHandledException(e.getMessage());
            }
        }

    //OLD Version
    // @AuraEnabled
    // public static String saveCaseData(Id caseId, String newStatus, String commentBody) {
    //     try {
    //         if (String.isNotBlank(newStatus)) {
    //             Case c = new Case(Id = caseId, Status = newStatus);
    //             update c;
    //         }

    //         if (String.isNotBlank(commentBody)) {
    //             CaseComment cc = new CaseComment(
    //                 ParentId = caseId,
    //                 CommentBody = commentBody
    //             );
    //             insert cc;
    //         }
    //         return 'SUCCESS';
    //     } catch (Exception e) {
    //         // Throw as AuraHandledException so LWC gets your custom message
    //         throw new AuraHandledException(e.getMessage());
    //     }
    // }    


    public static void createCallCenterSLAForQuickAction(Id caseId, String status, String remarks) {
    
        DateTime nowDt = System.now();
         Case currentCase = [
            SELECT Department_Responded_On__c 
            FROM Case 
            WHERE Id = :caseId 
            LIMIT 1
        ];

        Call_Center_SLA__c sla = new Call_Center_SLA__c();
        sla.Status__c               = status;         
        sla.Remarks__c              = remarks;        
        sla.Created_Date__c         = nowDt.date();   
        sla.Created_Time__c         = nowDt.time();  
        sla.Activity__c='Closure';
        sla.Case__c = caseId;  
        sla.Call_Center_Agent__c    = UserInfo.getUserId(); 
        sla.Department_Responded_On__c = currentCase.Department_Responded_On__c;    

        insert sla;
    }

	@AuraEnabled(cacheable=true)
    public static String getCurrentUserProfileName() {
        return [
            SELECT Profile.Name 
            FROM User 
            WHERE Id = :UserInfo.getUserId()
        ].Profile.Name;
    }

    @AuraEnabled(cacheable=true)
    public static String getCurrentUserName() {
        return [
            SELECT Name
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ].Name;
    }

}