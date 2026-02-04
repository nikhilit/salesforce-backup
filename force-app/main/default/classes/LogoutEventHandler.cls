public class LogoutEventHandler {
    public static void handle(List<LogoutEventStream> events) {
        if (events == null || events.isEmpty()) return;

        // Step 1: Collect user IDs & logout times
        Set<Id> userIds = new Set<Id>();
        Map<Id, Datetime> userIdToLogoutTime = new Map<Id, Datetime>();

        for (LogoutEventStream event : events) {
            if (event.UserId != null) {
                userIds.add(event.UserId);
                userIdToLogoutTime.put(event.UserId, event.EventDate);
            }
        }
        if (userIds.isEmpty()) return;

        // Step 2: Query latest open attendance per user
        Map<Id, Attendance__c> userToAttendanceMap = new Map<Id, Attendance__c>();
        List<Attendance__c> attendanceList = [
            SELECT Id, User__c, Day_In_Timestamp__c
            FROM Attendance__c
            WHERE User__c IN :userIds AND Day_Out_Timestamp__c = NULL
            ORDER BY Day_In_Timestamp__c DESC
        ];
        for (Attendance__c att : attendanceList) {
            if (!userToAttendanceMap.containsKey(att.User__c)) {
                userToAttendanceMap.put(att.User__c, att);
            }
        }

        // Step 3: Query open breaks for these attendances
        Map<Id, Break__c> attendanceIdToOpenBreakMap = new Map<Id, Break__c>();
        if (!userToAttendanceMap.isEmpty()) {
            List<Break__c> openBreaks = [
                SELECT Id, Attendance__c
                FROM Break__c
                WHERE Attendance__c IN :userToAttendanceMap.values()
                AND Break_End_Time__c = NULL
            ];
            for (Break__c b : openBreaks) {
                attendanceIdToOpenBreakMap.put(b.Attendance__c, b);
            }
        }

        // Step 4: Prepare records to update
        List<SObject> toUpdate = new List<SObject>();
        for (Id userId : userIds) {
            if (!userToAttendanceMap.containsKey(userId)) continue;

            Attendance__c attendance = userToAttendanceMap.get(userId);
            Datetime logoutTime = userIdToLogoutTime.get(userId);
            attendance.Day_Out_Timestamp__c = logoutTime;
            toUpdate.add(attendance);

            if (attendanceIdToOpenBreakMap.containsKey(attendance.Id)) {
                Break__c breakRecord = attendanceIdToOpenBreakMap.get(attendance.Id);
                breakRecord.Break_End_Time__c = logoutTime;
                toUpdate.add(breakRecord);
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
}