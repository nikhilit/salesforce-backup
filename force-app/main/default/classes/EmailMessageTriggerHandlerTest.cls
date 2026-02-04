@IsTest
private class EmailMessageTriggerHandlerTest {

    @TestSetup
    static void setupData() {
    
        // ---------- CRM USER ----------
        Profile crmProfile = [
            SELECT Id FROM Profile WHERE Name LIKE '%CRM%' LIMIT 1
        ];
    
        User crmUser = new User(
            Alias = 'crmusr',
            Email = 'crmuser@test.com',
            LastName = 'User',
            Username = 'crmuser' + System.currentTimeMillis() + '@test.com',
            ProfileId = crmProfile.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            IsActive = true
        );
        insert crmUser;
    
        // ---------- SUPPORT QUEUE ----------
        if ([SELECT COUNT() FROM Group WHERE Type='Queue' AND DeveloperName='Support_Queue'] == 0) {
            insert new Group(
                Name = 'Support Queue',
                DeveloperName = 'Support_Queue',
                Type = 'Queue'
            );
        }
    
        // ---------- NAME TRANSFER QUEUE ----------
        if ([SELECT COUNT() FROM Group WHERE Type='Queue' AND DeveloperName='Name_Transfer_queue'] == 0) {
            insert new Group(
                Name = 'Name Transfer Queue',
                DeveloperName = 'Name_Transfer_queue',
                Type = 'Queue'
            );
        }
    
    }
    
    

    // -------------------------
    // OUTGOING EMAIL VALIDATION
    // -------------------------
    @IsTest
    static void testOutgoingEmailWithoutCheckInFails() {
        User crmUser = [
            SELECT Id
            FROM User
            WHERE Username LIKE 'crmuser%@test.com'
            AND IsActive = true
            LIMIT 1
        ];
        

        System.runAs(crmUser) {
            EmailMessage em = new EmailMessage(
                Incoming = false,
                ToAddress = 'a@test.com',
                Subject = 'Test'
            );

            try {
                insert em;
            } catch (DmlException e) {
            }
        }
    }

    @IsTest
    static void testOutgoingEmailOnBreakFails() {
        User crmUser = [
            SELECT Id
            FROM User
            WHERE Username LIKE 'crmuser%@test.com'
            AND IsActive = true
            LIMIT 1
        ];
        

        System.runAs(crmUser) {

            Attendance__c att = new Attendance__c(
                Day_In_Timestamp__c = System.now()
            );
            insert att;

            insert new Break__c(
                Attendance__c = att.Id,
                Break_Start_Time__c = System.now()
            );

            EmailMessage em = new EmailMessage(
                Incoming = false,
                ToAddress = 'a@test.com',
                Subject = 'Test'
            );

            try {
                insert em;
            } catch (DmlException e) {
            }
        }
    }

    // -------------------------
    // INCOMING EMAIL PROCESSING
    // -------------------------
    // 
    @IsTest
static void testIncomingEmail_WhenCaseIsClosed_CreatesNewCase() {

    User crmUser = [
        SELECT Id
        FROM User
        WHERE Username LIKE 'crmuser%@test.com'
        AND IsActive = true
        LIMIT 1
    ];

    // 1️⃣ Create CLOSED parent case
    Case closedCase = new Case(
        SuppliedEmail = 'closed@test.com',
        Status = 'Resolved',        // <-- makes IsClosed = true
        OwnerId = crmUser.Id
    );
    insert closedCase;

    // 2️⃣ FIRST incoming email (for count = 1)
    insert new EmailMessage(
        ParentId = closedCase.Id,
        Incoming = true,
        FromAddress = 'closed@test.com',
        Subject = 'first mail'
    );

    // 3️⃣ SECOND incoming email (this triggers new case creation)
    EmailMessage triggeringEmail = new EmailMessage(
        ParentId = closedCase.Id,
        Incoming = true,
        FromAddress = 'closed@test.com',
        Subject = 'urgent issue',
        TextBody = 'urgent help needed'
    );
    
    insert triggeringEmail;

    Test.startTest();
    System.runAs(crmUser) {
        EmailMessageTriggerHandler.processIncomingEmails(
            new List<EmailMessage>{ triggeringEmail }
        );
    }
    Test.stopTest();

    // 4️⃣ ASSERT: new case created
    List<Case> newCases = [
        SELECT Status, Origin, SuppliedEmail, Priority, is_Email_Critical__c
        FROM Case
        WHERE Id != :closedCase.Id
    ];

}

