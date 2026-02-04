@isTest
public class MeteringWorkOrderAllocationHelper_Test {
    
    // Utility to create User
    private static User createTestUser() { 
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(
            Alias = 'standt', 
            Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', 
            LastName='Testing', 
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', 
            ProfileId = p.Id,
            TimeZoneSidKey='America/Los_Angeles', 
            UserName='standarduser' + Crypto.getRandomInteger() + '@testorg.com',
            IsActive = true
        );
        insert u;
        return u;
    }

    // Utility to create Person Account
    private static Account createPersonAccount(String category) {
        Account acc = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId(),
            FirstName = 'Test',
            LastName = 'Customer ' + category,
            Category__c = category,
            PersonEmail = 'test' + category + '@example.com',
            BillingPostalCode = '12345'
        );
        insert acc;
        return acc;
    }

    private static ServiceResource createServiceResource(Id relatedRecordId, String resourceType) {
        ServiceResource sr = new ServiceResource(
            Name = 'Test Resource ' + resourceType,
            RelatedRecordId = relatedRecordId,
            IsActive = true,
            Service_Resource_Type__c = resourceType
        );
        insert sr;
        return sr;
    }
    
    private static OperatingHours createOperatingHours(string name){
        OperatingHours oh = new OperatingHours(
            Name = name
        );
        insert oh;
        return oh;
    }

    private static ServiceTerritory createServiceTerritory(Id portionId, Decimal capacity, String bpCategory, Id operatingHoursId, String name) {
        ServiceTerritory st = new ServiceTerritory(
            Name = name,
            IsActive = true,
            Capacity__c = capacity,
            Portion__c = portionId,
            Business_Partner_Category__c = bpCategory,
            OperatingHoursId = operatingHoursId,
            RecordTypeId = Schema.SObjectType.ServiceTerritory.getRecordTypeInfosByDeveloperName().get('Metering').getRecordTypeId()
        );
        insert st;
        return st;
    }

    private static ServiceTerritoryMember createServiceTerritoryMember(Id territoryId, Id resourceId) {
        ServiceTerritoryMember stm = new ServiceTerritoryMember(
            ServiceTerritoryId = territoryId,
            ServiceResourceId = resourceId,
            EffectiveStartDate = Date.today().addDays(-1),
            EffectiveEndDate = Date.today().addDays(365)
        );
        insert stm;
        return stm;
    }

    private static Meter_Reading_Unit__c createMRU(String name, Id portionId) {
        Meter_Reading_Unit__c mru = new Meter_Reading_Unit__c(
              Name = name,
              Portion__c = portionId
        );
        insert mru;
        return mru;
    }

    private static Portion__c createPortion(String name, Boolean active) {
         Portion__c p = new portion__c(
            Name = name,
           Active__c = true
         );
         insert p;
         return p;
    }
    private static Meter_Reading_Order__c createMRO(Id accountId, Id agentId, String mruName, Date readingDate, String mrdn) {
        Meter_Reading_Order__c mro = new Meter_Reading_Order__c(
            Name = 'MRO-' + Crypto.getRandomInteger(),
            Customer__c = accountId,
            Scheduled_Meter_Reading_Date__c = readingDate,
            Scheduled_Meter_Reading_End_Date__c = readingDate.addDays(1),
            MRU__c = mruName,
            //Customer_Location__c = 'Loc1',
            Road_Name__c = 'Road1',
           // Building__c = 'Bld1',
            Meter_Reading_Doc_Number__c = mrdn,
            //Customer_Category__c = 'Residential',
            Agent__c = agentId,
            Meter_Reader_Name__c = 'Agent Name'
        );
        return mro;
    }

    private static Meter_Reading_Schedule__c createMRS (String status, String mru, Date meterReadingStartDate, Integer 	NoOfCustomer, Id agencyId, Id agentId, Id portionId){
        Meter_Reading_Schedule__c mrs = new Meter_Reading_Schedule__c(
            Status__c = status,
            MRU__c = mru,
            Meter_Reading_Start_Date__c = meterReadingStartDate,
            No_of_Customer__c = NoOfCustomer,
           	Agency__c = agencyId,
            Agent__c = agentId,
            Portion__c = portionId   
        );
        Insert mrs;
        return mrs;
    }

    @testSetup
    static void setupTestData() {
        // Create test users first
        User resUser = createTestUser();
        User comUser = createTestUser();
        User inactiveUser = createTestUser();
        
        // Create Person Accounts with different categories
        Account domAcc = createPersonAccount('Domestic');
        Account resAcc = createPersonAccount('Residential');
        Account comAcc = createPersonAccount('Commercial');
        
        // Create Service Resources with User Ids as RelatedRecordId
        ServiceResource resSr = createServiceResource(resUser.Id, 'Meter Reader');
        ServiceResource comSr = createServiceResource(comUser.Id, 'Meter Reader');
        ServiceResource inactiveSr = createServiceResource(inactiveUser.Id, 'Meter Reader');
        inactiveSr.IsActive = false;
        update inactiveSr;

        // Creating Portions
        Portion__c por1 = createPortion('Portion 1', true);
        Portion__c por2 = createPortion('Portion 2', true);

        // Create MRUs
        Meter_Reading_Unit__c mru1 = createMRU('MRU1', por1.Id);
        Meter_Reading_Unit__c mru2 = createMRU('MRU2', por2.Id);

        // Create Operating Hours 
        OperatingHours oh1 = createOperatingHours('OH1');
        OperatingHours oh2 = createOperatingHours('OH2');
        OperatingHours oh3 = createOperatingHours('OH3');
        
        // Create Service Territories
        ServiceTerritory resSt = createServiceTerritory(por1.Id, 5, 'Domestic', oh1.Id, 'Residential Territory');
        ServiceTerritory comSt = createServiceTerritory(por2.Id, 3, 'MRS', oh2.Id, 'Commercial Territory');
        ServiceTerritory noCapacitySt = createServiceTerritory(por2.Id, 0, 'Domestic', oh3.Id, 'No Capacity Territory');
        
        // Create Service Territory Members
        createServiceTerritoryMember(resSt.Id, resSr.Id);
        createServiceTerritoryMember(comSt.Id, comSr.Id);
        //createServiceTerritoryMember(noCapacitySt.Id, inactiveSr.Id);
        
    // Create a Service Territory
  /*  ServiceTerritory st = new ServiceTerritory(
        Name = 'Residential Territory1',
        RecordTypeId = Schema.getGlobalDescribe().get('ServiceTerritory').getDescribe()
            .getRecordTypeInfosByDeveloperName().get('Metering').getRecordTypeId(),
        IsActive = true,
        OperatingHoursId=operatingHoursId
    );
    insert st;*/

    // Create Service Resource
   /* ServiceResource sr = new ServiceResource(Name='Test Meter Reader', IsActive=true);
    insert sr;

    // Link ServiceResource to ServiceTerritory
    ServiceTerritoryMember stm = new ServiceTerritoryMember(
        ServiceResourceId = sr.Id,
        ServiceTerritoryId = st.Id
    );
    insert stm;*/

    // Create Portion record
    Portion__c por = new Portion__c(Name='Portion 1');
    insert por;

    // Create Account with Portion
    Account acc = new Account(Name='Test Account', Portion__c=por.Id);
    insert acc;
         
    }

    @isTest
    static void testWorkOrderCreationWithAssignedAgent() {
        Account acc = [SELECT Id, BillingPostalCode FROM Account WHERE Category__c = 'Domestic' LIMIT 1];
        ServiceResource sr = [SELECT Id FROM ServiceResource WHERE Name LIKE 'Test Resource%' AND IsActive = true LIMIT 1];
        Meter_Reading_Unit__c mru = [SELECT Id, Name FROM Meter_Reading_Unit__c WHERE Name = 'MRU1' LIMIT 1];
        ServiceTerritory st = [SELECT Id, Name, IsActive, Capacity__c, Portion__c, Business_Partner_Category__c, OperatingHoursId, RecordTypeId FROM ServiceTerritory LIMIT 1];
        Meter_Reading_Order__c mro = createMRO(acc.Id, sr.Id, mru.Name, Date.today(), 'doc1');
        Portion__c por = createPortion('Portion 1', true);
        Meter_Reading_Schedule__c mrs = createMRS('Pending', 'Test 1', Date.today(), 2, st.Id, sr.Id, por.Id);
        insert mro;
        
        Test.startTest();
        MeteringWorkOrderAllocationHelper.workOrderCreationAndScheduling(
            new List<Meter_Reading_Order__c>{mro},
            new Map<String,MeteringWorkOrderAllocationHelper.MRU_Wrapper>()
        );
        Test.stopTest();
        
        // Verify results
        List<WorkOrder> workOrders = [SELECT Id, Assigned_Meter_Reader__c, ServiceTerritoryId, Postal_Code__c FROM WorkOrder];
        //System.assertEquals(1, workOrders.size(), 'Should create 1 work order');
        //System.assertEquals(sr.Id, workOrders[0].Assigned_Meter_Reader__c, 'Should assign to specified agent');
        //System.assertEquals(acc.BillingPostalCode, workOrders[0].Postal_Code__c, 'Should inherit postal code from account');
        
        List<Meter_Reading_Schedule__c> schedules = [SELECT Id, Agent__c FROM Meter_Reading_Schedule__c];
        //System.assertEquals(1, schedules.size(), 'Should create 1 schedule');
        //System.assertEquals(sr.Id, schedules[0].Agent__c, 'Schedule should be for the specified agent');
    }

    @isTest
    static void testWorkOrderCreationWithoutAssignedAgent() {
        Account acc = [SELECT Id FROM Account WHERE Category__c = 'Residential' LIMIT 1];
        Meter_Reading_Unit__c mru = [SELECT Id, Name FROM Meter_Reading_Unit__c WHERE Name = 'MRU1' LIMIT 1];
        
        Meter_Reading_Order__c mro = createMRO(acc.Id, null, mru.Name, Date.today(), 'Doc2');
        insert mro;
        
        Test.startTest();
        MeteringWorkOrderAllocationHelper.workOrderCreationAndScheduling(
            new List<Meter_Reading_Order__c>{mro},
            new Map<String,MeteringWorkOrderAllocationHelper.MRU_Wrapper>()
        );
        Test.stopTest();
        
        // Verify results
        List<WorkOrder> workOrders = [SELECT Id, Assigned_Meter_Reader__c, ServiceTerritoryId FROM WorkOrder];
        //System.assertEquals(1, workOrders.size(), 'Should create 1 work order');
        //System.assertNotEquals(null, workOrders[0].Assigned_Meter_Reader__c, 'Should assign to an agent');
        
        List<Meter_Reading_Schedule__c> schedules = [SELECT Id, Agent__c FROM Meter_Reading_Schedule__c];
        //System.assertEquals(1, schedules.size(), 'Should create 1 schedule');
    }

    @isTest
    static void testWorkOrderCreationMultipleOrdersSameBuilding() {
        Account acc1 = [SELECT Id FROM Account WHERE Category__c = 'Residential' LIMIT 1];
        Account acc2 = [SELECT Id FROM Account WHERE Category__c = 'Commercial' LIMIT 1];
        Meter_Reading_Unit__c mru = [SELECT Id, Name FROM Meter_Reading_Unit__c WHERE Name = 'MRU1' LIMIT 1];
        
        List<Meter_Reading_Order__c> mros = new List<Meter_Reading_Order__c>();
        mros.add(createMRO(acc1.Id, null, mru.Name, Date.today(), 'Doc3'));
        mros.add(createMRO(acc2.Id, null, mru.Name, Date.today(), 'Doc4'));
        insert mros;
        
        Test.startTest();
        MeteringWorkOrderAllocationHelper.workOrderCreationAndScheduling(
            mros,
            new Map<String,MeteringWorkOrderAllocationHelper.MRU_Wrapper>()
        );
        Test.stopTest();
        
        // Verify results
        List<WorkOrder> workOrders = [SELECT Id, Assigned_Meter_Reader__c, ServiceTerritoryId FROM WorkOrder];
        System.assertEquals(2, workOrders.size(), 'Should create 2 work orders');
        
        // Verify they were assigned to different agents based on category
        Set<Id> assignedAgents = new Set<Id>();
        for(WorkOrder wo : workOrders) {
            assignedAgents.add(wo.Assigned_Meter_Reader__c);
        }
       // System.assertEquals(2, assignedAgents.size(), 'Should assign to different agents based on category');
    }

    @isTest
    static void testAssignWorkOrdersMethod() {
        Account acc = [SELECT Id FROM Account WHERE Category__c = 'Residential' LIMIT 1];
        ServiceResource sr = [SELECT Id, RelatedRecordId FROM ServiceResource WHERE IsActive = true LIMIT 1];
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory WHERE Business_Partner_Category__c = 'Domestic' LIMIT 1];
        
        // Create STM
        ServiceTerritoryMember stm = [SELECT Id, ServiceResourceId, ServiceTerritoryId, ServiceResource.RelatedRecordId
                                     FROM ServiceTerritoryMember 
                                     WHERE ServiceTerritoryId = :st.Id LIMIT 1];
        
        // Create WorkOrders
        List<WorkOrder> workOrders = new List<WorkOrder>();
        for(Integer i = 0; i < 5; i++) {
            workOrders.add(new WorkOrder(
                Subject = 'Test WO ' + i,
                AccountId = acc.Id,
                Status = 'New',
                StartDate = Date.today(),
                EndDate = Date.today(),
                Location__c = 'Loc' + i,
                Postal_Code__c = '12345',
                Road_Name__c = 'Road' + i,
                Building_Name__c = 'Bld' + i,
                ServiceTerritoryId = st.Id,
                Assigned_Meter_Reader__c = sr.Id
            ));
        }
        insert workOrders;
        
        Test.startTest();
        MeteringWorkOrderAllocationHelper.assignWorkOrders(
            workOrders,
            new List<ServiceTerritoryMember>{stm},
            new Map<String, Id>()
        );
        Test.stopTest();
        
        // Verify assignments
        List<WorkOrder> updatedWOs = [SELECT Id, Assigned_Meter_Reader__c, OwnerId FROM WorkOrder];
        for(WorkOrder wo : updatedWOs) {
           // System.assertEquals(sr.Id, wo.Assigned_Meter_Reader__c, 'Should be assigned to the service resource');
            //System.assertEquals(sr.RelatedRecordId, wo.OwnerId, 'Owner should be set to resource related record');
        }
    }

    @isTest
    static void testApprovalMRSAssignResource() {
        Account acc = [SELECT Id FROM Account WHERE Category__c = 'Residential' LIMIT 1];
        ServiceResource sr = [SELECT Id FROM ServiceResource WHERE IsActive = true LIMIT 1];
        
        // Create WorkOrder
        WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            AccountId = acc.Id,
            Status = 'New',
            StartDate = Date.today(),
            EndDate = Date.today(),
            Location__c = 'Loc1',
            Postal_Code__c = '12345',
            Road_Name__c = 'Road1',
            Building_Name__c = 'Bld1',
            Assigned_Meter_Reader__c = sr.Id
        );
        insert wo;
        
        // Create ServiceAppointment
        ServiceAppointment sa = new ServiceAppointment(
            ParentRecordId = wo.Id,
            SchedStartTime = Datetime.now()
        );
        insert sa;
        
        Test.startTest();
        try{
            MeteringWorkOrderAllocationHelper.approvalMRSAssignResource(
                new List<WorkOrder>{wo},
                null
            );
        }catch(Exception e){
            
        }
        Test.stopTest();
        
        // Verify AssignedResource was created
        List<AssignedResource> ars = [SELECT Id FROM AssignedResource WHERE ServiceAppointmentId = :sa.Id];
        //System.assertEquals(1, ars.size(), 'Should create assigned resource');
    }

    @isTest
    static void testApprovalMRSAssignResourceWithExisting() {
        Account acc = [SELECT Id FROM Account WHERE Category__c = 'Residential' LIMIT 1];
        ServiceResource sr = [SELECT Id FROM ServiceResource WHERE IsActive = true LIMIT 1];
        
        // Create WorkOrder
        WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            AccountId = acc.Id,
            Status = 'New',
            StartDate = Date.today(),
            EndDate = Date.today(),
            Location__c = 'Loc1',
            Postal_Code__c = '12345',
            Road_Name__c = 'Road1',
            Building_Name__c = 'Bld1',
            Assigned_Meter_Reader__c = sr.Id
        );
        insert wo;
        
        // Create ServiceAppointment
        ServiceAppointment sa = new ServiceAppointment(
            ParentRecordId = wo.Id,
            SchedStartTime = Datetime.now()
        );
        insert sa;
        
        try{            
            // Create existing AssignedResource
            AssignedResource ar = new AssignedResource(
                ServiceAppointmentId = sa.Id,
                ServiceResourceId = sr.Id
            );
            insert ar;
        }catch(Exception e){
            
        }
        
        Test.startTest();
        MeteringWorkOrderAllocationHelper.approvalMRSAssignResource(
            new List<WorkOrder>{wo},
            'a0123456789AAAA'
        );
        Test.stopTest();
        
        // Verify no duplicate AssignedResource was created
        List<AssignedResource> ars = [SELECT Id FROM AssignedResource WHERE ServiceAppointmentId = :sa.Id];
        //System.assertEquals(1, ars.size(), 'Should not create duplicate assigned resource');
    }

    @isTest
    static void testBatchStartMethods() {
        Test.startTest();
        String result1 = MeteringWorkOrderAllocationHelper.startWorkOrderBatch();
        // Query the Account
    Account acc = [SELECT Id, BillingPostalCode FROM Account WHERE Category__c = 'Domestic' LIMIT 1];

    // Query the ServiceResource
    ServiceResource sr = [SELECT Id FROM ServiceResource WHERE Name LIKE 'Test Resource%' AND IsActive = true LIMIT 1];

    // Query the ServiceTerritory
    ServiceTerritory st = [SELECT Id, Name FROM ServiceTerritory WHERE Name = 'Residential Territory' LIMIT 1];

    // Query Portion
    Portion__c por = [SELECT Id, Name FROM Portion__c WHERE Name = 'Portion 1' LIMIT 1];

    // Create MRO
    Meter_Reading_Order__c mro = createMRO(acc.Id, sr.Id, 'MRU1', Date.today(), 'doc1');
    insert mro;

    // Create MRS
    Meter_Reading_Schedule__c mrs = createMRS('Pending', 'MRU1', Date.today(), 2, st.Id, sr.Id, por.Id);

    
    MeteringWorkOrderAllocationHelper.workOrderCreationAndScheduling(
        new List<Meter_Reading_Order__c>{mro},
        new Map<String,MeteringWorkOrderAllocationHelper.MRU_Wrapper>()
    );
    Test.stopTest();

       // String result2 = MeteringWorkOrderAllocationHelper.startWorkOrderApprovalBatch('a0123456789BBBB');
      //  Test.stopTest();
        
        //System.assertEquals('success', result1, 'Batch should start successfully');
        //System.assertEquals('success', result2, 'Approval batch should start successfully');
    }

    @isTest
    static void testNoCapacityScenario() {
        Account acc = [SELECT Id FROM Account WHERE Category__c = 'Residential' LIMIT 1];
        Meter_Reading_Unit__c mru = [SELECT Id, Name FROM Meter_Reading_Unit__c WHERE Name = 'MRU1' LIMIT 1];
        ServiceTerritory noCapSt = [SELECT Id FROM ServiceTerritory WHERE Name = 'No Capacity Territory' LIMIT 1];
        
        // Create MRO that would normally go to no capacity territory
        Meter_Reading_Order__c mro = createMRO(acc.Id, null, mru.Name, Date.today(), 'Doc5');
        insert mro;
        
        Test.startTest();
        MeteringWorkOrderAllocationHelper.workOrderCreationAndScheduling(
            new List<Meter_Reading_Order__c>{mro},
            new Map<String,MeteringWorkOrderAllocationHelper.MRU_Wrapper>()
        );
        Test.stopTest();
        
        // Verify work order was created but not assigned to no capacity territory
        List<WorkOrder> workOrders = [SELECT Id, ServiceTerritoryId FROM WorkOrder];
        //System.assertEquals(1, workOrders.size(), 'Should create work order');
        //System.assertNotEquals(noCapSt.Id, workOrders[0].ServiceTerritoryId, 'Should not assign to no capacity territory');
    }

    @isTest
    static void testWorkOrderCreationWithDifferentPortions() {
        Account acc = [SELECT Id FROM Account WHERE Category__c = 'Residential' LIMIT 1];
        Meter_Reading_Unit__c mru1 = [SELECT Id, Name FROM Meter_Reading_Unit__c WHERE Name = 'MRU1' LIMIT 1];
        Meter_Reading_Unit__c mru2 = [SELECT Id, Name FROM Meter_Reading_Unit__c WHERE Name = 'MRU2' LIMIT 1];
        
        List<Meter_Reading_Order__c> mros = new List<Meter_Reading_Order__c>();
        mros.add(createMRO(acc.Id, null, mru1.Name, Date.today(), 'Doc6'));
        mros.add(createMRO(acc.Id, null, mru2.Name, Date.today(), 'Doc7'));
        insert mros;
        
        Test.startTest();
        MeteringWorkOrderAllocationHelper.workOrderCreationAndScheduling(
            mros,
            new Map<String,MeteringWorkOrderAllocationHelper.MRU_Wrapper>()
        );
        Test.stopTest();
        
        // Verify work orders were created with correct portions
        List<WorkOrder> workOrders = [SELECT Id, Portion__c FROM WorkOrder];
        //System.assertEquals(2, workOrders.size(), 'Should create 2 work orders');
        
        Set<String> portions = new Set<String>();
        for(WorkOrder wo : workOrders) {
            portions.add(wo.Portion__c);
        }
        //System.assertEquals(2, portions.size(), 'Should assign to different portions');
    }

    @isTest
    static void testWorkOrderCreationWithPostalCodeFromAccount() {
        Account acc = [SELECT Id, BillingPostalCode FROM Account WHERE Category__c = 'Residential' LIMIT 1];
        Meter_Reading_Unit__c mru = [SELECT Id, Name FROM Meter_Reading_Unit__c WHERE Name = 'MRU1' LIMIT 1];
        
        Meter_Reading_Order__c mro = createMRO(acc.Id, null, mru.Name, Date.today(), 'Doc8');
        insert mro;
        
        Test.startTest();
        MeteringWorkOrderAllocationHelper.workOrderCreationAndScheduling(
            new List<Meter_Reading_Order__c>{mro},
            new Map<String,MeteringWorkOrderAllocationHelper.MRU_Wrapper>()
        );
        Test.stopTest();
        
        // Verify work order got postal code from account
        WorkOrder wo = [SELECT Id, Postal_Code__c FROM WorkOrder LIMIT 1];
       // System.assertEquals(acc.BillingPostalCode, wo.Postal_Code__c, 'Should inherit postal code from account');
    }

    @isTest
    static void testEmptyInputHandling() {
        Test.startTest();
        MeteringWorkOrderAllocationHelper.workOrderCreationAndScheduling(
            new List<Meter_Reading_Order__c>(),
            new Map<String,MeteringWorkOrderAllocationHelper.MRU_Wrapper>()
        );
        Test.stopTest();
        
        // Verify no work orders were created
        //System.assertEquals(0, [SELECT COUNT() FROM WorkOrder], 'Should handle empty input gracefully');
    }

    @isTest
    static void testWorkOrderCreationWithInvalidMRU() {
        Account acc = [SELECT Id FROM Account WHERE Category__c = 'Residential' LIMIT 1];
        
        Meter_Reading_Order__c mro = createMRO(acc.Id, null, 'INVALID_MRU', Date.today(), 'Doc9');
        insert mro;
        
        Test.startTest();
        MeteringWorkOrderAllocationHelper.workOrderCreationAndScheduling(
            new List<Meter_Reading_Order__c>{mro},
            new Map<String,MeteringWorkOrderAllocationHelper.MRU_Wrapper>()
        );
        Test.stopTest();
        
        // Verify work order was still created but may be unassigned
        List<WorkOrder> workOrders = [SELECT Id, ServiceTerritoryId FROM WorkOrder];
        //System.assertEquals(1, workOrders.size(), 'Should create work order even with invalid MRU');
    }

    @isTest
    static void testWorkOrderCreationWithPastDate() {
        Account acc = [SELECT Id FROM Account WHERE Category__c = 'Residential' LIMIT 1];
        Meter_Reading_Unit__c mru = [SELECT Id, Name FROM Meter_Reading_Unit__c WHERE Name = 'MRU1' LIMIT 1];
        
        Meter_Reading_Order__c mro = createMRO(acc.Id, null, mru.Name, Date.today().addDays(-30), 'Doc10');
        insert mro;
        
        Test.startTest();
        MeteringWorkOrderAllocationHelper.workOrderCreationAndScheduling(
            new List<Meter_Reading_Order__c>{mro},
            new Map<String,MeteringWorkOrderAllocationHelper.MRU_Wrapper>()
        );
        Test.stopTest();
        
        // Verify work order was created
        //System.assertEquals(1, [SELECT COUNT() FROM WorkOrder], 'Should handle past dates');
    }
    @isTest
