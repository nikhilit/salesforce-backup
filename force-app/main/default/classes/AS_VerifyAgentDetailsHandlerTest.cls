/**
* @File Name : AS_VerifyAgentDetailsHandlerTest.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : July 9, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | July 9, 2025 |   | Initial Version
**/

@isTest
private class AS_VerifyAgentDetailsHandlerTest {

    @testSetup
    static void setupData() {
        // Create required OperatingHours for the ServiceTerritory
        OperatingHours hours = new OperatingHours(
            Name = 'Base Calendar',
            TimeZone = 'America/New_York'
        );
        insert hours;
    
        // Create a ServiceTerritory (used as Agency)
        ServiceTerritory agency = new ServiceTerritory(
            Name = 'Test Territory',
            OperatingHoursId = hours.Id,
            isActive = true
        );
        insert agency;

        // Create a User to associate with ServiceResource
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
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

        // Create a ServiceResource linked to User and Agency
        ServiceResource sr = new ServiceResource(
            Name = 'Test Agent',
            RelatedRecordId = testUser.Id,
            //Aadhar__c = '1234-5678-9012',
            Email_Id__c = 'agent@example.com',
            Agency__c = agency.Id,
            isActive = true,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addDays(5)
        );
        insert sr;
        
        // Create a ServiceTerritoryMember to associate ServiceResource with ServiceTerritory
        ServiceTerritoryMember member = new ServiceTerritoryMember(
            ServiceTerritoryId = agency.Id,
            ServiceResourceId = sr.Id,
            EffectiveStartDate = Date.today(),
            EffectiveEndDate = Date.today().addDays(5)
        );
        insert member;
    }

    @isTest
    static void testGetAgentDetails() {
        // Get the test user and ServiceResource
        User u = [SELECT Id FROM User WHERE Username = 'testuser123MGL@example.com' LIMIT 1];


        // Call method under test
        Test.startTest();
        AS_VerifyAgentDetailsHandler.AgentDetailsWrapper result =
            AS_VerifyAgentDetailsHandler.getAgentDetails(u.Id);
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals('Test Agent', result.name, 'Agent name should match');

        // Assert expected fields are present
        System.assert(result.fields.size() > 0, 'Fields list should not be empty');

        Boolean foundEmail = false;
        Boolean foundAgencyName = false;

        for (AS_VerifyAgentDetailsHandler.AgentFieldWrapper field : result.fields) {
            if (field.apiName == 'Email_Id__c') {
                foundEmail = true;
                System.assertEquals('agent@example.com', field.value);
                System.assert(field.label != null && field.label != '', 'Email label should be present');
            }
            if (field.apiName == 'Agency__r.Name') {
                foundAgencyName = true;
                System.assertEquals('Test Territory', field.value);
                System.assertEquals('Agency Name', field.label);
            }
        }

        System.assert(foundEmail, 'Email_Id__c field should be returned');
        System.assert(foundAgencyName, 'Agency__r.Name field should be returned');
    }

    @isTest
    static void testGetAgentDetailsWithMissingFields() {
        // Negative test: what if no ServiceResource is found?
        Test.startTest();
        try {
            AS_VerifyAgentDetailsHandler.getAgentDetails('001000000000000'); // Fake Id
            System.assert(false, 'Expected exception due to missing record');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('List has no rows'), 'Should throw expected query exception');
        }
        Test.stopTest();
    }
}