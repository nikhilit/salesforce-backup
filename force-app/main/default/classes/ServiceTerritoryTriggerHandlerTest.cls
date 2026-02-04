@isTest
private class ServiceTerritoryTriggerHandlerTest {

    @testSetup
    static void setupTestData() {
        // Create OperatingHours record with the default name as per your custom label
        OperatingHours oh = new OperatingHours(
            Name = System.Label.Default_Operating_Hours_Name,
            TimeZone = 'America/Los_Angeles' // Required field for OperatingHours
        );
        insert oh;
    }

    static testMethod void testBeforeInsertWithMeteringRecordType() {
        // Get the RecordTypeId for Metering
        Id meteringRTId = Schema.SObjectType.ServiceTerritory.getRecordTypeInfosByDeveloperName().get('Metering').getRecordTypeId();

        // Create ServiceTerritory without OperatingHoursId and with Metering record type to test mapping
        ServiceTerritory st = new ServiceTerritory(
            Name = 'Test Service Territory',
            RecordTypeId = meteringRTId
            // OperatingHoursId intentionally left null
        );

        Test.startTest();
        // Call beforeInsert manually to simulate trigger context
        ServiceTerritoryTriggerHandler.beforeInsert(new List<ServiceTerritory>{st});
        Test.stopTest();

        // Assert OperatingHoursId is assigned
        System.assertNotEquals(null, st.OperatingHoursId, 'OperatingHoursId should be assigned for Metering record type');
    }

    static testMethod void testBeforeInsertWithOtherRecordType() {
        // Get any other RecordTypeId that is not Metering (or null if no other exists)
        // For safety, let's create a ServiceTerritory with a different record type or no record type

        ServiceTerritory st = new ServiceTerritory(
            Name = 'Test Service Territory Other RT'
            // No RecordTypeId or a different one - OperatingHoursId should not be assigned
        );

        Test.startTest();
        ServiceTerritoryTriggerHandler.beforeInsert(new List<ServiceTerritory>{st});
        Test.stopTest();

        // OperatingHoursId should remain null
        System.assertEquals(null, st.OperatingHoursId, 'OperatingHoursId should NOT be assigned for non-Metering record types');
    }
}