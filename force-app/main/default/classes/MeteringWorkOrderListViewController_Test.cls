@IsTest
private class MeteringWorkOrderListViewController_Test {
    
    @testSetup
    static void setupData() { 
        
        /* ❇️ Create Test User */
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'test@example.com',
            Username = 'testuser' + System.now().getTime() + '@example.com',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            Alias = 'tuser',
            CommunityNickname = 'testuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        
        
        /* ❇️ Create Account */
        Account acc = new Account(
            Name = 'Test Acc',
            BP_Number__c = 'BP001'
        );
        insert acc;
        
        String gsRecordTypeID = Schema.getGlobalDescribe().get('WorkOrder').getDescribe().getRecordTypeInfosByDeveloperName().get('MGL_Metering').getRecordTypeId();
        
        /* ❇️ Create WorkOrder */
        WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            Status = 'New',
            RecordTypeId = gsRecordTypeID,
            Appointment_Status__c = 'Completed',
            AccountId = acc.Id,
            StartDate = Date.today(),
            EndDate = Date.today()
        );
        insert wo;
        
        /* ❇️ Group Metadata */
        Group_Master__c gm = new Group_Master__c(
            Name = 'GM',
            Active__c = true
        );
        insert gm;
        
        Group_Code__c gc = new Group_Code__c(
            Name = 'GC',
            Active__c = true,
            Group_Master__c = gm.Id,
            Description__c = 'Desc'
        );
        insert gc;
        
        Group_Message__c gmMsg = new Group_Message__c(
            Name = 'GMsg',
            Active__c = true,
            Group_Code__c = gc.Id,
            Description__c = 'Hello Msg'
        );
        insert gmMsg;
        
