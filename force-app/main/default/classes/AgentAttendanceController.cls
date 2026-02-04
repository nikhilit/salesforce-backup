public with sharing class AgentAttendanceController {
    @AuraEnabled
    public static String getCurrentUserName() {
        try {
            return [SELECT Name FROM User WHERE Id = :UserInfo.getUserId()].Name;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching user name: ' + e.getMessage());
        }
    }
@AuraEnabled
    public static void triggerScheduledJob() {
        (new DailyCaseTrackingScheduler()).execute(null);
    }
    @AuraEnabled
    public static void caseSynctoSAP() {
        Database.executeBatch(new CaseSAPBatch(), 200);
    }
    @AuraEnabled
    public static Map<String, Object> getTodayAttendanceWithUserType() {
        try {
            Id userId = UserInfo.getUserId();
            User user = [SELECT Type_Of_Work__c FROM User WHERE Id = :userId];
            
            List<Attendance__c> records = [
                SELECT Id, Block__c, Work_Type_Location__c, Day_In_Timestamp__c, Day_Out_Timestamp__c,Sub_Function__c
                FROM Attendance__c
                WHERE User__c = :userId AND CreatedDate = TODAY
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];

            // For display purposes, combine Block__c and Work_Type_Location__c
            if (!records.isEmpty()) {
                records[0].Block__c = records[0].Work_Type_Location__c != null ? 
                records[0].Work_Type_Location__c : records[0].Block__c;
            }

            return new Map<String, Object>{
                'record' => records.isEmpty() ? null : records[0],
                'typeOfWork' => user.Type_Of_Work__c
            };
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching attendance: ' + e.getMessage());
        }
    }
    // Add this method to get Sub Function picklist values
@AuraEnabled
public static List<String> getSubFunctionOptions() {
    try {
        List<String> options = new List<String>();
        Schema.DescribeFieldResult fieldResult = Attendance__c.Sub_Function__c.getDescribe();
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            if (entry.isActive()) {
                options.add(entry.getLabel());
            }
        }
        return options;
    } catch (Exception e) {
        throw new AuraHandledException('Error fetching sub function options: ' + e.getMessage());
    }
}

    @AuraEnabled
    public static Map<String, Object> getUserBlockAccessInfo() {
        try {
            User user = [SELECT Type_Of_Work__c FROM User WHERE Id = :UserInfo.getUserId()];
            String type = user.Type_Of_Work__c;
            
            List<String> blockOptions = new List<String>();
            String defaultBlock = '';
            
            if (type == 'Back Office') {
                defaultBlock = 'Back Office';
                blockOptions.add(defaultBlock);
            } 
            else if (type == 'Call Center') {
                defaultBlock = 'Call Center';
                blockOptions.add(defaultBlock);
            }
            else if (type == 'Front Office') {
                Schema.DescribeFieldResult fieldResult = Attendance__c.Block__c.getDescribe();
                for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
                    if (entry.isActive()) {
                        blockOptions.add(entry.getLabel());
                    }
                }
            }

            return new Map<String, Object>{
                'typeOfWork' => type,
                'defaultBlock' => defaultBlock,
                'blockOptions' => blockOptions
            };
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching user info: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void handleAttendance(
        String actionType,
        String block,
        String timestamp,
        String subFunction // Add this parameter
    ) {
        try {
            Id userId = UserInfo.getUserId();
            User user = [SELECT Type_Of_Work__c,Sub_Function__c FROM User WHERE Id = :userId];
            String type = user.Type_Of_Work__c;

             if (!String.isBlank(subFunction) && user.Sub_Function__c != subFunction) {
            user.Sub_Function__c = subFunction;
            update user;
        }

            if (actionType == 'Check-In') {
                // Create new attendance record
                Attendance__c newRecord = new Attendance__c(
                    User__c = userId,
                    Day_In_Timestamp__c = System.now(),
                    Day_Out_Timestamp__c = null,
                    Sub_Function__c = subFunction // Add this field
                );

                // Handle location differently based on user type
                if (type == 'Front Office') {
                    if (String.isBlank(block)) {
                        throw new AuraHandledException('Location is required for Front Office');
                    }
                    newRecord.Block__c = block;
                } else if (type == 'Back Office' || type == 'Call Center') {
                    newRecord.Work_Type_Location__c = type; // Store in a separate field
                    // Block__c remains null for these users
                     newRecord.Block__c = 'MGL '+block;
                }
                
                insert newRecord;
            } 
           else if (actionType == 'Check-Out') {
    // Find most recent check-in without check-out
    List<Attendance__c> records = [
        SELECT Id FROM Attendance__c 
        WHERE User__c = :userId 
        AND Day_Out_Timestamp__c = null
        ORDER BY Day_In_Timestamp__c DESC 
        LIMIT 1
    ];

    if (records.isEmpty()) {
        throw new AuraHandledException('No active check-in found to check out');
    }

    Attendance__c record = records[0];
    record.Day_Out_Timestamp__c = System.now();

    // Find any ongoing break (without end time) for this attendance
    List<Break__c> ongoingBreaks = [
        SELECT Id FROM Break__c 
        WHERE Attendance__c = :record.Id AND Break_End_Time__c = null
        LIMIT 1
    ];

    List<SObject> toUpdate = new List<SObject>{ record };

    if (!ongoingBreaks.isEmpty()) {
        Break__c breakRecord = ongoingBreaks[0];
        breakRecord.Break_End_Time__c = System.now();
        toUpdate.add(breakRecord);
    }

    update toUpdate;
}

            else {
                throw new AuraHandledException('Invalid action type: ' + actionType);
            }
        }catch (Exception e) {
    throw new AuraHandledException('Attendance processing failed: ' + (e != null && e.getMessage() != null ? e.getMessage() : 'Unknown error'));
}
    }
@AuraEnabled
public static Break__c getOngoingBreak() {
    try {
        Id userId = UserInfo.getUserId();

        // Get active attendance for today
        List<Attendance__c> attendanceList = [
            SELECT Id FROM Attendance__c
            WHERE User__c = :userId AND Day_Out_Timestamp__c = null AND CreatedDate = TODAY ORDER BY Createddate DESC
            LIMIT 1
        ];

        if (attendanceList.isEmpty()) {
            return null; // No attendance found
        }

        Id attendanceId = attendanceList[0].Id;

        // Check for break record without end time
        List<Break__c> ongoingBreaks = [
            SELECT Id, Break_Codes__c, Break_Start_Time__c
            FROM Break__c
            WHERE Attendance__c = :attendanceId AND Break_End_Time__c = null
            LIMIT 1
        ];

        return ongoingBreaks.isEmpty() ? null : ongoingBreaks[0];
    } catch (Exception e) {
        throw new AuraHandledException('Error fetching ongoing break: ' + e.getMessage());
    }
}


@AuraEnabled
public static void endBreak() {
    try {
        Break__c brk = [SELECT Id FROM Break__c WHERE Break_End_Time__c=null AND CreatedDate=today Order BY CreatedDate desc LIMIT 1];
        brk.Break_End_Time__c = System.now();
        update brk;
    } catch (Exception e) {
        throw new AuraHandledException('Error ending break: ' + e.getMessage());
    }
}

    @AuraEnabled
    public static Id createBreakRecord(String reason) {
        try {
            Id userId = UserInfo.getUserId();

            // Find active attendance
            Attendance__c attendance = [
                SELECT Id FROM Attendance__c
                WHERE User__c = :userId AND Day_Out_Timestamp__c = null AND CreatedDate=TODAY Order BY CreatedDate desc
                LIMIT 1
            ];

            Break__c brk = new Break__c(
                Attendance__c = attendance.Id,
                Break_Start_Time__c = System.now(),
                Break_Codes__c = reason
            );
            insert brk;
            return brk.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error starting break: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void endBreakRecord(String timestamp,String attendanceId) {
        try {
            Id userId = UserInfo.getUserId();
            DateTime endTime = DateTime.valueOf(timestamp.replace('T', ' '));

            // Find most recent break with no end
            Break__c openBreak = [
                SELECT Id, Break_Start_Time__c FROM Break__c
                WHERE Attendance__c = :attendanceId AND Break_End_Time__c = null
                ORDER BY Break_Start_Time__c DESC
                LIMIT 1
            ];

            openBreak.Break_End_Time__c	 = endTime;
            update openBreak;

            // Optional: update attendance break flag
            List<Attendance__c> activeAttendance = [
                SELECT Id FROM Attendance__c
                WHERE User__c = :userId AND Day_Out_Timestamp__c = null
                ORDER BY Day_In_Timestamp__c DESC
                LIMIT 1
            ];

        } catch (Exception e) {
            throw new AuraHandledException('Error ending break: ' + e.getMessage());
        }
    }

   @AuraEnabled
public static List<String> getBreakReasons() {
    try {
        List<String> breakReasonList = new List<String>();

        // Get picklist values for Break_Codes__c field
        Schema.DescribeFieldResult fieldResult = Break__c.Break_Codes__c.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();

        for (Schema.PicklistEntry entry : picklistValues) {
            breakReasonList.add(entry.getLabel());
        }

        return breakReasonList;
    } catch (Exception e) {
        throw new AuraHandledException('Error fetching break reasons: ' + e.getMessage());
    }
}
// In AgentAttendanceController.cls
@AuraEnabled(cacheable=true)
public static String getUserProfileName() {
    return [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1].Name;
}
@AuraEnabled(cacheable=true)
public static String getAttendanceStatus() {
    try {
        Id userId = UserInfo.getUserId();

        // Check if the user has an active attendance (checked in but not out)
        List<Attendance__c> attendanceList = [
            SELECT Id
            FROM Attendance__c
            WHERE User__c = :userId AND Day_Out_Timestamp__c = null AND CreatedDate = TODAY
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        if (attendanceList.isEmpty()) {
            return 'Checked Out';
        }

        Id attendanceId = attendanceList[0].Id;

        // Check if the user is on a break (i.e., there's a break with no end time)
        List<Break__c> ongoingBreak = [
            SELECT Id
            FROM Break__c
            WHERE Attendance__c = :attendanceId AND Break_End_Time__c = null
            LIMIT 1
        ];

        if (!ongoingBreak.isEmpty()) {
            return 'On Break';
        }

        return 'Checked In'; // Valid to submit
    } catch (Exception e) {
        throw new AuraHandledException('Error checking attendance status: ' + e.getMessage());
    }
}

}