/**
 * @description       : Type definitions for Auto Allocation
**/
public class MeteringAutoAllocationTypes {

    // -------------------------
    // WRAPPER: Agency
    // -------------------------
    public class AgencyWrapper {
        public Id agencyId;
        public Integer priority; // MUST be integer
        public List<AgentWrapper> agents = new List<AgentWrapper>();
    }

    // -------------------------
    // WRAPPER: Agent
    // -------------------------
    public class AgentWrapper {
        public Id agentId;                 // ServiceResourceId
        public Id serviceTerritoryId;      // Agency
        public Integer priority;           // Agent priority
        public Integer dailyCapacity;      
        public Integer effectiveCapacity;
        public Integer remainingCapacity;
        public Set<String> buildings = new Set<String>();
    }

    // -------------------------
    // WRAPPER: Building Group
    // -------------------------
    public class BuildingWrapper {
        public String buildingKey;
        public List<Meter_Reading_Order__c> mroList = new List<Meter_Reading_Order__c>();
    }

    // -------------------------
    // WRAPPER: MRS Helper
    // -------------------------
    public class MRS_Wrapper {
        public Id agentId;
        public Id agencyId;
        public Id portionId;
        public Date startDate;
        public Date endDate;
        public List<WorkOrder> woList = new List<WorkOrder>();
        public Integer capacityUsed = 0;
    }

    // -------------------------
    // WRAPPER: Building Assignment Info
    // -------------------------
    public class BuildingAssignmentInfo {
        public String buildingKey;
        public Id agentId; // null = overflow
        public Id agencyId; // null = overflow
    }

    // -------------------------
    // State of which agency is currently active per Portion
    // -------------------------
    public class AgencyProgressState {
        public Integer index = 0; 
    }
}