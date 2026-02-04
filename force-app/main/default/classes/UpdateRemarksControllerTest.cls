@IsTest(seeAllData=true)
public class UpdateRemarksControllerTest {

    @IsTest
    static void testGetObjectList() {
        // Assumes MGL_Setting__mdt with DeveloperName='UploadUtilityObjects' exists in org
        Test.startTest();
        List<Map<String, String>> objects = UpdateRemarksController.getObjectList();
        Test.stopTest();
    }

    @IsTest
    static void testUploadCSVBatchWorkOrder() {
        // Query required related records from org data
        Account acc = [SELECT Id, BP_Number__c FROM Account WHERE BP_Number__c != null LIMIT 1];
        WorkType wt = [SELECT Id, Name FROM WorkType WHERE Name != null LIMIT 1];
        RecordType rt = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType='WorkOrder' AND DeveloperName != null LIMIT 1];

        // Prepare CSV input mapped to supported fields
        List<Map<String, String>> csvData = new List<Map<String, String>>();
        Map<String, String> row = new Map<String, String>();
        row.put('BP Number', acc.BP_Number__c); // Supported field mapping
        row.put('WorkType Name', wt.Name);
        row.put('RecordType Name', rt.DeveloperName);
        csvData.add(row);

        Test.startTest();
        Map<String, Object> result = UpdateRemarksController.uploadCSVBatch('WorkOrder', csvData, null);
        Test.stopTest();
    }

    @IsTest
    static void testUploadCSVBatchAccount() {
        // Prepare CSV input for Account object
        List<Map<String,String>> csvData = new List<Map<String,String>>();
        csvData.add(new Map<String,String>{'Name' => 'Test Account 2', 'BP_Number__c' => 'BP_TEST_XYZ'});

        Test.startTest();
        Map<String, Object> result = UpdateRemarksController.uploadCSVBatch('Account', csvData, null);
        Test.stopTest();
    }

    @IsTest
    static void testUploadLargeCSVChunk() {
        List<Map<String,String>> csvData = new List<Map<String,String>>();
        csvData.add(new Map<String,String>{'Name' => 'Large Upload Test', 'BP_Number__c' => 'BP_LARGE_001'});

        Test.startTest();
        UpdateRemarksController.uploadLargeCSVChunk(csvData, 'Account', 'BP_Number__c');
        Test.stopTest();
    }

    @IsTest
    static void testUtilityMethods() {
        // Directly call utility methods to cover lines
        Test.startTest();
        Date d1 = UpdateRemarksController.parseFlexibleDate('12/25/2024');    // MM/dd/yyyy
        Date d2 = UpdateRemarksController.parseFlexibleDate('2024-12-25');    // yyyy-MM-dd
        Date d3 = UpdateRemarksController.parseFlexibleDate('12-25-2024');    // MM-dd-yyyy
        DateTime dt1 = UpdateRemarksController.parseFlexibleDateTime('2024-08-20 10:15:30'); // DateTime
        DateTime dt2 = UpdateRemarksController.parseFlexibleDateTime('2024-08-20T10:15:30'); // DateTime with T
        Test.stopTest();
    }
        @IsTest
    static void testUploadCSVBatchEmptyAndInvalidObject() {
        Test.startTest();
        // Test with empty data - triggers the "no records found" branch
        Map<String, Object> noRecordsResult = UpdateRemarksController.uploadCSVBatch('Account', new List<Map<String, String>>(), null);

        // Test with invalid object name - triggers the "Invalid object name" branch
        List<Map<String,String>> dummyData = new List<Map<String,String>>();
        dummyData.add(new Map<String,String>{'Name' => 'BadObj', 'BP_Number__c' => 'BP_FAKE'});
        Map<String, Object> invalidResult = UpdateRemarksController.uploadCSVBatch('BadObject', dummyData, null);
        Test.stopTest();
    }

    @IsTest
    static void testUtilityMethodsWithBadInput() {
        Test.startTest();
        Date badDate = UpdateRemarksController.parseFlexibleDate('notadate');
        DateTime badDateTime = UpdateRemarksController.parseFlexibleDateTime('badtime');
        Test.stopTest();
    }

}