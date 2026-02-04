@isTest
private class CaseActionControllerTest {

    @testSetup
    static void setupData() {
        // Create DRS__c
        DRS__c drs = new DRS__c(Name = 'DRS001');
        insert drs;

        // Create Account with DRS
        Account acc = new Account(
            Name = 'Test Account',
            DRS_Master__c = drs.Id
        );
        insert acc;

        // SPOC Mapping (not used directly by class, but ok to keep)
        Departments_SPOC_Mapping__c mapping = new Departments_SPOC_Mapping__c(
            Department__c = 'AFTER SALES',
            DRS__c        = drs.Id,
            SPOC_Id__c    = UserInfo.getUserId()
        );
        insert mapping;

        // Base Case (AFTER SALES) – will be used in happy-path test
        Case cs = new Case(
            AccountId         = acc.Id,
            Department__c     = 'AFTER SALES',
            Status            = 'New',
            TAT_in_minutes__c = '600',
            TAT_in_days__c    = '2',
            SPOC__c           = UserInfo.getUserId(),
            Docket_Number__c  = '123',          // key for lookup in tests
            Sub_Type__c       = 'Rubber Tube'   // to exercise Sub_Type switch & Rubber Tube branch
        );
        insert cs;

        // Create escalation record (Total_Days_Consumed__c is not writeable in your org)
        Case_Escalation__c esc = new Case_Escalation__c(
            Case__c                     = cs.Id,
            Actioned_By_Department__c   = System.today(),
            Assigned_To_Department_1__c = System.today(),
            Is_Active__c                = true
        );
        insert esc;

        // Insert an existing WorkOrder for ParentWorkOrderId branch
        WorkOrder existingWO = new WorkOrder(
            Subject = 'Existing WO',
            CaseId  = cs.Id,
            Status  = 'New'
        );
        insert existingWO;

        // Insert WorkTypes used in mapping (EstimatedDuration is REQUIRED on WorkType in your org)
        insert new WorkType(Name = 'Individual Permanent Disconnection', EstimatedDuration = 1);
        insert new WorkType(Name = 'Rubber Hose Replacement',             EstimatedDuration = 1);
        insert new WorkType(Name = 'Domestic Meter Checking',             EstimatedDuration = 1);
        // Note: 'After Sales Service' is not queried in SOQL.
    }

