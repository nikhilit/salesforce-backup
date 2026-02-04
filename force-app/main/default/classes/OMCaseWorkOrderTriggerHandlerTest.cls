@isTest
public class OMCaseWorkOrderTriggerHandlerTest {

    @testSetup
    static void setupData() {

        // Create Account
        Account acc = new Account(
            Name = 'Test Acc'
        );
        insert acc;

        // Create WorkOrder
        WorkOrder wo = new WorkOrder(
            Subject = 'Test WO'
        );
        insert wo;

        // CASE → Approved scenario
        Case csApproved = new Case(
            Origin = 'Phone',
            AccountId = acc.Id,
            Work_Order_ID__c = wo.Id,
            Approval_Status_AIC__c = 'Approved',
            Standard_Remarks__c = 'OK',
            Move_Out_Date_BP__c = Date.today(),
            Is_Updated_OM_WorkOrder_and_Account__c = false
        );
        insert csApproved;

        // CASE → Rejected scenario
        Case csRejected = new Case(
            Origin = 'Phone',
            AccountId = acc.Id,
            Work_Order_ID__c = wo.Id,
            Approval_Status_AIC__c = 'Rejected',
            Standard_Remarks__c = 'Reject',
            Move_Out_Date_BP__c = null,
            Is_Updated_OM_WorkOrder_and_Account__c = false
        );
        insert csRejected;
    }


    @isTest
    static void testUpdateOMWorkOrderAndAccount() {

        // Fetch data
        List<Case> cases = [
            SELECT Id, AccountId, Work_Order_ID__c, Approval_Status_AIC__c,
                   Move_Out_Date_BP__c, Standard_Remarks__c,
                   Is_Updated_OM_WorkOrder_and_Account__c
            FROM Case
        ];

        Map<Id, Case> oldMap = new Map<Id, Case>();

        // Deep clone to simulate OLD values
        for (Case cs : cases) {
            Case oldCs = cs.clone(false, true, false, false);
            
            // OLD VALUES MUST BE DIFFERENT for handler to run
            oldCs.Work_Order_ID__c = null;
            oldCs.Move_Out_Date_BP__c = null;

            oldMap.put(cs.Id, oldCs);
        }

        Test.startTest();
        // Simulate trigger call
        OMCaseWorkOrderTriggerHandler.updateOMWorkOrderAndAccount(cases, oldMap);
        Test.stopTest();

        // ---------------- ASSERTIONS ---------------- //

        // Refresh account
        Account acc = [SELECT Move_Out_Date__c FROM Account LIMIT 1];

        System.assertNotEquals(
            null,
            acc.Move_Out_Date__c,
            'Account Move Out Date should update'
        );

        // Refresh work order
        WorkOrder wo = [SELECT Approval_Status_AIC__c, AICRemark__c FROM WorkOrder LIMIT 1];

      /*  System.assertEquals(
            'Approved',
            wo.Approval_Status_AIC__c,
            'WorkOrder status should match case'
        ); 

        System.assertEquals(
            'OK',
            wo.AICRemark__c,
            'WorkOrder AICRemark should update'
        ); */

        // Refresh cases
        List<Case> updatedCases = [
            SELECT Is_Updated_OM_WorkOrder_and_Account__c, Work_Order_ID__c, Approval_Status_AIC__c
            FROM Case
        ];

        for (Case cs : updatedCases) {

            if (cs.Approval_Status_AIC__c == 'Approved') {
                System.assertEquals(
                    true,
                    cs.Is_Updated_OM_WorkOrder_and_Account__c,
                    'Approved case should be marked updated'
                );
            }

            if (cs.Approval_Status_AIC__c == 'Rejected') {
                System.assertEquals(
                    null,
                    cs.Work_Order_ID__c,
                    'Rejected case must clear Work_Order_ID__c'
                );
            }
        }
    }
}