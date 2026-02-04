@IsTest
public class O_MWorkOrderAccountListViewDetailsTest {

    @TestSetup
    static void setupTestData() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        // Create test User
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser' + System.currentTimeMillis() + '@example.com',
            Username = 'testuser' + System.currentTimeMillis() + '@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert u;

        // Create Account with all fields used in wrapper
        Account acc = new Account(
            Name = 'Test Account',
            Building_name__c = 'Test Building',
            Street__c = 'Test Street',
            Wing__c = 'A',
            Floor__c = '1',
            Flat__c = '101',
            Road_name__c = 'Test Road',
            Colony__c = 'Test Colony',
            BP_Number__c = 'BP123',
            FirstName__c = 'John',
            LastName__c = 'Doe'
        );
        insert acc;

        // WorkOrder RecordType
        RecordType woRT = [SELECT Id FROM RecordType WHERE SObjectType='WorkOrder' AND DeveloperName='MGL_O_M' LIMIT 1];

        // WorkOrder linked to Account
        WorkOrder wo = new WorkOrder(
            RecordTypeId = woRT.Id,
            Subject = 'Test WO',
            Status = 'New',
            AccountId = acc.Id
        );
        insert wo;

        // Operating Hours
        OperatingHours oh = new OperatingHours(Name='Default Operating Hours');
        insert oh;

        // ServiceTerritory
        ServiceTerritory st = new ServiceTerritory(
            Name = 'Test Territory',
            IsActive = true,
            OperatingHoursId = oh.Id
        );
        insert st;

        // ServiceResource linked to user
        ServiceResource sr = new ServiceResource(
            Name = 'Test Resource',
            RelatedRecordId = u.Id,
            IsActive = true
        );
        insert sr;

        // ServiceTerritoryMember
        ServiceTerritoryMember stm = new ServiceTerritoryMember(
            ServiceResourceId = sr.Id,
            ServiceTerritoryId = st.Id,
            EffectiveStartDate = Date.today().addDays(-10),
            EffectiveEndDate = Date.today().addYears(1)
        );
        insert stm;

        // Create ServiceAppointments linked to WorkOrder and ServiceTerritory
        DateTime now = System.now();
        List<ServiceAppointment> saList = new List<ServiceAppointment>{
            new ServiceAppointment(
                Subject='SA Scheduled',
                Status='Scheduled',
                ParentRecordId=wo.Id,
                SchedStartTime = now,
                SchedEndTime = now.addHours(1),
                ServiceTerritoryId = st.Id
            ),
            new ServiceAppointment(
                Subject='SA Completed',
                Status='Completed',
                ParentRecordId=wo.Id,
                SchedStartTime = now,
                SchedEndTime = now.addHours(1),
                ServiceTerritoryId = st.Id
            ),
            new ServiceAppointment(
                Subject='SA In Progress',
                Status='In Progress',
                ParentRecordId=wo.Id,
                SchedStartTime = now,
                SchedEndTime = now.addHours(1),
                ServiceTerritoryId = st.Id
            ),
            new ServiceAppointment(
                Subject='SA Cannot Complete',
                Status='Cannot Complete',
                ParentRecordId=wo.Id,
                SchedStartTime = now,
                SchedEndTime = now.addHours(1),
                ServiceTerritoryId = st.Id
            )
        };
        insert saList;

        // Assign appointments to ServiceResource
        List<AssignedResource> arList = new List<AssignedResource>();
        for(ServiceAppointment sa : saList){
            arList.add(new AssignedResource(
                ServiceResourceId = sr.Id,
                ServiceAppointmentId = sa.Id
            ));
        }
        insert arList;
    }

    @IsTest
    static void testGetAppointmentByStatus() {
        // Run as the test user to ensure ServiceResource matches
        User testUser = [SELECT Id FROM User WHERE Alias='tuser' LIMIT 1];

        System.runAs(testUser) {
            Test.startTest();

            List<ServiceAppointment> scheduledAppointments =
                O_MWorkOrderAccountListViewDetailsContr.getAppointmentByStatus('Scheduled', null);
            //System.assertEquals(1, scheduledAppointments.size());
            System.assertEquals('SA Scheduled', scheduledAppointments[0].Subject);

            List<ServiceAppointment> completedAppointments =
                O_MWorkOrderAccountListViewDetailsContr.getAppointmentByStatus('Completed', null);
            System.assertEquals(1, completedAppointments.size());
            System.assertEquals('SA Completed', completedAppointments[0].Subject);

            List<ServiceAppointment> incompleteAppointments =
                O_MWorkOrderAccountListViewDetailsContr.getAppointmentByStatus('Incomplete', null);
            System.assertEquals(2, incompleteAppointments.size());

            Test.stopTest();
        }
    }

    @IsTest
    static void testServiceAppointmentWrapper() {
        ServiceAppointment sa = [SELECT Id, Subject, Status, SchedStartTime, Appointment_Type__c, Meter_Number__c, Visit_Status__c,
                                 ParentRecordId,
                                 Account.Name, Account.Building_name__c, Account.Street__c, Account.Wing__c, Account.Floor__c,
                                 Account.Flat__c, Account.Road_name__c, Account.Colony__c,
                                 Account.BP_Number__c, Account.FirstName__c, Account.LastName__c
                                 FROM ServiceAppointment
                                 LIMIT 1];

        O_MWorkOrderAccountListViewDetailsContr.ServiceAppointmentWrapper wrapper =
            new O_MWorkOrderAccountListViewDetailsContr.ServiceAppointmentWrapper(sa);

        System.assertEquals(sa.Subject, wrapper.subject);
        System.assertEquals(sa.Status, wrapper.status);
        System.assert(wrapper.address.contains('Wing:'));
        System.assert(wrapper.address.contains('Floor:'));
        System.assert(wrapper.address.contains('Flat:'));
        System.assertEquals('BP123', wrapper.bpNumber);
        System.assertEquals('John', wrapper.customerFirstName);
        System.assertEquals('Doe', wrapper.customerLastName);
    }

    @IsTest
    static void testGetWorkOrderIdFromSA() {
        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment LIMIT 1];
        Id woId = O_MWorkOrderAccountListViewDetailsContr.getWorkOrderIdFromSA(sa.Id);
        System.assertNotEquals(null, woId);
    }
}