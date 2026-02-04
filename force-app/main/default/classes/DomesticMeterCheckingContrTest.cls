@isTest
public class DomesticMeterCheckingContrTest {
    
    @testSetup
    static void setupTestData() {
        // 1️⃣ Create a test account
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        // 2️⃣ Create WorkType
        WorkType wt = new WorkType(Name = 'Test WorkType', EstimatedDuration = 1);
        insert wt;
        
        // 3️⃣ Create a WorkOrder
        WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            AccountId = acc.Id,
            WorkTypeId = wt.Id,
            Status = 'New',
            SR_Material_Used__c = 'Test',
            Remarks__c = 'Test',
            Material_Recovered__c = 'Test'
        );
        insert wo;
        
        // 4️⃣ Create a WorkPlan (WorkStep needs WorkPlanId)
        WorkPlan wp = new WorkPlan(
            Name = 'Test WorkPlan',
            WorkOrderId = wo.Id
        );
        insert wp;
        
        // 5️⃣ Create a WorkStep linked to WorkPlan
        WorkStep ws = new WorkStep(
            Name = 'Service Report',
            Status = 'Pending',
            WorkPlanId = wp.Id   // 🔑 required field
        );
        insert ws;
    }
    
    
  /*  @isTest
    static void testSaveMeterCheckingDataAndWorkStepUpdate() {
        // Get WorkOrder and WorkStep
        WorkOrder wo = [SELECT Id, SR_Material_Used__c, Material_Recovered__c, Remarks__c FROM WorkOrder LIMIT 1];
        WorkStep ws = [SELECT Id, Status FROM WorkStep WHERE WorkPlan.WorkOrderId = :wo.Id AND Name='Service Report' LIMIT 1];
        
        // Test data
        String materialUsed = 'Material A';
        String materialRecovered = 'Material B';
        String actionTaken = 'Checked successfully';
        
        Test.startTest();
       // DomesticMeterCheckingContr.saveMeterCheckingData(wo.Id, materialUsed, materialRecovered, actionTaken);
        Test.stopTest();
        
        // Verify WorkOrder fields updated
        wo = [SELECT SR_Material_Used__c, Material_Recovered__c, Remarks__c FROM WorkOrder WHERE Id = :wo.Id];
        System.assertEquals(materialUsed, wo.SR_Material_Used__c, 'SR_Material_Used__c should be updated');
        System.assertEquals(materialRecovered, wo.Material_Recovered__c, 'Material_Recovered__c should be updated');
        System.assertEquals(actionTaken, wo.Remarks__c, 'Remarks__c should be updated');
        
        // Verify WorkStep status updated
        ws = [SELECT Status FROM WorkStep WHERE Id = :ws.Id];
    } */
    
    @isTest
    static void testGenerateAndAttachPdf() {
        // Fetch the WorkOrder created in testSetup
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        
        // ⚡ Set the VF page context
        PageReference pageRef = Page.domesticMeterCheckingReportPage;
        Test.setCurrentPage(pageRef);
        
        Test.startTest();
        Id cdId = DomesticMeterCheckingContr.generateAndAttachPdf(wo.Id);
        Test.stopTest();
        
        // If cdId is null (common in test context), mock a ContentVersion
        /*if (cdId == null) {
            ContentVersion cv = new ContentVersion(
                Title = 'Mock PDF',
                PathOnClient = 'Mock.pdf',
                VersionData = Blob.valueOf('Test PDF Content')
            );
            insert cv;
            cdId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        }
        
        // Now link ContentDocument to WorkOrder
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cdId,
            LinkedEntityId = wo.Id,
            ShareType = 'V'
        );
        insert cdl;
        
        // Verify
        List<ContentDocumentLink> cdlList = [
            SELECT Id, ContentDocumentId, LinkedEntityId 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :wo.Id
        ];*/
    }
    
   @isTest
    static void updateWorkStepStatusTest(){
        
            WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

           Test.startTest();
        DomesticMeterCheckingContr.updateWorkStepStatus(wo.Id, 'Completed');
            Test.stopTest();

        
    }

    
    @isTest
    static void testGenerateAndAttachPdf_ExceptionCase() {
        // Call method with wrong Id (to hit exception block)
        Test.startTest();
        Id cdId = DomesticMeterCheckingContr.generateAndAttachPdf('fakeId');
        Test.stopTest();
        
        // Should return null
        System.assertEquals(null, cdId, 'In case of exception, method should return null');
    }
}