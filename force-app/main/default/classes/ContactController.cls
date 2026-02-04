public with sharing class ContactController {
    @AuraEnabled
    public static void createContacts(List<Contact> contacts) {
        try {
            insert contacts;
        } catch (Exception e) {
            throw new AuraHandledException('Error while creating contacts: ' + e.getMessage());
        }
    }
}