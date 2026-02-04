@IsTest
public class WorkOrderNotificationServiceTest {
    
    private static Account createAccount(String pref, Boolean withPhone) {
        Account acc = new Account(
            Name = 'Test Acc',
            Phone = withPhone ? '1234567890' : null,
            CA_Number__c = 'CA123',
            Preferance__c = 'SMS'
        );
        insert acc;
        return acc;
    }
    
    private static Case_Type_SMS__c createTemplate(String id, String msg) {
        Case_Type_SMS__c t = new Case_Type_SMS__c(
            Template_Id__c = id,
            Message__c = msg
        );
        insert t;
        return t;
    }
    
    private static WorkOrder createWO(Account acc, Decimal amt, String txnId, String payMode) {
        Id rtId = [SELECT Id FROM RecordType 
                   WHERE SObjectType = 'WorkOrder' 
                   AND DeveloperName = 'MGL_R_T' LIMIT 1].Id;
        
        WorkOrder wo = new WorkOrder(
            Subject = 'WO',
            Status = 'New',
            RecordTypeId = rtId,
            AccountId = acc.Id,
            StartDate = DateTime.now(),
            EndDate = DateTime.now().addDays(1),
            Amount_Received__c = amt,
            Transaction_Id__c = txnId,
            Payment_Mode__c = payMode,
            Due_Amount__c = 123.45,
            Remarks__c = 'Sample remark'
        );
        insert wo;
        return wo;
    }

    private static Account makeAcc() {
        Account acc = new Account(Name='AccMore', Phone='9991112222', CA_Number__c='CA123', Preferance__c='SMS');
        insert acc;
        return acc;
    }
    private static Id getMglRt() {
        return [SELECT Id FROM RecordType WHERE SObjectType='WorkOrder' AND DeveloperName='MGL_R_T' LIMIT 1].Id;
    }

    private static WorkOrder makeWO(Account acc, Decimal amt, String txn, String mode) {
        WorkOrder wo = new WorkOrder(
            Subject='WO More',
            Status='New',
            AccountId=acc.Id,
            RecordTypeId=getMglRt(),
            Due_Amount__c=100,
            Amount_Received__c=amt,
            Transaction_Id__c=txn,
            Payment_Mode__c=mode,
            StartDate=DateTime.now(),
            EndDate=DateTime.now().addDays(1)
        );
        insert wo;
        return wo;
    }
    
    @IsTest static void testInsertScenario_SMS() {
        Account acc = createAccount('SMS', true);
        createTemplate('1007690345210860271', 'Created template msg');
        
        WorkOrder wo = createWO(acc, null, null, null);
        
        Test.startTest();
        WorkOrderNotificationService.processNotifications(new List<WorkOrder>{wo}, null);
        Test.stopTest();
    }
    
    @IsTest static void testUpdateScenario_SMS_withChanges() {
        Account acc = createAccount('SMS', true);
        createTemplate('1007302637557326707', 'Updated template msg');
        
        WorkOrder wo = createWO(acc, 10, 'T1', 'POS');
        WorkOrder oldWO = wo.clone(false, true, true, true);
        oldWO.Amount_Received__c = 5; // simulate change
        oldWO.Payment_Mode__c = 'M-POS';        
        Map<Id, WorkOrder> oldMap = new Map<Id, WorkOrder>{wo.Id => oldWO};
        Test.startTest();
        WorkOrderNotificationService.processNotifications(new List<WorkOrder>{wo}, oldMap);
        Test.stopTest();
    }
    
    @IsTest static void testUpdateScenario_noChange_skip() {
        Account acc = createAccount('SMS', true);
        createTemplate('1007302637557326707', 'Updated template msg');
        
        WorkOrder wo = createWO(acc, 10, 'T1', 'POS');
        WorkOrder oldWO = wo.clone(false, true, true, true);
        Map<Id, WorkOrder> oldMap = new Map<Id, WorkOrder>{wo.Id => oldWO};
        
        Test.startTest();
        WorkOrderNotificationService.processNotifications(new List<WorkOrder>{wo}, oldMap);
        Test.stopTest();
    }
    
