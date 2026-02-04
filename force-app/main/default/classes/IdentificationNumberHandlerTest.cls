@IsTest
public class IdentificationNumberHandlerTest {

    @IsTest
    static void testMarkIdentificationsToBeProcessed() {
        // Prepare test data
        Identification_Number__c ident1 = new Identification_Number__c(
            Unique_Id__c = 'CODE123'
        );
        Identification_Number__c ident2 = new Identification_Number__c(
            Unique_Id__c = null
        );

        List<Identification_Number__c> records = new List<Identification_Number__c>{ ident1, ident2 };

        // Call method
        IdentificationNumberHandler.markIdentificationsToBeProcessed(records,null);
        insert records;
        
    }
}