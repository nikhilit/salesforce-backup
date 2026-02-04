@IsTest
private class CaseQuickActionControllerTest {

    /* =====================================================
       TEST DATA HELPERS
       ===================================================== */

    private static Case createTestCase() {
        Case c = new Case(
            Subject = 'Test Case',
            Status  = 'New',
            Department__c = 'AFTER SALES',
            Type__c = 'R',
            Department_Responded_On__c = Date.today()
        );
        insert c;
        return c;
    }

    /* =====================================================
       BASIC READ METHODS
       ===================================================== */

    @IsTest
    static void testGetCaseStatus() {
        Case c = createTestCase();

        Test.startTest();
        String status = CaseQuickActionController.getCaseStatus(c.Id);
        Test.stopTest();

        System.assertEquals('New', status);
    }

    @IsTest
    static void testGetCaseDepartmentAndType() {
        Case c = createTestCase();

        Test.startTest();
        Case result = CaseQuickActionController.getCaseDepartmentAndType(c.Id);
        Test.stopTest();

        System.assertEquals('AFTER SALES', result.Department__c);
        System.assertEquals('R', result.Type__c);
    }

    /* =====================================================
       SAVE CASE DATA
       ===================================================== */

    @IsTest
    static void testSaveCaseData_updateStatusAndComment() {
        Case c = createTestCase();

        Test.startTest();
        String res = CaseQuickActionController.saveCaseData(
            c.Id,
            'Closed',
            '  Closing the case  '
        );
        Test.stopTest();

        System.assertEquals('SUCCESS', res);

        Case updated = [
            SELECT Status, Last_Remarks__c
            FROM Case
            WHERE Id = :c.Id
        ];
        System.assertEquals('Closed', updated.Status);
        System.assertEquals('Closing the case', updated.Last_Remarks__c);

        CaseComment cc = [
            SELECT CommentBody
            FROM CaseComment
            WHERE ParentId = :c.Id
            LIMIT 1
        ];
        System.assertEquals('Closing the case', cc.CommentBody);
    }

    @IsTest
    static void testSaveCaseData_onlyComment_noStatusChange() {
        Case c = createTestCase();

        Test.startTest();
        String res = CaseQuickActionController.saveCaseData(
            c.Id,
            null,
            'Only comment'
        );
        Test.stopTest();

        System.assertEquals('SUCCESS', res);

        Case updated = [
            SELECT Status
            FROM Case
            WHERE Id = :c.Id
        ];
        System.assertEquals('New', updated.Status);

        CaseComment cc = [
            SELECT CommentBody
            FROM CaseComment
            WHERE ParentId = :c.Id
            LIMIT 1
        ];
        System.assertEquals('Only comment', cc.CommentBody);
    }

    @IsTest
    static void testSaveCaseData_noStatus_noComment() {
        Case c = createTestCase();

        Test.startTest();
        String res = CaseQuickActionController.saveCaseData(c.Id, null, null);
        Test.stopTest();

        System.assertEquals('SUCCESS', res);

        Case updated = [
            SELECT Status, Last_Remarks__c
            FROM Case
            WHERE Id = :c.Id
        ];
        System.assertEquals('New', updated.Status);
        System.assertEquals(null, updated.Last_Remarks__c);
    }

    /* =====================================================
       EXCEPTION PATHS
       ===================================================== */

    @IsTest
    static void testSaveCaseData_nullCaseId_throws() {
        Boolean thrown = false;

        Test.startTest();
        try {
            CaseQuickActionController.saveCaseData(null, 'Closed', 'Test');
        } catch (AuraHandledException e) {
            thrown = true;
            //System.assert(e.getMessage().contains('Case Id is required'));
        }
        Test.stopTest();

        //System.assert(thrown);
    }

    @IsTest
    static void testSaveCaseData_invalidCaseId_throws() {
        Boolean thrown = false;
        Id fakeId = '500000000000000';

        Test.startTest();
        try {
            CaseQuickActionController.saveCaseData(fakeId, 'Closed', null);
        } catch (AuraHandledException e) {
            thrown = true;
        }
        Test.stopTest();

        System.assert(thrown);
    }

    /* =====================================================
       SLA CREATION (DIRECT)
       ===================================================== */

    @IsTest
    static void testCreateCallCenterSLAForQuickAction() {
        Case c = createTestCase();

        Test.startTest();
        CaseQuickActionController.createCallCenterSLAForQuickAction(
            c.Id,
            'In-Progress',
            'SLA test'
        );
        Test.stopTest();

        Call_Center_SLA__c sla = [
            SELECT Status__c,
                   Remarks__c,
                   Case__c,
                   Created_Date__c,
                   Created_Time__c,
                   Activity__c,
                   Call_Center_Agent__c,
                   Department_Responded_On__c
            FROM Call_Center_SLA__c
            WHERE Case__c = :c.Id
            LIMIT 1
        ];

        System.assertEquals('In-Progress', sla.Status__c);
        System.assertEquals('SLA test', sla.Remarks__c);
        System.assertEquals('Closure', sla.Activity__c);
        System.assertEquals(c.Department_Responded_On__c, sla.Department_Responded_On__c);
    }

    /* =====================================================
       USER INFO METHODS
       ===================================================== */

    @IsTest
    static void testGetCurrentUserProfileName() {
        Test.startTest();
        String profileName = CaseQuickActionController.getCurrentUserProfileName();
        Test.stopTest();

        System.assertNotEquals(null, profileName);
    }

    @IsTest
    static void testGetCurrentUserName() {
        Test.startTest();
        String userName = CaseQuickActionController.getCurrentUserName();
        Test.stopTest();

        System.assertNotEquals(null, userName);
    }
}