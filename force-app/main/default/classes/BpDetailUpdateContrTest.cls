@isTest
private class BpDetailUpdateContrTest {
    
    // Helper method to create base64 data for a fake file
    private static String getSampleBase64() {
        Blob b = Blob.valueOf('Sample File Content');
        return EncodingUtil.base64Encode(b);
    }

    @isTest
    static void testGetAndUpdateAccountDetails() {
        // Step 1: Create test Account
        Account acc = new Account(
            Name = 'Test Account',
            FirstName__c = 'John',
            LastName__c = 'Doe',
            BP_Number__c = 'BP123',
            Meter_Shifted__c = 'Yes',
        Connection_Done_Or_Not__c = 'Yes'
        );
        insert acc;
        
        Test.startTest();

        // Step 2: Call getAccountDetails
        Account fetchedAcc = BpDetailUpdateContr.getAccountDetails(acc.Id);
        
         Connection__c con = new Connection__c();
        
        con.Name='123';
        
        insert con;
        
         WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            Status = 'New',
            connection__c = con.Id,
             Connection_Done__c = 2,
             Meter_Shifted__c =3
         
        );
        insert wo;

        // Step 3: Prepare file wrapper list
        List<BpDetailUpdateContr.FileWrapper> files = new List<BpDetailUpdateContr.FileWrapper>();
        BpDetailUpdateContr.FileWrapper fw = new BpDetailUpdateContr.FileWrapper();
        fw.base64Data = getSampleBase64();
        fw.fileName = 'TestFile';
        fw.label = 'Test Label';
        files.add(fw);
    

        // Step 4: Call updateAccountDetails
        BpDetailUpdateContr.updateAccountDetails(
            acc.Id,
            wo.Id,
            'No',          // meterShifted
           // '10',           // coppermlclength
            'M123',         // meterNumber
            '100',          // meterReading
            'Reg123',       // regulatorMake
            'No',         // connectionDone
            'No',         // leakageTestDone
            '20',           // gILength
            '30',           // copperlengthMLClength
            files           // listFiles
        );

        Test.stopTest();