    @IsTest static void testMissingPhone() {
        Account acc = createAccount('SMS', false);
        createTemplate('1007690345210860271', 'Created template msg');
        
        WorkOrder wo = createWO(acc, null, null, null);
        
        Test.startTest();
        WorkOrderNotificationService.processNotifications(new List<WorkOrder>{wo}, null);
        Test.stopTest();
    }
    
    @IsTest static void testWhatsAppPreference() {
        Account acc = createAccount('WhatsApp', true);
        createTemplate('1007690345210860271', 'Created template msg');
        
        WorkOrder wo = createWO(acc, null, null, null);
        
        Test.startTest();
        WorkOrderNotificationService.processNotifications(new List<WorkOrder>{wo}, null);
        Test.stopTest();
    }
    
    @IsTest static void testInvalidPreference() {
        Account acc = createAccount('Other', true);
        createTemplate('1007690345210860271', 'Created template msg');
        
        WorkOrder wo = createWO(acc, null, null, null);
        
        Test.startTest();
        WorkOrderNotificationService.processNotifications(new List<WorkOrder>{wo}, null);
        Test.stopTest();
    }
    
    @IsTest static void testNoTemplateMessage() {
        Account acc = createAccount('SMS', true);
        createTemplate('1007690345210860271', null);
        
        WorkOrder wo = createWO(acc, null, null, null);
        
        Test.startTest();
        WorkOrderNotificationService.processNotifications(new List<WorkOrder>{wo}, null);
        Test.stopTest();
    }


	 

    @IsTest static void testFollowUp_noMetadata() {
        Account acc = WorkOrderNotificationServiceTest.createAccount('SMS', true);
        WorkOrder wo = WorkOrderNotificationServiceTest.createWO(acc, null, null, null);

        Test.startTest();
        //WorkOrderNotificationService.sendFollowUpNotification(wo, 'RandomRemark');
        Test.stopTest();
    }

    @IsTest static void testFollowUp_withTemplate() {
        Account acc = WorkOrderNotificationServiceTest.createAccount('SMS', true);
        WorkOrder wo = WorkOrderNotificationServiceTest.createWO(acc, null, null, null);

        Case_Type_SMS__c tmpl = new Case_Type_SMS__c(
            Template_Id__c = 'FollowUpRemark1',
            Message__c = 'FU message here'
        );
        insert tmpl;

        Test.startTest();
        //WorkOrderNotificationService.sendFollowUpNotification(wo, 'FollowUpRemark1');
        Test.stopTest();
    }

	@IsTest
	static void testFollowUp_viaProcessNotifications() {
    Account acc = WorkOrderNotificationServiceTest.createAccount('SMS', true);
    WorkOrder wo = WorkOrderNotificationServiceTest.createWO(acc, 15, null, null);

    WorkOrder oldWO = wo.clone(false, true, true, true);
    oldWO.Follow_up_Remarks__c = null;

    Map<String, Go_Collect_Follow_Up__mdt> fakeMdtMap = new Map<String, Go_Collect_Follow_Up__mdt>();
    Go_Collect_Follow_Up__mdt fakeMdt = new Go_Collect_Follow_Up__mdt(
        DeveloperName   = 'WorkOrder_Allocation',
        MasterLabel     = 'WorkOrder Allocation',
        SMS_requried__c = true,
        Template_Id__c  = '1007690345210860271'
    );
    fakeMdtMap.put(fakeMdt.MasterLabel, fakeMdt);

    insert new Case_Type_SMS__c(
        Template_Id__c = '1007690345210860271',
        Message__c     = 'Follow-up text'
    );

    wo.Follow_up_Remarks__c = 'WorkOrder Allocation';
    update wo;

    Test.startTest();
    WorkOrderNotificationService.processNotifications(
        new List<WorkOrder>{wo},
        new Map<Id, WorkOrder>{wo.Id => oldWO}
    );
    Test.stopTest();
}


