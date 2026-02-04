/**
 * @description       : 
 * @author            : Shashank.shekhar@appstrail.com
 * @group             : 
 * @last modified on  : 06-26-2025
 * @last modified by  : Shashank.shekhar@appstrail.com
**/
public without sharing class RtAppointmentListViewController {

    public static Map<Id, WorkOrder> mapWorkOrder = new Map<Id, WorkOrder>();
      
    @AuraEnabled
    public static List<Object> getAppointmentsByStatus(String status, String type) {
        try{

            System.debug('status: '+status);
            System.debug('type: '+type);

            Id userId = UserInfo.getUserId();
            Date todayDate = Date.today();

            //userId = '005fs0000001mvSAAQ'; // Abhi
            //userId = '005fs00000099vJAAQ'; // testAgent1

            String gsRecordTypeID = Schema.getGlobalDescribe().get('WorkOrder')
                .getDescribe()
                .getRecordTypeInfosByDeveloperName()
                .get('MGL_R_T')
                .getRecordTypeId();

            // Define Sets
            Set<String> completedStatuses = new Set<String>{'Completed'};
            Set<String> incompleteStatuses = new Set<String>{'Cannot Complete'};
            Set<String> unattemptedStatuses = new Set<String>{'None','Scheduled','In Progress','Dispatched'};
            Set<String> totalStatuses = new Set<String>{'Canceled','Completed','Cannot Complete','In Progress','Dispatched','Scheduled','None'};
            Set<String> allStatuses = totalStatuses.clone();

            // Normalize status
            String normalizedStatus = String.isNotBlank(status) ? status.trim().toLowerCase() : '';
            Set<String> targetStatuses = new Set<String>();
            if(normalizedStatus == 'completed') targetStatuses = completedStatuses;
            else if(normalizedStatus == 'incomplete') targetStatuses = incompleteStatuses;
            else if(normalizedStatus == 'unattempted') targetStatuses = unattemptedStatuses;
            else if(normalizedStatus == 'total') targetStatuses = totalStatuses;
            else targetStatuses = allStatuses;

            Id serviceResourceId = [SELECT Id FROM ServiceResource WHERE RelatedRecordId = :userId LIMIT 1].Id;

            Set<Id> assignedAppointmentIds = new Set<Id>();
            for(AssignedResource ar : [SELECT ServiceAppointmentId FROM AssignedResource WHERE ServiceResourceId = :serviceResourceId]){
                assignedAppointmentIds.add(ar.ServiceAppointmentId);
            }

            type = (type == null) ? 'Scheduled' : type;

            Map<Id, WorkOrder> mapWorkOrder = new Map<Id, WorkOrder>([
                SELECT Id, Building_Name__c, New_Flat__c, New_Floor__c, New_Wing__c, New_Plot__c,
                    New_Road_Name__c, New_Landmark__c, New_Colony__c, New_Location__c, City__c,
                    DISTRICT__c, New_Mobile_Number__c, Email_ID__c, Follow_up_Date__c, Status,
                    Customer_BP_Number__c, CA_Number__c, Customer_Name__c, Follow_up_Remarks__c,
                    Payment_Mode__c
                FROM WorkOrder
               WHERE Id IN (
                    SELECT ParentRecordId 
                    FROM ServiceAppointment
                    WHERE Id IN :assignedAppointmentIds
                    AND Status IN :targetStatuses
                    AND ParentRecord.RecordTypeId = :gsRecordTypeID
                )
            ]);

            // Build SOQL query for appointments
            String query = 'SELECT Id, Status, Subject, SchedEndTime, Visit_Status__c, Due_Amount__c, AccountId, ParentRecordId,' +
                ' Account.BP_Number__c, Account.DRS__c, Account.MRU_Code__c, Account.CA_Number__c, Account.Room__c,' +
                ' Account.Name, Account.Building_Name__c, Account.Street__c, Account.Colony__c, Follow_Up_Visit_Date__c,' +
                ' Account.Wing__c, Account.Floor__c, Account.Flat__c, Meter_Number__c, Appointment_Type__c,' +
                ' Account.Street_Line_3__c, Account.Road_name__c, Account.Location__c, Account.Other_City__c,' +
                ' Account.Street_Line_5__c, Account.Street_Line_2__c, Random_Visit_Date__c' +
                ' FROM ServiceAppointment WHERE Id IN :assignedAppointmentIds AND Status IN :targetStatuses' +
                ' AND ParentRecord.RecordTypeId = :gsRecordTypeID AND Follow_Up_Visit_Date__c = null' +
                ' AND DisplaySpecificRangeVisits__c = true';
 
            if(normalizedStatus != 'total' && type == 'Follow Up'){
                query += ' AND Appointment_Type__c = \'Follow Up\'';
            } else if(normalizedStatus != 'total' && type == 'Random'){
                query += ' AND (Appointment_Type__c = \'Random\' OR Random_Visit_Date__c != null)';
            } else if(normalizedStatus != 'total' && type != 'Follow Up'){
                query += ' AND (Appointment_Type__c != \'Follow Up\' OR Appointment_Type__c = null) AND Random_Visit_Date__c = null';
            } else{
                query += ' AND Random_Visit_Date__c = null';
            }

            query += ' ORDER BY Due_Amount__c DESC NULLS LAST';

            List<ServiceAppointment> appointments = Database.query(query);

            // ⚡ Branch: Follow-Up appointments
            if(type == 'Follow Up'){
                Map<String, List<ServiceAppointmentWrapper>> followUpMap = new Map<String, List<ServiceAppointmentWrapper>>();

                for(ServiceAppointment sa : appointments){
                    WorkOrder wo = mapWorkOrder.get(sa.ParentRecordId);
                    String remark = (wo != null && String.isNotBlank(wo.Follow_up_Remarks__c)) ? wo.Follow_up_Remarks__c : 'No Remarks';

                    if(!followUpMap.containsKey(remark)){
                        followUpMap.put(remark, new List<ServiceAppointmentWrapper>());
                    }
                    followUpMap.get(remark).add(new ServiceAppointmentWrapper(sa, wo));
                }

                List<Object> followUpGroups = new List<Object>();
                for(String remark : followUpMap.keySet()){
                    LocationGroup lg = new LocationGroup();
                    lg.name = remark;
                    lg.roads = new List<RoadGroup>();

                    RoadGroup rg = new RoadGroup();
                    rg.name = 'Follow Ups';
                    rg.buildings = new List<BuildingGroup>();

                    BuildingGroup bg = new BuildingGroup();
                    bg.name = remark;
                    bg.appointments = followUpMap.get(remark);
                    bg.statusCounts = new List<RTDashboardController.DataWrapper>();
                    bg.count = bg.appointments.size();

                    rg.buildings.add(bg);
                    rg.count = bg.appointments.size();

                    lg.roads.add(rg);
                    lg.count = bg.appointments.size();

                    followUpGroups.add(lg);
                }
                return followUpGroups;
            }

            // ⚡ Branch: Normal appointments (Location → Road → Building)
            Map<String, Map<String, Map<String, List<ServiceAppointmentWrapper>>>> locationMap = new Map<String, Map<String, Map<String, List<ServiceAppointmentWrapper>>>>();
            Map<String, List<ServiceAppointment>> mapBuildingServiceAppointments = new Map<String, List<ServiceAppointment>>();

            for(ServiceAppointment sa : appointments){

                WorkOrder wo = mapWorkOrder.get(sa.ParentRecordId);

                //if(wo.Status != 'Completed' && wo.Payment_Mode__c != 'Directly Paid by Customer'){
                    String location = (wo != null && wo.New_Location__c != null) ? wo.New_Location__c : (sa.Account.Other_City__c != null ? sa.Account.Other_City__c : 'Unknown Location');
                    String road = (wo != null && wo.New_Road_Name__c != null) ? wo.New_Road_Name__c : (sa.Account.Street_Line_5__c != null ? sa.Account.Street_Line_5__c : 'Unknown Road');
                    String building = (wo != null && wo.Building_Name__c != null) ? wo.Building_Name__c : (sa.Account.Building_Name__c != null ? sa.Account.Building_Name__c : 'Unknown Building');

                    if(!locationMap.containsKey(location)) locationMap.put(location, new Map<String, Map<String, List<ServiceAppointmentWrapper>>>());
                    if(!locationMap.get(location).containsKey(road)) locationMap.get(location).put(road, new Map<String, List<ServiceAppointmentWrapper>>());
                    if(!locationMap.get(location).get(road).containsKey(building)) locationMap.get(location).get(road).put(building, new List<ServiceAppointmentWrapper>());

                    locationMap.get(location).get(road).get(building).add(new ServiceAppointmentWrapper(sa, wo));

                    if(!mapBuildingServiceAppointments.containsKey(building)) mapBuildingServiceAppointments.put(building, new List<ServiceAppointment>());
                    mapBuildingServiceAppointments.get(building).add(sa);    
                //}
            }

            // Status counts
            List<Metering_Dashboard_Config__mdt> metaList = [
                SELECT Label__c, Field_API_Name__c, Values__c, Order__c, Card_Color__c, Icon_URL__c
                FROM Metering_Dashboard_Config__mdt 
                WHERE Active__c = true AND Department__c = 'R&T'
                ORDER BY Order__c ASC
            ];

            Map<String, List<RTDashboardController.DataWrapper>> groupedAppointmentCounts = new Map<String, List<RTDashboardController.DataWrapper>>();
            for(String key : mapBuildingServiceAppointments.keySet()){
                groupedAppointmentCounts.put(key, RTDashboardController.getStatusByCount(mapBuildingServiceAppointments.get(key), metaList));
            }

            List<Object> locationGroupList = new List<Object>();
            for(String loc : locationMap.keySet()){
                LocationGroup lg = new LocationGroup();
                lg.name = loc;
                lg.roads = new List<RoadGroup>();
                Integer rdCount = 0;

                for(String rd : locationMap.get(loc).keySet()){
                    RoadGroup rg = new RoadGroup();
                    rg.name = rd;
                    rg.buildings = new List<BuildingGroup>();
                    Integer blgCount = 0;

                    for(String bldg : locationMap.get(loc).get(rd).keySet()){
                        BuildingGroup bg = new BuildingGroup();
                        bg.name = bldg;
                        bg.appointments = locationMap.get(loc).get(rd).get(bldg);
                        bg.statusCounts = groupedAppointmentCounts.get(bldg);
                        bg.count = bg.appointments.size();
                        rg.buildings.add(bg);
                        blgCount += bg.appointments.size();
                    }

                    rg.count = blgCount;
                    rdCount += blgCount;
                    lg.roads.add(rg);
                }

                lg.count = rdCount;
                locationGroupList.add(lg);
            }

            return locationGroupList;
        }
        catch(Exception e){
            AS_ErrorLogger.log('RtAppointmentListViewController','getAppointmentsByStatus',e,null);
            return null;
        }
    }

    public class ReturnWrapper{
        @AuraEnabled public Map<String,List<RTDashboardController.DataWrapper>> groupedAppointmentCounts;
        @AuraEnabled public Map<String, List<ServiceAppointmentWrapper>> groupedAppointments;
        @AuraEnabled public List<LocationGroup> locationGroup;
    }

    public class LocationGroup {
        @AuraEnabled public String name;
        @AuraEnabled public Integer count;
        @AuraEnabled public List<RoadGroup> roads;
    }
    public class RoadGroup {
        @AuraEnabled public String name;
        @AuraEnabled public Integer count;
        @AuraEnabled public List<BuildingGroup> buildings;
    }
    public class BuildingGroup {
        @AuraEnabled public String name;
        @AuraEnabled public Integer count;
        @AuraEnabled public String buildingName;
        @AuraEnabled public String buildingStreet;
        @AuraEnabled public Boolean statusSection;
        @AuraEnabled public List<RTDashboardController.DataWrapper> statusCounts;
        @AuraEnabled public List<ServiceAppointmentWrapper> appointments;
    }

    public class ServiceAppointmentWrapper {
        @AuraEnabled public Id id;
        @AuraEnabled public String subject;
        @AuraEnabled public String bpNumber;
        @AuraEnabled public String caNumber;
        @AuraEnabled public String customerName;
        @AuraEnabled public String meterNumber;
        @AuraEnabled public String accountName;
        @AuraEnabled public Decimal DueAmount;
        @AuraEnabled public String status;
        @AuraEnabled public String visitStatus;
        @AuraEnabled public Datetime SchedEndTime;
        @AuraEnabled public String location;
        @AuraEnabled public String buildingName;
        @AuraEnabled public String buildingStreet;
        @AuraEnabled public String roadName;
        @AuraEnabled public String DetailAccountSummary; 
        @AuraEnabled public String appointmentType;
        @AuraEnabled public Boolean isRandomVisit;
        @AuraEnabled public Boolean isDirectPayment;
        @AuraEnabled public String followUpRemarks;

        // New constructor accepting both ServiceAppointment and WorkOrder
        public ServiceAppointmentWrapper(ServiceAppointment sa, WorkOrder wo) {
            this.id = sa.Id;
            this.subject = sa.Subject;
            this.bpNumber = (wo != null && String.isNotBlank(wo.Customer_BP_Number__c)) ? wo.Customer_BP_Number__c : '';
            this.caNumber = (wo != null && String.isNotBlank(wo.CA_Number__c)) ? wo.CA_Number__c : '';
            this.customerName = (wo != null && String.isNotBlank(wo.Customer_Name__c)) ? wo.Customer_Name__c : '';
            this.location = (wo != null && String.isNotBlank(wo.New_Location__c)) ? wo.New_Location__c : (sa.Account != null && String.isNotBlank(sa.Account.Other_City__c) ? sa.Account.Other_City__c : 'Unknown Location');
            this.meterNumber = sa.Meter_Number__c;
            this.DueAmount = sa.Due_Amount__c;
            this.accountName = (sa.Account != null) ? sa.Account.Name : '';
            this.status = sa.Status;
            this.SchedEndTime = (wo != null && wo.Status == 'Follow Up' && wo.Follow_up_Date__c != null) ? wo.Follow_up_Date__c : sa.SchedEndTime;
            this.appointmentType = String.isBlank(sa.Appointment_Type__c) ? 'Scheduled' : sa.Appointment_Type__c;
            this.isRandomVisit = sa.Random_Visit_Date__c != null;
            this.isDirectPayment = (wo != null && wo.Status == 'Completed' && wo.Payment_Mode__c == 'Directly Paid by Customer');
            this.visitStatus = sa.Visit_Status__c;
            this.followUpRemarks = (wo != null && String.isNotBlank(wo.Follow_up_Remarks__c)) ? wo.Follow_up_Remarks__c : '';

            if (sa.Account != null) {
                this.buildingName = (wo != null && String.isNotBlank(wo.Building_Name__c)) ? wo.Building_Name__c : (sa.Account.Building_Name__c != null ? sa.Account.Building_Name__c : 'Unknown');
                this.buildingStreet = (wo != null && String.isNotBlank(wo.New_Road_Name__c)) ? wo.New_Road_Name__c : (sa.Account.Street__c != null ? sa.Account.Street__c : '');
                this.roadName = (wo != null && String.isNotBlank(wo.New_Road_Name__c)) ? wo.New_Road_Name__c : (sa.Account.Street__c != null ? sa.Account.Street__c : '');

                this.DetailAccountSummary = formatAddress(
                    (wo != null && String.isNotBlank(wo.Building_Name__c)) ? wo.Building_Name__c : sa.Account.Street_Line_2__c,
                    (wo != null && String.isNotBlank(wo.New_Flat__c)) ? wo.New_Flat__c : sa.Account.Room__c,
                    (wo != null && String.isNotBlank(wo.New_Floor__c)) ? wo.New_Floor__c : sa.Account.Floor__c,
                    (wo != null && String.isNotBlank(wo.New_Wing__c)) ? wo.New_Wing__c : sa.Account.Wing__c,
                    (wo != null && String.isNotBlank(wo.New_Plot__c)) ? wo.New_Plot__c : '',
                    (wo != null && String.isNotBlank(wo.New_Road_Name__c)) ? wo.New_Road_Name__c : sa.Account.Street_Line_5__c,
                    (wo != null && String.isNotBlank(wo.New_Landmark__c)) ? wo.New_Landmark__c : sa.Account.Street_Line_3__c,
                    (wo != null && String.isNotBlank(wo.New_Colony__c)) ? wo.New_Colony__c : '',
                    (wo != null && String.isNotBlank(wo.New_Location__c)) ? wo.New_Location__c : sa.Account.Other_City__c,
                    (wo != null && String.isNotBlank(wo.City__c)) ? wo.City__c : '',
                    (wo != null && String.isNotBlank(wo.DISTRICT__c)) ? wo.DISTRICT__c : ''
                );
            } else {
                this.buildingName = 'Unknown';
                this.DetailAccountSummary = 'No address available';
            }
        }

        // Helper method to format address
        private String formatAddress(
            String building, 
            String flat, 
            String floor, 
            String wing, 
            String plot,
            String road, 
            String landmark, 
            String colony,
            String location,
            String city,
            String district
        ) {
            List<String> parts = new List<String>();
            if (String.isNotBlank(building)) parts.add(building);
            if (String.isNotBlank(flat)) parts.add(flat);
            if (String.isNotBlank(floor)) parts.add(floor);
            if (String.isNotBlank(wing)) parts.add(wing);
            if (String.isNotBlank(plot)) parts.add(plot);
            if (String.isNotBlank(road)) parts.add(road);
            if (String.isNotBlank(landmark)) parts.add(landmark);
            if (String.isNotBlank(colony)) parts.add(colony);
            if (String.isNotBlank(location)) parts.add(location);
            if (String.isNotBlank(city)) parts.add(city);
            if (String.isNotBlank(district)) parts.add(district);

            return parts.isEmpty() ? 'No address available' : String.join(parts, ', ');
        }
    }

    @AuraEnabled(cacheable=true)
    public static Id getWorkOrderIdFromSA(Id serviceAppointmentId) {

        if (serviceAppointmentId == null) {
            throw new AuraHandledException('Service Appointment ID is null.');
        }

        try {
            List<WorkOrder> workOrders = [SELECT Id, (SELECT Id FROM ServiceAppointments)
                                            FROM WorkOrder
                                           WHERE Id IN (SELECT ParentRecordId FROM ServiceAppointment WHERE Id = :serviceAppointmentId)
                                           LIMIT 1];

            if (!workOrders.isEmpty()) {
                return workOrders[0].Id;
            }

            return null;
            
        } catch (Exception ex) {
            throw new AuraHandledException('Failed to retrieve Work Order: ' + ex.getMessage());
        }
    }
}