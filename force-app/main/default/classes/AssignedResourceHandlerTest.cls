@isTest
public class AssignedResourceHandlerTest {

    @testSetup
    public static void setupData() {
        // Create User
    Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
    User u = new User(
        FirstName = 'Test',
        LastName = 'Technician123',
        Alias = 'ttech',
        Email = 'test.technician@example.com',
        Username = 'test.technician' + System.currentTimeMillis() + '@example.com',
        CommunityNickname = 'ttech' + System.currentTimeMillis(),
        TimeZoneSidKey = 'Asia/Kolkata',
        LocaleSidKey = 'en_US',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        ProfileId = p.Id
    );
    insert u;
        // Create Account
        Account acc = new Account(Name = 'Test Account', Phone = '9876543210');
        insert acc;

        // Create WorkType
        WorkType wt = new WorkType(Name = 'Maintenance Visit',EstimatedDuration = 1);
        insert wt;
        
         // Use valid picklist values: 'Domestic'
        String validCustomerCategory = 'Domestic';
        String validAccountCategory = 'Domestic';
        
        OperatingHours oph = new OperatingHours(Name = 'Test Operating Hours', TimeZone = 'Asia/Kolkata');
        insert oph;
        
            ServiceTerritory st = new ServiceTerritory(Name = 'Test Territory', IsActive = true, OperatingHoursId = oph.Id, Business_Partner_Category__c = 'Domestic');
        insert st;

       ServiceResource sr = new ServiceResource(Name = 'Test Resource',Role__c='Contractor', IsActive = true, RelatedRecordId = u.Id, Customer_Category__c = validCustomerCategory);
        insert sr;

        ServiceTerritoryMember stm = new ServiceTerritoryMember(
            ServiceResourceId = sr.Id,
            ServiceTerritoryId = st.Id,
            EffectiveStartDate = Date.today().addDays(-10),
            EffectiveEndDate = Date.today().addYears(1)
        );
        insert stm;
       

        
        WorkOrder wo = new WorkOrder(
                Subject = 'Test WO',
                AccountId = acc.Id,
                Status = 'New',
                //RecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('MGL_Metering').getRecordTypeId(),
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
            


        // Link AssignedResource (we won’t insert yet, that comes inside the test method)
        // Create Case_Type_SMS__c template
        Case_Type_SMS__c smsTemplate = new Case_Type_SMS__c(
            Template_Name__c = 'O&M',
            Status__c = 'Active',
            Template_Id__c = 'TMP-001',
            Message__c = 'Hello {assignedTech}, your appointment is on {scheduledDate} from {scheduledStartTime} to {scheduledEndTime} for {activityType}. Link: {technicianLink}',
            Sender__c = 'TestSender'
        );
        insert smsTemplate;
    }

    @isTest
    public static void testHandleAfterInsert_AssignedResource() {
        // Fetch ServiceAppointment and ServiceResource
        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment LIMIT 1];
        ServiceResource sr = [SELECT Id FROM ServiceResource LIMIT 1];
        List<AssignedResource> asignList=New List<AssignedResource>();
        // Insert AssignedResource → should trigger handler
        AssignedResource ar = new AssignedResource(
            ServiceAppointmentId = sa.Id,
            ServiceResourceId = sr.Id
        );
        asignList.add(ar);
        Test.startTest();
        insert asignList; // after-insert logic runs here
        AssignedResourceHandler.handleAfterInsert(asignList);
        Test.stopTest();

    }

   
}