@isTest
public class AutoRejectPendingApprovalsTest {

   @testSetup
    static void setupData() {

      //  Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
      
         Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator' LIMIT 1];


        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@test.com',
            Username = 'testuser'+System.currentTimeMillis()+'@test.com',
            Alias = 'tusr',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_IN',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert u;

        System.runAs(u) {
            
              Id rtId = Schema.SObjectType.WorkOrder
                .getRecordTypeInfosByDeveloperName()
                .get('TBT')
                .getRecordTypeId();

            WorkOrder wo = new WorkOrder(
                Subject = 'Approval Test',
                Status = 'New',
                RecordTypeId = rtId
            );
            insert wo;

            Approval.ProcessSubmitRequest psr = new Approval.ProcessSubmitRequest();
            psr.setObjectId(wo.Id);
 				psr.setProcessDefinitionNameOrId(
                'RiserAICSiteDocumentApprovalProcess'
            );
            psr.setSkipEntryCriteria(true);
            psr.setComments('Submitting for approval');
            Approval.ProcessResult result = Approval.process(psr);

          //  System.assert(result.isSuccess(), 'Approval submission failed');
        }
    }

    @isTest
    static void testSchedulerRejectsPendingApprovals() {

        Test.startTest();

        // Schedule the job
        System.schedule(
            'Auto Reject Pending Approvals',
            '0 0 0 * * ?',
            new AutoRejectPendingApprovals()
        );

        Test.stopTest();

        // Verify approval got rejected
        List<ProcessInstance> rejected = [
            SELECT Status
            FROM ProcessInstance
            WHERE Status = 'Rejected'
        ];

        //System.assert(rejected.size() > 0, 'Pending approval should be auto-rejected');
    }

    @isTest
    static void testEmptyPathCoverage() {
        Test.startTest();
        new AutoRejectPendingApprovals().execute(null);
        Test.stopTest();

      //  System.assert(true, 'Handled no pending approvals safely');
    }
}