@isTest
public class O_MSlaManagementContrTest {

    @testSetup
    static void setupData() {
        // Get WorkOrder record type "MGL O&M"
        Id woRTId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('MGL O&M').getRecordTypeId();

        // Create WorkOrder
        WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            Status = 'New',
            RecordTypeId = woRTId
        );
        insert wo;

        // WorkTypes
        List<WorkType> workTypes = new List<WorkType>{
            new WorkType(Name = 'Riser Maintenance',EstimatedDuration=60),
            new WorkType(Name = 'Meter Replacement',EstimatedDuration=60),
            new WorkType(Name = 'Rubber Hose Replacement',EstimatedDuration=60),
            new WorkType(Name = 'Individual Permanent Disconnection',EstimatedDuration=60),
            new WorkType(Name = 'Domestic Meter Checking',EstimatedDuration=60)
        };
        insert workTypes;
        
        OperatingHours oph = new OperatingHours(Name = 'Test Operating Hours', TimeZone = 'Asia/Kolkata');
        insert oph;
        ServiceTerritory st = new ServiceTerritory(Name = 'Test Territory', IsActive = true, OperatingHoursId = oph.Id, Business_Partner_Category__c = 'Domestic');
        insert st;

        // Use valid picklist values: 'Domestic'
        String validCustomerCategory = 'Domestic';
        String validAccountCategory = 'Domestic';

       

       
        // Create ServiceAppointments for each WorkType
        List<ServiceAppointment> apps = new List<ServiceAppointment>();
        for (WorkType wt : workTypes) {
            apps.add(new ServiceAppointment(
                ParentRecordId = wo.Id,
                WorkTypeId = wt.Id,
                SchedStartTime = System.now().addMinutes(5),
                SchedEndTime = System.now().addMinutes(35),
                ServiceTerritoryId = st.Id
            ));
        }
        insert apps;
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
        
         ServiceResource sr = new ServiceResource(Name = 'Test Resource', IsActive = true, RelatedRecordId = u.Id, Customer_Category__c = 'Domestic');
        insert sr;
         ServiceTerritoryMember stm = new ServiceTerritoryMember(
            ServiceResourceId = sr.Id,
            ServiceTerritoryId = st.Id,
            EffectiveStartDate = Date.today().addDays(-10),
            EffectiveEndDate = Date.today().addYears(1)
        );
        insert stm;
        // AssignedResources linked to those ServiceAppointments
        List<AssignedResource> res = new List<AssignedResource>();
        for (ServiceAppointment sa : apps) {
            res.add(new AssignedResource(
                ServiceAppointmentId = sa.Id,ServiceResourceId = sr.Id
            ));
        }
        insert res;
    }

    @isTest
    static void testUpdateServiceAppointment() {
        List<AssignedResource> lstRes = [SELECT Id, ServiceAppointmentId FROM AssignedResource];

        Test.startTest();
        O_MSlaManagementContr.updateServiceAppointment(lstRes);
        Test.stopTest();

        // Query back updated ServiceAppointments
        List<ServiceAppointment> updatedApps = [
            SELECT Id, WorkType.Name, Turnaround_Time_TAT__c, SLA_Status__c, Department__c, Status
            FROM ServiceAppointment
            WHERE Id IN (SELECT ServiceAppointmentId FROM AssignedResource)
        ];

        System.assert(!updatedApps.isEmpty(), 'ServiceAppointments should be updated');
        for (ServiceAppointment sa : updatedApps) {
           
            if (sa.WorkType.Name == 'Riser Maintenance') {
                System.assertEquals(Integer.valueOf(Label.Turnaround_Time_TAT), sa.Turnaround_Time_TAT__c);
            }
            if (sa.WorkType.Name == 'Meter Replacement' ||
                sa.WorkType.Name == 'Rubber Hose Replacement' ||
                sa.WorkType.Name == 'Individual Permanent Disconnection') {
                System.assertEquals(4, sa.Turnaround_Time_TAT__c);
            }
            if (sa.WorkType.Name == 'Domestic Meter Checking') {
                System.assertEquals(5, sa.Turnaround_Time_TAT__c);
            }
        }
    }
}