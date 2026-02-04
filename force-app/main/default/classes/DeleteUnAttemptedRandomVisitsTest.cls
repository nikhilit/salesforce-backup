@isTest
private class DeleteUnAttemptedRandomVisitsTest {
    @TestSetup
    static void makeData(){
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
        Remarks__c = 'test'
            );
        
        insert wo;
    }
    
    @isTest
    static void testBatchDeletesMatchingWorkOrders() {
        Test.startTest();
        System.schedule(
            'DeleteUnAttemptedRandomVisits',
        '0 0 0 1 1 ? 2099',
        new DeleteUnAttemptedRandomVisits()
            );
        Test.stopTest();
    }
}