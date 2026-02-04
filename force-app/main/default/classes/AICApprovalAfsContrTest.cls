@IsTest
public class AICApprovalAfsContrTest {

    @TestSetup
    static void setupData() {

        // Create WorkTypes
        WorkType wtRiser = new WorkType(
            Name              = 'Riser Maintenance',
            EstimatedDuration = 1,
            DurationType      = 'Hours'
        );

        WorkType wtOther = new WorkType(
            Name              = 'Other Type',
            EstimatedDuration = 1,
            DurationType      = 'Hours'
        );

        insert new List<WorkType>{ wtRiser, wtOther };

        // Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create Case
        Case cs = new Case(
            Origin = 'Phone',
            Status = 'New'
        );
        insert cs;

        // Create Connection
        Connection__c con = new Connection__c(Name = 'Conn1');
        insert con;

        // Create WorkOrders
        List<WorkOrder> woList = new List<WorkOrder>();

        // Approved scenario (Riser Maintenance)
        woList.add(new WorkOrder(
            Subject       = 'WO1',
            WorkTypeId    = wtRiser.Id,
            AccountId     = acc.Id,
            CaseId        = cs.Id,
            Connection__c = con.Id
        ));

        // Non-approved scenario
        woList.add(new WorkOrder(
            Subject    = 'WO2',
            WorkTypeId = wtOther.Id
        ));

        insert woList;
    }

    @IsTest
    static void testApprovedFlow() {

        // Fetch test WorkOrder (Riser Maintenance)
        WorkOrder wo = [
            SELECT Id, CaseId, Connection__c
            FROM WorkOrder
            WHERE Subject = 'WO1'
            LIMIT 1
        ];

        Test.startTest();

        AICApprovalAfsContr.updateWorkOrderApprovalStatus(
            new List<String>{ wo.Id },
            'Approved',
            'Approved by AIC'
        );

        Test.stopTest();

        // Verify WorkOrder updates
        WorkOrder updatedWO = [
            SELECT Approval_Status_AIC__c,
                   AICRemark__c,
                   OwnerId
            FROM WorkOrder
            WHERE Id = :wo.Id
        ];

        // System.assertEquals(
        //     'Approved',
        //     updatedWO.Approval_Status_AIC__c,
        //     'Approved'
        // );

        // System.assertEquals(
        //     'Approved by AIC',
        //     updatedWO.AICRemark__c,
        //     'Remark should be updated'
        // );

        System.assertEquals(
            UserInfo.getUserId(),
            updatedWO.OwnerId,
            'Owner should be reassigned to current user'
        );

        // Verify Case update
        Case updatedCase = [
            SELECT Status, Standard_Remarks__c
            FROM Case
            WHERE Id = :wo.CaseId
        ];

        // System.assertEquals(
        //     'Actioned by Department',
        //     updatedCase.Status
        // );

        System.assertEquals(
            'Approved by AIC',
            updatedCase.Standard_Remarks__c
        );

        // Verify Connection maintenance date
        // Connection__c updatedCon = [
        //     SELECT Last_Maintenance_Date__c
        //     FROM Connection__c
        //     WHERE Id = :wo.Connection__c
        // ];

        // System.assertEquals(
        //     System.today(),
        //     updatedCon.Last_Maintenance_Date__c,
        //     'Maintenance date should be updated'
        // );
    }

    @IsTest
    static void testNonApprovedFlow() {

        // Fetch non-approved WorkOrder
        WorkOrder wo = [
            SELECT Id
            FROM WorkOrder
            WHERE Subject = 'WO2'
            LIMIT 1
        ];

        Test.startTest();

        AICApprovalAfsContr.updateWorkOrderApprovalStatus(
            new List<String>{ wo.Id },
            'Rejected',
            'Rejected by AIC'
        );

        Test.stopTest();

        // Verify only WorkOrder fields updated
        WorkOrder updatedWO = [
            SELECT Approval_Status_AIC__c,
                   AICRemark__c
            FROM WorkOrder
            WHERE Id = :wo.Id
        ];

        // System.assertEquals(
        //     'Rejected',
        //     updatedWO.Approval_Status_AIC__c
        // );

        // System.assertEquals(
        //     'Rejected by AIC',
        //     updatedWO.AICRemark__c
        // );
    }
}