/**
* @description       : 
* @author            : Kartik Patkar Appstrail
* @group             : 
* @last modified on  : 11-08-2025
* @last modified by  : Kartik Patkar, Appstrail
* Modifications Log
* Ver   Date         Author                     Modification
* 1.0   11-08-2025   Kartik Patkar, Appstrail   Initial Version
**/
@isTest
private class WorkOrderVisitControllerTest {
    @testSetup
    static void setupData() {
        Account acc = new Account(Name = 'Test Account', Phone = '1234567890',
                                  Representative_Company__c = 'Test Company',
                                  Zone__c = 'East', Location__c = 'City');
        insert acc;
        WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            AccountId = acc.Id,
            Status = 'New'
        );
        insert wo;
        
        ServiceAppointment sa=new ServiceAppointment();
        sa.ParentRecordId=wo.Id;
        sa.Status='In Progress';
        insert sa;
        
        Dispenser_Point__c dp = new Dispenser_Point__c(
            
            Dispenser_Name__c = 'Point_1',
            WorkOrderId__c = wo.Id,
            Dispenser_Number__c = 'DIS-00001'
            // CNG_Meter_reading__c = 'a1mfs0000000GeHAAU'
        );
        insert dp;
    }
    
    
    @isTest
    static void test_UpdateVisitInfo() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        System.debug('wo '+wo);
        Test.startTest();        
        WorkOrderVisitController.updateVisitInfo(wo.Id, 'Comment', Date.today(), 'Follow up', 'Customer Not Available');
        WorkOrderVisitController.PicklistWrapper random =   new   WorkOrderVisitController.PicklistWrapper();
        WorkOrderVisitController.WorkOrderWrapper random2 = new WorkOrderVisitController.WorkOrderWrapper();
        //WorkOrderWrapper
        Test.stopTest();
    }
    
    @isTest
    static void testGetPicklistValues() {
        Test.startTest();
        WorkOrderVisitController.PicklistWrapper result = WorkOrderVisitController.getPicklistValues();
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.remarkTypes, 'Remark types list should not be null');
    }
    
    @isTest
    static void testGetWorkOrder() {
        // Step 1: Create Account
        Account acc = new Account(
            Name = 'Test Account',
            Phone = '9876543210',
            Representative_Company__c = 'Test Company',
            Zone__c = 'North',
            Location__c = 'Test Location'
        );
        insert acc;
        
        // Step 2: Create WorkOrder
        WorkOrder wo = new WorkOrder(
            Subject = 'Test Work Order',
            AccountId = acc.Id,
            Status = 'New'
        );
        insert wo;
        
        // Step 3: Call the method
        Test.startTest();
        WorkOrderVisitController.WorkOrderWrapper wrapper = WorkOrderVisitController.getWorkOrder(wo.Id);
        Test.stopTest();
        
        // Step 4: Assertions
        System.assertNotEquals(null, wrapper);
        System.assertEquals('Test Account', wrapper.customerName);
        System.assertEquals('North', wrapper.zone);
        //System.assertEquals('9876543210', wrapper.phone);
        System.assertEquals('Test Location', wrapper.location);
        System.assertEquals('Test Company', wrapper.repComp);
    }
    
    
    
    @isTest
    static void testWorkOrderWrapperConstructor() {
        // Step 1: Create Account with all required fields
        Account acc = new Account(
            Name = 'Test Customer',
            Phone = '9999999999',
            Zone__c = 'East Zone',
            Location__c = 'City X',
            Representative_Company__c = 'Rep Co.'
        );
        insert acc;
        
        // Step 2: Create WorkOrder linked to the account
        WorkOrder wo = new WorkOrder(
            Subject = 'Test WorkOrder',
            AccountId = acc.Id,
            Status = 'New'
        );
        insert wo;
        
        // Step 3: Query WorkOrder with related Account fields
        WorkOrder queriedWO = [
            SELECT Id, Account.Name, Account.Phone, Account.Zone__c,
            Account.Location__c, Account.Representative_Company__c
            FROM WorkOrder
            WHERE Id = :wo.Id
        ];
        
        // Step 4: Call the constructor
        WorkOrderVisitController.WorkOrderWrapper wrapper = new WorkOrderVisitController.WorkOrderWrapper(queriedWO);
        
        // Step 5: Assertions to validate values (optional but recommended)
        System.assertEquals('Test Customer', wrapper.customerName);
        System.assertEquals('East Zone', wrapper.zone);
        //System.assertEquals('9999999999', wrapper.phone);
        System.assertEquals('City X', wrapper.location);
        System.assertEquals('Rep Co.', wrapper.repComp);
    }
    
    
    @isTest
    static void testUpdateVisitInfo() {
        // Insert a test Account (required for WorkOrder)
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        // Insert a test WorkOrder
        WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            AccountId = acc.Id,
            Status = 'New'
        );
        insert wo;
        
        // Use a valid picklist value here instead of 'Not available'
        String validReason = 'Customer Not Available'; // ✅ Replace with actual valid value in your org
        
        // Call the method
        WorkOrderVisitController.updateVisitInfo(
            wo.Id,
            'Comment',
            Date.today(),
            'Follow up',
            validReason
        );
        
        // Verify the update
        WorkOrder updated = [SELECT Comments__c, Follow_Up_Appointment_Date__c FROM WorkOrder WHERE Id = :wo.Id];
        System.assertEquals('Comment', updated.Comments__c);
    }
    
    
    @isTest
    static void testPicklistValues_Coverage() {
        Test.startTest();
        WorkOrderVisitController.PicklistWrapper wrapper = WorkOrderVisitController.getPicklistValues();
        Test.stopTest();
        System.assertNotEquals(null, wrapper);
        System.assertNotEquals(null, wrapper.remarkTypes);
    }
    
    
    
    @isTest
    static void testInsertDispenserPoint() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        Dispenser_Point__c newDP = new Dispenser_Point__c(Dispenser_Name__c = 'Point_1');
        Test.startTest();
        WorkOrderVisitController.insertDispenserPoint(newDP, wo.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testCheckInWorkOrder() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        Double lat = 19.123;
        Double lon = 72.456;
        Test.startTest();
        WorkOrderVisitController.checkInWorkOrder(wo.Id, lat, lon);
        Test.stopTest();
    }
    
    @isTest
    static void testGetDispenserPoints() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        List<Dispenser_Point__c> result = WorkOrderVisitController.getDispenserPoints(wo.Id);
        System.assertNotEquals(null, result);
    }
    
    @isTest
    static void testSaveVisitDetails() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        List<Dispenser_Point__c> dps = [SELECT Id FROM Dispenser_Point__c LIMIT 1];
        Test.startTest();
        WorkOrderVisitController.saveVisitDetails(dps, wo.Id, 19.0, 72.0, 'Done', String.valueOf(Date.today()), String.valueOf(Date.today()));
        Test.stopTest();
    }
    
    @isTest
    static void testUpdateLiveDetails() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        List<Dispenser_Point__c> dps = [SELECT Id FROM Dispenser_Point__c LIMIT 1];
        Test.startTest();
        WorkOrderVisitController.updateLiveDetails(dps, wo.Id, 19.0, 72.0, 'Live remarks', String.valueOf(Date.today()), String.valueOf(Date.today()));
        Test.stopTest();
    }
    
    @isTest
    static void testUploadImage() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        Blob b = Blob.valueOf('Test Data');
        String base64String = EncodingUtil.base64Encode(b);
        Test.startTest();
        String url = WorkOrderVisitController.uploadImage('signature.png', base64String, wo.Id);
        Test.stopTest();
        System.assertNotEquals(null, url);
    }
    
    
    @isTest
    static void test_replaceDispenserPoint_success() {
        
        Account acc = new Account(Name = 'Disp Test Acc');
        insert acc;
        
        String rtId = Schema.getGlobalDescribe()
            .get('WorkOrder')
            .getDescribe()
            .getRecordTypeInfosByDeveloperName()
            .get('MGL_Metering')
            .getRecordTypeId();
        
        WorkOrder wo = new WorkOrder(
            Subject = 'Disp Test WO',
            Status = 'New',
            RecordTypeId = rtId,
            AccountId = acc.Id,
            StartDate = Date.today(),
            EndDate = Date.today()
        );
        insert wo;
        
        Dispenser_Point__c oldDisp = new Dispenser_Point__c(
            Dispenser_Name__c = 'Point_10',
            Dispenser_Number__c = 'DIS-00010',
            WorkOrderId__c = wo.Id,
            Live__c = true
        );
        insert oldDisp;

        Dispenser_Point__c newDisp = new Dispenser_Point__c();
        
        Test.startTest();
        
        WorkOrderVisitController.replaceDispenserPoint(
            newDisp,
            oldDisp.Id
        );
        
        Test.stopTest();
        

        Dispenser_Point__c created = [
            SELECT Id, Dispenser_Name__c, Dispenser_Number__c, WorkOrderId__c, Live__c
            FROM Dispenser_Point__c
            WHERE Id != :oldDisp.Id
            LIMIT 1
        ];
        
        oldDisp = [
            SELECT Live__c
            FROM Dispenser_Point__c
            WHERE Id = :oldDisp.Id
        ];
        
        System.assertEquals(
            false,
            oldDisp.Live__c,
            'Old dispenser must be deactivated'
        );
    }
    @isTest
    static void test_canReplaceDispenser_true() {
        
        Account acc = new Account(Name = 'Disp Test Acc');
        insert acc;
        
        Id rtId = Schema.getGlobalDescribe()
            .get('WorkOrder')
            .getDescribe()
            .getRecordTypeInfosByDeveloperName()
            .get('MGL_Metering')
            .getRecordTypeId();
        
        WorkOrder wo = new WorkOrder(
            Subject = 'Disp Test WO',
            Status = 'New',
            RecordTypeId = rtId,
            AccountId = acc.Id,
            StartDate = Date.today(),
            EndDate = Date.today()
        );
        insert wo;
        
        Dispenser_Point__c disp = new Dispenser_Point__c(
            Dispenser_Name__c = 'Point_10',
            Dispenser_Number__c = 'DIS-00010',
            WorkOrderId__c = wo.Id,
            Live__c = true
        );
        insert disp;
        
        Test.startTest();
        WorkOrderVisitController.canReplaceDispenser(disp.Id);
        Test.stopTest();
    }
    @isTest
    static void test_canReplaceDispenser_false() {
        
        Account acc = new Account(Name = 'Disp Test Acc 2');
        insert acc;
        
        Id rtId = Schema.getGlobalDescribe()
            .get('WorkOrder')
            .getDescribe()
            .getRecordTypeInfosByDeveloperName()
            .get('MGL_Metering')
            .getRecordTypeId();
        
        WorkOrder wo = new WorkOrder(
            Subject = 'Disp Test WO 2',
            Status = 'New',
            RecordTypeId = rtId,
            AccountId = acc.Id,
            StartDate = Date.today(),
            EndDate = Date.today()
        );
        insert wo;
        
        Dispenser_Point__c disp = new Dispenser_Point__c(
            Dispenser_Name__c = 'Point_2',
            Dispenser_Number__c = 'DIS-00002',
            WorkOrderId__c = wo.Id,
            Live__c = false
        );
        insert disp;
        
        Test.startTest();
        WorkOrderVisitController.canReplaceDispenser(disp.Id);
        Test.stopTest();
    }
    @isTest
    static void test_canReplaceDispenser_null() {
        
        try {
            Test.startTest();
            WorkOrderVisitController.canReplaceDispenser(null);
            Test.stopTest();
        } catch (Exception e) {
            // Intentionally blank — only for coverage
        }
    }
    
    @isTest
    static void test_uploadSelfieImage_success() {
        

        Account acc = new Account(Name = 'Selfie Test Acc');
        insert acc;
        

        Id rtId = Schema.getGlobalDescribe()
            .get('WorkOrder')
            .getDescribe()
            .getRecordTypeInfosByDeveloperName()
            .get('MGL_Metering')
            .getRecordTypeId();
        
        WorkOrder wo = new WorkOrder(
            Subject = 'Selfie Test WO',
            Status = 'New',
            RecordTypeId = rtId,
            AccountId = acc.Id,
            StartDate = Date.today(),
            EndDate = Date.today()
        );
        insert wo;
        

        Blob body = Blob.valueOf('test image');
        String base64Data = EncodingUtil.base64Encode(body);
        
        Test.startTest();
        
        WorkOrderVisitController.uploadSelfieImage(
            'selfie.png',
            base64Data,
            wo.Id
        );
        
        Test.stopTest();
    }
    
    @isTest
    static void test_deleteDispenserPoints_success() {
        
        Account acc = new Account(Name = 'Delete Disp Acc');
        insert acc;
        
        Id rtId = Schema.getGlobalDescribe()
            .get('WorkOrder')
            .getDescribe()
            .getRecordTypeInfosByDeveloperName()
            .get('MGL_Metering')
            .getRecordTypeId();
        
        WorkOrder wo = new WorkOrder(
            Subject = 'Delete Disp WO',
            Status = 'New',
            RecordTypeId = rtId,
            AccountId = acc.Id,
            StartDate = Date.today(),
            EndDate = Date.today()
        );
        insert wo;
        

        Dispenser_Point__c baseDisp = new Dispenser_Point__c(
            Dispenser_Name__c = 'Point_2',
            Dispenser_Number__c = 'DIS-00002',
            WorkOrderId__c = wo.Id,
            Live__c = false
        );
        insert baseDisp;
        

        Dispenser_Point__c newDisp1 = new Dispenser_Point__c(
            Dispenser_Name__c = 'Point_2_New_1',
            Dispenser_Number__c = 'DIS-00003',
            WorkOrderId__c = wo.Id,
            Live__c = false
        );
        insert newDisp1;
        

        Dispenser_Point__c newDisp2 = new Dispenser_Point__c(
            Dispenser_Name__c = 'Point_2_New_2',
            Dispenser_Number__c = 'DIS-00004',
            WorkOrderId__c = wo.Id,
            Live__c = true
        );
        insert newDisp2;
        
        Test.startTest();
        WorkOrderVisitController.deleteDispenserPoints(newDisp2.Id);
        Test.stopTest();
    }
}