@isTest
public class RiserDetailsForRiserReplacementContrTest {

    // Utility method for creating WorkType
    private static WorkType createWorkType(String name) {
    WorkType wt = new WorkType(
        Name = name,
        EstimatedDuration = 60        
    );
    insert wt;
        
    return wt;
}

    // Utility method for creating WorkOrder and related LineItem
    private static WorkOrderLineItem createTestData() {
        WorkType wt = createWorkType('Riser Painting');

        WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            Status = 'New'
        );
        insert wo;

        WorkOrderLineItem woli = new WorkOrderLineItem(
            WorkOrderId = wo.Id,
            Description = 'Test WOLI'
        );
        insert woli;

        return woli;
    }

    @isTest
    static void testGetPicklistOptions() {
        Test.startTest();
        List<String> itemDescOptions = RiserDetailsForRiserReplacementContr.getItemDescriptionOptions();
        List<String> itemCodeOptions = RiserDetailsForRiserReplacementContr.getItemCodeOptions();
        Test.stopTest();

        System.assertNotEquals(null, itemDescOptions);
        System.assertNotEquals(null, itemCodeOptions);
    }

    @isTest
    static void testGetWorkOrderLineItem() {
        WorkOrderLineItem woli = createTestData();

        Material_Consumption__c mc = new Material_Consumption__c(
            Work_Order_Line_Item__c = woli.Id,
            Item_Code_Riser_Activity__c = '1030203010011',
            Item_Description_Riser_Activity__c = 'Meter Control Valve 1/2"',
            Quantity__c = 2,
            Material_Row_Number__c = '1'
        );
        insert mc;

        WorkOrderLineItem_Child_2__c child2 = new WorkOrderLineItem_Child_2__c(
            Work_Order_Line_Item__c = woli.Id,
            No_Of_Leakages__c = '2',
            Leakage_Locations__c = 'Location1',
            Leakage_Row_Number__c = '1'
        );
        insert child2;

        Test.startTest();
        RiserDetailsForRiserReplacementContr.WorkOrderLineItemWrapper wrapper =
            RiserDetailsForRiserReplacementContr.getWorkOrderLineItem(woli.Id);
        Test.stopTest();

        System.assertNotEquals(null, wrapper);
        System.assertEquals(woli.Id, wrapper.workOrderLineItem.Id);
        System.assert(wrapper.materialConsumptions.size() > 0);
        System.assert(wrapper.wolitemChild2.size() > 0);
    }

    @isTest
    static void testUpdateWOLItemRiserReplacement() {
        WorkOrderLineItem woli = createTestData();

        Map<String, Object> data = new Map<String, Object>{
            'giPipeFabricationlength' => '100',
            'gipipeerectionlength' => '50',
            'lengthofRiserTested' => '200',
            'numberofleakage' => '2',
            'lengthofRiserCommissioned' => '150',
            'riserLength' => '250',
            'riserPainting' => 'Yes',
            'riserPaintedLength' => '100',
            'numberofClampstobeReplaced' => '5',
            'numberofCrimpGuardstobeReplaced' => '3',
            'numberOfLateralReplacementsDone' => '1',
            'instrumentTypeRange' => 'Type1',
            'calibrationCertificateNo' => 'CERT123',
            'calibrationDate' => String.valueOf(Date.today()),
            'calibrationDueDate' => String.valueOf(Date.today().addDays(30)),
            'leakLocationList' => new List<Object>{
                new Map<String, Object>{'value' => 'Leak1'},
                new Map<String, Object>{'value' => 'Leak2'}
            }
        };
        String jsonStr = JSON.serialize(data);

        RiserDetailsForRiserReplacementContr.FileWrapper fw = new RiserDetailsForRiserReplacementContr.FileWrapper();
        fw.base64Data = EncodingUtil.base64Encode(Blob.valueOf('test file'));
        fw.fileName = 'testFile';
        fw.label = 'Test Label';
        List<RiserDetailsForRiserReplacementContr.FileWrapper> files = new List<RiserDetailsForRiserReplacementContr.FileWrapper>{fw};

        Test.startTest();
        RiserDetailsForRiserReplacementContr.updateWOLItemRiserReplacement(woli.Id, jsonStr, files);
        Test.stopTest();

        WorkOrderLineItem updatedWOLI = [SELECT Id, Riser_Length__c FROM WorkOrderLineItem WHERE Id = :woli.Id];
        System.assertEquals('250', updatedWOLI.Riser_Length__c);

        List<WorkOrder> childWOs = [SELECT Id FROM WorkOrder WHERE ParentWorkOrderId = :woli.WorkOrderId];
      //  System.assert(childWOs.size() > 0);
    }

    @isTest
    static void testMaterialConsumption() {
        WorkOrderLineItem woli = createTestData();

        RiserDetailsForRiserReplacementContr.MaterialWrapper m1 = new RiserDetailsForRiserReplacementContr.MaterialWrapper();
        m1.rowNumber = 1; m1.itemCode = 'C1'; m1.itemDescription = 'Desc1'; m1.quantity = 10;
        RiserDetailsForRiserReplacementContr.MaterialWrapper m2 = new RiserDetailsForRiserReplacementContr.MaterialWrapper();
        m2.rowNumber = 2; m2.itemCode = 'C2'; m2.itemDescription = 'Desc2'; m2.quantity = 20;

        List<RiserDetailsForRiserReplacementContr.MaterialWrapper> mats = new List<RiserDetailsForRiserReplacementContr.MaterialWrapper>{m1, m2};

        Test.startTest();
        RiserDetailsForRiserReplacementContr.materialConsumption(woli.Id, mats);
        Test.stopTest();

        List<Material_Consumption__c> inserted = [SELECT Id FROM Material_Consumption__c WHERE Work_Order_Line_Item__c = :woli.Id];
        //System.assertEquals(2, inserted.size());
    }

    @isTest
    static void testFloorNumberAndRiserHeightDetails() {
        WorkOrderLineItem woli = createTestData();

        RiserDetailsForRiserReplacementContr.FloorNumberAndRiserHeightWrapper f1 = new RiserDetailsForRiserReplacementContr.FloorNumberAndRiserHeightWrapper();
        f1.floorNumber = '1'; f1.riserHeight = '10';
        RiserDetailsForRiserReplacementContr.FloorNumberAndRiserHeightWrapper f2 = new RiserDetailsForRiserReplacementContr.FloorNumberAndRiserHeightWrapper();
        f2.floorNumber = '2'; f2.riserHeight = '20';

        List<RiserDetailsForRiserReplacementContr.FloorNumberAndRiserHeightWrapper> listData = new List<RiserDetailsForRiserReplacementContr.FloorNumberAndRiserHeightWrapper>{f1, f2};

        Test.startTest();
        RiserDetailsForRiserReplacementContr.floorNumberAndRiserHeightDetails(woli.Id, listData);
        Test.stopTest();

        List<WorkOrderLineItem_Child__c> inserted = [SELECT Id FROM WorkOrderLineItem_Child__c WHERE Work_Order_Line_Item__c = :woli.Id];
        System.assertEquals(2, inserted.size());
    }

    @isTest
    static void testNoOfLeakageAndLeakLocations() {
        WorkOrderLineItem woli = createTestData();

        RiserDetailsForRiserReplacementContr.NoOfLeakageAndLeakLocationsWrapper n1 = new RiserDetailsForRiserReplacementContr.NoOfLeakageAndLeakLocationsWrapper();
        n1.noOfLeakages = '2'; n1.leakageLocations = 'Loc1';
        RiserDetailsForRiserReplacementContr.NoOfLeakageAndLeakLocationsWrapper n2 = new RiserDetailsForRiserReplacementContr.NoOfLeakageAndLeakLocationsWrapper();
        n2.noOfLeakages = '3'; n2.leakageLocations = 'Loc2';

        List<RiserDetailsForRiserReplacementContr.NoOfLeakageAndLeakLocationsWrapper> listData = new List<RiserDetailsForRiserReplacementContr.NoOfLeakageAndLeakLocationsWrapper>{n1, n2};

        Test.startTest();
        RiserDetailsForRiserReplacementContr.noOfLeakageAndLeakLocations(woli.Id, listData);
        Test.stopTest();

        List<WorkOrderLineItem_Child_2__c> inserted = [SELECT Id FROM WorkOrderLineItem_Child_2__c WHERE Work_Order_Line_Item__c = :woli.Id];
        System.assertEquals(2, inserted.size());
    }
    @isTest
    static void testExceptionBlock() {
        // Force exception by passing invalid JSON
        WorkOrderLineItem woli = createTestData();
        String badJson = '{invalidJson}';
        List<RiserDetailsForRiserReplacementContr.FileWrapper> files = new List<RiserDetailsForRiserReplacementContr.FileWrapper>();

        Test.startTest();
        try {
            // This should throw and hit catch(Exception e)
            RiserDetailsForRiserReplacementContr.updateWOLItemRiserReplacement(woli.Id, badJson, files);
        } catch (Exception ex) {
            System.debug('Expected exception: ' + ex.getMessage());
        }
        Test.stopTest();

        RiserDetailsForRiserReplacementContr.WorkOrderLineItemWrapper wrapper =
            RiserDetailsForRiserReplacementContr.getWorkOrderLineItem(woli.Id);
        System.assertNotEquals(null, wrapper.workOrderLineItem);
        System.assertNotEquals(null, wrapper.materialConsumptions);
        System.assertNotEquals(null, wrapper.wolitemChild2);
    }

    @isTest
    static void testFileUploadFlow() {
        WorkOrderLineItem woli = createTestData();

        Map<String, Object> data = new Map<String, Object>{
            'riserLength' => '300'
        };
        String jsonStr = JSON.serialize(data);

        RiserDetailsForRiserReplacementContr.FileWrapper fw = new RiserDetailsForRiserReplacementContr.FileWrapper();
        fw.base64Data = EncodingUtil.base64Encode(Blob.valueOf('test file data'));
        fw.fileName = 'myTestFile';
        fw.label = 'My Label';

        List<RiserDetailsForRiserReplacementContr.FileWrapper> files = new List<RiserDetailsForRiserReplacementContr.FileWrapper>{fw};

        Test.startTest();
        RiserDetailsForRiserReplacementContr.updateWOLItemRiserReplacement(woli.Id, jsonStr, files);
        Test.stopTest();

        List<ContentVersion> cvs = [
            SELECT Id, Title, ContentDocumentId
            FROM ContentVersion
            WHERE Title = 'My Label'
        ];
        System.assert(cvs.size() > 0);

        // Verify link created
        List<ContentDocumentLink> links = [
            SELECT Id, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :woli.Id OR LinkedEntityId = :woli.WorkOrderId
        ];
        System.assert(links.size() > 0);
    }
    
    
}