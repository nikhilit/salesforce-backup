@IsTest
private class MeteringAddMROtoMRSController_Test {

    @TestSetup
    static void setupData() {
        
        OperatingHours oph = new OperatingHours(Name = 'Test Operating Hours', TimeZone = 'Asia/Kolkata');
        insert oph;
        
        // Create ServiceTerritory (for Agency__c and ServiceTerritoryId)
        ServiceTerritory territory = new ServiceTerritory(Name = 'Test Territory',OperatingHoursId=oph.Id,IsActive=true);
        insert territory;
        
        // Create ServiceResource tagged to the User
        ServiceResource sr = new ServiceResource(
            Name = 'Test Resource',
            RelatedRecordId = UserInfo.getUserId(),
            IsActive = true
        );
        insert sr;

        // Create Meter Reading Schedule (MRS)
        Meter_Reading_Schedule__c mrs = new Meter_Reading_Schedule__c(
            Agency__c = territory.Id,
            Agent__c = sr.Id,
            Meter_Reading_Start_Date__c = Date.today(),
            Meter_Reading_Completion_Date__c = Date.today().addDays(5)
        );
        insert mrs;

        // Create Portion record
        Portion__c portion = new Portion__c(Name = 'Portion A');
        insert portion;

        // Create Meter Reading Unit (MRU)
        Meter_Reading_Unit__c mru = new Meter_Reading_Unit__c(
            Name = 'MRU001',
            Portion__c = portion.Id
        );
        insert mru;

        // Create Person Account (Account + Contact)
        Account acc = new Account(LastName = 'Test Person Account', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId());
        insert acc;

        Contact con = [SELECT Id, AccountId FROM Contact WHERE AccountId = :acc.Id LIMIT 1];

        // Create Meter Reading Orders (MROs)
        List<Meter_Reading_Order__c> mroList = new List<Meter_Reading_Order__c>();
        for (Integer i = 0; i < 3; i++) {
            mroList.add(new Meter_Reading_Order__c(
                Name = 'MRO ' + i,
                Customer__c = acc.Id,
                Created_Order__c = false,
                MRU__c = mru.Name,
                Meter_Reading_Doc_Number__c = 'DOC00' + i,
                Meter_Reader_Name__c = 'Reader ' + i,
                Business_Partner_Consumer_ID__c = '23232'
            ));
        }
        insert mroList;
    }

    @IsTest
    static void test_getMeterReadingOrderList() {
        Test.startTest();
        List<Meter_Reading_Order__c> result = MeteringAddMROtoMRSController.getMeterReadingOrderList(2, 0);
        Test.stopTest();

        System.assertNotEquals(0, result.size(), 'Expected non-empty MRO list');
        System.assert(result.size() <= 2, 'Result count should respect LIMIT value');
    }

    @IsTest
    static void test_getCurrentMRURecord() {
        Meter_Reading_Schedule__c sched = [SELECT Id FROM Meter_Reading_Schedule__c LIMIT 1];

        Test.startTest();
        Meter_Reading_Schedule__c result = MeteringAddMROtoMRSController.getCurrentMRURecord(sched.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected valid MRS record');
        System.assertEquals(sched.Id, result.Id, 'Returned MRS Id should match input');
    }

    @IsTest
    static void test_addMRO() {
        // Prepare data
        Meter_Reading_Schedule__c sched = [SELECT Id, Agency__c, Agent__c, Meter_Reading_Start_Date__c, Meter_Reading_Completion_Date__c FROM Meter_Reading_Schedule__c LIMIT 1];
        List<Meter_Reading_Order__c> mroList = [SELECT Id, Customer__c, MRU__c, Name, Created_Order__c, 
                                                    Customer_Location__c, Customer_Road_Name__c, Building__c, 
                                                    Customer_Postal_Code__c, Meter_Reading_Doc_Number__c, 
                                                    Customer_Category__c, Meter_Reader_Name__c 
                                                FROM Meter_Reading_Order__c WHERE Created_Order__c = false];

        Test.startTest();
        String response = MeteringAddMROtoMRSController.addMRO(mroList, sched);
        Test.stopTest();

        System.assertEquals('success', response, 'Expected successful operation');

        // Validate that MROs are now marked as created
        for (Meter_Reading_Order__c mro : [SELECT Created_Order__c FROM Meter_Reading_Order__c]) {
            System.assertEquals(true, mro.Created_Order__c, 'Created_Order__c should be true after processing');
        }

        // Validate Work Orders got created correctly
        List<WorkOrder> workOrders = [
            SELECT Id, RecordTypeId, Status, Work_Order_Type__c, Meter_Reading_Schedule__c, Meter_Reading_Order__c, AccountId, Meter_Reading_Unit__c
            FROM WorkOrder
        ];
        System.assert(workOrders.size() > 0, 'Expected WorkOrders to be created');
        System.assertEquals('Scheduled', workOrders[0].Work_Order_Type__c, 'Work Order Type should be Scheduled');
        System.assertEquals('New', workOrders[0].Status, 'Work Order status should be New');
        System.assertEquals(sched.Id, workOrders[0].Meter_Reading_Schedule__c, 'Work Order should link to the correct MRS');
    }

    @IsTest
    static void test_addMRO_noMROs() {
        Meter_Reading_Schedule__c sched = [SELECT Id FROM Meter_Reading_Schedule__c LIMIT 1];

        Test.startTest();
        String response = MeteringAddMROtoMRSController.addMRO(new List<Meter_Reading_Order__c>(), sched);
        Test.stopTest();

        System.assertEquals('No MROs found', response, 'Expected fallback response when list is empty');
    }
}