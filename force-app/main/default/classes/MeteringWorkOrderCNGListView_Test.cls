@isTest
private class MeteringWorkOrderCNGListView_Test {

    @testSetup 
    static void setupData() {
        String gsRecordTypeID = Schema.getGlobalDescribe().get('WorkOrder').getDescribe().getRecordTypeInfosByDeveloperName().get('MGL_Metering').getRecordTypeId();

        // Account
        Account acc = new Account(
            Name = 'CNG Account',
            Category__c = 'CNG/LNG',
            Location__c = 'Mumbai',
            Zone__c = 'West',
            Representative_Company__c = 'BPCL'
        );
        insert acc;

        // WorkOrder
        WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            Status = 'New',
            RecordTypeId = gsRecordTypeID,
            AccountId = acc.Id,
            Appointment_Status__c = 'Completed',
            From_Date__c = Date.today(),
            To_Date__c = Date.today()
        );
        insert wo;

        // Dispenser_Point__c
        Dispenser_Point__c dp = new Dispenser_Point__c(
			Dispenser_Number__c='1',
            WorkOrderID__c = wo.Id
        );
        insert dp;

        // ContentVersion + Link
        ContentVersion cv = new ContentVersion(
            Title = 'Image',
            VersionData = Blob.valueOf('test'),
            PathOnClient = 'a.jpg'
        );
        insert cv;
        Id cdId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        insert new ContentDocumentLink(
            ContentDocumentId = cdId,
            LinkedEntityId = wo.Id,
            ShareType = 'V'
        );

    }

    @isTest
    static void test_getColumnInfo_and_datatableColumns() {
        Test.startTest();
        MeteringWorkOrderCNGListViewController.DataWrapper dw =
            MeteringWorkOrderCNGListViewController.getColumnInfo('CNG_Meter_Readings');
        Test.stopTest();

    }

    @isTest
    static void test_getCNGWorkOrderRecords() {
        MeteringWorkOrderCNGListViewController.DataWrapper dw =
            MeteringWorkOrderCNGListViewController.getColumnInfo('CNG_Meter_Readings');

        Test.startTest();
        Map<String, Object> res = MeteringWorkOrderCNGListViewController.getCNGWorkOrderRecords(dw, '10');
        Test.stopTest();

    }

    @isTest
    static void test_getCNGWorkOrderFilterRecords() {
        MeteringWorkOrderCNGListViewController.DataWrapper dw =
            MeteringWorkOrderCNGListViewController.getColumnInfo('CNG_Meter_Readings');
List<String> listString=new List<String>();
        listString.add('1234');
        Test.startTest();
        Map<String, Object> res = MeteringWorkOrderCNGListViewController.getCNGWorkOrderFilterRecords(
            dw,
            Date.today(),
            Date.today(),
            'Completed',
            'Agency',
            'Agent',
            'BPCL',
            'West',
            'Mumbai',
            '001xx000003',
            '5',
            'Pending',
            'Dispenser Point',
            'CNG',
            'Sumit',
            'Mumbai',
            listString
        );
        Test.stopTest();

    }

    @isTest
    static void test_getExcelData() {
        MeteringWorkOrderCNGListViewController.DataWrapper dw =
            MeteringWorkOrderCNGListViewController.getColumnInfo('CNG_Meter_Readings');

        Test.startTest();
        List<String> listString=new List<String>();
        listString.add('1234');
        Map<String, Object> res = MeteringWorkOrderCNGListViewController.getExcelData(
            dw,
            Date.today(),
            Date.today(),
            'Completed',
            'Agency',
            'Agent',
            'BPCL',
            'West',
            'Mumbai',
            null,
            '10',
            'Pending',
            listString,
            'Dispenser Point',
            'CNG',
            'Sumit',
            'Mumbai'

        );
        Test.stopTest();

    }

    @isTest
    static void test_getAccountOptions() {
        Test.startTest();
        List<MeteringWorkOrderCNGListViewController.OptionsWrapper> opts =
            MeteringWorkOrderCNGListViewController.getAccountOptions('Representative_Company__c');
        Test.stopTest();

    }
}