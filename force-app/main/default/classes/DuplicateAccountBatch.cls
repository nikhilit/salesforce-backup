global class DuplicateAccountBatch implements Database.Batchable<SObject>, Database.Stateful {

    private String fieldName; // Dynamic field name
    List<String> csvLines = new List<String>();

    // Constructor to accept field name
    global DuplicateAccountBatch(String fieldApiName) {
        this.fieldName = fieldApiName;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        // Build dynamic SOQL for grouping
        String query = 'SELECT ' + fieldName + ', COUNT(Id) cnt ' +
                       'FROM Account ' +
                       'WHERE ' + fieldName + ' != NULL ' +
                       'GROUP BY ' + fieldName + ' ' +
                       'HAVING COUNT(Id) > 1';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        for (AggregateResult ar : (List<AggregateResult>) scope) {
            Object dupValue = ar.get(fieldName);

            // Dynamic query for duplicate accounts
            String soql = 'SELECT Id, Name, ' + fieldName + ', CreatedDate, Owner.Name ' +
                          'FROM Account ' +
                          'WHERE ' + fieldName + ' = :dupValue ' +
                          'ORDER BY CreatedDate ASC';

            List<Account> dupAccs = Database.query(soql);

            for (Account acc : dupAccs) {
                csvLines.add(
                    '"' + acc.Id + '","' +
                    acc.Name + '","' +
                    String.valueOf(acc.get(fieldName)) + '","' +
                    acc.Owner.Name + '","' +
                    acc.CreatedDate.format() + '"'
                );
            }
        }
    }

    global void finish(Database.BatchableContext bc) {
        // Build CSV
        String header = 'Id,Name,' + fieldName + ',Owner,CreatedDate\n';
        String csvContent = header + String.join(csvLines, '\n');

        // Save as File
        ContentVersion file = new ContentVersion();
        file.Title = 'Duplicate_Accounts_Report_By_' + fieldName;
        file.PathOnClient = 'Duplicate_Accounts.csv';
        file.VersionData = Blob.valueOf(csvContent);
        insert file;

        // Email CSV to Admin
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName('Duplicate_Accounts.csv');
        attachment.setBody(Blob.valueOf(csvContent));
        attachment.setContentType('text/csv');

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] { UserInfo.getUserEmail() });
        mail.setSubject('Duplicate Account Report by ' + fieldName);
        mail.setPlainTextBody('Please find attached duplicate account report based on ' + fieldName + '.');
        mail.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}