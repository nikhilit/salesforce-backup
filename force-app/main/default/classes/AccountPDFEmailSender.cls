public with sharing class AccountPDFEmailSender {
    @future(callout = true)
    public static void sendAccountDetailsAsPDF(List<Id> accountIds, Map<Id, String> accountOwnerEmails) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        system.debug('accountIds : '+accountIds);
        system.debug('accountOnwerEmail : '+accountOwnerEmails);
        for (Id accountId : accountIds) {
            String ownerEmail = accountOwnerEmails.get(accountId);
            if (String.isNotBlank(ownerEmail)) {
                // Step 1: Generate PDF content from Visualforce page
                PageReference pdfPage = Page.AccountPDFPage;
                pdfPage.getParameters().put('id', accountId);
                Blob pdfBlob = pdfPage.getContentAsPDF();

                // Step 2: Create email message
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new List<String>{ownerEmail});
                email.setSubject('New Account Created - Account Details');
                email.setPlainTextBody('A new account has been created. Please find attached the account details in PDF format.');
                
                // Step 3: Attach the PDF file
                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                attachment.setFileName('AccountDetails_' + accountId + '.pdf');
                attachment.setBody(pdfBlob);
                attachment.setContentType('application/pdf');
                email.setFileAttachments(new List<Messaging.EmailFileAttachment>{attachment});

                // Add email to the list
                emails.add(email);
            }
        }
        system.debug('emails: ' + emails);
        // Step 4: Send all emails
        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }


    @future(callout = true)
    public static void sendAccountDetailsToCustomer(List<Id> accountIdsForCustomer, Map<Id, String> accountCustomerEmails) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        System.debug('accountIds: ' + accountIdsForCustomer);
        System.debug('accountEmails: ' + accountCustomerEmails);

        for (Id accountId : accountIdsForCustomer) {
            String customerEmail = accountCustomerEmails.get(accountId);
            if (String.isNotBlank(customerEmail)) {
                // Step 1: Generate PDF content from Visualforce page
                PageReference pdfPage = Page.AccountPDFPage;
                pdfPage.getParameters().put('id', accountId);
                Blob pdfBlob = pdfPage.getContentAsPDF();

                // Step 2: Create email message
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new List<String>{customerEmail});
                email.setSubject('Your Account Has Been Created Successfully!');
                email.setPlainTextBody(
                    'Thank you for creating an account with us! ' +
                    'Please find your account details attached in PDF format.' +
                    '\n\n' +
                    'We look forward to serving you!'
                );

                // Step 3: Attach the PDF file
                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                attachment.setFileName('Your_Account_Details_' + accountId + '.pdf');
                attachment.setBody(pdfBlob);
                attachment.setContentType('application/pdf');
                email.setFileAttachments(new List<Messaging.EmailFileAttachment>{attachment});

                // Add email to the list
                emails.add(email);
            }
        }

        // Step 4: Send all emails
        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }


}