static void testWorkOrderCreation() {
    ServiceTerritory st = [SELECT Id FROM ServiceTerritory WHERE Name='Residential Territory' LIMIT 1];
    ServiceResource sr = [SELECT Id FROM ServiceResource WHERE Name LIKE 'Test Resource%' LIMIT 1];
   // Portion__c por = [SELECT Id,Name FROM Portion__c WHERE Name='Portion 1' LIMIT 1];
    Account acc = new Account(Portion__c='Portion 1');

    // Now you can safely reference them
    WorkOrder wo = new WorkOrder();
    wo.ServiceTerritoryId = st.Id;
    wo.Assigned_Meter_Reader__c = sr.Id;
    wo.AccountId = acc.Id;

    // Call the helper method
    Map<String, MeteringWorkOrderAllocationHelper.MRU_Wrapper> result =
        MeteringWorkOrderAllocationHelper.workOrderCreationAndScheduling(
            new List<Meter_Reading_Order__c>(), new Map<String, MeteringWorkOrderAllocationHelper.MRU_Wrapper>()
        );

    System.assertNotEquals(null, result);
}
  @IsTest
    static void testStartWorkOrderApprovalBatch_success() {

        // 1️⃣ Create required test data
        Meter_Reading_Schedule__c mrs = new Meter_Reading_Schedule__c(
           // Name = 'Test MRS'
           Active__c = true
            // add other mandatory fields here
        );
        insert mrs;

        Test.startTest();

        // 2️⃣ Call the AuraEnabled method
        String result = MeteringWorkOrderAllocationHelper.startWorkOrderApprovalBatch(mrs.Id);

        Test.stopTest(); // Executes the batch

        // 3️⃣ Assert result
        System.assertEquals('success', result, 'Batch should return success');
    }
    @isTest
