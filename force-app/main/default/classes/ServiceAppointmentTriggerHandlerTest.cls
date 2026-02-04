@isTest
private class ServiceAppointmentTriggerHandlerTest {

    @testSetup
    static void setupData() {
        Id recordTypeMeteringId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('MGL_Metering').getRecordTypeId();
        Id recordTypeRTId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('MGL_R_T').getRecordTypeId();
        Id srRecordTypeRTId = Schema.SObjectType.ServiceResource.getRecordTypeInfosByDeveloperName().get('MGL_R_T').getRecordTypeId();
        Id stRecordTypeRTId = Schema.SObjectType.ServiceTerritory.getRecordTypeInfosByDeveloperName().get('R_T').getRecordTypeId();
        
        OperatingHours oh = new OperatingHours(
            Name = 'Base Calendar'
        );
        insert oh;
        
        ServiceTerritory st = new ServiceTerritory(
        Name = 'Test Territory',
        RecordTypeId = stRecordTypeRTId,
        OperatingHoursId = oh.Id,
        IsActive = true);
        insert st;
        
        Contact contact = new Contact(LastName = 'Test Contact');
        insert contact;

        Account acc = new Account(Name = 'Test Account', BillingStreet = '123 Main St', BillingCity = 'City', BillingState = 'State',
                                  BillingPostalCode = '12345', BillingCountry = 'Country');
        insert acc;

        contact.AccountId = acc.Id;
        update contact;

       // ServiceTerritory territory = new ServiceTerritory(Name = 'Test Territory', OperatingHoursId = Test.getStandardOperatingHoursId());
      //  insert territory;

        ServiceResource sr = new ServiceResource(
            Name = 'Test Resource',
            IsActive = true,
            RelatedRecordId = UserInfo.getUserId(),
            RecordTypeId =srRecordTypeRTId);
        insert sr;
        
         ServiceTerritoryMember stm = new ServiceTerritoryMember(
            ServiceTerritoryId = st.Id,
            ServiceResourceId = sr.Id,
            EffectiveStartDate = Date.today().addDays(-1),
            EffectiveEndDate = Date.today().addDays(365)
        );
        insert stm;

        WorkOrder wo1 = new WorkOrder(
            Subject = 'WO1',
            RecordTypeId = recordTypeMeteringId,
            AccountId = acc.Id,
            ContactId = contact.Id,
            Assigned_Meter_Reader__c = sr.Id,
            Scheduled_Date__c = Date.today().addDays(1),
            Work_Order_Type__c = 'Standard',
            StartDate = DateTime.now().addDays(1),
            EndDate = DateTime.now().addDays(1).addHours(5)
        );
        insert wo1;

        WorkOrder wo2 = new WorkOrder(
            Subject = 'WO2',
            RecordTypeId = recordTypeRTId,
            AccountId = acc.Id,
            OwnerId = UserInfo.getUserId(),
            StartDate = DateTime.now().addDays(2),
            EndDate = DateTime.now().addDays(2).addHours(2),
            Due_Amount__c = 100,
            Agent__c = sr.Id,
            R_T_Agency__c = st.Id    
        );
        insert wo2;

        Metering_Dashboard_Config__mdt config = new Metering_Dashboard_Config__mdt(
            DeveloperName = 'Test_Config',
            MasterLabel = 'Test Config',
            Active__c = true,
            Department__c = 'Metering',
            Label__c = 'In Progress',
            Field_API_Name__c = 'Status',
            Values__c = 'Scheduled,Dispatched',
            Order__c = 1
        );
       // insert config;

        List<ServiceAppointment> appointments = new List<ServiceAppointment>{
            new ServiceAppointment(
                ParentRecordId = wo1.Id,
               // AccountId = acc.Id,
                Status = 'Scheduled',
                ServiceTerritoryId = st.Id
            ),
            new ServiceAppointment(
                ParentRecordId = wo2.Id,
               // AccountId = acc.Id,
                Status = 'Dispatched',
                ServiceTerritoryId = st.Id
            )
        };
        insert appointments;
        
        Case_Type_SMS__c csType = new Case_Type_SMS__c(
        	Template_Name__c = 'O&M',
            Template_Id__c = '213123123',
            Message__c = 'retwedasd'
        );
        insert csType;
    }

