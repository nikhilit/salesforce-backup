/**
 * @description       :
 * @author            : Kartik Patkar Appstrail
 * @group             :
 * @last modified on  : 16-09-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   14-05-2025   Kartik Patkar, Appstrail   Initial Version
 **/
public without sharing class MeteringWorkOrderAllocationHelper {
    
    // public static Map<String,Id> mapKeyAgentId=new Map<String,Id>();
    // public static Map<Id,Integer> mapAgencyUtilizedCapacity = new Map<Id,Integer>();
    
    /**
     * @description
     * @author Kartik Patkar, Appstrail | 16-05-2025
     * @param List<Meter_Reading_Order__c> listMROs
     **/
    public static Map<String,MRU_Wrapper> workOrderCreationAndScheduling(List<Meter_Reading_Order__c> listMROs, 
        Map<String,MRU_Wrapper> mapMRU) {
        
        // Get Record Type Id for MGL_Metering
        String meteringRecordTypeId = Schema.getGlobalDescribe().get('WorkOrder').getDescribe()
            .getRecordTypeInfosByDeveloperName().get('MGL_Metering').getRecordTypeId();
        
        List<WorkOrder> listNewWorkOrders = new List<WorkOrder>();
        Set<String> setMRU = new Set<String>();
        Set<Id> setAccountId=new Set<Id>();
        Set<Id> setAgentId=new Set<Id>();
        
        Date startDate;
        Date endDate;
        Integer dayDiff;
        String portionId;
        
        // Loop through MROs and create corresponding Work Orders
        for(Meter_Reading_Order__c mroRec : listMROs) {
            WorkOrder workOrderRec = new WorkOrder();
            workOrderRec.Meter_Reading_Order__c = mroRec.Id;
            workOrderRec.AccountId = mroRec.Customer__c;
            workOrderRec.StartDate = mroRec.Scheduled_Meter_Reading_Date__c;
            workOrderRec.EndDate = mroRec.Scheduled_Meter_Reading_End_Date__c;
            workOrderRec.Scheduled_Date__c = mroRec.Scheduled_Meter_Reading_Date__c;
            workOrderRec.Status = 'New';
            workOrderRec.Subject = 'Meter Reading for ' + mroRec.Name;
            workOrderRec.RecordTypeId = meteringRecordTypeId;
            workOrderRec.MRU__c = mroRec.MRU__c;
            workOrderRec.Work_Order_Type__c='Scheduled';
            workOrderRec.Location__c = mroRec.Customer_Location__c;
            workOrderRec.Road_Name__c = mroRec.Customer_Road_Name__c;
            workOrderRec.Building_Name__c = mroRec.Building__c;
            workOrderRec.Postal_Code__c = mroRec.Customer_Postal_Code__c;
            workOrderRec.Meter_Reading_Doc_Number__c = mroRec.Meter_Reading_Doc_Number__c;
            workOrderRec.BP_Category__c = mroRec.Customer_Category__c;
            workOrderRec.Assigned_Meter_Reader__c = mroRec.Agent__c;
            workOrderRec.Meter_Reader_Name__c = mroRec.Meter_Reader_Name__c;

           // mroRec.Created_Order__c = true;

            setMRU.add(mroRec.MRU__c);
            setAccountId.add(workOrderRec.AccountId);
            listNewWorkOrders.add(workOrderRec);

            if(workOrderRec.Assigned_Meter_Reader__c!=null){
                setAgentId.add(mroRec.Agent__c);
            }
        
            // Track date range
            if(startDate == null || startDate > mroRec.Scheduled_Meter_Reading_Date__c) {
                startDate = mroRec.Scheduled_Meter_Reading_Date__c;
            }
            if(endDate == null || endDate < mroRec.Scheduled_Meter_Reading_End_Date__c) {
                endDate = mroRec.Scheduled_Meter_Reading_End_Date__c;
            }
            dayDiff = mroRec.Scheduled_Meter_Reading_Date__c.daysBetween(mroRec.Scheduled_Meter_Reading_End_Date__c);
            portionId = mroRec.Portion__c;    
        }
        Map<Id,ServiceTerritoryMember> mapAgentIdWithServiceResourceRecords = new Map<Id,ServiceTerritoryMember>();
        if(!setAgentId.isEmpty()){
            for(ServiceTerritoryMember stmRec: [SELECT Id,ServiceResourceId,ServiceTerritoryId,ServiceTerritory.Portion__c
                                                FROM ServiceTerritoryMember 
                                                WHERE ServiceResourceId IN :setAgentId AND ServiceResource.IsActive=true]){
                
                if(!mapAgentIdWithServiceResourceRecords.containsKey(stmRec.ServiceResourceId)){
                    mapAgentIdWithServiceResourceRecords.put(stmRec.ServiceResourceId,stmRec);
                }
            }
        }
        // Contact records for Person Accounts
        Map<Id,Contact> mapAccountIdVSContactRec=new Map<Id,Contact>();
        for(Contact contactRec:[SELECT Id,AccountId FROM Contact WHERE AccountId IN:setAccountId 
                                    AND AccountId!=null AND IsPersonAccount=TRUE]){
            if(!mapAccountIdVSContactRec.containsKey(contactRec.AccountId)){
                mapAccountIdVSContactRec.put(contactRec.AccountId,contactRec);
            }
        }
        // Fetch Meter Reading Units and their Portions
        Set<Id> setPortionsId = new Set<Id>();
        Map<String, Meter_Reading_Unit__c> mapMruCodeVSRecord = new Map<String, Meter_Reading_Unit__c>();
        for(Meter_Reading_Unit__c mruRec:[SELECT Id, Name,Portion__c FROM Meter_Reading_Unit__c 
                                            WHERE Name IN :setMRU AND Portion__c!=null]) {
            
            setPortionsId.add(mruRec.Portion__c);
            if(!mapMruCodeVSRecord.containsKey(mruRec.Name)) {
                mapMruCodeVSRecord.put(mruRec.Name, mruRec);
            }
        }
        
        // Fetch existing Meter Reading Schedule records based on MRU and date
        Map<String, Meter_Reading_Schedule__c> mapKeyVSMRScheduleRec = new Map<String, Meter_Reading_Schedule__c>();
        for(Meter_Reading_Schedule__c mrsRec : [SELECT Id, MRU__c, Meter_Reading_Start_Date__c, No_of_Customer__c,Agency__c,
                                                    Portion__c,Agent__c,Meter_Reading_Completion_Date__c
                                                FROM Meter_Reading_Schedule__c 
                                                WHERE Agent__c IN :setAgentId 
                                                    AND Meter_Reading_Start_Date__c >= :startDate
                                                    AND Meter_Reading_Completion_Date__c <= :endDate
                                                    AND Status__c='Pending']) {
            
            String agencyKey;
            if(mrsRec.Agent__c==null){
                agencyKey = 'unassigned';
            } else {
                agencyKey = mrsRec.Agent__c;
            }
            // String agencyKey = mrsRec.Agency__c!=null?mrsRec.Agency__c:'assigned';
            String key = mrsRec.Meter_Reading_Start_Date__c+'-'+mrsRec.Meter_Reading_Completion_Date__c+'-'+agencyKey;
            if(!mapKeyVSMRScheduleRec.containsKey(key)) {
                mapKeyVSMRScheduleRec.put(key, mrsRec);
            }
        }

        // Fetch Service Territory and its Service Resources
        String agencyRecordTypeId = Schema.getGlobalDescribe().get('ServiceTerritory').getDescribe()
            .getRecordTypeInfosByDeveloperName().get('Metering').getRecordTypeId();
        
        // Fetch Service Territories based on MRU Portions and Record Type
        Map<Id,ServiceTerritory> mapServiceTerritoryId = new Map<Id, ServiceTerritory>(
            [SELECT Id, Name, MRU__c,Capacity__c, RecordTypeId,Portion__c,Business_Partner_Category__c,Portions__c,
                                            (SELECT Id, ServiceResourceId, ServiceResource.RelatedRecordId, ServiceTerritoryId,
                                                ServiceResource.Capacity__c 
                                            FROM ServiceResources 
                                            WHERE ServiceResource.IsActive=TRUE 
                                                AND ServiceResource.Service_Resource_Type__c='Meter Reader') 
                                        FROM ServiceTerritory 
                                        WHERE RecordTypeId=:agencyRecordTypeId AND IsActive=TRUE]);
        
        
        Map<String, List<ServiceTerritory>> mapPortionVSAgencies= new Map<String, List<ServiceTerritory>>();
        Map<Id, List<ServiceTerritoryMember>> mapServiceTerritoryMember = new Map<Id, List<ServiceTerritoryMember>>();
        // Map<Id,Integer> mapAgencyUtilizedCapacity = new Map<Id,Integer>();
        for(ServiceTerritory serviceTerritoryRec : mapServiceTerritoryId.values()) {
            
            if(serviceTerritoryRec.ServiceResources != null && !serviceTerritoryRec.ServiceResources.isEmpty()
                && serviceTerritoryRec.Portions__c != null && serviceTerritoryRec.Portions__c!='') {

                for(String portion : serviceTerritoryRec.Portions__c.split(',')) {
                    if(String.isNotBlank(portion)) {
                        String portionValue=portion.trim();
                        // Map Agency to Portion
                        if(!mapPortionVSAgencies.containsKey(portionValue)) {
                            mapPortionVSAgencies.put(portionValue, new List<ServiceTerritory>());
                        }
                        mapPortionVSAgencies.get(portionValue).add(serviceTerritoryRec);
                    }
                }
                
                // Map Agency to utilized capacity
                // if(!mapAgencyUtilizedCapacity.containsKey(serviceTerritoryRec.Id)){
                //     mapAgencyUtilizedCapacity.put(serviceTerritoryRec.Id, 0);
                // }
                
                // Map the Agency to the Service Resource
                if(serviceTerritoryRec.ServiceResources != null && !serviceTerritoryRec.ServiceResources.isEmpty()) {
                    List<ServiceTerritoryMember> listServiceTerritoryMember = new List<ServiceTerritoryMember>();
                    for(ServiceTerritoryMember stmRec : serviceTerritoryRec.ServiceResources) {
                        listServiceTerritoryMember.add(stmRec);
                    }
                    mapServiceTerritoryMember.put(serviceTerritoryRec.Id, listServiceTerritoryMember);
                }
            }
            
        }
         /* ================= AUTO ASSIGNMENT SUPPORT MAPS ================= */

        Map<String, List<Agency_Portion_Mapping__c>> mapPortionAgencies = new Map<String, List<Agency_Portion_Mapping__c>>();
        for (Agency_Portion_Mapping__c apm : [
            SELECT Portion__c, Agency__c, Priority__c
            FROM Agency_Portion_Mapping__c
            WHERE Active__c = TRUE
            ORDER BY Priority__c ASC]) {
            if (!mapPortionAgencies.containsKey(apm.Portion__c)) {
                mapPortionAgencies.put(apm.Portion__c, new List<Agency_Portion_Mapping__c>());
            }
            mapPortionAgencies.get(apm.Portion__c).add(apm);
             }

        Set<Id> setAgencyIds = new Set<Id>();
        for (List<Agency_Portion_Mapping__c> lst : mapPortionAgencies.values()) {
            for (Agency_Portion_Mapping__c apm : lst) {
                setAgencyIds.add(apm.Agency__c);
            }
        }

        Map<Id, List<ServiceTerritoryMember>> mapAgencyAgents = new Map<Id, List<ServiceTerritoryMember>>();
        for (ServiceTerritoryMember stm : [
            SELECT Id, ServiceTerritoryId, ServiceResourceId,Priority__c, Capacity__c
            FROM ServiceTerritoryMember
            WHERE Resource_Active__c = TRUE AND ServiceTerritoryId IN :setAgencyIds
            ORDER BY Priority__c ASC]) {
            if (!mapAgencyAgents.containsKey(stm.ServiceTerritoryId)) {
                mapAgencyAgents.put(stm.ServiceTerritoryId, new List<ServiceTerritoryMember>());
            }
            mapAgencyAgents.get(stm.ServiceTerritoryId).add(stm);
        }
        Map<Id, Integer> mapAgentUtilizedCapacity = new Map<Id, Integer>();
        // MRS Creation
        for(WorkOrder woRec : listNewWorkOrders){
            MRU_Wrapper mruWrap=new MRU_Wrapper();
            // NAME BASED MRU ASSIGNMENT
            String key;
            if(woRec.Assigned_Meter_Reader__c==null && woRec.Meter_Reader_Name__c!=null){
                key=woRec.Meter_Reader_Name__c;
                if(!mapMRU.containsKey(key)){
                    mruWrap=new MRU_Wrapper(key,woRec.StartDate.date(),woRec.StartDate.date(),null,woRec.Meter_Reader_Name__c,null,null);
                }else{
                    mruWrap=mapMRU.get(key);
                }
            }
            // AGENT BASED MRU ASSIGNMENT
            else if(woRec.Assigned_Meter_Reader__c!=null){
                key=woRec.Assigned_Meter_Reader__c;
                if(!mapMRU.containsKey(key)){
                    mruWrap=new MRU_Wrapper(key,woRec.StartDate.date(),woRec.EndDate.date(),woRec.Assigned_Meter_Reader__c,null,null,null);
                }else{
                    mruWrap=mapMRU.get(key);
                }
            }
            // AUTO MRU ASSIGNMENT LOGIC 
                else {
            if (!'Enabled'.equalsIgnoreCase(System.Label.autoAllocation)) {
                  System.debug('Auto allocation disabled via custom label.');
                  continue;
            }
            if (portionId == null || !mapPortionAgencies.containsKey(portionId)) {
               System.debug('Portion not found. Skipping WO.');
                 continue;
            }
            key = 'AUTO-' + woRec.Building_Name__c;
            if (!mapMRU.containsKey(key)) { 
                Boolean assigned = false;
            for (Agency_Portion_Mapping__c apm : mapPortionAgencies.get(portionId)) {
                 Id agencyId = apm.Agency__c;
                 if (!mapAgencyAgents.containsKey(agencyId)) {
                    continue;
                }
               for (ServiceTerritoryMember stm : mapAgencyAgents.get(agencyId)) {
                    System.debug('   Agent: ' + stm.ServiceResourceId +', Priority: ' + stm.Priority__c);
                    Integer used = mapAgentUtilizedCapacity.get(stm.ServiceResourceId) == null ? 0 : mapAgentUtilizedCapacity.get(stm.ServiceResourceId);
                    Decimal totalCapacity = stm.Capacity__c * dayDiff;
                     if (used >= totalCapacity) {
                        continue;
                    }
                    mruWrap = new MRU_Wrapper(
                    key,
                    woRec.StartDate.date(),
                    woRec.EndDate.date(),
                    stm.ServiceResourceId,
                    null,
                    totalCapacity,
                    agencyId);

                    mapMRU.put(key, mruWrap);

                    woRec.Assigned_Meter_Reader__c = stm.ServiceResourceId;
                    woRec.Metering_Agency__c = agencyId;
                    mapAgentUtilizedCapacity.put(stm.ServiceResourceId, used + 1);
                    assigned = true;
                    break; // agent loop
                }  
                if (assigned) {
                break; // agency loop
                }
     }
            if (!assigned) {
                System.debug('No agent available for new building.');
            }
    }
    else{   
        mruWrap = mapMRU.get(key);
        Integer used = mapAgentUtilizedCapacity.get(mruWrap.agentId) == null? 0 : mapAgentUtilizedCapacity.get(mruWrap.agentId);
        Decimal totalCapacity = mruWrap.totalCapacity;
        if (used < totalCapacity) {
            woRec.Assigned_Meter_Reader__c = mruWrap.agentId;
            woRec.Metering_Agency__c = mruWrap.agencyId;
            mapAgentUtilizedCapacity.put(mruWrap.agentId, used + 1);
        }   else {
                    System.debug('Existing building agent capacity full. Leaving WO.');
                }
        }

  }
        if(mruWrap.startDate > woRec.StartDate){
                mruWrap.startDate = woRec.StartDate.date();
        }
        if(mruWrap.endDate < woRec.EndDate){
                mruWrap.endDate = woRec.EndDate.date();
        }
        mruWrap.agentName=woRec.Meter_Reader_Name__c;
        mruWrap.listWorkOrders.add(woRec);
        mapMRU.put(key,mruWrap);
 }
        if(!mapMRU.isEmpty()){
            List<Meter_Reading_Schedule__c> listMRSToUpdate = new List<Meter_Reading_Schedule__c>();
            for(MeteringWorkOrderAllocationHelper.MRU_Wrapper mruWrapper:mapMRU.values()){
                Meter_Reading_Schedule__c mrsRecNew = new Meter_Reading_Schedule__c();
                mruWrapper.capacityAllocated += mruWrapper.listWorkOrders.size();
                mrsRecNew.No_of_Customer__c = mruWrapper.capacityAllocated;
                // mrsRec.Agency__c = workOrderRec.ServiceTerritoryId;
                // mrsRec.Agent__c = workOrderRec.Assigned_Meter_Reader__c;
                // mrsRec.MRU__c = workOrderRec.MRU__c;
                // mrsRec.Portion__c=workOrderRec.Portion__c;
                if(mruWrapper.mrsRec!=null){
                    mrsRecNew.Id=mruWrapper.mrsRec.Id;
                }
                mrsRecNew.Meter_Reading_Start_Date__c = mruWrapper.startDate;
                mrsRecNew.Meter_Reading_Completion_Date__c = mruWrapper.endDate;
                mrsRecNew.Meter_Reader_Name__c = mruWrapper.agentName;
                mrsRecNew.Agent__c = mruWrapper.agentId;
                if(mrsRecNew.Agent__c!=null && mapAgentIdWithServiceResourceRecords.containsKey(mrsRecNew.Agent__c)){
                    mrsRecNew.Agency__c = mapAgentIdWithServiceResourceRecords.get(mrsRecNew.Agent__c).ServiceTerritoryId;
                }
                
                listMRSToUpdate.add(mrsRecNew);
                mruWrapper.mrsRec = mrsRecNew;
            }

            if(!listMRSToUpdate.isEmpty()){
                upsert listMRSToUpdate;
            }

            List<WorkOrder> listWorkOrdersToUpdate = new List<WorkOrder>();
            for(MeteringWorkOrderAllocationHelper.MRU_Wrapper mruWrapper:mapMRU.values()){
                if(mruWrapper.mrsRec != null && !mruWrapper.listWorkOrders.isEmpty()){
                    for(WorkOrder woRec : mruWrapper.listWorkOrders){
                        woRec.Meter_Reading_Schedule__c = mruWrapper.mrsRec.Id;
                        if(woRec.Assigned_Meter_Reader__c!=null && mapAgentIdWithServiceResourceRecords.containsKey(woRec.Assigned_Meter_Reader__c)){
                            woRec.ServiceTerritoryId = mapAgentIdWithServiceResourceRecords.get(woRec.Assigned_Meter_Reader__c).ServiceTerritoryId;
                            woRec.Metering_Agency__c = mapAgentIdWithServiceResourceRecords.get(woRec.Assigned_Meter_Reader__c).ServiceTerritoryId;
                        }
                        if(mapAccountIdVSContactRec.containsKey(woRec.AccountId)){
                            woRec.contactId=mapAccountIdVSContactRec.get(woRec.AccountId).Id;
                        }
                        if(mapMruCodeVSRecord.containsKey(woRec.MRU__c)) {
                            woRec.Portion__c = mapMruCodeVSRecord.get(woRec.MRU__c).Portion__c;
                            woRec.Meter_Reading_Unit__c = mapMruCodeVSRecord.get(woRec.MRU__c).Id;
                        }
                        listWorkOrdersToUpdate.add(woRec);
                    }
                }   
            }

            if(!listWorkOrdersToUpdate.isEmpty()){
                insert listWorkOrdersToUpdate;
            }
            Set<Id> mroIdsToUpdate = new Set<Id>();
           for (WorkOrder wo : listWorkOrdersToUpdate) {
               if (wo.Meter_Reading_Order__c != null) {
                      mroIdsToUpdate.add(wo.Meter_Reading_Order__c);
                }
            }
            if (!mroIdsToUpdate.isEmpty()) {
                List<Meter_Reading_Order__c> mrosToUpdate = [
                 SELECT Id, Created_Order__c
                 FROM Meter_Reading_Order__c
                 WHERE Id IN :mroIdsToUpdate ];

            for (Meter_Reading_Order__c mro : mrosToUpdate) {
                mro.Created_Order__c = true;
            }
            update mrosToUpdate;
            }
            if(!mapMRU.isEmpty()){
                for(MeteringWorkOrderAllocationHelper.MRU_Wrapper mruWrapper:mapMRU.values()){
                    mruWrapper.listWorkOrders=new List<WorkOrder>();
                }
            }
            if(!listMROs.isEmpty()){
                update listMROs;
            }
        }

        return mapMRU;
    }

    public class MRU_Wrapper{
        public String key;
        public Date startDate;
        public Date endDate;
        public Id agentId;
        public String agentName;
        Decimal totalCapacity;
        Public Id agencyId;
        public Integer capacityUtilized=0;
        public Integer capacityAllocated=0;
        public List<WorkOrder> listWorkOrders=new List<WorkOrder>();
        public Meter_Reading_Schedule__c mrsRec;

        public MRU_Wrapper(){}

        public MRU_Wrapper(String key,Date startDate,Date endDate,Id agentId,String agentName,Decimal totalCapacity,Id agencyId){
            this.key=key;
            this.startDate=startDate;
            this.endDate=endDate;
            this.agentId=agentId;
            this.agentName=agentName;
            this.totalCapacity = totalCapacity;
            this.agencyId = agencyId;
            this.capacityUtilized=0;
            this.capacityAllocated=0;
            this.listWorkOrders=new List<WorkOrder>();
            this.mrsRec=null;
        }        
    }

    /**
     * @description
     * @author Kartik Patkar, Appstrail | 16-05-2025
     * @param List<WorkOrder> workOrders
     * @param List<ServiceTerritoryMember> listServiceTerritoryMember
     **/
    public static void assignWorkOrders(List<WorkOrder> listWorkOrders, List<ServiceTerritoryMember> listServiceTerritoryMember,
    Map<String, Id> mapKeyAgentId) {
        if (listWorkOrders.isEmpty() || listServiceTerritoryMember.isEmpty()) {
            return;
        }
        
        Integer totalOrders = listWorkOrders.size();
        Integer totalUsers = listServiceTerritoryMember.size();
        Integer baseCapacity = totalOrders / totalUsers;
        Integer remainder = Math.mod(totalOrders, totalUsers);
        
        // Step 1: Group by building
        Map<String, List<WorkOrder>> buildingWorkOrderMap = new Map<String, List<WorkOrder>>();
        for (WorkOrder wo : listWorkOrders) {
            if (wo.ServiceTerritoryId == null || wo.Assigned_Meter_Reader__c==null) {
                continue;
            }
            if (String.isNotBlank(wo.Location__c) && String.isNotBlank(wo.Postal_Code__c) &&
            String.isNotBlank(wo.Road_Name__c) && String.isNotBlank(wo.Building_Name__c)) {
                
                String key = wo.Location__c + '-' + wo.Postal_Code__c + '-' +
                    wo.Road_Name__c + '-' + wo.Building_Name__c;
                
                if (!buildingWorkOrderMap.containsKey(key)) {
                    buildingWorkOrderMap.put(key, new List<WorkOrder>());
                }
                buildingWorkOrderMap.get(key).add(wo);
            }
        }
        
        // Step 2: Assign buildings round-robin
        Integer agentIndex = 0;
        Map<Id, Integer> agentAssignedCount = new Map<Id, Integer>();
        
        for (String buildingKey : buildingWorkOrderMap.keySet()) {
            List<WorkOrder> buildingOrders = buildingWorkOrderMap.get(buildingKey);
            Integer groupSize = buildingOrders.size();
            
            Boolean assigned = false;
            Integer attempts = 0;
            
            // First try to find agent with enough capacity
            for (Integer i = 0; i < totalUsers; i++) {
                Integer tryIndex = Math.mod((agentIndex + i), totalUsers);
                ServiceTerritoryMember member = listServiceTerritoryMember[tryIndex];
                Id resourceId = member.ServiceResourceId;
                Id ownerId = member.ServiceResource.RelatedRecordId;
                Integer agentCap = baseCapacity + (tryIndex < remainder ? 1 : 0);
                Integer assignedCount = agentAssignedCount.get(resourceId) != null ? agentAssignedCount.get(resourceId) : 0;
                
                if (assignedCount + groupSize <= agentCap) {
                    for (WorkOrder wo : buildingOrders) {
                        wo.Assigned_Meter_Reader__c = resourceId;
                        wo.OwnerId = ownerId;
                    }
                    mapKeyAgentId.put(buildingKey, resourceId);
                    agentAssignedCount.put(resourceId, assignedCount + groupSize);
                    agentIndex = Math.mod((tryIndex + 1), totalUsers);
                    assigned = true;
                    break;
                }
            }
            
            // Fallback: assign to next agent even if over capacity
            if (!assigned) {
                ServiceTerritoryMember fallbackMember = listServiceTerritoryMember[agentIndex];
                Id fallbackId = fallbackMember.ServiceResourceId;
                Id fallbackOwner = fallbackMember.ServiceResource.RelatedRecordId;
                
                for (WorkOrder wo : buildingOrders) {
                    wo.Assigned_Meter_Reader__c = fallbackId;
                    wo.OwnerId = fallbackOwner;
                }
                
                Integer prevCount = agentAssignedCount.get(fallbackId) != null ? agentAssignedCount.get(fallbackId) : 0;
                agentAssignedCount.put(fallbackId, prevCount + groupSize);
                mapKeyAgentId.put(buildingKey, fallbackId);
                agentIndex = Math.mod((agentIndex + 1), totalUsers);
            }
        }
    }

    /**
     * @description
     * @author Kartik Patkar, Appstrail | 26-06-2025
     * @param List<WorkOrder> listWorkOrders
     * @param String mrsId
     **/
    public static void approvalMRSAssignResource(List<WorkOrder> listWorkOrders,String mrsId) {
        Set<Id> setWorkOrderIds=new Set<Id>();
        Set<Id> setServiceResourceIds=new Set<Id>();
        for(WorkOrder workOrder:listWorkOrders){
            setWorkOrderIds.add(workOrder.Id);
            setServiceResourceIds.add(workOrder.Assigned_Meter_Reader__c);
        }
        
        Map<Id,ServiceAppointment> mapWorkOrderIdVSAppointments=new Map<Id,ServiceAppointment>();
        Map<Id,Set<Id>> mapAppointIdVSUserIds=new Map<Id,Set<Id>>();
        for(ServiceAppointment serviceAppointRec:[SELECT Id,SchedStartTime,ParentRecordId,
                                                        (SELECT Id,ServiceResourceId,ServiceResource.RelatedRecordId 
                                                        FROM ServiceResources 
                                                        WHERE ServiceResource.IsActive=true AND ServiceResourceId IN:setServiceResourceIds)
                                                    FROM ServiceAppointment 
                                                    WHERE ParentRecordId!=null AND ParentRecordId IN:setWorkOrderIds]){
            
            if(!mapWorkOrderIdVSAppointments.containsKey(serviceAppointRec.ParentRecordId)){
                mapWorkOrderIdVSAppointments.put(serviceAppointRec.ParentRecordId,serviceAppointRec);
            }
            
            if(serviceAppointRec.ServiceResources!=null && !serviceAppointRec.ServiceResources.isEmpty()){
                for(AssignedResource serviceResRec:serviceAppointRec.ServiceResources){
                    if(!mapAppointIdVSUserIds.containsKey(serviceAppointRec.Id)){
                        mapAppointIdVSUserIds.put(serviceAppointRec.Id,new Set<Id>());
                    }
                    mapAppointIdVSUserIds.get(serviceAppointRec.Id).add(serviceResRec.ServiceResourceId);
                }
            }
        }
        
        List<AssignedResource> listAssignedResources=new List<AssignedResource>();
        for(WorkOrder workOrder:listWorkOrders){
            if(mapWorkOrderIdVSAppointments.containsKey(workOrder.Id)){
                ServiceAppointment serviceAppoint=mapWorkOrderIdVSAppointments.get(workOrder.Id);
                if(!mapAppointIdVSUserIds.containsKey(serviceAppoint.Id) || (mapAppointIdVSUserIds.containsKey(serviceAppoint.Id)
                && !mapAppointIdVSUserIds.get(serviceAppoint.Id).contains(workOrder.Assigned_Meter_Reader__c))){
                    
                    listAssignedResources.add(new AssignedResource(
                        ServiceAppointmentId = serviceAppoint.Id,
                    ServiceResourceId = workOrder.Assigned_Meter_Reader__c
                        ));
                }
            }
        }
        
        if(!listAssignedResources.isEmpty()){
            System.debug('listAssignedResources:::'+listAssignedResources);
            insert listAssignedResources;
            
            if(mrsId!=null){
                Meter_Reading_Schedule__c mrs=new Meter_Reading_Schedule__c(Id=mrsId);
                mrs.Status__c='Approved';
                update mrs;
            }
        }
    }
    
    /**
     * @description
     * @author Kartik Patkar, Appstrail | 16-05-2025
     * @return string
     **/
    @AuraEnabled
    public static string startWorkOrderBatch(){
        try {
            MeteringWorkOrderAllocationBatch batch = new MeteringWorkOrderAllocationBatch();
            Database.executeBatch(batch, 200);
            return 'success';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static string startWorkOrderApprovalBatch(String mrsId){
        try {
            MeterReadingScheduleApprovalBatch batch = new MeterReadingScheduleApprovalBatch(mrsId,null,false);
            Database.executeBatch(batch, 200);
            return 'success';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    
    
}