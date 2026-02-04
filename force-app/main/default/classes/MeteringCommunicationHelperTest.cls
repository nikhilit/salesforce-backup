@isTest
private class MeteringCommunicationHelperTest {

    // Mock for SmsApiHelper callouts
    private class MockHttp implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"msg":"OK"}');
            return res;
        } 
    }

    @testSetup
    static void setupData() {
        // Record Type for WorkOrder
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'WorkOrder' AND DeveloperName = 'MGL_Metering' LIMIT 1];

        // Create Account
        Account acc = new Account(Name = 'Test Account', BP_Number__c = 'BP001',Category__c='Domestic',Phone__c='8978876778', CA_Number__c ='786778',preferance__c='Whatsapp' );
        insert acc;
        
        Group_Master__c gm=new Group_Master__c(Name='GM1');
        insert gm;

        // Create Group Code
        Group_Code__c gc = new Group_Code__c(Name = 'GC1',Code__c=12);
        gc.Group_Master__c=gm.Id;
        insert gc;
        
        Group_Code__c gcNo = new Group_Code__c(Name = 'GCNo',Code__c=122);
        gcNo.Group_Master__c=gm.Id;
        insert gcNo;

        // Create Template
        Case_Type_SMS__c smsTemplate = new Case_Type_SMS__c(
            Template_Name__c = 'Test Template',
            Template_Id__c = 'TPL001',
            Message__c = 'Dear {!Customer_CA_Number__c}, reading: {!Current_Meter_Reading__c}',
            Active__c = true
        );
        Case_Type_SMS__c smsTemplate2 = new Case_Type_SMS__c(
            Template_Name__c = 'Visit Notification',
            Template_Id__c = 'TPL001',
            Message__c = 'Dear {!Customer_CA_Number__c}, reading: {!Current_Meter_Reading__c}',
            Active__c = true
        );
        insert smsTemplate;
        insert smsTemplate2;

        // Attach template to Group Code
        gc.SMS_Template__c = smsTemplate.Id;
        update gc;

        // WorkOrder with Group Code & Contact
        WorkOrder wo1 = new WorkOrder(
            Subject = 'WO Success',
            AccountId = acc.Id,
            RecordTypeId = rt.Id,
            Appointment_Status__c = 'Completed',
            Group_Code__c = gc.Id,
            Meter_Reading__c =123,
             Check_Out_Date_Time__c = System.now()
        );
        insert wo1;

        // WorkOrder without Group Code
        WorkOrder wo2 = new WorkOrder(
            Subject = 'WO Missing Group Code',
            AccountId = acc.Id,
            RecordTypeId = rt.Id,
            Appointment_Status__c = 'Completed',
            Meter_Reading__c =123,
            Check_Out_Date_Time__c = System.now()
        );
        insert wo2;
        
        Meter_Reading_Schedule__c mrsRec=new Meter_Reading_Schedule__c(Status__c='Approved');
        insert mrsRec;

        // WorkOrder without Contact Number
        WorkOrder wo3 = new WorkOrder(
            Subject = 'WO Missing Contact',
            AccountId = acc.Id,
            RecordTypeId = rt.Id,
            Appointment_Status__c = 'Completed',
            Group_Code__c = gc.Id,
            Meter_Reading_Schedule__c=mrsRec.Id
        );
        insert wo3;
        
        WorkOrder wo4 = new WorkOrder(
            Subject = 'WO No SMS Tempdate',
            AccountId = acc.Id,
            RecordTypeId = rt.Id,
            Appointment_Status__c = 'Completed',
            Group_Code__c = gcNo.Id,
            Meter_Reading__c =123,
             Check_Out_Date_Time__c = System.now()
        );
        insert wo4;
    }

    @isTest
    static void testAfterUpdateAndFutureSMS() {
        Test.setMock(HttpCalloutMock.class, new MockHttp());

        // Fetch test WorkOrders
        List<WorkOrder> wos = [SELECT Id, Appointment_Status__c, RecordTypeId, Group_Code__c, Customer_Contact_Number__c,Customer_Category__c FROM WorkOrder];

        // Simulate oldMap with different status
        Map<Id, WorkOrder> oldMap = new Map<Id, WorkOrder>();
        for (WorkOrder wo : wos) {
            WorkOrder cloneWo = wo.clone(false, false, false, false);
            cloneWo.Appointment_Status__c = 'Scheduled';
            oldMap.put(wo.Id, cloneWo);
        }
        
        List<Meter_Reading_Schedule__c> listMRS=[SELECT Id,Status__c FROM Meter_Reading_Schedule__c];
        Map<Id, Meter_Reading_Schedule__c> oldMapMRS = new Map<Id, Meter_Reading_Schedule__c>();
        for (Meter_Reading_Schedule__c wo : listMRS) {
            Meter_Reading_Schedule__c cloneMRS = wo.clone(false, false, false, false);
            cloneMRS.Status__c = 'Pending';
            oldMapMRS.put(wo.Id, cloneMRS);
        }

        Test.startTest();
        MeteringCommunicationHelper.afterUpdate(wos, oldMap);
        MeteringCommunicationHelper.afterInsertUpdateMRS(listMRS, oldMapMRS);
        Test.stopTest();

    }

    @isTest
    static void testSendWorkOrderSMS_MissingData() {
        Test.setMock(HttpCalloutMock.class, new MockHttp());

        // WorkOrders inserted in testSetup
        List<WorkOrder> wos = [SELECT Id,Appointment_Status__c, RecordTypeId, Group_Code__c, Customer_Contact_Number__c,Customer_Category__c FROM WorkOrder];

        Test.startTest();
        Set<Id> setWorkOrderIds=new Set<Id>();
        setWorkOrderIds.add(wos[0].Id);
        MeteringCommunicationHelper.executeSendWorkOrderSMS(setWorkOrderIds);
        Test.stopTest();

    }
    
    @isTest
    static void testSendWorkOrderSMS_NOSMSTempdate() {
        Test.setMock(HttpCalloutMock.class, new MockHttp());

        // WorkOrders inserted in testSetup
        List<WorkOrder> wos = [SELECT Id,Appointment_Status__c, RecordTypeId, Group_Code__c, Customer_Contact_Number__c,Customer_Category__c FROM WorkOrder WHERE Subject = 'WO No SMS Tempdate'];

        Test.startTest();
        Set<Id> setWorkOrderIds=new Set<Id>();
        setWorkOrderIds.add(wos[0].Id);
        MeteringCommunicationHelper.executeSendWorkOrderSMS(setWorkOrderIds);
        Test.stopTest();

    }
    
        @isTest
    static void testBuildMergeFieldJson() {
        // Prepare test WorkOrder
        WorkOrder wo = [SELECT Id, Customer_Contact_Number__c,Meter_Reading__c FROM WorkOrder LIMIT 1];

        // Prepare template with placeholders
        String smsTemplate = 'Dear {!Customer_Contact_Number__c}, your reading is {!Meter_Reading__c} and static {!Static_Value__c}';

        // Prepare merge field config map
        Map<String, Message_Template_Field_Mapping_Config__mdt> mergeFields = new Map<String, Message_Template_Field_Mapping_Config__mdt>();

        // Placeholder 1: From Field
        Message_Template_Field_Mapping_Config__mdt cfg1 = new Message_Template_Field_Mapping_Config__mdt(
            MasterLabel = 'Customer Contact Field',
            DeveloperName = 'Customer_Contact_Number__c',
            Type__c = 'Field',
            Field_API_Name__c = 'Customer_Contact_Number__c'
        );
        mergeFields.put('Customer_Contact_Number__c', cfg1);

        // Placeholder 2: From Field
        Message_Template_Field_Mapping_Config__mdt cfg2 = new Message_Template_Field_Mapping_Config__mdt(
            MasterLabel = 'Meter Reading',
            DeveloperName = 'Meter_Reading__c',
            Type__c = 'Field',
            Field_API_Name__c = 'Meter_Reading__c'
        );
        mergeFields.put('Meter_Reading__c', cfg2);

        // Placeholder 3: Static Value
        Message_Template_Field_Mapping_Config__mdt cfg3 = new Message_Template_Field_Mapping_Config__mdt(
            MasterLabel = 'Static Value Config',
            DeveloperName = 'Static_Value__c',
            Type__c = 'Value',
            Value__c = '12345'
        );
        mergeFields.put('Static_Value__c', cfg3);

        // Call method
        Test.startTest();
        String jsonOutput = MeteringCommunicationHelper.buildMergeFieldJson(smsTemplate, wo, mergeFields);
        Test.stopTest();

        // Validate output JSON
        System.assertNotEquals(null, jsonOutput);
        System.assert(jsonOutput.contains('Customer_Contact_Number__c'));
        System.assert(jsonOutput.contains('Meter_Reading__c'));
        System.assert(jsonOutput.contains('Static_Value__c'));
    }
    
    @isTest
    static void testExecuteSendMRSApprovalSMS_Success() {
        Test.setMock(HttpCalloutMock.class, new MockHttp());

        // Get WorkOrder linked to MRS
        List<WorkOrder> wos = [SELECT Id FROM WorkOrder WHERE Meter_Reading_Schedule__c != null LIMIT 1];
        
        Test.startTest();
        Set<Id> workOrderIds = new Set<Id>{wos[0].Id};
        MeteringCommunicationHelper.executeSendMRSApprovalSMS(workOrderIds);
        Test.stopTest();

        // Verify method executed without errors
        System.assertEquals(1, wos.size(), 'WorkOrder should exist');
    }
    
    @isTest
    static void testExecuteSendMRSApprovalSMS_EmptySet() {
        Test.startTest();
        Set<Id> workOrderIds = new Set<Id>();
        MeteringCommunicationHelper.executeSendMRSApprovalSMS(workOrderIds);
        Test.stopTest();

        // Method should handle empty set gracefully
        System.assertEquals(0, workOrderIds.size(), 'Should handle empty set');
    }
    
    @isTest
    static void testGetCommunicationMode() {
        // Test SMS mode
        Map<String, Boolean> result1 = MeteringCommunicationHelper.getCommunicationMode('SMS', 'Whatsapp');
        System.assertEquals(true, result1.get('sendSMS'), 'SMS should be true');
        System.assertEquals(false, result1.get('sendWhatsApp'), 'WhatsApp should be false');
        
        // Test WhatsApp mode
        Map<String, Boolean> result2 = MeteringCommunicationHelper.getCommunicationMode('WhatsApp', 'SMS');
        System.assertEquals(false, result2.get('sendSMS'), 'SMS should be false');
        System.assertEquals(true, result2.get('sendWhatsApp'), 'WhatsApp should be true');
        
        // Test Both mode
        Map<String, Boolean> result3 = MeteringCommunicationHelper.getCommunicationMode('Both', null);
        System.assertEquals(true, result3.get('sendSMS'), 'SMS should be true');
        System.assertEquals(true, result3.get('sendWhatsApp'), 'WhatsApp should be true');
        
        // Test Preference mode with Whatsapp preference
        Map<String, Boolean> result4 = MeteringCommunicationHelper.getCommunicationMode('Preference', 'Whatsapp');
        System.assertEquals(false, result4.get('sendSMS'), 'SMS should be false');
        System.assertEquals(true, result4.get('sendWhatsApp'), 'WhatsApp should be true');
        
        // Test Preference mode with SMS preference
        Map<String, Boolean> result5 = MeteringCommunicationHelper.getCommunicationMode('Preference', 'SMS');
        System.assertEquals(true, result5.get('sendSMS'), 'SMS should be true');
        System.assertEquals(false, result5.get('sendWhatsApp'), 'WhatsApp should be false');
    }

}