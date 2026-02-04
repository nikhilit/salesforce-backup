@isTest
private class EmailAttachmentHandlerTest {

    @isTest
    static void test_convertEmailAttachments() {
        // ===== 1) Create a Case (parent)
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Case c = new Case(
            Subject  = 'Email Attachment Test',
            Status   = 'New',
            Origin   = 'Email',
            AccountId = acc.Id
        );
        insert c;

        // ===== 2) Create EmailMessage linked to Case
        EmailMessage em = new EmailMessage(
            Subject      = 'Test Email',
            FromAddress  = 'test@example.com',
            ToAddress    = 'support@example.com',
            Incoming     = true,
            Status       = '3', // e.g.: New
            ParentId     = c.Id
        );
        insert em;

        // ===== 3) Create Attachment linked to EmailMessage
        Attachment att = new Attachment(
            Name        = 'TestAttachment.txt',
            Body        = Blob.valueOf('This is the file content'),
            ParentId    = em.Id
        );
        insert att;

        // ===== 4) Call the handler
        Test.startTest();
        EmailAttachmentHandler.convertEmailAttachments(
            new List<Attachment>{ att }
        );
        Test.stopTest(); // ensures @future delete runs

        // ===== 5) Assertions:

        // Verify ContentVersion created with correct data
        List<ContentVersion> cvs = [
            SELECT Title, PathOnClient, FirstPublishLocationId, IsMajorVersion
            FROM ContentVersion
            WHERE Title = 'TestAttachment.txt'
        ];
        //System.assertEquals(1, cvs.size(), 'One ContentVersion should be inserted');
        System.assertEquals('TestAttachment.txt', cvs[0].Title);
        System.assertEquals(c.Id, cvs[0].FirstPublishLocationId, 'Should be linked to Case');

        // Verify attachment is deleted
        Integer attCount = [
            SELECT count() 
            FROM Attachment 
            WHERE Id = :att.Id
        ];
        System.assertEquals(0, attCount, 'Attachment should be deleted');
    }

    @isTest
    static void test_no_related_case() {
        // Attachment with parentId that is NOT an EmailMessage linked to a case

        // Create an EmailMessage with no ParentId (so it won’t match criteria)
        EmailMessage em = new EmailMessage(
            Subject      = 'Test Email 2',
            FromAddress  = 'test@example.com',
            ToAddress    = 'support@example.com',
            Incoming     = true,
            Status       = '3'
        );
        insert em;

        Attachment att = new Attachment(
            Name     = 'OrphanAttachment.txt',
            Body     = Blob.valueOf('Hello World'),
            ParentId = em.Id
        );
        insert att;

        Test.startTest();
        EmailAttachmentHandler.convertEmailAttachments(
            new List<Attachment>{ att }
        );
        Test.stopTest();

        // Verify no ContentVersion created
        System.assertEquals(0, [
            SELECT Count()
            FROM ContentVersion
            WHERE Title = 'OrphanAttachment.txt'
        ]);

        // Verify attachment still exists
        System.assertEquals(1, [
            SELECT Count()
            FROM Attachment
            WHERE Id = :att.Id
        ]);
    }
}