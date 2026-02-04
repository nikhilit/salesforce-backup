@isTest
public class TestIndirectMeterImageTaggingHelper {

    @isTest
    static void testAttachFileToWorkOrder_MatchingWO() {
        Account acc = new Account(
            Name = 'Test Account',
            BP_Number__c = 'BP1001' 
        );
        insert acc;

        WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            Status = 'New',
            Priority = 'Medium',
            AccountId = acc.Id,
            Meter_Reading_Doc_Number__c = 'MRO123'
        );
        insert wo;

        List<ContentVersion> cvs = new List<ContentVersion>();
        for (Integer i = 0; i < 2; i++) {
            cvs.add(new ContentVersion(
                Title = 'Test File ' + i,
                PathOnClient = 'TestFile' + i + '.txt',
                VersionData = Blob.valueOf('Test content ' + i),
                In_Direct_Meter_Reading__c = true,
                BP_Number__c = 'BP1001',
                MRO_Doc_Number__c = 'MRO123'
            ));
        }
        insert cvs;

        cvs = [
            SELECT Id, ContentDocumentId, In_Direct_Meter_Reading__c, BP_Number__c, MRO_Doc_Number__c
            FROM ContentVersion
            WHERE Id IN :cvs
        ];

        Test.startTest();
        IndirectMeterImageTaggingHelper.attachFileToWorkOrder(cvs);
        Test.stopTest();

        List<Meter_Reading_OCR__c> ocrList = [
            SELECT Id, Work_Order__c, BP_Number__c, Status__c
            FROM Meter_Reading_OCR__c
            WHERE Work_Order__c = :wo.Id
        ];
        //System.assertEquals(2, ocrList.size(), 'Two Meter_Reading_OCR__c records created');
        for (Meter_Reading_OCR__c o : ocrList) {
            System.assertEquals('Pending', o.Status__c);
        }

        Set<Id> contentDocIds = new Set<Id>();
        for (ContentVersion cv : cvs) {
            if (cv.ContentDocumentId != null) {
                contentDocIds.add(cv.ContentDocumentId);
            }
        }

        if (!contentDocIds.isEmpty()) {
            List<ContentDocumentLink> cdlList = [
                SELECT ContentDocumentId, LinkedEntityId, ShareType
                FROM ContentDocumentLink
                WHERE ContentDocumentId IN :contentDocIds
            ];
            //System.assertEquals(2, cdlList.size(), 'Two ContentDocumentLinks expected');
            for (ContentDocumentLink cdl : cdlList) {
                System.assertEquals('I', cdl.ShareType);
            }
        }
    }

    @isTest
    static void testAttachFileToWorkOrder_NoMatch() {
        ContentVersion cv = new ContentVersion(
            Title = 'No Match File',
            PathOnClient = 'NoMatch.txt',
            VersionData = Blob.valueOf('Random content'),
            In_Direct_Meter_Reading__c = true,
            BP_Number__c = 'BP_NO_MATCH',
            MRO_Doc_Number__c = 'MRO_NO_MATCH'
        );
        insert cv;

        cv = [
            SELECT Id, ContentDocumentId, In_Direct_Meter_Reading__c, BP_Number__c, MRO_Doc_Number__c
            FROM ContentVersion
            WHERE Id = :cv.Id
        ];

        Test.startTest();
        IndirectMeterImageTaggingHelper.attachFileToWorkOrder(new List<ContentVersion>{ cv });
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Meter_Reading_OCR__c]);
    }
}