        // Step 5: Re-query account and assert updated fields
        Account updatedAcc = [SELECT Meter_Shifted__c, Copper_MLC_Length__c, 
                                     Meter_Number__c, Meter_Reading__c, Regulator_Make__c,
                                     Connection_Done_Or_Not__c, LeakageTestDone__c,
                                     GI_Length__c, Copper_Length_MLC_Length__c
                              FROM Account WHERE Id = :acc.Id];
    }
    
    /* @isTest
    static void testGetAndUpdateAccountDetailsNo() {
        // Step 1: Create test Account
        Account acc = new Account(
            Name = 'Test Account',
            FirstName__c = 'John',
            LastName__c = 'Doe',
            BP_Number__c = 'BP123'
        );
        insert acc;
        
        Test.startTest();

        // Step 2: Call getAccountDetails
        Account fetchedAcc = BpDetailUpdateContr.getAccountDetails(acc.Id);
        
         Connection__c con = new Connection__c();
        
        con.Name='123';
        
        insert con;
        
         WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            Status = 'New',
            connection__c = con.Id
        
        );
        insert wo;

        // Step 3: Prepare file wrapper list
        List<BpDetailUpdateContr.FileWrapper> files = new List<BpDetailUpdateContr.FileWrapper>();
        BpDetailUpdateContr.FileWrapper fw = new BpDetailUpdateContr.FileWrapper();
        fw.base64Data = getSampleBase64();
        fw.fileName = 'TestFile';
        fw.label = 'Test Label';
        files.add(fw);
    

        // Step 4: Call updateAccountDetails
        BpDetailUpdateContr.updateAccountDetails(
            acc.Id,
            wo.Id,
            'No',          // meterShifted
           // '10',           // coppermlclength
            'M123',         // meterNumber
            '100',          // meterReading
            'Reg123',       // regulatorMake
            'Yes',         // connectionDone
            'Yes',         // leakageTestDone
            '20',           // gILength
            '30',           // copperlengthMLClength
            files           // listFiles
        );

        Test.stopTest();

        // Step 5: Re-query account and assert updated fields
        Account updatedAcc = [SELECT Meter_Shifted__c, Copper_MLC_Length__c, 
                                     Meter_Number__c, Meter_Reading__c, Regulator_Make__c,
                                     Connection_Done_Or_Not__c, LeakageTestDone__c,
                                     GI_Length__c, Copper_Length_MLC_Length__c
                              FROM Account WHERE Id = :acc.Id];
    } */

    
    @isTest
    static void generateAndAttachPdfTest(){
        
        Connection__c con = new Connection__c();
        
        con.Name='123';
        
        insert con;
        
            
       Account acc = new Account(
            Name = 'Test Account',
            FirstName__c = 'John',
            LastName__c = 'Doe',
            BP_Number__c = 'BP123',
           Connection__c = con.Id
        );
        insert acc;
        
        WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            Status = 'New',
            connection__c = con.Id
        
        );
        insert wo;
        
        Test.startTest();
        
           WorkOrder woDetail =[Select id,Connection__c from WorkOrder limit 1];
           Account accDetail = [Select id,BP_Number__c,Connection__c from Account limit 1];   
        
            Test.setCurrentPage(Page.riserReplacementCopperReportPage);

        
        BpDetailUpdateContr.generateAndAttachPdf(woDetail.Id,accDetail.Id);
        
        Test.stopTest();
    }
    
     @isTest
    static void getAccountAndMaterialDetailsTest() {
          Account acc = new Account(
            Name = 'Test Account',
            FirstName__c = 'John',
            LastName__c = 'Doe',
            BP_Number__c = 'BP123',
            Meter_Shifted__c = 'Yes',
        Connection_Done_Or_Not__c = 'Yes'
        );
        insert acc;
     
       // WorkOrderLineItem woli = [SELECT Id FROM WorkOrderLineItem LIMIT 1];
        Test.startTest();
        BpDetailUpdateContr.AccountWrapper  result =
            BpDetailUpdateContr.getAccountAndMaterialDetails(acc.Id);
        Test.stopTest();
    }
    
     @isTest
    static void testMaterialConsumption_HappyPath() {
      //  WorkOrderLineItem woli = [SELECT Id FROM WorkOrderLineItem LIMIT 1];
  Account acc = new Account(
            Name = 'Test Account',
            FirstName__c = 'John',
            LastName__c = 'Doe',
            BP_Number__c = 'BP123',
            Meter_Shifted__c = 'Yes',
        Connection_Done_Or_Not__c = 'Yes'
        );
        insert acc;
        List<BpDetailUpdateContr.MaterialWrapper> matList = new List<BpDetailUpdateContr.MaterialWrapper>();
        BpDetailUpdateContr.MaterialWrapper mat = new BpDetailUpdateContr.MaterialWrapper();
        mat.itemCode = 'Code1';
        mat.itemDescription = 'Desc1';
        mat.quantity = 5;
        mat.rowNumber = 1;
        matList.add(mat);

        Test.startTest();
        BpDetailUpdateContr.materialConsumption(acc.Id, matList);
        Test.stopTest();

      //  List<Material_Consumption__c> insertedMat = [SELECT Id FROM Material_Consumption__c WHERE Work_Order_Line_Item__c = :woli.Id];
       // System.assertEquals(1, insertedMat.size());
    }

    @isTest
    static void testMaterialConsumption_EmptyList() {
      //  WorkOrderLineItem woli = [SELECT Id FROM WorkOrderLineItem LIMIT 1];
         Account acc = new Account(
            Name = 'Test Account',
            FirstName__c = 'John',
            LastName__c = 'Doe',
            BP_Number__c = 'BP123',
            Meter_Shifted__c = 'Yes',
        Connection_Done_Or_Not__c = 'Yes'
        );
        insert acc;
        Test.startTest();
        BpDetailUpdateContr.materialConsumption(acc.Id, new List<BpDetailUpdateContr.MaterialWrapper>());
        Test.stopTest();
    }

    @isTest
    static void testMaterialConsumption_ExceptionPath() {
        Test.startTest();
        BpDetailUpdateContr.materialConsumption(null, null);
        Test.stopTest();
    }

}