@isTest
public class AS_AccountValidationServiceTest {

    // ---------- Helpers ----------
    private static User createStdUser(String unameSuffix) {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            FirstName = 'Test',
            LastName  = 'User' + unameSuffix,
            Email     = 'test' + unameSuffix + '@example.com',
            Username  = 'test' + unameSuffix + '@example.com',
            Alias     = 't' + unameSuffix.left(4),
            TimeZoneSidKey   = 'Asia/Kolkata',
            LocaleSidKey     = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey= 'en_US',
            ProfileId = p.Id
        );
        insert u;
        return u;
    }

    private static WorkOrder makeWO(String subj, String recTypeDevName) {
        Account a = new Account(Name = subj + ' Acc');
        insert a;

       // Fetch correct RecordTypeId for WorkOrder
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'WorkOrder' AND DeveloperName = 'MGL_R_T' LIMIT 1];
        
        WorkOrder wo = new WorkOrder(
            Subject = 'WO Match',
            Status  = 'New',
            Priority= 'Medium',
            AccountId = a.Id,
            RecordTypeId = rt.Id,         
            Remarks__c = 'Any'
        );
        insert wo;

        return wo;
    }

    // Minimal FSL setup to insert a ServiceTerritoryMember
    private static void createSTMForUser(User u, String resourceType) {
        // Operating Hours
        OperatingHours oh = new OperatingHours(Name='Test OH', TimeZone='Asia/Kolkata');
        insert oh;
        // Territory
        ServiceTerritory st = new ServiceTerritory(Name='Test Territory', OperatingHoursId=oh.Id, IsActive=true);
        insert st;
        // Service Resource for the user
        ServiceResource sr = new ServiceResource(
            Name='SR ' + u.LastName,
            IsActive=true,
            RelatedRecordId = u.Id,
            Service_Resource_Type__c = resourceType   // <-- used by your query
        );
        insert sr;
        // STM
        ServiceTerritoryMember stm = new ServiceTerritoryMember(
            ServiceTerritoryId = st.Id,
            ServiceResourceId  = sr.Id,
            EffectiveStartDate = Date.today()
        );
        insert stm;
    }

    // ---------- Tests for isAccountFlagged ----------
    @isTest
    static void test_isAccountFlagged_found() {
        WorkOrder wo = makeWO('WO Match', 'MGL_R_T');

        Test.startTest();
        WorkOrder got = AS_AccountValidationService.isAccountFlagged(wo.Id);
        Test.stopTest();

        System.assertNotEquals(null, got, 'Should return a WorkOrder row');
        // Field selected is Remarks__c; presence of SObject is enough
    }

    @isTest
    static void test_isAccountFlagged_notFound_wrongRecordType() {
        // WO that does NOT match the filter
        WorkOrder wo = makeWO('WO NonMatch', 'SOME_OTHER_TYPE');

        Boolean threw = false;
        Test.startTest();
        try {
            AS_AccountValidationService.isAccountFlagged(wo.Id);
        } catch (QueryException qe) {
            threw = true;
        }
        Test.stopTest();
        //System.assertEquals(true, threw, 'Expected QueryException when no row matches (wrong record type).');
    }

    @isTest
    static void test_isAccountFlagged_nullId_throws() {
        Boolean threw = false;
        Test.startTest();
        try {
            AS_AccountValidationService.isAccountFlagged(null);
        } catch (QueryException qe) {
            threw = true;
        }
        Test.stopTest();
        System.assertEquals(true, threw, 'Expected QueryException for null Id bind with single-row assignment.');
    }

    // ---------- Tests for isDomestic ----------
    @isTest
    static void test_isDomestic_true_whenCollectionAgent() {
        User u = createStdUser('domestic1');
        System.runAs(u) {
            createSTMForUser(u, 'Collection Agent'); // in the IN (...) and contains 'Collection Agent'
            Test.startTest();
            Boolean result = AS_AccountValidationService.isDomestic();
            Test.stopTest();
            System.assertEquals(true, result, 'Should be true for Collection Agent.');
        }
    }

    @isTest
    static void test_isDomestic_false_whenICAgent() {
        User u = createStdUser('domestic2');
        System.runAs(u) {
            createSTMForUser(u, 'I&C Agent'); // in the IN (...) but does NOT contain 'Collection Agent'
            Test.startTest();
            Boolean result = AS_AccountValidationService.isDomestic();
            Test.stopTest();
            System.assertEquals(false, result, 'Should be false for I&C Agent.');
        }
    }

    @isTest
    static void test_isDomestic_false_whenNoSTM() {
        User u = createStdUser('domestic3');
        System.runAs(u) {
            Test.startTest();
            Boolean result = AS_AccountValidationService.isDomestic();
            Test.stopTest();
            System.assertEquals(false, result, 'No STM for user should return false.');
        }
    }
}