/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 15-01-2026
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   15-01-2026   Kartik Patkar, Appstrail   Initial Version
**/
@isTest
private class MeterReadingOCRTriggerHandlerTest {

    @isTest
    static void testBeforeInsert_UpdatesFileName() {
        // Create Work Order with required fields
        WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            Status = 'New',
            Meter_Reading_Doc_Number__c = 'DOC-001',
            Bill_Date__c = Date.today()
        );
        insert wo;

        Test.startTest();
        // Create OCR record with Pending status (triggers updateFileName in beforeInsert)
        Meter_Reading_OCR__c ocr = new Meter_Reading_OCR__c(
            Status__c = 'Pending',
            Meter_Number__c = '123',
            Meter_Reading__c = '111',
            Work_Order__c = wo.Id
        );
        insert ocr;
        Test.stopTest();
    }

    @isTest
    static void testBeforeUpdate_UpdatesFileName() {
        // Create Work Order
        WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            Status = 'New',
            Meter_Reading_Doc_Number__c = 'DOC-002',
            Bill_Date__c = Date.today()
        );
        insert wo;

        // Create OCR record with Draft status
        Meter_Reading_OCR__c ocr = new Meter_Reading_OCR__c(
            Status__c = 'Draft',
            Meter_Number__c = '456',
            Meter_Reading__c = '222',
            Work_Order__c = wo.Id
        );
        insert ocr;

        Test.startTest();
        // Update status to Pending (triggers updateFileName in beforeUpdate)
        ocr.Status__c = 'Pending';
        update ocr;
        Test.stopTest();
    }

    @isTest
    static void testAfterInsert_PendingStatus() {
        // Create Work Order
        WorkOrder wo = new WorkOrder(
            Subject = 'Insert WO',
            Status = 'New',
            Meter_Reading_Doc_Number__c = 'DOC-003',
            Bill_Date__c = Date.today()
        );
        insert wo;

        Test.startTest();
        // Insert with Pending status - triggers checkMeterReadingOCR
        Meter_Reading_OCR__c ocr = new Meter_Reading_OCR__c(
            Status__c = 'Pending',
            Meter_Number__c = '123',
            Meter_Reading__c = '111',
            Work_Order__c = wo.Id
        );
        insert ocr;
        Test.stopTest();
    }

    @isTest
    static void testAfterUpdate_StatusChangedToCompleted() {
        // Create Work Order
        WorkOrder wo = new WorkOrder(
            Subject = 'Update WO',
            Status = 'New'
        );
        insert wo;

        // Create OCR record with Draft status
        Meter_Reading_OCR__c ocr = new Meter_Reading_OCR__c(
            Status__c = 'Draft',
            Meter_Number__c = '456',
            Meter_Reading__c = '222',
            Work_Order__c = wo.Id
        );
        insert ocr;

        Test.startTest();
        // Update status to Completed - triggers updateOCRResultToWorkOrder
        ocr.Status__c = 'Completed';
        update ocr;
        Test.stopTest();

    }

    @isTest
    static void testAfterUpdate_StatusChangedToFailed() {
        // Create Work Order
        WorkOrder wo = new WorkOrder(
            Subject = 'Update WO',
            Status = 'New'
        );
        insert wo;

        // Create OCR record with Pending status
        Meter_Reading_OCR__c ocr = new Meter_Reading_OCR__c(
            Status__c = 'Pending',
            Meter_Number__c = '789',
            Meter_Reading__c = '333',
            Work_Order__c = wo.Id
        );
        insert ocr;

        Test.startTest();
        // Update status to Failed - triggers updateOCRResultToWorkOrder
        ocr.Status__c = 'Failed';
        update ocr;
        Test.stopTest();
    }

    @isTest
    static void testAfterUpdate_NoStatusChange_NoAction() {
        // Create Work Order
        WorkOrder wo = new WorkOrder(
            Subject = 'No Change WO',
            Status = 'New'
        );
        insert wo;

        // Create OCR record with Completed status
        Meter_Reading_OCR__c ocr = new Meter_Reading_OCR__c(
            Status__c = 'Completed',
            Meter_Number__c = '999',
            Meter_Reading__c = '444',
            Work_Order__c = wo.Id
        );
        insert ocr;

        Test.startTest();
        // Update meter reading without changing status
        ocr.Meter_Reading__c = '555';
        update ocr;
        Test.stopTest();
    }

    @isTest
    static void testUpdateFileName_EmptyWorkOrderIds() {
        // Create OCR record without Work Order (edge case)
        Meter_Reading_OCR__c ocr = new Meter_Reading_OCR__c(
            Status__c = 'Draft',
            Meter_Number__c = '000',
            Meter_Reading__c = '000'
        );

        Test.startTest();
        // Call updateFileName directly with non-Pending status
        MeterReadingOCRTriggerHandler.updateFileName(new List<Meter_Reading_OCR__c>{ocr}, null);
        Test.stopTest();
    }

    @isTest
    static void testCheckMeterReadingOCR_EmptyMeterIds() {
        // Create OCR records with non-Pending status
        Meter_Reading_OCR__c ocr = new Meter_Reading_OCR__c(
            Status__c = 'Completed',
            Meter_Number__c = '111',
            Meter_Reading__c = '111'
        );

        Test.startTest();
        // Call checkMeterReadingOCR directly - should exit early
        MeterReadingOCRTriggerHandler.checkMeterReadingOCR(new List<Meter_Reading_OCR__c>{ocr}, null);
        Test.stopTest();

    }

    @isTest
    static void testUpdateOCRResultToWorkOrder_BulkRecords() {
        // Create multiple Work Orders
        List<WorkOrder> workOrders = new List<WorkOrder>();
        for (Integer i = 0; i < 5; i++) {
            workOrders.add(new WorkOrder(
                Subject = 'Bulk WO ' + i,
                Status = 'New'
            ));
        }
        insert workOrders;

        // Create multiple OCR records with Draft status
        List<Meter_Reading_OCR__c> ocrRecords = new List<Meter_Reading_OCR__c>();
        for (Integer i = 0; i < 5; i++) {
            ocrRecords.add(new Meter_Reading_OCR__c(
                Status__c = 'Draft',
                Meter_Number__c = 'M' + i,
                Meter_Reading__c = String.valueOf(100 + i),
                Work_Order__c = workOrders[i].Id
            ));
        }
        insert ocrRecords;

        Test.startTest();
        // Bulk update to Completed status
        for (Meter_Reading_OCR__c ocr : ocrRecords) {
            ocr.Status__c = 'Completed';
        }
        update ocrRecords;
        Test.stopTest();
    }
}