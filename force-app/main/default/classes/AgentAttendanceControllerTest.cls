@IsTest
private class AgentAttendanceControllerTest {

    // Helper method to create a test user with the given Type_Of_Work__c
    private static User createTestUser(String typeOfWork) {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            Alias = 'tuser',
            Email = 'testuser' + Math.random() + '@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Asia/Kolkata',
            UserName = 'testuser' + Math.random() + '@example.com',
            ProfileId = p.Id,
            Type_Of_Work__c = typeOfWork
        );
        insert u;
        return u;
    }

    // Helper to create Attendance__c
    private static Attendance__c createAttendance(User u, Boolean open) {
        Attendance__c att = new Attendance__c(
            User__c = u.Id,
            Day_In_Timestamp__c = System.now(),
            Block__c = 'Bandra Escalation',
            Work_Type_Location__c = u.Type_Of_Work__c,
            Sub_Function__c = 'Escalation Cell'
        );
        if (!open) {
            att.Day_Out_Timestamp__c = System.now().addHours(1);
        }
        insert att;
        return att;
    }

    // Helper to create Break__c
    private static Break__c createBreak(Attendance__c att, Boolean open) {
        Break__c brk = new Break__c(
            Attendance__c = att.Id,
            Break_Start_Time__c = System.now(),
            Break_Codes__c = 'Lunch Break'
        );
        if (!open) {
            brk.Break_End_Time__c = System.now().addMinutes(30);
        }
        insert brk;
        return brk;
    }

    @IsTest
    static void testGetCurrentUserName() {
        User u = createTestUser('Front Office');
        System.runAs(u) {
            Test.startTest();
            String name = AgentAttendanceController.getCurrentUserName();
            System.assertNotEquals(null, name);
            Test.stopTest();
        }
    }

    @IsTest
    static void testTriggerScheduledJob() {
        User u = createTestUser('Front Office');
        System.runAs(u) {
            Test.startTest();
            AgentAttendanceController.triggerScheduledJob();
            Test.stopTest();
        }
    }

    @IsTest
    static void testGetTodayAttendanceWithUserType() {
        User u = createTestUser('Front Office');
        System.runAs(u) {
            createAttendance(u, true);
            Test.startTest();
            Map<String, Object> result = AgentAttendanceController.getTodayAttendanceWithUserType();
            System.assert(result.containsKey('typeOfWork'));
            Test.stopTest();
        }
    }

    @IsTest
    static void testGetSubFunctionOptions() {
        User u = createTestUser('Front Office');
        System.runAs(u) {
            Test.startTest();
            List<String> options = AgentAttendanceController.getSubFunctionOptions();
            System.assertNotEquals(null, options);
            Test.stopTest();
        }
    }

    @IsTest
    static void testGetUserBlockAccessInfo() {
        User u = createTestUser('Back Office');
        System.runAs(u) {
            Test.startTest();
            Map<String, Object> result = AgentAttendanceController.getUserBlockAccessInfo();
            System.assertNotEquals(null, result);
            Test.stopTest();
        }
    }

    @IsTest
    static void testHandleAttendanceCheckInOutAndInvalid() {
        User u = createTestUser('Front Office');
        System.runAs(u) {
            Test.startTest();
            // Check-In
            AgentAttendanceController.handleAttendance('Check-In', 'Bandra Escalation', String.valueOf(System.now()), 'Escalation Cell');

            // Check-Out
            AgentAttendanceController.handleAttendance('Check-Out', null, String.valueOf(System.now()), null);

            // Invalid Action
            try {
                AgentAttendanceController.handleAttendance('Invalid', null, null, null);
                System.assert(false, 'Expected exception for invalid action');
            } catch (AuraHandledException e) {
                //System.assert(e.getMessage().contains('Invalid action type'));
            }
            Test.stopTest();
        }
    }

    @IsTest
    static void testBreakMethodsFullFlow() {
        User u = createTestUser('Front Office');
        System.runAs(u) {
            Attendance__c att = createAttendance(u, true);

            Test.startTest();
            // Create Break
            Id brkId = AgentAttendanceController.createBreakRecord('Lunch Break');

            // Get Ongoing Break
            Break__c ongoing = AgentAttendanceController.getOngoingBreak();
            System.assertNotEquals(null, ongoing);

            // End Break by record
            AgentAttendanceController.endBreakRecord(String.valueOf(System.now()), att.Id);

            // End Break directly
            //AgentAttendanceController.endBreak();

            // Get Break Reasons
            List<String> reasons = AgentAttendanceController.getBreakReasons();
            System.assertNotEquals(null, reasons);
            Test.stopTest();
        }
    }

    @IsTest
    static void testGetUserProfileName() {
        User u = createTestUser('Call Center');
        System.runAs(u) {
            Test.startTest();
            String profileName = AgentAttendanceController.getUserProfileName();
            System.assertNotEquals(null, profileName);
            Test.stopTest();
        }
    }

    @IsTest
    static void testGetAttendanceStatus() {
        User u = createTestUser('Call Center');
        System.runAs(u) {
            Test.startTest();
            // No Attendance → Checked Out
            String status = AgentAttendanceController.getAttendanceStatus();
            System.assertEquals('Checked Out', status);

            // Open Attendance → Checked In
            Attendance__c att = createAttendance(u, true);
            status = AgentAttendanceController.getAttendanceStatus();
            System.assertEquals('Checked In', status);

            // On Break → On Break
            createBreak(att, true);
            status = AgentAttendanceController.getAttendanceStatus();
            System.assertEquals('On Break', status);
            Test.stopTest();
        }
    }
    @IsTest
static void testBreakMethodsFullFlows() {
    User u = createTestUser('Front Office');
    System.runAs(u) {
        Attendance__c att = createAttendance(u, true);

        Test.startTest();
        // Create Break
        Id brkId = AgentAttendanceController.createBreakRecord('Lunch Break');

        // Get Ongoing Break
        Break__c ongoing = AgentAttendanceController.getOngoingBreak();
        System.assertNotEquals(null, ongoing);

        // End Break by record
        AgentAttendanceController.endBreakRecord(String.valueOf(System.now()), att.Id);

        // End Break directly (for coverage)
        AgentAttendanceController.createBreakRecord('Tea Break'); // new break
        AgentAttendanceController.endBreak(); // cover direct method

        // Get Break Reasons
        List<String> reasons = AgentAttendanceController.getBreakReasons();
        System.assertNotEquals(null, reasons);
        Test.stopTest();
    }
}

}