@isTest
public class AssignedResourceTriggerTest {

    @testSetup
    static void setupData() {
        
         Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            Alias = 'tuser',
            Email = 'testuser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'TestUser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            UserName = 'testuser' + System.currentTimeMillis() + '@test.com'
        );
        insert u;

        // Create ServiceResource tagged to the User
        ServiceResource sr = new ServiceResource(
            Name = 'Test Resource',
            RelatedRecordId = u.Id,
            IsActive = true
        );
        insert sr;
        
        OperatingHours opHours = new OperatingHours(
            Name = 'Test Operating Hours',
            TimeZone = 'Asia/Kolkata'   
        );
        insert opHours;        
        ServiceTerritory st = new ServiceTerritory(
            Name = 'Test Territory',
            OperatingHoursId = opHours.id,
            IsActive = true
        );
        insert st;

        ServiceTerritoryMember stm = new ServiceTerritoryMember(
            ServiceTerritoryId = st.Id,
            ServiceResourceId = sr.Id,
            //Role = 'Technician',
            EffectiveStartDate = Date.today().addDays(-1)
        );
        insert stm;


        WorkOrder wo = new WorkOrder(
            Subject = 'Test Work Order',
            Status = 'New'
        );
        insert wo;

        ServiceAppointment sa = new ServiceAppointment(
            ParentRecordId = wo.Id,
            EarliestStartTime = System.now(),
            DueDate = System.now().addDays(1),
            Status = 'Scheduled',
            SchedStartTime = system.now(),
            SchedEndTime = system.now()
        );
        insert sa;
    }

    @isTest
    static void testAfterInsertAssignedResource() {
        // Fetch ServiceAppointment for linking
        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment LIMIT 1];
        
        ServiceResource serRes = [Select id from serviceresource limit 1];

        AssignedResource ar = new AssignedResource(
            ServiceAppointmentId = sa.Id,
            ServiceResourceId = serRes.Id
           // Role = 'Technician'
        );

        Test.startTest();
        insert ar; 
        Test.stopTest();

       
    }



}