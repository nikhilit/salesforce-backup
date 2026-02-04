@isTest
public class UnsuccessfulVisitControllerIPTest {

    // Utility method to create base test data
    private static WorkOrder createTestWorkOrder() {
        
        Case cs = new Case();
        
        cs.Status = 'Actioned by department';
        cs.Is_Cancelled__c=true;
        cs.Current_Work_Type__c='5';
        cs.Standard_Remarks__c ='rejected';
        
        insert cs;
        
         Profile p = [
        SELECT Id 
        FROM Profile 
        WHERE Name = 'System Administrator' 
        LIMIT 1
    ];

    User managerUser = new User(
        FirstName = 'Manager',
        LastName = 'User',
        Alias = 'mgr1',
        Email = 'manager@test.com',
        Username = 'manager' + System.currentTimeMillis() + '@test.com',
        TimeZoneSidKey = 'Asia/Kolkata',
        LocaleSidKey = 'en_US',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        ProfileId = p.Id
    );

    insert managerUser;
        
        Profile p1 = [
    SELECT Id, Name 
    FROM Profile 
    WHERE Name = 'Field Agent Riser'
    LIMIT 1
];
        
         User serviceUser = new User(
        FirstName = 'Service',
        LastName = 'Resource',
        Alias = 'srv1',
        Email = 'service@test.com',
        Username = 'service' + System.currentTimeMillis() + '@test.com',
        TimeZoneSidKey = 'Asia/Kolkata',
        LocaleSidKey = 'en_US',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        ProfileId = p1.Id,
        ManagerId = managerUser.Id   // 👈 tagging manager
    );

    insert serviceUser;
        
       
        
     
         ServiceResource sr = new ServiceResource(
        Name = 'Test Service Resource',
      //  ResourceType = 'Technician',
        IsActive = true,
        RelatedRecordId = serviceUser.Id   
    );

    insert sr;

        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Contact con = new Contact(
    FirstName = 'Test',
    LastName = 'Contact',
    AccountId = acc.Id,
    Phone = '9999999999'
);
insert con;
		
        WorkType testWorkType = new WorkType(
            Name = 'Disconnection WorkType',
            EstimatedDuration = 2.5
        );
        insert testWorkType;
        
           OperatingHours oph = new OperatingHours(Name = 'Test Operating Hours', TimeZone = 'Asia/Kolkata');
        insert oph;
     
        ServiceTerritory st = new ServiceTerritory(Name = 'Test Territory', IsActive = true, OperatingHoursId = oph.Id, Business_Partner_Category__c = 'Domestic');
        insert st;
        
        
        WorkOrder testWorkOrder = new WorkOrder(
            AccountId = acc.Id,
            WorkTypeId = testWorkType.Id,
            Status = 'New',
            CaseId = cs.Id,
            Agent__c=sr.Id,
             Reason_ForUnavilability__c ='House Lock',
            Reason_Other_Remark__c = 'other remark',
            Check_Customer_Availability__c = 'No',
	          ServiceTerritoryId = st.Id,
           ContactId = con.Id,
            AICRemark__c = 'aic ok',
            Approval_Status_AIC__c = 'Approved' 

        );
        insert testWorkOrder;
        
         WorkOrderShare woShare = new WorkOrderShare(
    ParentId = testWorkOrder.Id,
    UserOrGroupId = serviceUser.Id,
    AccessLevel = 'Edit',
    RowCause = Schema.WorkOrderShare.RowCause.Manual
);
insert woShare;
        
        
                 
     
        
        ServiceAppointment sa = new ServiceAppointment(
            ParentRecordId = testWorkOrder.Id,
            Status = 'Scheduled',
            SchedStartTime = System.now().addMinutes(5),
            SchedEndTime = System.now().addMinutes(35),
            ServiceTerritoryId = st.Id,
            Work_Order__c = testWorkOrder.Id
        );
        insert sa;        
        
        
        
        // Create test WorkPlan
        WorkPlan testWorkPlan = new WorkPlan(
            Name = 'Test WorkPlan',
            WorkOrderId = testWorkOrder.Id
        );
        insert testWorkPlan;
        
        WorkStep ws = new WorkStep(
            Name = 'Work Order Execution Detail',
            WorkPlanId = testWorkPlan.Id,
            Status = 'Not Started'
        );
        insert ws;

        return testWorkOrder;
    }