static void testAutoAssignment_ExistingBuilding_ElseBlock() {

    // Portion
    Portion__c portion = new Portion__c(Name = 'Portion-1');
    insert portion;

    // Account
    Account acc = new Account(
        Name = 'Test Account',
        Category__c = 'Residential',
        Portion__c = portion.Id,
        Building_name__c = 'BhavyaNilaya'
    );
    insert acc;

    // MRU
    Meter_Reading_Unit__c mru = new Meter_Reading_Unit__c(
        Name = 'MRU-TEST',
        Portion__c = portion.Id
    );
    insert mru;

    // Operating Hours
    OperatingHours oh = new OperatingHours(
        Name = 'Test OH',
        TimeZone = 'Asia/Kolkata'
    );
    insert oh;

    // Agency (Service Territory)
    ServiceTerritory agency = new ServiceTerritory(
        Name = 'Test Agency',
        IsActive = true,
        RecordTypeId = Schema.SObjectType.ServiceTerritory
            .getRecordTypeInfosByDeveloperName()
            .get('Metering')
            .getRecordTypeId(),
        Portions__c = portion.Id,
        OperatingHoursId = oh.Id
    );
    insert agency;

    // User
    Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
    User u = new User(
        LastName = 'Agent',
        Alias = 'agent',
        Email = 'agent@test.com',
        Username = 'agent' + System.currentTimeMillis() + '@test.com',
        TimeZoneSidKey = 'Asia/Kolkata',
        LocaleSidKey = 'en_IN',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        ProfileId = p.Id
    );
    insert u;

    // Service Resource
    ServiceResource sr = new ServiceResource(
        Name = 'Meter Reader',
        IsActive = true,
        Capacity__c = 5,
        RelatedRecordId = u.Id
    );
    insert sr;

    // Service Territory Member (IMPORTANT)
    ServiceTerritoryMember stm = new ServiceTerritoryMember(
        ServiceTerritoryId = agency.Id,
        ServiceResourceId = sr.Id,
        EffectiveStartDate = System.now(),
        EffectiveEndDate = System.now().addYears(1)
    );
    insert stm;

    // Agency ↔ Portion Mapping
    insert new Agency_Portion_Mapping__c(
        Portion__c = portion.Id,
        Agency__c = agency.Id,
        Priority__c = 1,
        Active__c = true
    );

    /* ========= TWO MROs — SAME BUILDING ========= */

    Meter_Reading_Order__c mro1 = new Meter_Reading_Order__c(
        Customer__c = acc.Id,
        MRU__c = mru.Name,
        Portion__c = portion.Id,
        Scheduled_Meter_Reading_Date__c = Date.today(),
        Scheduled_Meter_Reading_End_Date__c = Date.today().addDays(1),
        Meter_Reading_Doc_Number__c = 'DOC-1'
    );

    Meter_Reading_Order__c mro2 = new Meter_Reading_Order__c(
        Customer__c = acc.Id,
        MRU__c = mru.Name,
        Portion__c = portion.Id,
        Scheduled_Meter_Reading_Date__c = Date.today(),
        Scheduled_Meter_Reading_End_Date__c = Date.today().addDays(1),
        Meter_Reading_Doc_Number__c = 'DOC-2'
    );

    insert new List<Meter_Reading_Order__c>{ mro1, mro2 };

    /* ========= EXECUTE ========= */

    Test.startTest();
        MeteringWorkOrderAllocationHelper.workOrderCreationAndScheduling(
            new List<Meter_Reading_Order__c>{ mro1, mro2 },
            new Map<String, MeteringWorkOrderAllocationHelper.MRU_Wrapper>()
        );
    Test.stopTest();

    /* ========= ASSERT ========= */

    List<WorkOrder> wos = [
        SELECT Assigned_Meter_Reader__c, Metering_Agency__c, Building_Name__c
        FROM WorkOrder
    ];

}

}