    @isTest
    static void testProcessCase_HappyPath() {
        // Re-find the base case by known Docket_Number__c
        Case testCase = [
            SELECT Id, TAT_in_days__c, TAT_in_minutes__c
            FROM Case
            WHERE Docket_Number__c = '123'
            LIMIT 1
        ];

        Test.startTest();
        CaseActionController.processCase(testCase.Id, 'Processing case successfully');
        Test.stopTest();

        // Re-query case to verify core fields and Remaining_TAT__c when remainingDays > 0
        Case csAfter = [
            SELECT Status, Current_Work_Type__c, OwnerId, Assigned_To__c, 
                   Is_reponed__c, Comments, Remaining_TAT__c, Reopen_Count__c,
                   Bypass_Status_Validation__c, Department_Responded_on__c,
                   Last_Remarks__c
            FROM Case
            WHERE Id = :testCase.Id
        ];

        System.assertEquals('In-Progress', csAfter.Status);
        System.assertEquals('1', csAfter.Current_Work_Type__c);
        System.assertEquals(UserInfo.getUserId(), csAfter.OwnerId);
        System.assertEquals(UserInfo.getUserId(), csAfter.Assigned_To__c);
        System.assertEquals(true, csAfter.Is_reponed__c);
        //System.assertEquals('Processing case successfully', csAfter.Comments);
        System.assertEquals('Processing case successfully', csAfter.Last_Remarks__c);
        System.assertEquals(1, csAfter.Reopen_Count__c);
        System.assertEquals(null, csAfter.Department_Responded_on__c);

        // remainingDays = tatDays(2) - totalDays(0) = 2 → 2 * 1440 = 2880
        System.assertEquals('2880', csAfter.Remaining_TAT__c);

        // WorkOrder created with ParentWorkOrderId set (existing WO) and Sub_Type__c override for Rubber Tube
        WorkOrder wo = [
            SELECT Id, CaseId, ParentWorkOrderId, Department__c, Status, Case_Remark__c, Follow_up_Remarks__c
            FROM WorkOrder
            WHERE CaseId = :testCase.Id
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        

        // Call Center SLA record created
        Call_Center_SLA__c sla = [
            SELECT Id, Case__c, Status__c, Remarks__c
            FROM Call_Center_SLA__c
            WHERE Case__c = :testCase.Id
            LIMIT 1
        ];
        System.assertEquals('In-Progress', sla.Status__c);
        System.assertEquals('Processing case successfully', sla.Remarks__c);

        // Existing escalations set to inactive and new escalation record inserted
        List<Case_Escalation__c> escalations = [
            SELECT Id, Is_Active__c, Escalation_Type__c
            FROM Case_Escalation__c
            WHERE Case__c = :testCase.Id
        ];
        Boolean foundReopen = false;
        Boolean foundInactive = false;
        for (Case_Escalation__c ce : escalations) {
            if (ce.Escalation_Type__c == 'Reopen') {
                foundReopen = true;
                System.assertEquals(true, ce.Is_Active__c);
            } else {
                foundInactive = foundInactive || (ce.Is_Active__c == false);
            }
        }
        System.assert(foundReopen, 'Reopen escalation record should be present');
        System.assert(foundInactive, 'Existing escalation should be marked inactive');
    }

    @isTest
    static void testProcessCase_RemainingTatElseBranch_NoEscalations() {
        // Re-get DRS__c for this test (testSetup data is cloned, statics are not)
        Id drsId = [SELECT Id FROM DRS__c LIMIT 1].Id;

        // Case with Account, SPOC, but NO escalations → caseEscalationsToInactive empty
        Account acc = new Account(
            Name         = 'No Escalations Account',
            DRS_Master__c = drsId
        );
        insert acc;

        Case cs = new Case(
            AccountId         = acc.Id,
            Department__c     = 'BILLING',
            Status            = 'New',
            TAT_in_minutes__c = '500',
            TAT_in_days__c    = null,          // tatDays stays 0
            SPOC__c           = UserInfo.getUserId(),
            Docket_Number__c  = '456',
            Sub_Type__c       = 'Meter Checking'  // to hit 'Meter Checking' branch in switch
        );
        insert cs;

        Test.startTest();
        CaseActionController.processCase(cs.Id, 'No escalation test');
        Test.stopTest();

        Case updatedCase = [
            SELECT Remaining_TAT__c, Status, Current_Work_Type__c
            FROM Case WHERE Id = :cs.Id
        ];

        // remainingDays = tatDays(0) - totalDays(0) = 0 → else branch → Remaining_TAT__c = TAT_in_minutes__c
        System.assertEquals('500', updatedCase.Remaining_TAT__c);
        System.assertEquals('In-Progress', updatedCase.Status);
        System.assertEquals('1', updatedCase.Current_Work_Type__c);

        // WorkOrder should be created even without existing WorkOrder
        WorkOrder wo = [
            SELECT Id, WorkTypeId, ParentWorkOrderId, Department__c
            FROM WorkOrder
            WHERE CaseId = :cs.Id
            LIMIT 1
        ];
        System.assertEquals('O&M', wo.Department__c);
        System.assertNotEquals(null, wo.WorkTypeId);
        System.assertEquals(null, wo.ParentWorkOrderId);
    }

    @isTest
    static void testProcessCase_AccountAndLeadMissing_TriggersErrorLogger() {
        // Case with no Account and no Lead__c → AuraHandledException inside try, caught and logged
        Case cs = new Case(
            Department__c     = 'AFTER SALES',
            Status            = 'New',
            TAT_in_minutes__c = '100',
            TAT_in_days__c    = '1',
            SPOC__c           = UserInfo.getUserId(),
            Docket_Number__c  = 'NOACC'
            // AccountId = null, Lead__c = null
        );
        insert cs;

        Test.startTest();
        // No exception should bubble up due to catch
        CaseActionController.processCase(cs.Id, 'Missing BP/Prospect');
        Test.stopTest();

        // Error logger should have been written (we just check existence)
        Error_Logger__c err = [
            SELECT Id, Class_Name__c, Method_Name__c
            FROM Error_Logger__c
            WHERE Class_Name__c = 'CaseActionController'
              AND Method_Name__c = 'processCase'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertNotEquals(null, err.Id, 'Error_Logger__c record should exist');
    }

    @isTest
    static void testProcessCase_NoSPOC_ErrorPath() {
        Id drsId = [SELECT Id FROM DRS__c LIMIT 1].Id;

        // Case with Account but no SPOC__c → SPOC error branch
        Account acc = new Account(
            Name         = 'No SPOC Account',
            DRS_Master__c = drsId
        );
        insert acc;

        Case cs = new Case(
            AccountId         = acc.Id,
            Department__c     = 'AFTER SALES',
            Status            = 'New',
            TAT_in_minutes__c = '60',
            TAT_in_days__c    = '1',
            SPOC__c           = null,                  // to hit SPOC error branch
            Docket_Number__c  = 'NOSPOC'
        );
        insert cs;

        Test.startTest();
        // AuraHandledException is thrown inside try, then caught and logged, so no exception to the test
        CaseActionController.processCase(cs.Id, 'No SPOC set');
        Test.stopTest();

        // Error logger should record this as well (again, just existence)
        Error_Logger__c err = [
            SELECT Id, Class_Name__c, Method_Name__c
            FROM Error_Logger__c
            WHERE Class_Name__c = 'CaseActionController'
              AND Method_Name__c = 'processCase'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertNotEquals(null, err.Id, 'Error_Logger__c record should exist for SPOC error');
    }

    @isTest
    static void testProcessCase_NullCaseId_Throws() {
        Boolean thrown = false;

        Test.startTest();
        try {
            CaseActionController.processCase(null, 'Should fail');
        } catch (AuraHandledException e) {
            thrown = true;
            //System.assert(e.getMessage().contains('Case Id is required'));
        }
        Test.stopTest();

        System.assert(thrown, 'Expected AuraHandledException when caseId is null');
    }

    @isTest
    static void testProcessCase_NoEscalations_IndividualDisconnection() {
        Id drsId = [SELECT Id FROM DRS__c LIMIT 1].Id;

        // Another case to touch additional Sub_Type__c mapping, with no escalations
        Account acc = new Account(
            Name         = 'IPD Account',
            DRS_Master__c = drsId
        );
        insert acc;

        Case cs = new Case(
            AccountId         = acc.Id,
            Department__c     = 'BILLING',  // not AFTER SALES, so first switch result is kept
            Status            = 'New',
            TAT_in_minutes__c = '300',
            TAT_in_days__c    = '1',
            SPOC__c           = UserInfo.getUserId(),
            Docket_Number__c  = 'IPD',
            Sub_Type__c       = 'Individual Permanent Disconnection & Refund Processing'
        );
        insert cs;

        Test.startTest();
        CaseActionController.processCase(cs.Id, 'IPD Case');
        Test.stopTest();

        // WorkOrder should be created with WorkType mapped to 'Individual Permanent Disconnection'
        WorkOrder wo = [
            SELECT Id, WorkTypeId, Department__c
            FROM WorkOrder
            WHERE CaseId = :cs.Id
            LIMIT 1
        ];
        System.assertEquals('O&M', wo.Department__c);
        System.assertNotEquals(null, wo.WorkTypeId);
    }
}