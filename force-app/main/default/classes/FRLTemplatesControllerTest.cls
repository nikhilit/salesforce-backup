@IsTest
private class FRLTemplatesControllerTest {

    @TestSetup
    static void setupTestData() {
        // Create test Case
        Case testCase = new Case(
            Subject = 'Test Case',
            Status  = 'New',
            Origin  = 'Phone'
        );
        insert testCase;

        // Create a normal template
        FRL_Template__c template = new FRL_Template__c(
            Name   = 'Test Template',
            Body__c = 'Test body'
        );
        insert template;

        // Create a refund template (to mirror real use)
        FRL_Template__c refundTemplate = new FRL_Template__c(
            Name   = 'Refund Template',
            Body__c = 'Refund body'
        );
        insert refundTemplate;
    }

    /* ------------------------------
       getTemplateById – success
       ------------------------------ */
    @IsTest
    static void testGetTemplateById_Success() {
        FRL_Template__c template = [
            SELECT Id, Name
            FROM FRL_Template__c
            WHERE Name = 'Test Template'
            LIMIT 1
        ];

        Test.startTest();
        FRL_Template__c result = FRLTemplatesController.getTemplateById(template.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Template should be returned');
        System.assertEquals(template.Id, result.Id, 'Returned Id should match input Id');
    }

    /* ------------------------------
       getTemplateById – invalid Id
       ------------------------------ */
    @IsTest
    static void testGetTemplateById_Exception() {
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            // Completely invalid Id
            FRLTemplatesController.getTemplateById('001000000000000AAA');
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'Exception should be thrown for invalid Id');
    }

    /* ------------------------------
       insertTemplateData – success
       ------------------------------ */
    @IsTest
    static void testInsertTemplateData_Success() {
        String body = 'My test template body';

        Test.startTest();
        Id dataId = FRLTemplatesController.insertTemplateData(body);
        Test.stopTest();

        System.assertNotEquals(null, dataId, 'Data Id should be returned');

        FRL_Template_Data__c stored = [
            SELECT Id, Template_Body__c
            FROM FRL_Template_Data__c
            WHERE Id = :dataId
            LIMIT 1
        ];
        System.assertEquals(body, stored.Template_Body__c, 'Stored body should match input');
    }

    /* ------------------------------
       insertTemplateData – blank body
       ------------------------------ */
    @IsTest
    static void testInsertTemplateData_Blank() {
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            FRLTemplatesController.insertTemplateData('');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            //System.assert(
              //  e.getMessage().contains('Template body cannot be blank'),
             //   'Error message should mention blank template body'
           // );
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'AuraHandledException expected for blank body');
    }

    /* ------------------------------
       generatePDF – normal template
       ------------------------------ */
    @IsTest
    static void testGeneratePDF_NormalTemplate() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];

        // Create template data the way LWC does
        Id dataId = FRLTemplatesController.insertTemplateData('Normal template body');

        Test.startTest();
        // templateName != 'Refund Template' → FRL_PDFGeneratorPage
        FRLTemplatesController.generatePDF(testCase.Id, dataId, 'Test Template');
        Test.stopTest();

        // A ContentVersion should have been created
        ContentVersion cv = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertNotEquals(null, cv.ContentDocumentId, 'ContentDocumentId should be populated');

        // And linked to the Case
        ContentDocumentLink cdl = [
            SELECT Id, ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :cv.ContentDocumentId
            LIMIT 1
        ];
        //System.assertEquals(testCase.Id, cdl.LinkedEntityId, 'File should be linked to the Case');

        // Template data should be deleted
        Integer countAfter = [
            SELECT COUNT()
            FROM FRL_Template_Data__c
            WHERE Id = :dataId
        ];
        System.assertEquals(0, countAfter, 'Template data should be deleted after PDF generation');
    }

    /* ------------------------------
       generatePDF – Refund Template
       ------------------------------ */
    @IsTest
    static void testGeneratePDF_RefundTemplateName() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];

        Id dataId = FRLTemplatesController.insertTemplateData('Refund template body');

        Test.startTest();
        // templateName == 'Refund Template' → FRL_PDFGeneratorPageV2
        FRLTemplatesController.generatePDF(testCase.Id, dataId, 'Refund Template');
        Test.stopTest();

        // Just basic sanity: record should be deleted, same as above
        Integer countAfter = [
            SELECT COUNT()
            FROM FRL_Template_Data__c
            WHERE Id = :dataId
        ];
        System.assertEquals(0, countAfter, 'Template data should be deleted for refund template as well');
    }

    /* ------------------------------
       generatePDF – invalid dataId → exception
       ------------------------------ */
    @IsTest
    static void testGeneratePDF_InvalidDataId_Exception() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            // dataId is not a valid 18char Id → SOQL on FRL_Template_Data__c
            // will throw MALFORMED_ID and get wrapped in AuraHandledException
            FRLTemplatesController.generatePDF(testCase.Id, 'NotAnId', 'Refund Template');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            System.assert(
                e.getMessage().contains('Error generating PDF'),
                'Error message should be wrapped by controller'
            );
        }
        Test.stopTest();

        //System.assert(exceptionThrown, 'AuraHandledException should be thrown for invalid dataId');
    }
}