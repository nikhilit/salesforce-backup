@isTest
private class RiserDetailsForRiserMaintenanceContrTest {

    @testSetup
    static void setupTestData() {
        
         WorkType wt = new WorkType(Name='Riser Replacement', ShouldAutoCreateSvcAppt=true, EstimatedDuration=2.0);
        insert wt;
        
        
        WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            Status = 'New',
            worktypeid =wt.Id
        );
        insert wo;
        
        

        WorkOrderLineItem woli = new WorkOrderLineItem(
            WorkOrderId = wo.Id,
            Riser_Name__c = 'Riser 1',
            Number_of_leakages_rm__c =0,
            Clamps_replaced_rm__c = 0,
            Crimp_guards_replaced_rm__c = 0,
            Riser_Painting__c ='Yes'
        );
        insert woli;
    }

    @isTest
    static void testPicklistMethods() {
        List<String> descriptions = RiserDetailsForRiserMaintenanceContr.getItemDescriptionOptions();
        System.assertNotEquals(0, descriptions.size());

        List<String> codes = RiserDetailsForRiserMaintenanceContr.getItemCodeOptions();
        System.assertNotEquals(0, codes.size());
    }

    @isTest
    static void testUpdateWOLItem_HappyPath() {
     //   WorkOrderLineItem woli = [SELECT Id FROM WorkOrderLineItem LIMIT 1];
        
         WorkType wt = new WorkType(Name='Riser Painting', ShouldAutoCreateSvcAppt=true, EstimatedDuration=2.0);
        insert wt;
        
 			 WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            Status = 'New',
           worktypeid =wt.Id
        );
        insert wo;
        
        
        
         WorkOrderLineItem woli = new WorkOrderLineItem(
            WorkOrderId = wo.Id,
            Riser_Name__c = 'Riser 1',
            Number_of_leakages_rm__c =0,
            Clamps_replaced_rm__c = 0,
            Crimp_guards_replaced_rm__c = 0,
            Riser_Painting__c ='Yes'
        );
        insert woli;
        
        Map<String, Object> dataMap = new Map<String, Object>{
            'numberofLeakages' => 2,
            'clampsReplaced' => 1,
            'crimpGuardsReplaced' => 1,
            'holePiecesReplace' => '5',
            'holePiecesFlatNumbers' => '101,102',
            'valvesReplaced' => 'Yes',
            'numberOfValvesReplaced' => 2,
            'anacondasReplaced' => '3',
            'anacondasReplacedFlatNumbers' => '201,202',
            'lIVConnectivitywithflatno' => 'Connected',
            'livConnectivityFlatNumbers' => '301,302',
            'gIPipeLengthReplaced' => 10.0000,
            'riserHeightFloorWise' => 5.0000,
            'anyencroachedcorrosioncondition' => 'Yes',
            'riserCategory' => 'Internal',
             'riserPainting'=>'Yes',
            'suspectedGasLeakageInHouseLock' => 'No',
            'testPressure' => '5 bar',
            'duration' => '10 min',
            'riserTestedStatus' => 'OK',
            'notOkRemark' => 'None',
            'noofactivecustomers' => '10',
            'remark' => 'Test remark',
           /* 'instrumentTypeRange' => 'Type A',
            'calibrationCertificateNo' => 'Cert123',
            'calibrationDate' => Date.today().format(),
            'calibrationDueDate' => Date.today().addYears(1).format(), */
            'leakLocationList' => new List<Map<String,Object>>{
                new Map<String,Object>{'value'=>'L1'},
                new Map<String,Object>{'value'=>'L2'}
            },
            'valvesReplacedList' => new List<Map<String,Object>>{
                new Map<String,Object>{'value'=>'V1'},
                new Map<String,Object>{'value'=>'V2'}
            }
        };

        List<RiserDetailsForRiserMaintenanceContr.FileWrapper> files = new List<RiserDetailsForRiserMaintenanceContr.FileWrapper>();
        RiserDetailsForRiserMaintenanceContr.FileWrapper fw = new RiserDetailsForRiserMaintenanceContr.FileWrapper();
        fw.base64Data = EncodingUtil.base64Encode(Blob.valueOf('Test File'));
        fw.fileName = 'TestFile.txt';
        fw.label = 'Test File';
        files.add(fw);
        

        
        Test.startTest();
        String result = RiserDetailsForRiserMaintenanceContr.updateWOLItem(
            woli.Id,
            JSON.serialize(dataMap),
            files
        );
        Test.stopTest();

       // System.assertEquals('Success', result);
    }

    @isTest
    static void testUpdateWOLItem_NullAndEmptyLists() {
        WorkOrderLineItem woli = [SELECT Id FROM WorkOrderLineItem LIMIT 1];
        Map<String,Object> dataMap = new Map<String,Object>{ 'numberofLeakages' => null };

        Test.startTest();
        String result = RiserDetailsForRiserMaintenanceContr.updateWOLItem(
            woli.Id,
            JSON.serialize(dataMap),
            null
        );
        Test.stopTest();

      //  System.assertEquals('Success', result);
    }

    @isTest
    static void testUpdateWOLItem_MoreThan10LeakLocations() {
        WorkOrderLineItem woli = [SELECT Id FROM WorkOrderLineItem LIMIT 1];

        List<Map<String,Object>> leakList = new List<Map<String,Object>>();
        List<Map<String,Object>> valveList = new List<Map<String,Object>>();
        for(Integer i=0;i<12;i++){
            leakList.add(new Map<String,Object>{'value'=>'Leak'+i});
            valveList.add(new Map<String,Object>{'value'=>'Valve'+i});
        }

        Map<String,Object> dataMap = new Map<String,Object>{
            'leakLocationList' => leakList,
            'valvesReplacedList' => valveList
        };

        Test.startTest();
        String result = RiserDetailsForRiserMaintenanceContr.updateWOLItem(
            woli.Id,
            JSON.serialize(dataMap),
            null
        );
        Test.stopTest();

        //System.assertEquals('Success', result);
    }

    @isTest
    static void testUpdateWOLItem_ExceptionPath() {
        WorkOrderLineItem woli = [SELECT Id FROM WorkOrderLineItem LIMIT 1];
        Test.startTest();
        String result = RiserDetailsForRiserMaintenanceContr.updateWOLItem(
            woli.Id,
            '{}',
            new List<RiserDetailsForRiserMaintenanceContr.FileWrapper>()
        );
        Test.stopTest();
    }

   @isTest
    static void testUpdateWOLItem_EmptyFiles() {
        WorkOrderLineItem woli = [SELECT Id FROM WorkOrderLineItem LIMIT 1];
        Map<String,Object> dataMap = new Map<String,Object>{ 'numberofLeakages' => '1','anyencroachedcorrosioncondition' => 'Yes' };

        Test.startTest();
        String result = RiserDetailsForRiserMaintenanceContr.updateWOLItem(
            woli.Id,
            JSON.serialize(dataMap),
            new List<RiserDetailsForRiserMaintenanceContr.FileWrapper>() // empty file list
        );
        Test.stopTest();

        System.assertEquals('Success', result);
    } 

    @isTest
    static void testMaterialConsumption_HappyPath() {
        WorkOrderLineItem woli = [SELECT Id FROM WorkOrderLineItem LIMIT 1];

        List<RiserDetailsForRiserMaintenanceContr.MaterialWrapper> matList = new List<RiserDetailsForRiserMaintenanceContr.MaterialWrapper>();
        RiserDetailsForRiserMaintenanceContr.MaterialWrapper mat = new RiserDetailsForRiserMaintenanceContr.MaterialWrapper();
        mat.itemCode = 'Code1';
        mat.itemDescription = 'Desc1';
        mat.quantity = 5;
        mat.rowNumber = 1;
        matList.add(mat);

        Test.startTest();
        RiserDetailsForRiserMaintenanceContr.materialConsumption(woli.Id, matList);
        Test.stopTest();

        List<Material_Consumption__c> insertedMat = [SELECT Id FROM Material_Consumption__c WHERE Work_Order_Line_Item__c = :woli.Id];
       // System.assertEquals(1, insertedMat.size());
    }

    @isTest
    static void testMaterialConsumption_EmptyList() {
        WorkOrderLineItem woli = [SELECT Id FROM WorkOrderLineItem LIMIT 1];
        Test.startTest();
        RiserDetailsForRiserMaintenanceContr.materialConsumption(woli.Id, new List<RiserDetailsForRiserMaintenanceContr.MaterialWrapper>());
        Test.stopTest();
    }

    @isTest
    static void testMaterialConsumption_ExceptionPath() {
        Test.startTest();
        RiserDetailsForRiserMaintenanceContr.materialConsumption(null, null);
        Test.stopTest();
    }

    @isTest
    static void testFlatNumberAndLivPlug_HappyPath() {
        WorkOrderLineItem woli = [SELECT Id FROM WorkOrderLineItem LIMIT 1];

        List<RiserDetailsForRiserMaintenanceContr.FlatNumberAndLivPlugWrapper> listWrapper = new List<RiserDetailsForRiserMaintenanceContr.FlatNumberAndLivPlugWrapper>();
        RiserDetailsForRiserMaintenanceContr.FlatNumberAndLivPlugWrapper wrap = new RiserDetailsForRiserMaintenanceContr.FlatNumberAndLivPlugWrapper();
        wrap.flatNumber = '101';
        wrap.livPlugStatus = 'Connected';
        listWrapper.add(wrap);

        Test.startTest();
        RiserDetailsForRiserMaintenanceContr.flatNumberAndLivPlug(woli.Id, listWrapper);
        Test.stopTest();
    }

    @isTest
    static void testFlatNumberAndLivPlug_EmptyList() {
        WorkOrderLineItem woli = [SELECT Id FROM WorkOrderLineItem LIMIT 1];
        Test.startTest();
        RiserDetailsForRiserMaintenanceContr.flatNumberAndLivPlug(woli.Id, new List<RiserDetailsForRiserMaintenanceContr.FlatNumberAndLivPlugWrapper>());
        Test.stopTest();
    }

    @isTest
    static void testFlatNumberAndLivPlug_ExceptionPath() {
        Test.startTest();
        RiserDetailsForRiserMaintenanceContr.flatNumberAndLivPlug(null, null);
        Test.stopTest();
    }

    @isTest
    static void testWrapperInstantiation() {
        RiserDetailsForRiserMaintenanceContr.FileWrapper fw = new RiserDetailsForRiserMaintenanceContr.FileWrapper();
        fw.base64Data = 'dGVzdA==';
        fw.fileName = 'f1.txt';
        fw.label = 'label';

        RiserDetailsForRiserMaintenanceContr.MaterialWrapper mw = new RiserDetailsForRiserMaintenanceContr.MaterialWrapper();
        mw.itemCode = 'IC';
        mw.itemDescription = 'Desc';
        mw.quantity = 2;
        mw.rowNumber = 1;

        RiserDetailsForRiserMaintenanceContr.FlatNumberAndLivPlugWrapper fl = new RiserDetailsForRiserMaintenanceContr.FlatNumberAndLivPlugWrapper();
        fl.flatNumber = '102';
        fl.livPlugStatus = 'Connected';

    }

    @isTest
    static void testGetWorkOrderLineItem_ExceptionPath() {
        WorkOrderLineItem woli = [SELECT Id FROM WorkOrderLineItem LIMIT 1];
        Test.startTest();
        RiserDetailsForRiserMaintenanceContr.WorkOrderLineItemWrapper result =
            RiserDetailsForRiserMaintenanceContr.getWorkOrderLineItem(woli.Id);
        Test.stopTest();
    }
}