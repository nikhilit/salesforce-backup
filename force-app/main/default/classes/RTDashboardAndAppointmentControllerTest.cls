@isTest
public class RTDashboardAndAppointmentControllerTest {
    static ServiceResource sr;
    static Account acc;
    static WorkOrder wo;
    static ServiceAppointment saCompleted;
    static ServiceAppointment saScheduled;

    @testSetup
    static void setupData() {
        Id testUserId = userInfo.getUserId();
        // Create Account
        acc = new Account(Name = 'Test Account',
		Phone = '9876543210',
            Secondary_Telephone__c = '1234567890',
            Account_Email__c = 'test@test.com',
            Account_Type__c = 'Business Account',
            Type = 'Customer',
            MRU_Code__c = 'MRU123',
            BP_Number__c = 'BP123',
            CA_Number__c = 'CA123',
            Building_name__c = 'Test Building',
            Street__c = 'Test Street',
            Colony__c = 'Test Colony',
            Wing__c = 'A',
            Floor__c = '1',
            Flat__c = '101',
            Road_name__c = 'Test Road',
            Portion__c = 'Left',
            BillingPostalCode = '123456',
            Location__c = 'Test Loc',
            Email_Id__c = 'acc@test.com');
        insert acc;
        
        String gsRecordTypeID = Schema.getGlobalDescribe().get('WorkOrder')
        .getDescribe().getRecordTypeInfosByDeveloperName().get('MGL_R_T').getRecordTypeId();
        // Create WorkOrder
        wo = new WorkOrder(
            Subject = 'Test WorkOrder',
            Status = 'New',
            AccountId = acc.Id,
			Due_Amount__c = 100,
            Amount_Received__c = 50,
            RecordTypeId = gsRecordTypeID
        );
        insert wo;
        
		// Create Portion
		Portion__c p = new portion__c(
           Name = 'Test Portion',
           Active__c = true
         );
         insert p;
        
		// Create Operating Hours
		  OperatingHours oh = new OperatingHours(
            Name = 'Test Hours'
        );
        insert oh;

        // Create Service territory
		ServiceTerritory st = new ServiceTerritory(
            Name = 'Test Territory',
            IsActive = true,
            Capacity__c = 5,
            Portion__c = p.Id,
            Business_Partner_Category__c = 'Domestic',
            OperatingHoursId = oh.Id,
            RecordTypeId = Schema.SObjectType.ServiceTerritory.getRecordTypeInfosByDeveloperName().get('Metering').getRecordTypeId()
        );
        insert st;

        // Create ServiceResource linked to User
        sr = new ServiceResource(
            Name = 'Test Resource',
            RelatedRecordId = testUserId,
            IsActive = true
        );
        insert sr;

		// Create Service Territory Member
		 ServiceTerritoryMember stm = new ServiceTerritoryMember(
            ServiceTerritoryId = st.Id,
            ServiceResourceId = sr.Id,
            EffectiveStartDate = Date.today().addDays(-1),
            EffectiveEndDate = Date.today().addDays(365)
        );
        insert stm;

        // Create ServiceAppointments
        saCompleted = new ServiceAppointment(
            Subject = 'Completed Appointment',
            Status = 'Completed',
            ParentRecordId = wo.Id,
            SchedStartTime = Date.today().addDays(-1),
            SchedEndTime = Date.today(),
            Appointment_Type__c = 'Scheduled'
        );
        insert saCompleted;

        saScheduled = new ServiceAppointment(
            Subject = 'Scheduled Appointment',
            Status = 'Scheduled',
            ParentRecordId = wo.Id,
            SchedStartTime = Date.today().addDays(-1),
            SchedEndTime = Date.today(),
            Appointment_Type__c = 'Follow Up'
        );
        insert saScheduled;

        // Assign them to ServiceResource
        List<AssignedResource> ars = new List<AssignedResource>{
            new AssignedResource(ServiceAppointmentId = saCompleted.Id, ServiceResourceId = sr.Id),
            new AssignedResource(ServiceAppointmentId = saScheduled.Id, ServiceResourceId = sr.Id)
        };
        insert ars;

    }

