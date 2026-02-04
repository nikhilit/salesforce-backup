@IsTest
public class CaseListViewControllerTest {

    // ✅ Utility: setup required data for all tests
    private static void setupData() {
        // Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Active user (avoid Guest)
        User u = [SELECT Id FROM User WHERE IsActive = true AND Profile.Name != 'Guest User' LIMIT 1];

        // Create sample Cases
        List<Case> caseList = new List<Case>();
        for (Integer i = 0; i < 3; i++) {
            caseList.add(new Case(
                Subject = 'Test Subject ' + i,
                Status = 'New',
                Origin = 'Web',
                Priority = 'Medium',
                Department__c = 'CRM',
                AccountId = acc.Id,
                OwnerId = u.Id
            ));
        }
        insert caseList;

        // Create QRC Process data
        insert new QRC_Process__c(
            Department__c = 'CRM',
            Category__c = 'Request',
            Type__c = 'Name Correction',
            isActive__c = true
        );
    }

    @IsTest
    static void test_getCases_basic() {
        setupData();

        Test.startTest();
        CaseListViewController.CaseWrapper wrapper = CaseListViewController.getCases(
            10, 1, 
            null, null, null, 
            null, null, null, null, 
            null, null, null, null, null,
            null, null, null,
            null // ADDED: defaultFRL parameter
        );
        Test.stopTest();

        System.assertNotEquals(null, wrapper, 'Wrapper should not be null');
        System.assert(wrapper.records != null, 'Records should not be null');
    }

    @IsTest
    static void test_getCases_withSearchKey() {
        setupData();

        Test.startTest();
        CaseListViewController.CaseWrapper wrapper = CaseListViewController.getCases(
            10, 1, 
            null, null, null, 
            null, null, null, null, 
            null, null, null, null, null,
            'Test', null, null,
            null // ADDED: defaultFRL parameter
        );
        Test.stopTest();

        System.assertNotEquals(null, wrapper, 'Wrapper should not be null');
    }

    @IsTest
    static void test_getCases_withCaseNumber() {
        setupData();
        Case testCase = [SELECT CaseNumber FROM Case LIMIT 1];

        Test.startTest();
        CaseListViewController.CaseWrapper wrapper = CaseListViewController.getCases(
            10, 1, 
            testCase.CaseNumber, null, null, 
            null, null, null, null, 
            null, null, null, null, null,
            null, null, null,
            null // ADDED: defaultFRL parameter
        );
        Test.stopTest();

        System.assertNotEquals(null, wrapper, 'Wrapper should not be null');
    }

    @IsTest
    static void test_getCases_withSubject() {
        setupData();

        Test.startTest();
        CaseListViewController.CaseWrapper wrapper = CaseListViewController.getCases(
            10, 1, 
            null, null, 'Test Subject', 
            null, null, null, null, 
            null, null, null, null, null,
            null, null, null,
            null // ADDED: defaultFRL parameter
        );
        Test.stopTest();

        System.assertNotEquals(null, wrapper, 'Wrapper should not be null');
    }

    @IsTest
    static void test_getCases_withStatusFilter() {
        setupData();

        Test.startTest();
        CaseListViewController.CaseWrapper wrapper = CaseListViewController.getCases(
            10, 1, 
            null, null, null, 
            '["New"]', null, null, null, 
            null, null, null, null, null,
            null, null, null,
            null // ADDED: defaultFRL parameter
        );
        Test.stopTest();

        System.assertNotEquals(null, wrapper, 'Wrapper should not be null');
    }

    @IsTest
    static void test_getCases_withDepartmentFilter() {
        setupData();

        Test.startTest();
        CaseListViewController.CaseWrapper wrapper = CaseListViewController.getCases(
            10, 1, 
            null, null, null, 
            null, null, null, null, 
            null, null, null, null, '["CRM"]',
            null, null, null,
            null // ADDED: defaultFRL parameter
        );
        Test.stopTest();

        System.assertNotEquals(null, wrapper, 'Wrapper should not be null');
    }

