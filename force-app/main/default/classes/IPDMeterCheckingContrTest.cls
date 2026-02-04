@isTest
public class IPDMeterCheckingContrTest {
    
     @testSetup
    static void setupData(){
        
      /*  Connection__c con = new Connection__c();
        con.Name='1221';
        insert con;

 Account.FirstName__c, Account.LastName__c, Account.Customer_Contact_no__c,
                        BP_Customer_Address__c, BP_Number__c, WorkOrderNumber, 
                        Completion_Datetime__c, CreatedDate, Owner.Name, ServiceTerritory.Name,
                        Ensure_No_Gas_Leakage_Before_LeavingSit__c,Agent__r.Name,Agent__r.Supervisor__r.Name,                   
                        New_Meter_Make__c, Meter_Number__c, Final_Meter_Reading__c, Final_Remark__c                                        
                            FROM WorkOrder 

*/
      Account acc = new Account(Name='Test Account',FirstName__c='Test',LastName__c='Singh',
                                Customer_Contact_no__c='9878786787',BP_Number__c='2121');
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
    static void generateAndAttachPdfTest(){
        
        
      //  Connection__c con=[Select id,Name from Connection__c];
        Account acc = [Select id,BP_Number__c from Account];
        
        WorkOrder wo = [SELECT Id,AccountId,BP_Number__c FROM WorkOrder LIMIT 1];
        
       
        
        

        
       
        string woId=wo.Id;
        
      
        
       // PageReference pageRef = Page.riserReplacement;
         PageReference pageRef = Page.riserReplacement;
        pageRef.getParameters().put('Id', woId);
        Test.setCurrentPage(pageRef);

        
        Test.startTest();
         IPDMeterCheckingContr.generateAndAttachPdf(woId);
        Test.stopTest();
        
         List<ContentDocumentLink> links = [
        SELECT Id, LinkedEntityId
        FROM ContentDocumentLink
        WHERE LinkedEntityId = :wo.Id
    ];
        
                
        
    }
    
    @isTest
    static void getCreatedServiceReportDetailTest(){
        
        WorkOrder wo = [Select id from WorkOrder limit 1];
        
        Test.startTest();
        
        IPDMeterCheckingContr.getCreatedServiceReportDetail(wo.Id);
        
        Test.stopTest();
        
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
    

}