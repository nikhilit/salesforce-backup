/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 21-11-2025
 * @last modified by  : Kartik Patkar Appstrail 
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   21-11-2025   Kartik Patkar, Appstrail   Initial Version
**/
@isTest
private class WOStatusUpdaterTest {

    @testSetup
    static void setup() {
        // Create sample Work Orders
        List<WorkOrder> woList = new List<WorkOrder>();
        for (Integer i = 0; i < 3; i++) {
            woList.add(new WorkOrder(
                Subject = 'Test WO ' + i,
                Send_Email__c = false
            ));
        }
        insert woList;
    }

    @isTest
    static void testWOStatusUpdater() {
        // Fetch WorkOrders
        List<WorkOrder> wos = [
            SELECT Id, Send_Email__c 
            FROM WorkOrder
        ];

        List<Id> ids = new List<Id>();
        for (WorkOrder wo : wos) {
            ids.add(wo.Id);
        }

        Test.startTest();
        // Enqueue Queueable
        System.enqueueJob(new WOStatusUpdater(ids));
        Test.stopTest(); // Ensures execution of Queueable

        // Validate results
        List<WorkOrder> updated = [
            SELECT Id, Send_Email__c 
            FROM WorkOrder
        ];
        for (WorkOrder wo : updated) {
            System.assertEquals(true, wo.Send_Email__c, 'Send_Email__c should be set to true');
        }
    }
}