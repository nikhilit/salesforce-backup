/**
* @File Name : connectionListViewDetailsContr.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : August 19, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | August 19, 2025 |   | Initial Version
**/

public without sharing class connectionListViewDetailsContr {

    @AuraEnabled
    public static List<Connection__c> getAppointmentByStatus(String status,String type) {

        try {
        System.debug('### getAppointmentsByStatus called with status: ' + status);
        System.debug('### getAppointmentsByStatus called with type: ' + type);

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
        
        // String query='SELECT Id, Status, Subject, SchedStartTime,Visit_Status__c,AccountId,'+
        //     ' Account.Name, Account.Building_name__c, Account.Street__c, Account.Colony__c,'+
        //     ' Account.Wing__c, Account.Floor__c, Account.Flat__c, Account.Road_name__c, '+
        //     ' Account.BP_Number__c, Account.FirstName__c, Account.LastName__c, '+
        //     ' Meter_Number__c, Appointment_Type__c'+
        //     ' FROM ServiceAppointment WHERE Id IN :assignedAppointmentIds AND Status IN :targetStatuses AND ParentRecord.RecordTypeId=:gsRecordTypeID';

        // if(type=='Ad-Hoc'){
        //     query+=' AND Appointment_Type__c=:type';
        // }


		//  String query='SELECT Id, Status, Subject, SchedStartTime,Visit_Status__c,AccountId,'+
        //     ' Account.Name, Account.Building_name__c, Account.Street__c, Account.Colony__c,'+
        //     ' Account.Wing__c, Account.Floor__c, Account.Flat__c, Account.Road_name__c, '+
        //     ' Account.BP_Number__c, Account.FirstName__c, Account.LastName__c, '+
        //     ' Meter_Number__c, Appointment_Type__c'+
        //     ' FROM ServiceAppointment WHERE Id IN :assignedAppointmentIds AND Status IN :targetStatuses AND ParentRecord.RecordTypeId=:gsRecordTypeID';

        // List<ServiceAppointment> appointments = Database.query(query);

		     //   System.debug('### Queried Appointments: ' + appointments);


		List<ServiceAppointment> lstServiceApp = [Select id,ParentRecordId from ServiceAppointment WHERE Id IN :assignedAppointmentIds AND Status IN :targetStatuses AND ParentRecord.RecordTypeId=:gsRecordTypeID ];
        
		system.debug('lst of serviceappointment ::'+ lstServiceApp);
		List<String> lstWorkOrder = new List<String>();

		List<String> lstConnection = new List<String>();

                System.debug('### Queried Appointments: ' + lstServiceApp);

				for(ServiceAppointment serApp : lstServiceApp){

					lstWorkOrder.add(serApp.ParentRecordId);
				}


				List<WorkOrder> lstWorkConnection = [Select id,Connection__c from WorkOrder Where Id IN:lstWorkOrder];

				for(WorkOrder wo : lstWorkConnection){

					lstConnection.add(wo.Connection__c);
				}

		system.debug('lst of workorder ::'+ lstWorkConnection);

			system.debug('connection ids::'+ lstConnection);


		List<Connection__c> lstConnectionReturn = [Select id,Name,Building_Name__c,Address_1__c, Move_InDate__c, Status__c from Connection__c where id IN:lstConnection];
        
	system.debug('connection::'+ lstConnectionReturn);

        // Map<String, List<ServiceAppointmentWrapper>> groupedAppointments = new Map<String, List<ServiceAppointmentWrapper>>();
        // Map<String,List<ServiceAppointment>> mapBuildingServiceAppointments=new Map<String,List<ServiceAppointment>>();
        // List<ServiceAppointmentWrapper> listServiceApp=new List<ServiceAppointmentWrapper>();
        // for (ServiceAppointment sa : appointments) {
        //     listServiceApp.add(new ServiceAppointmentWrapper(sa));
        //     String building = (sa.Account != null && String.isNotBlank(sa.Account.Building_name__c))
        //         ? sa.Account.Building_name__c
        //         : 'Others';
            
        //     String street = (sa.Account != null && String.isNotBlank(sa.Account.Street__c))
        //         ? sa.Account.Street__c
        //         : 'Others';
            
        //     if (!groupedAppointments.containsKey(building)) {
        //         groupedAppointments.put(building, new List<ServiceAppointmentWrapper>());
        //     }
            
        //     groupedAppointments.get(building).add(new ServiceAppointmentWrapper(sa));
        //     if(mapBuildingServiceAppointments.containsKey(building)){
        //         mapBuildingServiceAppointments.get(building).add(sa);
        //     }else{
        //         mapBuildingServiceAppointments.put(building,new List<ServiceAppointment>{sa});
        //     }
        // }
        
        // Load and organize metadata
        List<Metering_Dashboard_Config__mdt> metaList = [
            SELECT Label__c, Field_API_Name__c, Values__c, Order__c,Card_Color__c,Icon_URL__c
            FROM Metering_Dashboard_Config__mdt
            WHERE Active__c = true and Department__c='O&M'
            ORDER BY Order__c ASC
        ];
        
        // Map<String,List<MeterReaderDashboardController.DataWrapper>> groupedAppointmentCounts = new Map<String,List<MeterReaderDashboardController.DataWrapper>>();
        // for(String key:groupedAppointments.keySet()){
        //     System.debug('### key: ' + key);
        //     groupedAppointmentCounts.put(key,MeterReaderDashboardController.getStatusByCount(mapBuildingServiceAppointments.get(key),metaList));
        // }
        
        // // List<MeterReaderDashboardController.DataWrapper> listDataWrapper=MeterReaderDashboardController.getStatusByCount(appointments,metaList);
        
        // System.debug('### Grouped Appointments (Final Response): ' + groupedAppointments);
        
       // ReturnWrapper result=new ReturnWrapper();
        // result.groupedAppointmentCounts=groupedAppointmentCounts;
        // result.groupedAppointments=groupedAppointments;
        // result.listServiceApp=listServiceApp;

      //  return appointments;
       // return result;

	         //  return lstServiceApp;

			return lstConnectionReturn;



    }
    catch(Exception e){

        system.debug('Error returning serviceappointments:::'+ e.getLineNumber() + e.getMessage());

        return new List<Connection__c>();
    }
    }
    
    public class ReturnWrapper{
        @AuraEnabled public Map<String,List<MeterReaderDashboardController.DataWrapper>> groupedAppointmentCounts;
        @AuraEnabled public Map<String, List<ServiceAppointmentWrapper>> groupedAppointments;
        @AuraEnabled public  List<ServiceAppointmentWrapper> listServiceApp;
    }
    
    public class ServiceAppointmentWrapper {
        @AuraEnabled public Id id;
        @AuraEnabled public String subject;
        @AuraEnabled public String meterNumber;
        @AuraEnabled public String accountName;
        @AuraEnabled public String status;
        @AuraEnabled public String visitStatus;
        @AuraEnabled public String schedStartTime;
        @AuraEnabled public String buildingName;
        @AuraEnabled public String buildingStreet;
        @AuraEnabled public String DetailAccountSummary;
        @AuraEnabled public String appointmentType;
        @AuraEnabled public String bpNumber; // New field
        @AuraEnabled public String customerFirstName; // New field
        @AuraEnabled public String customerLastName; // New field
        @AuraEnabled public String address; // New field
        
        public ServiceAppointmentWrapper(ServiceAppointment sa) {
            this.id = sa.Id;
            this.subject = sa.Subject;
            this.meterNumber = sa.Meter_Number__c;
            this.visitStatus = sa.Visit_Status__c;
            this.accountName = sa.Account != null ? sa.Account.Name : null;
            this.status = sa.Status;
            this.schedStartTime = sa.SchedStartTime.format('dd-MM-yyyy');
            this.appointmentType= String.isBlank(sa.Appointment_Type__c)?'Scheduled':sa.Appointment_Type__c;
            
            if (sa.Account != null) {
                this.buildingName = sa.Account.Building_name__c;
                this.buildingStreet= sa.Account.Street__c;
                this.bpNumber = sa.Account.BP_Number__c; // New field assignment
               this.customerFirstName = sa.Account.FirstName__c; // New field assignment
               this.customerLastName = sa.Account.LastName__c; // New field assignment

                this.address  = formatAddress(
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
    
    @AuraEnabled(cacheable=false)
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