@IsTest
public class CheckInControllerTest {

    @TestSetup
    static void setupTestData() {
        // 1. Create a User
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
        
          Profile fieldAgentRiserProfile = [SELECT Id FROM Profile WHERE Name = 'Field Agent Riser' LIMIT 1];
       Profile fieldAgentOMProfile = [SELECT Id FROM Profile WHERE Name = 'Field Agent(O&M)- IPD' LIMIT 1];
        
        
        User riserUser = new User(
            FirstName = 'Riser',
            LastName = 'Test',
            Email = 'riser.test@test.com',
            Username = 'riser.test@test.com',
            Alias = 'rtest',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = fieldAgentRiserProfile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert riserUser;
        
         User omUser = new User(
            FirstName = 'OM',
            LastName = 'Test',
            Email = 'om.test@test.com',
            Username = 'om.test@test.com',
            Alias = 'otest',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = fieldAgentOMProfile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert omUser;

        // 2. WorkOrder RecordType
        RecordType woRT = [SELECT Id FROM RecordType WHERE SObjectType='WorkOrder' AND DeveloperName='MGL_O_M' LIMIT 1];

        // 3. Create WorkTypes
        WorkType riserWT = new WorkType(Name = 'Riser Painting', EstimatedDuration = 60);
        WorkType domesticWT = new WorkType(Name = 'Domestic Meter Checking', EstimatedDuration = 60);
        insert new List<WorkType>{riserWT, domesticWT};

        // 4. WorkOrders
        WorkOrder riserWO = new WorkOrder(Subject='Riser WO', Status='New', WorkTypeId = riserWT.Id, RecordTypeId = woRT.Id);
        WorkOrder domesticWO = new WorkOrder(Subject='Domestic WO', Status='New', WorkTypeId = domesticWT.Id, RecordTypeId = woRT.Id);
        WorkOrder otherWO = new WorkOrder(Subject='Other WO', Status='New', RecordTypeId = woRT.Id);
        insert new List<WorkOrder>{riserWO, domesticWO, otherWO};

        // 5. Create WorkPlans
        WorkPlan riserWP = new WorkPlan(Name='Riser WP', WorkOrderId=riserWO.Id);
        WorkPlan domesticWP = new WorkPlan(Name='Domestic WP', WorkOrderId=domesticWO.Id);
        insert new List<WorkPlan>{riserWP, domesticWP};

        // 6. Create WorkSteps
        List<WorkStep> workSteps = new List<WorkStep>();
        workSteps.add(new WorkStep(Name='Check-in', WorkPlanId=riserWP.Id, Status='New'));
        workSteps.add(new WorkStep(Name='CO Execution Detail', WorkPlanId=riserWP.Id, Status='New'));
        workSteps.add(new WorkStep(Name='Check-in', WorkPlanId=domesticWP.Id, Status='New'));
        workSteps.add(new WorkStep(Name='Site Details', WorkPlanId=domesticWP.Id, Status='New'));
        insert workSteps;

        // 7. Operating Hours, ServiceTerritory, ServiceResource, ServiceAppointment
        OperatingHours oh = new OperatingHours(Name='Default Operating Hours');
        insert oh;
        ServiceTerritory st = new ServiceTerritory(Name='Test Territory', IsActive=true, OperatingHoursId=oh.Id);
        insert st;
        ServiceResource sr = new ServiceResource(Name='Test Resource', RelatedRecordId=u.Id, IsActive=true);
        insert sr;
        ServiceAppointment sa = new ServiceAppointment(Subject='Test Appointment', Status='Scheduled', ParentRecordId=riserWO.Id, ServiceTerritoryId=st.Id);
        insert sa;
    }
    
    @isTest
    static void checkUploadSiteDocumentApprovedTest(){
        
           WorkOrder riserWO = [SELECT Id FROM WorkOrder WHERE Subject='Riser WO' LIMIT 1];

        WorkStep ws = [SELECT Id, Status FROM WorkStep WHERE Name='Check-in' AND ParentRecordId=:riserWO.Id LIMIT 1];


        	Test.startTest();
        
        WorkOrder wo = checkInController.checkUploadSiteDocumentApproved(riserWO.Id);
        
            Test.stopTest();
        
    }
    
     @IsTest
    static void testGetApprovalStatusWithoutDocument() {
        User testUser = [SELECT Id, Username FROM User WHERE Username = 'riser.test@test.com'];
        
        System.runAs(testUser) {
            Test.startTest();
            CheckInController.CheckInControllerWrapper result = CheckInController.getApprovalStatus();
            Test.stopTest();
            
           // System.assertNotEquals(null, result, 'Should return empty document object');
        }
    } 
    
     /* Document__c testDoc = new Document__c(
                Submitted_Agent_Name__c = testUser.Username,
                Approval_Status_O_M__c = 'Pending'
            );
            insert testDoc; */
    
     @IsTest
    static void testGetApprovalStatusWithDocument() {
        User testUser = [SELECT Id, Username FROM User WHERE Username = 'riser.test@test.com'];
        
        System.runAs(testUser) {
          
            
          RecordType woTBT = [SELECT Id FROM RecordType WHERE SObjectType='WorkOrder' AND DeveloperName='TBT' LIMIT 1];

            
 			ServiceResource sr = [Select id from serviceresource limit 1];

           WorkOrder wo = new WorkOrder();
            
			wo.RecordTypeId = woTBT.Id;
			wo.Agent__c = sr.Id;
           // wo.Approvar_User__c = u.Id;
            
            insert wo; 
            
            Test.startTest();
           CheckInController.CheckInControllerWrapper result = CheckInController.getApprovalStatus();
            Test.stopTest();
            
          
        }
    } 
    
    
   
    @IsTest
    static void testGetCheckInStatus() {
        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment LIMIT 1];

        Test.startTest();
        ServiceAppointment result = CheckInController.getCheckInStatus(sa.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'ServiceAppointment should be returned');
        System.assertEquals(sa.Id, result.Id, 'Returned record Id should match');
    }

    // Test check-in update
    @IsTest
    static void testUpdateServiceAppoinment_CheckIn() {
        ServiceAppointment sa = [SELECT Id, ParentRecordId, ServiceTerritoryId FROM ServiceAppointment LIMIT 1];
        Double lat = 12.9716;
        Double lon = 77.5946;
        DateTime now = System.now();
        String saIdStr = String.valueOf(sa.Id);

        Test.startTest();
        String message = CheckInController.updateServiceAppoinment(saIdStr, lat, lon, true, now);
        Test.stopTest();

        // Covers check-in branch
       // System.assertEquals('Check In Successfully', message);
    }

    // Test check-out update
    @IsTest
    static void testUpdateServiceAppoinment_CheckOut() {
        ServiceAppointment sa = [SELECT Id, ParentRecordId, ServiceTerritoryId FROM ServiceAppointment LIMIT 1];
        Double lat = 12.9716;
        Double lon = 77.5946;
        DateTime now = System.now();
        String saIdStr = String.valueOf(sa.Id);

        Test.startTest();
        String message = CheckInController.updateServiceAppoinment(saIdStr, lat, lon, false, now);
        Test.stopTest();

        // Covers check-out branch
        //System.assertEquals('Check Out Successfully', message);
    }

    // Test missing values branch in updateServiceAppoinment
    @IsTest
    static void testUpdateServiceAppoinment_MissingValues() {
        Double lat = 12.9716;
        Double lon = 77.5946;
        DateTime now = System.now();

        Test.startTest();
        String message = CheckInController.updateServiceAppoinment((String)null, lat, lon, true, now);
        Test.stopTest();

        System.assertEquals('MISSING_VALUES', message);
    }
    
    @IsTest
    static void testCheckWorkStep_FullCoverage() {
        WorkOrder riserWO = [SELECT Id FROM WorkOrder WHERE Subject='Riser WO' LIMIT 1];
        WorkOrder domesticWO = [SELECT Id FROM WorkOrder WHERE Subject='Domestic WO' LIMIT 1];
        WorkOrder otherWO = [SELECT Id FROM WorkOrder WHERE Subject='Other WO' LIMIT 1];

        Test.startTest();
        String riserResult = CheckInController.checkWorkStep(riserWO.Id);
        String domesticResult = CheckInController.checkWorkStep(domesticWO.Id);
        String otherResult = CheckInController.checkWorkStep(otherWO.Id);
        Test.stopTest();

        System.assertEquals('riserPaintingSuccess', riserResult);
        System.assertEquals('domesticMeterCheckingSuccess', domesticResult);
        System.assertEquals('Success', otherResult);
    }

    @IsTest
    static void testUpdateWorkStepStatus_Coverage() {
        WorkOrder riserWO = [SELECT Id FROM WorkOrder WHERE Subject='Riser WO' LIMIT 1];

        // Before update
        WorkStep ws = [SELECT Id, Status FROM WorkStep WHERE Name='Check-in' AND ParentRecordId=:riserWO.Id LIMIT 1];
        System.assertEquals('New', ws.Status);

        Test.startTest();
        CheckInController.updateWorkStepStatus(riserWO.Id, 'Check-in');
        Test.stopTest();

        // After update
        ws = [SELECT Id, Status FROM WorkStep WHERE Name='Check-in' AND ParentRecordId=:riserWO.Id LIMIT 1];
        System.assertEquals('Completed', ws.Status, 'WorkStep should be updated to Completed');
    }


    // Test checkWorkStep OK fallback branch
    @IsTest
    static void testCheckWorkStep_OK() {
        WorkOrder wo = [SELECT Id, WorkTypeId, WorkType.Name FROM WorkOrder LIMIT 1];

        Test.startTest();
        String status = CheckInController.checkWorkStep(wo.Id);
        Test.stopTest();

        // Fallback branch is executed
        //System.assertEquals('Success', status, 'Default fallback for WorkSteps');
    }
}