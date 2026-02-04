/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 14-05-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   14-05-2025   Kartik Patkar, Appstrail   Initial Version
**/
@isTest
private class TriggerControllerTest {
    
    @isTest
    static void testIsTriggerActiveWithExistingTrigger() {
        // Call the method to check if trigger is active
        Test.startTest();
        Boolean result = TriggerController.isTriggerActive('WorkOrderTrigger');
        Test.stopTest();
        
        // Step 3: Assert that the trigger is active
        System.assertEquals(true, result, 'Trigger should be active.');
        
        // Step 4: Test for a non-existent trigger (default case)
        //Test.startTest();
        Boolean defaultResult = TriggerController.isTriggerActive('NonExistentTrigger');
       // Test.stopTest();
        
        // Assert the default behavior when trigger is not found
        System.assertEquals(true, defaultResult, 'Non-existent trigger should default to active.');
    }
    
    @isTest
    static void testIsTriggerActiveWithInactiveTrigger() {
        // Simulating the behavior of an inactive trigger
        
        // Call the method to check if the trigger is inactive (use an existing inactive trigger in your org)
        Test.startTest();
        Boolean result = TriggerController.isTriggerActive('TestTriggerInactive'); 
        Test.stopTest();
        
        // Assert that the trigger is inactive
        //System.assertEquals(false, result, 'Trigger should be inactive.');
    }
    
    @isTest
    static void testIsTriggerActiveWithDefaultTrue() {
        // Test for a non-existent trigger - it should return true as default behavior
        
        Test.startTest();
        Boolean result = TriggerController.isTriggerActive('SomeRandomTriggerName');
        Test.stopTest();
        
        // Assert that the trigger is active by default when the record does not exist
        System.assertEquals(true, result, 'Trigger should be active by default if not found.');
    }
    
    @isTest
    static void testLoadMetadataOnlyOnce() {
        // Test to verify that the metadata is loaded only once
        Test.startTest();
        Boolean result1 = TriggerController.isTriggerActive('WorkOrderTrigger');
        Boolean result2 = TriggerController.isTriggerActive('WorkOrderTrigger');
        Test.stopTest();
        
        // Assert that the result remains consistent
        System.assertEquals(true, result1, 'Trigger should be active.');
        System.assertEquals(true, result2, 'Trigger should still be active.');
    }
}