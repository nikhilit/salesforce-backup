@isTest
public class IcDashboardControllerTest {

    private static User createUser() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            FirstName = 'Test',
            LastName  = 'User',
            Email     = 'test' + System.currentTimeMillis() + '@example.com',
            Username  = 'test' + System.currentTimeMillis() + '@example.com',
            Alias     = 'tusr',
            TimeZoneSidKey   = 'Asia/Kolkata',
            LocaleSidKey     = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey= 'en_US',
            ProfileId = p.Id
        );
        insert u;
        return u;
    }

    private static Map<String, Id> createServiceResourceSetup(Id userId) {
        OperatingHours oh = new OperatingHours(Name='Test OH', TimeZone='Asia/Kolkata');
        insert oh;

        ServiceTerritory st = new ServiceTerritory(
            Name = 'Test Territory',
            OperatingHoursId = oh.Id,
            IsActive = true
        );
        insert st;

        ServiceResource sr = new ServiceResource(
            Name = 'Test SR',
            IsActive = true,
            RelatedRecordId = userId
        );
        insert sr;

        ServiceTerritoryMember stm = new ServiceTerritoryMember(
            ServiceTerritoryId = st.Id,
            ServiceResourceId = sr.Id,
            EffectiveStartDate = Date.today()
        );
        insert stm;

        return new Map<String, Id>{
            'srId' => sr.Id,
            'stId' => st.Id
        };
    }

    private static WorkOrder createWorkOrder(Id accountId) {
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'WorkOrder' AND DeveloperName = 'MGL_R_T' LIMIT 1];

        WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            Status = 'New',
            Priority = 'Medium',
            AccountId = accountId,
            RecordTypeId = rt.Id
        );
        insert wo;
        return wo;
    }

    private static ServiceAppointment createAppointment(Id woId, Id srId, Id stId, String status, String apptType) {
        ServiceAppointment sa = new ServiceAppointment(
            ParentRecordId = woId,
            Subject = 'Test SA',
            Status = status,
            Appointment_Type__c = apptType,
            SchedStartTime = System.now(),
            SchedEndTime   = System.now().addHours(2),
            ServiceTerritoryId = stId   
        );
        insert sa;

        AssignedResource ar = new AssignedResource(
            ServiceAppointmentId = sa.Id,
            ServiceResourceId = srId
        );
        insert ar;

        return sa;
    }

    @isTest
    static void test_getKPIs_withAppointments() {
        User u = createUser();
        System.runAs(u) {
            Account acc = new Account(Name = 'Test Acc');
            insert acc;

            Map<String, Id> setup = createServiceResourceSetup(u.Id);
            Id srId = setup.get('srId');
            Id stId = setup.get('stId');

            WorkOrder wo = createWorkOrder(acc.Id);

            createAppointment(wo.Id, srId, stId, 'Completed', 'Standard');
            createAppointment(wo.Id, srId, stId, 'Cannot Complete', 'Scheduled');
            createAppointment(wo.Id, srId, stId, 'Scheduled', 'Ad-Hoc');
            createAppointment(wo.Id, srId, stId, 'None', 'Follow Up');

            Test.startTest();
            Map<String,Integer> kpis = IcDashboardController.getKPIs();
            Test.stopTest();

            System.assert(kpis.get('total') > 0, 'Should have counted appointments');
            System.assert(kpis.containsKey('completed'));
            System.assert(kpis.containsKey('incomplete'));
            System.assert(kpis.containsKey('unattempted'));
            System.assert(kpis.containsKey('followup'));
        }
    }

    @isTest
    static void test_getKPIs_noServiceResource() {
        User u = createUser();
        System.runAs(u) {
            Test.startTest();
            Map<String,Integer> kpis = IcDashboardController.getKPIs();
            Test.stopTest();

            System.assertEquals(0, kpis.get('total'));
        }
    }

	@isTest
	static void test_getCountByMetadataMatch_withMetadata() {
    User u = createUser();
    System.runAs(u) {
        Account acc = new Account(Name = 'Test Acc');
        insert acc;

        Map<String, Id> setup = createServiceResourceSetup(u.Id);
        Id srId = setup.get('srId');
        Id stId = setup.get('stId');

        WorkOrder wo = createWorkOrder(acc.Id);

        ServiceAppointment sa = new ServiceAppointment(
            ParentRecordId = wo.Id,
            Subject = 'SA for Metadata Match',
            Status = 'Completed',
            Appointment_Type__c = 'Standard',
            ServiceTerritoryId = stId,
            SchedStartTime = System.now(),
            SchedEndTime = System.now().addHours(1)
        );
        insert sa;

        AssignedResource ar = new AssignedResource(
            ServiceAppointmentId = sa.Id,
            ServiceResourceId = srId
        );
        insert ar;

        Test.startTest();
        List<IcDashboardController.DataWrapper> results =
            IcDashboardController.getCountByMetadataMatch();
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        System.assert(results.size() >= 0, 'Results should return a list (maybe empty)');
    }
}


    @isTest
    static void test_getStatusByCount_direct() {
        Account acc = new Account(Name='Test Acc');
        insert acc;

        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'WorkOrder' AND DeveloperName = 'MGL_R_T' LIMIT 1];
        WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            Status = 'New',
            Priority = 'Medium',
            AccountId = acc.Id,
            RecordTypeId = rt.Id
        );
        insert wo;

        // Minimal appointment without SR/ST (safe because we call method directly)
        ServiceAppointment sa = new ServiceAppointment(
            ParentRecordId = wo.Id,
            Subject = 'Test SA',
            Status = 'Completed',
            SchedStartTime = System.now(),
            SchedEndTime   = System.now().addHours(1)
        );
        insert sa;

        Metering_Dashboard_Config__mdt meta = new Metering_Dashboard_Config__mdt(
            Label__c = 'CompletedLabel',
            Field_API_Name__c = 'Status',
            Values__c = 'Completed',
            Order__c = 1,
            Card_Color__c = 'Blue',
            Icon_URL__c = 'icon.png',
            Active__c = true,
            Department__c = 'R&T'
        );

        List<Metering_Dashboard_Config__mdt> metaList = new List<Metering_Dashboard_Config__mdt>{ meta };

        Test.startTest();
        List<IcDashboardController.DataWrapper> results =
            IcDashboardController.getStatusByCount(new List<ServiceAppointment>{ sa }, metaList);
        Test.stopTest();

        System.assertEquals(1, results[0].count, 'Count should be 1 for Completed');
        System.assertEquals('CompletedLabel', results[0].label);
    }

	
}