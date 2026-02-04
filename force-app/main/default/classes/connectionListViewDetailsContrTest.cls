@isTest
private class connectionListViewDetailsContrTest {

    @testSetup
    static void createData() {
                OperatingHours oph = new OperatingHours(Name = 'Test Hours');
        insert oph;

        // Create Account
        Account acc = new Account(Name = 'Test Account', Category__c = 'Domestic', 
                                  Location__c = 'Loc1', Zone__c = 'Zone1', Representative_Company__c = 'RepCo');
        insert acc;

        // Create User
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser' + System.currentTimeMillis() + '@example.com',
            Username = 'testuser' + System.currentTimeMillis() + '@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert u;

        // WorkTypes for coverage
        insert new WorkType(Name = 'Riser Maintenance', EstimatedDuration = 60, ShouldAutoCreateSvcAppt = true);
        insert new WorkType(Name = 'Riser Replacement', EstimatedDuration = 45, ShouldAutoCreateSvcAppt = true);
        insert new WorkType(Name = 'Riser Painting', EstimatedDuration = 30, ShouldAutoCreateSvcAppt = true);

        // Create Service Territory
        ServiceTerritory st = new ServiceTerritory(Name = 'Test Territory', IsActive = true, OperatingHoursId = oph.Id, Business_Partner_Category__c = 'Domestic');
        insert st;

        // Create initial WorkOrder
        WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            AccountId = acc.Id,
            Status = 'New',
            WorkTypeId = [SELECT Id FROM WorkType WHERE Name = 'Riser Maintenance' LIMIT 1].Id,
            RecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('MGL_Metering').getRecordTypeId(),
            StartDate = Date.today(),
            EndDate = Date.today()
        );
        insert wo;

        // ServiceAppointment
        ServiceAppointment sa = new ServiceAppointment(
            ParentRecordId = wo.Id,
            Status = 'Scheduled',
            SchedStartTime = System.now().addMinutes(5),
            SchedEndTime = System.now().addMinutes(35),
            ServiceTerritoryId = st.Id
        );
        insert sa;

        // ServiceResource + AssignedResource
        ServiceResource sr = new ServiceResource(Name = 'Test Resource', IsActive = true, RelatedRecordId = u.Id, Customer_Category__c = 'Domestic');
        insert sr;

        insert new ServiceTerritoryMember(
            ServiceResourceId = sr.Id,
            ServiceTerritoryId = st.Id,
            EffectiveStartDate = Date.today().addDays(-10),
            EffectiveEndDate = Date.today().addYears(1)
        );

        insert new AssignedResource(ServiceAppointmentId = sa.Id, ServiceResourceId = sr.Id);

        // Connection__c
        insert new Connection__c(Name = 'Test Connection');
    }
    
    @isTest
    static void testEmptyCase() {
        // Call with no matching data
         User u = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        Test.startTest();
        system.runAs(u){
        List<Connection__c> emptyResult = connectionListViewDetailsContr.getAppointmentByStatus('completed', null);
        }
        Test.stopTest();

    }
    @isTest
    static void testEmptyCase1() {
        // Call with no matching data
         User u = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        Test.startTest();
        system.runAs(u){
        List<Connection__c> emptyResult = connectionListViewDetailsContr.getAppointmentByStatus('incomplete', null);
        }
        Test.stopTest();

    }
    @isTest
    static void testEmptyCase2() {
        // Call with no matching data
         User u = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        Test.startTest();
        system.runAs(u){
        List<Connection__c> emptyResult = connectionListViewDetailsContr.getAppointmentByStatus('unattempted', null);
        }
        Test.stopTest();

    }
     @isTest
    static void testEmptyCase3() {
        // Call with no matching data
         User u = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        Test.startTest();
        system.runAs(u){
        List<Connection__c> emptyResult = connectionListViewDetailsContr.getAppointmentByStatus('total', null);
        }
        Test.stopTest();

    }
    @isTest
    static void testGetAppointmentByStatusAndWorkOrderTest() {
        // Call with no matching data
        Test.startTest();
        // Call the method with "completed" status
        List<Connection__c> conns = connectionListViewDetailsContr.getAppointmentByStatus('completed', 'Scheduled');
        Test.stopTest();

    }
    @isTest
    static void getWorkOrderIdFromSA() {
        // Call with no matching data
        ServiceAppointment sa = [SELECT Status, SchedStartTime, SchedEndTime FROM ServiceAppointment where Status = 'Scheduled' LIMIT 1];

        Test.startTest();
        // Call the method with "completed" status
        connectionListViewDetailsContr.getWorkOrderIdFromSA(sa.Id);
        Test.stopTest();

    }
    @isTest
    static void testServiceAppointmentWrapperWithAccount() {
        // Create Account with extra fields for wrapper coverage
        Account acc = new Account(
            Name = 'Wrapper Test Account',
            Building_name__c = 'Tower A',
            Street__c = 'Main St',
            Colony__c = 'Green Colony',
            Wing__c = 'B',
            Floor__c = '3',
            Flat__c = '301',
            Road_name__c = 'MG Road',
            BP_Number__c = 'BP123',
            FirstName__c = 'John',
            LastName__c = 'Doe'
        );
        insert acc;
        OperatingHours oph = new OperatingHours(Name = 'Test Hours');
        insert oph;
        // Create Service Territory
        ServiceTerritory st = new ServiceTerritory(Name = 'Test Territory2', IsActive = true, OperatingHoursId = oph.Id, Business_Partner_Category__c = 'Domestic');
        insert st;
                // Create initial WorkOrder
        WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            AccountId = acc.Id,
            Status = 'New',
            WorkTypeId = [SELECT Id FROM WorkType WHERE Name = 'Riser Maintenance' LIMIT 1].Id,
            RecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('MGL_Metering').getRecordTypeId(),
            StartDate = Date.today(),
            EndDate = Date.today()
        );
        insert wo;
        insert new WorkType(Name = 'Riser Maintenance', EstimatedDuration = 60, ShouldAutoCreateSvcAppt = true);
        ServiceAppointment se=[SELECT Id,Subject,Meter_Number__c,Visit_Status__c,Status,Account.Name,SchedStartTime,AccountId,Account.Building_name__c,
                               Account.Street__c,Account.BP_Number__c,Appointment_Type__c,Account.FirstName__c,Account.LastName__c,Account.Wing__c,Account.Colony__c,Account.Floor__c,Account.Flat__c,Account.Road_name__c FROM ServiceAppointment WHERE ParentRecordId=:wo.Id];

        // Call wrapper constructor
        connectionListViewDetailsContr.ServiceAppointmentWrapper wrap =
            new connectionListViewDetailsContr.ServiceAppointmentWrapper(se);
    }
}