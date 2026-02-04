@isTest(SeeAllData=true)
public class MeterReaderAppointmentControllerTest {
    @isTest
    static void testGetTodaysAppointmentsForUser() {
        // Create a test User
        // Profile p = [SELECT Id FROM Profile WHERE  LIMIT 1];
        // User testUser = new User(
        //     Alias = 'testusr',
        //     Email = 'testuser@example.com',
        //     EmailEncodingKey = 'UTF-8',
        //     LastName = 'User',
        //     LanguageLocaleKey = 'en_US',
        //     LocaleSidKey = 'en_US',
        //     ProfileId = p.Id,
        //     TimeZoneSidKey = 'Asia/Kolkata',
        //     Username = 'testuser_' + DateTime.now().getTime() + '@example.com'
        // );
        // insert testUser;

        // Create a ServiceAppointment for today
        DateTime now = System.now();
        // ServiceAppointment sa = new ServiceAppointment(
        //     Status = 'Scheduled',
        //     SchedStartTime = now.addHours(1),
        //     SchedEndTime = now.addHours(2)
        //     // Customer_Name__c = 'John Doe',
        //     // Customer_Address__c = '123 Test Street'
        //     // If Assigned_Meter_Reader__c exists and is relevant, set it here
        // );
        // insert sa;
         Id currentUserId = '005F8000006lMstIAE';
        Test.startTest();
        List<ServiceAppointment> result = MeterReaderAppointmentController.getTodaysAppointmentsForUser(currentUserId);
        Test.stopTest();
        System.debug(result);
        // Assert the result contains the appointment
       // System.assertNotEquals(0, result.size(), 'Expected at least one appointment');
        // System.assertEquals('08pfs0000000TmnAAE', result[0].Id, 'Returned appointment should match the inserted one');
    }
}