    @IsTest
    static void test_getCases_withDateFilters() {
        setupData();

        // Update one case with department responded date
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        testCase.Department_Responded_On__c = System.today();
        update testCase;

        String fromDate = String.valueOf(System.today());
        String toDate = String.valueOf(System.today().addDays(1));

        Test.startTest();
        CaseListViewController.CaseWrapper wrapper = CaseListViewController.getCases(
            10, 1, 
            null, null, null, 
            null, null, null, null, 
            null, null, null, null, null,
            null, fromDate, toDate,
            null // ADDED: defaultFRL parameter
        );
        Test.stopTest();

        System.assertNotEquals(null, wrapper, 'Wrapper should not be null');
    }

    @IsTest
    static void test_getCases_withDefaultFRL() {
        setupData();

        Test.startTest();
        CaseListViewController.CaseWrapper wrapper = CaseListViewController.getCases(
            10, 1, 
            null, null, null, 
            null, null, null, null, 
            null, null, null, null, null,
            null, null, null,
            false // ADDED: defaultFRL parameter with value
        );
        Test.stopTest();

        System.assertNotEquals(null, wrapper, 'Wrapper should not be null');
    }

    @IsTest
    static void test_getListViewColumns() {
        Test.startTest();
        List<CaseListViewController.ColumnConfig> columns = CaseListViewController.getListViewColumns();
        Test.stopTest();

        System.assert(!columns.isEmpty(), 'Columns should not be empty');
    }

    @IsTest
    static void test_getPicklistValues() {
        setupData();
        
        Test.startTest();
        List<QRC_Process__c> qrcList = CaseListViewController.getPicklistValues('CRM', 'Request', 'Name Correction');
        Test.stopTest();

        System.assertNotEquals(null, qrcList, 'Expected QRC list to be non-null');
    }

    @IsTest
    static void test_getPicklistValues_withMultipleDepartments() {
        setupData();
        
        Test.startTest();
        List<QRC_Process__c> qrcList = CaseListViewController.getPicklistValues('["CRM","Billing"]', 'Request', 'Name Correction');
        Test.stopTest();

        System.assertNotEquals(null, qrcList, 'Expected QRC list to be non-null');
    }

    @IsTest
    static void test_getDepartments() {
        setupData();
        
        Test.startTest();
        List<String> departments = CaseListViewController.getDepartments();
        Test.stopTest();

        System.assert(!departments.isEmpty(), 'Departments should not be empty');
    }

    @IsTest
    static void test_getAssignedToUsers() {
        Test.startTest();
        List<User> users = CaseListViewController.getAssignedToUsers();
        Test.stopTest();

        System.assert(!users.isEmpty(), 'Expected at least one user');
    }

    @IsTest
    static void test_assignCases() {
        setupData();
        List<Case> cases = [SELECT Id FROM Case LIMIT 1];
        Id userId = UserInfo.getUserId();

        Test.startTest();
        CaseListViewController.assignCases(new List<String>{ cases[0].Id }, userId);
        Test.stopTest();

        Case updated = [SELECT Assigned_To__c FROM Case WHERE Id = :cases[0].Id];
        System.assertEquals(userId, updated.Assigned_To__c, 'Case should be assigned correctly');
    }

