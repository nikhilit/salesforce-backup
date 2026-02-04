public with sharing class WhatsAppController {
    @AuraEnabled(cacheable=true)
    public static Contact getContactDetails(Id contactId) {
        // Fetch contact details including MobilePhone
        return [
            SELECT Id, Name, MobilePhone 
            FROM Contact 
            WHERE Id = :contactId
        ];
    }
}