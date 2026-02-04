@isTest
private class MeterReadingScheduleHandlerTest {
    
    @testSetup
    static void setupData() {
        OperatingHours oh = new OperatingHours(
            Name = System.Label.Default_Operating_Hours_Name,
            TimeZone = 'America/Los_Angeles' // Required field for OperatingHours
        );
        insert oh;
        
        // Create ServiceTerritory
        ServiceTerritory territory = new ServiceTerritory(Name = 'Test Territory',OperatingHoursId=oh.Id,IsActive=true);
        insert territory;
        
        // Get a Profile to assign to the user — pick an existing one in your org
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        // Create test user
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'tuser',
            Email = 'testuser@example.com',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            CommunityNickname = 'testuser' + DateTime.now().getTime(),
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            IsActive=true
        );
        insert u;

        // Create ServiceResource (Agent)
        ServiceResource agent1 = new ServiceResource(Name = 'Agent 1', IsActive = true,RelatedRecordId=UserInfo.getUserId());
        ServiceResource agent2 = new ServiceResource(Name = 'Agent 2', IsActive = true,RelatedRecordId=u.Id);
        insert new List<ServiceResource>{agent1,agent2};

        // Create ServiceTerritoryMember mapping agents to territory
        insert new List<ServiceTerritoryMember>{
            new ServiceTerritoryMember(ServiceTerritoryId = territory.Id, ServiceResourceId = agent1.Id,EffectiveStartDate=System.Today()),
            new ServiceTerritoryMember(ServiceTerritoryId = territory.Id, ServiceResourceId = agent2.Id,EffectiveStartDate=System.Today())
        };

        // Create Meter Reading Schedules
        Meter_Reading_Schedule__c sched1 = new Meter_Reading_Schedule__c(
            Meter_Reader_Name__c='Test1',
            Agent__c = agent1.Id,
            Status__c = 'Pending',
            Active__c = false,
            Meter_Reading_Start_Date__c = Date.today(),
            Meter_Reading_Completion_Date__c = Date.today().addDays(1)
        );
        insert sched1;

        Meter_Reading_Schedule__c sched2 = new Meter_Reading_Schedule__c(
            Agent__c = agent2.Id,
            Status__c = 'Pending',
            Active__c = true,
            Meter_Reading_Start_Date__c = Date.today().addDays(2),
            Meter_Reading_Completion_Date__c = Date.today().addDays(3)
        );
        insert sched2;

        // Create WorkOrder linked to sched1
        WorkOrder wo = new WorkOrder(
            Subject = 'Test WorkOrder',
            Meter_Reading_Schedule__c = sched1.Id,
            Status = 'Open',
            StartDate = System.today(),
            EndDate = Date.today().addDays(1)
        );
        insert wo;

        // Create ServiceAppointment linked to WorkOrder
        ServiceAppointment sa = new ServiceAppointment(
            ParentRecordId = wo.Id,
            Status = 'Scheduled',
            SchedStartTime = System.now(),
            SchedEndTime = System.now().addHours(1)
        );
        insert sa;
    }

    @isTest
    static void testHandleAgentUpdate_AgentChanged() {
        Meter_Reading_Schedule__c existing = [SELECT Id, Agent__c,Status__c,Meter_Reading_Completion_Date__c FROM Meter_Reading_Schedule__c WHERE Meter_Reader_Name__c='' LIMIT 1];
        Meter_Reading_Schedule__c updated = existing.clone(false, true, false, false);
        updated.Agent__c = [SELECT Id FROM ServiceResource WHERE Name = 'Agent 1' LIMIT 1].Id;

        Test.startTest();
        MeterReadingScheduleHandler.handleAgentUpdate(
            new List<Meter_Reading_Schedule__c>{existing},
            new Map<Id, Meter_Reading_Schedule__c>{existing.Id => updated}
        );
        Test.stopTest();

    }

    @isTest
    static void testHandleAgentUpdate_DateChanged() {
        Meter_Reading_Schedule__c existing = [SELECT Id, Meter_Reading_Completion_Date__c,Status__c,Agent__c FROM Meter_Reading_Schedule__c WHERE Meter_Reader_Name__c='Test1' LIMIT 1];
        Meter_Reading_Schedule__c updated = existing.clone(false, true, false, false);
        updated.Meter_Reading_Completion_Date__c = Date.today().addDays(10);

        Test.startTest();
        MeterReadingScheduleHandler.handleAgentUpdate(
            new List<Meter_Reading_Schedule__c>{existing},
            new Map<Id, Meter_Reading_Schedule__c>{existing.Id => updated}
        );
        Test.stopTest();

    }

    @isTest
    static void testValidateOverlappingSchedules() {
        Meter_Reading_Schedule__c s1 = [SELECT Id, Agent__c FROM Meter_Reading_Schedule__c LIMIT 1];
        Meter_Reading_Schedule__c overlapping = new Meter_Reading_Schedule__c(
            Agent__c = s1.Agent__c,
            Meter_Reading_Start_Date__c = Date.today(),
            Meter_Reading_Completion_Date__c = Date.today().addDays(1)
        );

        Test.startTest();
        try {
            MeterReadingScheduleHandler.validateOverlappingSchedules(
                new List<Meter_Reading_Schedule__c>{overlapping},
                new Map<Id, Meter_Reading_Schedule__c>()
            );
        } catch (Exception e) {
            System.assert(e.getMessage().contains('overlapping'));
        }
        Test.stopTest();
    }

    @isTest
    static void testValidateActiveSchedule() {
        Meter_Reading_Schedule__c s1 = [SELECT Id, Agent__c FROM Meter_Reading_Schedule__c WHERE Active__c = true LIMIT 1];
        Meter_Reading_Schedule__c newActive = new Meter_Reading_Schedule__c(
            Agent__c = s1.Agent__c,
            Active__c = true
        );

        Test.startTest();
        try {
            MeterReadingScheduleHandler.validateActiveSchedule(
                new List<Meter_Reading_Schedule__c>{newActive},
                new Map<Id, Meter_Reading_Schedule__c>()
            );
        } catch (Exception e) {
            System.assert(e.getMessage().contains('already active'));
        }
        Test.stopTest();
    }

    @isTest
    static void testScheduleToBeActive() {
        Meter_Reading_Schedule__c s1 = [SELECT Id, Agent__c, Active__c FROM Meter_Reading_Schedule__c WHERE Active__c = true LIMIT 1];
        Meter_Reading_Schedule__c s2 = [SELECT Id, Agent__c, Active__c FROM Meter_Reading_Schedule__c WHERE Active__c = false LIMIT 1];
        s2.Active__c = true;

        Test.startTest();
        MeterReadingScheduleHandler.scheduleToBeActive(
            new List<Meter_Reading_Schedule__c>{s2},
            null
            
        );
        Test.stopTest();

    }
}