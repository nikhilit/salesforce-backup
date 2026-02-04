/**
 * @File Name : AS_AgencyAssignmentController.cls
 * @Description :
 * @Author :
 * @Last Modified By :
 * @Last Modified On : August 8, 2025
 * @Modification Log :
 *==============================================================================
 * Ver | Date | Author | Modification
 *==============================================================================
 * 1.0 | August 8, 2025 |   | Initial Version
 **/

public without sharing class AS_AgencyAssignmentController {
    
    public static String asFieldSenseFlowLabel = System.Label.AS_FieldSenseFlowLabel;
    public static String asGoCollectFlowLabel = System.Label.AS_GoCollectFlowLabel;
    public static String asDomesticProfileName = System.Label.AS_FieldAgentDomesticProfile;
    public static Id rtId = Schema.SObjectType.ServiceTerritory.getRecordTypeInfosByDeveloperName().get('R_T').getRecordTypeId();
    
    public static List<String> workTypeName = getWorkTypeBasedOnFlow();
    
    // Commented by Aliyaj
    // public static List<String> getWorkTypeBasedOnFlow(){
        //     Id currentUserId = UserInfo.getUserId();
        
        //     //currentUserId = '005fs0000001r7CAAQ';//Muraree
        //     List<String> workTypeName = new List<String>();
        //     Boolean isDomestic = false;
        
        // 	List<User> lstSTM = [SELECT Id, Title
    //         				   FROM User
    //            				  WHERE Id =: currentUserId
    //                             AND (Title = 'GoCollect AIC' OR Profile.Name = 'System Administrator')];
        // 	isDomestic = !lstSTM.isEmpty();
        
        //     if(isDomestic){
            //         workTypeName = asGoCollectFlowLabel.split(',');
        //     }else{
            //         workTypeName = asFieldSenseFlowLabel.split(',');
        //     }
        
        //     return workTypeName;
    // }
    // ends here
    
    // Changes by Aliyaj
    public static List<String> getWorkTypeBasedOnFlow() {
        
        Id currentUserId = UserInfo.getUserId();
        
        // Query Role: Admin OR Domestic AIC
        User u = [
            SELECT Id, Title, Profile.Name
            FROM User
            WHERE Id = :currentUserId
            LIMIT 1
        ];
        
        // CASE 1: Admin → return ALL work types
        if (u.Profile.Name == 'System Administrator') {
            List<String> allWorkTypes = new List<String>();
            allWorkTypes.addAll(asGoCollectFlowLabel.split(','));
            allWorkTypes.addAll(asFieldSenseFlowLabel.split(','));
            return allWorkTypes;
        }
        
        // CASE 2: Domestic user → return only Domestic work types
        if (u.Profile.Name == asDomesticProfileName) {
            return asGoCollectFlowLabel.split(',');
        }
        
        // CASE 3: Everyone else → return FieldSense work types
        return asFieldSenseFlowLabel.split(',');
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getSettings() {
        
        List<Map<String, String>> results = new List<Map<String, String>>();
        
        try{
            List<MGL_Setting__mdt> settings = [
                SELECT Supported_Fields__c,Supported_Objects__c,Expected_Value_Mappings__c
                FROM MGL_Setting__mdt
                WHERE DeveloperName = 'FS_WorkOrder_Allocation'
                LIMIT 1
            ];
            
            if (settings.isEmpty() || String.isBlank(settings[0].Supported_Fields__c)) {
                return results;
            }
            
            MGL_Setting__mdt settingRec = settings[0];
            
            // Split comma-separated API names
            List<String> fieldApiList = new List<String>();
            for (String f : settingRec.Supported_Fields__c.split(',')) {
                if (!String.isBlank(f)) fieldApiList.add(f.trim());
            }
            
            System.debug('fieldApiList: '+fieldApiList);
            
            // // Describe WorkOrder object
            Map<String,Schema.SObjectField> fieldMap = Schema.WorkOrder.SObjectType.getDescribe().fields.getMap();
            
            // // Loop API names → Get Label → Build return list
            for (String apiName : fieldApiList) {
                
                Schema.DescribeFieldResult fieldDescribe;
                String label;
                String fieldType;
                // Handle relationship fields (Parent.Field)
                if (apiName.contains('.')) {
                    List<String> parts = apiName.split('\\.');
                    
                    Schema.DescribeSObjectResult currentObj =
                        Schema.WorkOrder.SObjectType.getDescribe();
                    
                    Schema.DescribeFieldResult finalFieldDescribe;
                    
                    for (Integer i = 0; i < parts.size(); i++) {
                        String part = parts[i];
                        
                        // LAST PART → actual field (Name, CreatedDate, etc.)
                        if (i == parts.size() - 1) {
                            Map<String, Schema.SObjectField> fMap =
                                currentObj.fields.getMap();
                            
                            if (!fMap.containsKey(part)) {
                                finalFieldDescribe = null;
                                break;
                            }
                            
                            finalFieldDescribe = fMap.get(part).getDescribe();
                        }
                        // INTERMEDIATE PART → relationship name (WorkType, Account, Owner)
                        else {
                            Boolean relationshipFound = false;
                            
                            for (Schema.SObjectField f : currentObj.fields.getMap().values()) {
                                Schema.DescribeFieldResult d = f.getDescribe();
                                
                                if (d.getType() == Schema.DisplayType.REFERENCE &&
                                d.getRelationshipName() == part) {
                                    
                                    // Move to referenced object
                                    currentObj = d.getReferenceTo()[0].getDescribe();
                                    relationshipFound = true;
                                    break;
                                }
                            }
                            
                            if (!relationshipFound) {
                                finalFieldDescribe = null;
                                break;
                            }
                        }
                    }
                    
                    if (finalFieldDescribe != null) {
                        results.add(new Map<String, String>{
                            'label'   => finalFieldDescribe.getLabel(),
                            'value'   => apiName.replace('.', '_'), // 👈 datatable-safe
                            'apiPath' => apiName,                   // 👈 original relationship path
                            'type'    => String.valueOf(finalFieldDescribe.getType())
                        });
                    }
                }
                
                // Handle direct fields
                else if (fieldMap.containsKey(apiName)) {
                    fieldDescribe = fieldMap.get(apiName).getDescribe();
                    label = fieldDescribe.getLabel();
                    fieldType = String.valueOf(fieldDescribe.getType());
                }
                
                System.debug('label: '+label);
                System.debug('apiName: '+apiName);
                
                if (fieldDescribe != null) {
                    results.add(new Map<String, String>{
                        'label' => label,
                        'value' => apiName,
                        'type'  => fieldType
                    });
                }
            }
            if (!String.isBlank(settingRec.Supported_Objects__c)) {
                Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
                for (String objApi : settingRec.Supported_Objects__c.split(',')) {
                    objApi = objApi.trim();
                    if (String.isBlank(objApi))
                        continue;
                    if (!gd.containsKey(objApi))
                        continue;
                    Schema.DescribeSObjectResult d = gd.get(objApi).getDescribe();
                    results.add(new Map<String, String>{ 'label' => d.getLabel(), // Object Label
                        'value' => objApi, // Object API Name
                        'type' => 'OBJECT' // distinguish if needed
                    });
                }
            }
            
            
        }catch(Exception e){
            AS_ErrorLogger.log('AS_AgencyAssignmentController', 'getSettings', e, null);
            return results;
        }
        
        return results;
    }
    
    
    // ---------------------------
    // Helper wrapper for paged results
    // ---------------------------
    public class PagedWorkOrders {
        @AuraEnabled public List<WorkOrder> records;
        @AuraEnabled public Integer totalSize;
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
    @AuraEnabled(cacheable=false)
    public static PagedWorkOrders getFilteredWorkOrders(
        Integer pageSize,
    Integer pageNumber,
    Date invoiceFrom,
    Date invoiceTo,
    Integer fromHour,
    Integer fromMin,
    Integer toHour,
    Integer toMin,
    String meterNumber,
    String bpNumber,
    String caNumber,
    String installationNumber,
    String status,
    String pinCode,
    Id agencyId,
    String deviceNo,
    String groupBy,
    String mrNote,
    String message,
    String portion,
    Id agentServiceResourceId,
    String activityType
    ) {
        if (pageSize == null || pageSize <= 0) pageSize = 10;
        if (pageNumber == null || pageNumber <= 0) pageNumber = 1;
        
        // Base where clause: record type developer name MGL_R_T
        String whereClause = ' WHERE RecordType.DeveloperName = \'MGL_R_T\' ';
        
        // Commented by Aliyaj
        // if (invoiceFrom != null) {
            //     whereClause += ' AND Account.Inv_No__c >= \'' + String.valueOf(invoiceFrom) + '\'';
        // }
        // if (invoiceTo != null) {
            //     whereClause += ' AND Account.Inv_No__c <= \'' + String.valueOf(invoiceTo) + '\'';
        // }
        // if (!String.isBlank(location)) {
            //     whereClause += ' AND Account.Location__c LIKE \'%' + String.escapeSingleQuotes(location) + '%\'';
        // }
        // if (!String.isBlank(pinCode)) {
            //     whereClause += ' AND Account.Postal_Code__c LIKE \'%' + String.escapeSingleQuotes(pinCode) + '%\'';
        // }
        // ends here

        DateTime fromDateTime;
        DateTime toDateTime;

        Boolean hasFromTime = (fromHour != null || fromMin != null);
        Boolean hasToTime   = (toHour != null || toMin != null);

        if (invoiceFrom != null) {
            Integer fh = (fromHour != null) ? fromHour : 0;
            Integer fm = (fromMin != null) ? fromMin : 0;
            fromDateTime = DateTime.newInstance(
                invoiceFrom,
                Time.newInstance(fh, fm, 0, 0)
            );
        }

        if (invoiceTo != null) {
            Integer th = (toHour != null) ? toHour : 23;
            Integer tm = (toMin != null) ? toMin : 59;
            toDateTime = DateTime.newInstance(
                invoiceTo,
                Time.newInstance(th, tm, 59, 999)
            );
        }

        if (invoiceFrom != null && invoiceTo != null) {

            if (hasFromTime || hasToTime) {
                // Date + Time comparison
                whereClause += ' AND (StartDate <= :toDateTime AND EndDate >= :fromDateTime)';
            } else {
                // Date-only comparison (your original logic)
                whereClause += ' AND (DAY_ONLY(StartDate) <= :invoiceTo AND DAY_ONLY(EndDate) >= :invoiceFrom)';
            }

        } else if (invoiceFrom != null) {

            if (hasFromTime) {
                whereClause += ' AND EndDate >= :fromDateTime';
            } else {
                whereClause += ' AND DAY_ONLY(EndDate) >= :invoiceFrom';
            }

        } else if (invoiceTo != null) {

            if (hasToTime) {
                whereClause += ' AND StartDate <= :toDateTime';
            } else {
                whereClause += ' AND DAY_ONLY(StartDate) <= :invoiceTo';
            }
        }


        if (!String.isBlank(meterNumber)) {
            whereClause += ' AND Meter_No_SR__c LIKE \'%' + String.escapeSingleQuotes(meterNumber) + '%\'';
        }
        if (!String.isBlank(bpNumber)) {
            whereClause += ' AND Account.BP_Number__c LIKE \'%' + String.escapeSingleQuotes(bpNumber) + '%\'';
        }

        if (!String.isBlank(caNumber)) {
            whereClause += ' AND Customer_CA_Number__c LIKE \'%' + String.escapeSingleQuotes(caNumber) + '%\'';
        }

        if (!String.isBlank(installationNumber)) {
            whereClause += ' AND Installation__c LIKE \'%' + String.escapeSingleQuotes(installationNumber) + '%\'';
        }
        
        if (!String.isBlank(deviceNo)) {
            whereClause += ' AND Device_Number__c = \'' + String.escapeSingleQuotes(deviceNo) + '\'';
        }
        if (!String.isBlank(groupBy)) {
            whereClause += ' AND Group_Master__c = \'' + String.escapeSingleQuotes(groupBy) + '\'';
        }

        if (!String.isBlank(mrNote)) {
            whereClause += ' AND Group_Code__c = \'' + String.escapeSingleQuotes(mrNote) + '\'';
        }

        if (!String.isBlank(message)) {
            whereClause += ' AND Group_Message__c = \'' + String.escapeSingleQuotes(message) + '\'';
        }

        if (!String.isBlank(portion)) {
            whereClause += ' AND Billing_portion__c LIKE \'%' + String.escapeSingleQuotes(portion) + '%\'';
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
        
        // Commented by Aliyaj
        // Build select fields - include required fields
        // String selectClause = 'SELECT Id, WorkOrderNumber, Account.Inv_No__c, Account.Location__c, Account.Road_Name__c, Account.Postal_Code__c, '+
        // 							 'R_T_Agency__r.Name, R_T_Agency__c, Agent__c, WorkType.Name, WorkTypeId, StartDate, '+
        // 							 'EndDate, AccountId, Agent__r.Name, Appointment_Status__c';
        // ends here
        String selectClause = 'SELECT Id,Customer_CA_Number__c,Account.BP_Number__c,Account.Name, Area__c,Bill_Date__c,Outstanding_Amount__c,'+
            'Old_Mobile_Number__c,Email_ID__c,Billing_portion__c,MRU__c,Meter_No_SR__c,Invoice__c,Start_Date__c,End_Date__c,'+
            'New_Mobile_Number__c,New_Email__c,Attempt_Count__c,WorkOrderNumber, Payment_Type__c,New_Location__c,Phone__c,Follow_up_Date__c,'+
            'New_Road_Name__c, Postal_Code__c,Address,Remarks__c,Check_In_Location__latitude__s, Check_In_Location__longitude__s,'+
            'Agency_Name_Formula__c, R_T_Agency__c, Agent__c, WorkType.Name, WorkTypeId, StartDate,Due_Amount__c,Payment_Date__c,'+
            'EndDate, AccountId, Agent_ID__c,Agent_Name_Formula__c,GA_Wise__c,R_T_Agency__r.Agency_Code__c, Appointment_Status__c, Check_In_Date_Time__c,'+
            'Payment_Mode__c, ImageUrl1__c, ImageUrl2__c, ImageUrl3__c,ImageUrl4__c,ImageUrl5__c,Amount_Received__c,'+
            '(SELECT Check_In_Timestamp__c FROM ServiceAppointments),(SELECT Bank_Name__c,Cheque_Date__c,Cheque_Number__c,Cheque_Amount__c from Payments__r order by CreatedDate desc limit 1)' ;
        
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
        Savepoint sp = Database.setSavepoint();
        try {
            
            System.debug('=========agencyId========>'+agencyId);
            System.debug('=========agentId========>'+agentId);
            System.debug('=========workOrderIds========>'+workOrderIds);
            // System.debug('=========workTypeId========>'+workTypeId);
            System.debug('=========startDate========>'+startDate);
            System.debug('=========endDate========>'+endDate);
            
            if (workOrderIds == null || workOrderIds.isEmpty()) {
                throw new AuraHandledException('No WorkOrder IDs provided.');
            }
            
            if (agencyId == null || agentId == null || startDate == null || endDate == null) {
                throw new AuraHandledException('All fields are required.');
            }

            ServiceResource agent = [SELECT Id, Agent_ID__c, RelatedRecordId FROM ServiceResource WHERE Id =: agentId];
            
            // Get Contractor
            Id contractorUserId = [SELECT RelatedRecordId
                                     FROM ServiceResource
                                    WHERE Agency__c = :agencyId 
                                      AND Service_Resource_Type__c = 'Contractor'
                                    LIMIT 1].RelatedRecordId;
            
            System.debug('=========contractorUserId========>'+contractorUserId);
            
            List<WorkOrder> workOrdersToUpdate = new List<WorkOrder>();
            Map<Id, ServiceAppointment> saMap = new Map<Id, ServiceAppointment>();
            
            Map<Id, Id> workOrderToAgent = new Map<Id, Id>();
            Map<Id, Id> workOrderToAllocatedAgent = new Map<Id, Id>();
            
            // Get Work Orders
            Map<Id, WorkOrder> workOrders =new Map<Id,WorkOrder>([SELECT Id, AccountId, Due_Amount__c,
                                                 Account.PersonContactId, Agent__c, Agent__r.RelatedRecordId
                                            FROM WorkOrder 
                                           WHERE Id IN :workOrderIds AND Status != 'Completed' ]);

            if(workOrders.isEmpty()) return;

            Map<Id, ServiceAppointment> existingSAs = new Map<Id, ServiceAppointment>();
            Set<Id> saIds = new Set<Id>();
            for (ServiceAppointment sa : [
                SELECT Id, ParentRecordId
                FROM ServiceAppointment
                WHERE ParentRecordId IN :workOrders.keySet()
            ]) {
                existingSAs.put(sa.ParentRecordId, sa);
                saIds.add(sa.Id);
            }
            
            System.debug('=========workOrders========>'+workOrders);
            
            for (WorkOrder wOrder : workOrders.values()) {
                if (wOrder.Agent__r.RelatedRecordId != null) {
                    Id withdrawnUserId = wOrder.Agent__r.RelatedRecordId;
                    workOrderToAgent.put(wOrder.Id, withdrawnUserId);
                }

                workOrderToAllocatedAgent.put(wOrder.Id, agent.RelatedRecordId);

                // Get Contact ID from related Account
                Id contactId;
                if (wOrder.Account.PersonContactId != null) {
                    contactId = wOrder.Account.PersonContactId;
                }
                
                // Update Work Order
                WorkOrder wo = new WorkOrder(
                    Id = wOrder.Id,
                    R_T_Agency__c = agencyId,
                    Agent_ID__c = agent.Agent_ID__c,
                    Agent__c = agentId,
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
                    EarliestStartTime = startDate,
                    ContactId = contactId,
                    DueDate = endDate,
                    SchedStartTime = startDate,
                    SchedEndTime = endDate,
                    Due_Amount__c = wOrder.Due_Amount__c,
                    Status = 'In Progress'
                );

                if (existingSAs.containsKey(wOrder.Id)) {
                    ServiceAppointment existingSA = existingSAs.get(wOrder.Id);
                    sa.Id = existingSA.Id;
                }

                saMap.put(wOrder.Id, sa);
            }
            
            System.debug('=========workOrdersToUpdate========>'+workOrdersToUpdate);
            System.debug('=========saMap========>'+saMap);
            
            // Update Work Orders
            if(!workOrdersToUpdate.isEmpty()){
                update workOrdersToUpdate;
            }
            
            // upsert saMap.values();
            if(!saMap.isEmpty()){
                upsert saMap.values();
            }

            
            Map<Id, AssignedResource> arBySA = new Map<Id, AssignedResource>();

            for (AssignedResource ar : [
                SELECT Id, ServiceAppointmentId
                FROM AssignedResource
                WHERE ServiceAppointmentId IN :saIds
            ]) {
                arBySA.put(ar.ServiceAppointmentId, ar);
            }

            List<AssignedResource> arsToUpdate = new List<AssignedResource>();

            for(AssignedResource ar : arBySA.values()){
                arsToUpdate.add(new AssignedResource(
                    Id = ar.Id,
                    ServiceResourceId = agentId
                ));
            }

            if (!arsToUpdate.isEmpty()) {
                update arsToUpdate;
            } 

            if(!workOrderToAgent.isEmpty()){
                withdrawNotification(workOrderToAgent); 
            }

            if(!workOrderToAllocatedAgent.isEmpty()){
                assignNotification(workOrderToAllocatedAgent);
            }
        } catch (Exception e) {
            Database.rollback(sp);
            String recordId = workOrderIds != null && !workOrderIds.isEmpty() ? workOrderIds[0] : null;
            AS_ErrorLogger.log('AS_AgencyAssignmentController', 'assignAgency', e, recordId);
            throw e;
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getChildFields(String objectApiName) {
        List<String> result = new List<String>();
        
        if (String.isBlank(objectApiName)) {
            return result;
        }
        
        MGL_Setting__mdt setting = [
            SELECT Expected_Value_Mappings__c
            FROM MGL_Setting__mdt
            WHERE DeveloperName = 'FS_WorkOrder_Allocation'
            LIMIT 1
        ];
        
        if (String.isBlank(setting.Expected_Value_Mappings__c)) {
            return result;
        }
        
        Map<String, Object> mappings =
            (Map<String, Object>) JSON.deserializeUntyped(setting.Expected_Value_Mappings__c);
        
        if (!mappings.containsKey(objectApiName)) {
            return result;
        }
        
        for (Object fieldObj : (List<Object>) mappings.get(objectApiName)) {
            result.add(String.valueOf(fieldObj));
        }
        
        return result;
    }

    @AuraEnabled
    public static void withdrawAllocations(List<Id> workOrderIds) {
		try{
            Map<Id, Id> workOrderToAgent = new Map<Id, Id>();

			List<WorkOrder> workOrdersToUpdate = [SELECT Id, Remarks__c, Agent__c, R_T_Agency__c, Agent__r.RelatedRecordId
													FROM WorkOrder 
												   WHERE Id IN :workOrderIds 
												     AND Record_Type_Developer_Name__c = 'MGL_R_T'];

			for (WorkOrder wo : workOrdersToUpdate) {
                if (wo.Agent__c != null && wo.Agent__r.RelatedRecordId != null) {
                    workOrderToAgent.put(wo.Id, wo.Agent__r.RelatedRecordId);
                }
				wo.Agent__c = null;
				wo.R_T_Agency__c = null;
                wo.Agent_ID__c = null;
			}
 
			if (!workOrdersToUpdate.isEmpty()) {
                update workOrdersToUpdate;
            }

            if (!workOrderToAgent.isEmpty()) {
                withdrawNotification(workOrderToAgent);
            }
		} catch (Exception ex) {
            AS_ErrorLogger.log('AS_AgencyAssignmentController', 'withdrawAllocations', ex, '');
        }
    }


    public static void withdrawNotification(Map<Id, Id> workOrderToAgent){

            CustomNotificationType notificationType =
                [SELECT Id, DeveloperName 
             FROM CustomNotificationType 
             WHERE DeveloperName='Case_Withdrawal'];
                                    
            // Enable notification delivery settings ==> Notification Type ==> mobile apps
            for (Id workOrderId : workOrderToAgent.keySet()) {
                Id withdrawnUserId = workOrderToAgent.get(workOrderId);
                System.debug('withdrawnUserId'+withdrawnUserId);
                if (withdrawnUserId == null) {
                    continue;
                }
                // Create a new custom notification
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                
                notification.setNotificationTypeId(notificationType.Id);
                notification.setTitle('Work Order Withdrawal');
                notification.setBody('You have been withdrawn from this work order.');
                //notification.setSenderId(loggedUserId);
                notification.setTargetId(workOrderId);
                
                Set<String> recipients = new Set<String>{ String.valueOf(withdrawnUserId) };
                System.debug('recipients: ' + recipients);
                // send notification for THIS work order to THIS user
                notification.send(recipients);
            }
    }

    public static void assignNotification(Map<Id, Id> workOrderToAgent){

            CustomNotificationType notificationType =
                [SELECT Id, DeveloperName 
             FROM CustomNotificationType 
             WHERE DeveloperName='Case_Assignment'];
                                    
            // Enable notification delivery settings ==> Notification Type ==> mobile apps
            for (Id workOrderId : workOrderToAgent.keySet()) {
                Id assignedUserId = workOrderToAgent.get(workOrderId);
                if (assignedUserId == null) {
                    continue;
                }
                // Create a new custom notification
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                
                notification.setNotificationTypeId(notificationType.Id);
                notification.setTitle('Work Order Assignment');
                notification.setBody('You have been assigned this work order.');
                notification.setTargetId(workOrderId);
                
                Set<String> recipients = new Set<String>{ String.valueOf(assignedUserId) };
                System.debug('recipients: ' + recipients);
                // send notification for THIS work order to THIS user
                notification.send(recipients);
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