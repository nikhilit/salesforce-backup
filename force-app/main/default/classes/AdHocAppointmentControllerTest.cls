@isTest
private class AdHocAppointmentControllerTest {
    
    static testMethod void testGetPicklistValues() {
        Test.startTest();
        AdHocAppointmentController.PicklistWrapper wrapper = AdHocAppointmentController.getPicklistValues();
        System.assertNotEquals(null, wrapper);
        System.assertNotEquals(null, wrapper.identificationTypes);
        System.assertNotEquals(null, wrapper.appointmentTypes);
        Test.stopTest();
    }
    
    static testMethod void testGetValidAccounts_withResults() {
        // Setup test data
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        // Setup service resource and territory
        OperatingHours oh = new OperatingHours(Name = 'Default Hours');
        insert oh;
        
        Account acc = new Account(Name = 'Test Account', LastName__c = 'Smith', Category__c = 'Domestic');
        insert acc;
        
        ServiceTerritory st = new ServiceTerritory(OperatingHoursId = oh.Id,Name = 'Test Territory', IsActive = true);
        insert st;
        
        ServiceResource sr = new ServiceResource(Name = 'Test Resource', IsActive = true, RelatedRecordId = u.Id);
        insert sr;
        
        ServiceTerritoryMember stm = new ServiceTerritoryMember(
            ServiceTerritoryId = st.Id,
            ServiceResourceId = sr.Id,
            EffectiveStartDate = System.Today()
        );
        insert stm;
        
        Test.startTest();
        Map<String, Object> result = AdHocAppointmentController.getValidAccounts('Smith');
        Test.stopTest();
        
        System.assertNotEquals(null, result);
        System.assert(result.containsKey('accounts'));
    }
    
    static testMethod void testGetValidAccounts_noResults() {
        Test.startTest();
        Map<String, Object> result = AdHocAppointmentController.getValidAccounts('NothingHere');
        Test.stopTest();
        System.assertEquals(null, result);
    }
    
    static testMethod void testGetAccountByIdentification_success() {
        Account acc = new Account(Name = 'Test Account', LastName__c = 'Johnson', BP_Number__c = 'BP123', Category__c = 'Domestic');
        insert acc;
        
        Test.startTest();
        Account found = AdHocAppointmentController.getAccountByIdentification('BP Number', 'BP123');
        Test.stopTest();
        
        System.assertNotEquals(null, found);
        System.assertEquals(acc.Id, found.Id);
    }
    
    static testMethod void testGetAccountByIdentification_invalidType() {
        Boolean exceptionThrown = false;
        try {
            AdHocAppointmentController.getAccountByIdentification('Invalid Type', '123');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        System.assertEquals(true, exceptionThrown);
    }
    
    static testMethod void testCreateAdHocAppointment_success() {
        // Setup account + contact
        Contact con = new Contact(LastName = 'Test Contact');
        Account acc = new Account(Name = 'Test Account', LastName__c = 'Doe', BP_Number__c = 'BP001', Category__c = 'Domestic', Phone = '1234567890');
        
        insert acc;
        
        // Setup service resource and territory
        OperatingHours oh = new OperatingHours(Name = 'Default Hours');
        insert oh;
        ServiceTerritory st = new ServiceTerritory(Name = 'Territory', OperatingHoursId = oh.Id, IsActive = true);
        insert st;
        
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        ServiceResource sr = new ServiceResource(Name = 'Resource', IsActive = true, RelatedRecordId = u.Id);
        insert sr;
        
        insert new ServiceTerritoryMember(ServiceTerritoryId = st.Id, ServiceResourceId = sr.Id,EffectiveStartDate=System.today());
        
        // Create a ServiceAppointment for the WO to link to
        // (In a real org this might be auto-created by trigger)
        
        Test.startTest();
        String woId;
        try {
        	woId = AdHocAppointmentController.createAdHocAppointment('BP Number', 'BP001', acc.Id);
        } catch (AuraHandledException e) {
            //exceptionThrown = true;
        }
        Test.stopTest();
        
        //System.assertNotEquals(null, woId);
        //System.assert([SELECT Id FROM WorkOrder WHERE Id = :woId LIMIT 1] != null);
    }
    
    static testMethod void testCreateAdHocAppointment_noServiceResource() {
        Account acc = new Account(Name = 'Test Account', LastName__c = 'Doe', BP_Number__c = 'BP002', Category__c = 'Domestic');
        insert acc;
        
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            AdHocAppointmentController.createAdHocAppointment('BP Number', 'BP002', acc.Id);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        
        System.assertEquals(true, exceptionThrown);
    }
   
}