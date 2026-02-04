@isTest
public class RiserMaintenenceServiceReportContrTest {
    
    
    
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
    RiserMaintenenceServiceReportContr.updateWorkStepStatus(wo.Id, 'Test');
    Test.stopTest();

 
}
    
    @isTest
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
         PageReference pageRef = Page.riserMaintenancePage;
        pageRef.getParameters().put('Id', wolItem.Id);
        Test.setCurrentPage(pageRef);

        
        Test.startTest();
         RiserMaintenenceServiceReportContr.generateAndAttachPdf(woId);
        Test.stopTest();
        
         List<ContentDocumentLink> links = [
        SELECT Id, LinkedEntityId
        FROM ContentDocumentLink
        WHERE LinkedEntityId = :wo.Id
    ];
        
                
        
    }
    
    
   
    
    
    


}