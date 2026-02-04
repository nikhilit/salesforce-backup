@IsTest
public class DailyTrackingRealtimeControllerTest {

    @testSetup
    static void setupData() {
        Date today = System.today();
        Date yesterday = today.addDays(-1);

        Account acc = new Account(Name = 'Test Account', BP_Number__c = 'BP-12345');
        insert acc;

        // 1. Setup for "Opening"
        Case openingCase = new Case(Subject = 'Opening', Status = 'Assigned', Origin = '4', AccountId = acc.Id);
        insert openingCase;
        Test.setCreatedDate(openingCase.Id, yesterday);

        // 2. Setup for "doneCategorized > doneCR" 
        // We set Assigned_To_Department__c to TODAY to ensure doneCategorized increments
        Case catCase = new Case(
            Subject = 'Categorized Case', 
            Status = 'New', 
            Origin = '4', 
            AccountId = acc.Id,
            Assigned_To_Department__c = today 
        );
        insert catCase;
        
        // Update to Resolved to satisfy the other side of the OR filter in your controller
        catCase.Status = 'Resolved by CRM';
        update catCase; 

        // 3. Simple Report Data
        Case emailFRL = new Case(Subject = 'Email FRL', Status = 'New', Origin = '4', FRL__c = true, FRL_Sent_Date__c = today, AccountId = acc.Id);
        insert emailFRL;
        emailFRL.Status = 'Resolved';
        update emailFRL;
    }

    @IsTest
    static void testBackOfficeAndMathLogic() {
        Test.startTest();
        // This covers Email + Web and the "if (r.doneCategorized > r.doneCR)" branch
        // because we have 1 categorized case and 0 CR cases.
        DailyTrackingRealtimeController.ReportData r = DailyTrackingRealtimeController.getReport('Email + Web');
        System.assertNotEquals(null, r);
        
        // Cover remaining if/else branches in getReport
        DailyTrackingRealtimeController.getReport('MGL Connect');
        DailyTrackingRealtimeController.getReport('Critical Cases');
        Test.stopTest();
    }

    @IsTest
    static void testSimpleReports() {
        Test.startTest();
        DailyTrackingRealtimeController.getReport('Email FRL');
        DailyTrackingRealtimeController.getReport('Letter FRL');
        DailyTrackingRealtimeController.getReport('Letter');
        Test.stopTest();
    }

    @IsTest
    static void testGetReportsUtil() {
        List<String> results = DailyTrackingRealtimeController.getReports();
        System.assert(results.size() > 0);
    }
}