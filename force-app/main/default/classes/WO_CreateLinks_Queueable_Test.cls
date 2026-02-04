@isTest
private class WO_CreateLinks_Queueable_Test {

    // STATIC HOLDER FOR VERSION IDS
    private static List<Id> TEST_VERSION_IDS = new List<Id>();

    /** Utility: Create a ContentVersion and return its ID */
    private static Id createVersion(String title,Id recordId){
        ContentVersion cv = new ContentVersion(
            Title = title,
            PathOnClient = title + '.pdf',
            VersionData = Blob.valueOf('dummy')
        );
        insert cv;

        // Re-query to get ContentDocumentId
        cv = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
        ];
        
     

        return cv.Id;
    }

    @testSetup
    static void setupData(){

        Account acc = new Account(
            Name = 'TestAcc', 
            BP_Number__c = '1001',
            Representative_Company__c ='OMC'
        );
        insert acc;

        WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            AccountId = acc.Id,
            From_Date__c = Date.today(),
            To_Date__c = Date.today().addDays(1)
        );
        insert wo;

        // Create exactly 2 Versions required by Queueable
        Id v1 = createVersion('JT_TestFile_1',wo.Id);
        Id v2 = createVersion('JT_TestFile_2',null);

        TEST_VERSION_IDS.add(v1);
        TEST_VERSION_IDS.add(v2);
    }

    @isTest
    static void testQueueable(){

        // Get one WO
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        // Query the 2 versions created
        List<ContentVersion> versions = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
        ];
        
        List<Id> listIds=new List<Id>();
        for(ContentVersion ver:versions){
            listIds.add(ver.Id);
        }

        Test.startTest();
        System.enqueueJob(
            new WO_CreateLinks_Queueable(
                new List<Id>{wo.Id},
                listIds
            )
        );
        Test.stopTest();
    }
}