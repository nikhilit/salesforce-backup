@isTest
private class O_MMeterDetailContr_Test {

    @isTest
    static void testControllerWithValidWorkOrder() {
        // Create Account
        Account acc = new Account(
            FirstName__c = 'John',
            LastName__c = 'Doe',
            Customer_Contact_no__c = '9876543210',
            Name = 'John Doe'
        );
        insert acc;

        // Create User to act as Agent
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User agent = new User(
            Alias = 'testusr',
            Email = 'testuser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Agent',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            UserName = 'testuser' + System.currentTimeMillis() + '@test.com'
        );
        insert agent;

        // Create WorkOrder
        WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            AccountId = acc.Id,
            New_Rubber_Hose__c = Date.today(),
            The_Work_Done__c = 'Test Work Done',
            Satisfactory__c = true,
            Not_Satisfactory__c = false,
            Meter_Reading_RH__c = '123',
            Meter_Number_RH__c = 'MTR-456',
            Status = 'Open'
        );
        insert wo;

        // Create a file (ContentVersion → ContentDocumentLink)
        ContentVersion cv = new ContentVersion(
            Title = 'New Rubber Hose Image',
            PathOnClient = 'test.txt',
            VersionData = Blob.valueOf('dummy content')
        );
        insert cv;

        Id contentDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = contentDocId,
            LinkedEntityId = wo.Id,
            ShareType = 'I'
        );
        insert cdl;

        // Set VF Page and pass WorkOrder Id
        Test.startTest();
        PageReference pageRef = new PageReference('/apex/O_MMeterDetails');
        pageRef.getParameters().put('id', wo.Id);
        Test.setCurrentPage(pageRef);

        // Instantiate controller
        O_MMeterDetailContr controller = new O_MMeterDetailContr();
        Test.stopTest();

        
    }

    @isTest
    static void testControllerWithoutIdParam() {
        Test.startTest();
        PageReference pageRef = new PageReference('/apex/O_MMeterDetails');
        Test.setCurrentPage(pageRef);

        O_MMeterDetailContr controller = new O_MMeterDetailContr();
        Test.stopTest();

       
    }
}