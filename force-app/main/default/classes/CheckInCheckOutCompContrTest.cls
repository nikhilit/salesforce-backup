@IsTest
private class CheckInCheckOutCompContrTest {

    private static Map<String, Id> makeData() {
        Map<String, Id> ids = new Map<String, Id>();

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            FirstName = 'T',
            LastName  = 'User',
            Email = 'tuser' + System.currentTimeMillis() + '@example.com',
            Username = 'tuser' + System.currentTimeMillis() + '@example.com',
            Alias = 'tusr',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert u;
        ids.put('UserId', u.Id);

        OperatingHours oph = new OperatingHours(Name = 'Test OPH', TimeZone = 'Asia/Kolkata');
        insert oph;
        ids.put('OphId', oph.Id);

        ServiceTerritory st = new ServiceTerritory(Name = 'Test Territory', IsActive = true, OperatingHoursId = oph.Id);
        insert st;
        ids.put('TerritoryId', st.Id);

        ServiceResource sr = new ServiceResource(Name = 'Tech Resource', IsActive = true, RelatedRecordId = u.Id);
        insert sr;
        ids.put('ResourceId', sr.Id);

        ServiceTerritoryMember stm = new ServiceTerritoryMember(
            ServiceTerritoryId = st.Id,
            ServiceResourceId  = sr.Id,
            EffectiveStartDate = Date.today().addDays(-10),
            EffectiveEndDate   = Date.today().addYears(1)
        );
        insert stm;
        ids.put('StmId', stm.Id);

        Account a = new Account(Name = 'Acme');
        insert a;
        ids.put('AccountId', a.Id);

        WorkOrder wo = new WorkOrder(AccountId = a.Id, Status = 'New', Subject = 'WO for SA');
        insert wo;
        ids.put('WorkOrderId', wo.Id);

        ServiceAppointment sa1 = new ServiceAppointment(
            ParentRecordId    = wo.Id,
            Status            = 'In Progress', 
            ServiceTerritoryId = st.Id,
            SchedStartTime    = System.now().addMinutes(5),
            SchedEndTime      = System.now().addMinutes(35)
        );
        sa1.put('Scheduled_Location__latitude__s', 12.9716);
        sa1.put('Scheduled_Location__longitude__s', 77.5946);
        insert sa1;
        ids.put('ServiceApptId', sa1.Id);

        ServiceAppointment sa2 = new ServiceAppointment(
            ParentRecordId    = wo.Id,
            Status            = 'In Progress',
            ServiceTerritoryId = st.Id,
            SchedStartTime    = System.now().addMinutes(10),
            SchedEndTime      = System.now().addMinutes(40)
        );
        sa2.put('Scheduled_Location__latitude__s', 12.9716);
        sa2.put('Scheduled_Location__longitude__s', 77.5946);
        insert sa2;
        ids.put('ServiceApptFarId', sa2.Id);

        return ids;
    }


    @IsTest
    static void test_getCheckInStatus_byServiceAppointment() {
        Map<String, Id> ids = makeData();

        Test.startTest();
        ServiceAppointment got = CheckInCheckOutCompContr.getCheckInStatus(String.valueOf(ids.get('ServiceApptId')));
        Test.stopTest();

        System.assertNotEquals(null, got);
        System.assertEquals(ids.get('ServiceApptId'), got.Id);
    }

    @IsTest
    static void test_getCheckInStatus_byWorkOrder() {
        Map<String, Id> ids = makeData();

        Test.startTest();
        ServiceAppointment got = CheckInCheckOutCompContr.getCheckInStatus(String.valueOf(ids.get('WorkOrderId')));
        Test.stopTest();

        System.assertNotEquals(null, got);
        ServiceAppointment gotFull = [
            SELECT Id, ParentRecordId FROM ServiceAppointment WHERE Id = :got.Id
        ];
        System.assertEquals(ids.get('WorkOrderId'), gotFull.ParentRecordId);
    }

    @IsTest
    static void test_updateServiceAppointment_missingValues() {
        Test.startTest();
        String res = CheckInCheckOutCompContr.updateServiceAppoinment(null, null, null, true, System.now());
        Test.stopTest();

        System.assertEquals('MISSING_VALUES', res);
    }

    @IsTest
    static void test_updateServiceAppointment_tooFar() {
        Map<String, Id> ids = makeData();

        Double farLat = 12.9716d + 5.0d;
        Double farLon = 77.5946d;

        Test.startTest();
        String res = CheckInCheckOutCompContr.updateServiceAppoinment(
            String.valueOf(ids.get('ServiceApptFarId')),
            farLat, farLon,
            true,
            System.now()
        );
        Test.stopTest();

        System.assertEquals('TOO_FAR_FROM_LOCATION', res);
    }

    @IsTest
    static void test_updateServiceAppointment_checkInSuccess() {
        Map<String, Id> ids = makeData();

        Test.startTest();
        String res = CheckInCheckOutCompContr.updateServiceAppoinment(
            String.valueOf(ids.get('ServiceApptId')),
            12.9716d, 77.5946d,   
            true,
            System.now()
        );
        Test.stopTest();

        System.assertEquals('Check In Successfully', res);

        ServiceAppointment sa = [
            SELECT O_MCheckInTimestamp__c, Check_In_Lat_Long__latitude__s, Check_In_Lat_Long__longitude__s, Status
            FROM ServiceAppointment WHERE Id = :ids.get('ServiceApptId')
        ];
        System.assertNotEquals(null, sa.O_MCheckInTimestamp__c);
        System.assertEquals('In Progress', sa.Status);
    }

    @IsTest
    static void test_updateServiceAppointment_checkOutSuccess() {
        Map<String, Id> ids = makeData();

        Test.startTest();
        String res = CheckInCheckOutCompContr.updateServiceAppoinment(
            String.valueOf(ids.get('ServiceApptId')),
            12.9716d, 77.5946d,
            false,                 
            System.now()
        );
        Test.stopTest();

        System.assertEquals('Check Out Successfully', res);

        ServiceAppointment sa = [
            SELECT O_MCheckOutTimestamp__c, Check_Out_Lat_Long__latitude__s, Check_Out_Lat_Long__longitude__s, Status
            FROM ServiceAppointment WHERE Id = :ids.get('ServiceApptId')
        ];
        System.assertNotEquals(null, sa.O_MCheckOutTimestamp__c);
        System.assertEquals('Completed', sa.Status);
    }
}