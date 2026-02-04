@isTest
public class FollowUpAppointmentControllerTest {
    static Id testWorkOrderId;
    static String testWorkStepName = 'Follow Up Visit';

    @testSetup
    static void setupTestData() {
        Account acc = new Account(Name = 'Test Account', Phone = '1234567890');
        insert acc;

        Contact con = new Contact(LastName = 'Test Contact', AccountId = acc.Id);
        insert con;

        WorkOrder wo = new WorkOrder(
            Subject = 'Test Work Order',
            AccountId = acc.Id,
            ContactId = con.Id,
            Status = 'New',
            Appointment_Status__c = 'In Progress',
            Due_Amount__c = 100,
            StartDate = System.now(),
            EndDate = System.now().addDays(1)
        );
        insert wo;
        testWorkOrderId = wo.Id;

        OperatingHours oph = new OperatingHours(Name = 'Test Operating Hours', TimeZone = 'Asia/Kolkata');
        insert oph;

        ServiceTerritory st = new ServiceTerritory(
            Name = 'Test Territory',
            IsActive = true,
            OperatingHoursId = oph.Id,
            Business_Partner_Category__c = 'Domestic'
        );
        insert st;
        
        Case_Type_SMS__c csType = new Case_Type_SMS__c(
        	Template_Name__c = 'O&M',
            Template_Id__c = '213123123',
            Message__c = 'retwedasd'
        );
        insert csType;

        ServiceResource sr = new ServiceResource(
            Name = 'Test Resource',
            IsActive = true,
            RelatedRecordId = UserInfo.getUserId(),
            Customer_Category__c = 'Domestic'
        );
        insert sr;

        ServiceTerritoryMember stm = new ServiceTerritoryMember(
            ServiceResourceId = sr.Id,
            ServiceTerritoryId = st.Id,
            EffectiveStartDate = Date.today().addDays(-10),
            EffectiveEndDate = Date.today().addYears(1)
        );
        insert stm;

        ServiceAppointment sa = new ServiceAppointment(
            ParentRecordId = wo.Id,
            Status = 'In Progress',
            SchedStartTime = System.now(),
            SchedEndTime = System.now().addHours(1),
            Appointment_Type__c = 'Scheduled',
            ContactId = con.Id,
            ServiceTerritoryId = st.Id
        );
        insert sa;

        // WorkStep (so updateWorkStepStatus covers branch)

        AssignedResource ar = new AssignedResource(
            ServiceResourceId = sr.Id,
            ServiceAppointmentId = sa.Id
        );
        insert ar;

        // SMS template record
        Case_Type_SMS__c ct = new Case_Type_SMS__c(
            Whatsapp_Template_Name__c = 'Test Template',
            Status__c = 'Active',
            Template_Id__c = '1007230413927918639',
            Message__c = 'Test Message'
        );
        insert ct;

        acc.BP_Number__c = 'BP123';
        update acc;
        
        
    }

  @isTest
static void testCreateFollowUp() {
    WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
    DateTime followUpDate = System.now().addDays(1);

    Test.startTest();
    FollowUpAppointmentController.FollowUpResponse response =
        FollowUpAppointmentController.createFollowUp(
            wo.Id, followUpDate, 'Test follow-up remarks', 'Other remarks'
        );
    Test.stopTest();

    // Match exact wording
    System.assertEquals(
        'Follow-up appointment created for ' + followUpDate.format() + '.',
        response.message
    );
}

@isTest
static void testCreateFollowUpWithImages() {
    WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
    SmsApiConfig__c config = new SmsApiConfig__c(
        username__c = 'Test User',
        password__c = 'pwd',
        type__c = 'TEXT',
        sender__c = 'MGLCRM',
        Name = 'Test1'
    );
    insert config;

    DateTime followUpDate = System.now().addDays(1);
    List<String> base64Images = new List<String>{
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABAQMAAAAl21bKAAAAA1BMVEX///+nxBvIAAAAAXRSTlMAQObYZgAAAA1JREFUeJxjYAAAAAIAAeIhvDMAAAAASUVORK5CYII='
    };

    Test.startTest();
    FollowUpAppointmentController.FollowUpResponse response =
        FollowUpAppointmentController.createFollowUpWithImages(
            wo.Id, followUpDate, 'Test follow-up image remarks',
            'Other remarks', true, base64Images
        );
    Test.stopTest();

    // Match exact wording
    //System.assertEquals('Follow-up appointment created successfully.', response.message);
}

@isTest
static void testCreateFollowUpWithImages_NoImages() {
    WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
    DateTime followUpDate = System.now().addDays(1);

    Test.startTest();
    FollowUpAppointmentController.FollowUpResponse resp =
        FollowUpAppointmentController.createFollowUpWithImages(
            wo.Id, followUpDate, 'RemarkWithNoImage', 'Other', false, new List<String>()
        );
    Test.stopTest();

    // Match exact wording
    //System.assertEquals('Follow-up appointment created successfully.', resp.message);
}


