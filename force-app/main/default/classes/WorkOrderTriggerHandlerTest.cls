@isTest
public class WorkOrderTriggerHandlerTest {

    @testSetup
    static void setupTestData() {
        // Create WorkType
        WorkType wt = new WorkType(Name = 'Test Type', EstimatedDuration = 30);
        insert wt;

        // Get valid picklist value for Category__c
        Schema.DescribeFieldResult f = Account.Category__c.getDescribe();
        String categoryValue = f.getPicklistValues()[0].getValue();

        // Create Account using valid picklist value
        Account acc = new Account(Name = 'Test Account', Category__c = 'Domestic', BP_Number__c = '1234');
        insert acc;

        // Create Account Dispenser
        Account_Dispensor__c ad = new Account_Dispensor__c(
            Name = 'Point_1',
            Closing_Reading__c = 123,
            Business_Partner__c = acc.Id
        );
        insert ad;

        // Create OperatingHours
        OperatingHours oh = new OperatingHours(Name = 'Default Hours');
        insert oh;

        // Create Service Territory
        ServiceTerritory st = new ServiceTerritory(Name = 'Territory 1', OperatingHoursId = oh.Id,AgencyCode__c = 'AGENCY1');
        insert st;
         Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
         User testUser = new User(
            Username = 'testuser123MGL@example.com',
            LastName = 'Test',
            Email = 'testuser123MGL@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        // Create Service Resource
        ServiceResource sr = new ServiceResource(Name = 'Test Resource', IsActive = true, Service_Resource_Type__c = 'Meter Reader', RelatedRecordId = testUser.Id, Agent_ID__c = 'AG001');
        insert sr;

        // Create WorkOrder for use in PDF test
        WorkOrder wo = new WorkOrder(
            Subject = 'WO for PDF',
            AccountId = acc.Id,
            WorkTypeId = wt.Id,
            From_Date__c = Date.today(),
            To_Date__c = Date.today().addDays(1)
        );
        insert wo;
        
        Id rtId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('MGL R&T').getRecordTypeId();
        
        WorkOrder wo2 = new WorkOrder(
            Subject = 'Test',
            RecordTypeId = rtId,
            Customer_BP_Number__c = '123123123',
            Agent_ID__c = '12312113',
            Agency_Name__c = '12311211',
            WorkTypeId = wt.Id,
            Agent__c = null,
            R_T_Agency__c = null,
            AccountId = null,
            From_Date__c = Date.today(),
            To_Date__c = Date.today().addDays(1)
        );
        insert wo2;
    }

    @isTest
    static void testBeforeInsertCheckWorkTypeAssigned() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        WorkOrder wo = new WorkOrder(
            Subject = 'WO without WT',
            AccountId = acc.Id
        );

        Test.startTest();
        insert wo;
        Test.stopTest();
    }

    @isTest
    static void testCreateDispenserPoints() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        WorkType wt = [SELECT Id FROM WorkType LIMIT 1];

        WorkOrder wo = new WorkOrder(
            Subject = 'WO with Dispenser',
            AccountId = acc.Id,
            WorkTypeId = wt.Id
        );
        insert wo;

        Test.startTest();
        WorkOrderTriggerHandler.createDispenserPoints(new List<WorkOrder>{wo});
        Test.stopTest();
    }

    @isTest
    static void testHandleStatusUpdate() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        WorkType wt = [SELECT Id FROM WorkType LIMIT 1];

        WorkOrder wo = new WorkOrder(
            Subject = 'Status Update WO',
            AccountId = acc.Id,
            WorkTypeId = wt.Id,
            Appointment_Status__c = 'Completed'
        );
        insert wo;

        WorkOrder updated = [SELECT Id, Appointment_Status__c, Follow_Up_Appointment_Date__c FROM WorkOrder WHERE Id = :wo.Id];
        updated.Appointment_Status__c = 'Incomplete';
        updated.Follow_Up_Appointment_Date__c = Date.today().addDays(2);

        Map<Id, WorkOrder> oldMap = new Map<Id, WorkOrder>{
            wo.Id => new WorkOrder(
                Id = wo.Id,
                Appointment_Status__c = 'Completed',
                Follow_Up_Appointment_Date__c = null
            )
        };

        Test.startTest();
        WorkOrderTriggerHandler.handleStatusUpdate(new List<WorkOrder>{updated}, oldMap);
        Test.stopTest();
    }

    @isTest
    static void testExtractLastNumber() {
        Integer result = WorkOrderTriggerHandler.extractLastNumber('Point_1');
        System.assertEquals(456, result);
    }
    
     /*  @isTest
    static void dtmmytest() {
        Test.startTest();
        WorkOrderTriggerHandler.dummy();
        Test.stopTest();
    }*/

    @IsTest
    static void testattachPDFsAsync(){
        List<Account> accList = [SELECT Id, Name, Category__c, BP_Number__c FROM Account];
        List<WorkOrder> woList = [SELECT Id, From_Date__c, To_Date__c, WorkTypeId, AccountId, Subject, Account.BP_Number__c FROM WorkOrder];
        List<Id> woIds = new List<Id>();
        for(WorkOrder each : woList){
           woIds.add(each.Id);
        }
        //Test.startTest();
        WorkOrderTriggerHandler.attachPDFsAsync(woIds);
        //Test.stopTest();
    }


