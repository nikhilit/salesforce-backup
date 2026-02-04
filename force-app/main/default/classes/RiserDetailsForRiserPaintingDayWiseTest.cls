@IsTest
public class RiserDetailsForRiserPaintingDayWiseTest {

    @TestSetup
    static void setupTestData() {

        // Get valid picklist value for Riser_Category__c
        List<Schema.PicklistEntry> riserCategoryPicklist = WorkOrderLineItem.Riser_Category__c.getDescribe().getPicklistValues();
        String validRiserCategory = riserCategoryPicklist.isEmpty() ? null : riserCategoryPicklist[0].getValue();

        // Get valid picklist value for Item_Code_Riser_Activity__c
        List<Schema.PicklistEntry> itemCodePicklist = Material_Consumption__c.Item_Code_Riser_Activity__c.getDescribe().getPicklistValues();
        String validItemCode = itemCodePicklist.isEmpty() ? null : itemCodePicklist[0].getValue();

        // Get valid picklist value for Item_Description_Riser_Activity__c
        List<Schema.PicklistEntry> itemDescPicklist = Material_Consumption__c.Item_Description_Riser_Activity__c.getDescribe().getPicklistValues();
        String validItemDesc = itemDescPicklist.isEmpty() ? null : itemDescPicklist[0].getValue();

        // Create WorkOrder
        WorkOrder wo = new WorkOrder(
            Status = 'New',
            Subject = 'Test WO',
            Number_of_Risers__c = '5'
        );
        insert wo;

        // Create WorkOrderLineItem
        WorkOrderLineItem woli = new WorkOrderLineItem(
            WorkOrderId = wo.Id,
            Riser_Category__c = validRiserCategory
        );
        insert woli;

        // Create Material_Consumption__c
        Material_Consumption__c mat = new Material_Consumption__c(
            Work_Order_Line_Item__c = woli.Id,
            Item_Code_Riser_Activity__c = validItemCode,
            Item_Description_Riser_Activity__c = validItemDesc,
            Quantity__c = 10,
            Material_Row_Number__c = '1'
        );
        insert mat;

        // Create WorkOrderLineItem_Child__c
        WorkOrderLineItem_Child__c child1 = new WorkOrderLineItem_Child__c(
            Work_Order_Line_Item__c = woli.Id,
            Floor_Number__c = '1',
            Riser_Height__c = '10',
            WOLItemChild_Row_Number__c = '1'
                     
        );
        insert child1;

        // Create WorkOrderLineItem_Child_2__c
        WorkOrderLineItem_Child_2__c child2 = new WorkOrderLineItem_Child_2__c(
            Work_Order_Line_Item__c = woli.Id,
            No_Of_Leakages__c = '2',
            Leakage_Locations__c = 'Location1',
            Leakage_Row_Number__c = '1'
            
        );
        insert child2;
    }

    @IsTest
    static void testPicklistMethods() {
        Test.startTest();
        List<String> itemDescOptions = RiserDetailsForRiserPaintingDayWiseContr.getItemDescriptionOptions();
        List<String> itemCodeOptions = RiserDetailsForRiserPaintingDayWiseContr.getItemCodeOptions();
        Test.stopTest();
        System.assertNotEquals(0, itemDescOptions.size());
        System.assertNotEquals(0, itemCodeOptions.size());
    }

    @IsTest
    static void testGetWorkOrderLineItem() {
        WorkOrderLineItem woli = [SELECT Id FROM WorkOrderLineItem LIMIT 1];
        Test.startTest();
       // RiserDetailsForRiserPaintingDayWiseContr.WorkOrderLineItemWrapper wrapper =
         //   RiserDetailsForRiserPaintingDayWiseContr.getWorkOrderLineItem(woli.Id);
        Test.stopTest();
      
    }

    @IsTest
    static void testGetNumberOfRisersWO() {
        WorkOrderLineItem woli = [SELECT Id FROM WorkOrderLineItem LIMIT 1];
        Test.startTest();
      //  String numRisers = RiserDetailsForRiserPaintingDayWiseContr.getNumberOfRisersWO(woli.Id);
        Test.stopTest();
      //  System.assertEquals('5', numRisers);
    }
     @IsTest
    static void savePaintingNotPossibleTest() {
        WorkOrderLineItem woli = [SELECT Id,Is_Riser_Painting_Possible__c,Riser_Painting_Not_Possible_Remark__c FROM WorkOrderLineItem LIMIT 1];
        string wolitemId = woli.Id;
        Test.startTest();
     RiserDetailsForRiserPaintingDayWiseContr.savePaintingNotPossible(wolitemId,woli.Riser_Painting_Not_Possible_Remark__c);
        Test.stopTest();
      //  System.assertEquals('5', numRisers);
    }

