@isTest
public class DomesticMeterCheckingPageTest {
    @testSetup
    static void setupData() {
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

        OperatingHours oph = new OperatingHours(Name = 'Test Operating Hours', TimeZone = 'Asia/Kolkata');
        insert oph;

        ServiceTerritory st = new ServiceTerritory(Name = 'Test Territory', IsActive = true, OperatingHoursId = oph.Id, Business_Partner_Category__c = 'Domestic');
        insert st;

        // Use valid picklist values: 'Domestic'
        String validCustomerCategory = 'Domestic';
        String validAccountCategory = 'Domestic';

        ServiceResource sr = new ServiceResource(Name = 'Test Resource', IsActive = true, RelatedRecordId = u.Id, Customer_Category__c = validCustomerCategory);
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

            AssignedResource ar = new AssignedResource(ServiceAppointmentId = sa.Id, ServiceResourceId = sr.Id);
            insert ar;
    }

    @isTest
    static void testControllerWithValidId() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        Test.startTest();
        // Setup page with parameters
        PageReference pageRef = new PageReference('/apex/DummyVFPage');
        pageRef.getParameters().put('id', wo.Id);
        pageRef.getParameters().put('materialUsed', 'Test Material');
        Test.setCurrentPage(pageRef);

        DomesticMeterCheckingReportPageContr controller = new DomesticMeterCheckingReportPageContr();
        Test.stopTest();

    }

    @isTest
    static void testControllerWithNoId() {
        Test.startTest();
        PageReference pageRef = new PageReference('/apex/DummyVFPage');
        Test.setCurrentPage(pageRef);

        DomesticMeterCheckingReportPageContr controller = new DomesticMeterCheckingReportPageContr();
        Test.stopTest();
    }
}