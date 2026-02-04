@IsTest
public class DailyTrackingMetadataTest {

    @IsTest(SeeAllData=true)
    static void testGetReportIdSuccess() {
        // Find any existing report in the org to cover the !isEmpty() branch
        List<Report> existingReports = [SELECT Name FROM Report LIMIT 1];
        
        Test.startTest();
        if(!existingReports.isEmpty()) {
            String reportId = DailyTrackingRealtimeController.getReportIdByName(existingReports[0].Name);
            System.assertNotEquals(null, reportId);
        }
        
        // Cover the "return null" when list is empty (using a fake name)
        String fakeId = DailyTrackingRealtimeController.getReportIdByName('ThisReportDoesNotExist_999');
        System.assertEquals(null, fakeId);
        Test.stopTest();
    }

    @IsTest
    static void testGetReportIdCatchBlock() {
        Test.startTest();
        // Forcing the catch block: 
        // In many environments, passing a search string with certain 
        // escape characters or exceeding limits in a SOQL bind can trigger an exception.
        // Alternatively, passing null is the most common way to hit internal query errors.
        String reportId = DailyTrackingRealtimeController.getReportIdByName(null);
        System.assertEquals(null, reportId);
        Test.stopTest();
    }
}