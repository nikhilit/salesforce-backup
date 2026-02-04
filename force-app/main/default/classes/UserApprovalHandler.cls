/**
* @File Name : UserApprovalHandler.cls
* @Description : Collection agent Approval Process
* @Author : Shruthi
* @Last Modified On : May 21, 2025
**/
public with sharing class UserApprovalHandler {
    
    @AuraEnabled
    public static void submitServiceResourceForApproval(Id serviceResourceId) {
        // Get the ServiceResource record
        ServiceResource sr = [
            SELECT Id
            FROM ServiceResource
            WHERE Id = :serviceResourceId
            LIMIT 1
        ];

        // Get current logged-in user Id
        Id currentUserId = UserInfo.getUserId();

        // Get the current user and their ManagerId
        User currentUser = [
            SELECT Id, ManagerId
            FROM User
            WHERE Id = :currentUserId
            LIMIT 1
        ];

        if (currentUser.ManagerId == null) {
            throw new AuraHandledException('Your manager is not defined. Approval cannot be submitted.');
        }

        // Submit for approval and assign to current user's Manager
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(sr.Id);
        req.setProcessDefinitionNameOrId('Collection_Agent_Approval'); // Replace with your actual API name
        req.setSkipEntryCriteria(false);
        req.setNextApproverIds(new Id[] { currentUser.ManagerId });

        Approval.ProcessResult result = Approval.process(req);

        if (!result.isSuccess()) {
            throw new AuraHandledException('Approval submission failed. Status: ' + result.getInstanceStatus());
        }
    }

    @AuraEnabled(cacheable=true)
    public static String getApprovalStatus(Id serviceResourceId) {
        List<ProcessInstance> piList = [
            SELECT Status
            FROM ProcessInstance
            WHERE TargetObjectId = :serviceResourceId
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        
        if (piList.isEmpty()) {
            return 'None'; // No approval process started
        }
        
        return piList[0].Status; // e.g., 'Pending', 'Approved', 'Rejected'
    }
}