@IsTest
public class checkCustomerAvalibilityIPDContrTest {

    @testSetup
    static void setupTestData() {

        // Profile
        Profile p = [SELECT Id FROM Profile LIMIT 1];

        // User
        User u = new User(
            FirstName = 'Test',
            LastName = 'Agent',
            Email = 'agent@test.com',
            Username = 'agent' + System.currentTimeMillis() + '@test.com',
            Alias = 'tagn',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_IN',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert u;

        // Service Resource
        ServiceResource sr = new ServiceResource(
            Name = 'Test SR',
            RelatedRecordId = userInfo.getUserId(),
            IsActive = true
        );
        insert sr;

        // WorkType
       WorkType wt = new WorkType(
            Name = 'Individual Permanent Disconnection',
           EstimatedDuration = 60
        );
       insert wt;
      // WorkType wt = [SELECT Id FROM WorkType where Name ='Individual Permanent Disconnection'];

        // RecordType
        RecordType rt = [
            SELECT Id FROM RecordType
            WHERE SObjectType = 'WorkOrder'and DeveloperName='TBT'
            LIMIT 1
        ];

        // WorkOrder (matches controller query)
        WorkOrder wo = new WorkOrder(
            Subject = 'Test WorkOrder',
            Status = 'New',
            WorkTypeId = wt.Id,
            RecordTypeId = rt.Id,
            Agent__c = sr.Id,
            Approval_Status__c = 'Pending'
        );
        insert wo;
    }

    // ---------------------------------------------------
    // Cover getWOrderWType
    // ---------------------------------------------------
    @IsTest
    static void testGetWOrderWType() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        Test.startTest();
        String result =
            checkCustomerAvalibilityIPDContr.getWOrderWType(wo.Id);
        Test.stopTest();

        System.assertNotEquals('Error', result);
    }
@IsTest
static void testGetWOrderWType_Exception() {

    // Dynamically generate a valid but non-existing WorkOrder Id
    String woPrefix = Schema.SObjectType.WorkOrder.getKeyPrefix();
    Id fakeWorkOrderId = (Id)(woPrefix + '000000000000AAA');

    Test.startTest();
    checkCustomerAvalibilityIPDContr.getWOrderWType(fakeWorkOrderId);
    Test.stopTest();
}

    // ---------------------------------------------------
    // Cover getApprovalStatus TRY block
    // ---------------------------------------------------
    @IsTest
    static void testGetApprovalStatus() {

        User u = [SELECT Id, Profile.Name FROM User LIMIT 1];

        System.runAs(u) {
            Test.startTest();
            checkCustomerAvalibilityIPDContr.CheckInControllerWrapper result =
                checkCustomerAvalibilityIPDContr.getApprovalStatus();
            Test.stopTest();

        }
    }

    // ---------------------------------------------------
    // Explicit Wrapper Coverage
    // ---------------------------------------------------
    @IsTest
    static void testCheckInControllerWrapper() {

        WorkOrder wo = new WorkOrder(
            Subject = 'Wrapper Test',
            Status = 'New'
        );

        checkCustomerAvalibilityIPDContr.CheckInControllerWrapper wrapper =
            new checkCustomerAvalibilityIPDContr.CheckInControllerWrapper();

        wrapper.documentRecordDetail = wo;
        wrapper.profileName = 'Test Profile';

        System.assertEquals(wo, wrapper.documentRecordDetail);
        System.assertEquals('Test Profile', wrapper.profileName);
    }

    // ---------------------------------------------------
    // Existing method coverage
    // ---------------------------------------------------
    @IsTest
    static void testUpdateWorkOrder() {

        WorkOrder wo =
            [SELECT Id FROM WorkOrder LIMIT 1];

        Test.startTest();
        checkCustomerAvalibilityIPDContr.updateWorkOrder(
            wo.Id, 'Yes'
        );
        Test.stopTest();
    }

    @IsTest
    static void testCheckWorkStepCheckin() {

        WorkOrder wo =
            [SELECT Id FROM WorkOrder LIMIT 1];

        Test.startTest();
        checkCustomerAvalibilityIPDContr.checkWorkStepCheckin(wo.Id);
        Test.stopTest();
    }
}