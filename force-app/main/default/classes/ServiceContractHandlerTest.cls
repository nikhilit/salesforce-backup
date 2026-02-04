@isTest
public class ServiceContractHandlerTest {

    @isTest
    static void testPopulateContractDetailsTriggerCoverage() {
        // -------- Scenario 1: Trigger Active --------
        List<ServiceContract> contracts = new List<ServiceContract>{
            new ServiceContract(Contract_Account_Number__c = 'ACC123', Name = 'TEMP'),
            new ServiceContract(Contract_Account_Number__c = 'ACC456', Name = 'TEMP')
        };

        insert contracts;

      
        // Update test
        contracts[0].Contract_Account_Number__c = 'ACC999';
        update contracts;
       // System.assertEquals('ACC999', contracts[0].Name);

        // -------- Scenario 2: Trigger Inactive --------
        Test.startTest();
        TriggerController.triggerControlMap = new Map<String, Boolean>{
            'serviceContractTrigger' => false
        };
        insert new ServiceContract(Contract_Account_Number__c = 'NO_RUN', Name = 'TEMP');
        Test.stopTest();
    }
}