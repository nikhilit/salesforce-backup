/**
 * @description       : 
 * @author            : Shashank.shekhar@appstrail.com
 * @group             : 
 * @last modified on  : 05-15-2025
 * @last modified by  : Shashank.shekhar@appstrail.com
**/
public without sharing class AttendanceController {

    @AuraEnabled(cacheable=false)
    public static AttendanceWrapper getTodayAttendance() {
        Id userId = UserInfo.getUserId();

        Date today = Date.today();
        System.debug('Fetching today\'s attendance for user: ' + userId + ' on date: ' + today);

        List<Attendance__c> records = [
            SELECT Id, Status__c, Day_In_Timestamp__c, Day_Out_Timestamp__c, Attendance_Locked__c
            FROM Attendance__c
            WHERE User__c = :userId AND Attendance_Date__c = :today
            LIMIT 1
        ];

        if (records.isEmpty()) {
            System.debug('No attendance record found for today.');
            return new AttendanceWrapper(null, false);
        }

        Attendance__c att = records[0];
        Boolean canView = att.Status__c == 'Present' && att.Day_In_Timestamp__c != null && att.Day_Out_Timestamp__c == null;
        System.debug('Attendance record found: ' + att + ', canViewVisits: ' + canView);
        return new AttendanceWrapper(att, canView);
    }

    @AuraEnabled
    public static String markAttendance(String status, Decimal lat, Decimal lon, String leaveReason) {
    Id userId = UserInfo.getUserId();
    Date today = Date.today();

    // Check for existing attendance
    List<Attendance__c> existing = [
        SELECT Id FROM Attendance__c
        WHERE User__c = :userId AND Attendance_Date__c = :today
        LIMIT 1
    ];

    if (!existing.isEmpty()) {
        System.debug('Attendance already marked for today.');
        return 'ALREADY_MARKED';
    }

    // Create new attendance record
    Attendance__c newAttendance = new Attendance__c();
    newAttendance.User__c = userId;
    newAttendance.Attendance_Date__c = today;
    newAttendance.Status__c = status;

	if (status == 'Present') {
        newAttendance.Day_In_Timestamp__c = System.now();
        newAttendance.Day_In_Lat__c = lat;
        newAttendance.Day_In_Long__c = lon;
    }else if (status == 'On Leave') {
        // Assuming you have a field to save leave reason on Attendance__c or you want to save it only in ResourceAbsence
        // If Attendance__c has a field for reason, e.g. Leave_Reason__c, you can save here:
        newAttendance.Reason__c = leaveReason;
    }

    insert newAttendance;
    System.debug('Inserted new Attendance__c record: ' + newAttendance);
        
     if (status == 'On Leave') {
        createAbsenceRecord(leaveReason);
    }

    return 'SUCCESS';
}


    @AuraEnabled
    public static void markDayOut(Decimal lat, Decimal lon) {
        Id userId = UserInfo.getUserId();
        Date today = Date.today();
        System.debug('Marking Day-Out for user: ' + userId + ', lat: ' + lat + ', lon: ' + lon);

        List<Attendance__c> updateAttendance = [
            SELECT Id, Status__c, Attendance_Locked__c, Day_Out_Long__c, Day_Out_Lat__c, Day_Out_Timestamp__c
            FROM Attendance__c
            WHERE User__c = :userId AND Attendance_Date__c = :today
        ];

        if (updateAttendance.isEmpty()) {
            System.debug('No attendance record found for Day-Out.');
            return;
        }

        Attendance__c record = updateAttendance[0];
        System.debug('Attendance record before update: ' + record);

        record.Day_Out_Timestamp__c = System.now();
        record.Day_Out_Lat__c = lat;
        record.Day_Out_Long__c = lon;

        update record;
        System.debug('Updated Day-Out details for Attendance__c: ' + record);
    }

    @AuraEnabled
    public static void createAbsenceRecord(String leaveReason) {
        System.debug('Creating ResourceAbsence record...');

        ServiceResource sr = [
            SELECT Id FROM ServiceResource 
            WHERE RelatedRecordId = :UserInfo.getUserId() 
            LIMIT 1
        ];
        System.debug('Found ServiceResource: ' + sr.Id);

        ResourceAbsence absence = new ResourceAbsence();
        absence.ResourceId = sr.Id;
        absence.Start = System.now();
        absence.End = System.now().addHours(8);
        absence.Description = 'Marked On Leave via Attendance Component. Reason: ' + leaveReason;

        insert absence;
        System.debug('Inserted ResourceAbsence: ' + absence);
    }

    public class AttendanceWrapper {
        @AuraEnabled public Attendance__c attendance;
        @AuraEnabled public Boolean canViewVisits;

        public AttendanceWrapper(Attendance__c att, Boolean canView) {
            this.attendance = att;
            this.canViewVisits = canView;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<PicklistOption> getStatusOptions() {
        List<PicklistOption> options = new List<PicklistOption>();
        // Describe the field
        Schema.DescribeFieldResult fieldResult = Attendance__c.Status__c.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();

        // Convert to custom wrapper for LWC
        for (Schema.PicklistEntry entry : picklistValues) {
            options.add(new PicklistOption(entry.getValue(), entry.getLabel()));
        }
        return options;
    }

    public class PicklistOption {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }

        public PicklistOption(String value, String label) {
            this.label = label;
            this.value = value;
        }
    }



/*@AuraEnabled(cacheable=true)
public static List<ServiceAppointment> getAssignedServiceAppointments() {
    // Get the ServiceResource linked to the current user
    ServiceResource sr = [
        SELECT Id
        FROM ServiceResource
        WHERE RelatedRecordId = :UserInfo.getUserId()
        LIMIT 1
    ];

    // Fetch today's appointments through the AssignedResource junction object
    List<AssignedResource> assignedResources = [
        SELECT ServiceAppointment.Id,
               ServiceAppointment.Subject,
               ServiceAppointment.Status,
               ServiceAppointment.SchedStartTime,
               ServiceAppointment.SchedEndTime,
               ServiceAppointment.Check_In_Location__c,
               ServiceAppointment.Check_Out_Location__c,
               ServiceAppointment.Description,
               ServiceAppointment.AppointmentNumber
        FROM AssignedResource
        WHERE ServiceResourceId = :sr.Id
        AND ServiceAppointment.SchedStartTime = TODAY
        ORDER BY ServiceAppointment.SchedStartTime ASC
    ];

    // Extract the ServiceAppointment records
    List<ServiceAppointment> appointments = new List<ServiceAppointment>();
    for (AssignedResource ar : assignedResources) {
        if (ar.ServiceAppointment != null) {
            appointments.add(ar.ServiceAppointment);
        }
    }

    return appointments;
}*/


}