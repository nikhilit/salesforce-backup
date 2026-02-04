public class AS_ReportEmailerQueue implements Queueable, Database.AllowsCallouts {
    private Id reportId;
    private List<User> recipients;

    public AS_ReportEmailerQueue(Id reportId, List<User> recipients) {
        this.reportId = reportId;
        this.recipients = recipients;
    }

    public void execute(QueueableContext context) {
        for (User u : recipients) {
            System.runAs(u) {
                Reports.ReportResults results = Reports.ReportManager.runReport(reportId, true);
                String xlsData = AS_ReportEmailer.generateXlsFromReport(results);

                // Create attachment
                ContentVersion cv = new ContentVersion(
                    Title = 'Daily_Collections_Report_' + Date.today().format(),
                    PathOnClient = 'Daily_Collections_Report_' + u.Name + '.xls',
                    VersionData = Blob.valueOf(xlsData)
                );
                insert cv;

                // Send the email
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new String[]{ u.Email });
                mail.setSubject('Daily Collections Report - ' + Date.today().format());
                mail.setPlainTextBody('Dear ' + u.Name + ',\n\nPlease find enclosed your daily report.');
                mail.setEntityAttachments(new Id[]{ cv.Id });
                Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ mail });
            }
        }
    }
}