	@IsTest
    static void testEmptyInputLists() {
        Test.startTest();
        WorkOrderNotificationService.processNotifications(null, null);
        WorkOrderNotificationService.processNotifications(new List<WorkOrder>(), null);
        Test.stopTest();
    }

    @IsTest
    static void testSkipWrongRecordTypeAndDueAmount() {
        Account acc = new Account(Name='SkipAcc', Phone='1234567890', CA_Number__c='CA99', Preferance__c='SMS');
        insert acc;

        Id otherRtId = [SELECT Id FROM RecordType WHERE SObjectType='WorkOrder' AND DeveloperName != 'MGL_R_T' LIMIT 1].Id;
        WorkOrder wo1 = new WorkOrder(Subject='WO BadRT', AccountId=acc.Id, RecordTypeId=otherRtId, Due_Amount__c=50);
        insert wo1;

        Id mglRtId = [SELECT Id FROM RecordType WHERE SObjectType='WorkOrder' AND DeveloperName='MGL_R_T' LIMIT 1].Id;
        WorkOrder wo2 = new WorkOrder(Subject='WO NoDue', AccountId=acc.Id, RecordTypeId=mglRtId, Due_Amount__c=0);
        insert wo2;

        Test.startTest();
        WorkOrderNotificationService.processNotifications(new List<WorkOrder>{wo1,wo2}, null);
        Test.stopTest();
    }

    @IsTest
    static void testAgentAgencyChanged() {
        Account acc = new Account(Name='AgentAcc', Phone='9999999999', CA_Number__c='CAAA', Preferance__c='SMS');
        insert acc;

        Id mglRtId = [SELECT Id FROM RecordType WHERE SObjectType='WorkOrder' AND DeveloperName='MGL_R_T' LIMIT 1].Id;
        WorkOrder wo = new WorkOrder(Subject='WO agent', AccountId=acc.Id, RecordTypeId=mglRtId, Due_Amount__c=99);
        insert wo;

        insert new Case_Type_SMS__c(Template_Id__c='1001', Message__c='Agent changed');

        WorkOrder oldWO = wo.clone(false,true,true,true);
        oldWO.Agent__c = null; 
        wo.Agent__c = UserInfo.getUserId(); 

        Test.startTest();
        WorkOrderNotificationService.processNotifications(
            new List<WorkOrder>{wo},
            new Map<Id,WorkOrder>{wo.Id=>oldWO}
        );
        Test.stopTest();
    }

    @IsTest
    static void testFollowUpCaseInsensitiveAndSmsRequiredFalse() {
        Account acc = new Account(Name='FUAcc', Phone='1111111111', CA_Number__c='CAXX', Preferance__c='SMS');
        insert acc;
        Id mglRtId = [SELECT Id FROM RecordType WHERE SObjectType='WorkOrder' AND DeveloperName='MGL_R_T' LIMIT 1].Id;
        WorkOrder wo = new WorkOrder(Subject='WO FU', AccountId=acc.Id, RecordTypeId=mglRtId, Due_Amount__c=50);
        insert wo;

        Map<String,Go_Collect_Follow_Up__mdt> fakeMdtMap = new Map<String,Go_Collect_Follow_Up__mdt>();
        Go_Collect_Follow_Up__mdt fakeMdt = new Go_Collect_Follow_Up__mdt(
            DeveloperName='FU1',
            MasterLabel='MyLabel',
            SMS_requried__c=false, 
            Template_Id__c='TMPX'
        );
        fakeMdtMap.put(fakeMdt.MasterLabel, fakeMdt);

        Map<String,Case_Type_SMS__c> tmplById = new Map<String,Case_Type_SMS__c>();
        tmplById.put('TMPX', new Case_Type_SMS__c(Template_Id__c='TMPX', Message__c='Msg'));

        Test.startTest();
        WorkOrderNotificationService.WorkOrderNotificationWrapper wrap1 =
            WorkOrderNotificationService.sendFollowUpNotification(wo,'MyLabel',fakeMdtMap,tmplById);
        System.assertEquals(null, wrap1);

        fakeMdt.SMS_requried__c = true;
        wrap1 = WorkOrderNotificationService.sendFollowUpNotification(wo,'mylabel',fakeMdtMap,tmplById);
        //System.assertNotEquals(null, wrap1, 'Case-insensitive follow-up should work');
        Test.stopTest();
    }

