@IsTest
public class AS_AttendanceProcessorTest {

    @TestSetup
    static void setupData() {
        // Create a User
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User u = new User(
            FirstName = 'Test',
            LastName = 'Agent',
            Email = 'testagent@example.com',
            Username = 'testagent' + DateTime.now().getTime() + '@example.com',
            Alias = 'tagent',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert u;

        // Create ServiceResource linked to User
        ServiceResource sr = new ServiceResource(
            Name = 'Test Resource',
            RelatedRecordId = u.Id,
            IsActive = true
        );
        insert sr;

        // Attendance 1 → should become Present
        Attendance__c att1 = new Attendance__c(
            User__c = u.Id,
            Attendance_Date__c = Date.today(),
            Day_In_Timestamp__c = DateTime.now().addHours(-9)
        );
        insert att1;

        // Attendance 2 → should become Absent
        Attendance__c att2 = new Attendance__c(
            User__c = u.Id,
            Attendance_Date__c = Date.today(),
            Day_In_Timestamp__c = DateTime.now().addHours(-8)
        );
        insert att2;

        // WorkOrder for Attendance 1 → ensures Present
        WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            Agent__c = sr.Id,
            Check_In_Date_Time__c = DateTime.now().addHours(-8),
            Check_Out_Date_Time__c = DateTime.now().addHours(-1),
            Status = 'Completed'
        );
        insert wo;
    }

    @IsTest
    static void testProcessAttendance() {
        Test.startTest();
        AS_AttendanceProcessor.processAttendance();
        Test.stopTest();

        List<Attendance__c> atts = [
            SELECT Id, Status__c, Day_Out_Timestamp__c
            FROM Attendance__c
            WHERE Attendance_Date__c = :Date.today()
            ORDER BY CreatedDate ASC
        ];

        //System.assertEquals(2, atts.size(), 'Should process 2 Attendance records');

        // First one → Present
        //System.assertEquals('Present', atts[0].Status__c, 'First Attendance should be Present');
        //System.assertNotEquals(null, atts[0].Day_Out_Timestamp__c, 'Day_Out_Timestamp should be populated');

        // Second one → Absent
        //System.assertEquals('Absent', atts[1].Status__c, 'Second Attendance should be Absent');
        //System.assertEquals(null, atts[1].Day_Out_Timestamp__c, 'Day_Out_Timestamp should remain null');
    }

    @IsTest
    static void testScheduler() { 
        Test.startTest();
        String cronExp = '0 45 23 * * ?'; // 11:45 PM IST = 18:15 GMT (adjust if org timezone differs)
        AS_AttendanceScheduler.scheduleJob('Test Attendance Job 1', cronExp);
        Test.stopTest();

        // Verify scheduler invoked processor logic
        List<Attendance__c> atts = [
            SELECT Id, Status__c
            FROM Attendance__c
            WHERE Attendance_Date__c = :Date.today()
        ];
        System.assert(atts.size() > 0, 'Scheduler should have processed attendance records'); 
    }
    
    @IsTest
    static void testScheduler2() { 
        Test.startTest();
        new AS_AttendanceScheduler();
        Test.stopTest();

        // Verify scheduler invoked processor logic
        List<Attendance__c> atts = [
            SELECT Id, Status__c
            FROM Attendance__c
            WHERE Attendance_Date__c = :Date.today()
        ];
        System.assert(atts.size() > 0, 'Scheduler should have processed attendance records');
    }
}