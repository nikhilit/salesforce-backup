public without sharing class WorkOrderListViewController {

    public static String asFieldSenseFlowLabel = System.Label.AS_FieldSenseFlowLabel;
    public static String asGoCollectFlowLabel = System.Label.AS_GoCollectFlowLabel;
    public static Id rtId = Schema.SObjectType.ServiceTerritory.getRecordTypeInfosByDeveloperName().get('R_T').getRecordTypeId();

	public static List<String> workTypeName = getWorkTypeBasedOnFlow();

    public static List<String> getWorkTypeBasedOnFlow(){
        Id currentUserId = UserInfo.getUserId(); 

        //currentUserId = '005fs0000001r7CAAQ';//Muraree
        List<String> workTypeName = new List<String>();
        Boolean isDomestic = false;

		List<User> lstSTM = [SELECT Id, Title
            				   FROM User
               				  WHERE Id =: currentUserId
                                AND (Title = 'GoCollect AIC' OR Profile.Name = 'System Administrator')];
		isDomestic = !lstSTM.isEmpty();

        if(isDomestic){
            workTypeName = asGoCollectFlowLabel.split(','); 
        }else{
            workTypeName = asFieldSenseFlowLabel.split(','); 
        }

        return workTypeName;
    }
    
    // ---------------------------
    // Helper wrapper for paged results
    // ---------------------------
    public class PagedWorkOrders {
        @AuraEnabled public List<WorkOrder> records;
        @AuraEnabled public Integer totalSize;
    }
     @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getListViewColumns() {
        List<Map<String, String>> columnList = new List<Map<String, String>>();
        for (Work_Order_List_View__mdt mdt : [
            SELECT FieldName__c, Type__c, Label__c 
            FROM Work_Order_List_View__mdt
        ]) {
            columnList.add(new Map<String, String>{
                'fieldName' => mdt.FieldName__c,
                'type' => mdt.Type__c,
                'label' => mdt.Label__c
            });
        }
        return columnList;
    }
    // ---------------------------
    // Basic lookups
    // ---------------------------
    @AuraEnabled(cacheable=true)
    public static List<ServiceTerritory> getAllAgencies() {
        
        return [
            SELECT Id, Name
            FROM ServiceTerritory
            WHERE IsActive = TRUE AND RecordTypeId = :rtId
            ORDER BY Name
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<ServiceTerritoryMember> getAllAgents() {
        return [
            SELECT Id, ServiceTerritoryId, ServiceResourceId, ServiceResource.RelatedRecord.Name
            FROM ServiceTerritoryMember
            WHERE ServiceTerritory.RecordTypeId = :rtId
            ORDER BY ServiceResource.RelatedRecord.Name
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<ServiceTerritoryMember> getAgentsByAgency(Id agencyId) {
        if (agencyId == null) return new List<ServiceTerritoryMember>();
        return [
            SELECT Id, ServiceTerritoryId, ServiceResourceId, ServiceResource.RelatedRecord.Name
            FROM ServiceTerritoryMember
            WHERE ServiceTerritoryId = :agencyId
              AND ServiceTerritory.RecordTypeId = :rtId
            ORDER BY ServiceResource.RelatedRecord.Name
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<ServiceTerritory> getAgenciesByAgent(Id agentServiceResourceId) {
        if (agentServiceResourceId == null) return new List<ServiceTerritory>();
        return [
            SELECT Id, Name
            FROM ServiceTerritory
            WHERE Id IN (
                SELECT ServiceTerritoryId
                FROM ServiceTerritoryMember
                WHERE ServiceResourceId = :agentServiceResourceId
            )
            ORDER BY Name
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<WorkType> getWorkTypes() {
        return [SELECT Id, Name FROM WorkType WHERE Name IN :workTypeName ORDER BY Name];
    }

    // ---------------------------
    // Paginated & filtered work orders
    // ---------------------------
    @AuraEnabled(cacheable=true)
    public static PagedWorkOrders getFilteredWorkOrders(
        Integer pageSize,
        Integer pageNumber,
        Decimal invoiceFrom,
        Decimal invoiceTo,
        String location,
        String status,
        String pinCode,
        Id agencyId,
        Id agentServiceResourceId,
        String activityType
    ) {
        if (pageSize == null || pageSize <= 0) pageSize = 10;
        if (pageNumber == null || pageNumber <= 0) pageNumber = 1;

        // Base where clause: record type developer name MGL_R_T
        String whereClause = ' WHERE RecordType.DeveloperName = \'MGL_R_T\'';

        if (invoiceFrom != null) {
            whereClause += ' AND Account.Inv_No__c >= \'' + String.valueOf(invoiceFrom) + '\'';
        }
        if (invoiceTo != null) {
            whereClause += ' AND Account.Inv_No__c <= \'' + String.valueOf(invoiceTo) + '\'';
        }
        if (!String.isBlank(location)) {
            whereClause += ' AND Account.Location__c LIKE \'%' + String.escapeSingleQuotes(location) + '%\'';
        }
        if (!String.isBlank(status)) {
            whereClause += ' AND Appointment_Status__c = \'' + String.escapeSingleQuotes(status) + '\'';
        }
        if (!String.isBlank(pinCode)) {
            whereClause += ' AND Account.Postal_Code__c LIKE \'%' + String.escapeSingleQuotes(pinCode) + '%\'';
        }
        if (agencyId != null) {
            whereClause += ' AND R_T_Agency__c = \'' + String.escapeSingleQuotes(String.valueOf(agencyId)) + '\'';
        }
        if (!String.isBlank(activityType)) {
            whereClause += ' AND WorkTypeId = \'' + String.escapeSingleQuotes(activityType) + '\'';
        }else{
			whereClause += ' AND WorkType.Name IN :workTypeName';
		}
        if (agentServiceResourceId != null) {
            // WorkOrders linked to Agent via Agent__c (assuming Agent__c stores ServiceResource.RelatedRecordId or ServiceResourceId)
            // Attempt two checks: if Agent__c stores ServiceResource (custom) or RelatedRecordId
            //whereClause += ' AND (Agent__c = \'' + String.escapeSingleQuotes(String.valueOf(agentServiceResourceId)) + '\' OR Agent__c IN (SELECT RelatedRecordId FROM ServiceResource WHERE Id = \'' + String.escapeSingleQuotes(String.valueOf(agentServiceResourceId)) + '\'))';
			whereClause += ' AND Agent__c = \'' + String.escapeSingleQuotes(agentServiceResourceId) + '\'';
        }

        // Build count query
        String countQuery = 'SELECT count() FROM WorkOrder' + whereClause;
        Integer totalSize = 0;

		System.debug('=========countQuery========>'+countQuery);

        try {
			totalSize = Database.countQuery(countQuery);
		} catch (Exception ex) {
			// Optional fallback if you’re not sure countQuery is valid for countQuery
			AggregateResult[] ar = Database.query(countQuery);
			if (!ar.isEmpty()) {
				totalSize = (Integer)ar[0].get('expr0');
			}
		}

        // Build select fields - include required fields
        String selectClause = 'SELECT Id, WorkOrderNumber, Account.Inv_No__c, Account.Location__c, Account.Road_Name__c, Account.Postal_Code__c,Location__c, '+
									 'R_T_Agency__r.Name,Overdue__c,Batch_lot__c,Agency_Name_Formula__c,Customer_Full_Name__c,End_Date__c,Due_Amount__c,BP_Number__c,CreatedDate, R_T_Agency__c, Agent__c, WorkType.Name, WorkTypeId, StartDate, '+
									 'EndDate, AccountId, Agent__r.Name, Appointment_Status__c';

        Integer offsetRows = (pageNumber - 1) * pageSize;
        String orderClause = ' ORDER BY CreatedDate DESC LIMIT ' + String.valueOf(pageSize) + ' OFFSET ' + String.valueOf(offsetRows);

        String finalQuery = selectClause + ' FROM WorkOrder' + whereClause + orderClause;

		System.debug('=========finalQuery========>'+finalQuery);

        List<WorkOrder> results = new List<WorkOrder>();
        if (!String.isBlank(finalQuery)) {
            results = Database.query(finalQuery);
        }

		System.debug('=========results========>'+results);
		System.debug('=========totalSize========>'+totalSize);

        PagedWorkOrders pw = new PagedWorkOrders();
        pw.records = results;
        pw.totalSize = totalSize;
        return pw;
    }

    // ---------------------------
    // Assignment logic
    // ---------------------------
	@AuraEnabled
    public static void assignAgency(
        List<Id> workOrderIds,
        Id agencyId,
        Id agentId,
        Id workTypeId,
        Datetime startDate,
        Datetime endDate
    ) {
        try {

			System.debug('=========agencyId========>'+agencyId);
			System.debug('=========agentId========>'+agentId);
			System.debug('=========workOrderIds========>'+workOrderIds);
			System.debug('=========workTypeId========>'+workTypeId);
			System.debug('=========startDate========>'+startDate);
			System.debug('=========endDate========>'+endDate);

            if (workOrderIds == null || workOrderIds.isEmpty()) {
                throw new AuraHandledException('No WorkOrder IDs provided.');
            }

            if (agencyId == null || agentId == null || workTypeId == null || startDate == null || endDate == null) {
                throw new AuraHandledException('All fields are required.');
            }

            // Get Contractor
            Id contractorUserId = [SELECT RelatedRecordId
                                     FROM ServiceResource
                                    WHERE Agency__c = :agencyId 
                                      AND Service_Resource_Type__c = 'Contractor'
                                    LIMIT 1].RelatedRecordId;

			System.debug('=========contractorUserId========>'+contractorUserId);

            List<WorkOrder> workOrdersToUpdate = new List<WorkOrder>();
            List<ServiceAppointment> appointments = new List<ServiceAppointment>();
            Map<Id, Id> workOrderToAppointmentMap = new Map<Id, Id>();
            Map<Id, ServiceAppointment> saMap = new Map<Id, ServiceAppointment>();

            List<WorkOrder> workOrders = [SELECT Id, AccountId, Due_Amount__c,
                                                 Account.PersonContactId 
                                            FROM WorkOrder 
                                           WHERE Id IN :workOrderIds];

			System.debug('=========workOrders========>'+workOrders);

            for (WorkOrder wOrder : workOrders) {

                // Get Contact ID from related Account
                Id contactId;
                if (wOrder.Account.PersonContactId != null) {
                    contactId = wOrder.Account.PersonContactId;
                }

                // Update Work Order
                WorkOrder wo = new WorkOrder(
                    Id = wOrder.Id,
                    R_T_Agency__c = agencyId,
                    Agent__c = agentId,
                    WorkTypeId = workTypeId, 
                    StartDate = startDate,
                    EndDate = endDate,
                    OwnerId = contractorUserId,
                    Assiged_to_Agency__c = true
                );
                workOrdersToUpdate.add(wo);

            
                // Create or update Service Appointment
                ServiceAppointment sa = new ServiceAppointment(
                    ParentRecordId = wOrder.Id,
                    ServiceTerritoryId = agencyId,
                    WorkTypeId = workTypeId,
                    EarliestStartTime = startDate,
                    ContactId = contactId,
                    DueDate = endDate,
                    Status = 'In Progress',
                    SchedStartTime = startDate,
                    SchedEndTime = endDate,
                    Due_Amount__c = wOrder.Due_Amount__c
                );
                saMap.put(wOrder.Id, sa);
            }

			System.debug('=========workOrdersToUpdate========>'+workOrdersToUpdate);
			System.debug('=========saMap========>'+saMap);

            // Update Work Orders
            update workOrdersToUpdate;

            //Delete existing ServiceAppointments (if any)
            delete [SELECT Id FROM ServiceAppointment WHERE ParentRecordId IN :workOrderIds];

            upsert saMap.values();

            List<AssignedResource> assignedResources = new List<AssignedResource>();

            for (Id woId : workOrderIds) {
                if (saMap.containsKey(woId)) {
                    AssignedResource ar = new AssignedResource(
                        ServiceAppointmentId = saMap.get(woId).Id,
                        ServiceResourceId = agentId
                    );
                    assignedResources.add(ar);
                }
            }

            //insert assignedResources;

        } catch (Exception e) {

            AS_ErrorLogger.log('AS_AgencyAssignmentController', 'assignAgency', e, workOrderIds.get(0));
        }
    }

    // @AuraEnabled
    // public static void assignAgency(
    //     List<Id> workOrderIds,
    //     Id agencyId,
    //     Id agentServiceResourceId,
    //     Id workTypeId,
    //     Date startDate,
    //     Date endDate
    // ) {
    //     if (workOrderIds == null || workOrderIds.isEmpty()) {
    //         throw new AuraHandledException('No WorkOrder IDs provided.');
    //     }
    //     if (agencyId == null) {
    //         throw new AuraHandledException('Agency is required.');
    //     }
    //     if (agentServiceResourceId == null) {
    //         throw new AuraHandledException('Agent is required.');
    //     }
    //     if (workTypeId == null) {
    //         throw new AuraHandledException('Work Type is required.');
    //     }
    //     if (startDate == null || endDate == null) {
    //         throw new AuraHandledException('Start and End Date are required.');
    //     }
    //     if (startDate > endDate) {
    //         throw new AuraHandledException('Start Date cannot be after End Date.');
    //     }

    //     // 1) Find contractor user (to set OwnerId)
    //     Id contractorUserId = null;
    //     List<ServiceResource> contractors = [
    //         SELECT RelatedRecordId
    //         FROM ServiceResource
    //         WHERE Agency__c = :agencyId AND Service_Resource_Type__c = 'Contractor'
    //         LIMIT 1
    //     ];
    //     if (!contractors.isEmpty()) contractorUserId = contractors[0].RelatedRecordId;

    //     // 2) Query WorkOrders with Account info
    //     List<WorkOrder> wos = [
    //         SELECT Id, AccountId, WorkTypeId, StartDate, EndDate
    //         FROM WorkOrder
    //         WHERE Id IN :workOrderIds
    //         FOR UPDATE
    //     ];

    //     // 3) Update WorkOrders (using partial sObject updates)
    //     List<WorkOrder> wosToUpdate = new List<WorkOrder>();
    //     for (WorkOrder wo : wos) {
    //         WorkOrder u = new WorkOrder(Id = wo.Id);
    //         u.R_T_Agency__c = agencyId;
    //         u.Agent__c = agentServiceResourceId;
    //         u.WorkTypeId = workTypeId;
    //         u.StartDate = startDate;
    //         u.EndDate = endDate;
    //         u.Assiged_to_Agency__c = true;
    //         if (contractorUserId != null) u.OwnerId = contractorUserId;
    //         wosToUpdate.add(u);
    //     }
    //     if (!wosToUpdate.isEmpty()) update wosToUpdate;

    //     // 4) Delete existing ServiceAppointment and AssignedResource children for these WorkOrders
    //     List<ServiceAppointment> existingSAs = [
    //         SELECT Id
    //         FROM ServiceAppointment
    //         WHERE ParentRecordId IN :workOrderIds
    //     ];
    //     if (!existingSAs.isEmpty()) {
    //         // delete AssignedResource children explicitly (safer)
    //         List<Id> saIds = new List<Id>();
    //         for (ServiceAppointment sa : existingSAs) saIds.add(sa.Id);

    //         List<AssignedResource> arsToDelete = [SELECT Id FROM AssignedResource WHERE ServiceAppointmentId IN :saIds];
    //         if (!arsToDelete.isEmpty()) delete arsToDelete;

    //         delete existingSAs;
    //     }

    //     // 5) Create new ServiceAppointments (and capture created records for AssignedResource creation)
    //     List<ServiceAppointment> sasToInsert = new List<ServiceAppointment>();
    //     for (WorkOrder wo : wos) {
    //         // derive ContactId from Account (prefer PersonContactId then custom Contact__c)
    //         Id contactId = null;
    //         if (wo.AccountId != null) {
    //             Account a = [SELECT Id, PersonContactId FROM Account WHERE Id = :wo.AccountId LIMIT 1];
    //             if (a.PersonContactId != null) contactId = a.PersonContactId;
    //             //else if (a.get('Contact__c') != null) contactId = (Id)a.get('Contact__c');
    //         }

    //         // convert Date -> Datetime for EarliestStartTime and DueDate
    //         Datetime earliest = Datetime.newInstance(startDate.year(), startDate.month(), startDate.day(), 9, 0, 0);
    //         Datetime due = Datetime.newInstance(endDate.year(), endDate.month(), endDate.day(), 17, 0, 0);

    //         ServiceAppointment sa = new ServiceAppointment();
    //         //sa.WorkOrderId = wo.Id;
    //         sa.Status = 'Scheduled';
    //         sa.ServiceTerritoryId = agencyId;
    //         sa.WorkTypeId = workTypeId;
    //         sa.EarliestStartTime = earliest;
    //         sa.DueDate = due;
    //         sa.ContactId = contactId;
    //         //sa.AppointmentNumber = 'Auto-' + String.valueOf(Datetime.now().getTime());
    //         sasToInsert.add(sa);
    //     }

    //     if (!sasToInsert.isEmpty()) insert sasToInsert;

    //     // 6) Create AssignedResource entries linking agentServiceResourceId to the new ServiceAppointments
    //     List<AssignedResource> arsToInsert = new List<AssignedResource>();
    //     if (!sasToInsert.isEmpty()) {
    //         for (ServiceAppointment s : sasToInsert) {
    //             AssignedResource ar = new AssignedResource();
    //             ar.ServiceAppointmentId = s.Id;
    //             ar.ServiceResourceId = agentServiceResourceId;
    //             //ar.AssignmentStatus = 'Scheduled';
    //             // set estimated times
    //             //ar.EstimatedStartTime = s.EarliestStartTime;
    //             //ar.EstimatedEndTime = s.DueDate;
    //             //ar.AllocationPercent = 100;
    //             arsToInsert.add(ar);
    //         }
    //         insert arsToInsert;
    //     }

    //     // 7) WorkPlan creation: cannot be performed via Apex directly using WorkPlanTemplate (WorkPlan.WorkPlanTemplateId is read-only).
    //     // Recommend adding an after-insert Flow on ServiceAppointment to create WorkPlan(s) from WorkPlanTemplate for inserted SAs.
    // }
}