	 @IsTest static void testTxnChangedOnly() {
        Account acc = makeAcc();
        insert new Case_Type_SMS__c(Template_Id__c='TUPD', Message__c='Txn Changed');
        WorkOrder wo = makeWO(acc, 10, 'NEW_TXN', 'M-POS');
        WorkOrder oldWO = wo.clone(false,true,true,true);
        oldWO.Transaction_Id__c = 'OLD_TXN';
        Map<Id,WorkOrder> oldMap = new Map<Id,WorkOrder>{wo.Id => oldWO};

        Test.startTest();
        WorkOrderNotificationService.processNotifications(new List<WorkOrder>{wo}, oldMap);
        Test.stopTest();
    }

    @IsTest static void testValidPaymentQRAndCheque() {
        Account acc = makeAcc();
        insert new Case_Type_SMS__c(Template_Id__c='TMPQR', Message__c='QR Changed');
        insert new Case_Type_SMS__c(Template_Id__c='TMPCHQ', Message__c='Cheque Changed');

        WorkOrder wo1 = makeWO(acc, 50, 'TQR', 'QR Code');
        WorkOrder oldWO1 = wo1.clone(false,true,true,true);
        oldWO1.Amount_Received__c = 10;
        Map<Id,WorkOrder> oldMap1 = new Map<Id,WorkOrder>{wo1.Id=>oldWO1};

        WorkOrder wo2 = makeWO(acc, 60, 'TCHQ', 'Cheque');
        WorkOrder oldWO2 = wo2.clone(false,true,true,true);
        oldWO2.Amount_Received__c = 20;
        Map<Id,WorkOrder> oldMap2 = new Map<Id,WorkOrder>{wo2.Id=>oldWO2};

        Test.startTest();
        WorkOrderNotificationService.processNotifications(new List<WorkOrder>{wo1}, oldMap1);
        WorkOrderNotificationService.processNotifications(new List<WorkOrder>{wo2}, oldMap2);
        Test.stopTest();
    }

    @IsTest static void testOldMapMissingWO() {
        Account acc = makeAcc();
        insert new Case_Type_SMS__c(Template_Id__c='TMPMISS', Message__c='Skip oldMap');

        WorkOrder wo = makeWO(acc, 20, 'TX1', 'M-POS');
        Test.startTest();
        WorkOrderNotificationService.processNotifications(new List<WorkOrder>{wo}, new Map<Id,WorkOrder>());
        Test.stopTest();
    }

    @IsTest static void testFollowUp_blankAndNoMatch() {
        Account acc = makeAcc();
        WorkOrder wo = makeWO(acc, 10, 'TX', 'M-POS');

        Map<String,Go_Collect_Follow_Up__mdt> mdtMap = new Map<String,Go_Collect_Follow_Up__mdt>();
        Map<String,Case_Type_SMS__c> tmplMap = new Map<String,Case_Type_SMS__c>();

        Test.startTest();
        System.assertEquals(null, WorkOrderNotificationService.sendFollowUpNotification(wo,'',mdtMap,tmplMap));
        System.assertEquals(null, WorkOrderNotificationService.sendFollowUpNotification(wo,'NotThere',mdtMap,tmplMap));
        Test.stopTest();
    }

    @IsTest static void testNeededTemplateIdsEmpty() {
        Account acc = makeAcc();
        WorkOrder wo = makeWO(acc, null, null, null);

        Test.startTest();
        WorkOrderNotificationService.processNotifications(new List<WorkOrder>{wo}, null);
        Test.stopTest();
    }
}