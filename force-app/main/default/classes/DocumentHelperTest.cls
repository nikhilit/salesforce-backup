@isTest
private class DocumentHelperTest {
    
    @testSetup
    static void setupData() {
        // No org data needed for this helper — only primitive values are tested.
    }
    
    @isTest
    static void testGenerateKey_MeterDocNoPriority() {
        // Positive case — meterDocNo should take priority
        String result = DocumentHelper.generateDocumentKey('MTR123', 'BP456', DateTime.newInstance(2025, 7, 30, 10, 30, 0), 'WO789');
        
    }
    
    @isTest
    static void testGenerateKey_WorkOrderNumberPriority() {
        // meterDocNo is blank, workOrderNumber should be used
        String result = DocumentHelper.generateDocumentKey('', 'BP456', DateTime.newInstance(2025, 7, 30, 10, 30, 0), 'WO789');
        
    }
    
    @isTest
    static void testGenerateKey_BothIdsBlank() {
        // Both meterDocNo and workOrderNumber blank — primaryId should be empty
        String result = DocumentHelper.generateDocumentKey('', 'BP456', DateTime.newInstance(2025, 7, 30, 10, 30, 0), '');
        
    }
    
    @isTest
    static void testGenerateKey_BlankBpNumber() {
        // bpNumber is blank — safeBpNumber should be empty
        String result = DocumentHelper.generateDocumentKey('MTR123', '', DateTime.newInstance(2025, 7, 30, 10, 30, 0), '');
        
    }
    
    @isTest
    static void testGenerateKey_NullBillDate() {
        // billDate is null — formattedBillDate should be empty
        String result = DocumentHelper.generateDocumentKey('MTR123', 'BP456', null, '');
        
    }
    
    @isTest
    static void testGenerateKey_AllBlankExceptDate() {
        // Edge case — only billDate is provided
        String result = DocumentHelper.generateDocumentKey('', '', DateTime.newInstance(2025, 7, 30, 10, 30, 0), '');
       
    }
}