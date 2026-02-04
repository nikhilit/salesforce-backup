/**
 * @File Name : ApprovalController.cls
 * @Description :
 * @Author :
 * @Last Modified By :
 * @Last Modified On : August 6, 2025
 * @Modification Log :
 *==============================================================================
 * Ver | Date | Author | Modification
 *==============================================================================
 * 1.0 | August 6, 2025 |   | Initial Version
 **/

public without sharing class ApprovalController {
    
    @AuraEnabled
    public static List<ApprovalWrapClass> getApprovalRequests() {
        System.debug('Fetching approval requests for user: ' + UserInfo.getUserId());
        try{
            // List<Approval_Request_Type__mdt> approvalMappingQuery = [SELECT Id,DeveloperName,Tab_Name__c,Approval_process_Name__c
        //                                                     FROM Approval_Request_Type__mdt  
        //                                                    ];
            // Map<String,String> TabAndApprovalMap = new Map<String,String>();
            // for(Approval_Request_Type__mdt item : approvalMappingQuery){
                //     TabAndApprovalMap.put(item.Approval_process_Name__c,item.Tab_Name__c);
            // }
            
            // System.debug('TabAndApprovalMap: ' + TabAndApprovalMap);
            
            List<ProcessInstanceWorkitem> approvalRequests =  [SELECT Id, ActorId, ProcessInstance.TargetObjectId, 
                                        ProcessInstance.TargetObject.Name, ProcessInstance.Status, 
                                        ProcessInstance.ProcessDefinition.Name, 
                                        ProcessInstance.ProcessDefinition.DeveloperName,ProcessInstance.CreatedBy.Name, 
                                        CreatedDate
                                    FROM ProcessInstanceWorkitem
                                    WHERE ActorId = :UserInfo.getUserId()
                                    AND ProcessInstance.Status = 'Pending' 
                                    AND ((ProcessInstance.ProcessDefinition.DeveloperName Like '%TBT' AND CreatedDate=TODAY) 
                                        OR ProcessInstance.ProcessDefinition.DeveloperName Like '%SiteDocumentApprovalProcess')
                                    ORDER BY CreatedDate ASC
            ];
            System.debug('approvalRequests: ' + approvalRequests);

         Set<Id> workOrderIds = new Set<Id>();
        for (ProcessInstanceWorkitem item : approvalRequests) {
            if (item.ProcessInstance.TargetObjectId != null) {
                workOrderIds.add(item.ProcessInstance.TargetObjectId);
            }
        }

        // 🔹 Query BP_Number__c from related WorkOrders
        Map<Id, WorkOrder> workOrderMap = new Map<Id, WorkOrder>(
            [SELECT Id, BP_Number__c FROM WorkOrder WHERE Id IN :workOrderIds]
        );



            List<ApprovalWrapClass> approvalRequestsWrap = new List<ApprovalWrapClass>();
            
            for(ProcessInstanceWorkitem item : approvalRequests){
                ApprovalWrapClass obj = new ApprovalWrapClass();
                obj.workItemIds = item.Id;
                obj.ActorId = item.ActorId;
                obj.recordLink = '/'+item.ProcessInstance.TargetObjectId;
                obj.ProcessInstanceTargetObjectId = item.ProcessInstance.TargetObjectId;
                obj.ProcessInstanceTargetObjectName = item.ProcessInstance.TargetObject.Name;
                obj.ProcessInstanceStatus = item.ProcessInstance.Status;
                obj.ProcessInstanceCreatedBy = item.ProcessInstance.CreatedBy.Name;
                obj.SubmittedDate = item.CreatedDate.format('MMM dd, yyyy');
                obj.SubmittedDateTime = item.CreatedDate;
                //  obj.TabName = TabAndApprovalMap.containsKey(item.ProcessInstance.ProcessDefinition.DeveloperName) ? TabAndApprovalMap.get(item.ProcessInstance.ProcessDefinition.DeveloperName) : '';
            
            
              //  obj.ApprovalProcessName = item.ProcessInstance.ProcessDefinition.DeveloperName;
              String devName = item.ProcessInstance.ProcessDefinition.DeveloperName;
                if (devName != null && devName.endsWith('TBT')) {
                    obj.ApprovalProcessName = 'TBT Document';
                } else {
                    obj.ApprovalProcessName = 'Upload Site Document';
                }


                 // 🔹 Map BP Number if it's a WorkOrder
            if (workOrderMap.containsKey(item.ProcessInstance.TargetObjectId)) {
                obj.BPNumber = workOrderMap.get(item.ProcessInstance.TargetObjectId).BP_Number__c;
            }


              
                // obj.ApprovalProcessSubmitterName = UserInfo.getFirstName() + ' ' + UserInfo.getLastName();
                approvalRequestsWrap.add(obj);
            }
            
            System.debug('Approval Requests: ' + approvalRequestsWrap);
            return approvalRequestsWrap;
        }
        catch(exception e){
            System.debug('error--'+e.getMessage()+'--line--'+e.getLineNumber());
            return null;
        }
    }
    
    public class ApprovalWrapClass {
        @AuraEnabled public String workItemIds;
        @AuraEnabled public String ActorId;
        @AuraEnabled public String ProcessInstanceTargetObjectId;
        @AuraEnabled public String ProcessInstanceTargetObjectName;
        @AuraEnabled public String ProcessInstanceStatus;
        @AuraEnabled public String ProcessInstanceCreatedBy;
        @AuraEnabled public String CreatedDate;
        @AuraEnabled public String recordLink;
        @AuraEnabled public String SubmittedDate;
        @AuraEnabled public String SubmittedName;
        @AuraEnabled public Datetime SubmittedDateTime;
        //  @AuraEnabled public String TabName;
        @AuraEnabled public String ApprovalProcessName;
        @AuraEnabled public String ApprovalProcessSubmitterName;
        @AuraEnabled public String BPNumber; // 🔹 Added this field

    }
    
    /**
     * Handles approval or rejection of approval requests.
     * @param workItemIds List of Work Item IDs to process.
     * @param action The action to take ('Approve' or 'Reject').
     * @param comments Comments provided by the user.
     * @throws AuraHandledException if no Work Item IDs are provided.
     */
    // @AuraEnabled
    // public static void handleApproval(List<String> workItemIds, String action, String comments) {
        //     System.debug('Processing approval action. Work Item IDs: ' + workItemIds + ', Action: ' + action);
        
        //     if (workItemIds == null || workItemIds.isEmpty()) {
            //         throw new AuraHandledException('No work item IDs provided.');
        //     }
        
        //     List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();
        
        //     for (String workItemId : workItemIds) {
            //         Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            //         req.setWorkItemId(workItemId);
            //         req.setAction(action);
            //         req.setComments(String.isBlank(comments) ? (action == 'Approve' ? 'Approved' : 'Rejected') : comments.abbreviate(4000));
            //         requests.add(req);
        //     }
        
        //     List<Approval.ProcessResult> results = Approval.process(requests);
        
        //     for (Approval.ProcessResult result : results) {
            //         if (!result.isSuccess()) {
                //             String errorMessage = '';
                //             for (Database.Error error : result.getErrors()) {
                    //                 errorMessage += error.getMessage() + '\n';
                //             }
                //             throw new AuraHandledException('Error processing approvals: ' + errorMessage);
            //         }
        //     }
        
        //     System.debug('Approval action completed successfully.');
    // }
    
    
    
    @AuraEnabled
    public static string handleApproval(List<payLoadWrapper> payload , String action, string commonComments) {
        
        try {
            System.debug('Processing approval action. Work Item IDs: ' + payload);
            
            System.debug('Action :::'+ action);
            
            List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();
            
            for (PayLoadWrapper workItem : payload ) {
                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                req.setWorkItemId(workItem.workItemIds);
                req.setAction(action);
                // Use comment from the map, or set default
                String approvalComment = commonComments + (String.isEmpty(workItem.comment) ? '' : ' ' + workItem.comment);
                req.setComments(approvalComment.abbreviate(4000));
                requests.add(req);
            }
            
            System.debug('Request ::'+ requests);
            
            List<Approval.ProcessResult> results = Approval.process(requests);
            
            system.debug('results:::'+ results);
            
            return 'Success';
            
        }
        
        catch(exception e){
            
            System.debug('Error message::'+ e.getMessage() + 'line number :::' + e.getLineNumber());
            return 'error';
        }
        
    }
    
    
    
    public class payLoadWrapper {
        @AuraEnabled
        public  string comment {get;set;}
        @AuraEnabled
        public  string workItemIds {get;set;}
    }
    
}