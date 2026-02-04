@IsTest
public class SecurityDepositTriggerHandlerTest {

    @IsTest
    static void testAssignValues() {
        // Prepare sample data
        Security_Deposit__c depWithNumber = new Security_Deposit__c(
            Security_Number__c = 'SEC-123'
        );
        Security_Deposit__c depWithoutNumber = new Security_Deposit__c(
            Security_Number__c = null
        );

        List<Security_Deposit__c> depositList = new List<Security_Deposit__c>{
            depWithNumber, depWithoutNumber
        };

        // Call the method
        //SecurityDepositTriggerHandler.assignValues(depositList);
        insert depositList;
    }
}