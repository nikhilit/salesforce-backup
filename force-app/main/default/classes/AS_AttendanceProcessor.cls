public without sharing class AS_AttendanceProcessor {

    public static void processAttendance() {
        try {
            Date today = Date.today();
			String profileName = System.Label.AS_FieldAgentDomesticProfile;
            
            if(Test.isRunningTest()){
                profileName = 'Standard User';
            }
            
            // Step 0: Get all Users with Profile = "Field Agent Domestic"
            List<User> fieldAgents = [
                SELECT Id, Name, Profile.Name
                  FROM User
                 WHERE Profile.Name = :profileName
                   AND IsActive = TRUE
            ];
            
            if (fieldAgents.isEmpty()) {
                System.debug('No Field Agent Domestic users found.');
                return;
            }

            Set<Id> fieldAgentIds = new Set<Id>();
            for (User u : fieldAgents) fieldAgentIds.add(u.Id);

            // Step 1: Fetch Attendance records for today
            List<Attendance__c> existingAttendances = [
                SELECT Id, User__c, Attendance_Date__c, Status__c,
                       Day_In_Timestamp__c, Day_Out_Timestamp__c,
                       Day_In_Lat__c, Day_In_Long__c, Day_Out_Lat__c, Day_Out_Long__c,
                       Completed_Visits__c
                FROM Attendance__c
                WHERE User__c IN :fieldAgentIds
                AND Attendance_Date__c = :today
            ];

            // Step 2: Separate pending attendances and build user set
            List<Attendance__c> pendingAttendances = new List<Attendance__c>();
            Set<Id> usersWithAttendance = new Set<Id>();

            for (Attendance__c att : existingAttendances) {
                pendingAttendances.add(att);
                usersWithAttendance.add(att.User__c);
            }

            // Step 3: Get ServiceResources for all users
            Map<Id, ServiceResource> userToResourceMap = new Map<Id, ServiceResource>();
            for (ServiceResource sR : [
                SELECT Id, RelatedRecordId
                FROM ServiceResource
                WHERE RelatedRecordId IN :fieldAgentIds
            ]) {
                userToResourceMap.put(sR.RelatedRecordId, sR);
            }

            // Step 4: Get today's WorkOrders for all ServiceResources
            Map<Id, List<WorkOrder>> resourceToWorkOrders = new Map<Id, List<WorkOrder>>();
            for (WorkOrder wo : [
                SELECT Id, Agent__c, Check_In_Date_Time__c, Check_Out_Date_Time__c,
                       Check_In_Location__Latitude__s, Check_In_Location__Longitude__s,
                       Check_Out_Location__Latitude__s, Check_Out_Location__Longitude__s
                FROM WorkOrder
                WHERE Agent__c IN :userToResourceMap.values()
                AND Check_In_Date_Time__c = TODAY
                ORDER BY Check_Out_Date_Time__c DESC NULLS LAST
            ]) {
                if (!resourceToWorkOrders.containsKey(wo.Agent__c)) {
                    resourceToWorkOrders.put(wo.Agent__c, new List<WorkOrder>());
                }
                resourceToWorkOrders.get(wo.Agent__c).add(wo);
            }

            // Step 5: Update Attendance records
            List<Attendance__c> toUpdate = new List<Attendance__c>();

            for (Attendance__c att : pendingAttendances) {
                ServiceResource sr = userToResourceMap.get(att.User__c);
                if (sr == null) continue;

                List<WorkOrder> orders = resourceToWorkOrders.get(sr.Id);
                if (orders != null && !orders.isEmpty()) {
                    WorkOrder latestWO = orders[0];

                    if (att.Day_Out_Timestamp__c == null) {
                        att.Day_Out_Timestamp__c = latestWO.Check_Out_Date_Time__c != null
                            ? latestWO.Check_Out_Date_Time__c
                            : Datetime.now();

                        att.Day_Out_Lat__c  = latestWO.Check_Out_Location__Latitude__s  != null ? latestWO.Check_Out_Location__Latitude__s  : 12.9716;
                        att.Day_Out_Long__c = latestWO.Check_Out_Location__Longitude__s != null ? latestWO.Check_Out_Location__Longitude__s : 77.5946;
                        att.Day_In_Lat__c   = latestWO.Check_In_Location__Latitude__s   != null ? latestWO.Check_In_Location__Latitude__s   : 12.9716;
                        att.Day_In_Long__c  = latestWO.Check_In_Location__Longitude__s  != null ? latestWO.Check_In_Location__Longitude__s  : 77.5946;
                    }

                    att.Status__c = 'Present';
                    att.Completed_Visits__c = orders.size();
                } else {
                    att.Status__c = 'Visit Not Done';
                    att.Completed_Visits__c = 0;
                }

                toUpdate.add(att);
            }

            if (!toUpdate.isEmpty()) {
                update toUpdate;
                System.debug('Updated ' + toUpdate.size() + ' attendance records.');
            }

            // Step 6: Handle Missing Attendance (mark as Absent)
            Set<Id> usersWithoutAttendance = new Set<Id>(fieldAgentIds);
            usersWithoutAttendance.removeAll(usersWithAttendance);

            List<Attendance__c> toInsert = new List<Attendance__c>();

            for (Id userId : usersWithoutAttendance) {
                Attendance__c newAtt = new Attendance__c();
                newAtt.User__c = userId;
                newAtt.Attendance_Date__c = today;
                newAtt.Status__c = 'Absent';
                toInsert.add(newAtt);
            }

            if (!toInsert.isEmpty()) {
                insert toInsert;
                System.debug('Inserted ' + toInsert.size() + ' Absent attendance records.');
            }

        } catch (Exception ex) {
            AS_ErrorLogger.log('AS_AttendanceProcessor', 'processAttendance', ex, '');
        }
    }
}