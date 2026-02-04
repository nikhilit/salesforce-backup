@IsTest
public class O_MDashboardContrTest {

    @TestSetup
    static void setupTestData() {
        
        Map<String, Id> ids = new Map<String, Id>();
        // 1. Create a User
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
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
        ids.put('userId', u.Id);

        // 2. WorkOrder RecordType
        RecordType woRT = [SELECT Id FROM RecordType WHERE SObjectType='WorkOrder' AND DeveloperName='MGL_O_M' LIMIT 1];

        // 3. WorkOrder
        WorkOrder wo = new WorkOrder(
            RecordTypeId = woRT.Id,
            Subject = 'Test WO',
            Status = 'New'
        );
        insert wo;

        // 4. Operating Hours (needed for ServiceTerritory)
        OperatingHours oh = new OperatingHours(Name='Default Operating Hours');
        insert oh;

        // 5. ServiceTerritory
		ServiceTerritory st = new ServiceTerritory(
            Name = 'Test Territory',
            IsActive = true,
            OperatingHoursId = oh.Id,
            Business_Partner_Category__c = 'Domestic'
        );
        insert st;
        ids.put('serviceTerritoryId', st.Id);

        // 6. ServiceResource linked to user
        ServiceResource sr = new ServiceResource(
            Name = 'Test Resource',
            RelatedRecordId = u.Id,
            IsActive = true
        );
        insert sr;

        // 7. ServiceTerritoryMember linking SR to Territory
        ServiceTerritoryMember stm = new ServiceTerritoryMember(
            ServiceResourceId = sr.Id,
            ServiceTerritoryId = st.Id,
            EffectiveStartDate = Date.today().addDays(-10),
            EffectiveEndDate = Date.today().addYears(1)
        );
        insert stm;

        // 8. Create ServiceAppointments
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

        // 9. Assign ServiceAppointments to ServiceResource
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
static void testGetKPIs_FullCoverage() {
    // get the test user
    User u = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
    
    System.runAs(u) {
        Test.startTest();
        Map<String, Integer> kpis = O_MDashboardContr.getKPIs();
        Test.stopTest();
    }
}

	@IsTest
	static void testGetCountByMetadataMatch_FullCoverage() {
    // get the test user
    User u = [SELECT Id FROM User WHERE Username LIKE 'testuser%@example.com' LIMIT 1];

    System.runAs(u) {
        Test.startTest();
        List<O_MDashboardContr.DataWrapper> results = O_MDashboardContr.getCountByMetadataMatch();
        Test.stopTest();
    }
}
}