@isTest
public class AssignServiceAppointmentToAgentContrTest {

    @testSetup
    static void setupData() {
        // Create a test user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User u = new User(
            Alias = 'testu',
            Email = 'testu@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'TestCheckUser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testuser' + System.currentTimeMillis() + '@test.com'
        );
        insert u;
        User u2 = new User(
            Alias = 'testu',
            Email = 'testu@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testuser' + System.currentTimeMillis() + '@test.com'
        );
        insert u2;

        OperatingHours oph = new OperatingHours(Name = 'Test Operating Hours', TimeZone = 'Asia/Kolkata');
        insert oph;

        ServiceTerritory st = new ServiceTerritory(Name = 'Test Territory', IsActive = true, OperatingHoursId = oph.Id, Business_Partner_Category__c = 'Domestic');
        insert st;

        // Use valid picklist values: 'Domestic'
        String validCustomerCategory = 'Domestic';
        String validAccountCategory = 'Domestic';

        ServiceResource sr = new ServiceResource(Name = 'Test Resource',Role__c='Contractor', IsActive = true, RelatedRecordId = u.Id, Customer_Category__c = validCustomerCategory);
        insert sr;

        ServiceTerritoryMember stm = new ServiceTerritoryMember(
            ServiceResourceId = sr.Id,
            ServiceTerritoryId = st.Id,
            EffectiveStartDate = Date.today().addDays(-10),
            EffectiveEndDate = Date.today().addYears(1)
        );
        insert stm;

        Account acc = new Account(Name = 'Test Account', Category__c = validAccountCategory, Location__c = 'Loc1', Zone__c = 'Zone1', Representative_Company__c = 'RepCo');
        insert acc;

            WorkOrder wo = new WorkOrder(
                Subject = 'Test WO',
                AccountId = acc.Id,
                Status = 'New',
                RecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('MGL_Metering').getRecordTypeId(),
                StartDate = Date.today(),
                EndDate = Date.today(),
                Assigned_Meter_Reader__c = sr.Id
            );
            insert wo;

            ServiceAppointment sa = new ServiceAppointment(
                ParentRecordId = wo.Id,
                Status = 'Scheduled',
                SchedStartTime = System.now().addMinutes(5),
                SchedEndTime = System.now().addMinutes(35),
                ServiceTerritoryId = st.Id
            );
            insert sa;

