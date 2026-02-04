@IsTest
public class serviceAppointmentsAddressMap_Test {

    @TestSetup
    static void setupTestData() {
        // Create test User
        User u = [SELECT Id FROM User LIMIT 1];
OperatingHours oph = new OperatingHours(Name = 'Test Operating Hours', TimeZone = 'Asia/Kolkata');
        insert oph;
        // Create Service Territory
    ServiceTerritory st = new ServiceTerritory(
        Name = 'Test Territory',
        OperatingHoursId = oph.Id,
        IsActive=true
    );
    insert st;

    // Create ServiceResource for User
    ServiceResource sr = new ServiceResource(
        Name = 'Test Resource',
        RelatedRecordId = UserInfo.getUserId(),
        Customer_Category__c = 'Domestic',
        IsActive=true
    );
    insert sr;

    // Create ServiceTerritoryMember linking Resource to Territory
    ServiceTerritoryMember stm = new ServiceTerritoryMember(
        ServiceResourceId = sr.Id,
            ServiceTerritoryId = st.Id,
        EffectiveStartDate  = Date.today()
    );
    insert stm;

        // Create Accounts
        Account acc1 = new Account(
            Name = 'Test Account 1',
            Building_name__c = 'Building A',
            Street__c = 'Street A',
            City__c = 'City A',
            Postal_Code__c = '12345'
        );
        Account acc2 = new Account(
            Name = 'Test Account 2'
        );
        insert new List<Account>{acc1, acc2};

        // Create WorkOrders
        RecordType rt = [SELECT Id FROM RecordType WHERE DeveloperName='MGL_Metering' AND SobjectType='WorkOrder' LIMIT 1];
        WorkOrder wo1 = new WorkOrder(
            RecordTypeId = rt.Id,
            Status = 'New',
            Subject = 'WO1',
            AccountId = acc1.Id
        );
        insert wo1;

        // Create ServiceAppointments
        ServiceAppointment sa1 = new ServiceAppointment(
            ParentRecordId = wo1.Id,
            Status = 'Completed',
            Subject = 'SA1',
            SchedStartTime = System.now().addHours(-1),
            SchedEndTime = System.now().addHours(1),
            Appointment_Type__c = 'Scheduled'
        );
        ServiceAppointment sa2 = new ServiceAppointment(
            ParentRecordId = wo1.Id,
            Status = 'In Progress',
            Subject = 'SA2',
            SchedStartTime = System.now().addHours(-1),
            SchedEndTime = System.now().addHours(1),
            Appointment_Type__c = 'Ad-Hoc'
        );
        insert new List<ServiceAppointment>{sa1};

        // Assign resources
        AssignedResource ar1 = new AssignedResource(
            ServiceResourceId = sr.Id,
            ServiceAppointmentId = sa1.Id
        );
        AssignedResource ar2 = new AssignedResource(
            ServiceResourceId = sr.Id,
            ServiceAppointmentId = sa2.Id
        );
        insert new List<AssignedResource>{ar1};
    }

    @IsTest
    static void testGetAppointmentsByStatus_AllStatuses() {
        Test.startTest();
        serviceAppointmentsAddressMapController.ReturnWrapper result = 
            serviceAppointmentsAddressMapController.getAppointmentsByStatus('','Scheduled');
        Test.stopTest();

    }

    @IsTest
    static void testGetAppointmentsByStatus_EdgeCases() {
        Test.startTest();
        // completed
        serviceAppointmentsAddressMapController.ReturnWrapper completedResult = 
            serviceAppointmentsAddressMapController.getAppointmentsByStatus('completed','Scheduled');
        // incomplete
        serviceAppointmentsAddressMapController.ReturnWrapper incompleteResult = 
            serviceAppointmentsAddressMapController.getAppointmentsByStatus('incomplete','Ad-Hoc');
        // unattempted
        serviceAppointmentsAddressMapController.ReturnWrapper unattemptedResult = 
            serviceAppointmentsAddressMapController.getAppointmentsByStatus('unattempted',null);
        // total
        serviceAppointmentsAddressMapController.ReturnWrapper totalResult = 
            serviceAppointmentsAddressMapController.getAppointmentsByStatus('total','Scheduled');
        Test.stopTest();

    }

    @IsTest
    static void testServiceAppointmentWrapperAndBuildAddress() {
        Account acc = [SELECT Id, Name, Building_name__c, Street__c FROM Account LIMIT 1];
        ServiceAppointment sa = [SELECT Id, Status, Subject, SchedStartTime,AccountId,Customer_Name__c,BP_Number__c,
            Account.Name, Account.Building_name__c,Account.City__c,Account.Postal_Code__c, Account.Street__c, Account.Colony__c,
            Account.Wing__c, Account.Floor__c, Account.Flat__c, Account.Road_name__c, Meter_Number__c,Account.Plot__c,
            Appointment_Type__c,Account.Phone__c,Account.Customer_Contact_no__c,Account.PersonHomePhone,Account.Landmark__c,
            Account.Secondary_Telephone__c,Account.Secondary_Phone__c,Account.Location__c,Account.Zone__c,Account.Representative_Company__c  FROM ServiceAppointment LIMIT 1];
        serviceAppointmentsAddressMapController.ServiceAppointmentWrapper wrapper = new serviceAppointmentsAddressMapController.ServiceAppointmentWrapper(sa);

        String fullAddress = serviceAppointmentsAddressMapController.buildFullAddress('Building A','Landmark','Road','Location','City','12345');
        
    }

    @IsTest
    static void testGetWorkOrderIdFromSA() {
        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment LIMIT 1];
        Test.startTest();
        Id woId = serviceAppointmentsAddressMapController.getWorkOrderIdFromSA(sa.Id);
        Test.stopTest();

    }

    @IsTest
    static void testGetAppointments_AllTypes() {
        Test.startTest();
        serviceAppointmentsAddressMapController.ReturnWrapper result = 
            serviceAppointmentsAddressMapController.getAppointments('completed','Ad-Hoc');
        Test.stopTest();

    }
}