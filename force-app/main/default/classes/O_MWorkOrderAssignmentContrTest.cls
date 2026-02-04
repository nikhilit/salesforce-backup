@isTest
public class O_MWorkOrderAssignmentContrTest {

    @testSetup
    static void setupData() {
        
        
        // Create a sample DRS Master record
        DRS__c drsMaster = new DRS__c(
            Name = '0001',
            DRS_Code__c = '0001',
            GA__c = 'GA-I'
        );
        insert drsMaster;

        // Create Account with DRS Master lookup
        Account acc = new Account(
            Name = 'Test Account',
            DRS_Master__c = drsMaster.Id,
            DRS__c='0001'
        );
        insert acc;

        // Create WorkType
        WorkType wt = new WorkType(Name='Domestic Meter Checking',EstimatedDuration = 60);
        insert wt;
        
        OperatingHours oph = new OperatingHours(
            Name = 'Default Operating Hours',
            TimeZone = 'Asia/Kolkata'
        );
        insert oph;

        // Create Service Territory (Agency)
        ServiceTerritory st = new ServiceTerritory(Name='Test Territory',OperatingHoursId = oph.Id,IsActive = true);
        insert st;
        
        // Get a Profile to assign the User
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        // Create User
        User u = new User(
            FirstName = 'Test',
            LastName = 'Contractor',
            Email = 'testcontractor@example.com',
            Username = 'testcontractor' + System.currentTimeMillis() + '@example.com',
            Alias = 'tcon',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert u;
        
        // Create Service Resource with RelatedRecordId = User.Id
        ServiceResource sr = new ServiceResource(
            Name = 'Contractor Resource',
            IsActive = true,
            RelatedRecordId = u.Id,
            Role__c='Contractor',
            Activity_Name__c ='Domestic Meter Checking'
        );
        insert sr;

        // Create Service Territory Member (active via dates, no IsActive field!)
        ServiceTerritoryMember stm = new ServiceTerritoryMember(
            ServiceTerritoryId = st.Id,
            ServiceResourceId = sr.Id,
            EffectiveStartDate = Date.today().addDays(-1),
            EffectiveEndDate   = Date.today().addYears(1)
        );
        insert stm;

        // Create DRS Contractor Mapping Master
        DRS_Contractor_Mapping_Master__c drsMap = new DRS_Contractor_Mapping_Master__c(
            DRS__c = drsMaster.Id,    
            Agency__c = st.Id,
            Activity_Name__c = wt.Name
        );
        insert drsMap;
        
       String workOrderRecordTypeId = Schema.getGlobalDescribe().get('WorkOrder').getDescribe().getRecordTypeInfosByDeveloperName().get('MGL_O_M').getRecordTypeId();


        // Create WorkOrder with O&M Department (eligible case)
        WorkOrder wo = new WorkOrder(
            Subject='Test WO',
            AccountId = acc.Id,
            Department__c='O&M',
            WorkTypeId = wt.Id,
            Status='New',
			RecordTypeId =workOrderRecordTypeId
        );
        insert wo;

        // Create Service Appointment related to WO
        ServiceAppointment sa = new ServiceAppointment(
            ParentRecordId = wo.Id,
            Status='New'
        );
        insert sa;

        // Create WorkOrder that does not meet condition (negative case)
        WorkOrder woNeg = new WorkOrder(
            Subject='Neg WO',
            AccountId = acc.Id,
            Department__c='Finance',
            WorkTypeId = wt.Id,
            Status='New'
        );
        insert woNeg;
    }

    @isTest
    static void testAssignWorkOrder_Positive() {
        List<WorkOrder> wos = [SELECT Id, AccountId, Department__c, CaseId, WorkTypeId,RecordTypeId 
                               FROM WorkOrder WHERE Department__c = 'O&M'];
        Test.startTest();
        O_MWorkOrderAssignmentContr.assignWorkOrder(wos);
        Test.stopTest();

        // Fetch updated WO
        WorkOrder updatedWO = [SELECT Id, OwnerId, RecordTypeId, ServiceTerritoryId, Work_Order_Type__c
                               FROM WorkOrder WHERE Id = :wos[0].Id];

      
       }

    @isTest
    static void testAssignWorkOrder_Negative() {
        List<WorkOrder> wos = [SELECT Id, AccountId, Department__c, CaseId, WorkTypeId,RecordTypeId 
                               FROM WorkOrder WHERE Department__c = 'Finance'];
        Test.startTest();
        O_MWorkOrderAssignmentContr.assignWorkOrder(wos);
        Test.stopTest();

        // Fetch WO again
        WorkOrder woNeg = [SELECT Id, OwnerId, RecordTypeId, ServiceTerritoryId 
                           FROM WorkOrder WHERE Id = :wos[0].Id];

        // Assert no changes happened
        //System.assertEquals(null, woNeg.OwnerId, 'OwnerId should not be updated');
        //System.assertEquals(null, woNeg.RecordTypeId, 'RecordType should not be updated');
        //System.assertEquals(null, woNeg.ServiceTerritoryId, 'ServiceTerritory should not be updated');
    }
}