    @isTest
    static void testBeforeInsertTrigger() {
        WorkOrder wo = [SELECT Id FROM WorkOrder WHERE Subject = 'WO2' AND RecordType.DeveloperName = 'MGL_R_T' LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        ServiceAppointment sa = new ServiceAppointment(
            ParentRecordId = wo.Id
            //AccountId = acc.Id
        );

        Test.startTest();
        insert sa;
        Test.stopTest();
    }

    @isTest
    static void testBeforeUpdateTrigger() {
        ServiceAppointment sa = [SELECT Id, ParentRecordId FROM ServiceAppointment LIMIT 1];
        sa.Status = 'Scheduled';
        Test.startTest();
        update sa;
        Test.stopTest();
    }

    @isTest
    static void testAfterInsertTrigger() {
        WorkOrder wo = [SELECT Id FROM WorkOrder WHERE Subject = 'WO1' LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];

        ServiceAppointment sa = new ServiceAppointment(
            ParentRecordId = wo.Id,
           // AccountId = acc.Id,
            Status = 'Scheduled'
        );

        Test.startTest();
        insert sa;
        Test.stopTest();
    }

    @isTest
    static void testAfterUpdateTrigger() {
        ServiceAppointment sa = [SELECT Id, Status FROM ServiceAppointment LIMIT 1];
        sa.Status = 'Dispatched';
        Test.startTest();
        update sa;
        Test.stopTest();
    }

    @isTest
    static void testMapWorkOrderDatesToAppointments() {
        WorkOrder wo = [SELECT Id FROM WorkOrder WHERE Subject = 'WO2' LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];

        ServiceAppointment sa = new ServiceAppointment(
            ParentRecordId = wo.Id
          //  AccountId = acc.Id
        );

        Test.startTest();
        insert sa;
        Test.stopTest();
    }
    
     @isTest
    static void testServiceResourceAssignment() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        //ServiceTerritory territory = new ServiceTerritory(
          //  Name = 'Test Territory'
            //OperatingHoursId = Test.getStandardOperatingHoursId()
        //);
       // insert territory;
         
        // Create Service Resource linked to running user
        // Create Work Order
        Id recordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('MGL_Metering').getRecordTypeId();
        WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            AccountId = acc.Id,
            RecordTypeId = recordTypeId
        );
        insert wo;

        // Create Service Appointment with Assigned Meter Reader
        ServiceAppointment sa = new ServiceAppointment(
            ParentRecordId = wo.Id
           // Assigned_Meter_Reader__c = sr.Id
        );
        insert sa;

        // Run the method
        Test.startTest();
        ServiceAppointmentTriggerHandler.serviceResourceAssignment(new List<ServiceAppointment>{ sa });
        Test.stopTest();

        // Verify AssignedResource was created
        List<AssignedResource> ars = [SELECT Id, ServiceAppointmentId, ServiceResourceId FROM AssignedResource WHERE ServiceAppointmentId = :sa.Id];
        //System.assertEquals(1, ars.size(), 'AssignedResource should be created');
       // System.assertEquals(sr.Id, ars[0].ServiceResourceId, 'ServiceResourceId should match');
    }
    
    /*
    @isTest
    static void testMapWorkOrderDatesToAppointment() {
        // Get record type for MGL_R_T
        Id recordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('MGL_R_T').getRecordTypeId();

        // Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create Contact related to Account
        Contact con = new Contact(LastName = 'Test Contact', AccountId = acc.Id);
        insert con;

        // Create WorkOrder with MGL_R_T record type and all required fields
        WorkOrder wo = new WorkOrder(
            Subject = 'WO with MGL_R_T',
            AccountId = acc.Id,
            RecordTypeId = recordTypeId,
            StartDate = DateTime.now().addDays(1),
            EndDate = DateTime.now().addDays(2),
            OwnerId = UserInfo.getUserId(),
            Due_Amount__c = 200
        );
        insert wo;

        // Create ServiceAppointment to be passed in method
        ServiceAppointment sa = new ServiceAppointment(
            ParentRecordId = wo.Id
        );

        List<ServiceAppointment> appointments = new List<ServiceAppointment>{ sa };

        Test.startTest();
        ServiceAppointmentTriggerHandler.mapWorkOrderDatesToAppointments(appointments);
        Test.stopTest();

        // Assert that values are mapped correctly
        System.assertEquals(wo.StartDate, sa.SchedStartTime, 'SchedStartTime should match');
        System.assertEquals(wo.EndDate, sa.SchedEndTime, 'SchedEndTime should match');
        System.assertEquals(wo.Due_Amount__c, sa.Due_Amount__c, 'Due amount should match');
        System.assertEquals(wo.OwnerId, sa.OwnerId, 'Owner should match');
        System.assertEquals(con.Id, sa.ContactId, 'Contact should match');
    }*/
    
    
}