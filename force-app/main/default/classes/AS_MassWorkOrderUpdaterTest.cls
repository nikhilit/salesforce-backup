@isTest
private class AS_MassWorkOrderUpdaterTest {

    @testSetup
    static void setupTestData() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        WorkType wt = new WorkType(Name = 'Test Type',EstimatedDuration=6);
        insert wt;

        RecordType rt = [
            SELECT Id FROM RecordType 
            WHERE SObjectType = 'WorkOrder' 
              AND DeveloperName = 'MGL_R_T'
            LIMIT 1
        ];

        List<WorkOrder> workOrders = new List<WorkOrder>();
        for (Integer i = 0; i < 2; i++) {
            workOrders.add(new WorkOrder(
                Subject = 'Test WorkOrder ' + i,
                AccountId = acc.Id,
                WorkTypeId = wt.Id,
                Remarks__c = 'Initial',
                RecordTypeId = rt.Id 
            ));
        }
        insert workOrders;
    }

    @isTest
    static void test_updateRemarks_success() {
        List<Id> ids = new List<Id>();
        for (WorkOrder wo : [
            SELECT Id FROM WorkOrder 
            WHERE RecordType.DeveloperName = 'MGL_R_T'
        ]) {
            ids.add(wo.Id);
        }

        Test.startTest();
        AS_MassWorkOrderUpdater.updateRemarks(ids, 'Updated Remarks');
        Test.stopTest();

        List<WorkOrder> updatedWOs = [
            SELECT Remarks__c FROM WorkOrder 
            WHERE Id IN :ids
        ];
        for (WorkOrder wo : updatedWOs) {
            System.assertEquals('Updated Remarks', wo.Remarks__c, 'Remarks should be updated');
        }
    }

     @isTest
    static void testUpdateRemarks_errorPath() {
        RecordType rt = [SELECT Id FROM RecordType WHERE DeveloperName = 'MGL_R_T' AND SObjectType = 'WorkOrder' LIMIT 1];
    
        WorkOrder wo = new WorkOrder(
            Subject = 'WO to delete',
            Status = 'New',
            RecordTypeId = rt.Id
        );
        insert wo;
        delete wo;
    
        Test.startTest();
        AS_MassWorkOrderUpdater.updateRemarks(null, 'Test remarks');
        Test.stopTest();
    
        List<Integration_Log__c> logs = [
            SELECT Id, Class_Name__c, Method_Name__c, Message__c
            FROM Integration_Log__c
            WHERE Class_Name__c = 'AS_MassWorkOrderUpdater'
            AND Method_Name__c = 'updateRemarks'
        ];
        System.assertEquals(1, logs.size(), 'Expected error log to be created');
    }

}