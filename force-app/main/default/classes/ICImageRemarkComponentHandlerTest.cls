@isTest
public class ICImageRemarkComponentHandlerTest {

    @isTest
    static void testSaveImage() {
        Account acc = new Account(Name = 'Test Account', BP_Number__c = 'BP123456');
        insert acc;

        WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            AccountId = acc.Id,
            Status = 'New'
        );
        insert wo;

        ICImageRemarkComponentHandler.FileWrapper fw = new ICImageRemarkComponentHandler.FileWrapper();
        fw.base64Data = EncodingUtil.base64Encode(Blob.valueOf('test image data'));
        fw.fileName = 'test.jpg';
        fw.label = 'Test File';

        List<ICImageRemarkComponentHandler.FileWrapper> files = new List<ICImageRemarkComponentHandler.FileWrapper>{ fw };

        Test.startTest();
        ICImageRemarkComponentHandler.saveImage(files, wo.Id, 'Test Remark', 'FakeWorkStep', '');
        Test.stopTest();

        List<ContentVersion> cvs = [SELECT Id, Title FROM ContentVersion WHERE Title = 'Test File'];
        System.assertEquals(1, cvs.size(), 'One ContentVersion should be inserted');
    }

    @isTest
    static void testSaveImageWithSignature() {
        Account acc = new Account(Name = 'Test Account', BP_Number__c = 'BP789123');
        insert acc;

        WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            AccountId = acc.Id,
            Status = 'New'
        );
        insert wo;

        ICImageRemarkComponentHandler.FileWrapper fw = new ICImageRemarkComponentHandler.FileWrapper();
        fw.base64Data = EncodingUtil.base64Encode(Blob.valueOf('image'));
        fw.fileName = 'signed.jpg';
        fw.label = 'Signed File';

        List<ICImageRemarkComponentHandler.FileWrapper> files = new List<ICImageRemarkComponentHandler.FileWrapper>{ fw };
        String fakeSignature = EncodingUtil.base64Encode(Blob.valueOf('signature'));

        Test.startTest();
        ICImageRemarkComponentHandler.saveImage(files, wo.Id, 'Remark with signature', 'AnotherFakeStep', fakeSignature);
        Test.stopTest();

        WorkOrder updatedWO = [SELECT Signature__c FROM WorkOrder WHERE Id = :wo.Id];
        //System.assert(updatedWO.Signature__c.contains('data:image/png;base64'), 'Signature image tag should be present');
    }

    @isTest
    static void testSavePaymentDetail() {
        Account acc = new Account(Name = 'Payment Acc', BP_Number__c = 'BP000111');
        insert acc;

        WorkOrder wo = new WorkOrder(
            Subject = 'Payment WO',
            AccountId = acc.Id,
            Status = 'New'
        );
        insert wo;

        ICImageRemarkComponentHandler.FileWrapper fw = new ICImageRemarkComponentHandler.FileWrapper();
        fw.base64Data = EncodingUtil.base64Encode(Blob.valueOf('pay image'));
        fw.fileName = 'pay.jpg';
        fw.label = 'Payment File';

        List<ICImageRemarkComponentHandler.FileWrapper> files = new List<ICImageRemarkComponentHandler.FileWrapper>{ fw };

        Test.startTest();
        ICImageRemarkComponentHandler.savePaymentDetail(
            files, wo.Id, 'Paid now', 'NonExistentStep', 'Cash', 123.45, '');
        Test.stopTest();

        List<ContentVersion> cvs = [SELECT Id, Title FROM ContentVersion WHERE Title = 'Payment File'];
        System.assertEquals(1, cvs.size(), 'One ContentVersion for payment should be inserted');
    }

    @isTest
    static void testUpdateGeoLocation() {
        Account acc = new Account(Name = 'Geo Acc', BP_Number__c = 'BP121212');
        insert acc;

        WorkOrder wo = new WorkOrder(
            Subject = 'Geo WO',
            AccountId = acc.Id,
            Status = 'New'
        );
        insert wo;

        ServiceAppointment sa = new ServiceAppointment(
            ParentRecordId = wo.Id,
            Status = 'Scheduled'
        );
        insert sa;

        Test.startTest();
        ICImageRemarkComponentHandler.updateGeoLocation(wo.Id, 28.67d, 77.12d, 'Check In');
        ICImageRemarkComponentHandler.updateGeoLocation(wo.Id, 28.67d, 77.12d, 'Check Out');
        Test.stopTest();

        ServiceAppointment updated = [SELECT Check_In_Timestamp__c, Check_Out_Timestamp__c FROM ServiceAppointment WHERE Id = :sa.Id];
        //System.assertNotEquals(null, updated.Check_In_Timestamp__c);
        //System.assertNotEquals(null, updated.Check_Out_Timestamp__c);
    }
}