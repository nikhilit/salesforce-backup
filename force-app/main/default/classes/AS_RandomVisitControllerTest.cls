@isTest
public class AS_RandomVisitControllerTest {
    // 🔧 Common Test Data
    @testSetup
    static void setupTestData() {
        
        RecordType woRt = [SELECT Id FROM RecordType
            WHERE SObjectType='WorkOrder' AND DeveloperName='MGL_R_T'
            LIMIT 1];
        
        // Create WorkType
        WorkType WT = new WorkType(
            Name = 'Domestic Customer (R&T)',
        ShouldAutoCreateSvcAppt=false,
        EstimatedDuration=6
            );
        insert WT;
        
        // Create Account with BP and CA numbers
        Account acc = new Account(
            Name = 'Test Customer',
        BP_Number__c = 'BP123',
        CA_Number__c = 'CA123'
            );
        insert acc;
        
        Account acc2 = new Account(
            Name = 'Test Customer',
        BP_Number__c = 'BP1234',
        CA_Number__c = 'CA123'
            );
        insert acc2;
        
        OperatingHours oph = new OperatingHours(Name='OPH', TimeZone='Asia/Kolkata');
        insert oph;
        
        // Create Service Resource & Territory setup
        ServiceTerritory st = new ServiceTerritory(Name = 'Test Territory',
        OperatingHoursId = oph.Id, IsActive=true);
        insert st;
        
        ServiceResource sr = new ServiceResource(
            Name = 'Agent Resource',
        IsActive = true,
        RelatedRecordId = UserInfo.getUserId()
            );
        insert sr;
        
        ServiceTerritoryMember stm = new ServiceTerritoryMember(
            ServiceResourceId=sr.Id,
        ServiceTerritoryId=st.Id,
        EffectiveStartDate=Date.today().addDays(-2),
        EffectiveEndDate=Date.today().addYears(1)
            );
        insert stm;
        
        Id recordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().get('MGL_R_T').getRecordTypeId();
        Date today = Date.today();
        DateTime startDate = DateTime.newInstance(today, Time.newInstance(9, 0, 0, 0));
        DateTime endDate = DateTime.newInstance(today, Time.newInstance(20, 0, 0, 0));
        
        WorkOrder wo = new WorkOrder(
            RecordTypeId = recordTypeId,
        AccountId = acc2.Id,
        StartDate = startDate,
        EndDate = endDate,
        WorkTypeId = WT.Id,
        CA_Number__c = 'CA123',
        Customer_BP_Number__c = 'BP1234',
        Customer_Name__c = 'Test Customer',
        Work_Order_Type__c = 'Ad-Hoc',
        Due_Amount__c = 100,
        Payment_Remark__c = 'Random Payment',
        Remarks__c = 'test'
            );
        
        System.debug('WorkOrder: ' + wo);
        insert wo;
    }
    
    // Get Account by BP Number
    @IsTest
    static void GetAccountByBPNumberTest() {
        Account acc = [SELECT BP_Number__c FROM Account WHERE BP_Number__c = 'BP123' LIMIT 1];
        Test.startTest();
        Account result = AS_RandomVisitController.getAccountByBPNumber('BP123');
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Account should be returned for valid BP');
        System.assertEquals(acc.BP_Number__c, result.BP_Number__c, 'Returned account should match BP');
    }
    
    @IsTest
    static void createRandomPaymentWorkOrderTest() {
        Map<String, Object> formData = new Map<String, Object>{
            'BPNumber' => 'BP123',
            'Remark' => 'Random Collection',
            'PaymentAmount' => '250.50'
        };
        
        Test.startTest();
        AS_RandomVisitController.createRandomPaymentWorkOrder(formData , false);
        Test.stopTest();
    }

    @IsTest
    static void createRandomPaymentWorkOrderTest2() {
        Map<String, Object> formData = new Map<String, Object>{
            'Remark' => 'Random Collection',
            'PaymentAmount' => '250.50',
            'WorkType' => 'Domestic Customer (R&T)', // billing distribution (r&t)
            'AccountName' => 'Test Customer',
            'CANumber' => 'CA123'
        };
        
        Test.startTest();
        AS_RandomVisitController.createRandomPaymentWorkOrder(formData, false);
        Test.stopTest();
    }

    @IsTest
    static void createRandomPaymentWorkOrderTest3() {
        Map<String, Object> formData = new Map<String, Object>{
            'Remark' => 'Random Collection',
            'PaymentAmount' => '250.50',
            'WorkType' => 'Domestic Customer (R&T)',
            'AccountName' => 'Test Customer234',
            'CANumber' => 'CA122343'
        };
        
        Test.startTest();
        AS_RandomVisitController.createRandomPaymentWorkOrder(formData, true);
        Test.stopTest();
    }
    
    @IsTest
    static void createRandomPaymentWorkOrderTest_isFieldSense() {
        Map<String, Object> formData = new Map<String, Object>{
            'BPNumber' => 'BP123',
            'Remark' => 'Random Collection',
            'PaymentAmount' => '250.50',
            'WorkType' => 'Domestic Customer (R&T)', // billing distribution (r&t)
            'AccountName' => 'Test Customer',
            'CANumber' => 'CA123'
        };
        
        Test.startTest();
        AS_RandomVisitController.createRandomPaymentWorkOrder(formData, true);
        Test.stopTest();
    }
    
    @IsTest
    static void createRandomPaymentWorkOrderTest_isFieldSenseBPMismatch() {
        Map<String, Object> formData = new Map<String, Object>{
            'BPNumber' => 'BP12213',
            'Remark' => 'Random Collection',
            'PaymentAmount' => '250.50',
            'WorkType' => 'Domestic Customer (R&T)',
            'AccountName' => 'Test Customer',
            'CANumber' => 'CA123'
        };
        
        Test.startTest();
        try {
            AS_RandomVisitController.createRandomPaymentWorkOrder(formData, true);
        } catch (AuraHandledException e) {
            // String expectedMessagePart1 = 'BP Number = ' + formData.get('BPNumber');
            // String expectedMessagePart2 = 'Customer Name = ' + formData.get('AccountName');
            // String expectedMessagePart3 = 'CA Number = ' + formData.get('CANumber');
            
            // String expectedMessage = 'No matching Account found for: '
            //     + expectedMessagePart1 + ', '
            //     + expectedMessagePart2 + ', '
            //     + expectedMessagePart3;
            
            System.assertEquals('Script-thrown exception', e.getMessage());
        }
        Test.stopTest();
    }
    
}