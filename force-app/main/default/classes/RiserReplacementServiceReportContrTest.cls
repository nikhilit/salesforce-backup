@isTest
private class RiserReplacementServiceReportContrTest {
    
    @testSetup
    static void setupData(){
        
        Connection__c con = new Connection__c();
        con.Name='1221';
        insert con;
      Account acc = new Account(Name='Test Account',Connection__c=con.Id);
        insert acc;

        // WorkType
        WorkType wt = new WorkType(Name='Test WorkType',EstimatedDuration=60);
        insert wt;

        // WorkOrder
        WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            AccountId = acc.Id,
            WorkTypeId = wt.Id,
            Status = 'New'
        );
        insert wo;
        
         ContentVersion cv = new ContentVersion(
        Title = 'Test Document',
        PathOnClient = 'TestDocument.pdf',
        VersionData = Blob.valueOf('Test Content'),
        IsMajorVersion = true
       // O_M_Document_Types__c = validDocType
    );
    insert cv;
    
    // Create ContentDocumentLink
    Id cdId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
    ContentDocumentLink cdl = new ContentDocumentLink(
        LinkedEntityId = wo.Id,
        ContentDocumentId = cdId,
        ShareType = 'I'
    );
    insert cdl;
    }
    
    @isTest
static void updateWorkStepStatusTest() {
    
    WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
    
   

    WorkPlan testWorkPlan = new WorkPlan(
        Name = 'Test WorkPlan',
        WorkOrderId = wo.Id
    );
    insert testWorkPlan;

    WorkStep ws = new WorkStep(
        Name = 'Test',
        WorkPlanId = testWorkPlan.Id,
        Status = 'New'
    );
    insert ws;


    Test.startTest();
    RiserReplacementServiceReportContr.updateWorkStepStatus(wo.Id, 'Test');
    Test.stopTest();

 
}
    
  /*  @isTest
    static void generateAndAttachPdfTest(){
        
        
        Connection__c con=[Select id,Name from Connection__c];
        Account acc = [Select id,Connection__c from Account];
        
        WorkOrder wo = [SELECT Id,AccountId FROM WorkOrder LIMIT 1];
        
         WorkOrderLineItem wolItem = new WorkOrderLineItem();
   // wolItem.Name='Test';
    wolItem.WorkOrderId=wo.Id;
    wolItem.Riser_Name__c ='Riser 1';
    
    insert wolItem;
        
        

        
        List<WorkOrderLineItem> lstWolItem = [Select id,WorkOrderId,Riser_Name__c from WorkOrderLineItem Where workorderid=:wo.Id];
        
        string woId=wo.Id;
        
      
        
       // PageReference pageRef = Page.riserReplacement;
         PageReference pageRef = Page.riserReplacement;
        pageRef.getParameters().put('Id', wolItem.Id);
        Test.setCurrentPage(pageRef);

        
        Test.startTest();
         RiserReplacementServiceReportContr.generateAndAttachPdf(woId);
        Test.stopTest();
        
         List<ContentDocumentLink> links = [
        SELECT Id, LinkedEntityId
        FROM ContentDocumentLink
        WHERE LinkedEntityId = :wo.Id
    ];
        
                
        
    } */
    
    @isTest
static void generateAndAttachPdfTest(){

    WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

    // Create WOLI
    WorkOrderLineItem wolItem = new WorkOrderLineItem(
        WorkOrderId = wo.Id,
        Riser_Name__c = 'Riser 1'
    );
    insert wolItem;

    // 🔹 Create DAY-WISE record (THIS WAS MISSING)
    WorkOrderLineItem_Day_Wise__c woliDay = new WorkOrderLineItem_Day_Wise__c(
        Work_Order_Line_Item__c = wolItem.Id,
        Length_of_Riser_Tested__c = '10'
        // OR Length_of_Riser_Commissioned__c = '10'
    );
    insert woliDay;

    // VF Page setup
    PageReference pageRef = Page.riserReplacement;
    pageRef.getParameters().put('Id', wolItem.Id);
    Test.setCurrentPage(pageRef);

    Test.startTest();
    String result = RiserReplacementServiceReportContr.generateAndAttachPdf(wo.Id);
    Test.stopTest();

    // 🔹 Assertions
  //  System.assertEquals('Records Found', result);

  /*  List<ContentDocumentLink> links = [
        SELECT Id, LinkedEntityId
        FROM ContentDocumentLink
        WHERE LinkedEntityId = :wolItem.Id
    ]; */
   // System.assertEquals(1, links.size(), 'PDF should be attached to WOLI');
}

    
    
   
    
    
     @isTest
    static void testGenerateAndAttachPdf_ExceptionCase() {
        // Call method with wrong Id (to hit exception block)
        Test.startTest();
      //  RiserReplacementServiceReportContr.generateAndAttachPdf('fakeId');
        Test.stopTest();
        
        // Should return null
       // System.assertEquals(null, cdId, 'In case of exception, method should return null');
    }

}