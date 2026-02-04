@isTest
private class WorkOrderTriggerTest {
    
    @testSetup
    static void setupTestData() {
        // Insert Account to associate with WorkOrder
        Account acc = new Account(Name = 'Test Account',BP_Number__c='test123');
        insert acc;
        
        // Verify the RecordType 'MGL_Metering' exists (fail test if not)
        RecordType rt = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'WorkOrder' AND DeveloperName = 'MGL_Metering' LIMIT 1];
        System.assert(rt != null, 'MGL_Metering RecordType must exist for test');
    }

    static testMethod void testWorkOrderTrigger() {
        // Get Account and RecordType for the test WorkOrder
        Account acc = [SELECT Id,BP_Number__c FROM Account LIMIT 1];
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'WorkOrder' AND DeveloperName = 'MGL_Metering' LIMIT 1];

        Test.startTest();
        
        // Create a WorkOrder with RecordTypeId = MGL_Metering
        WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            Status = 'New',
            AccountId = acc.Id,
            RecordTypeId = rt.Id,
            Approval_Status__c = 'Pending',
            From_Date__c=System.today(),
            To_Date__c=System.today()
        );
        
        insert wo; // triggers before insert and after insert

        // Reload the WorkOrder
        wo = [SELECT Id, Approval_Status__c FROM WorkOrder WHERE Id = :wo.Id];
        
        // Update to Rejected (should trigger rejected logic)
        wo.Approval_Status__c = 'Rejected';
        update wo;

        // Update to Approved (should trigger approved logic and PDF attachment)
        wo.Approval_Status__c = 'Approved';
        update wo;
        
        Test.stopTest();
    }
}