//Test for updating MeterReading when work order Approval status changes to approved
    @isTest
    static void testUpdateMeterReading(){
        Account_Dispensor__c accDisp = [Select id from Account_Dispensor__c limit 1];

        Account acc = new Account(Name = 'Test Account', Category__c = 'CNG/LNG', BP_Number__c = '12345');
        insert acc;

        WorkOrder wo = [select id from WorkOrder limit 1];

        Dispenser_Point__c dispPoint = new Dispenser_Point__c();
        dispPoint.Closing_Reading__c = 100;
        dispPoint.Account_Dispensor__c = accDisp.id;
        dispPoint.WorkOrderID__c = wo.id;
        dispPoint.Live__c = true;
        dispPoint.Dispenser_Number__c = 'Test';
        insert dispPoint;
        
        Id rtId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('MGL Metering').getRecordTypeId();
        wo.RecordTypeId = rtId;
        wo.AccountId = acc.id;
        wo.Approval_Status__c = 'Approved';
        update wo;
        
        Account_Dispensor__c accDispensor = [Select id,SCADA_Closing_Reading__c,Closing_Reading__c from Account_Dispensor__c limit 1];
        System.assertEquals(123,accDispensor.SCADA_Closing_Reading__c);
        System.Assert.areEqual(100,accDispensor.Closing_Reading__c);
        System.Assert.areEqual(100,accDispensor.Closing_Reading__c);
    }
   
//Test for populating related fields in Work Orders before insert    
    @IsTest
    static void testPopulateRelatedFields(){
        Account acc = [SELECT Id,BP_Number__c FROM Account WHERE BP_Number__c = '1234' LIMIT 1];
        ServiceResource sr = [SELECT Id,Agent_ID__c FROM ServiceResource Where Agent_ID__c = 'AG001' LIMIT 1];
        ServiceTerritory st = [SELECT Id,AgencyCode__c FROM ServiceTerritory Where AgencyCode__c = 'AGENCY1' LIMIT 1];

        Portion__c po = new Portion__c(Name = 'Test');
        insert po;

        Id rtId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('MGL R&T').getRecordTypeId();
        
        WorkOrder wo = new WorkOrder(
            Subject = 'Test',
            RecordTypeId = rtId,
            Customer_BP_Number__c = '1234',
            Agent_ID__c = 'AG001',
            Agency_Name__c = 'AGENCY1',
            Billing_portion__c = 'Test',
            Agent__c = null,
            R_T_Agency__c = null,
            AccountId = null,
            Portion__c = null,
            From_Date__c = Date.today(),
            To_Date__c = Date.today().addDays(1)
        );
         Test.startTest();
    	 insert wo;
    	 Test.stopTest();

        WorkOrder updatedWo = [SELECT Id, Agent__c, R_T_Agency__c, AccountId, Portion__c FROM WorkOrder WHERE Id = :wo.Id Limit 1];

        System.assertEquals(sr.Id, updatedWo.Agent__c);
        System.assertEquals(st.Id,updatedWo.R_T_Agency__c);
        System.assertEquals(acc.Id, updatedWo.AccountId);
        System.assertEquals(po.Id,updatedWo.Portion__c);
    }


//Test for updating Work order Address fields from its related BP.
    @isTest
    static void testPopulateWOAddress(){
        Account acc = new Account(Name = 'Test Account',
                                    Road_name__c = 'Test Road Name',
                                    Landmark__c = 'Test Landmark',
                                    Location__c = 'Test Location',
                                    City__c = 'Test City',
                                    Postal_Code__c = '1234');
        insert acc;

        WorkType wt = new WorkType(Name = 'Billing Distribution (r&t)',EstimatedDuration = 30);
        insert wt;

        WorkOrder wo = new WorkOrder(AccountId = acc.Id,WorkTypeId = wt.Id);

        Test.startTest();
        insert wo;
        Test.stopTest();

        WorkOrder updatedWO = [SELECT Id, Road_name__c, Landmark__c, Location__c, City__c, Postal_Code__c FROM WorkOrder WHERE Id = :wo.Id];

        System.Assert.areEqual('Test Road Name', updatedWO.Road_name__c);
        System.Assert.areEqual('Test Landmark', updatedWO.Landmark__c);
        System.Assert.areEqual('Test Location', updatedWO.Location__c);
        System.Assert.areEqual('Test City', updatedWO.City__c);
        System.Assert.areEqual('1234', updatedWO.Postal_Code__c);
    }

}