public with sharing class DailyTrackingRealtimeController {

    public class ReportData {
        @AuraEnabled public String reportName;
        @AuraEnabled public Integer opening;
        @AuraEnabled public Integer oldReceived;
        @AuraEnabled public Integer newReceived;
        @AuraEnabled public Integer crReceived;
        @AuraEnabled public Integer doneCategorized;
        @AuraEnabled public Integer doneCR;
        @AuraEnabled public Integer pending;
        @AuraEnabled public Integer received;
        @AuraEnabled public Integer totalDone;
    }

    @AuraEnabled(cacheable=false)
    public static ReportData getReport(String reportName) {

        Date today = System.today();
        Date yesterday = today.addDays(-1);

        DateTime startToday = DateTime.newInstance(today, Time.newInstance(0,0,0,0));
        DateTime endToday   = startToday.addDays(1);

        DateTime startYesterday = DateTime.newInstance(yesterday, Time.newInstance(0,0,0,0));
        DateTime endYesterday   = startYesterday.addDays(1);

        ReportData r = new ReportData();
        r.reportName = reportName;

        // BACK OFFICE REPORTS
        if (reportName == 'Email + Web' || reportName == 'MGL Connect' || reportName == 'Critical Cases') {

            String extraFilter = '';
            if (reportName == 'Email + Web') extraFilter = ' AND Origin IN (\'4\',\'6\')';
            else if (reportName == 'MGL Connect') extraFilter = ' AND Origin = \'10\'';
            else if (reportName == 'Critical Cases') extraFilter = ' AND Is_Email_Critical__c = true';

            // OPENING
            r.opening = Database.countQuery(
                'SELECT COUNT() FROM Case WHERE CRM_Segments__c = \'Back Office\' AND IsClosed = false AND Status = \'Assigned\' AND Categorised_By__c = null AND CreatedDate < :startToday ' + extraFilter
            );

            // OLD RECEIVED
            r.oldReceived = Database.countQuery(
                'SELECT COUNT() FROM Case WHERE CRM_Segments__c = \'Back Office\' AND Status = \'New\' AND CreatedDate >= :startYesterday AND CreatedDate < :endYesterday ' + extraFilter
            );

            // NEW RECEIVED
            r.newReceived = Database.countQuery(
                'SELECT COUNT() FROM Case WHERE CRM_Segments__c = \'Back Office\' AND CreatedDate >= :startToday AND CreatedDate < :endToday ' + extraFilter
            );

            // CR RECEIVED
            Set<Id> crIds = new Set<Id>();

            for (CaseHistory ch : [
                SELECT CaseId, NewValue
                FROM CaseHistory
                WHERE Field = 'Status'
                AND CreatedDate >= :startToday
                AND CreatedDate < :endToday
                AND CreatedBy.Name = 'Automated User1'
            ]) {
                if (String.valueOf(ch.NewValue) == 'Customer Responded') {
                    crIds.add(ch.CaseId);
                }
            }

            if (!crIds.isEmpty()) {
                String caseFilter = 'SELECT COUNT() FROM Case WHERE Id IN :crIds';

                // apply Origin-based extraFilter
                if (reportName == 'Email + Web') {
                    caseFilter += ' AND Origin IN (\'4\',\'6\')';
                } else if (reportName == 'MGL Connect') {
                    caseFilter += ' AND Origin = \'10\'';
                } else if (reportName == 'Critical Cases') {
                    caseFilter += ' AND Is_Email_Critical__c = true';
                }

                r.crReceived = Database.countQuery(caseFilter);
            } else {
                r.crReceived = 0;
            }

r.doneCategorized = Database.countQuery(
    'SELECT COUNT() FROM Case ' +
    'WHERE CRM_Segments__c = \'Back Office\' ' +
    'AND (Assigned_To_Department__c = :today ' +
    'OR (Status = \'Resolved by CRM\' AND ClosedDate = TODAY)) ' +
    extraFilter
);



            // DONE CR
            List<CaseHistory> chList = [
                SELECT CaseId, OldValue, NewValue
                FROM CaseHistory
                WHERE Field = 'Status'
                AND CreatedDate >= :startToday
                AND CreatedDate < :endToday
            ];

            Set<Id> doneCRCaseIds = new Set<Id>();
            for (CaseHistory ch : chList) {
                if (String.valueOf(ch.OldValue) == 'Customer Responded' &&
                    String.valueOf(ch.NewValue) != 'Customer Responded') {
                    doneCRCaseIds.add(ch.CaseId);
                }
            }

            Map<Id, Case> filteredCases = new Map<Id, Case>();
            if (!doneCRCaseIds.isEmpty()) {
                for (Case c : [
                    SELECT Id, CRM_Segments__c, Origin, Is_Email_Critical__c
                    FROM Case
                    WHERE Id IN :doneCRCaseIds
                ]) {
                    Boolean include = false;
                    if (reportName == 'Email + Web' && (c.Origin == '4' || c.Origin == '6')) include = true;
                    else if (reportName == 'MGL Connect' && c.Origin == '10') include = true;
                    else if (reportName == 'Critical Cases' && c.Is_Email_Critical__c) include = true;

                    if (include) filteredCases.put(c.Id, c);
                }
            }
            r.doneCR = filteredCases.size();

            
            r.totalDone = r.doneCategorized + r.doneCR;

            // PENDING
            r.pending = r.opening + r.oldReceived + r.newReceived + r.crReceived - r.totalDone;

            return r;
        }

        // SIMPLE REPORTS (Email FRL, Letter FRL, Letter)
        if (reportName == 'Email FRL') {
            r.opening = [SELECT COUNT() FROM Case WHERE Origin IN ('4','5','6') AND FRL__c = false AND IsClosed = true AND ClosedDate < :today AND Status IN ('Resolved', 'Customer Not Responded')];
            r.received = [SELECT COUNT() FROM Case WHERE Origin IN ('4','5','6') AND Status IN ('Resolved', 'Customer Not Responded') AND IsClosed = true AND ClosedDate = :today];
            r.doneCategorized = [SELECT COUNT() FROM Case WHERE Origin IN ('4','5','6') AND FRL__c = true AND FRL_Sent_Date__c = :today];
            r.totalDone = r.doneCategorized;
            r.pending = r.opening + r.received - r.totalDone;
            return r;
        }

        if (reportName == 'Letter FRL') {
            r.opening = [SELECT COUNT() FROM Case WHERE Origin = '2' AND FRL__c = false AND IsClosed = true AND ClosedDate < :today AND Status IN ('Resolved', 'Customer Not Responded')];
            r.received = [SELECT COUNT() FROM Case WHERE Origin = '2' AND Status IN ('Resolved by CRM', 'Customer Not Responded') AND IsClosed = true AND ClosedDate = :today];
            r.doneCategorized = [SELECT COUNT() FROM Case WHERE Origin = '2' AND FRL__c = true AND FRL_Sent_Date__c = :today];
            r.totalDone = r.doneCategorized;
            r.pending = r.opening + r.received - r.totalDone;
            return r;
        }

        if (reportName == 'Letter') {
            r.opening = [SELECT COUNT() FROM Case WHERE Origin = '17' AND Status = 'Resolved by CRM' AND CreatedDate >= :startYesterday AND CreatedDate < :endYesterday];
            r.received = [SELECT COUNT() FROM Case WHERE Origin = '17' AND CreatedDate >= :startToday AND CreatedDate < :endToday AND Status = 'Resolved by CRM' ];
            r.doneCategorized = [SELECT COUNT() FROM Case WHERE Origin = '2' AND CreatedDate = :today AND CRM_Segments__c = 'Back Office'];
            r.totalDone = r.doneCategorized;
            r.pending = r.opening + r.received - r.totalDone;
            return r;
        }

        return r;
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getReports() {
        return new List<String>{
            'Email + Web',
            'MGL Connect',
            'Critical Cases',
            'Email FRL',
            'Letter FRL',
            'Letter'
        };
    }
    @AuraEnabled(cacheable=true)
public static String getReportIdByName(String reportName) {
    try {
        List<Report> reports = [SELECT Id FROM Report WHERE Name = :reportName LIMIT 1];
        if (!reports.isEmpty()) {
            return reports[0].Id;
        }
        return null;
    } catch (Exception e) {
        System.debug('Error getting report ID: ' + e.getMessage());
        return null;
    }
}
}