    @IsTest
    static void testUpdateWOLItemRiserPainting() {
        WorkOrderLineItem woli = [SELECT Id, Riser_Category__c FROM WorkOrderLineItem LIMIT 1];

        // Use existing picklist value for riserCategory update
        String updatedRiserCategory = woli.Riser_Category__c;

        Map<String, Object> dataMap = new Map<String, Object>{
            'riserCategory' => updatedRiserCategory,
            'noOfClampsReplaced' => '3',
            'noofCrimpGuardsReplaced' => '4',
            'lengthPaintedPrimer' => '100',
            'dFTReadingPrimer' => '10',
            'lengthPaintedYellow' => '50',
            'dFTReadingYellow' => '5',
            'lengthPaintedYellow3' => '30',
            'dFTReadingYellow3' => '3',
            'instrumentTypeRange' => 'Range1',
            'calibrationCertificateNo' => 'Cert123',
            'calibrationDate' => '2025-08-20',
            'calibrationDueDate' => '2025-09-20'
        };

        RiserDetailsForRiserPaintingDayWiseContr.FileWrapper fileWrapper = 
            new RiserDetailsForRiserPaintingDayWiseContr.FileWrapper();
        fileWrapper.base64Data = EncodingUtil.base64Encode(Blob.valueOf('test'));
        fileWrapper.fileName = 'testFile';
        fileWrapper.label = 'Test File';

        Test.startTest();
        RiserDetailsForRiserPaintingDayWiseContr.updateWOLItemRiserPainting(
            woli.Id,
            JSON.serialize(dataMap),
            new List<RiserDetailsForRiserPaintingDayWiseContr.FileWrapper>{fileWrapper}
        );
        Test.stopTest();

        WorkOrderLineItem updatedWOLI = [SELECT Riser_Category__c,Clamps_Replaced__c FROM WorkOrderLineItem WHERE Id=:woli.Id];
        System.assertEquals(updatedRiserCategory, updatedWOLI.Riser_Category__c);
    }
     

    @IsTest
    static void testMaterialConsumption() {
        WorkOrderLineItem woli = [SELECT Id FROM WorkOrderLineItem LIMIT 1];

        // Get valid picklist values for material insert
        List<Schema.PicklistEntry> itemCodePicklist = Material_Consumption__c.Item_Code_Riser_Activity__c.getDescribe().getPicklistValues();
        String validItemCode = itemCodePicklist.isEmpty() ? null : itemCodePicklist[0].getValue();
        List<Schema.PicklistEntry> itemDescPicklist = Material_Consumption__c.Item_Description_Riser_Activity__c.getDescribe().getPicklistValues();
        String validItemDesc = itemDescPicklist.isEmpty() ? null : itemDescPicklist[0].getValue();

        RiserDetailsForRiserPaintingDayWiseContr.MaterialWrapper matWrapper = 
            new RiserDetailsForRiserPaintingDayWiseContr.MaterialWrapper();
        matWrapper.rowNumber = 2;
        matWrapper.itemCode = validItemCode;
        matWrapper.itemDescription = validItemDesc;
        matWrapper.quantity = 15;

        Test.startTest();
      //  RiserDetailsForRiserPaintingDayWiseCont.materialConsumption(
        //    woli.Id,
        //    new List<RiserDetailsForRiserPaintingDayWiseContr.MaterialWrapper>{matWrapper}
      //  );
        Test.stopTest();

        List<Material_Consumption__c> insertedMats = [
            SELECT Id,Item_Code_Riser_Activity__c FROM Material_Consumption__c WHERE Work_Order_Line_Item__c=:woli.Id
        ];
       // System.assert(insertedMats.size() > 1);
    }

   /* @IsTest
    static void testFloorNumberAndRiserHeightDetails() {
        WorkOrderLineItem woli = [SELECT Id FROM WorkOrderLineItem LIMIT 1];

        RiserDetailsForRiserPaintingContr.FloorNumberAndRiserHeightWrapper wrapper = 
            new RiserDetailsForRiserPaintingContr.FloorNumberAndRiserHeightWrapper();
        wrapper.rowNumber = 2;
        wrapper.floorNumber = '2';
        wrapper.riserHeight = '20';

        Test.startTest();
        RiserDetailsForRiserPaintingContr.floorNumberAndRiserHeightDetails(
            woli.Id,
            new List<RiserDetailsForRiserPaintingContr.FloorNumberAndRiserHeightWrapper>{wrapper}
        );
        Test.stopTest();

        List<WorkOrderLineItem_Child__c> children = [
            SELECT Id FROM WorkOrderLineItem_Child__c WHERE Work_Order_Line_Item__c=:woli.Id
        ];
       // System.assert(children.size() > 1);
    } */

  /*  @IsTest
    static void testNoOfLeakageAndLeakLocations() {
        WorkOrderLineItem woli = [SELECT Id FROM WorkOrderLineItem LIMIT 1];

        RiserDetailsForRiserPaintingContr.NoOfLeakageAndLeakLocationsWrapper wrapper = 
            new RiserDetailsForRiserPaintingContr.NoOfLeakageAndLeakLocationsWrapper();
        wrapper.rowNumber = 2;
        wrapper.noOfLeakages = '3';
        wrapper.leakageLocations = 'LeakLoc2';

        Test.startTest();
        RiserDetailsForRiserPaintingContr.noOfLeakageAndLeakLocations(
            woli.Id,
            new List<RiserDetailsForRiserPaintingContr.NoOfLeakageAndLeakLocationsWrapper>{wrapper}
        ); 
        Test.stopTest();

        List<WorkOrderLineItem_Child_2__c> children = [
            SELECT Id FROM WorkOrderLineItem_Child_2__c WHERE Work_Order_Line_Item__c=:woli.Id
        ]; 
    } */
}