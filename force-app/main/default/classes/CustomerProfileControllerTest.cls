@isTest
public class CustomerProfileControllerTest {
    
    @isTest
    static void test_CustomerProfileController(){
        
        Account acc = new Account();
        acc.Name = 'Test Acc';
        acc.BP_Number__c = '12345';
        acc.CA_Number__c = '54321';
        acc.Dispenser_Number__c = '67890';
        acc.Category__c = 'CNG/LNG';
        acc.Road_name__c = 'Test Road';
        acc.Location__c = 'Street';
        acc.Floor__c = '4';
        acc.Flat__c = '12';
        acc.Building_name__c = 'A2';
        Insert acc;
        
        WorkOrder wo = new WorkOrder(
            AccountId = acc.Id,
            Subject = 'Test WO 1',
            Status = 'New',
            Closing_Meter_Reading__c = 80,
            SCADA_Closing_Reading__c = 100
        );
        insert wo;

        Test.startTest();
        CustomerProfileController.getCustomerProfile(wo.Id);
        Test.stopTest();        
    }
}