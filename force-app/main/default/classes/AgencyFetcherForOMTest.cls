@isTest
public class AgencyFetcherForOMTest {

    @testSetup
    static void setupTestData() {
        // Create test user (contractor)
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

        // Use existing OM RecordType
        Id rtId = [SELECT Id FROM RecordType WHERE SObjectType = 'ServiceTerritory' AND DeveloperName = 'O_M' LIMIT 1].Id;
		
        OperatingHours oph = new OperatingHours(
            Name = 'Default Operating Hours',
            TimeZone = 'Asia/Kolkata'
        );
        insert oph;
        
        
        // Create ServiceTerritory (Agency)
        ServiceTerritory st = new ServiceTerritory(
            Name = 'Test OM Agency',
            IsActive = true,
            RecordTypeId = rtId,
            OperatingHoursId = oph.Id
        );
        insert st;

        // Create ServiceResource (Contractor)
        ServiceResource sr = new ServiceResource(
            Name = 'Test Contractor',
            IsActive = true,
            RelatedRecordId = u.Id,
            Role__c = 'Contractor',
            Agency__c = st.Id
        );
        insert sr;

        // Create WorkOrder
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            AccountId = acc.Id,
            Status = 'New'
        );
        insert wo;
    }

    @isTest
    static void testGetOMAgencies() {
        Test.startTest();
        List<ServiceTerritory> agencies = AgencyFetcherForOM.getOMAgencies();
        Test.stopTest();

        System.assert(agencies.size() > 0, 'Should fetch at least one OM agency.');
        for (ServiceTerritory st : agencies) {
            //System.assertEquals(true, st.IsActive, 'Agency should be active.');
        }
    }

    @isTest
    static void testAssignOMAgency() {
        // Get test agency and workOrder
        ServiceTerritory agency = [SELECT Id FROM ServiceTerritory LIMIT 1];
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        List<String> woIds = new List<String>{String.valueOf(wo.Id)};

        Test.startTest();
        AgencyFetcherForOM.assignOMAgency(woIds, agency.Id);
        Test.stopTest();

        WorkOrder updatedWO = [SELECT Id, ServiceTerritoryId, OwnerId, Assiged_to_Agency__c FROM WorkOrder WHERE Id = :wo.Id];
        System.assertEquals(agency.Id, updatedWO.ServiceTerritoryId, 'ServiceTerritoryId should be updated.');
        System.assertNotEquals(null, updatedWO.OwnerId, 'OwnerId should be set.');
        System.assertEquals(true, updatedWO.Assiged_to_Agency__c, 'Assigned to Agency checkbox should be true.');
    }

    @isTest
    static void testAssignOMAgency_NoContractor() {
        // Create an agency without contractor
        
        OperatingHours oph = new OperatingHours(
            Name = 'Default Operating Hours',
            TimeZone = 'Asia/Kolkata'
        );
        insert oph;
        
        Id rtId = [SELECT Id FROM RecordType WHERE SObjectType = 'ServiceTerritory' AND DeveloperName = 'O_M' LIMIT 1].Id;
        ServiceTerritory st = new ServiceTerritory(Name='NoContractor', IsActive=true, RecordTypeId=rtId,OperatingHoursId = oph.Id);
        insert st;

        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        List<String> woIds = new List<String>{String.valueOf(wo.Id)};

        try {
            Test.startTest();
            AgencyFetcherForOM.assignOMAgency(woIds, st.Id);
            Test.stopTest();
            System.assert(false, 'Should have thrown an exception for no contractor.');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('No contractor'), 'Exception message should indicate no contractor found.');
        }
    }
}