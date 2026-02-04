@IsTest
public class BPBankHandlerTest {

    @IsTest
    static void testMarkBillingToBeProcessed() {
        // Prepare test data
        BP_Bank_Details__c bank = new BP_Bank_Details__c(
            Unique_ID__c = '12345'
        );

        List<BP_Bank_Details__c> bankList = new List<BP_Bank_Details__c>{ bank};

       insert bankList;
    }
}