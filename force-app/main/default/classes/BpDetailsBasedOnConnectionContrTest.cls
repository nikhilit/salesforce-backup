@IsTest
public class BpDetailsBasedOnConnectionContrTest {

    @TestSetup
    static void setupTestData() {
        // Create a Connection object (assuming it's a custom object)
        Connection__c conn = new Connection__c(Name = 'TestConnection');
        insert conn;

        // Create a WorkOrder related to the Connection
        WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            Status = 'New',
            Connection__c = conn.Id,
            Any_customer_using_gas_but_not_having_bp__c ='Yes',
           Customer_Details_Using_Gas_Not_Having_BP__c ='Mohan' 
        );
        insert wo;

        // Create Accounts linked to this Connection__r.Name
        List<Account> accountsToInsert = new List<Account>();
        for (Integer i = 1; i <= 3; i++) {
            accountsToInsert.add(new Account(
                Name = 'Account ' + i,
                BP_Number__c = 'BP00' + i,
                Connection_Object__c = conn.Name,
                Connection__c = conn.Id
            ));
        }
        insert accountsToInsert;
    }

    @IsTest
    static void testGetBPDetails() {
        // Retrieve the WorkOrder created in @TestSetup
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        // Call the controller method
        Test.startTest();
        List<BpDetailsBasedOnConnectionContr.BPWrapper> result = BpDetailsBasedOnConnectionContr.getBPDetails(wo.Id);
        Test.stopTest();

        // Validate results
       /* System.assertEquals(3, result.size(), 'There should be 3 BPWrapper records');
        System.assertEquals('BP001', result[0].name, 'First BP Number should match');
        System.assertEquals('BP002', result[1].name, 'Second BP Number should match');
        System.assertEquals('BP003', result[2].name, 'Third BP Number should match');
        System.assertEquals(1, result[0].index, 'First index should be 1');
        System.assertEquals(2, result[1].index, 'Second index should be 2'); */
    }
    
    @IsTest
    static void saveBPFoundDetailsTest(){
        
        
        WorkOrder wo = [Select id,Any_customer_using_gas_but_not_having_bp__c,Customer_Details_Using_Gas_Not_Having_BP__c from WorkOrder limit 1];
       
        Test.startTest();
        BpDetailsBasedOnConnectionContr.saveBPFoundDetails(wo.Id,'Yes','Sohan');
        
        Test.stopTest();
    }
     @IsTest
    static void getWorkOrderTest(){
        
        
        WorkOrder wo = [Select id,Any_customer_using_gas_but_not_having_bp__c,Customer_Details_Using_Gas_Not_Having_BP__c from WorkOrder limit 1];
       
        Test.startTest();
        BpDetailsBasedOnConnectionContr.getWorkOrder(wo.Id);
        
        Test.stopTest();
    }
}