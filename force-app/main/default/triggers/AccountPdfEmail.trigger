trigger AccountPdfEmail on Account (After insert) {
    List<Id> accountIds = new List<Id>();
    Map<Id, String> accountOwnerEmails = new Map<Id, String>();

    List<Id> accountIdsForCustomer = new List<Id>();
    Map<Id, String> accountCustomerEmails = new Map<Id, String>();

    set<Id> accIds = new Set<Id>();
    for (Account acc : Trigger.new) {
        accIds.add(acc.Id);
    }

    for (Account acc : Trigger.new) {
        // Debug the Customer Email
        if (String.isNotBlank(acc.Email__c)) {
            System.debug('Customer Email for Account ' + acc.Id + ': ' + acc.Email__c);
            accountIdsForCustomer.add(acc.Id);
            accountCustomerEmails.put(acc.Id, acc.Email__c);
        }
    }

    // Collect Account IDs and their owner's email addresses
    for (Account acc : [SELECT Id, Owner.Email FROM Account WHERE Id IN :accIds]) {
        if (acc.OwnerId != null) {
            accountIds.add(acc.Id);
            accountOwnerEmails.put(acc.Id, acc.Owner.Email);
        }
    }

    // Call helper class to send emails
    if (!accountIds.isEmpty() && !accountOwnerEmails.isEmpty()) {
        AccountPDFEmailSender.sendAccountDetailsAsPDF(accountIds, accountOwnerEmails);
    }

    // Send email to customers
    if (!accountIdsForCustomer.isEmpty() && !accountCustomerEmails.isEmpty()) {
        System.debug('Sending emails to customers...');
        AccountPDFEmailSender.sendAccountDetailsToCustomer(accountIdsForCustomer, accountCustomerEmails);
    }
}