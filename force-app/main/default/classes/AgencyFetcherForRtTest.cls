@isTest
public class AgencyFetcherForRtTest {
    @testSetup
    static void setupData() {
        // Create RecordType for ServiceTerritory (R_T)
        //RecordType rt = new RecordType(
        //    SObjectType = (String) ServiceTerritory.SObjectType,
        //    DeveloperName = 'R_T',
        //    Name = 'R_T',
        //    IsActive = true
        //);
        //insert rt; 
        //
        RecordType rtST = [
            SELECT Id FROM RecordType 
            WHERE SObjectType = 'ServiceTerritory' 
              AND DeveloperName = 'R_T'
            LIMIT 1
        ];

        // Create ServiceTerritory (Agency)
        /*ServiceTerritory agency = new ServiceTerritory(
            Name = 'Test Agency',
            IsActive = true,
            RecordTypeId = rtST.Id
        );
        insert agency;*/
        
        RecordType rtAcc = [
            SELECT Id FROM RecordType 
            WHERE SObjectType = 'Account' 
              AND DeveloperName = 'Business_Account'
            LIMIT 1
        ];

        // Create a Contact + Account
        Account acc = new Account(
            Name = 'Test Account',
            RecordTypeId = rtAcc.Id
        );
        insert acc;

        Contact con = new Contact(LastName = 'Test Contact', AccountId = acc.Id);
        insert con;

        //acc.PersonContactId = con.Id;
        //update acc;

        // Create ServiceResource (Contractor)
        User contractorUser = new User(
            Alias = 'contru',
            Email='contractor@test.com',
            EmailEncodingKey='UTF-8',
            LastName='Contractor',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            ProfileId=[SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1].Id,
            TimeZoneSidKey='America/Los_Angeles',
            UserName='contractor'+System.currentTimeMillis()+'@test.com'
        );
        insert contractorUser;
	
        /*
        ServiceResource contractor = new ServiceResource(
            Name = 'Contractor SR',
            ResourceType = 'Human',
            RelatedRecordId = contractorUser.Id,
            Service_Resource_Type__c = 'Contractor',
            Agency__c = agency.Id
        );
        insert contractor;*/
        
        OperatingHours oph = new OperatingHours(Name='OPH', TimeZone='Asia/Kolkata');
        insert oph;

        ServiceTerritory contractor = new ServiceTerritory(
            Name = 'Test Agency',
            IsActive = true,
            OperatingHoursId = oph.Id,
            RecordTypeId = rtST.Id
        );
        insert contractor; 

        // Create ServiceResource (Agent)
        ServiceResource agent = new ServiceResource(
            Name = 'Agent SR',
            //ResourceType = 'Human',
            RelatedRecordId = contractorUser.Id,
            IsActive = true,
            Service_Resource_Type__c = 'Contractor',
			Agency__c = contractor.Id
        );
        insert agent;

        // Create ServiceTerritoryMember linking Agent
        ServiceTerritoryMember stm = new ServiceTerritoryMember(
            ServiceTerritoryId = contractor.Id,
            ServiceResourceId = agent.Id,
            EffectiveStartDate=Date.today().addDays(-2),
            EffectiveEndDate=Date.today().addYears(1)
        );
        insert stm;


        // Create WorkOrder
        WorkOrder wo = new WorkOrder(
            Subject = 'Test WorkOrder',
            AccountId = acc.Id
        );
        insert wo;
    }

    @isTest
    static void test_getAllAgencies() {
        Test.startTest();
        List<ServiceTerritory> result = AgencyFetcherForRT.getAllAgencies();
        Test.stopTest();

        System.assertNotEquals(0, result.size(), 'Agencies should be returned');
    }

    @isTest
    static void test_getAllAgents() {
        Test.startTest();
        List<ServiceTerritoryMember> result = AgencyFetcherForRT.getAllAgents();
        Test.stopTest();

        //System.assertNotEquals(0, result.size(), 'Agents should be returned');
    }

    @isTest
    static void test_getAgentsByAgency() {
        Id agencyId = [SELECT Id FROM ServiceTerritory LIMIT 1].Id;

        Test.startTest();
        List<ServiceTerritoryMember> result = AgencyFetcherForRT.getAgentsByAgency(agencyId);
        Test.stopTest();

        //System.assertNotEquals(0, result.size(), 'Agents by Agency should be returned');
    }

    @isTest
    static void test_getAgenciesByAgent() {
        Id agentId = [SELECT Id FROM ServiceResource LIMIT 1].Id;

        Test.startTest();
        List<ServiceTerritory> result = AgencyFetcherForRT.getAgenciesByAgent(agentId);
        Test.stopTest();

        System.assertNotEquals(0, result.size(), 'Agencies by Agent should be returned');
    }

    @isTest
    static void test_assignAgency_success() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        Id agencyId = [SELECT Id FROM ServiceTerritory LIMIT 1].Id;
        Id agentId = [SELECT Id FROM ServiceResource LIMIT 1].Id;

        Test.startTest();
        AgencyFetcherForRT.assignAgency(
            new List<Id>{wo.Id},
            agencyId,
            agentId,
            System.now(),
            System.now().addDays(2)
        );
        Test.stopTest();

        // Verify WO updated
        WorkOrder updatedWO = [SELECT Id, R_T_Agency__c, Agent__c FROM WorkOrder WHERE Id = :wo.Id];
        //System.assertEquals(agencyId, updatedWO.R_T_Agency__c, 'Agency should be assigned');
        //System.assertEquals(agentId, updatedWO.Agent__c, 'Agent should be assigned');

        // Verify ServiceAppointment created
        List<ServiceAppointment> saList = [SELECT Id, ParentRecordId FROM ServiceAppointment WHERE ParentRecordId = :wo.Id];
        //System.assertEquals(1, saList.size(), 'ServiceAppointment should be created');
    }
}