/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 11-08-2025
 * @last modified by  : Kartik Patkar Appstrail 
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   11-08-2025   Kartik Patkar, Appstrail   Initial Version
**/
@isTest
private class TestJointTicketPDFControllerFixed {

    @testSetup
    static void setupTestData() {
        String unique = String.valueOf(DateTime.now().getTime());
        Profile p = [SELECT Id FROM Profile WHERE UserLicense.Name = 'Salesforce' LIMIT 1];

        User approverUser = new User(
            FirstName = 'Test', LastName = 'Approver',
            Email = 'approver' + unique + '@test.com',
            Username = 'approver' + unique + '@test.com',
            Alias = 'appr' + unique.substring(unique.length() - 4),
            TimeZoneSidKey = 'Asia/Kolkata', LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8', ProfileId = p.Id, LanguageLocaleKey = 'en_US'
        );
        insert approverUser;

        User meterReaderUser = new User(
            FirstName = 'Meter', LastName = 'Reader',
            Email = 'reader' + unique + '@test.com',
            Username = 'reader' + unique + '@test.com',
            Alias = 'mrd' + unique.substring(unique.length() - 4),
            TimeZoneSidKey = 'Asia/Kolkata', LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8', ProfileId = p.Id, LanguageLocaleKey = 'en_US'
        );
        insert meterReaderUser;

        Account acc = new Account(Name = 'Test Account', Location__c = 'Test', Representative_Company__c = 'RepCo');
        insert acc;

        ServiceResource sr = new ServiceResource(Name = 'Test SR', IsActive = true, RelatedRecordId = meterReaderUser.Id);
        insert sr;

        WorkOrder wo = new WorkOrder(
            AccountId = acc.Id, Subject = 'Test WO', Status = 'New',
            StartDate = Date.today(), EndDate = Date.today().addDays(1),
            From_Date__c = Date.today().addDays(-2), To_Date__c = Date.today(),
            Check_In_Date_Time__c = DateTime.now(), Approvar_Date__c = Date.today(),
            Approvar_User__c = approverUser.Id, Assigned_Meter_Reader__c = sr.Id,
            Final_Meter_Reading__c = 123
        );
        insert wo;

        // CNG_Meter_Reading__c correctMeterReading = new CNG_Meter_Reading__c(Name = 'Test Reading');
        // insert correctMeterReading;

        List<Dispenser_Point__c> dpList = new List<Dispenser_Point__c>();
        for (Integer i = 0; i < 3; i++) {
            dpList.add(new Dispenser_Point__c(
                WorkOrderID__c = wo.Id, 
                Dispenser_Number__c = 'D-' + i, Dispenser_Name__c = 'Dispenser ' + i,
                Remark__c = (i == 1 ? 'Remark' : null), Is_Progressive__c = (i == 0 ? 'Yes' : 'No'),
                Opening_Reading__c = 10, Closing_Reading__c = 20, Jumping_Qty__c = 1,
                Other_Qty__c = 1, Calibration_Qty__c = 1, Live_Reading__c = 100,
                Dispenser_Number_Value__c = i
            ));
        }
        insert dpList;

        ContentVersion cv = new ContentVersion(
            Title = 'Test PDF', PathOnClient = 'test.pdf', VersionData = Blob.valueOf('PDF content')
        );
        insert cv;

        List<ContentVersion> contentList = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
            LIMIT 1
        ];
        if (!contentList.isEmpty()) {
            insert new ContentDocumentLink(
                ContentDocumentId = contentList[0].ContentDocumentId,
                LinkedEntityId = wo.Id,
                ShareType = 'V'
            );
        }
    }

    @isTest
    static void testController() {
        Id woId = [SELECT Id FROM WorkOrder LIMIT 1].Id;
        PageReference pg = new PageReference('/apex/JointTicketPDF');
        pg.getParameters().put('id', woId);
        Test.setCurrentPage(pg);

        Test.startTest();
        JointTicketPDFController ctrl = new JointTicketPDFController();
        Test.stopTest();
    }
}