/**
 * @description       :
 * @author            : Shashank.shekhar@appstrail.com
 * @group             :
 * @last modified on  : 18-11-2025
 * @last modified by  : Kartik Patkar, Appstrail
 **/
public without sharing class serviceAppointmentsAddressMapController{
    
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
        Set<String> incompleteStatuses = new Set<String>{'Cannot Complete'};
        Set<String> unattemptedStatuses = new Set<String>{'None', 'Scheduled','In Progress', 'Dispatched'};
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
            .getDescribe().getRecordTypeInfosByDeveloperName().get('MGL_Metering').getRecordTypeId();
        DateTime nowTime = System.now();
        String query='SELECT Id, Status, Subject, SchedStartTime,AccountId,Customer_Name__c,BP_Number__c,'+
            ' Account.Name, Account.Building_name__c,Account.City__c,Account.Postal_Code__c, Account.Street__c, Account.Colony__c,'+
            ' Account.Wing__c, Account.Floor__c, Account.Flat__c, Account.Road_name__c, Meter_Number__c,'+
            ' Appointment_Type__c,Account.Phone__c,Account.Customer_Contact_no__c,Account.PersonHomePhone,' +
            ' Account.Secondary_Telephone__c,Account.Secondary_Phone__c,Account.Location__c,Account.Zone__c,Account.Representative_Company__c '+
            ' FROM ServiceAppointment WHERE Id IN :assignedAppointmentIds AND Status IN :targetStatuses AND ParentRecord.RecordTypeId=:gsRecordTypeID '+
            'AND SchedStartTime != NULL AND SchedEndTime != NULL '+
            'AND Schedule_Start_Date__c <= :today AND Schedule_End_Date__c >= :today AND Indirect_Reading_Received__c=false';
        
        //AND Work_Order__r.StartDate >= :today AND Work_Order__r.EndDate <= :today
        
        if(type=='Ad-Hoc'){
            query+=' AND Appointment_Type__c=\'Ad-Hoc\'';
        }else if(type=='Scheduled'){
            query+=' AND (Appointment_Type__c=\'Scheduled\' OR Appointment_Type__c=\'Standard\')';
        }
        query+=' ORDER BY Account.Building_name__c NULLS LAST,Account.Floor__c NULLS LAST,Account.Flat__c NULLS LAST';
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
            WHERE Active__c = true AND Department__c='Metering'
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
        @AuraEnabled public String query;
        @AuraEnabled public List<ServiceAppointmentWrapper> appointmentList;
        @AuraEnabled public String customerCategory;
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
        @AuraEnabled public String customerName;
        @AuraEnabled public String BPNumber;
        @AuraEnabled public String phone;
        @AuraEnabled public String customerContactNo;
        @AuraEnabled public String personHomePhone;
        @AuraEnabled public String secondaryTelephone;
        @AuraEnabled public String secondaryPhone;
        @AuraEnabled public String location;
        @AuraEnabled public String zone;
        @AuraEnabled public String representativeCompany;
        @AuraEnabled public String plot;
        @AuraEnabled public String flat;
        @AuraEnabled public String floor;
        @AuraEnabled public String wing;
        
        public ServiceAppointmentWrapper(ServiceAppointment sa) {
            this.id = sa.Id;
            this.subject = sa.Subject;
            this.meterNumber = sa.Meter_Number__c;
            this.accountName = sa.Account != null ? sa.Account.Name : null;
            this.status = sa.Status;
            this.schedStartTime = sa.SchedStartTime;
            this.appointmentType= String.isBlank(sa.Appointment_Type__c)?'Scheduled':sa.Appointment_Type__c;
            this.customerName = sa.Customer_Name__c;
            this.BPNumber = sa.BP_Number__c;
            
            if (sa.Account != null) {
                this.buildingName = sa.Account.Building_name__c;
                // this.buildingStreet= sa.Account.Street__c;
                this.buildingStreet= buildFullAddress(sa.Account.Building_name__c, 
                                                        sa.Account.Landmark__c, 
                                                        sa.Account.Road_name__c, 
                                                        sa.Account.Location__c, 
                                                        sa.Account.City__c, 
                                                        sa.Account.Postal_Code__c);
                this.phone = sa.Account.Phone__c;
                this.customerContactNo = sa.Account.Customer_Contact_no__c;
                this.personHomePhone = sa.Account.PersonHomePhone;
                this.secondaryTelephone = sa.Account.Secondary_Telephone__c;
                this.secondaryPhone = sa.Account.Secondary_Phone__c;
                this.location = sa.Account.Location__c;
                this.zone = sa.Account.Zone__c;
                this.representativeCompany = sa.Account.Representative_Company__c;
                this.plot = sa.Account.Plot__c;
                this.flat = sa.Account.Flat__c;
                this.floor = sa.Account.Floor__c;
                this.wing = sa.Account.Wing__c;
                
                this.DetailAccountSummary = formatAddress(
                    sa.Account.Street__c,
                    sa.Account.Wing__c,
                    sa.Account.Colony__c,
                    sa.Account.Floor__c,
                    sa.Account.Flat__c,
                    sa.Account.Plot__c
                );
            } else {
                this.buildingName = 'Unknown';
                this.DetailAccountSummary = 'No address available';
            }
        }
        
        private String formatAddress(String street, String wing, String colony, String floor, String flat, String plot) {
            List<String> parts = new List<String>();
            if (String.isNotBlank(plot)) parts.add('Plot: ' + plot);
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
   
    @AuraEnabled
    public static ReturnWrapper getAppointments(String status,String type) {
        System.debug('### getAppointmentsByStatus called with status: ' + status );
        System.debug('### getAppointmentsByStatus called with type: ' + type );
        
        Date today = Date.today();
        Date tomorrow = today.addDays(1);
        Id userId = UserInfo.getUserId();
        
        ServiceResource serviceResourceRec = [
            SELECT Id,Customer_Category__c
            FROM ServiceResource
            WHERE RelatedRecordId = :userId
            LIMIT 1
        ];
        
        Id serviceResourceId = serviceResourceRec.Id;
        String category = serviceResourceRec.Customer_Category__c;
        System.debug('### ServiceResourceId: ' + serviceResourceId);
        
        // Define Sets for real Salesforce Status values
        Set<String> completedStatuses = new Set<String>{'Completed'};
        Set<String> incompleteStatuses = new Set<String>{'Cannot Complete'};
        Set<String> unattemptedStatuses = new Set<String>{'None', 'Scheduled','In Progress', 'Dispatched'};
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
            .getDescribe().getRecordTypeInfosByDeveloperName().get('MGL_Metering').getRecordTypeId();
        DateTime nowTime = System.now();
        String query='SELECT Id, Status, Subject, SchedStartTime,AccountId,Customer_Name__c,BP_Number__c,'+
            ' Account.Name, Account.Building_name__c,Account.City__c,Account.Postal_Code__c, Account.Street__c, Account.Colony__c,'+
            ' Account.Wing__c, Account.Floor__c, Account.Flat__c, Account.Road_name__c,Account.Landmark__c, Meter_Number__c,'+
            ' Appointment_Type__c,Account.Phone__c,Account.Customer_Contact_no__c,Account.PersonHomePhone,Account.Plot__c,' +
            ' Account.Secondary_Telephone__c,Account.Secondary_Phone__c,Account.Location__c,Account.Zone__c,Account.Representative_Company__c '+
            ' FROM ServiceAppointment WHERE Id IN :assignedAppointmentIds AND Status IN :targetStatuses AND ParentRecord.RecordTypeId=:gsRecordTypeID '+
            'AND SchedStartTime != NULL AND SchedEndTime != NULL '+
            'AND Schedule_Start_Date__c <= :today AND Schedule_End_Date__c >= :today AND Indirect_Reading_Received__c=false';
        
        //AND Work_Order__r.StartDate >= :today AND Work_Order__r.EndDate <= :today
        
        if(type=='Ad-Hoc'){
            query+=' AND Appointment_Type__c=\'Ad-Hoc\'';
        }else if(type=='Scheduled'){
            query+=' AND (Appointment_Type__c=\'Scheduled\' OR Appointment_Type__c=\'Standard\')';
        }else{
            query+=' AND (Appointment_Type__c=\'Scheduled\' OR Appointment_Type__c=\'Standard\' OR Appointment_Type__c=\'Ad-Hoc\')';
        }

        query+=' ORDER BY Account.Building_name__c NULLS LAST,Account.Floor__c NULLS LAST, Account.Flat__c NULLS LAST';
        
        System.debug('### Query: ' + query);
        List<ServiceAppointment> appointments = Database.query(query);
        
        System.debug('### Queried Appointments: ' + appointments);
        
        Map<String, List<ServiceAppointmentWrapper>> groupedAppointments = new Map<String, List<ServiceAppointmentWrapper>>();
        Map<String,List<ServiceAppointment>> mapBuildingServiceAppointments=new Map<String,List<ServiceAppointment>>();
        List<ServiceAppointmentWrapper> appointmentList = new List<ServiceAppointmentWrapper>();
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
            appointmentList.add(new ServiceAppointmentWrapper(sa));
            
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
            WHERE Active__c = true AND Department__c='Metering'
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
        result.appointmentList=appointmentList;
        result.query=query;
        result.customerCategory=category;
        return result;
    }
    
    public static String buildFullAddress(String buildingName, String landmark, String roadName, String location, 
                                            String city, String postalCode) {
        List<String> addressParts = new List<String>();
        
        // if (String.isNotBlank(buildingName)) addressParts.add(buildingName.trim());
        if (String.isNotBlank(landmark)) addressParts.add(landmark.trim());
        if (String.isNotBlank(roadName)) addressParts.add(roadName.trim());
        if (String.isNotBlank(location)) addressParts.add(location.trim());
        if (String.isNotBlank(city)) addressParts.add(city.trim());
        
        String address = String.join(addressParts, ', ');
        
        if (String.isNotBlank(postalCode)) {
            address += ' -' + postalCode.trim();
        }
        
        return address;
    }
}