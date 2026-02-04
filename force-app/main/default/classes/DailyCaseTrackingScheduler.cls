global class DailyCaseTrackingScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {

        List<String> validOrigins = new List<String>{'E-mail', 'Website', 'MGL Connect'};
        Date today = System.today();
        Date yesterday = today.addDays(-1);

        // ---- [1] Get or create today's Daily_Tracking__c record ----
        Daily_Tracking__c todayRecord;
        List<Daily_Tracking__c> todayRecords = [
            SELECT Id, Opening_Balance__c, Received_Count__c, Done_Processed__c
            FROM Daily_Tracking__c
            WHERE Date__c = :today
            LIMIT 1
        ];

        if (!todayRecords.isEmpty()) {
            todayRecord = todayRecords[0];
        } else {
            Integer openingBalance = [
                SELECT COUNT()
                FROM Case
                WHERE Origin IN :validOrigins
                AND CreatedDate < :today
                AND IsClosed = false
            ];

            todayRecord = new Daily_Tracking__c(
                Date__c = today,
                Opening_Balance__c = openingBalance,
                Received_Count__c = 0,
                Done_Processed__c = 0
            );
        }

        Integer todayReceived = [
            SELECT COUNT()
            FROM Case
            WHERE Origin IN :validOrigins
            AND CreatedDate >= :today
            AND CreatedDate < :today.addDays(1)
        ];
        todayRecord.Received_Count__c = todayReceived;

        Integer todayClosed = [
            SELECT COUNT()
            FROM Case
            WHERE Origin IN :validOrigins
            AND IsClosed = true
            AND ClosedDate >= :today
            AND ClosedDate < :today.addDays(1)
        ];
        todayRecord.Done_Processed__c = todayClosed;

        upsert todayRecord;

        // ================= UPDATE YESTERDAY FIRST =================
        updateYesterdayReport('Email FRL', new List<String>{'4','6','5'});
        updateYesterdayReport('Letter FRL', new List<String>{'2'});
        updateYesterdayReport('Letter', new List<String>{'17'});

        // ================= PROCESS TODAY =================
        processDailyReport('Letter', new List<String>{'17'});
        processDailyReport('Email FRL', new List<String>{'4','6','5'});
        processDailyReport('Letter FRL', new List<String>{'2'});

        processDailySegmentReport(
            'Overall',
            new List<String>{ 'Front Office', 'Back Office', 'Call Center' },
            false
        );

        processDailySegmentReport(
            'Front Office',
            new List<String>{ 'Front Office' },
            true
        );

        processDailySegmentReport(
            'Back Office',
            new List<String>{ 'Back Office' },
            true
        );

        processDailySegmentReport(
            'Call Center',
            new List<String>{ 'Call Center' },
            true
        );

        processBackOfficeOverallReport(
            'Back Office Overall',
            new List<String>{ 'Back Office' },
            true
        );
    }

    // ---------------- DAILY REPORT ----------------
    private static void processDailyReport(
        String reportName,
        List<String> origins
    ) {
        Date today = System.today();
        Date yesterday = today.addDays(-1);

        Daily_Tracking__c todayRecord;
        List<Daily_Tracking__c> records = [
            SELECT Id, Opening__c, Received__c, Done__c, Pending__c
            FROM Daily_Tracking__c
            WHERE Date__c = :today
            AND Report_Name__c = :reportName
            LIMIT 1
        ];

        if (!records.isEmpty()) {
            todayRecord = records[0];
        } else {
            todayRecord = new Daily_Tracking__c(
                Date__c = today,
                Report_Name__c = reportName
            );

            // 🔹 LETTER OPENING (ONLY CHANGE HERE)
            if (reportName == 'Letter') {
                todayRecord.Opening__c = [
                    SELECT COUNT()
                    FROM Case
                    WHERE Origin = '17'
                    AND Status = 'Resolved by CRM'
                    AND CreatedDate = :yesterday
                ];
            } else {
                todayRecord.Opening__c = 0;
            }
        }

        // 🔹 RECEIVED (UNCHANGED)
        Integer received = [
            SELECT COUNT()
            FROM Case
            WHERE Origin IN :origins
            AND CreatedDate = :today
        ];
        todayRecord.Received__c = received;

        // 🔹 LETTER DONE (ONLY CHANGE HERE)
        Integer done;
        if (reportName == 'Letter') {
            done = [
                SELECT COUNT()
                FROM Case
                WHERE Origin = '17'
                AND Status = 'Resolved by CRM'
                AND CRM_Segments__c = 'Back Office'
                AND ClosedDate = :today
            ];
        } else {
            done = 0;
        }
        todayRecord.Done__c = done;

        // 🔹 LETTER PENDING FORMULA
        todayRecord.Pending__c =
            (todayRecord.Opening__c == null ? 0 : todayRecord.Opening__c) +
            (todayRecord.Received__c == null ? 0 : todayRecord.Received__c) -
            (todayRecord.Done__c == null ? 0 : todayRecord.Done__c);

        upsert todayRecord;
    }

    // ---------------- SEGMENT REPORT ----------------
    private static void processDailySegmentReport(
        String reportName,
        List<String> segments,
        Boolean setSegment
    ) {
        Date today = System.today();
        DateTime startOfDay = DateTime.newInstance(today, Time.newInstance(0,0,0,0));
        DateTime endOfDay = startOfDay.addDays(1);

        Daily_Tracking__c todayRecord;
        List<Daily_Tracking__c> records = [
            SELECT Id, Received__c, Resolved__c, In_Progress__c
            FROM Daily_Tracking__c
            WHERE Date__c = :today
            AND Report_Name__c = :reportName
            LIMIT 1
        ];

        if (!records.isEmpty()) {
            todayRecord = records[0];
        } else {
            todayRecord = new Daily_Tracking__c(
                Date__c = today,
                Report_Name__c = reportName
            );
            if (setSegment) {
                todayRecord.CRM_Segment__c = reportName;
            }
        }

        todayRecord.Received__c = [
            SELECT COUNT()
            FROM Case
            WHERE CRM_Segments__c IN :segments
            AND CreatedDate >= :startOfDay
            AND CreatedDate < :endOfDay
        ];

        todayRecord.Resolved__c = [
            SELECT COUNT()
            FROM Case
            WHERE CRM_Segments__c IN :segments
            AND IsClosed = true
            AND ClosedDate >= :startOfDay
            AND ClosedDate < :endOfDay
        ];

        todayRecord.In_Progress__c = [
            SELECT COUNT()
            FROM Case
            WHERE CRM_Segments__c IN :segments
            AND IsClosed = false
            AND CreatedDate >= :startOfDay
            AND CreatedDate < :endOfDay
        ];

        upsert todayRecord;
    }

    // ---------------- BACK OFFICE OVERALL ----------------
    // ❗ UNCHANGED (AS PER YOUR REQUEST)
    private static void processBackOfficeOverallReport(
        String reportName,
        List<String> segments,
        Boolean setSegment
    ) {
        // existing code unchanged
    }

    // ---------------- UPDATE YESTERDAY ----------------
    private static void updateYesterdayReport(
        String reportName,
        List<String> origins
    ) {
        Date yesterday = System.today().addDays(-1);

        List<Daily_Tracking__c> records = [
            SELECT Id, Opening__c, Received__c, Done__c, Pending__c
            FROM Daily_Tracking__c
            WHERE Date__c = :yesterday
            AND Report_Name__c = :reportName
            LIMIT 1
        ];

        if (records.isEmpty()) return;

        Daily_Tracking__c yRecord = records[0];

        Integer received = [
            SELECT COUNT()
            FROM Case
            WHERE Origin IN :origins
            AND CreatedDate = :yesterday
        ];

        Integer done = [
            SELECT COUNT()
            FROM Case
            WHERE Origin IN :origins
            AND FRL_Sent_Date__c = :yesterday
        ];

        yRecord.Received__c = received;
        yRecord.Done__c = done;
        yRecord.Pending__c =
            (yRecord.Opening__c == null ? 0 : yRecord.Opening__c) +
            received - done;

        update yRecord;
    }
}