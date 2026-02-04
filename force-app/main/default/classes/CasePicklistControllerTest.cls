@IsTest
public class CasePicklistControllerTest {

    /* ================= HELPERS ================= */

    private static DRS__c createDRS() {
        DRS__c d = new DRS__c(Name = 'DRS');
        insert d;
        return d;
    }

    private static Account createAccount() {
        Account a = new Account(
            Name = 'Acc',
            Drs_Master__c = createDRS().Id
        );
        insert a;
        return a;
    }

    private static Case createCase() {
        Case c = new Case(
            Subject = 'Test',
            Status  = 'New',
            AccountId = createAccount().Id
        );
        insert c;
        return c;
    }

    private static Attendance__c createAttendance() {
        Attendance__c a = new Attendance__c(
            Name = 'Today',
            User__c = UserInfo.getUserId(),
            Day_In_Timestamp__c = System.now()
        );
        insert a;
        return a;
    }

    private static void createQRC() {
        insert new QRC_Process__c(
            Department__c   = 'BIS',
            Category__c     = 'Request',
            Type__c         = 'MGL Connect',
            Sub_Type__c     = 'Name Transfer',
            Value_1__c      = 'Proof Provided',
            TAT_in_hours__c = 48,
            isActive__c     = true
        );
    }

    /* ================= SUCCESS ================= */

    @IsTest
    static void testUpdateCaseRecord_Success_AllBranches() {
        Case c = createCase();
        createAttendance();
        createQRC();

        Map<String,String> valueMap = new Map<String,String>{
            'PD_Reason__c'   => 'Redevelopment of society',
            'New_Address__c' => 'Mumbai'
        };

        Test.startTest();
        CasePicklistController.updateCaseRecord(
            c.Id,
            'BIS',
            'Request',
            'MGL Connect',
            'Name Transfer',
            'Proof Provided',
            valueMap,
            48,
            'remarks',
            'a@test.com',
            '9999999999',
            'John',
            'A',
            'Doe',
            'Mr.',
            '123',
            Date.today(),
            Date.today().addDays(1),
            '100'
        );
        Test.stopTest();

        Case updated = [
            SELECT Attendance__c,
                   PD_Reason__c,
                   New_Address__c,
                   TAT__c,
                   TAT_in_minutes__c,
                   TAT_in_days__c,
                   Remarks__c,
                   Amount__c
            FROM Case WHERE Id = :c.Id
        ];

        System.assertNotEquals(null, updated.Attendance__c);
        System.assertEquals('Redevelopment of society', updated.PD_Reason__c);
        System.assertEquals('Mumbai', updated.New_Address__c);
        System.assertEquals('remarks', updated.Remarks__c);
        System.assertEquals('100', updated.Amount__c);
        System.assertNotEquals(null, updated.TAT__c);
    }

    /* ================= NULL CASE ================= */

    @IsTest
    static void testUpdateCaseRecord_NullCaseId() {
        Boolean thrown = false;
        try {
            CasePicklistController.updateCaseRecord(
                null,
                'BIS','Request','MGL Connect','Name Transfer','Issue',
                null,
                48,
                null,
                null,null,null,null,null,null,null,
                null,null,null
            );
        } catch (AuraHandledException e) {
            thrown = true;
        }
        System.assert(thrown);
    }

    /* ================= NO ATTENDANCE ================= */

    @IsTest
    static void testUpdateCaseRecord_NoAttendance() {
        Case c = createCase();
        createQRC();

        Boolean thrown = false;
        try {
            Test.startTest();
            CasePicklistController.updateCaseRecord(
                c.Id,
                'BIS','Request','MGL Connect','Name Transfer','Issue',
                null,
                48,
                null,
                null,null,null,null,null,null,null,
                null,null,null
            );
            Test.stopTest();
        } catch (AuraHandledException e) {
            thrown = true;
        }
        System.assert(thrown);
    }

    /* ================= ON BREAK ================= */

    @IsTest
    static void testUpdateCaseRecord_OnBreak() {
        Case c = createCase();
        createQRC();
        Attendance__c att = createAttendance();

        insert new Break__c(
            Attendance__c     = att.Id,
            Break_Codes__c    = 'Training',
            Break_Start_Time__c = System.now()
        );

        Boolean thrown = false;
        try {
            Test.startTest();
            CasePicklistController.updateCaseRecord(
                c.Id,
                'BIS','Request','MGL Connect','Name Transfer','Issue',
                null,
                48,
                null,
                null,null,null,null,null,null,null,
                null,null,null
            );
            Test.stopTest();
        } catch (AuraHandledException e) {
            thrown = true;
        }
        System.assert(thrown);
    }

    /* ================= PICKLIST VALUES ================= */

    @IsTest
    static void testGetPicklistValues_WithAndWithoutType() {
        createQRC();

        Test.startTest();
        List<QRC_Process__c> withType =
            CasePicklistController.getPicklistValues('BIS','Request','MGL Connect');

        List<QRC_Process__c> withoutType =
            CasePicklistController.getPicklistValues('BIS','Request',null);
        Test.stopTest();

        System.assert(withType.size() > 0);
        System.assert(withoutType.size() > 0);
    }

    /* ================= GET CASE RECORD ================= */

    @IsTest
    static void testGetCaseRecord() {
        Case c = createCase();
        c.Remarks__c = 'Hello';
        update c;

        Test.startTest();
        Case fetched = CasePicklistController.getCaseRecord(c.Id);
        Test.stopTest();

        System.assertEquals('Hello', fetched.Remarks__c);
    }

    /* ================= SALUTATION PICKLIST ================= */

    @IsTest
    static void testGetSalutationPicklist() {
        Test.startTest();
        List<Map<String, String>> result =
            CasePicklistController.getSalutationPicklist();
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assert(result.size() > 0);
        System.assert(result[0].containsKey('label'));
        System.assert(result[0].containsKey('value'));
    }

    /* ================= PD REASON PICKLIST ================= */

    @IsTest
    static void testGetPDReasonPicklist() {
        Test.startTest();
        List<Map<String, String>> result =
            CasePicklistController.getPDReasonPicklist();
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assert(result.size() > 0);
        System.assert(result[0].containsKey('label'));
        System.assert(result[0].containsKey('value'));
    }

    /* ================= ATTACHMENT COUNT ================= */

    @IsTest
    static void testGetAttachmentCount_NoAttachments() {
        Case c = createCase();

        Integer count = CasePicklistController.getAttachmentCount(c.Id);
        System.assertEquals(0, count);
    }
}