   @isTest
    static void testGetKPIs() {
		List<ServiceResource> sr = [SELECT Id, Name, RelatedRecordId, IsActive FROM ServiceResource];
		//List<AssignedResource> ar = [SELECT Id, ServiceAppointmentId, ServiceResourceId FROM AssignedResource];
		//List<ServiceAppointment> appointments  = [SELECT Id, Subject, Status, ParentRecordId, SchedStartTime, SchedEndTime, Appointment_Type__c FROM ServiceAppointment];
		  List<ServiceAppointment> validAppointments = [SELECT Id, ParentRecordId FROM ServiceAppointment WHERE Id IN (SELECT ServiceAppointmentId FROM AssignedResource WHERE ServiceResourceId = :sr[0].Id)];
        Test.startTest();
            Map<String, Integer> result = RTDashboardController.getKPIs();
            System.assert(result.containsKey('total'), 'Total KPI should be present');
            System.assert(result.get('total') > 0, 'Should have appointments counted');
        Test.stopTest();
    }


    @isTest
    static void testGetCountByMetadataMatch() {
        List<ServiceResource> sr = [SELECT Id, Name, RelatedRecordId, IsActive FROM ServiceResource];
        List<AssignedResource> ar = [SELECT Id, ServiceAppointmentId, ServiceResourceId FROM AssignedResource];
        Test.startTest();
        List<RTDashboardController.DataWrapper> data = RTDashboardController.getCountByMetadataMatch();
        System.assertNotEquals(null, data, 'Should return empty or default list');
        Test.stopTest();
    }

      @isTest
    static void testGetPaymentSummary() {
        List<ServiceResource> sr = [SELECT Id, Name, RelatedRecordId, IsActive FROM ServiceResource];
        List<AssignedResource> ar = [SELECT Id, ServiceAppointmentId, ServiceResourceId FROM AssignedResource];
        List<ServiceAppointment> sa = [SELECT Id, ParentRecordId FROM ServiceAppointment];
        List<WorkOrder> wo = [SELECT Id, Due_Amount__c, Status, Subject, AccountId, Amount_Received__c FROM WorkOrder];
        Test.startTest();
            RTDashboardController.PaymentSummary ps = RTDashboardController.getPaymentSummary();
            System.assertNotEquals(null, ps, 'PaymentSummary should not be null');
            System.assertEquals(50, ps.totalAmountReceived, 'Stub data => 50 received');
        Test.stopTest();
    } 

    @isTest
    static void testGetFlatAppointmentsByStatus(){
         List<ServiceResource> sr = [SELECT Id, Name, RelatedRecordId, IsActive FROM ServiceResource];
         List<AssignedResource> ar = [SELECT Id, ServiceAppointmentId, ServiceResourceId FROM AssignedResource];
         List<ServiceAppointment> sa = [SELECT Id, ParentRecordId FROM ServiceAppointment];
         Test.startTest();
         RtAppointmentListViewController.getFlatAppointmentsByStatus('Scheduled', 'Follow Up');
         Test.StopTest();
    }
    
    @isTest
    static void testGetFlatAppointmentsByStatusUnattemp(){
         List<ServiceResource> sr = [SELECT Id, Name, RelatedRecordId, IsActive FROM ServiceResource];
         List<AssignedResource> ar = [SELECT Id, ServiceAppointmentId, ServiceResourceId FROM AssignedResource];
         List<ServiceAppointment> sa = [SELECT Id, ParentRecordId FROM ServiceAppointment];
         Test.startTest();
         RtAppointmentListViewController.getAppointmentsByStatus('Scheduled', 'In Progress');
         Test.StopTest();
    }

      @isTest
    static void testGetAppointmentsByStatus(){
         List<ServiceResource> sr = [SELECT Id, Name, RelatedRecordId, IsActive FROM ServiceResource];
         List<AssignedResource> ar = [SELECT Id, ServiceAppointmentId, ServiceResourceId FROM AssignedResource];
         List<ServiceAppointment> sa = [SELECT Id, ParentRecordId FROM ServiceAppointment];
         Test.startTest();
         RtAppointmentListViewController.getAppointmentsByStatus('Scheduled', 'Follow Up');
         Test.StopTest();
    }
    
    @isTest
    static void testgetWorkOrderIdFromSA(){
         ServiceAppointment sa = [SELECT Id, ParentRecordId FROM ServiceAppointment LIMIT 1]; 
         List<WorkOrder> wo = [SELECT Id FROM WorkOrder LIMIT 1];
         Test.startTest();
         RtAppointmentListViewController.getWorkOrderIdFromSA(sa.Id);
         Test.StopTest();
    }
}