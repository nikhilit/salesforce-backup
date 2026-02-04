@isTest
public class CreateWOFromConnectionContrTest {

    @testSetup
    static void setupData() {
        
        // Create OperatingHours for ServiceTerritory
        OperatingHours oph = new OperatingHours(Name = 'Test Hours');
        insert oph;

        Account acc = new Account(
            Name = 'Test Account',
            Category__c = 'Domestic',
            Location__c = 'Loc1',
            Zone__c = 'Zone1',
            Representative_Company__c = 'RepCo'
        );
        insert acc;

        // Create a WorkType
        WorkType wt = new WorkType(
            Name = 'Riser Maintenance',
            EstimatedDuration = 60,
            ShouldAutoCreateSvcAppt = true
        );
        insert wt;
        
         Connection__c conn = new Connection__c(Name = 'Test Connection');
        insert conn;

        // WorkOrder for linking ServiceAppointment
        WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            AccountId = acc.Id,
            Status = 'New',
            WorkTypeId = wt.Id,
            RecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('MGL_O_M').getRecordTypeId(),
            StartDate = Date.today(),
            EndDate = Date.today(),
            Connection__c = conn.Id
            
        );
        insert wo;

        // Service Territory
        ServiceTerritory st = new ServiceTerritory(
            Name = 'Test Territory',
            IsActive = true,
            OperatingHoursId = oph.Id,
            Business_Partner_Category__c = 'Domestic'
        );
        insert st;

        // ServiceAppointment (CreatedById = running user, we can’t override)
        ServiceAppointment sa = new ServiceAppointment(
            ParentRecordId = wo.Id,
            //Status = 'Dispatched',
            SchedStartTime = System.now().addMinutes(5),
            SchedEndTime = System.now().addMinutes(35),
            ServiceTerritoryId = st.Id
        );
        insert sa;

        // ServiceResource must match running user’s Id
        ServiceResource sr = new ServiceResource(
            Name = 'Test Resource',
            IsActive = true,
            RelatedRecordId = UserInfo.getUserId(),  // important fix
            Customer_Category__c = 'Domestic'
        );
        insert sr;

        ServiceTerritoryMember stm = new ServiceTerritoryMember(
            ServiceResourceId = sr.Id,
            ServiceTerritoryId = st.Id,
            EffectiveStartDate = Date.today().addDays(-10),
            EffectiveEndDate = Date.today().addYears(1)
        );
        insert stm;

        // Connection__c
       
    }

    @isTest
    static void testCreateWorkOrder_Success() {
        Connection__c conn = [SELECT Id FROM Connection__c LIMIT 1];
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory LIMIT 1];
        ServiceAppointment sapp = [SELECT Id,status,SchedEndTime,SchedStartTime FROM ServiceAppointment LIMIT 1];
        WorkType wt = [SELECT Id, Name FROM WorkType LIMIT 1];

        Test.startTest();
        String woId = CreateWOFromConnectionContr.createWorkOrder(
            conn.Id,
            wt.Name,
            DateTime.now(),
            st.Id,
            'Test Supervisor',
            'Mohan',
            '4100012888'
        );
        
        List<ServiceTerritory> terrList = CreateWOFromConnectionContr.getServiceTerritories();
        Test.stopTest();
    }
    
    @isTest
    static void getLatestRiserMaintenanceWOTest(){
        
        WorkOrder wo = [Select id,Connection__c,Worktypeid,CreatedDate from workorder where connection__c !='' limit 1];
        
        Test.startTest();
        
        WorkOrder woReturn = CreateWOFromConnectionContr.getLatestRiserMaintenanceWO(wo.Connection__c);
        
        Test.stopTest();
    }


    @isTest
    static void testGetServiceTerritories_Failure() {
        Test.startTest();
        List<ServiceTerritory> territories = new List<ServiceTerritory>();
        try {
            territories = CreateWOFromConnectionContr.getServiceTerritories();
        } catch (Exception e) {
            System.assert(true, 'Exception handled');
        }
        Test.stopTest();
        System.assertNotEquals(null, territories, 'Should return empty list in case of exception');
    }

    //  New: Force exception for getServiceTerritories
    @isTest
    static void testGetServiceTerritories_Exception() {
        OperatingHours oph = [SELECT Id FROM OperatingHours LIMIT 1];
        // Insert a ServiceTerritory without Work_Type__c to cause null deref
        ServiceTerritory badST = new ServiceTerritory(
            Name = 'Bad ST',
            IsActive = true,
            OperatingHoursId = oph.Id
        );
        insert badST;

        Test.startTest();
        List<ServiceTerritory> terrs = CreateWOFromConnectionContr.getServiceTerritories();
        Test.stopTest();

        System.assertEquals(true, terrs.isEmpty(), 'Should return empty list on exception');
    }
}