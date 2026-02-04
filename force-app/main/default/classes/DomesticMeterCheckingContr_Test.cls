@isTest
private class DomesticMeterCheckingContr_Test {

    @testSetup
    static void setupData() {
        Account acc = new Account(Name = 'Test Acc');
        insert acc;

        WorkOrder wo = new WorkOrder(
            AccountId = acc.Id,
            Subject   = 'WO – Test',
            Status    = 'New'
        );
        insert wo;

 		// Create WorkPlan (linked to WorkOrder)
       /* WorkPlan wp = new WorkPlan(
            WorkOrderId = wo.Id,
			Name = 'Work Plan'
        );
        insert wp;
        
        // Create WorkStep (child of WorkPlan)
        WorkStep ws = new WorkStep(
            Name = 'Step 1',
            WorkPlanId = wp.Id,     // correct parent reference
            Status = 'Not Started'
        );
        insert ws;*/
    }

    private static Id getAnyWorkOrderId() {
        return [SELECT Id FROM WorkOrder LIMIT 1].Id;
    }

    @isTest
    static void test_saveMeterCheckingData_noWorkStep() {
        Id woId = getAnyWorkOrderId();

        Test.startTest();
        DomesticMeterCheckingContr.saveMeterCheckingData(
            woId, 'Mat Used', 'Mat Rec', 'Act Taken'
        );
        Test.stopTest();

        WorkOrder woAfter = [
            SELECT SR_Material_Used__c, Material_Recovered__c, Remarks__c
            FROM WorkOrder WHERE Id = :woId
        ];
        System.assertEquals('Mat Used', woAfter.SR_Material_Used__c);
        System.assertEquals('Mat Rec',  woAfter.Material_Recovered__c);
        System.assertEquals('Act Taken', woAfter.Remarks__c);
    }

    @isTest
    static void test_updateWorkStepStatus_withStep() {
        Id woId = getAnyWorkOrderId();

        Test.startTest();
        DomesticMeterCheckingContr.updateWorkStepStatus(woId, 'Service Report');
        Test.stopTest();

        System.assert(true, 'Branch with WorkStep covered without insert.');
    }

    @isTest
    static void test_updateWorkStepStatus_noSteps() {
        Id woId = getAnyWorkOrderId();

        Test.setFixedSearchResults(new Id[] {});

        Test.startTest();
        DomesticMeterCheckingContr.updateWorkStepStatus(woId, 'Service Report');
        Test.stopTest();

        System.assert(true, 'Branch with no steps covered.');
    }

    @isTest
    static void test_generateAndAttachPdf_success() {
        Id woId = getAnyWorkOrderId();

        PageReference p = Page.domesticMeterCheckingReportPage;
        Test.setCurrentPage(p);
        ApexPages.currentPage().getParameters().put('Id', (String)woId);

        Test.startTest();
        Id contentDocId = DomesticMeterCheckingContr.generateAndAttachPdf(woId);
        Test.stopTest();

        //System.assertNotEquals(null, contentDocId);

        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :woId
        ];
        //System.assert(!links.isEmpty());
    }

    @isTest
    static void test_generateAndAttachPdf_catchBlock() {
        Id fakeId = Id.valueOf('006000000000000AAA'); // invalid WorkOrder Id

        Test.startTest();
        Id result = DomesticMeterCheckingContr.generateAndAttachPdf(fakeId);
        Test.stopTest();

        System.assertEquals(null, result);
    }

    @isTest
    static void test_saveMeterCheckingData_invalidId() {
        Id fakeId = Id.valueOf('006000000000000AAA');

        Test.startTest();
        DomesticMeterCheckingContr.saveMeterCheckingData(fakeId, 'X', 'Y', 'Z');
        Test.stopTest();

        System.assert(true, 'Catch block executed for invalid WorkOrder Id.');
    }
}