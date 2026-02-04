public without sharing class AICApprovalAfsContr {

    @AuraEnabled
    public static void updateWorkOrderApprovalStatus(
        List<String> reactiveValue,
        String approvalStatusValue,
        String remark
    ) {
        try {
            User userDetail = [
                SELECT Id, Profile.Name
                FROM User
                WHERE Id = :UserInfo.getUserId()
                LIMIT 1
            ];

            List<WorkOrder> lstWorkOrder = [
                SELECT Id, OwnerId, WorkType.Name, Connection__c,
                       Approval_Status_AIC__c, AICRemark__c,
                       AccountId, CaseId
                FROM WorkOrder
                WHERE Id IN :reactiveValue
            ];

            Set<Id> caseIds = new Set<Id>();
            Set<Id> connectionIds = new Set<Id>();
            Set<Id> updatedWorkorderIds = new Set<Id>();

            for (WorkOrder wo : lstWorkOrder) {

                wo.Approval_Status_AIC__c = approvalStatusValue;
                wo.AICRemark__c = remark;

                if (approvalStatusValue == 'Approved') {
                    wo.OwnerId = userDetail.Id;
                    updatedWorkorderIds.add(wo.Id);
                }

                if (wo.CaseId != null && approvalStatusValue == 'Approved') {
                    caseIds.add(wo.CaseId);
                }

                if (
                    wo.Connection__c != null &&
                    wo.WorkType.Name == 'Riser Maintenance' &&
                    approvalStatusValue == 'Approved'
                ) {
                    connectionIds.add(wo.Connection__c);
                }
            }

            if (!lstWorkOrder.isEmpty()) {
                update lstWorkOrder;
            }

            /* Update Case Remarks & Status */
            if (!caseIds.isEmpty()) {
                List<Case> lstCases = [
                    SELECT Id, Status, Standard_Remarks__c
                    FROM Case
                    WHERE Id IN :caseIds
                ];

                for (Case cs : lstCases) {
                    cs.Status = 'Actioned by Department';
                    cs.Standard_Remarks__c = remark;
                }

                update lstCases;
            }

            /* Update Connection Maintenance Date */
            // if (!connectionIds.isEmpty()) {
            //     List<Connection__c> lstConnection = [
            //         SELECT Id, Last_Maintenance_Date__c
            //         FROM Connection__c
            //         WHERE Id IN :connectionIds
            //     ];

            //     for (Connection__c con : lstConnection) {
            //         con.Last_Maintenance_Date__c = System.today();
            //     }

            //     update lstConnection;
            // }

            /* Remove Old Work Order Shares */
            if (!updatedWorkorderIds.isEmpty()) {
                List<WorkOrderShare> sharesToDelete = [
                    SELECT Id
                    FROM WorkOrderShare
                    WHERE ParentId IN :updatedWorkorderIds
                    AND UserOrGroup.Profile.Name IN (
                        'Field Agent Riser',
                        'O&M Field Agent Riser Activity',
                        'O&M Supervisor IPD',
                        'Field Agent(O&M)- IPD',
                        'O&M Supervisor DOMESTIC METER CHECKING',
                        'Field Agent(O&M)- AfterSalesService',
                        'Supervisor Building Demolition'
                    )
                ];
                delete sharesToDelete;
            }

            /* Cleanup Service Appointments */
            List<ServiceAppointment> lstServiceAppointment = [
                SELECT Id
                FROM ServiceAppointment
                WHERE ParentRecordId IN :updatedWorkorderIds
            ];

            if (!lstServiceAppointment.isEmpty()) {
                List<AssignedResource> lstAssignedResource = [
                    SELECT Id
                    FROM AssignedResource
                    WHERE ServiceAppointmentId IN :lstServiceAppointment
                ];

                delete lstAssignedResource;
            }

        } catch (Exception e) {
            System.debug(
                'Error :: ' + e.getLineNumber() + ' ' + e.getMessage()
            );
        }
    }
}