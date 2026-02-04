@IsTest
private class WO_UpdateSendEmail_Batch_Test {

    @testSetup
    static void setupData() {

        // Create Account
        Account acc = new Account(
            Name = 'Test Acc',
            BP_Number__c = '10001'
        );
        insert acc;

        // Insert 3 WorkOrders
        List<WorkOrder> wos = new List<WorkOrder>();
        for (Integer i = 0; i < 3; i++) {
            wos.add(new WorkOrder(
                Subject = 'WO ' + i,
                AccountId = acc.Id,
                Send_Email__c = false
            ));
        }
        insert wos;
    }

    @IsTest
    static void testBatchUpdatesSendEmail() {

        // Get all WOs
        List<WorkOrder> listWO = [
            SELECT Id, Send_Email__c FROM WorkOrder
        ];

        // Extract IDs
        List<Id> woIds = new List<Id>();
        for (WorkOrder wo : listWO) {
            woIds.add(wo.Id);
        }

        Test.startTest();
        // Execute batch with chunk size 40
        Database.executeBatch(new WO_UpdateSendEmail_Batch(woIds), 40);
        Test.stopTest();

    }
}