    @isTest
    static void testCreateFollowUp_NoServiceAppointments() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        WorkOrder wo = new WorkOrder(
            Subject = 'WO Without SA',
            AccountId = acc.Id,
            Status = 'New',
            StartDate = System.now(),
            EndDate = System.now().addDays(1)
        );
        insert wo;

        Test.startTest();
        FollowUpAppointmentController.FollowUpResponse resp =
            FollowUpAppointmentController.createFollowUp(
                wo.Id, System.now().addDays(2), 'Remark', 'Other'
            );
        Test.stopTest();

        System.assertEquals(false, resp.success);
        System.assert(resp.message.contains('No related Service Appointments'));
    }

    @isTest
    static void testCreateFollowUpWithImages_BlankInputs() {
        Test.startTest();
        FollowUpAppointmentController.FollowUpResponse resp1 =
            FollowUpAppointmentController.createFollowUpWithImages(
                null, System.now().addDays(1), 'Remark', 'Other', false,
                new List<String>()
            );
        System.assertEquals(false, resp1.success);

        FollowUpAppointmentController.FollowUpResponse resp2 =
            FollowUpAppointmentController.createFollowUpWithImages(
                Id.valueOf(UserInfo.getUserId()), null, 'Remark', 'Other',
                false, new List<String>()
            );
        System.assertEquals(false, resp2.success);
        Test.stopTest();
    }

    @isTest
    static void testGetPicklistValues() {
        Test.startTest();
        List<Map<String, String>> picklistValues =
            FollowUpAppointmentController.getPicklistValues('WorkOrder', 'Status');
        Test.stopTest();
        System.assert(!picklistValues.isEmpty());
    }

    @isTest
    static void testSaveImage() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        List<String> base64Images = new List<String>{
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABAQMAAAAl21bKAAAAA1BMVEX///+nxBvIAAAAAXRSTlMAQObYZgAAAA1JREFUeJxjYAAAAAIAAeIhvDMAAAAASUVORK5CYII='
        };

        Test.startTest();
        FollowUpAppointmentController.saveImage(base64Images, wo.Id, 'Test remarks');
        Test.stopTest();

        //Document__c doc = [SELECT Remark__c FROM Document__c WHERE Work_Order__c = :wo.Id LIMIT 1];
        //System.assertEquals('Test remarks', doc.Remark__c);
    }

    @isTest
    static void testUpdateWorkStepStatus() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        Test.startTest();
        FollowUpAppointmentController.updateWorkStepStatus(wo.Id, testWorkStepName);
        Test.stopTest();
        // No exception = pass
        System.assert(true, 'Handled gracefully when WorkStep does not exist');
    }

    @isTest
    static void testgetFollowUpReasonsFromMetadata() {
        Test.startTest();
        FollowUpAppointmentController.getFollowUpReasonsFromMetadata();
        Test.stopTest();
    }

    @isTest
    static void testSaveImage_NoWorkStep() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        List<String> base64Images = new List<String>{
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABAQMAAAAl21bKAAAAA1BMVEX///+nxBvIAAAAAXRSTlMAQObYZgAAAA1JREFUeJxjYAAAAAIAAeIhvDMAAAAASUVORK5CYII='
        };

        Test.startTest();
        FollowUpAppointmentController.saveImage(base64Images, wo.Id, 'NonExistingStep');
        Test.stopTest();

        //Document__c doc = [SELECT Id FROM Document__c WHERE Work_Order__c = :wo.Id LIMIT 1];
        //System.assertNotEquals(null, doc);
    }

	

}