            /*AssignedResource ar = new AssignedResource(ServiceAppointmentId = sa.Id, ServiceResourceId = sr.Id);
            insert ar;*/
        
    }

    @isTest
    static void testGetContractorAgents() {
        // Run as the contractor user created in setup
       // User contrUser = [SELECT Id FROM User WHERE Username LIKE 'testuser%@test.com' LIMIT 1];
       
        Profile p = [SELECT Id, Name FROM Profile WHERE Name = 'O&M AIC IPD' LIMIT 1];

      /*  Profile p1 = [SELECT Id, Name FROM Profile WHERE Name = 'Supervisor (O&M- IPD)' LIMIT 1];
        
       Profile p2 = [SELECT Id, Name FROM Profile WHERE Name = 'RubberHose AIC' LIMIT 1];

       Profile p3 = [SELECT Id, Name FROM Profile WHERE Name = 'Supervisor (O&M)' LIMIT 1];
        
      Profile p4 = [SELECT Id, Name FROM Profile WHERE Name = 'AIC (O&M- Domestic Meter Checking)' LIMIT 1];

*/
    // create user with same profile but trick by setting profile name in SOQL check
    // since we cannot change Profile.Name directly, we simulate by querying AIC profile if it exists
    User u = new User(
        Alias = 'aicipd',
        Email = 'aicipd@test.com',
        EmailEncodingKey = 'UTF-8',
        LastName = 'AICUser',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        ProfileId = p.Id,
        TimeZoneSidKey = 'America/Los_Angeles',
        Username = 'aicipd' + System.currentTimeMillis() + '@test.com'
    );
    insert u;

    // Create Supervisor user + ServiceResource
    User sup = new User(
        Alias = 'supipd',
        Email = 'supipd@test.com',
        EmailEncodingKey = 'UTF-8',
        LastName = 'Supervisor',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        ProfileId = p.Id,
        TimeZoneSidKey = 'America/Los_Angeles',
        Username = 'supipd' + System.currentTimeMillis() + '@test.com'
    );
    insert sup;
        
      

    ServiceResource supSR = new ServiceResource(
        Name = 'SupSR',
        IsActive = true,
        RelatedRecordId = sup.Id
    );
    insert supSR;
        Test.startTest();
        System.runAs(u) {
            List<ServiceResource> agents = AssignServiceAppointmentToAgentContr.getContractorAgents();
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetContractorAgents1() {
        // Run as the contractor user created in setup
       // User contrUser = [SELECT Id FROM User WHERE Username LIKE 'testuser%@test.com' LIMIT 1];
       
      //  Profile p = [SELECT Id, Name FROM Profile WHERE Name = 'AIC (O&M- IPD)' LIMIT 1];
        
                  Account acc = new Account(Name = 'Test Account');
            insert acc;
        
                /*    Database.executeBatch(new PartnerAccountEnableBatch(new Set<Id>{acc.Id}));
            acc.IsPartner = true;
            update acc; */
            
            // Contact
            Contact con = new Contact(
                LastName = 'Test Contact',
                AccountId = acc.Id,
                Email = 'testcontact' + System.currentTimeMillis() + '@test.com'
            );
            insert con;

        Profile p = [SELECT Id, Name FROM Profile WHERE Name = 'Supervisor (O&M- IPD)' LIMIT 1];
        
         Profile pAgent = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];

        
      /* Profile p2 = [SELECT Id, Name FROM Profile WHERE Name = 'RubberHose AIC' LIMIT 1];

       Profile p3 = [SELECT Id, Name FROM Profile WHERE Name = 'Supervisor (O&M)' LIMIT 1];
        
      Profile p4 = [SELECT Id, Name FROM Profile WHERE Name = 'AIC (O&M- Domestic Meter Checking)' LIMIT 1];

*/
    // create user with same profile but trick by setting profile name in SOQL check
    // since we cannot change Profile.Name directly, we simulate by querying AIC profile if it exists
  /*  User u = new User(
        Alias = 'aicipd',
        Email = 'aicipd@test.com',
        EmailEncodingKey = 'UTF-8',
        LastName = 'AICUser',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        ProfileId = p.Id,
        TimeZoneSidKey = 'America/Los_Angeles',
        Username = 'aicipd' + System.currentTimeMillis() + '@test.com'
    );
    insert u; */

    // Create Supervisor user + ServiceResource
    User sup = new User(
        Alias = 'supipd',
        Email = 'supipd@test.com',
        EmailEncodingKey = 'UTF-8',
        LastName = 'Supervisor',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        ProfileId = p.Id,
        TimeZoneSidKey = 'America/Los_Angeles',
        Username = 'supfipdk' + System.currentTimeMillis() + '@test.com'
       //  ContactId = con.Id 

    );
    insert sup;
        
      /*   User fieAgent = new User(
        Alias = 'agentipd',
        Email = 'supipd@test.com',
        EmailEncodingKey = 'UTF-8',
        LastName = 'Supervisor',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        ProfileId = pAgent.Id,
        TimeZoneSidKey = 'America/Los_Angeles',
        Username = 'fieldaipd' + System.currentTimeMillis() + '@test.com'
    );
    insert fieAgent; */
        
         ServiceResource sr = new ServiceResource(Name = 'Test Resource',Role__c='Contractor', IsActive = true, RelatedRecordId = sup.Id);
        insert sr;
        
      

   /* ServiceResource supSR = new ServiceResource(
        Name = 'SupSR',
        IsActive = true,
        RelatedRecordId = fieAgent.Id,
        Supervisor__c = sr.Id
    );
    insert supSR; */
        Test.startTest();
        System.runAs(sup) {
            List<ServiceResource> agents = AssignServiceAppointmentToAgentContr.getContractorAgents();
        }
        Test.stopTest();
    }


  @isTest
    static void testGetContractorAgents2() {
      
        
       Profile p = [SELECT Id, Name FROM Profile WHERE Name = 'O&M AIC Rubber Hose' LIMIT 1];
        
        

    /*   Profile p3 = [SELECT Id, Name FROM Profile WHERE Name = 'Supervisor (O&M)' LIMIT 1];
        
      Profile p4 = [SELECT Id, Name FROM Profile WHERE Name = 'AIC (O&M- Domestic Meter Checking)' LIMIT 1];

*/
    // create user with same profile but trick by setting profile name in SOQL check
    // since we cannot change Profile.Name directly, we simulate by querying AIC profile if it exists
    User u = new User(
        Alias = 'aicipd',
        Email = 'aicipd@test.com',
        EmailEncodingKey = 'UTF-8',
        LastName = 'AICUser',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        ProfileId = p.Id,
        TimeZoneSidKey = 'America/Los_Angeles',
        Username = 'aicipd' + System.currentTimeMillis() + '@test.com'
    );
    insert u;

    // Create Supervisor user + ServiceResource
    User sup = new User(
        Alias = 'supipd',
        Email = 'supipd@test.com',
        EmailEncodingKey = 'UTF-8',
        LastName = 'Supervisor',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        ProfileId = p.Id,
        TimeZoneSidKey = 'America/Los_Angeles',
        Username = 'supipdk' + System.currentTimeMillis() + '@test.com'
    );
    insert sup;
        
      

    ServiceResource supSR = new ServiceResource(
        Name = 'SupSR',
        IsActive = true,
        RelatedRecordId = sup.Id
    );
    insert supSR;
        Test.startTest();
        System.runAs(u) {
            List<ServiceResource> agents = AssignServiceAppointmentToAgentContr.getContractorAgents();
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetContractorAgents3() {
      
          Profile p = [SELECT Id, Name FROM Profile WHERE Name = 'Supervisor (O&M)' LIMIT 1];

        
     
   /* User u = new User(
        Alias = 'aicipd',
        Email = 'aicipd@test.com',
        EmailEncodingKey = 'UTF-8',
        LastName = 'AICUser',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        ProfileId = p.Id,
        TimeZoneSidKey = 'America/Los_Angeles',
        Username = 'aicipd' + System.currentTimeMillis() + '@test.com'
    );
    insert u; */

    // Create Supervisor user + ServiceResource
    User sup = new User(
        Alias = 'supipd',
        Email = 'supipd@test.com',
        EmailEncodingKey = 'UTF-8',
        LastName = 'Supervisor',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        ProfileId = p.Id,
        TimeZoneSidKey = 'America/Los_Angeles',
        Username = 'supipdk' + System.currentTimeMillis() + '@test.com'
    );
    insert sup;
        
      

   /* ServiceResource supSR = new ServiceResource(
        Name = 'SupSR',
        IsActive = true,
        RelatedRecordId = sup.Id
    );
    insert supSR; */
        
          Profile pagent = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User u = new User(
            Alias = 'testu',
            Email = 'testu@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'TestCheckUser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = pagent.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testuser' + System.currentTimeMillis() + '@test.com'
        );
        insert u;
        
          ServiceResource sr = new ServiceResource(Name = 'Test Resource',Role__c='Contractor', IsActive = true, RelatedRecordId = sup.Id);
        insert sr;
    ServiceResource srAgent = new ServiceResource(Name = 'Test Resource',IsActive = true, RelatedRecordId = u.Id,Supervisor__c=sr.Id);
        insert srAgent;     
        
        
        Test.startTest();
        System.runAs(sup) {
            List<ServiceResource> agents = AssignServiceAppointmentToAgentContr.getContractorAgents();
        }
        Test.stopTest();
    }
    
     @isTest
    static void testGetContractorAgents4() {
      

         Profile p = [SELECT Id, Name FROM Profile WHERE Name = 'O&M AIC DOMESTIC METER CHECKING' LIMIT 1];

     
    User u = new User(
        Alias = 'aicipd',
        Email = 'aicipd@test.com',
        EmailEncodingKey = 'UTF-8',
        LastName = 'AICUser',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        ProfileId = p.Id,
        TimeZoneSidKey = 'America/Los_Angeles',
        Username = 'aicipd' + System.currentTimeMillis() + '@test.com'
    );
    insert u;

    // Create Supervisor user + ServiceResource
    User sup = new User(
        Alias = 'supipd',
        Email = 'supipd@test.com',
        EmailEncodingKey = 'UTF-8',
        LastName = 'Supervisor',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        ProfileId = p.Id,
        TimeZoneSidKey = 'America/Los_Angeles',
        Username = 'supipdk' + System.currentTimeMillis() + '@test.com'
    );
    insert sup;
        
      

    ServiceResource supSR = new ServiceResource(
        Name = 'SupSR',
        IsActive = true,
        RelatedRecordId = sup.Id
    );
    insert supSR;
        Test.startTest();
        System.runAs(u) {
            List<ServiceResource> agents = AssignServiceAppointmentToAgentContr.getContractorAgents();
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetContractorAgents5() {
      
          Profile p = [SELECT Id, Name FROM Profile WHERE Name = 'Supervisor (O&M- Domestic Meter Checking)' LIMIT 1];

        
     
  
    User sup = new User(
        Alias = 'supipd',
        Email = 'supipd@test.com',
        EmailEncodingKey = 'UTF-8',
        LastName = 'Supervisor',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        ProfileId = p.Id,
        TimeZoneSidKey = 'America/Los_Angeles',
        Username = 'supipd12' + System.currentTimeMillis() + '@test.com'
    );
    insert sup;
        
      

  
        
          Profile pagent = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User u = new User(
            Alias = 'testu',
            Email = 'testu@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'TestCheckUser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = pagent.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testuser1' + System.currentTimeMillis() + '@test.com'
        );
        insert u;
        
          ServiceResource sr = new ServiceResource(Name = 'Test Resource',Role__c='Contractor', IsActive = true, RelatedRecordId = sup.Id);
        insert sr;
    ServiceResource srAgent = new ServiceResource(Name = 'Test Resource',IsActive = true, RelatedRecordId = u.Id,Supervisor__c=sr.Id);
        insert srAgent;     
        
        
        Test.startTest();
        System.runAs(sup) {
            List<ServiceResource> agents = AssignServiceAppointmentToAgentContr.getContractorAgents();
        }
        Test.stopTest();
    }
    
      
        
    

    @isTest
    static void testAssignAgentToAssignResource() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        ServiceAppointment sa = [SELECT Id, Status FROM ServiceAppointment LIMIT 1];
        ServiceResource agent = [SELECT Id FROM ServiceResource WHERE Role__c = 'Contractor' LIMIT 1];

        List<String> reactiveValues = new List<String>{ wo.Id };

        Test.startTest();
       /* String result = AssignServiceAppointmentToAgentContr.assignAgentToAssignResource(
            reactiveValues,
            agent.Id,
            DateTime.now().addDays(1),
            DateTime.now().addDays(2) 
        ); */
        Test.stopTest();

    }
    @isTest
    static void testAssignAgentToAssignResource1() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        
          OperatingHours oph = new OperatingHours(Name = 'Test Operating Hours', TimeZone = 'Asia/Kolkata');
        insert oph;

         ServiceTerritory st = new ServiceTerritory(Name = 'Test Territory', IsActive = true, OperatingHoursId = oph.Id);
      //  insert st;
        
          ServiceAppointment sa = new ServiceAppointment(
                ParentRecordId = wo.Id,
                Status = 'Scheduled',
                SchedStartTime = null,
                SchedEndTime = null,
                ServiceTerritoryId = st.Id
            );
            insert sa;

      //  ServiceAppointment sa = [SELECT Id, Status FROM ServiceAppointment LIMIT 1];
        ServiceResource agent = [SELECT Id FROM ServiceResource WHERE Role__c = 'Contractor' LIMIT 1];

        List<String> reactiveValues = new List<String>{ wo.Id };

        Test.startTest();
        String result = AssignServiceAppointmentToAgentContr.assignAgentToAssignResource(
            reactiveValues,
            agent.Id,
            sa.SchedStartTime,
            sa.SchedEndTime
          //  DateTime.now().addDays(1),
           // DateTime.now().addDays(2)
        );
        Test.stopTest();

    }

    @isTest
    static void testAssignAgentWithNullDates() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        ServiceResource agent = [SELECT Id FROM ServiceResource WHERE Role__c = 'Contractor' LIMIT 1];

        List<String> reactiveValues = new List<String>{ wo.Id };

        Test.startTest();
        String result = AssignServiceAppointmentToAgentContr.assignAgentToAssignResource(
            reactiveValues,
            agent.Id,
            null,
            null // null dates to test default behavior
        );
        Test.stopTest();

    }

    @isTest
    static void testGetContractorAgents_ExceptionCase() {
        // Create a user that is NOT a contractor
        User nonContrUser = new User(
            Alias = 'xxuser',
            Email = 'xx@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'xxuser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'xxuser' + System.currentTimeMillis() + '@test.com'
        );
        insert nonContrUser;

        Boolean thrown = false;
        Test.startTest();
        System.runAs(nonContrUser) {
            try {
                AssignServiceAppointmentToAgentContr.getContractorAgents();
            } catch (AuraHandledException e) {
                thrown = true;
            }
        }
        Test.stopTest();

       // System.assert(thrown, 'Should throw AuraHandledException when no contractor found');
    }
}