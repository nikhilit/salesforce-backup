@isTest
private class MilestoneCalculationTest {

    // Utility method to create a Case record
    private static Case createCaseWithTATs() {
        Case c = new Case(
            Subject = 'Test Case',
            Status = 'New',
            Remaining_TAT__c = '60',
            Remaining_TAT_2__c = '120',
            Remaining_TAT_3__c = '180',
            Remaining_Tat_4__c = '240',
            Remaining_TAT_5__c = '300'
        );
        insert c;
        return c;
    }

    @isTest
    static void testCalculateMilestoneTriggerTime_AllMilestones() {
        // Create Case (data object)
        Case testCase = createCaseWithTATs();

        // Create Milestone types separately inside System.runAs (setup object DML)
        User u = [SELECT Id FROM User WHERE IsActive = TRUE LIMIT 1];

        Id mt1Id;
        Id mt2Id;
        Id mt3Id;
        Id mt4Id;
        Id mt5Id;

        System.runAs(u) {
            insert new MilestoneType(Name = 'TAT for ticket closure1');
            insert new MilestoneType(Name = 'Second TAT for ticket 2');
            insert new MilestoneType(Name = 'Third TAT for ticket closure2');
            insert new MilestoneType(Name = 'Fourth TAT for ticket closure4');
            insert new MilestoneType(Name = 'Fifth TAT for ticket closure4');

            List<MilestoneType> mts = [SELECT Id, Name FROM MilestoneType WHERE Name LIKE '%ticket closure%'];
            mt1Id = mts[0].Id;
            mt2Id = mts[1].Id;
            mt3Id = mts[2].Id;
            mt4Id = mts[3].Id;
            mt5Id = mts[4].Id;
        }

        MilestoneCalculation calc = new MilestoneCalculation();

        Test.startTest();
        calc.calculateMilestoneTriggerTime(testCase.Id, mt1Id);
        calc.calculateMilestoneTriggerTime(testCase.Id, mt2Id);
        calc.calculateMilestoneTriggerTime(testCase.Id, mt3Id);
        calc.calculateMilestoneTriggerTime(testCase.Id, mt4Id);
        calc.calculateMilestoneTriggerTime(testCase.Id, mt5Id);
        Test.stopTest();
    }

    @isTest
    static void testCalculateMilestoneTriggerTime_DefaultValue() {
        Case c = new Case(Subject = 'Blank TAT Case', Status = 'New');
        insert c;

        Id mtId;
        User u = [SELECT Id FROM User WHERE IsActive = TRUE LIMIT 1];
        System.runAs(u) {
            insert new MilestoneType(Name = 'Unmatched milestone');
            mtId = [SELECT Id FROM MilestoneType WHERE Name = 'Unmatched milestone' LIMIT 1].Id;
        }

        MilestoneCalculation calc = new MilestoneCalculation();

        Test.startTest();
        calc.calculateMilestoneTriggerTime(c.Id, mtId);
        Test.stopTest();
    }

    @isTest
    static void testCalculateMilestoneTriggerTime_ExceptionBlock() {
        MilestoneCalculation calc = new MilestoneCalculation();

        Test.startTest();
        calc.calculateMilestoneTriggerTime(null, null);
        Test.stopTest();
    }
}