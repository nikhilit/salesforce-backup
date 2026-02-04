/**
 * @description: Auto Allocation Engine
 **/
public with sharing class MeteringAutoAllocationHelper {
    
    /**
     * MAIN ENTRY POINT FOR AUTO ALLOCATION
     */
    public static Map<String, MeteringAutoAllocationTypes.BuildingAssignmentInfo> allocateAuto(
        List<Meter_Reading_Order__c> mroChunk,
    Map<Id, Integer> agentRemainingCapacity,
    Map<Id, Set<String>> agentAssignedBuildings,
    Map<Id, MeteringAutoAllocationTypes.MRS_Wrapper> agentMRSMap,
    Map<String, MeteringAutoAllocationTypes.BuildingAssignmentInfo> buildingAssignments,
    Map<Id, MeteringAutoAllocationTypes.AgencyProgressState> portionPointers
    ) {
        if (mroChunk.isEmpty()) return buildingAssignments;
        
        // 1. Group by Portion
        Map<Id, List<Meter_Reading_Order__c>> portionToMRO = groupByPortion(mroChunk);
        
        // 2. Extract portions
        Set<Id> portionIds = portionToMRO.keySet();
        
        // 3. Load Agencies per portion
        Map<Id, List<MeteringAutoAllocationTypes.AgencyWrapper>> portionToAgencies =
            loadAgenciesForPortions(portionIds);
        
        // 4. Load Agents
        Set<Id> agencyIds = new Set<Id>();
        for (List<MeteringAutoAllocationTypes.AgencyWrapper> listA : portionToAgencies.values())
            for (MeteringAutoAllocationTypes.AgencyWrapper a : listA) agencyIds.add(a.agencyId);
        
        Map<Id, List<MeteringAutoAllocationTypes.AgentWrapper>> agencyToAgents =
            loadAgentsForAgencies(agencyIds);
        
        // 5. Get total days for capacity
        Date minDate, maxDate;
        for (Meter_Reading_Order__c m : mroChunk) {
            if (minDate == null || m.Scheduled_Meter_Reading_Date__c < minDate)
                minDate = m.Scheduled_Meter_Reading_Date__c;
            if (maxDate == null || m.Scheduled_Meter_Reading_End_Date__c > maxDate)
                maxDate = m.Scheduled_Meter_Reading_End_Date__c;
        }
        Integer numDays = maxDate.daysBetween(minDate) + 1;
        
        // 6. Prepare capacities
        prepareAgentCapacities(agencyToAgents, agentRemainingCapacity, numDays);
        
        // 7. Allocate per Portion
        for (Id portionId : portionToMRO.keySet()) {
            
            List<Meter_Reading_Order__c> mros = portionToMRO.get(portionId);
            
            // Group by building
            Map<String, MeteringAutoAllocationTypes.BuildingWrapper> buildingMap =
                groupByBuilding(mros);
            
            List<String> buildingKeys = new List<String>(buildingMap.keySet());
            buildingKeys.sort();
            
            // If no agency → overflow
            if (!portionToAgencies.containsKey(portionId)) {
                for (String b : buildingKeys)
                    createOverflowAssignment(b, buildingAssignments);
                continue;
            }
            
            List<MeteringAutoAllocationTypes.AgencyWrapper> agencies = portionToAgencies.get(portionId);
            
            // pointer init
            if (!portionPointers.containsKey(portionId))
                portionPointers.put(portionId, new MeteringAutoAllocationTypes.AgencyProgressState());
            
            MeteringAutoAllocationTypes.AgencyProgressState pointer =
                portionPointers.get(portionId);
            
            // Allocation engine
            allocatePortionBuildings(
                buildingKeys,
            buildingMap,
            agencies,
            agencyToAgents,
            pointer,
            buildingAssignments,
            agentRemainingCapacity,
            agentAssignedBuildings
                );
        }
        
        return buildingAssignments;
    }
    
    
    // ------------------------------------------
    // GROUP BY PORTION
    // ------------------------------------------
    public static Map<Id, List<Meter_Reading_Order__c>> groupByPortion(
        List<Meter_Reading_Order__c> listMRO
    ) {
        Map<Id, List<Meter_Reading_Order__c>> result = new Map<Id, List<Meter_Reading_Order__c>>();
        for (Meter_Reading_Order__c m : listMRO) {
            if (m.Portion__c == null) continue;
            if (!result.containsKey(m.Portion__c))
                result.put(m.Portion__c, new List<Meter_Reading_Order__c>());
            result.get(m.Portion__c).add(m);
        }
        return result;
    }
    
    
    // ------------------------------------------
    // GROUP BY BUILDING
    // ------------------------------------------
    public static Map<String, MeteringAutoAllocationTypes.BuildingWrapper> groupByBuilding(
        List<Meter_Reading_Order__c> mroList
    ) {
        Map<String, MeteringAutoAllocationTypes.BuildingWrapper> result =
            new Map<String, MeteringAutoAllocationTypes.BuildingWrapper>();
        
        for (Meter_Reading_Order__c m : mroList) {
            if (String.isBlank(m.Building__c)) continue;
            
            if (!result.containsKey(m.Building__c)) {
                MeteringAutoAllocationTypes.BuildingWrapper bw =
                    new MeteringAutoAllocationTypes.BuildingWrapper();
                bw.buildingKey = m.Building__c;
                result.put(m.Building__c, bw);
            }
            result.get(m.Building__c).mroList.add(m);
        }
        return result;
    }
    
    
    // ------------------------------------------
    // LOAD AGENCIES
    // ------------------------------------------
    public static Map<Id, List<MeteringAutoAllocationTypes.AgencyWrapper>> loadAgenciesForPortions(
        Set<Id> portionIds
    ) {
        Map<Id, List<MeteringAutoAllocationTypes.AgencyWrapper>> result =
            new Map<Id, List<MeteringAutoAllocationTypes.AgencyWrapper>>();
        
        List<Agency_Portion_Mapping__c> mappings = [
            SELECT Portion__c, Agency__c, Priority__c
            FROM Agency_Portion_Mapping__c
            WHERE Portion__c IN :portionIds
            ORDER BY Priority__c
        ];
        
        for (Agency_Portion_Mapping__c mapRec : mappings) {
            MeteringAutoAllocationTypes.AgencyWrapper a = new MeteringAutoAllocationTypes.AgencyWrapper();
            
            a.agencyId = mapRec.Agency__c;
            a.priority = (mapRec.Priority__c == null ? 99999 : Integer.valueOf(mapRec.Priority__c.intValue()));
            
            if (!result.containsKey(mapRec.Portion__c))
                result.put(mapRec.Portion__c, new List<MeteringAutoAllocationTypes.AgencyWrapper>());
            
            result.get(mapRec.Portion__c).add(a);
        }
        return result;
    }
    
    
    // ------------------------------------------
    // LOAD AGENTS PER AGENCY
    // ------------------------------------------
    public static Map<Id, List<MeteringAutoAllocationTypes.AgentWrapper>> loadAgentsForAgencies( Set<Id> agencyIds ) {
        Map<Id, List<MeteringAutoAllocationTypes.AgentWrapper>> result =
            new Map<Id, List<MeteringAutoAllocationTypes.AgentWrapper>>();
        
        List<ServiceTerritoryMember> members = [
            SELECT ServiceResourceId, ServiceTerritoryId, Capacity__c, Priority__c
            FROM ServiceTerritoryMember
            WHERE ServiceTerritoryId IN :agencyIds
              AND ServiceResource.IsActive = TRUE
        ];
        
        for (ServiceTerritoryMember stm : members) {
            MeteringAutoAllocationTypes.AgentWrapper a = new MeteringAutoAllocationTypes.AgentWrapper();
            
            a.agentId = stm.ServiceResourceId;
            a.serviceTerritoryId = stm.ServiceTerritoryId;
            a.priority = (stm.Priority__c == null ? 99999 : Integer.valueOf(stm.Priority__c.intValue()));
            a.dailyCapacity = (stm.Capacity__c == null ? 0 : Integer.valueOf(stm.Capacity__c.intValue()));
            
            if (!result.containsKey(stm.ServiceTerritoryId))
                result.put(stm.ServiceTerritoryId, new List<MeteringAutoAllocationTypes.AgentWrapper>());
            
            result.get(stm.ServiceTerritoryId).add(a);
        }
        
        // Sort by agent priority
        for (Id id : result.keySet())
            result.get(id).sort(new CompareAgentPriority());
        
        return result;
    }
    
    
    // Comparator
    public class CompareAgentPriority implements Comparator<MeteringAutoAllocationTypes.AgentWrapper> {
        
        public Integer compare(
            MeteringAutoAllocationTypes.AgentWrapper a,
        MeteringAutoAllocationTypes.AgentWrapper b
        ) {
            if (a.priority == b.priority) return 0;
            return (a.priority < b.priority) ? -1 : 1;
        }
    }
    
    
    // ------------------------------------------
    // PREPARE CAPACITIES
    // ------------------------------------------
    public static void prepareAgentCapacities(
        Map<Id, List<MeteringAutoAllocationTypes.AgentWrapper>> agencyToAgents,
    Map<Id, Integer> agentRemainingCapacity,
    Integer numDays
    ) {
        for (Id ag : agencyToAgents.keySet()) {
            for (MeteringAutoAllocationTypes.AgentWrapper agent :
            agencyToAgents.get(ag)) {
                
                Integer effective = agent.dailyCapacity * numDays;
                
                if (!agentRemainingCapacity.containsKey(agent.agentId)) {
                    agentRemainingCapacity.put(agent.agentId, effective);
                }
                
                agent.remainingCapacity = agentRemainingCapacity.get(agent.agentId);
            }
        }
    }
    
    
    // ------------------------------------------
    // ALLOCATION ENGINE
    // ------------------------------------------
    public static void allocatePortionBuildings(
        List<String> buildingKeys,
    Map<String, MeteringAutoAllocationTypes.BuildingWrapper> buildingMap,
    List<MeteringAutoAllocationTypes.AgencyWrapper> agencies,
    Map<Id, List<MeteringAutoAllocationTypes.AgentWrapper>> agencyToAgents,
    MeteringAutoAllocationTypes.AgencyProgressState pointer,
    Map<String, MeteringAutoAllocationTypes.BuildingAssignmentInfo> buildingAssignments,
    Map<Id, Integer> agentRemainingCapacity,
    Map<Id, Set<String>> agentAssignedBuildings
    ) {
        Integer agencyIdx = pointer.index;
        
        for (String bkey : buildingKeys) {
            
            if (buildingAssignments.containsKey(bkey))
                continue;
            
            Integer groupSize = buildingMap.get(bkey).mroList.size();
            
            Boolean assigned = false;
            
            for (Integer a = agencyIdx; a < agencies.size(); a++) {
                
                MeteringAutoAllocationTypes.AgencyWrapper agency = agencies[a];
                
                if (!agencyToAgents.containsKey(agency.agencyId)) continue;
                
                List<MeteringAutoAllocationTypes.AgentWrapper> agents =
                    agencyToAgents.get(agency.agencyId);
                
                for (MeteringAutoAllocationTypes.AgentWrapper agent : agents) {
                    
                    if (!agentAssignedBuildings.containsKey(agent.agentId))
                        agentAssignedBuildings.put(agent.agentId, new Set<String>());
                    
                    if (agentAssignedBuildings.get(agent.agentId).contains(bkey))
                        continue;
                    
                    if (groupSize > agentRemainingCapacity.get(agent.agentId))
                        continue;
                    
                    assignBuilding(
                        bkey,
                    groupSize,
                    agent,
                    agency,
                    buildingAssignments,
                    agentRemainingCapacity,
                    agentAssignedBuildings
                        );
                    assigned = true;
                    pointer.index = a;
                    break;
                }
                if (assigned) break;
            }
            
            if (!assigned) {
                createOverflowAssignment(bkey, buildingAssignments);
            }
        }
    }
    
    
    // ------------------------------------------
    // ASSIGN BUILDING
    // ------------------------------------------
    public static void assignBuilding(
        String bkey,
    Integer groupSize,
    MeteringAutoAllocationTypes.AgentWrapper agent,
    MeteringAutoAllocationTypes.AgencyWrapper agency,
    Map<String, MeteringAutoAllocationTypes.BuildingAssignmentInfo> buildingAssignments,
    Map<Id, Integer> agentRemainingCapacity,
    Map<Id, Set<String>> agentAssignedBuildings
    ) {
        MeteringAutoAllocationTypes.BuildingAssignmentInfo info =
            new MeteringAutoAllocationTypes.BuildingAssignmentInfo();
        
        info.buildingKey = bkey;
        info.agentId = agent.agentId;
        info.agencyId = agency.agencyId;
        
        buildingAssignments.put(bkey, info);
        
        Integer rem = agentRemainingCapacity.get(agent.agentId);
        agentRemainingCapacity.put(agent.agentId, rem - groupSize);
        
        agentAssignedBuildings.get(agent.agentId).add(bkey);
    }
    
    
    // ------------------------------------------
    // OVERFLOW
    // ------------------------------------------
    public static void createOverflowAssignment(
        String bkey,
    Map<String, MeteringAutoAllocationTypes.BuildingAssignmentInfo> buildingAssignments
    ) {
        MeteringAutoAllocationTypes.BuildingAssignmentInfo info =
            new MeteringAutoAllocationTypes.BuildingAssignmentInfo();
        
        info.buildingKey = bkey;
        info.agentId = null;
        info.agencyId = null;
        
        buildingAssignments.put(bkey, info);
    }
}