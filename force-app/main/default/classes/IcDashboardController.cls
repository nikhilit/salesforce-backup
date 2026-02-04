/**
 * @description       :
 * @author            : Shashank.shekhar@appstrail.com
 * @group             :
 * @last modified on  : 06-26-2025
 * @last modified by  : Shashank.shekhar@appstrail.com
 **/
public without sharing class IcDashboardController {
    
    public static Map<Id, WorkOrder> mapWorkOrder = new Map<Id, WorkOrder>();
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Integer> getKPIs() {
        
        Id userId = UserInfo.getUserId();
        userId = '005fs0000001xfZAAQ'; //Bhav
        
        //Id serviceResourceId = [SELECT Id FROM ServiceResource WHERE RelatedRecordId = :userId LIMIT 1].Id;
        
        List<ServiceResource> srList = [SELECT Id FROM ServiceResource WHERE RelatedRecordId = :userId LIMIT 1];
        if (srList.isEmpty()) {
            // No ServiceResource found, return empty KPIs map
            return new Map<String, Integer>{
                'total' => 0,
                'unattempted' => 0,
                'completed' => 0,
                'incomplete' => 0,
                'followup' => 0,
                'random' => 0
            };
        }
        Id serviceResourceId = srList[0].Id;
        
        Date today = Date.today();
        Date startDate = today;
        Date endDate = today.addDays(1);
        
        Map<String, Integer> kpis = new Map<String, Integer>{
            'total' => 0,
            'unattempted' => 0,
            'completed' => 0,
            'incomplete' => 0,
            'followup' => 0,
            'random' => 0
        };
        
        //Get all ServiceAppointments assigned to the user
        Set<Id> serviceAppointmentIds = new Set<Id>();
        
        for (AssignedResource ar : [SELECT ServiceAppointmentId FROM AssignedResource WHERE ServiceResourceId = :serviceResourceId]) {
            if (ar.ServiceAppointmentId != null) {
                serviceAppointmentIds.add(ar.ServiceAppointmentId);
            }
        }
        
        if (serviceAppointmentIds.isEmpty()) {
            return kpis;
        }
        
        String gsRecordTypeID = Schema.getGlobalDescribe().get('WorkOrder').getDescribe().getRecordTypeInfosByDeveloperName().get('MGL_R_T').getRecordTypeId();
        
        //Get today's scheduled ServiceAppointments
        List<ServiceAppointment> appointments = [SELECT Id, Status, SchedStartTime, SchedEndTime, Appointment_Type__c,
                                                        Random_Visit_Date__c
                                                   FROM ServiceAppointment
                                                  WHERE Id IN :serviceAppointmentIds 
                                                    AND ParentRecord.RecordTypeId = :gsRecordTypeID
                                                    AND Follow_Up_Visit_Date__c = null
                                                    AND DisplaySpecificRangeVisits__c = true];
        
        //Classify based on Status
        for (ServiceAppointment sa : appointments) {
            
            if(sa.Random_Visit_Date__c == null){
                kpis.put('total', kpis.get('total') + 1);
                
                if (sa.Appointment_Type__c == 'Follow Up') {
                    kpis.put('followup', kpis.get('followup') + 1);
                }
                
                if (sa.Status == 'Completed') {
                    kpis.put('completed', kpis.get('completed') + 1);
                } else if (sa.Status == 'Cannot Complete') {
                    kpis.put('incomplete', kpis.get('incomplete') + 1);
                } else if (sa.Status == 'Scheduled' || sa.Status == 'None' || sa.Status == 'In Progress' || sa.Status == 'Dispatched') {
                    kpis.put('unattempted', kpis.get('unattempted') + 1);
                }
            }else{
                if(sa.Status == 'Completed'){
                    kpis.put('random', kpis.get('random') + 1);
                }
            }
        }
        
        return kpis;
    }
    
    @AuraEnabled
    public static List<DataWrapper> getCountByMetadataMatch() {
        
        Id userId = UserInfo.getUserId();
        userId = '005fs0000001xfZAAQ'; //Bhav
        
        //Id serviceResourceId = [SELECT Id FROM ServiceResource WHERE RelatedRecordId =: userId LIMIT 1].Id;
        
        List<ServiceResource> srList = [SELECT Id FROM ServiceResource WHERE RelatedRecordId = :userId LIMIT 1];
        if (srList.isEmpty()) {
            return new List<DataWrapper>();
        }
        Id serviceResourceId = srList[0].Id;
        
        //Get all ServiceAppointments assigned to the user
        Set<Id> serviceAppointmentIds = new Set<Id>();
        for (AssignedResource ar : [SELECT ServiceAppointmentId
                                      FROM AssignedResource
                                     WHERE ServiceResourceId = :serviceResourceId]) {
            if (ar.ServiceAppointmentId != null) {
                serviceAppointmentIds.add(ar.ServiceAppointmentId);
            }
        }
        
        List<DataWrapper> results = new List<DataWrapper>();
        
        // Load and organize metadata
        List<Metering_Dashboard_Config__mdt> metaList = [SELECT Label__c, Field_API_Name__c, Values__c, Order__c,Card_Color__c,Icon_URL__c
                                                           FROM Metering_Dashboard_Config__mdt
                                                          WHERE Active__c = true 
                                                            AND Department__c = 'R&T'
                                                       ORDER BY Order__c ASC];
        
        // Map<FieldName, Map<ExpectedValue, Label>>
        Map<String, Map<String, String>> fieldValueToLabelMap = new Map<String, Map<String, String>>();
        Map<String, Integer> labelToCount = new Map<String, Integer>();
        Map<String, List<ServiceAppointment>> mapLabelListSA = new Map<String, List<ServiceAppointment>>();
        
        for (Metering_Dashboard_Config__mdt meta : metaList) {
            
            String fieldName = meta.Field_API_Name__c;
            String label = meta.Label__c;
            
            List<String> values = meta.Values__c != null ? new List<String>(meta.Values__c.split(',')) : new List<String>();
            
            if (!fieldValueToLabelMap.containsKey(fieldName)) {
                fieldValueToLabelMap.put(fieldName, new Map<String, String>());
            }
            
            for (String val : values) {
                fieldValueToLabelMap.get(fieldName).put(val.trim().toLowerCase(), label);
            }
            
            labelToCount.put(label, 0);
            mapLabelListSA.put(label, new List<ServiceAppointment>());
        }
        
        String gsRecordTypeID = Schema.getGlobalDescribe().get('WorkOrder').getDescribe().getRecordTypeInfosByDeveloperName().get('MGL_R_T').getRecordTypeId();
        
        // Collect all relevant fields to query
        Set<String> allFields = new Set<String>(fieldValueToLabelMap.keySet());
        //{Status => {{Completed=>Completed}, {Cannot Complete=>Incompleted}, {None=>Un-attempted, In Progress=>Un-attempted}}}
        
        String soql = 'SELECT Id';
        
        for (String f : allFields) {
            soql += ', ' + f;
        }
        
        soql += ' FROM ServiceAppointment WHERE Id IN :serviceAppointmentIds AND ParentRecord.RecordTypeId = :gsRecordTypeID'+
            ' AND Appointment_Type__c NOT IN (\'Follow Up\', \'Random\') AND Follow_Up_Visit_Date__c = null'+
            ' AND DisplaySpecificRangeVisits__c = true AND Random_Visit_Date__c = null';
        
        // Query appointments dynamically
        List<ServiceAppointment> appointments = Database.query(soql);
        
        results = getStatusByCount(appointments, metaList);
        
        return results;
    }
    
    public static List<DataWrapper> getStatusByCount(List<ServiceAppointment> listServiceAppointments, List<Metering_Dashboard_Config__mdt> metaList){
        // Load and organize metadata
        
        // Map<FieldName, Map<ExpectedValue, Label>>
        Map<String, Map<String, String>> fieldValueToLabelMap = new Map<String, Map<String, String>>();
        Map<String, Integer> labelToCount = new Map<String, Integer>();
        Map<String, List<ServiceAppointment>> mapLabelListSA = new Map<String, List<ServiceAppointment>>();
        
        for (Metering_Dashboard_Config__mdt meta : metaList) {
            
            String fieldName = meta.Field_API_Name__c;
            String label = meta.Label__c;
            
            List<String> values = meta.Values__c != null ? new List<String>(meta.Values__c.split(',')) : new List<String>();
            
            if (!fieldValueToLabelMap.containsKey(fieldName)) {
                fieldValueToLabelMap.put(fieldName, new Map<String, String>());
            }
            
            for (String val : values) {
                fieldValueToLabelMap.get(fieldName).put(val.trim().toLowerCase(), label);
            }
            
            labelToCount.put(label, 0);
            mapLabelListSA.put(label, new List<ServiceAppointment>());
        }
        
        List<DataWrapper> results = new List<DataWrapper>();
        
        // Collect all relevant fields to query
        Set<String> allFields = new Set<String>(fieldValueToLabelMap.keySet());
        
        // Count matches
        for (ServiceAppointment sa : listServiceAppointments) {
            
            for (String fieldName : allFields) {
                
                if (!sa.getSObjectType().getDescribe().fields.getMap().containsKey(fieldName)) continue;
                
                Object value = sa.get(fieldName);
                if (value == null) continue;
                
                String valueStr = String.valueOf(value).trim().toLowerCase();
                //{Status => {{Completed=>Completed}, {Cannot Complete=>Incompleted}, {None=>Un-attempted, In Progress=>Un-attempted}}}
                
                if (fieldValueToLabelMap.get(fieldName).containsKey(valueStr)) {
                    String label = fieldValueToLabelMap.get(fieldName).get(valueStr);
                    labelToCount.put(label, labelToCount.get(label) + 1);
                    mapLabelListSA.get(label).add(sa);
                }
            }
        }
        
        // Convert to wrapper
        for (Metering_Dashboard_Config__mdt meta : metaList) {
            results.add(new DataWrapper(
                meta.Label__c,
            labelToCount.get(meta.Label__c),
            mapLabelListSA.get(meta.Label__c),
            meta.Card_Color__c,
            meta.Icon_URL__c
                ));
        }
        
        return results;
    }
    
    public class DataWrapper {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String cardColor { get; set; }
        @AuraEnabled public String iconUrl { get; set; }
        @AuraEnabled public Decimal count { get; set; }
        @AuraEnabled public List<ServiceAppointment> listServiceAppointments{get;set;}
        
        public DataWrapper(String label, Decimal count, List<ServiceAppointment> listServiceAppointments,
        String cardColor,String iconUrl) {
            this.label = label;
            this.count = count;
            this.iconUrl= iconUrl;
            this.cardColor= cardColor;
            this.listServiceAppointments = listServiceAppointments;
        }
    }
    
    @AuraEnabled
    public static List<WorkType> getFlatAppointmentsByStatus(String status, String type) {
        Date today = Date.today();
        Id userId = UserInfo.getUserId();
        
        userId = '005fs0000001xfZAAQ'; //Bhav
        // userId = '005fs00000099vJAAQ'; // testAgent1
        
        Id serviceResourceId;
        try {
            serviceResourceId = [
                SELECT Id
                FROM ServiceResource
                WHERE RelatedRecordId = :userId
                LIMIT 1
            ].Id;
            
        } catch (Exception e) {
            return new List<WorkType>();
        }
        
        Set<String> completedStatuses = new Set<String>{'Completed'};
        Set<String> incompleteStatuses = new Set<String>{'Cannot Complete'};
        Set<String> unattemptedStatuses = new Set<String>{'None', 'Scheduled', 'In Progress', 'Dispatched'};
        Set<String> totalStatuses = new Set<String>{'Canceled', 'Completed', 'Cannot Complete', 'In Progress', 'Dispatched', 'Scheduled', 'None'};
        Set<String> allStatuses = new Set<String>{'Canceled', 'Completed', 'Cannot Complete', 'In Progress', 'Dispatched', 'Scheduled', 'None'};
        
        String normalizedStatus = String.isNotBlank(status) ? status.trim().toLowerCase() : '';
        String normalizedType = String.isNotBlank(type) ? type.trim() : null;
        
        Set<String> targetStatuses = new Set<String>();
        if (normalizedStatus == 'completed') {
            targetStatuses = completedStatuses;
        } else if (normalizedStatus == 'incomplete') {
            targetStatuses = incompleteStatuses;
        } else if (normalizedStatus == 'unattempted') {
            targetStatuses = unattemptedStatuses;
        } else if (normalizedStatus == 'total') {
            targetStatuses = totalStatuses;
        } else {
            targetStatuses = allStatuses;
        }
        
        
        Set<Id> assignedAppointmentIds = new Set<Id>();
        for (AssignedResource ar : [
            SELECT ServiceAppointmentId
            FROM AssignedResource
            WHERE ServiceResourceId = :serviceResourceId
        ]) {
            assignedAppointmentIds.add(ar.ServiceAppointmentId);
        }
        
        if (assignedAppointmentIds.isEmpty()) {
            return new List<WorkType>();
        }
        
        String gsRecordTypeID = Schema.getGlobalDescribe().get('WorkOrder').getDescribe().getRecordTypeInfosByDeveloperName().get('MGL_R_T').getRecordTypeId();
        
        mapWorkOrder = new Map<Id, WorkOrder>([SELECT Id, Building_Name__c, New_Flat__c, New_Floor__c, New_Wing__c, New_Plot__c, 
                                                      New_Road_Name__c, New_Landmark__c, New_Colony__c, New_Location__c, City__c,
                                                      DISTRICT__c, New_Mobile_Number__c, Email_ID__c, Follow_up_Date__c, Status,
                                                      Customer_BP_Number__c, CA_Number__c, Customer_Name__c, Follow_up_Remarks__c,
                                                      Payment_Mode__c
                                                 FROM WorkOrder 
                                                WHERE Id 
                                                   IN (SELECT ParentRecordId 
                                                         FROM ServiceAppointment 
                                                        WHERE Id IN :assignedAppointmentIds
                                                          AND Status IN :targetStatuses
                                                          AND ParentRecord.RecordTypeId=:gsRecordTypeID)]);
        
        String query = 'SELECT Id, Status, Subject, SchedEndTime, Visit_Status__c, Due_Amount__c, AccountId, ParentRecordId,' +
            ' Account.BP_Number__c, Account.DRS__c, Account.MRU_Code__c,Account.BillingStreet, Account.CA_Number__c,' +
            ' Account.Name, Account.Building_name__c, Account.Street__c, Account.Colony__c, WorkType.Name, Account.Room__c,' +
            ' Account.Wing__c, Account.Floor__c, Account.Flat__c, Account.Road_name__c, Meter_Number__c, Appointment_Type__c,' +
            ' Account.Street_Line_5__c, Account.Street_Line_3__c, Account.Street_Line_2__c, Account.Other_City__c,' +
            ' Follow_Up_Visit_Date__c, Random_Visit_Date__c' +
            ' FROM ServiceAppointment WHERE Id IN :assignedAppointmentIds' +
            ' AND Status IN :targetStatuses' +
            ' AND ParentRecord.RecordTypeId = :gsRecordTypeID AND Follow_Up_Visit_Date__c = null' +
            ' AND DisplaySpecificRangeVisits__c = true';
        
        // // Filter on Appointment_Type__c only if type is provided
        // if (normalizedType != null) {
            //     query += ' AND Appointment_Type__c = :normalizedType AND Status != \'Completed\'';
        // }
        
        if(normalizedStatus != 'total' && type == 'Follow Up'){
            query += ' AND Appointment_Type__c = \'Follow Up\'';
        } else if(normalizedStatus != 'total' && type == 'Random'){
            query += ' AND (Appointment_Type__c = \'Random\' OR Random_Visit_Date__c != null) AND Status = \'Completed\' ';
        } else if(normalizedStatus != 'total' && type != 'Follow Up'){
            query += ' AND (Appointment_Type__c != \'Follow Up\' OR Appointment_Type__c = null) AND Random_Visit_Date__c = null';
        } else{
            query += ' AND Random_Visit_Date__c = null';
        }
        
        query += ' ORDER BY Due_Amount__c DESC NULLS LAST';
        
        List<ServiceAppointment> appointments = Database.query(query);
        
        // List<ServiceAppointmentWrapper> flatAppointmentList = new List<ServiceAppointmentWrapper>();
        // for (ServiceAppointment sa : appointments) {
            //     flatAppointmentList.add(new ServiceAppointmentWrapper(sa));
        // }
        
        
        Map<String, List<ServiceAppointmentWrapper>> groupedByWorkType = new Map<String, List<ServiceAppointmentWrapper>>();
        for (ServiceAppointment sa : appointments) {
            String workTypeName = (sa.WorkType != null && String.isNotBlank(sa.WorkType.Name))
                ? sa.WorkType.Name
                : 'Unknown';
            
            WorkOrder wo = mapWorkOrder.get(sa.ParentRecordId);
            
            if (!groupedByWorkType.containsKey(workTypeName)) {
                groupedByWorkType.put(workTypeName, new List<ServiceAppointmentWrapper>());
            }
            groupedByWorkType.get(workTypeName).add(new ServiceAppointmentWrapper(sa, wo));
        }
        
        List<WorkType> lstWorkType = new List<WorkType>();
        
        // List<String> orderedWorkTypes = new List<String>{
        //     'Billing Distribution (R&T)',
        //     'Payment Collection(R&T)',
        //     'Letter of Notices (R&T)',
        //     'Disconnection Activity (R&T)',
        //     'Reconnection Activity (R&T)'
        // };

        for(String workTp : groupedByWorkType.keySet()){
            WorkType wT = new WorkType();
            
            wT.name = workTp;
            wT.count = groupedByWorkType.get(workTp).size();
            wT.appointments = groupedByWorkType.get(workTp);
            
            lstWorkType.add(wT);
        }
        
        return lstWorkType;
    }
    
    public class WorkType{
        @AuraEnabled public String name;
        @AuraEnabled public Integer count;
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