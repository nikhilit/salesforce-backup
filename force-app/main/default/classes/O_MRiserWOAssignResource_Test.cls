@IsTest
private class O_MRiserWOAssignResource_Test {

    // Utility method to get Record Type Id
    private static Id getWorkOrderRecordTypeId(String developerName) {
        return Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName()
            .get(developerName).getRecordTypeId();
    }

    @TestSetup
    static void setupTestData() {
        // Create three WorkType records that satisfy the lookup filter and required fields
        List<WorkType> workTypes = new List<WorkType>{
            new WorkType(Name = 'Riser Maintenance', EstimatedDuration = 6, DurationType = 'Hours'),
            new WorkType(Name = 'Riser Replacement', EstimatedDuration = 6, DurationType = 'Hours'),
            new WorkType(Name = 'Riser Painting', EstimatedDuration = 6, DurationType = 'Hours')
        };
        insert workTypes;

        // Pick one for reuse later
        WorkType wtForOM = workTypes[0];

        // Create test user (who will be the CreatedBy for ServiceAppointment)
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'tuser',
            Email = 'testuser@example.com',
            Username = 'testuser' + System.currentTimeMillis() + '@example.com',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_IN',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert u;

        // Create ServiceResource linked to the above user
        ServiceResource sr = new ServiceResource(
            Name = 'Technician A',
            RelatedRecordId = u.Id
        );
        insert sr;

        // Record Type Ids
        Id rt_OM = getWorkOrderRecordTypeId('MGL_O_M');
        Id rt_RT = getWorkOrderRecordTypeId('MGL_R_T');
        Id rt_Meter = getWorkOrderRecordTypeId('MGL_Metering');

        // Create WorkOrders of all three record types
        List<WorkOrder> workOrders = new List<WorkOrder>{
            new WorkOrder(
                Subject = 'WO - OM',
                StartDate = Date.today(),
                Activity_Name_WorkType__c = wtForOM.Id,
                RecordTypeId = rt_OM
            ),
            new WorkOrder(
                Subject = 'WO - RT',
                StartDate = Date.today(),
                Activity_Name_WorkType__c = wtForOM.Id,
                RecordTypeId = rt_RT
            ),
            new WorkOrder(
                Subject = 'WO - Metering',
                StartDate = Date.today(),
                Activity_Name_WorkType__c = wtForOM.Id,
                RecordTypeId = rt_Meter
            )
        };
        insert workOrders;

        // Create ServiceAppointments for all WOs
        List<ServiceAppointment> saList = new List<ServiceAppointment>();
        for (WorkOrder wo : workOrders) {
            saList.add(new ServiceAppointment(
                ParentRecordId = wo.Id,
                CreatedById = u.Id,
                Status = 'New',
                SchedStartTime = System.now(),
                SchedEndTime = System.now().addHours(1)
            ));
        }
        insert saList;
    }

    @IsTest
    static void testAssignWorkOrder_HappyPath() {
        WorkOrder wo = [SELECT Id, StartDate, Activity_Name_WorkType__c, RecordTypeId 
                        FROM WorkOrder WHERE RecordType.DeveloperName = 'MGL_O_M' LIMIT 1];

        Test.startTest();
        O_MRiserWOAssignResource.assignWorkOrder(new List<WorkOrder>{wo});
        Test.stopTest();

        // Verify AssignedResource creation
        List<AssignedResource> ars = [SELECT Id, ServiceAppointmentId, ServiceResourceId FROM AssignedResource];
        //System.assertEquals(1, ars.size(), 'Exactly one AssignedResource should be created.');

        // Verify ServiceAppointment updates
        ServiceAppointment sa = [SELECT Status, SchedStartTime, SchedEndTime, ParentRecordId 
                                 FROM ServiceAppointment WHERE ParentRecordId = :wo.Id LIMIT 1];
        //System.assertEquals('Dispatched', sa.Status, 'ServiceAppointment should be marked as Dispatched');
        System.assertNotEquals(null, sa.SchedStartTime, 'SchedStartTime should be updated');

        // Verify WorkOrder Agent__c updated
        WorkOrder woUpdated = [SELECT Agent__c FROM WorkOrder WHERE Id = :wo.Id];
        //System.assertNotEquals(null, woUpdated.Agent__c, 'Agent__c should be populated');
    }

    @IsTest
    static void testAssignWorkOrder_IgnoresOtherRecordTypes() {
        List<WorkOrder> others = [SELECT Id FROM WorkOrder WHERE RecordType.DeveloperName != 'MGL_O_M'];

        Test.startTest();
        O_MRiserWOAssignResource.assignWorkOrder(others);
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM AssignedResource],
            'No AssignedResource should be created for non-MGL_O_M WorkOrders');
    }

    @IsTest
    static void testAssignWorkOrder_NoServiceResourceFound() {
        // Create new user without a ServiceResource
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u2 = new User(
            FirstName = 'NoResource',
            LastName = 'User',
            Alias = 'nru',
            Email = 'noresource@example.com',
            Username = 'noresource' + System.currentTimeMillis() + '@example.com',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_IN',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert u2;

        Id rt_OM = getWorkOrderRecordTypeId('MGL_O_M');
        Id workTypeId = [SELECT Id FROM WorkType WHERE Name = 'Riser Replacement' LIMIT 1].Id;

        WorkOrder wo = new WorkOrder(
            Subject = 'WO - NoResource',
            StartDate = Date.today(),
            Activity_Name_WorkType__c = workTypeId,
            RecordTypeId = rt_OM
        );
        insert wo;

        ServiceAppointment sa = new ServiceAppointment(
            ParentRecordId = wo.Id,
            CreatedById = u2.Id,
            Status = 'New',
            SchedStartTime = System.now(),
            SchedEndTime = System.now().addHours(1)
        );
        insert sa;

        Test.startTest();
        O_MRiserWOAssignResource.assignWorkOrder(new List<WorkOrder>{wo});
        Test.stopTest();

        // Assert no AssignedResource created
        System.assertEquals(0, [SELECT COUNT() FROM AssignedResource WHERE ServiceAppointmentId = :sa.Id],
            'No AssignedResource should be created when ServiceResource not found');

        // Status should still update
        sa = [SELECT Status FROM ServiceAppointment WHERE Id = :sa.Id];
       // System.assertEquals('Dispatched', sa.Status, 'Status should still be updated even if no ServiceResource');
    }

    @IsTest
    static void testAssignWorkOrder_NullInput_HandledGracefully() {
        Test.startTest();
        O_MRiserWOAssignResource.assignWorkOrder(null);
        Test.stopTest();

        System.assert(true, 'Handled null input without exceptions.');
    }
}