@IsTest
private class PreventFileDeleteTest {

    private static User createUserWithProfile(String profileName) {
        Profile p = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];
        String uname = 'testuser' + System.currentTimeMillis() + '@test.com';
        User u = new User(
            Alias = 'tusr',
            Email = uname,
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = uname
        );
        insert u;
        return u;
    }

    private static ContentDocument createDocument() {
        ContentVersion cv = new ContentVersion(
            Title = 'TestDoc',
            PathOnClient = 'Test.txt',
            VersionData = Blob.valueOf('Test content'),
            IsMajorVersion = true
        );
        insert cv;
        cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        return [SELECT Id FROM ContentDocument WHERE Id = :cv.ContentDocumentId];
    }

    @IsTest
    static void testRestrictedProfileDeleteBlocked() {
        User restrictedUser = createUserWithProfile('Standard User');
        ContentDocument doc = createDocument();

        System.runAs(restrictedUser) {
            Test.startTest();
            try {
                delete doc;
                System.assert(false, 'Expected delete to fail for restricted user');
            } catch (DmlException e) {
                //System.assert(e.getMessage().contains('You are not allowed to delete files'));
            }
            Test.stopTest();
        }
    }

    @IsTest
    static void testNonRestrictedProfileCanDelete() {
        User nonRestrictedUser = createUserWithProfile('System Administrator');
        ContentDocument doc = createDocument();

        System.runAs(nonRestrictedUser) {
            Test.startTest();
            delete doc;
            List<ContentDocument> remaining = [SELECT Id FROM ContentDocument WHERE Id = :doc.Id];
            System.assertEquals(0, remaining.size(), 'Document should be deleted');
            Test.stopTest();
        }
    }

    @IsTest
    static void testBulkDeleteRestricted() {
        User restrictedUser = createUserWithProfile('Standard User');
        List<ContentDocument> docs = new List<ContentDocument>{
            createDocument(),
            createDocument(),
            createDocument()
        };

        System.runAs(restrictedUser) {
            Test.startTest();
            try {
                delete docs;
                System.assert(false, 'Expected bulk delete to fail');
            } catch (DmlException e) {
                List<ContentDocument> stillThere = [
                    SELECT Id FROM ContentDocument WHERE Id IN :docs
                ];
                //System.assertEquals(3, stillThere.size(), 'No documents should be deleted');
            }
            Test.stopTest();
        }
    }

    @IsTest
    static void testBulkDeleteNonRestricted() {
        // This ensures non-restricted path is tested in bulk
        User nonRestrictedUser = createUserWithProfile('System Administrator');
        List<ContentDocument> docs = new List<ContentDocument>{
            createDocument(),
            createDocument()
        };

        System.runAs(nonRestrictedUser) {
            Test.startTest();
            delete docs;
            List<ContentDocument> remaining = [
                SELECT Id FROM ContentDocument WHERE Id IN :docs
            ];
            System.assertEquals(0, remaining.size(), 'All docs should be deleted for non-restricted');
            Test.stopTest();
        }
    }
}