        /* ❇️ ContentVersion */
        ContentVersion cv = new ContentVersion(
            Title = 'img',
            PathOnClient = 'img.jpg',
            VersionData = Blob.valueOf('test')
        );
        insert cv;
    }
    
    /* ✅ Test Dynamic Columns */
    @isTest
    static void testGetDynamicColumns() {
        Test.startTest();
        MeteringWorkOrderListViewController.getDynamicColumns('Sample_Work_Order_List');
        Test.stopTest();
        
    }
    
    /* ✅ Test Dynamic WO List */
    @isTest
    static void testGetWorkOrdersDynamic() {
        
        Metering_Listview_Config__mdt cfg = [
            SELECT Field_to_Display__c,Object_API_Name__c,Record_Type_Developer_Name__c
            FROM Metering_Listview_Config__mdt WHERE DeveloperName ='Sample_Work_Order_List' LIMIT 1
        ];
        
        Test.startTest();
        List<Map<String,Object>> res = MeteringWorkOrderListViewController.getWorkOrdersDynamic(
            cfg.Record_Type_Developer_Name__c,
            cfg.Field_to_Display__c,
            cfg.Object_API_Name__c,
            'Domestic',
            '1000'
        );
        Test.stopTest();
        
    }
    
    /* ✅ Test Get ContentVersion Base64 */
    @isTest
    static void testContentVersionBase64() {
        Id cvId = [SELECT Id FROM ContentVersion LIMIT 1].Id;
        
        String data = MeteringWorkOrderListViewController.getContentVersionBase64(cvId);
        
    }
    
    /* ✅ Test Get Multiple ContentVersion Base64 */
    @isTest
    static void testContentVersionMulti() {
        Id cvId = [SELECT Id FROM ContentVersion LIMIT 1].Id;
        
        List<String> listRec = MeteringWorkOrderListViewController.getContentVersionsBase64(
            new List<String>{cvId}, 4
        );
        
    }
    
    /* ✅ Test Picklist Values */
    @isTest
    static void testPicklistValues() {
        List<MeteringWorkOrderListViewController.OptionsWrapper> listRec =
            MeteringWorkOrderListViewController.fieldPicklistValue('WorkOrder', 'Status');
        
    }
    
    /* ✅ Test Group Master */
    @isTest
    static void testGroupMasterOptions() {
        List<MeteringWorkOrderListViewController.OptionsWrapper> listRec =
            MeteringWorkOrderListViewController.getGroupMasterOptions();
        
    }
    
    /* ✅ Test Group Code */
    @isTest
    static void testGroupCodeOptions() {
        
        Id gmId = [SELECT Id FROM Group_Master__c LIMIT 1].Id;
        
        List<MeteringWorkOrderListViewController.OptionsWrapper> listRec =
            MeteringWorkOrderListViewController.getGroupCodeOptions(gmId);
        
    }
    
    /* ✅ Test Group Message */
    @isTest
    static void testGroupMessageOptions() {
        
        Id gcId = [SELECT Id FROM Group_Code__c LIMIT 1].Id;
        
        List<MeteringWorkOrderListViewController.OptionsWrapper> listRec =
            MeteringWorkOrderListViewController.getGroupMessageOptions(gcId);
        
    }
    
    /* ✅ Test getWorkOrdersByFilters */
    @isTest
    static void testGetWorkOrdersByFilters() {
        
        Metering_Listview_Config__mdt cfg = [
            SELECT Field_to_Display__c,Object_API_Name__c,Record_Type_Developer_Name__c
            FROM Metering_Listview_Config__mdt WHERE DeveloperName ='Sample_Work_Order_List' LIMIT 1
        ];
        
        List<Map<String,Object>> result = MeteringWorkOrderListViewController.getWorkOrdersByFilters(
            new List<String>{'BP001'},
            new List<String>{'CA001'},
            Date.today(),
            Date.today(),
            null, null, null, null, null,
            'Completed',
            null,
            '',
            cfg.Record_Type_Developer_Name__c,
            cfg.Field_to_Display__c,
            cfg.Object_API_Name__c,
            'Domestic',
            '100',
            'approved',
            'Mumbai',
            '',
            ''
        );
        MeteringWorkOrderListViewController.getMRUCategoryOptions();
        
    }
    
    @isTest
    static void testFlattenFunctions() {
        
        Sobject wq = [
            SELECT Id, Subject, Account.Name, Account.Phone
            FROM WorkOrder LIMIT 1
        ];
        
        List<String> fields = new List<String>{
            'Subject',
                'Account.Name',
                'Account.Phone'
                };
                    
                    Map<String,Object> flat = MeteringWorkOrderListViewController.flattenRow(wq, fields);
    }
    @isTest
    private static void testWorkOrderOptions() {
        List<WorkOrder> woList = new List<WorkOrder>{
            new WorkOrder(
                Subject = 'Test WO 1'
            ),
                new WorkOrder(
                    Subject = 'Test WO 2'
                    
                ),
                new WorkOrder(
                    Subject = 'Test WO 3'
                    
                )
                };
                    insert woList;
        List<MeteringWorkOrderListViewController.OptionsWrapper> areaOptions = MeteringWorkOrderListViewController.getareaOptions();
        List<MeteringWorkOrderListViewController.OptionsWrapper> gaWiseOptions = MeteringWorkOrderListViewController.getGAWiseOptions();
    }
    
    private class DynamicHttpMock implements HttpCalloutMock {
        private List<Account> accounts;
        
        public DynamicHttpMock(List<Account> accs) {
            this.accounts = accs;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            
            List<String> recordJson = new List<String>();
            for(Account a : accounts) {
                recordJson.add(JSON.serialize(a));
            }
            
            String body = '{"done": true, "records": [' + String.join(recordJson, ',') + ']}';
            res.setBody(body);
            return res;
        }
    }
    
    @isTest
    static void testRunMassiveQueryDynamic() {
        
        List<Account> testAccounts = new List<Account>{
            new Account(Name = 'Test Account A'),
                new Account(Name = 'Test Account B')
                };
                    insert testAccounts;
        
        String soql = 'SELECT Id, Name FROM Account WHERE Id IN (' +
            String.join(
                new List<String>{ testAccounts[0].Id, testAccounts[1].Id },
                ','
            ) + ')';
        
        Test.setMock(HttpCalloutMock.class, new DynamicHttpMock(testAccounts));
        
        Test.startTest();
        //List<Map<String, Object>> results = MeteringWorkOrderListViewController.runMassiveQuery(soql);
        //System.debug('Dynamic Results: ' + results);
        Test.stopTest();
    }
    
    @isTest
    static void test_getLocationOptions() {
        Account acc = new Account(
            Name = 'Test Account',
            Location__c = 'Mumbai'
        );
        insert acc;
        
        WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            AccountId = acc.Id
        );
        insert wo;
        
        Test.startTest();
        MeteringWorkOrderListViewController.getLocationOptions();
        Test.stopTest();
    }
    
    /* ✅ Test 1: Save New Config */
    @isTest
    static void testSaveNewConfig() {
        User testUser = [SELECT Id FROM User WHERE Username LIKE 'testuser%' LIMIT 1];
        
        System.runAs(testUser) {
            String listViewName = 'AccountListView';
            String selectedFields = 'Id,Name,BillingCity';
            
            Test.startTest();
            MeteringWorkOrderListViewController.saveUserColumnConfig(listViewName, selectedFields);
            Test.stopTest();
            
            List<User_ListView_Config__c> configs = [
                SELECT Id, Name, Selected_Fields__c, Is_Active__c
                FROM User_ListView_Config__c 
                WHERE User__c = :testUser.Id 
                AND Name = :listViewName
            ];
            
            Assert.areEqual(1, configs.size(), 'Config should be created');
            Assert.areEqual(selectedFields, configs[0].Selected_Fields__c, 'Fields should match');
            Assert.areEqual(true, configs[0].Is_Active__c, 'Should be active');
        }
    }
    
    /* ✅ Test 2: Update Existing Config */
    @isTest
    static void testUpdateExistingConfig() {
        User testUser = [SELECT Id FROM User WHERE Username LIKE 'testuser%' LIMIT 1];
        
        User_ListView_Config__c config = new User_ListView_Config__c(
            User__c = testUser.Id,
            Name = 'AccountListView',
            Object_API_Name__c = 'AccountListView',
            Selected_Fields__c = 'Id,Name',
            Is_Active__c = true
        );
        insert config;
        Id originalId = config.Id;
        
        System.runAs(testUser) {
            Test.startTest();
            MeteringWorkOrderListViewController.saveUserColumnConfig('AccountListView', 'Id,Name,BillingCity');
            Test.stopTest();
            
            User_ListView_Config__c updated = [
                SELECT Id, Selected_Fields__c
                FROM User_ListView_Config__c 
                WHERE User__c = :testUser.Id 
                AND Name = 'AccountListView'
            ];
            
            Assert.areEqual(originalId, updated.Id, 'Should update same record');
            Assert.areEqual('Id,Name,BillingCity', updated.Selected_Fields__c, 'Fields should be updated');
        }
    }
    
    /* ✅ Test 3: Get Existing Active Config */
    @isTest
    static void testGetExistingConfig() {
        User testUser = [SELECT Id FROM User WHERE Username LIKE 'testuser%' LIMIT 1];
        
        User_ListView_Config__c config = new User_ListView_Config__c(
            User__c = testUser.Id,
            Name = 'OpportunityListView',
            Object_API_Name__c = 'OpportunityListView',
            Selected_Fields__c = 'Id,Name,Amount',
            Is_Active__c = true
        );
        insert config;
        
        System.runAs(testUser) {
            Test.startTest();
            User_ListView_Config__c retrieved = MeteringWorkOrderListViewController.getUserColumnConfig('OpportunityListView');
            Test.stopTest();
            
            Assert.isNotNull(retrieved, 'Config should be retrieved');
            Assert.areEqual('Id,Name,Amount', retrieved.Selected_Fields__c, 'Fields should match');
        }
    }
    
    /* ✅ Test 4: Get Non-Existent Config Returns Null */
    @isTest
    static void testGetNonExistentConfig() {
        User testUser = [SELECT Id FROM User WHERE Username LIKE 'testuser%' LIMIT 1];
        
        System.runAs(testUser) {
            Test.startTest();
            User_ListView_Config__c retrieved = MeteringWorkOrderListViewController.getUserColumnConfig('NonExistent');
            Test.stopTest();
            
            Assert.isNull(retrieved, 'Should return null when not found');
        }
    }
    
    /* ✅ Test 5: Inactive Config Not Retrieved */
    @isTest
    static void testInactiveConfigNotRetrieved() {
        User testUser = [SELECT Id FROM User WHERE Username LIKE 'testuser%' LIMIT 1];
        
        User_ListView_Config__c config = new User_ListView_Config__c(
            User__c = testUser.Id,
            Name = 'InactiveListView',
            Object_API_Name__c = 'InactiveListView',
            Selected_Fields__c = 'Id,Name',
            Is_Active__c = false
        );
        insert config;
        
        System.runAs(testUser) {
            Test.startTest();
            User_ListView_Config__c retrieved = MeteringWorkOrderListViewController.getUserColumnConfig('InactiveListView');
            Test.stopTest();
            
            Assert.isNull(retrieved, 'Inactive config should not be retrieved');
        }
    }
    
    @isTest
    static void test_getS3PathByContentVersionId() {
        

        Account acc = new Account(
            Name = 'S3 Test Account',
            BP_Number__c = 'BP_S3'
        );
        insert acc;
        
        String rtId = Schema.getGlobalDescribe()
            .get('WorkOrder')
            .getDescribe()
            .getRecordTypeInfosByDeveloperName()
            .get('MGL_Metering')
            .getRecordTypeId();
        
        WorkOrder wo = new WorkOrder(
            Subject = 'S3 Test WO',
            Status = 'New',
            RecordTypeId = rtId,
            AccountId = acc.Id,
            StartDate = Date.today(),
            EndDate = Date.today()
        );
        insert wo;
        

        ContentVersion cv = new ContentVersion(
            Title = 'MeterImage1',
            PathOnClient = 'MeterImage1.jpg',
            VersionData = Blob.valueOf('fake image data')
        );
        insert cv;
        
        // Re-query to get ContentDocumentId
        cv = [
            SELECT Id, ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :cv.Id
        ];
        

        Document__c doc = new Document__c(
            File_Name__c = 'MeterImage1.jpg',
            Work_Order__c = wo.Id,
            S3_Bucket_Name__c = 'meter-images',
            S3_Key__c = '2026/01/MeterImage1.jpg'
        );
        insert doc;
        
        
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = doc.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;
        
        
        Test.startTest();
        
        Map<String, String> result =
            MeteringWorkOrderListViewController.getS3PathByContentVersionId(
                new List<String>{ cv.Id }
            );
        
        Test.stopTest();
        
        
        /*String expectedPath = 'meter-images, 2026/01/MeterImage1.jpg';
        
        System.assertEquals(
            1,
            result.size(),
            'One ContentVersion should be returned'
        );
        
        System.assertEquals(
            expectedPath,
            result.get(cv.Id),
            'Returned S3 path must match formula field value'
        );*/
    }
    
     @isTest
    static void test_executeBatchImageProcess() {
    

        Account acc = new Account(
            Name = 'Batch Test Account',
            BP_Number__c = 'BP_BATCH',
            Category__c = 'MRS'   // ✅ Formula source
        );
        insert acc;
    

        Id meteringRtId = Schema.getGlobalDescribe()
            .get('WorkOrder')
            .getDescribe()
            .getRecordTypeInfosByDeveloperName()
            .get('MGL_Metering')
            .getRecordTypeId();
    

        WorkOrder wo = new WorkOrder(
            Subject = 'Batch Image Test WO',
            Status = 'New',
            RecordTypeId = meteringRtId,
            AccountId = acc.Id,
            StartDate = Date.today(),
            EndDate = Date.today()
        );
        insert wo;
    
        Test.startTest();
    
        String jobId =
            MeteringWorkOrderListViewController.executeBatchImageProcess();
        Test.stopTest();
    
    }
}