@isTest
public class MeterReadingPlausibilityCheckHelperTest {
    
	@testSetup
    static void setup() {

    }

    @isTest
    static void testPlausibilityCheckLogic_AllScenarios() {
        Date today = Date.today();
        Date fiveDaysAgo = today.addDays(-5);

        // Negative consumption
        Map<String,Object> neg = MeterReadingPlausibilityCheckHelper.plausibilityCheckLogic(100, 50, fiveDaysAgo, 10);
        System.assertEquals(false, neg.get('valid'));
        System.assertEquals('Negative', neg.get('check'));

        // Zero consumption
        Map<String,Object> zero = MeterReadingPlausibilityCheckHelper.plausibilityCheckLogic(100, 100, fiveDaysAgo, 10);
        System.assertEquals(false, zero.get('valid'));
        System.assertEquals('Zero', zero.get('check'));

        // High consumption
        Map<String,Object> high = MeterReadingPlausibilityCheckHelper.plausibilityCheckLogic(100, 5000, fiveDaysAgo, 10);
        System.assertEquals(false, high.get('valid'));
        System.assertEquals('High', high.get('check'));

        // Low consumption
        Map<String,Object> low = MeterReadingPlausibilityCheckHelper.plausibilityCheckLogic(100, 101, fiveDaysAgo, 100);
        System.assertEquals(false, low.get('valid'));
        System.assertEquals('Low', low.get('check'));

        // Plausible consumption
        Map<String,Object> plausible = MeterReadingPlausibilityCheckHelper.plausibilityCheckLogic(100, 150, fiveDaysAgo, 10);
        System.assertEquals(true, plausible.get('valid'));
        System.assertEquals('Plausible', plausible.get('check'));
    }

    @isTest
    static void testCheckWorkOrderPlausibility_UpdateFlags() {
       
        Account accRec=new Account();
        accRec.Name = 'Test';
		accRec.Category__c='Domestic';
        insert accRec;
        
        String meteringRecordType = Schema.getGlobalDescribe().get('WorkOrder').getDescribe().getRecordTypeInfosByDeveloperName().get('MGL_Metering').getRecordTypeId();
        WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            Status = 'New',
            RecordTypeId = meteringRecordType,
            Previous_Meter_Reading__c = '100',
            Meter_Reading__c = 5000,
            Average_Consumption__c = 10,
            Last_Meter_Reading_Date__c = Date.today().addDays(-5),
            AccountId=accRec.Id,
            Appointment_Status__c = 'Completed'
        );
        insert wo;

        List<WorkOrder> newList = new List<WorkOrder>{ wo };

        Test.startTest();
        MeterReadingPlausibilityCheckHelper.checkWorkOrderPlausibility(newList, null);
        Test.stopTest();
    }
}