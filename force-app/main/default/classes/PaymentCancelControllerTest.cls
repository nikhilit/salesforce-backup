@isTest
public class PaymentCancelControllerTest {
    @TestSetup
    static void makeData(){
        // Create WorkType
        WorkType WT = new WorkType(
            Name = 'Domestic Customer (R&T)',
        ShouldAutoCreateSvcAppt=true,
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
        AccountId = acc.Id,
        StartDate = startDate,
        EndDate = endDate,
        WorkTypeId = WT.Id,
        CA_Number__c = 'CA123',
        Customer_BP_Number__c = 'BP123',
        Customer_Name__c = 'Test Customer',
        Work_Order_Type__c = 'Ad-Hoc',
        Due_Amount__c = 100,
        Payment_Remark__c = 'Random Payment',
        New_Mobile_Number__c = '9021743879',
        Remarks__c = 'test',
        Payment_Date__c = '09/01/2026'
            );
        
        insert wo;
        
        ServiceAppointment serviceAppointment = [SELECT Id, Status FROM ServiceAppointment WHERE ParentRecordId =: wo.Id ORDER BY CreatedDate DESC limit 1];
        serviceAppointment.Status = 'Scheduled';
        update serviceAppointment;
        
        Payment__c pay = new Payment__c(
            Name = 'testCheque',
        Cheque_Number__c = '23123123',
        Work_Order__c = wo.Id
            );
        insert pay;
        Go_Collect_Follow_Up__mdt cfg = Go_Collect_Follow_Up__mdt.getInstance('Cheque_Cancel');
        // Insert a dummy template for wrapper
        Case_Type_SMS__c tmpl = new Case_Type_SMS__c(
            Message__c = 'Hello {!Remark}',
        Template_Id__c = cfg.Template_Id__c
            );
        insert tmpl;
    }
    
    @isTest
    public static void checkValidityTest(){
        Test.startTest();
        WorkOrder wo = [SELECT Id FROM WorkOrder Limit 1];
        Boolean isValid = PaymentCancelController.checkValidity(wo.Id);
        Test.stopTest();
    }
    
    @isTest
    public static void cancelReceiptMethod(){
        Test.startTest();
        WorkOrder wo = [SELECT Id FROM WorkOrder Limit 1];
        Map<String, Object> formData = new Map<String, Object>();
        formData.put('cancelReason', 'Agreed to pay online');
        formData.put('remarks', 'Test remarks for cancellation');
        
        PaymentCancelController.cancelReceiptMethod(formData, wo.Id);
        Test.stopTest();
    }
    @isTest
    public static void updateWorkStepsTest(){
        Test.startTest();
        WorkOrder wo = [SELECT Id FROM WorkOrder Limit 1];
        
        PaymentCancelController.updateWorkSteps(wo.Id);
        Test.stopTest();
    }
    
    @isTest
    public static void updatePaymentsTest(){
        Test.startTest();
        WorkOrder wo = [SELECT Id FROM WorkOrder Limit 1];
        
        PaymentCancelController.updatePayments(wo.Id, 'Agreed to pay online');
        Test.stopTest();
    }
    
    @isTest
    public static void sendSmsTest(){
        Test.startTest();
        WorkOrder wo = [SELECT Id FROM WorkOrder Limit 1];
        
        PaymentCancelController.sendSms('9021743879', wo.Id);
        Test.stopTest();
    }
}