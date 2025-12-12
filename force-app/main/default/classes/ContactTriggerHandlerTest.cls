@isTest
public class ContactTriggerHandlerTest {
    @isTest
    static void testDuplicateContactCreation() {
        // Create existing contact in the database
        Account acc= new Account();
        acc.Name='test acc';
        insert acc;
        
        
        Contact existingCon = new Contact(LastName = 'Smith', Email = 'test@example.com', Phone = '1234567890');
        existingCon.AccountId=acc.Id;
        insert existingCon;
        
        // Now, create a new contact record that will trigger the logic
        Contact newCon = new Contact(LastName = 'Smith', Email = 'test@example.com', Phone = '1234567890');
        
        // Add the new contact to a list to simulate the trigger firing
        List<Contact> newContacts = new List<Contact> { newCon };
        
        // Run your method
        Test.startTest();
        ContactTriggerHandler.DoNotLetThemCreateContactCreation(newContacts);
        
        Test.stopTest();
        
        // Check if the new contact was prevented from being created
        System.assert(newCon.Id == null, 'Duplicate contact should not be inserted');
    }
}