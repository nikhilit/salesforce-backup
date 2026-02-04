/**
* @File Name : AICApprovalContrTest.cls
* @Description : Test class for AICApprovalContr
*/

@IsTest
public class AICApprovalContrTest {

    // ----------------------------------------------------------------------
    // MOCK FOR CALLOUTS (BillsCallout / NameTransferUpdate / etc.)
    // ----------------------------------------------------------------------
    private class DummyHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');

            String endpoint = req.getEndpoint() != null ? req.getEndpoint().toLowerCase() : '';

            // Token call (if any)
            if (endpoint.contains('token') || endpoint.contains('oauth')) {
                res.setBody('{"access_token":"DUMMY_TOKEN","token_type":"Bearer","expires_in":3600}');
            } else {
                // Generic JSON response for any other SAP API
                res.setBody('{"status":"SUCCESS","message":"Mocked callout success"}');
            }
            return res;
        }
    }

    private static void setupCalloutMock() {
        Test.setMock(HttpCalloutMock.class, new DummyHttpMock());
    }

    // ----------------------------------------------------------------------
    // TEST SETUP
    // ----------------------------------------------------------------------
    @TestSetup
    static void setupData() {

        // Create WorkType
        WorkType wtRiser = new WorkType(
            Name             = 'Riser Maintenance',
            EstimatedDuration= 1,
            DurationType     = 'Hours'
        );

        WorkType wtOther = new WorkType(
            Name             = 'Other Type',
            EstimatedDuration= 1,
            DurationType     = 'Hours'
        );

        insert new List<WorkType>{ wtRiser, wtOther };

        // Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create Case
        Case cs = new Case(Origin = 'Phone', Status = 'New');
        insert cs;

        // Create Connection__c
        Connection__c con = new Connection__c(Name = 'Conn1');
        insert con;

        // Create WorkOrders
        List<WorkOrder> woList = new List<WorkOrder>();

        // WO 1 - Approved scenario (with Account & Case & Connection, Riser Maintenance)
        woList.add(new WorkOrder(
            Subject      = 'WO1',
            WorkTypeId   = wtRiser.Id,
            AccountId    = acc.Id,
            CaseId       = cs.Id,
            Connection__c= con.Id
        ));

        // WO 2 - Not Approved scenario
        woList.add(new WorkOrder(
            Subject    = 'WO2',
            WorkTypeId = wtOther.Id
        ));

        insert woList;
    }

    // ----------------------------------------------------------------------
    // TEST: Approved path (happy path)
    // ----------------------------------------------------------------------
    @IsTest
    static void testUpdateWorkOrderApprovalStatus_Approved() {
        setupCalloutMock();

        // Get both work orders
        List<WorkOrder> woList = [
            SELECT Id, AccountId, CaseId, WorkType.Name, Connection__c, OwnerId
            FROM WorkOrder
            ORDER BY CreatedDate
        ];
        System.assertEquals(2, woList.size(), 'Expected 2 work orders from setup');

        WorkOrder woApproved = woList[0]; // WO1 with Account/Case/Connection

        List<String> ids = new List<String>();
        ids.add(woApproved.Id);

        String moveOutDateStr = '2025-12-12';
        Date moveOutDate = Date.newInstance(2025, 12, 12);

        Id currentUserId = UserInfo.getUserId();

        Test.startTest();
        AICApprovalContr.updateWorkOrderApprovalStatus(
            ids,
            'Approved',
            'Test Remark',
            moveOutDateStr
        );
        Test.stopTest();

        // Refresh all related records
        WorkOrder woAfter = [
            SELECT OwnerId, Approval_Status_AIC__c, AICRemark__c,
                   AccountId, CaseId, Connection__c
            FROM WorkOrder
            WHERE Id = :woApproved.Id
        ];

        System.assertEquals('Approved', woAfter.Approval_Status_AIC__c, 'WO approval status should be Approved');
        System.assertEquals('Test Remark', woAfter.AICRemark__c, 'WO remark should be updated');
        System.assertEquals(currentUserId, woAfter.OwnerId, 'WO owner should be current user when Approved');

        if (woAfter.AccountId != null) {
            Account accAfter = [
                SELECT Move_Out_Date__c
                FROM Account
                WHERE Id = :woAfter.AccountId
            ];
            System.assertEquals(moveOutDate, accAfter.Move_Out_Date__c, 'Account Move_Out_Date__c should be updated');
        }

        if (woAfter.CaseId != null) {
            Case caseAfter = [
                SELECT Status, Standard_Remarks__c, Move_Out_Date__c
                FROM Case
                WHERE Id = :woAfter.CaseId
            ];
            System.assertEquals('Actioned by Department', caseAfter.Status, 'Case status should be Actioned by Department');
            System.assertEquals('Test Remark', caseAfter.Standard_Remarks__c, 'Case remarks should be updated');
            System.assertEquals(moveOutDate, caseAfter.Move_Out_Date__c, 'Case Move_Out_Date__c should be updated');
        }

        if (woAfter.Connection__c != null) {
            Connection__c conAfter = [
                SELECT Last_Maintenance_Date__c
                FROM Connection__c
                WHERE Id = :woAfter.Connection__c
            ];
            System.assertEquals(System.today(), conAfter.Last_Maintenance_Date__c,
                                'Connection Last_Maintenance_Date__c should be today');
        }
    }

    // ----------------------------------------------------------------------
    // TEST: Rejected path (no Account/Case/Connection updates)
    // ----------------------------------------------------------------------
    @IsTest
    static void testUpdateWorkOrderApprovalStatus_NotApproved() {
        setupCalloutMock();

        // Get the second workorder (WO2, "Other Type")
        WorkOrder woRejected = [
            SELECT Id, Approval_Status_AIC__c, AICRemark__c
            FROM WorkOrder
            WHERE Subject = 'WO2'
            LIMIT 1
        ];

        Test.startTest();
        AICApprovalContr.updateWorkOrderApprovalStatus(
            new List<String>{ woRejected.Id },
            'Rejected',
            'Not Approved',
            '2025-12-12'
        );
        Test.stopTest();

        WorkOrder woAfter = [
            SELECT Approval_Status_AIC__c, AICRemark__c
            FROM WorkOrder
            WHERE Id = :woRejected.Id
        ];

        System.assertEquals('Rejected', woAfter.Approval_Status_AIC__c,
                            'WO approval status should be Rejected');
        System.assertEquals('Not Approved', woAfter.AICRemark__c,
                            'WO remark should be Not Approved');
    }

    // ----------------------------------------------------------------------
    // TEST: Invalid date to hit catch(Exception e) block
    // ----------------------------------------------------------------------
    @IsTest
    static void testUpdateWorkOrderApprovalStatus_InvalidDate_CatchBlock() {
        setupCalloutMock();

        // Use the approved-type workorder with account/case/connection to ensure we hit Date.valueOf
        WorkOrder woApproved = [
            SELECT Id
            FROM WorkOrder
            WHERE Subject = 'WO1'
            LIMIT 1
        ];

        List<String> ids = new List<String>{ woApproved.Id };

        // Invalid date string to force Date.valueOf(moveOutDate) to throw, which will be caught
        String badDate = 'NOT_A_DATE';

        Test.startTest();
        // Should not throw to the test context; exception is caught in the method
        AICApprovalContr.updateWorkOrderApprovalStatus(
            ids,
            'Approved',
            'Remark With Bad Date',
            badDate
        );
        Test.stopTest();

        // We mainly care that the method finished without unhandled exception,
        // which means the catch block executed. Optionally assert that related
        // records are still in a sane state.
        WorkOrder woAfter = [
            SELECT Approval_Status_AIC__c, AICRemark__c
            FROM WorkOrder
            WHERE Id = :woApproved.Id
        ];
        // Approval status and remark might have been set before the exception,
        // so we just assert we can still query without errors.
        System.assertEquals('Approved', woAfter.Approval_Status_AIC__c,
                            'WO status should still be set to Approved even if date failed');
        System.assertEquals('Remark With Bad Date', woAfter.AICRemark__c,
                            'WO remark should still be updated');
    }
}