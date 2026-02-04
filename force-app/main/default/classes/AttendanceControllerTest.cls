@isTest
public class AttendanceControllerTest {

    private static User createUser() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'test' + System.currentTimeMillis() + '@example.com',
            Username = 'test' + System.currentTimeMillis() + '@example.com',
            Alias = 'tusr',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert u;
        return u;
    }

    private static ServiceResource createServiceResource(Id userId) {
        ServiceResource sr = new ServiceResource(
            Name = 'Test SR',
            IsActive = true,
            RelatedRecordId = userId
        );
        insert sr;
        return sr;
    }

    @isTest
    static void test_getTodayAttendance_noRecord() {
        User u = createUser();
        System.runAs(u) {
            Test.startTest();
            AttendanceController.AttendanceWrapper wrap = AttendanceController.getTodayAttendance();
            Test.stopTest();

            System.assertEquals(null, wrap.attendance, 'No record should return null attendance');
            System.assertEquals(false, wrap.canViewVisits);
        }
    }

    @isTest
    static void test_markAttendance_present_and_getTodayAttendance() {
        User u = createUser();
        ServiceResource sr = createServiceResource(u.Id);
        System.runAs(u) {
            Test.startTest();
            String res = AttendanceController.markAttendance('Present', 12.9716, 77.5946, null);
            Test.stopTest();
            System.assertEquals('SUCCESS', res);
    
            AttendanceController.AttendanceWrapper wrap = AttendanceController.getTodayAttendance();
            System.assertNotEquals(null, wrap.attendance, 'Attendance should exist');
            System.assertEquals(true, wrap.canViewVisits, 'Present without day-out should allow view');
        }
    }


    @isTest
    static void test_markAttendance_onLeave_and_absenceRecord() {
        User u = createUser();
        ServiceResource sr = createServiceResource(u.Id);
        System.runAs(u) {
            Test.startTest();
            String res = AttendanceController.markAttendance('On Leave', null, null, 'Vacation');
            Test.stopTest();
            System.assertEquals('SUCCESS', res);

            List<ResourceAbsence> abs = [SELECT Id, Description FROM ResourceAbsence WHERE ResourceId = :sr.Id];
            System.assert(!abs.isEmpty(), 'Absence should be created for On Leave');
            System.assert(abs[0].Description.contains('Vacation'));
        }
    }

    @isTest
    static void test_markAttendance_alreadyMarked_and_markDayOut() {
        User u = createUser();
        ServiceResource sr = createServiceResource(u.Id);

        System.runAs(u) {
            Attendance__c att = new Attendance__c(
            User__c = u.Id,
            Attendance_Date__c = Date.today(),
            Status__c = 'Present',
            Day_In_Timestamp__c = System.now(),
            Day_In_Lat__c = 11.11,         
            Day_In_Long__c = 22.22        
        );
        insert att;

            Test.startTest();
            String res = AttendanceController.markAttendance('Present', 11.11, 22.22, null);
            System.assertEquals('ALREADY_MARKED', res);
            AttendanceController.markDayOut(33.33, 44.44);
            Test.stopTest();

            Attendance__c updated = [SELECT Day_Out_Timestamp__c, Day_Out_Lat__c, Day_Out_Long__c FROM Attendance__c WHERE Id = :att.Id];
            System.assertNotEquals(null, updated.Day_Out_Timestamp__c);
            System.assertEquals(33.33, updated.Day_Out_Lat__c);
            System.assertEquals(44.44, updated.Day_Out_Long__c);
        }
    }

    @isTest
    static void test_getStatusOptions() {
        Test.startTest();
        List<AttendanceController.PicklistOption> opts = AttendanceController.getStatusOptions();
        Test.stopTest();
        System.assert(!opts.isEmpty(), 'Picklist options should not be empty');
        System.assertNotEquals(null, opts[0].label);
        System.assertNotEquals(null, opts[0].value);
    }

}