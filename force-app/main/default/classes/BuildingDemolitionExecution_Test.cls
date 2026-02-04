@isTest
private class BuildingDemolitionExecution_Test {

    // Utility: Create Account + WorkOrder
    private static WorkOrder createTestWorkOrder() {
        Account acc = new Account(Name = 'Test Account', Meter_Number__c = 'MTR-12345');
        insert acc;

        WorkOrder wo = new WorkOrder(
            AccountId = acc.Id,
            Subject = 'Demo WO',
            Status = 'Open'
        );
        insert wo;

        return wo;
    }

    @isTest
    static void testValidateMeterApex() {
        WorkOrder wo = createTestWorkOrder();

        // Case 1: Valid meter number
        BuildingDemolitionExecutionController.ValidationResult res1 =
            BuildingDemolitionExecutionController.validateMeterApex(wo.Id, 'MTR-12345');
        System.assertEquals(true, res1.isValid);
        System.assertEquals('Valid', res1.message);

        // Case 2: Invalid meter number
        BuildingDemolitionExecutionController.ValidationResult res2 =
            BuildingDemolitionExecutionController.validateMeterApex(wo.Id, 'WRONG');
        System.assertEquals(false, res2.isValid);

        // Case 3: Account without meter number
        Account acc2 = new Account(Name = 'No Meter');
        insert acc2;
        WorkOrder wo2 = new WorkOrder(AccountId = acc2.Id, Subject = 'Demo WO 2', Status = 'Open');
        insert wo2;
        BuildingDemolitionExecutionController.ValidationResult res3 =
            BuildingDemolitionExecutionController.validateMeterApex(wo2.Id, 'ANY');
        System.assertEquals(false, res3.isValid);
    }

    @isTest
    static void testUpdateWorkOrder() {
        WorkOrder wo = createTestWorkOrder();

        Test.startTest();
        BuildingDemolitionExecutionController.updateWorkOrder(
            wo.Id,
            'MP ENDCAP',
            'Okay',
            'All Good',
            111,      // meter number (ignored)
            456,      // meter reading
            Date.today(),
            10,       // trench volume
            20,       // pipeline length
            'MP',
            '30'
        );
        Test.stopTest();

       
    }

    @isTest
    static void testSaveMaterialDetails() {
        WorkOrder wo = createTestWorkOrder();

        BuildingDemolitionExecutionController.MaterialWrapper mw = 
            new BuildingDemolitionExecutionController.MaterialWrapper();
        mw.itemDescription = 'Copper Elbow 12 mm';
        mw.unit = 'Nos';
        mw.quantity = 5;

        List<BuildingDemolitionExecutionController.MaterialWrapper> materials = new List<BuildingDemolitionExecutionController.MaterialWrapper>{mw};

        Test.startTest();
        BuildingDemolitionExecutionController.saveMaterialDetails(wo.Id, materials);
        Test.stopTest();

    }

    @isTest
    static void testGetItemDescriptionOptions() {
        Test.startTest();
        List<String> options = BuildingDemolitionExecutionController.getItemDescriptionOptions();
        Test.stopTest();

    }

    @isTest
    static void testSavePhotoUploads() {
        WorkOrder wo = createTestWorkOrder();
         // Create test WorkPlan
        WorkPlan testWorkPlan = new WorkPlan(
            Name = 'Test WorkPlan',
            WorkOrderId = wo.Id
        );
        insert testWorkPlan;
        // Create WorkStep so updateWorkStepStatus is also covered
         List<WorkStep> workSteps = new List<WorkStep>();
        workSteps.add(new WorkStep(
            Name = 'BP Execution Details',
            WorkPlanId = testWorkPlan.Id,
            Status = 'New'
        ));
        workSteps.add(new WorkStep(
            Name = 'Other Step',
            WorkPlanId = testWorkPlan.Id,
            Status = 'New'
        ));
        insert workSteps;

        // Simulate a photo file
        BuildingDemolitionExecutionController.PhotoWrapper pw = new BuildingDemolitionExecutionController.PhotoWrapper();
        pw.fileName = 'testFile.png';
        pw.label = 'Test Photo';
        pw.base64Data = EncodingUtil.base64Encode(Blob.valueOf('dummy data'));

        List<BuildingDemolitionExecutionController.PhotoWrapper> listFiles = new List<BuildingDemolitionExecutionController.PhotoWrapper>{pw};

        Test.startTest();
        String result = BuildingDemolitionExecutionController.savePhotoUploads(wo.Id, listFiles);
        Test.stopTest();
       
    }
}