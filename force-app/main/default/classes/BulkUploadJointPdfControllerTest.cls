@isTest
private class BulkUploadJointPdfControllerTest {
    
    @testSetup
    static void setupTestData() {
        // Create Account
        Account acc = new Account(
            Name = 'Test Account',
            Representative_Company__c = 'Test Company',
            Location__c = 'Test Location'
        );
        insert acc;
        
        // Create User for Assigned_Meter_Reader__c
        Profile sysAdminProfile = [
            SELECT Id 
            FROM Profile 
            WHERE Name = 'System Administrator' 
            LIMIT 1
        ];
        User meterReader = new User(
            Alias = 'mtrdr',
            Email = 'meterreader' + DateTime.now().getTime() + '@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'MeterReader',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = sysAdminProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'meterreader' + DateTime.now().getTime() + '@test.com'
        );
        insert meterReader;
        
        OperatingHours oh = new OperatingHours(
            Name = System.Label.Default_Operating_Hours_Name,
            TimeZone = 'America/Los_Angeles' // Required field for OperatingHours
        );
        insert oh;
        
        ServiceTerritory st=new ServiceTerritory(
        	name='Territory',
        	IsActive=true,
            OperatingHoursId=oh.Id
        );
        insert st;
		
		ServiceResource sr=new ServiceResource(
            name='Resource',
            IsActive=true,
            RelatedRecordId=UserInfo.getUserId()
        );
        insert sr;
        
        ServiceTerritoryMember stm=new ServiceTerritoryMember(
            ServiceTerritoryId=st.Id,
            ServiceResourceId=sr.Id,
            EffectiveStartDate=System.Today()
        );
        insert stm;
        
        // Create WorkOrder
        WorkOrder wo = new WorkOrder(
            AccountId = acc.Id,
            Status = 'Open',
            Customer_Name__c = 'Customer X',
            Assigned_Meter_Reader__c = sr.Id,
            Check_In_Date_Time__c = System.now(),
            Approvar_Date__c = Date.today(),
            From_Date__c = Date.today().addDays(-5),
            To_Date__c = Date.today(),
            Final_Meter_Reading__c = 120,
            StartDate = System.now(),
            EndDate = System.now().addDays(2),
            Check_Out_Date_Time__c = System.now(),
            Approval_Date_Time__c =System.now(),
            Live_Reading_Date_Time__c=System.now()
        );
        insert wo;
        
        // Create Dispenser Points
        List<Dispenser_Point__c> dpList = new List<Dispenser_Point__c>{
            new Dispenser_Point__c(
                WorkOrderID__c = wo.Id,
                Dispenser_Number__c = 'D1',
                Is_Progressive__c = 'No',
                Remark__c = 'Needs Maintenance',
                Dispenser_Name__c = 'Disp A',
                Live_Reading__c = 100,
                Opening_Reading__c = 10,
                Closing_Reading__c = 20,
                Jumping_Qty__c = 1,
                Other_Qty__c = 2,
                Calibration_Qty__c = 3
            ),
            new Dispenser_Point__c(
                WorkOrderID__c = wo.Id,
                Dispenser_Number__c = 'D2',
                Is_Progressive__c = 'Yes',
                Dispenser_Name__c = 'Disp B',
                Live_Reading__c = 200,
                Opening_Reading__c = 20,
                Closing_Reading__c = 40,
                Live__c=true
            )
        };
        insert dpList;
        
        // Create ContentDocument, ContentVersion, and ContentDocumentLink
        ContentVersion cv = new ContentVersion(
            Title = System.Label.CNG_PDF_Signature_File_Name,
            PathOnClient = 'Test.pdf',
            VersionData = Blob.valueOf('Test Content')
        );
        insert cv;
        
        cv=[SELECT Id,ContentDocumentId FROM ContentVersion WHERE Id=:cv.Id LIMIT 1];
        
        ContentDocument cd = [
            SELECT Id 
            FROM ContentDocument 
            WHERE Id = :cv.ContentDocumentId
            LIMIT 1
        ];
        
        insert new ContentDocumentLink(
            ContentDocumentId = cd.Id,
            LinkedEntityId = wo.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
    }
    
    @isTest
    static void testControllerWithRecords() {
        Id woId = [SELECT Id FROM WorkOrder LIMIT 1].Id;
        
        Test.startTest();
        Test.setCurrentPage(Page.BulkUploadJointPdf); // Replace with your actual VF page name
        ApexPages.currentPage().getParameters().put('ids', String.valueOf(woId));
        
        BulkUploadJointPdfController controller = new BulkUploadJointPdfController();
        
        System.assertNotEquals(0, controller.tickets.size(), 'Tickets should be populated');
        System.assertNotEquals(null, controller.tickets[0].ticket, 'Ticket record should not be null');
        System.assertEquals(11, controller.tickets[0].dispenserListLeft.size(), 'Left dispenser list should have 11 entries');
        System.assertEquals(11, controller.tickets[0].dispenserListRight.size(), 'Right dispenser list should have 11 entries');
        System.assertNotEquals(null, controller.tickets[0].fileDownloadUrl, 'File download URL should be populated');
        Test.stopTest();
    }
    
    @isTest
    static void testControllerWithNoRecords() {
        Test.startTest();
        Test.setCurrentPage(Page.BulkUploadJointPdf); // Replace with your VF page name
        ApexPages.currentPage().getParameters().put('ids', '');
        
        BulkUploadJointPdfController controller = new BulkUploadJointPdfController();
        System.assertEquals(0, controller.tickets.size(), 'Tickets should be empty when no IDs are provided');
        Test.stopTest();
    }
}