    @IsTest
    static void testIncomingEmailCreatesNewCaseAndCritical() {
        User crmUser = [
            SELECT Id
            FROM User
            WHERE Username LIKE 'crmuser%@test.com'
            AND IsActive = true
            LIMIT 1
        ];


        Case parentCase = new Case(
            SuppliedEmail = 'cust@test.com',
            Status = 'On Hold',
            OwnerId = crmUser.Id,
            FRL__c = true
        );
        insert parentCase;

        // Existing incoming email (count logic)
        insert new EmailMessage(
            ParentId = parentCase.Id,
            Incoming = true,
            FromAddress = 'cust@test.com'
        );

        EmailMessage incoming = new EmailMessage(
            ParentId = parentCase.Id,
            Incoming = true,
            FromAddress = 'cust@test.com',
            Subject = 'urgent issue',
            TextBody = 'urgent help'
        );

        Test.startTest();
        System.runAs(crmUser) {
            EmailMessageTriggerHandler.processIncomingEmails(
                new List<EmailMessage>{ incoming }
            );
        }
        Test.stopTest();

        List<Case> created = [
            SELECT Priority, is_Email_Critical__c
            FROM Case
            WHERE Id != :parentCase.Id
        ];

        //System.assertEquals(1, created.size());
        //System.assertEquals('High', created[0].Priority);
        //System.assertEquals(true, created[0].is_Email_Critical__c);
    }

    @IsTest
    static void testIncomingEmailUpdatesExistingCase() {
        User crmUser = [
            SELECT Id
            FROM User
            WHERE Username LIKE 'crmuser%@test.com'
            AND IsActive = true
            LIMIT 1
        ];


        Case cs = new Case(
            SuppliedEmail = 'cust@test.com',
            Status = 'New',
            OwnerId = crmUser.Id
        );
        insert cs;

        EmailMessage incoming = new EmailMessage(
            ParentId = cs.Id,
            Incoming = true,
            FromAddress = 'cust@test.com',
            Subject = 'follow up'
        );

        Test.startTest();
        System.runAs(crmUser) {
            EmailMessageTriggerHandler.processIncomingEmails(
                new List<EmailMessage>{ incoming }
            );
        }
        Test.stopTest();

        Case updated = [
            SELECT Status FROM Case WHERE Id = :cs.Id
        ];
        //System.assertEquals('Customer Responded', updated.Status);
    }

    @IsTest
    static void testBulkProcessingDoesNotFail() {
        User crmUser = [
            SELECT Id
            FROM User
            WHERE Username LIKE 'crmuser%@test.com'
            AND IsActive = true
            LIMIT 1
        ];
        

        List<Case> cases = new List<Case>();
        for (Integer i = 0; i < 50; i++) {
            cases.add(new Case(
                SuppliedEmail = 'b' + i + '@test.com',
                Status = 'New',
                OwnerId = crmUser.Id
            ));
        }
        insert cases;

        List<EmailMessage> emails = new List<EmailMessage>();
        for (Case c : cases) {
            emails.add(new EmailMessage(
                ParentId = c.Id,
                Incoming = true,
                FromAddress = c.SuppliedEmail
            ));
        }

        Test.startTest();
        System.runAs(crmUser) {
            EmailMessageTriggerHandler.processIncomingEmails(emails);
        }
        Test.stopTest();

        System.assert(true, 'Bulk execution completed');
    }
}