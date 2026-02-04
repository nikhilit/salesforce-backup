global class AutoRejectPendingApprovals implements Schedulable {

    global void execute(SchedulableContext sc) {

        // Fetch pending approval work items
        List<ProcessInstanceWorkitem> pendingItems = [
            SELECT Id
            FROM ProcessInstanceWorkitem
            WHERE ProcessInstance.Status = 'Pending'
            AND (
                ProcessInstance.ProcessDefinition.DeveloperName LIKE '%TBT'
                OR ProcessInstance.ProcessDefinition.DeveloperName LIKE '%SiteDocumentApprovalProcess'
            )AND CreatedDate = TODAY 
        ];

        if (pendingItems.isEmpty()) {
            System.debug('No pending approvals found.');
            return;
        }

        List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();

        for (ProcessInstanceWorkitem item : pendingItems) {
            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            req.setWorkItemId(item.Id);
            req.setAction('Reject');
            req.setComments('Auto-rejected by system');
            requests.add(req);
        }

        if (!requests.isEmpty()) {
            Approval.process(requests);
        }
    }
}