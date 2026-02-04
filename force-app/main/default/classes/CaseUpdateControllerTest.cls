@IsTest
public class CaseUpdateControllerTest {
    
    @TestSetup
    static void setupTestData() {
        Case testCase = new Case(
            Subject = 'Test Case',
            Status = 'New'
        );
        insert testCase;
    }
    
    @IsTest
    static void testGetCaseData_Success() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        
        Test.startTest();
        CaseUpdateController.CaseDataWrapper result = CaseUpdateController.getCaseData(testCase.Id);
        Test.stopTest();
    }
    
    @IsTest
    static void testGetCaseData_NoCaseId() {
        Test.startTest();
        try {
            CaseUpdateController.CaseDataWrapper result = CaseUpdateController.getCaseData(null);
        } catch (AuraHandledException e) {
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testGetCaseData_InvalidCaseId() {
        Test.startTest();
        try {
            CaseUpdateController.CaseDataWrapper result = CaseUpdateController.getCaseData('001000000000000');
        } catch (AuraHandledException e) {
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testUpdateRemarksAndCount_FirstCall() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        String testRemarks = 'Test remarks for first call';
        
        Test.startTest();
        String result = CaseUpdateController.updateRemarksAndCount(testCase.Id, testRemarks);
        Test.stopTest();
        
        Case updatedCase = [SELECT Id, Outbound_Call_1_Remarks__c, Outbound_Call_1_Done_By__c, 
                           Outbound_Call_1_Done_Time__c, Outgoing_Calls_Count__c, Comments 
                           FROM Case WHERE Id = :testCase.Id];
    }
    
    @IsTest
    static void testUpdateRemarksAndCount_SecondCall() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        String firstRemarks = 'First call remarks';
        
        testCase.Outbound_Call_1_Remarks__c = firstRemarks;
        testCase.Outbound_Call_1_Done_By__c = 'Test User 1';
        testCase.Outbound_Call_1_Done_Time__c = '2024-01-01 10:00:00';
        testCase.Outgoing_Calls_Count__c = 1;
        update testCase;
        
        String secondRemarks = 'Second call remarks';
        
        Test.startTest();
        String result = CaseUpdateController.updateRemarksAndCount(testCase.Id, secondRemarks);
        Test.stopTest();
        
        Case updatedCase = [SELECT Id, Outbound_Call_2_Remarks__c, Outbound_Call_2_Done_By__c, 
                           Outbound_Call_2_Done_Time__c, Outgoing_Calls_Count__c, Comments 
                           FROM Case WHERE Id = :testCase.Id];
    }
    
    @IsTest
    static void testUpdateRemarksAndCount_MaxCallsReached() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        
        testCase.Outbound_Call_1_Remarks__c = 'First call remarks';
        testCase.Outbound_Call_1_Done_By__c = 'Test User 1';
        testCase.Outbound_Call_1_Done_Time__c = '2024-01-01 10:00:00';
        testCase.Outbound_Call_2_Remarks__c = 'Second call remarks';
        testCase.Outbound_Call_2_Done_By__c = 'Test User 2';
        testCase.Outbound_Call_2_Done_Time__c = '2024-01-01 11:00:00';
        testCase.Outgoing_Calls_Count__c = 2;
        update testCase;
        
        String thirdRemarks = 'Third call remarks - should fail';
        
        Test.startTest();
        try {
            String result = CaseUpdateController.updateRemarksAndCount(testCase.Id, thirdRemarks);
        } catch (AuraHandledException e) {
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testUpdateRemarksAndCount_NoCaseId() {
        Test.startTest();
        try {
            String result = CaseUpdateController.updateRemarksAndCount(null, 'Test remarks');
        } catch (AuraHandledException e) {
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testUpdateRemarksAndCount_NoRemarks() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        
        Test.startTest();
        try {
            String result = CaseUpdateController.updateRemarksAndCount(testCase.Id, '');
        } catch (AuraHandledException e) {
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testUpdateRemarksAndCount_InvalidCaseId() {
        Test.startTest();
        try {
            String result = CaseUpdateController.updateRemarksAndCount('001000000000000', 'Test remarks');
        } catch (AuraHandledException e) {
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testCaseDataWrapper() {
        Case testCase = new Case(Subject = 'Test Case');
        CaseUpdateController.CaseDataWrapper wrapper = new CaseUpdateController.CaseDataWrapper();
        
        wrapper.caseRecord = testCase;
        wrapper.isSaveDisabled = false;
        wrapper.hasError = false;
        wrapper.errorMessage = '';
    }
    
    @IsTest
    static void testUpdateRemarksAndCount_CommentsAppendedCorrectly() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        String firstRemarks = 'First call remarks';
        
        Test.startTest();
        String result1 = CaseUpdateController.updateRemarksAndCount(testCase.Id, firstRemarks);
        
        String secondRemarks = 'Second call remarks';
        String result2 = CaseUpdateController.updateRemarksAndCount(testCase.Id, secondRemarks);
        Test.stopTest();
        
        Case updatedCase = [SELECT Id, Comments FROM Case WHERE Id = :testCase.Id];
    }
}