    // 🔹 Positive Test - Submit Unsuccessful Visit with valid reason
  /*  @isTest
    static void testSubmitUnsuccessfulVisit_Valid() {
        WorkOrder wo = createTestWorkOrder();
        
         List<UnsuccessfulVisitControllerIP.FileWrapper> testFiles = new List<UnsuccessfulVisitControllerIP.FileWrapper>();
        UnsuccessfulVisitControllerIP.FileWrapper fw = new UnsuccessfulVisitControllerIP.FileWrapper();
        fw.base64Data = 'testBase64Data';
        fw.fileName = 'testFile.jpg';
        fw.label = 'Test Label';
       
        testFiles.add(fw);
         
             
        
         


        Test.startTest();
        String result = UnsuccessfulVisitControllerIP.savePhotoUploadsIP(wo.Id, wrappers);
        Test.stopTest();

        Test.startTest();
        UnsuccessfulVisitControllerIP.submitUnsuccessfulVisit(
            wo.Id,
            'House Lock',
            'Test Notes',
            Date.today().addDays(-2),testFiles
            
        );
        Test.stopTest();

       

       
    } */

    // 🔹 Negative Test - Blank Reason should throw exception
    @isTest
    static void testSubmitUnsuccessfulVisit_BlankReason() {
        WorkOrder wo = createTestWorkOrder();
        
           List<UnsuccessfulVisitControllerIP.FileWrapper> testFiles = new List<UnsuccessfulVisitControllerIP.FileWrapper>();
        UnsuccessfulVisitControllerIP.FileWrapper fw = new UnsuccessfulVisitControllerIP.FileWrapper();
        fw.base64Data = 'testBase64Data';
        fw.fileName = 'testFile.jpg';
        fw.label = 'Test Label';
       
        testFiles.add(fw);

        try {
            Test.startTest();
            UnsuccessfulVisitControllerIP.submitUnsuccessfulVisit(
                wo.Id,
                '', // blank reason
                'Notes',
                null,testFiles
                
            );
            Test.stopTest();
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('Reason is mandatory.'));
        }
    }

    // 🔹 Test Reason = Others should store in Follow_up_Remarks__c
    @isTest
    static void testSubmitUnsuccessfulVisit_Others() {
        WorkOrder wo = createTestWorkOrder();
        
           List<UnsuccessfulVisitControllerIP.FileWrapper> testFiles = new List<UnsuccessfulVisitControllerIP.FileWrapper>();
        UnsuccessfulVisitControllerIP.FileWrapper fw = new UnsuccessfulVisitControllerIP.FileWrapper();
        fw.base64Data = 'testBase64Data';
        fw.fileName = 'testFile.jpg';
        fw.label = 'Test Label';
       
        testFiles.add(fw);
        
            Case cs = [Select id,Status,Is_Cancelled__c,Current_Work_Type__c,Standard_Remarks__c from Case  limit 1];


        Test.startTest();
          WorkOrderShare workOrderOldOwnerDelete = [
    SELECT Id, AccessLevel, UserOrGroup.Name
    FROM WorkOrderShare
    WHERE ParentId = :wo.Id
    AND UserOrGroup.Profile.Name IN (
        'Field Agent Riser',
        'O&M Field Agent Riser Activity',
        'O&M Supervisor IPD',
        'Field Agent(O&M)- IPD',
        'O&M Supervisor DOMESTIC METER CHECKING',
        'Field Agent(O&M)- AfterSalesService',
        'Supervisor Building Demolition'
    )
    LIMIT 1
];

//delete workOrderOldOwnerDelete;
        UnsuccessfulVisitControllerIP.submitUnsuccessfulVisit(
            wo.Id,
            'Others',
            'Custom Notes for Others',
            null,testFiles
        );
        Test.stopTest();

       

    }
     @isTest
    static void testSubmitUnsuccessfulVisit_HouseLock() {
        WorkOrder wo = createTestWorkOrder();
        
          List<UnsuccessfulVisitControllerIP.FileWrapper> testFiles = new List<UnsuccessfulVisitControllerIP.FileWrapper>();
        UnsuccessfulVisitControllerIP.FileWrapper fw = new UnsuccessfulVisitControllerIP.FileWrapper();
        fw.base64Data = 'testBase64Data';
        fw.fileName = 'testFile.jpg';
        fw.label = 'Test Label';
       
        testFiles.add(fw); 
        
       
        
        Date futureDate = Date.today().addDays(1);
        
		WorkOrder woPar = [Select id,Reason_ForUnavilability__c,Reason_Other_Remark__c,CaseId,
                                      Check_Customer_Availability__c,Agent__r.RelatedRecord.managerid,
                                      WorkTypeId,ServiceTerritoryId,ContactId,
                                 AccountId,OwnerId,Agent__c,AICRemark__c,Approval_Status_AIC__c                            
                                       from WorkOrder where Id=: wo.Id];
        
              Id woOMRecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('MGL O&M').getRecordTypeId();

       
        workorder childWO = new workorder();
                     
         childWO.ParentWorkOrderId = wo.Id;
                childWO.WorkTypeId = wo.WorkTypeId;
                childWO.AccountId = wo.AccountId;
               childWO.RecordTypeId = woOMRecordTypeId;
                childWO.CaseId = wo.CaseId;
               childWO.Agent__c = woPar.Agent__c;
        		childWO.ServiceTerritoryId = woPar.ServiceTerritoryId;
        
        insert childWO;
        
        ServiceAppointment childSA = new ServiceAppointment(
    ParentRecordId = childWO.Id,
    Status = 'Scheduled',
    SchedStartTime = System.now().addHours(1),
    SchedEndTime = System.now().addHours(2),
    ServiceTerritoryId = wo.ServiceTerritoryId,
    Work_Order__c = childWO.Id
);
insert childSA;
        
       /*  ServiceAppointment childsa = new ServiceAppointment(
            ParentRecordId = childWO.Id,
            Status = 'None',
            SchedStartTime = System.now().addMinutes(5),
            SchedEndTime = System.now().addMinutes(35),
           // ServiceTerritoryId = st.Id,
            Work_Order__c = childWO.Id
        );
        insert childsa;   */
        
                
      //  ServiceAppointment serApp = [Select id,SchedStartTime,SchedEndTime,Work_Order__c,Status from ServiceAppointment limit 1];


        Test.startTest();
      
        UnsuccessfulVisitControllerIP.submitUnsuccessfulVisit(
            wo.Id,
            'House Lock',
            'Custom Notes for Others',
             futureDate ,testFiles
        );
        Test.stopTest();      
    }
    
     @isTest
    static void updateWorkStep() {
        
        WorkOrder wo = createTestWorkOrder();
        
        
        
      //  WorkStep wStep = new WorkStep();
      //  wStep.Name='Check Customer Availability';
       // wStep.ParentRecordId= wo.Id;
       // wStep.Status='New';
        
      //  insert wStep;

        Test.startTest();
        UnsuccessfulVisitControllerIP.updateWorkStepStatus(
            wo.Id,
            'Check Customer Availability'
        );
        Test.stopTest();

       

    }
    
    

    // 🔹 Test Save Photo Uploads
  /*  @isTest
    static void testSavePhotoUploadsIP() {
        WorkOrder wo = createTestWorkOrder();

        // Prepare photo wrapper
        UnsuccessfulVisitControllerIP.PhotoWrapper pw = new UnsuccessfulVisitControllerIP.PhotoWrapper();
        pw.base64Data = EncodingUtil.base64Encode(Blob.valueOf('Test File'));
        pw.fileName = 'test.jpg';
        pw.label = 'Test Label';

        List<UnsuccessfulVisitControllerIP.PhotoWrapper> wrappers = new List<UnsuccessfulVisitControllerIP.PhotoWrapper>{ pw };

        Test.startTest();
        String result = UnsuccessfulVisitControllerIP.savePhotoUploadsIP(wo.Id, wrappers);
        Test.stopTest();

        System.assertEquals('SUCCESS', result, 'File upload should return SUCCESS');

        // Verify ContentDocumentLink created
        ContentDocumentLink cdl = [
            SELECT ContentDocumentId, LinkedEntityId 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :wo.Id 
            LIMIT 1
        ];
        System.assertEquals(wo.Id, cdl.LinkedEntityId);

        // Verify WorkStep status updated
        WorkStep ws = [
            SELECT Status FROM WorkStep WHERE ParentRecordId = :wo.Id LIMIT 1
        ];
        System.assertEquals('Completed', ws.Status);
    }

    // 🔹 Test Save Photo Uploads with empty list
    @isTest
    static void testSavePhotoUploadsIP_Empty() {
        WorkOrder wo = createTestWorkOrder();

        Test.startTest();
        String result = UnsuccessfulVisitControllerIP.savePhotoUploadsIP(wo.Id, new List<UnsuccessfulVisitControllerIP.PhotoWrapper>());
        Test.stopTest();

        System.assertEquals('No valid files to upload.', result);
    } */
}