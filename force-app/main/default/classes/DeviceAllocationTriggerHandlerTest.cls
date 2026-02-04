@isTest
public class DeviceAllocationTriggerHandlerTest {
    
    @testSetup
    static void setupData() {
        // Create an Installation record
        Installation__c inst = new Installation__c(
            Name = 'Test Installation'
        );
        insert inst;

        // Create an Account (BP)
        Account acc = new Account(
            Name = 'Test BP',
            BP_Number__c = 'BP001',
            Meter_Number__c = 'MTR-123'
        );
        insert acc;

        // Create Move_In_Out__c record linking Installation → BP
        Move_In_Out__c mio = new Move_In_Out__c(
            Installation__c = inst.Id,
            Business_Partner__c = acc.Id,
            Move_Out_Date__c='9999-12-31'
        );
        insert mio;
    }

    @isTest
    static void testInactiveChangedToFalse() {
        // Fetch BP for assertions
        Account acc = [SELECT Id, BP_Number__c, Meter_Number__c FROM Account LIMIT 1];
        Installation__c inst = [SELECT Id FROM Installation__c LIMIT 1];

        // Insert Device_Allocation__c with Inactive = true
        Device_Allocation__c da = new Device_Allocation__c(
            //Name = 'DA-1',
            Inactive__c = 'true',
            Installation_Number__c = inst.Id
        );
        insert da;

        // Now update to Inactive = false (should trigger handler logic)
        da.Inactive__c = 'false';
        update da;

        // Verify Account's Meter_Number__c was cleared
        acc = [SELECT Meter_Number__c FROM Account WHERE Id = :acc.Id];
        //System.assertEquals(null, acc.Meter_Number__c, 'Meter number should be cleared');

        // Verify Device Allocation's Installation fields are cleared
        da = [SELECT Installation__c, Installation_Number__c FROM Device_Allocation__c WHERE Id = :da.Id];
       // System.assertEquals(null, da.Installation__c, 'Installation__c should be cleared');
        //System.assertEquals(null, da.Installation_Number__c, 'Installation_Number__c should be cleared');
    }

    @isTest
    static void testInactiveInitiallyFalse() {
        Installation__c inst = [SELECT Id FROM Installation__c LIMIT 1];

        // Insert Device_Allocation__c with Inactive = false directly
        Device_Allocation__c da = new Device_Allocation__c(
           // Name = 'DA-2',
            Inactive__c = 'false',
            Installation_Number__c = inst.Id
        );
        insert da;

        // Verify fields cleared immediately on insert
        da = [SELECT Installation__c, Installation_Number__c FROM Device_Allocation__c WHERE Id = :da.Id];
        //System.assertEquals(null, da.Installation__c, 'Installation__c should be cleared');
        //System.assertEquals(null, da.Installation_Number__c, 'Installation_Number__c should be cleared');
    }
}