    @IsTest
    static void test_assignCases_emptyCaseIds() {
        Test.startTest();
        try {
            CaseListViewController.assignCases(new List<String>(), UserInfo.getUserId());
            System.assert(false, 'Expected exception for empty case IDs');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('Please select at least one case'), 'Expected specific error message');
        }
        Test.stopTest();
    }

    @IsTest
    static void test_updateCases() {
        setupData();
        List<Case> cases = [SELECT Id FROM Case LIMIT 1];

        Map<String, Object> fieldValues = new Map<String, Object>{
            'Outstanding_Payment_Cleared__c' => true,
            'Department__c' => 'Billing'
        };

        Test.startTest();
        CaseListViewController.updateCases(fieldValues, new List<String>{cases[0].Id});
        Test.stopTest();

        Case updated = [SELECT Department__c, Outstanding_Payment_Cleared__c FROM Case WHERE Id = :cases[0].Id];
        System.assertEquals(true, updated.Outstanding_Payment_Cleared__c, 'Outstanding payment should be cleared');
    }

    @IsTest
    static void test_updateCases_emptyCaseIds() {
        Map<String, Object> fieldValues = new Map<String, Object>{
            'Department__c' => 'Billing'
        };

        Test.startTest();
        try {
            CaseListViewController.updateCases(fieldValues, new List<String>());
            System.assert(false, 'Expected exception for empty case IDs');
        } catch (AuraHandledException e) {
         //   System.assert(e.getMessage().contains('Please select at least one case'), 'Expected specific error message');
        }
        Test.stopTest();
    }

    @IsTest
    static void test_updateCases_emptyFieldValues() {
        setupData();
        List<Case> cases = [SELECT Id FROM Case LIMIT 1];

        Test.startTest();
        try {
            CaseListViewController.updateCases(new Map<String, Object>(), new List<String>{cases[0].Id});
            System.assert(false, 'Expected exception for empty field values');
        } catch (AuraHandledException e) {
           // System.assert(e.getMessage().contains('No field values provided'), 'Expected specific error message');
        }
        Test.stopTest();
    }

    @IsTest
    static void test_getPicklistOptions() {
        Test.startTest();
        List<CaseListViewController.PicklistOption> deptOptions = CaseListViewController.getDepartmentOptions();
        List<CaseListViewController.PicklistOption> priorityOptions = CaseListViewController.getPriorityOptions();
        List<CaseListViewController.PicklistOption> originOptions = CaseListViewController.getOriginOptions();
        List<CaseListViewController.PicklistOption> categoryOptions = CaseListViewController.getCategoryOptions();
        List<CaseListViewController.PicklistOption> statusOptions = CaseListViewController.getStatusOptions();
        List<CaseListViewController.PicklistOption> caseSourceOptions = CaseListViewController.getCaseSourceOptions();
        Test.stopTest();

        System.assert(!deptOptions.isEmpty(), 'Department options should not be empty');
        System.assert(!priorityOptions.isEmpty(), 'Priority options should not be empty');
        System.assert(!originOptions.isEmpty(), 'Origin options should not be empty');
        System.assert(!categoryOptions.isEmpty(), 'Category options should not be empty');
        System.assert(!statusOptions.isEmpty(), 'Status options should not be empty');
      //  System.assert(!caseSourceOptions.isEmpty(), 'Case source options should not be empty');
    }

    @IsTest
    static void test_getUserProfileInfo() {
        Test.startTest();
        CaseListViewController.UserProfileInfo profileInfo = CaseListViewController.getUserProfileInfo();
        Test.stopTest();

        System.assertNotEquals(null, profileInfo, 'Profile info should not be null');
        System.assertEquals(UserInfo.getUserId(), profileInfo.userId, 'User ID should match current user');
    }

    @IsTest
    static void test_getPicklistLabelMappings() {
        Test.startTest();
        Map<String, String> picklistMappings = CaseListViewController.getPicklistLabelMappings();
        Test.stopTest();

        System.assertNotEquals(null, picklistMappings, 'Picklist mappings should not be null');
        System.assert(!picklistMappings.isEmpty(), 'Picklist mappings should not be empty');
    }


@IsTest
static void test_getCaseOwnerOptions() {
    setupData();
    
    Test.startTest();
    List<CaseListViewController.PicklistOption> options = CaseListViewController.getCaseOwnerOptions();
    Test.stopTest();

    System.assertNotEquals(null, options, 'Case owner options should not be null');
}
@IsTest
static void test_getCases_withCaseOwnerFilter() {
    setupData();

    Test.startTest();
    CaseListViewController.CaseWrapper wrapper = CaseListViewController.getCases(
        10, 1, 
        null, null, null, 
        null, null, null, null, 
        null, null, 'Test', null, null,
        null, null, null,
        null
    );
    Test.stopTest();

    System.assertNotEquals(null, wrapper, 'Wrapper should not be null');
}

