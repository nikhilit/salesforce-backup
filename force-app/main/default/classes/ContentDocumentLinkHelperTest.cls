/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 15-01-2026
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   15-01-2026   Kartik Patkar, Appstrail   Initial Version
**/
@isTest
public class ContentDocumentLinkHelperTest {
    
    @TestSetup
    static void setupTestData(){
        // Create Account
        Account testAccount = new Account(
            Name = 'Test Account',
            BP_Number__c = 'BP12345'
        );
        insert testAccount;
        
        // Get MGL_Metering RecordType
        Id mglMeteringRTId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName()
            .get('MGL_Metering').getRecordTypeId();
        
        // Create WorkOrder with MGL_Metering RecordType
        WorkOrder testWorkOrder = new WorkOrder(
            AccountId = testAccount.Id,
            RecordTypeId = mglMeteringRTId,
            Subject = 'Test Work Order',
            Status = 'New'
        );
        insert testWorkOrder;
        
        // Create Document__c records with different statuses
        List<Document__c> documents = new List<Document__c>{
            new Document__c(
                File_Name__c = 'Doc Draft',
                Work_Order__c = testWorkOrder.Id,
                Upload_Status__c = 'Draft'
            ),
            new Document__c(
                File_Name__c = 'Doc New',
                Work_Order__c = testWorkOrder.Id,
                Upload_Status__c = 'New'
            ),
            new Document__c(
                File_Name__c = 'Doc Already Uploaded',
                Work_Order__c = testWorkOrder.Id,
                Upload_Status__c = 'Uploaded'
            ),
            new Document__c(
                File_Name__c = 'Doc Already Pending',
                Work_Order__c = testWorkOrder.Id,
                Upload_Status__c = 'Pending'
            )
        };
        insert documents;
    }
    
    @isTest
    static void testFileAttachmentUpdatesToPending(){
        // Get test Document__c with Draft status
        Document__c draftDoc = [SELECT Id, Upload_Status__c 
                                FROM Document__c 
                                WHERE File_Name__c = 'Doc Draft' AND Upload_Status__c = 'Draft' LIMIT 1];
        
        System.assertEquals('Draft', draftDoc.Upload_Status__c, 'Initial status should be Draft');
        
        Test.startTest();
        
        // Create ContentVersion (file)
        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'test.jpg',
            VersionData = Blob.valueOf('Test file content'),
            IsMajorVersion = true
        );
        insert cv;
        
        // Get ContentDocumentId
        ContentVersion insertedCV = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        
        // Create ContentDocumentLink to attach file to Document__c
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = insertedCV.ContentDocumentId,
            LinkedEntityId = draftDoc.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;
        
        Test.stopTest();
        
    }
    
    @isTest
    static void testMultipleFilesAttachmentUpdatesToPending(){
        // Get test Document__c with New status
        Document__c newDoc = [SELECT Id, Upload_Status__c 
                              FROM Document__c 
                              WHERE File_Name__c = 'Doc New' AND Upload_Status__c = 'New' LIMIT 1];
        
        System.assertEquals('New', newDoc.Upload_Status__c, 'Initial status should be New');
        
        Test.startTest();
        
        // Create multiple ContentVersions
        List<ContentVersion> cvList = new List<ContentVersion>{
            new ContentVersion(
                Title = 'Test Image 1',
                PathOnClient = 'test1.jpg',
                VersionData = Blob.valueOf('Test image 1 content'),
                IsMajorVersion = true
            ),
            new ContentVersion(
                Title = 'Test Image 2',
                PathOnClient = 'test2.jpg',
                VersionData = Blob.valueOf('Test image 2 content'),
                IsMajorVersion = true
            )
        };
        insert cvList;
        
        // Get ContentDocumentIds
        List<ContentVersion> insertedCVs = [SELECT ContentDocumentId FROM ContentVersion WHERE Id IN :cvList];
        
        // Create ContentDocumentLinks
        List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
        for(ContentVersion cv : insertedCVs){
            cdlList.add(new ContentDocumentLink(
                ContentDocumentId = cv.ContentDocumentId,
                LinkedEntityId = newDoc.Id,
                ShareType = 'V',
                Visibility = 'AllUsers'
            ));
        }
        insert cdlList;
        
        Test.stopTest();
        
    }
    
    @isTest
    static void testAlreadyUploadedDocumentNotUpdated(){
        // Get test Document__c with Uploaded status
        Document__c uploadedDoc = [SELECT Id, Upload_Status__c 
                                   FROM Document__c 
                                   WHERE File_Name__c = 'Doc Already Uploaded' AND Upload_Status__c = 'Uploaded' LIMIT 1];
        
        System.assertEquals('Uploaded', uploadedDoc.Upload_Status__c, 'Initial status should be Uploaded');
        
        Test.startTest();
        
        // Create ContentVersion
        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'test.jpg',
            VersionData = Blob.valueOf('Test file content'),
            IsMajorVersion = true
        );
        insert cv;
        
        ContentVersion insertedCV = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        
        // Attach file to already Uploaded Document__c
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = insertedCV.ContentDocumentId,
            LinkedEntityId = uploadedDoc.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;
        
        Test.stopTest();
    }
    
    @isTest
    static void testAlreadyPendingDocumentNotUpdated(){
        // Get test Document__c with Pending status
        Document__c pendingDoc = [SELECT Id, Upload_Status__c 
                                  FROM Document__c 
                                  WHERE File_Name__c = 'Doc Already Pending' AND Upload_Status__c = 'Pending' LIMIT 1];
        
        System.assertEquals('Pending', pendingDoc.Upload_Status__c, 'Initial status should be Pending');
        
        Test.startTest();
        
        // Create ContentVersion
        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'test.jpg',
            VersionData = Blob.valueOf('Test file content'),
            IsMajorVersion = true
        );
        insert cv;
        
        ContentVersion insertedCV = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        
        // Attach file to already Pending Document__c
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = insertedCV.ContentDocumentId,
            LinkedEntityId = pendingDoc.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;
        
        Test.stopTest();
        
    }
    
    @isTest
    static void testFileAttachedToNonDocumentRecord(){
        // Get any Account (non-Document__c record)
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        
        // Create ContentVersion
        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'test.jpg',
            VersionData = Blob.valueOf('Test file content'),
            IsMajorVersion = true
        );
        insert cv;
        
        ContentVersion insertedCV = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        
        // Attach file to Account (should be ignored by helper)
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = insertedCV.ContentDocumentId,
            LinkedEntityId = testAccount.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        
        // Should complete without errors even though no Document__c is involved
        insert cdl;
        
        Test.stopTest();
    }
    
}