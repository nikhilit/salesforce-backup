@IsTest
private class AS_CommissionReportControllerTest {

    // ======================================================
    //                 TEST SETUP
    // ======================================================
    @testSetup
    static void setup() {
 
        // ---------- Create WorkType ----------
        WorkType WT = new WorkType(
        	Name = 'Domestic Customer (R&T)',
	        ShouldAutoCreateSvcAppt=false,
    	    EstimatedDuration=6
        );
        insert WT;

        // ---------- Create RecordType ----------
        Id rt = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('MGL_R_T').getRecordTypeId();

        // ---------- Create WorkOrders ----------
        List<WorkOrder> wos = new List<WorkOrder>();

        for (Integer i=0; i<3; i++) {
            wos.add(new WorkOrder(
                RecordTypeId = rt,
                WorkTypeId   = wt.Id,
                StartDate    = Date.today().addDays(-10),
                EndDate      = Date.today(),
                Amount_Received__c = 100 + i,
                Due_Amount__c      = 100 + i,
                Agency_Name__c     = (i==0 ? 'AGENCY1' : 'AGENCY2'),
                Customer_BP_Number__c = 'BP' + i,
                Batch_Lot__c       = (i==0 ? 'BATCH1' : 'BATCH2'),
                B4DUE__c = 10,
                NOTDUE__c = 5,
                X0_30__c = 20,
                X31_60__c = 10,
                X61_90__c = 10,
                X91_180__c = 30,
                X181_365__c = 15,
                X1_2YR__c = 10,
                X2_3YR__c = 5,
                GR3YR__c = 5
            ));
        }
        insert wos;
    }

    // ======================================================
    //                 TEST: DATE RANGE
    // ======================================================
    @IsTest
    static void test_generate_with_dates() {

        Date sd = Date.today().addDays(-5);
        Date ed = Date.today();

        Test.startTest();
        AS_CommissionReportController.ReportResponse resp =
            AS_CommissionReportController.generateCommissionReport(sd, ed, null, null);
        Test.stopTest();

        System.assertNotEquals(null, resp, 'Response should not be null');
        System.assert(resp.base64Data != null && resp.base64Data.length() > 0, 'Base64 should be populated');
        System.assert(resp.fileName.contains('Commission_Report'), 'Filename must be set');
    }


    // ======================================================
    //                 TEST: BATCH LOT
    // ======================================================
    @IsTest
    static void test_generate_with_batchLot() {

        Test.startTest();
        AS_CommissionReportController.ReportResponse resp =
            AS_CommissionReportController.generateCommissionReport(null, null, 'BATCH1', null);
        Test.stopTest();

        System.assertNotEquals(null, resp);
        System.assert(resp.base64Data != null, 'Response must contain base64 output');
    }


    // ======================================================
    //                 TEST: UPLOADED FILE (BP FILTER)
    // ======================================================
    @IsTest
    static void test_generate_with_fileUpload() {

        // File containing BP numbers (BP1, BP2)
        String raw = 'BP0\nBP1';
        String base64File = EncodingUtil.base64Encode(Blob.valueOf(raw));

        Test.startTest();
        AS_CommissionReportController.ReportResponse resp =
            AS_CommissionReportController.generateCommissionReport(null, null, null, base64File);
        Test.stopTest();

        System.assertNotEquals(null, resp);
        System.assert(resp.base64Data != null, 'Base64 required');
        System.assert(resp.fileName.endsWith('.xls'), 'Filename must be .xls');
    }


    // ======================================================
    //           TEST: REQUIRED FIELD VALIDATION
    // ======================================================
    @IsTest
    static void test_missing_inputs_should_throw_error() {
        try {
            Test.startTest();
            AS_CommissionReportController.generateCommissionReport(null, null, null, null);
            Test.stopTest();
            System.assert(false, 'Expected AuraHandledException');
        } catch (AuraHandledException ex) {
            //System.assert(ex.getMessage().contains('Provide either Start Date'), 'Error message mismatch');
        }
    }


    // ======================================================
    //           TEST: INVALID DATE RANGE
    // ======================================================
    @IsTest
    static void test_invalid_date_range() {

        Date sd = Date.today();
        Date ed = Date.today().addDays(-1);

        try {
            Test.startTest();
            AS_CommissionReportController.generateCommissionReport(sd, ed, null, null);
            Test.stopTest();
            System.assert(false, 'Expected exception');
        } catch (AuraHandledException ex) {
            //System.assert(ex.getMessage().contains('End Date must be same or after Start Date'));
        }
    }
}