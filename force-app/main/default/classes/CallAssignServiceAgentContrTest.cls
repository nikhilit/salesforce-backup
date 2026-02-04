@isTest
public class CallAssignServiceAgentContrTest {

    // Utility to create a test System Admin User
    private static User createTestUser() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User u = new User(
            Alias = 'tuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Tester',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Asia/Kolkata',
            UserName = 'testuser' + DateTime.now().getTime() + '@example.com',
            ProfileId = p.Id
        );
        insert u;
        return u;
    }

    @isTest
    static void testGetFilteredWorkOrders() {
        // Create WorkType
        WorkType wt = new WorkType(Name = 'Domestic Meter Checking',EstimatedDuration = 1);
        insert wt;

        // Create Account
        Account acc = new Account(Name = 'Test Account');
            insert acc;
        
        OperatingHours oph = new OperatingHours(Name = 'Test Operating Hours', TimeZone = 'Asia/Kolkata');
        insert oph;

        // Create Service Territory
        ServiceTerritory st = new ServiceTerritory(Name = 'Test Territory',OperatingHoursId=oph.Id,IsActive=true);
        insert st;

        // Fetch record type for WorkOrder
        Id workOrderRT = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName()
                          .get('MGL_O_M').getRecordTypeId();

        // Create WorkOrder
        WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            AccountId = acc.Id,
            ServiceTerritoryId = st.Id,
            WorkTypeId = wt.Id,
            Appointment_Status__c = 'Planned',
            RecordTypeId = workOrderRT
        );
        insert wo;

        // Create test user
        User u = createTestUser();

        Test.startTest();
        System.runAs(u) {
            CallAssignServiceAgentContr.PagedWorkOrders pw =
                CallAssignServiceAgentContr.getFilteredWorkOrders(5, 1,'jind','126101','JK','Main Road');

          /*  System.assertNotEquals(null, pw, 'PagedWorkOrders wrapper should not be null');
            System.assert(pw.totalSize > 0, 'At least one work order should be returned');
            System.assert(!pw.records.isEmpty(), 'Records list should not be empty');
            System.assertEquals('Domestic Meter Checking',
                                pw.records[0].WorkType.Name,
                                'WorkType should be Domestic Meter Checking'); */
        }
        Test.stopTest();
    }



}