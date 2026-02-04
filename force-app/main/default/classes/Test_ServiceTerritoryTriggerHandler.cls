@isTest
public class Test_ServiceTerritoryTriggerHandler {

    @isTest
    static void testBeforeInsertWithOperatingHours() {
        // Create test Operating Hours with the label name
        OperatingHours oh = new OperatingHours(
            Name = System.label.Default_Operating_Hours_Name
        );
        insert oh;

        // Get the RecordTypeId for ServiceTerritory with DeveloperName = 'Metering'
        Id meteringRTId = Schema.SObjectType.ServiceTerritory.getRecordTypeInfosByDeveloperName()
                                .get('Metering').getRecordTypeId();

        // Create ServiceTerritory record without OperatingHoursId
        ServiceTerritory st = new ServiceTerritory(
            Name = 'Test Territory',
            RecordTypeId = meteringRTId
        );

        Test.startTest();
        // Simulate before insert trigger context
        ServiceTerritoryTriggerHandler.beforeInsert(new List<ServiceTerritory>{st});
        Test.stopTest();

        // Validate that the OperatingHoursId was set
        System.assertEquals(oh.Id, st.OperatingHoursId);
    }

    @isTest
    static void testBeforeInsertWithNonMeteringRecordType() {
        // Create test Operating Hours with the label name
        OperatingHours oh = new OperatingHours(
            Name = System.label.Default_Operating_Hours_Name
        );
        insert oh;

        // Get any RecordTypeId that is NOT Metering
        Id nonMeteringRTId = null;
        for (Schema.RecordTypeInfo rtInfo : Schema.SObjectType.ServiceTerritory.getRecordTypeInfos()) {
            if (rtInfo.getName() != 'Metering' && rtInfo.isAvailable()) {
                nonMeteringRTId = rtInfo.getRecordTypeId();
                break;
            }
        }

        if (nonMeteringRTId == null) {
            // If Metering is the only available RecordType, create a dummy RT to proceed
            RecordType dummyRT = new RecordType(
                SObjectType = 'ServiceTerritory',
                DeveloperName = 'Dummy',
                Name = 'Dummy'
                //IsActive = true
            );
            //insert dummyRT;
           // nonMeteringRTId = dummyRT.Id;
        }

        // Create ServiceTerritory with non-Metering RT
        ServiceTerritory st = new ServiceTerritory(
            Name = 'Dummy Territory',
            RecordTypeId = nonMeteringRTId
        );

        Test.startTest();
        ServiceTerritoryTriggerHandler.beforeInsert(new List<ServiceTerritory>{st});
        Test.stopTest();

        // Validate that OperatingHoursId was NOT set
        System.assertEquals(null, st.OperatingHoursId);
    }

    @isTest
    static void testBeforeInsertWithOperatingHoursAlreadySet() {
        // Create test Operating Hours
        OperatingHours oh1 = new OperatingHours(Name = System.label.Default_Operating_Hours_Name);
        insert oh1;

        OperatingHours oh2 = new OperatingHours(Name = 'Custom OH');
        insert oh2;

        // Get Metering RecordTypeId
        Id meteringRTId = Schema.SObjectType.ServiceTerritory.getRecordTypeInfosByDeveloperName()
                                .get('Metering').getRecordTypeId();

        // Create ServiceTerritory with already set OperatingHoursId
        ServiceTerritory st = new ServiceTerritory(
            Name = 'Territory With OH',
            RecordTypeId = meteringRTId,
            OperatingHoursId = oh2.Id
        );

        Test.startTest();
        ServiceTerritoryTriggerHandler.beforeInsert(new List<ServiceTerritory>{st});
        Test.stopTest();

        // Assert that existing OperatingHoursId was not overwritten
        System.assertEquals(oh2.Id, st.OperatingHoursId);
    }
}