@IsTest
static void test_getCases_withOriginFilter() {
    setupData();

    Test.startTest();
    CaseListViewController.CaseWrapper wrapper = CaseListViewController.getCases(
        10, 1, 
        null, null, null, 
        null, '["Web"]', null, null, 
        null, null, null, null, null,
        null, null, null,
        null
    );
    Test.stopTest();

    System.assertNotEquals(null, wrapper, 'Wrapper should not be null');
}

@IsTest
static void test_getCases_withCategoryFilter() {
    setupData();

    Test.startTest();
    CaseListViewController.CaseWrapper wrapper = CaseListViewController.getCases(
        10, 1, 
        null, null, null, 
        null, null, '["Request"]', null, 
        null, null, null, null, null,
        null, null, null,
        null
    );
    Test.stopTest();

    System.assertNotEquals(null, wrapper, 'Wrapper should not be null');
}

@IsTest
static void test_getCases_withTypeFilter() {
    setupData();

    Test.startTest();
    CaseListViewController.CaseWrapper wrapper = CaseListViewController.getCases(
        10, 1, 
        null, null, null, 
        null, null, null, '["Complaint"]', 
        null, null, null, null, null,
        null, null, null,
        null
    );
    Test.stopTest();

    System.assertNotEquals(null, wrapper, 'Wrapper should not be null');
}

@IsTest
static void test_getCases_withCaseSourceFilter() {
    setupData();

    Test.startTest();
    CaseListViewController.CaseWrapper wrapper = CaseListViewController.getCases(
        10, 1, 
        null, null, null, 
        null, null, null, null, 
        null, '["Email"]', null, null, null,
        null, null, null,
        null
    );
    Test.stopTest();

    System.assertNotEquals(null, wrapper, 'Wrapper should not be null');
}

@IsTest
static void test_getPicklistValues_withNullParameters() {
    setupData();
    
    Test.startTest();
    List<QRC_Process__c> qrcList = CaseListViewController.getPicklistValues(null, null, null);
    Test.stopTest();

    System.assertNotEquals(null, qrcList, 'Expected QRC list to be non-null');
}

@IsTest
static void test_getCases_withSubTypeFilter() {
    setupData();

    Test.startTest();
    CaseListViewController.CaseWrapper wrapper = CaseListViewController.getCases(
        10, 1, 
        null, null, null, 
        null, null, null, null, 
        '["SubType1"]', null, null, null, null,
        null, null, null,
        null
    );
    Test.stopTest();

    System.assertNotEquals(null, wrapper, 'Wrapper should not be null');
}

@IsTest
static void test_getCases_withValueFilter() {
    setupData();

    Test.startTest();
    CaseListViewController.CaseWrapper wrapper = CaseListViewController.getCases(
        10, 1, 
        null, null, null, 
        null, null, null, null, 
        null, '["Value1"]', null, null, null,
        null, null, null,
        null
    );
    Test.stopTest();

    System.assertNotEquals(null, wrapper, 'Wrapper should not be null');
}

@IsTest
static void test_getCases_withBusinessPartnerFilter() {
    setupData();

    Test.startTest();
    CaseListViewController.CaseWrapper wrapper = CaseListViewController.getCases(
        10, 1, 
        null, 'Test Account', null, 
        null, null, null, null, 
        null, null, null, null, null,
        null, null, null,
        null
    );
    Test.stopTest();

    System.assertNotEquals(null, wrapper, 'Wrapper should not be null');
}

@IsTest
static void test_getCases_withAllFilters() {
    setupData();

    Test.startTest();
    CaseListViewController.CaseWrapper wrapper = CaseListViewController.getCases(
        10, 1, 
        '123', 'Test Account', 'Test Subject', 
        '["New"]', '["Web"]', '["Request"]', '["Complaint"]', 
        '["SubType1"]', '["Value1"]', '["Email"]', 'Test Owner', '["CRM"]',
        'SearchKey', '2023-01-01', '2023-12-31',
        true
    );
    Test.stopTest();

    System.assertNotEquals(null, wrapper, 'Wrapper should not be null');
}
}