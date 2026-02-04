global class DailyEscalationSpocScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {

        DateTime nowDt = System.now();
        DateTime last24Hrs = nowDt.addHours(-24);

        /* ================= STEP 1: FETCH BREACHED CASES ================= */
        List<Case> cases = [
            SELECT Id, Docket_Number__c, Department__c, Status,
                   AccountId, QRC_Process__c,SPOC__r.name,
                   Case_Violation__c, Case_Violation1__c,
                   Case_Violation2__c, Case_Violation3__c,
                   Case_Violation_Time_1__c, Case_Violation_Time_2__c,
                   Case_Violation_Time_3__c, Case_Violation_Time_4__c
            FROM Case
            WHERE IsClosed = false
            AND Created_Date_OLd__c = null
            AND Department__c = 'BIS'
            AND (
                (Case_Violation__c  = true AND Case_Violation_Time_1__c >= :last24Hrs)
            )
        ];

        if (cases.isEmpty()) return;

        /* ================= STEP 2: ACCOUNTS ================= */
        Set<Id> accIds = new Set<Id>();
        Set<Id> qrcIds = new Set<Id>();

        for (Case c : cases) {
            if (c.AccountId != null) accIds.add(c.AccountId);
            if (c.QRC_Process__c != null) qrcIds.add(c.QRC_Process__c);
        }

        Map<Id, Account> accMap = new Map<Id, Account>(
            [SELECT Id, DRS_Master__c FROM Account WHERE Id IN :accIds]
        );

        Set<Id> drsIds = new Set<Id>();
        for (Account a : accMap.values()) {
            if (a.DRS_Master__c != null) drsIds.add(a.DRS_Master__c);
        }

        /* ================= STEP 3: SPOC MAPPINGS ================= */
        Map<String, Departments_SPOC_Mapping__c> mappingMap = new Map<String, Departments_SPOC_Mapping__c>();

        for (Departments_SPOC_Mapping__c m : [
            SELECT Department__c, DRS__c, QRC_Process__c,
                   SPOC_Id_2__c, SPOC_Id_3__c, SPOC_Id_4__c
            FROM Departments_SPOC_Mapping__c
            WHERE Department__c = 'BIS'
            AND DRS__c IN :drsIds
            AND QRC_Process__c IN :qrcIds
        ]) {
            String key = (
                m.Department__c.replaceAll('\\s+', '') + '-' +
                String.valueOf(m.DRS__c) + '-' +
                String.valueOf(m.QRC_Process__c)
            ).toLowerCase();

            mappingMap.put(key, m);
        }

        /* ================= STEP 4: GROUP CASES BY ESCALATION SPOC ================= */
        Map<Id, List<Case>> spocToCases = new Map<Id, List<Case>>();
        Map<Id, Integer> spocToLevel = new Map<Id, Integer>();

        for (Case c : cases) {

            Account acc = accMap.get(c.AccountId);
            if (acc == null || acc.DRS_Master__c == null) continue;

            String key = (
                c.Department__c.replaceAll('\\s+', '') + '-' +
                String.valueOf(acc.DRS_Master__c) + '-' +
                String.valueOf(c.QRC_Process__c)
            ).toLowerCase();

            Departments_SPOC_Mapping__c m = mappingMap.get(key);
            if (m == null) continue;

            Id spocId;
            Integer level;

            
    
                spocId = m.SPOC_Id_2__c;
                level = 1;
           

            if (spocId == null) continue;

            if (!spocToCases.containsKey(spocId)) {
                spocToCases.put(spocId, new List<Case>());
            }

            spocToCases.get(spocId).add(c);
            spocToLevel.put(spocId, level);
        }

        if (spocToCases.isEmpty()) return;

        /* ================= STEP 5: USERS ================= */
        Map<Id, User> users = new Map<Id, User>(
            [SELECT Id, Name, Email FROM User WHERE Id IN :spocToCases.keySet()]
        );

        OrgWideEmailAddress owea = [
            SELECT Id FROM OrgWideEmailAddress
            WHERE Address = :System.Label.Escalation_Email_From_Address
            LIMIT 1
        ];

        /* ================= STEP 6: SEND EMAILS ================= */
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (Id spocId : spocToCases.keySet()) {

            User u = users.get(spocId);
            if (u == null || String.isBlank(u.Email)) continue;

            Integer level = spocToLevel.get(spocId);

            String body =
                'Hello ' + u.Name + ',<br/><br/>' +
                'This is a Level ' + level +
                ' escalation for cases that have breached their TAT in the last 24 hours and are currently pending resolution.<br/><br/>' +

                '<b>Summary:</b><br/>' +
                'Total Cases Breached: ' + spocToCases.get(spocId).size() + '<br/>' +
                'Date Range: ' +
                last24Hrs.format('dd/MM/yyyy hh:mm a') + ' – ' +
                nowDt.format('dd/MM/yyyy hh:mm a') + '<br/><br/>' +

                '<b>Details:</b><br/>' +
                '<table border="1" cellpadding="5">' +
                '<tr><th>Case Number</th><th>Responsible Person</th></tr>';

            for (Case c : spocToCases.get(spocId)) {
                body +=
                    '<tr><td>' + c.Docket_Number__c +
                    '</td><td>' + c.SPOC__r.name + '</td></tr>';
            }

            body +=
                '</table><br/><br/>' +
                '<b>Action Required:</b><br/>' +
                'Kindly review these cases and ensure timely resolution by the respective teams to avoid further escalation.<br/><br/>' +
                'Regards,<br/><b>MGL - CRM</b>';

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setOrgWideEmailAddressId(owea.Id);
            mail.setToAddresses(new String[]{u.Email});
            mail.setSubject(
                'Level ' + level + ' Escalation: TAT-Breached Cases (Last 24 Hours)'
            );
            mail.setHtmlBody(body);

            emails.add(mail);
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }
}