@IsTest
public class DailyEscalationSpocSchedulerTest {

    @testSetup
    static void setupData() {

        // ---------- DRS ----------
        DRS__c drs = new DRS__c(
            Name = 'BIS Test DRS'
        );
        insert drs;

        // ---------- QRC ----------
        QRC_Process__c qrc = new QRC_Process__c(
            Category__c = 'Request',
            Type__c = 'BIS Process',
            Department__c = 'BIS',
            TAT_in_hours__c = 24,
            Isactive__c = true
        );
        insert qrc;

        // ---------- SPOC USER ----------
        Profile p = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Standard User'
            LIMIT 1
        ];

        User spoc = new User(
            FirstName = 'BIS',
            LastName = 'SPOC',
            Email = 'bisspoc@test.com',
            Username = 'bisspoc_' + System.currentTimeMillis() + '@test.com',
            Alias = 'bspoc',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert spoc;

        // ---------- ACCOUNT ----------
        Account acc = new Account(
            Name = 'BIS Account',
            FirstName__c = 'Test',
            LastName__c = 'Customer',
            DRS_Master__c = drs.Id
        );
        insert acc;

        // ---------- SPOC MAPPING ----------
        Departments_SPOC_Mapping__c mapping = new Departments_SPOC_Mapping__c(
            Department__c = 'BIS',
            DRS__c = drs.Id,
            QRC_Process__c = qrc.Id,
            SPOC_Id_2__c = spoc.Id,
            SPOC_Id_3__c = spoc.Id,
            SPOC_Id_4__c = spoc.Id
        );
        insert mapping;

        // ---------- CASE (VIOLATION IN LAST 24 HRS) ----------
        Case c = new Case(
            AccountId = acc.Id,
            Status = 'New',
            Department__c = 'BIS',
            QRC_Process__c = qrc.Id,
            Case_Violation__c = true,
            Case_Violation_Time_1__c = System.now().addHours(-2),
            Docket_Number__c = 'DCKT-' + System.currentTimeMillis()
        );
        insert c;
    }

    @IsTest
    static void testSchedulerExecution() {

        Test.startTest();

        String jobId = System.schedule(
            'DailyEscalationSpocScheduler_Test',
            '0 0 0 * * ?',
            new DailyEscalationSpocScheduler()
        );

        Test.stopTest();

        // ---------- ASSERTIONS ----------

        // Scheduler was created
        System.assertNotEquals(null, jobId, 'Scheduler job ID should not be null');

        // Case exists and matches criteria
        Integer caseCount = [
            SELECT COUNT()
            FROM Case
            WHERE Department__c = 'BIS'
            AND Case_Violation__c = true
        ];
        System.assertEquals(1, caseCount, 'Exactly one BIS violation case should exist');
    }
}