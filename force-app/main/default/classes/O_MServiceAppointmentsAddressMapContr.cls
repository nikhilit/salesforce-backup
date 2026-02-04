/**
 * @description       :
 * @author            : Shashank.shekhar@appstrail.com
 * @group             :
 * @last modified on  : 19-05-2025
 * @last modified by  : Kartik Patkar, Appstrail
 **/
public with sharing class O_MServiceAppointmentsAddressMapContr{
    
    @AuraEnabled(cacheable=true)
    public static ReturnWrapper getAppointmentsByStatus(String status,String type) {
        System.debug('### getAppointmentsByStatus called with status: ' + status);
        
        Date today = Date.today();
        Date tomorrow = today.addDays(1);
        Id userId = UserInfo.getUserId();
        
        Id serviceResourceId = [
            SELECT Id
            FROM ServiceResource
            WHERE RelatedRecordId = :userId
            LIMIT 1
        ].Id;
        
        System.debug('### ServiceResourceId: ' + serviceResourceId);
        
        // Define Sets for real Salesforce Status values
        Set<String> completedStatuses = new Set<String>{'Completed'};
        Set<String> incompleteStatuses = new Set<String>{'Cannot Complete','In Progress'};
        Set<String> unattemptedStatuses = new Set<String>{'None', 'Scheduled','Dispatched'};
        Set<String> totalStatuses = new Set<String>{'Canceled', 'Completed', 'Cannot Complete', 'In Progress', 'Dispatched', 'Scheduled', 'None'};
        Set<String> allStatuses = new Set<String>{'Canceled', 'Completed', 'Cannot Complete', 'In Progress', 'Dispatched', 'Scheduled', 'None'};
        
        // Normalize incoming status string
        String normalizedStatus = String.isNotBlank(status) ? status.trim().toLowerCase() : '';
        
        System.debug('### Raw Status: _' + status + '_');
        System.debug('### Normalized Status: _' + normalizedStatus + '_');
        
        // Final target statuses to query
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
        
        System.debug('### Final Target Statuses: ' + targetStatuses);
        
        
        Set<Id> assignedAppointmentIds = new Set<Id>();
        for (AssignedResource ar : [
            SELECT ServiceAppointmentId
            FROM AssignedResource
            WHERE ServiceResourceId = :serviceResourceId
        ]) {
            assignedAppointmentIds.add(ar.ServiceAppointmentId);
        }
        
        System.debug('### Assigned Appointment IDs: ' + assignedAppointmentIds);
        type=(type==null)?'Scheduled':type;
        String gsRecordTypeID = Schema.getGlobalDescribe().get('WorkOrder')
            .getDescribe().getRecordTypeInfosByDeveloperName().get('MGL_O_M').getRecordTypeId();
        
        String query='SELECT Id, Status, Subject, SchedStartTime,Visit_Status__c,AccountId,'+
                    ' Account.Name, Account.Building_name__c, Account.Street__c, Account.Colony__c,'+
                    ' Account.Wing__c, Account.Floor__c, Account.Flat__c, Account.Road_name__c, Meter_Number__c, Appointment_Type__c'+
                    ' FROM ServiceAppointment WHERE Id IN :assignedAppointmentIds AND Status IN :targetStatuses AND ParentRecord.RecordTypeId=:gsRecordTypeID';

        if(type=='Ad-Hoc'){
            query+=' AND Appointment_Type__c=:type';
        }
        List<ServiceAppointment> appointments = Database.query(query);
        
        System.debug('### Queried Appointments: ' + appointments);
        
        Map<String, List<ServiceAppointmentWrapper>> groupedAppointments = new Map<String, List<ServiceAppointmentWrapper>>();
        Map<String,List<ServiceAppointment>> mapBuildingServiceAppointments=new Map<String,List<ServiceAppointment>>();
        for (ServiceAppointment sa : appointments) {
            String building = (sa.Account != null && String.isNotBlank(sa.Account.Building_name__c))
                ? sa.Account.Building_name__c
                : 'Others';
            
            String street = (sa.Account != null && String.isNotBlank(sa.Account.Street__c))
                ? sa.Account.Street__c
                : 'Others';
            
            if (!groupedAppointments.containsKey(building)) {
                groupedAppointments.put(building, new List<ServiceAppointmentWrapper>());
            }
            
            groupedAppointments.get(building).add(new ServiceAppointmentWrapper(sa));
            if(mapBuildingServiceAppointments.containsKey(building)){
                mapBuildingServiceAppointments.get(building).add(sa);
            }else{
                mapBuildingServiceAppointments.put(building,new List<ServiceAppointment>{sa});
            }
        }
        
        // Load and organize metadata
        List<Metering_Dashboard_Config__mdt> metaList = [
            SELECT Label__c, Field_API_Name__c, Values__c, Order__c,Card_Color__c,Icon_URL__c
            FROM Metering_Dashboard_Config__mdt
            WHERE Active__c = true and Department__c='O&M'
            ORDER BY Order__c ASC
        ];
        
        Map<String,List<MeterReaderDashboardController.DataWrapper>> groupedAppointmentCounts = new Map<String,List<MeterReaderDashboardController.DataWrapper>>();
        for(String key:groupedAppointments.keySet()){
            System.debug('### key: ' + key);
            groupedAppointmentCounts.put(key,MeterReaderDashboardController.getStatusByCount(mapBuildingServiceAppointments.get(key),metaList));
        }
        
        // List<MeterReaderDashboardController.DataWrapper> listDataWrapper=MeterReaderDashboardController.getStatusByCount(appointments,metaList);
        
        System.debug('### Grouped Appointments (Final Response): ' + groupedAppointments);
        
        ReturnWrapper result=new ReturnWrapper();
        result.groupedAppointmentCounts=groupedAppointmentCounts;
        result.groupedAppointments=groupedAppointments;
        return result;
    }
    
    public class ReturnWrapper{
        @AuraEnabled public Map<String,List<MeterReaderDashboardController.DataWrapper>> groupedAppointmentCounts;
        @AuraEnabled public Map<String, List<ServiceAppointmentWrapper>> groupedAppointments;
    }
    
    public class ServiceAppointmentWrapper {
        @AuraEnabled public Id id;
        @AuraEnabled public String subject;
        @AuraEnabled public String meterNumber;
        @AuraEnabled public String accountName;
        @AuraEnabled public String status;
        @AuraEnabled public String visitStatus;
        @AuraEnabled public Datetime schedStartTime;
        @AuraEnabled public String buildingName;
        @AuraEnabled public String buildingStreet;
        @AuraEnabled public String DetailAccountSummary;
        @AuraEnabled public String appointmentType;
        
        public ServiceAppointmentWrapper(ServiceAppointment sa) {
            this.id = sa.Id;
            this.subject = sa.Subject;
            this.meterNumber = sa.Meter_Number__c;
            this.visitStatus = sa.Visit_Status__c;
            this.accountName = sa.Account != null ? sa.Account.Name : null;
            this.status = sa.Status;
            this.schedStartTime = sa.SchedStartTime;
            this.appointmentType= String.isBlank(sa.Appointment_Type__c)?'Scheduled':sa.Appointment_Type__c;
            
            if (sa.Account != null) {
                this.buildingName = sa.Account.Building_name__c;
                this.buildingStreet= sa.Account.Street__c;
                
                this.DetailAccountSummary = formatAddress(
                    sa.Account.Street__c,
                sa.Account.Wing__c,
                sa.Account.Colony__c,
                sa.Account.Floor__c,
                sa.Account.Flat__c,
                sa.Account.Road_name__c
                    );
            } else {
                this.buildingName = 'Unknown';
                this.DetailAccountSummary = 'No address available';
            }
        }
        
        private String formatAddress(String street, String wing, String colony, String floor, String flat, String road) {
            List<String> parts = new List<String>();
            if (String.isNotBlank(wing)) parts.add('Wing: '+wing);
            if (String.isNotBlank(floor)) parts.add('Floor: ' + floor);
            if (String.isNotBlank(flat)) parts.add('Flat: ' + flat);
            return parts.isEmpty() ? 'No address available' : String.join(parts, ', ');
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Id getWorkOrderIdFromSA(Id serviceAppointmentId) {
        List<WorkOrder> workOrders = [
            SELECT Id, (SELECT Id FROM ServiceAppointments)
            FROM WorkOrder
            WHERE Id IN (
                SELECT ParentRecordId FROM ServiceAppointment WHERE Id = :serviceAppointmentId
            )
            LIMIT 1
        ];
        
        if (!workOrders.isEmpty()) {
            return workOrders[0].Id;
        }
        return null;
    }
}