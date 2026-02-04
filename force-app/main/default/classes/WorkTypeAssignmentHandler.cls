/**
 * @description       :
 * @author            : Kartik Patkar Appstrail
 * @group             :
 * @last modified on  : 06-01-2026
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   15-05-2025   Kartik Patkar, Appstrail   Initial Version
 **/
public without sharing class WorkTypeAssignmentHandler {
    
    public static void assignWorkTypes(List<WorkOrder> listWorkOrder) {
        Map<String, Work_Type_Mapping_Config__mdt> configMap = new Map<String, Work_Type_Mapping_Config__mdt>();
        Map<String, List<Work_Type_Mapping_Condition_Config__mdt>> conditionMap = new Map<String, List<Work_Type_Mapping_Condition_Config__mdt>>();
        Set<String> workTypeNames = new Set<String>();
        
        // Filter active configs and collect work type names
        for (Work_Type_Mapping_Config__mdt config : [SELECT DeveloperName, Work_Type_Name__c, Priority__c,Id
                                                        FROM Work_Type_Mapping_Config__mdt
                                                        WHERE Active__c = TRUE
                                                        ORDER BY Priority__c ASC]) {
            configMap.put(config.Id, config);
            if (config.Work_Type_Name__c != null) {
                workTypeNames.add(config.Work_Type_Name__c);
            }
        }
        
        // Query WorkType Ids by name
        Map<String, Id> workTypeNameToIdMap = new Map<String, Id>();
        for (WorkType wt : [SELECT Id, Name FROM WorkType WHERE Name IN :workTypeNames]) {
            workTypeNameToIdMap.put(wt.Name, wt.Id);
        }
        
        // Load all condition records
        if(!configMap.keySet().isEmpty()){
            for (Work_Type_Mapping_Condition_Config__mdt cond : [SELECT Work_Type_Mapping_Config__c, Field_API_Name__c, Operator__c, Value__c, Active__c
                                                                FROM Work_Type_Mapping_Condition_Config__mdt
                                                                WHERE Work_Type_Mapping_Config__c IN :configMap.keySet()
                                                                    AND Active__c = TRUE]){
                if (configMap.containsKey(cond.Work_Type_Mapping_Config__c)) {
                    if (!conditionMap.containsKey(cond.Work_Type_Mapping_Config__c)) {
                        conditionMap.put(cond.Work_Type_Mapping_Config__c, new List<Work_Type_Mapping_Condition_Config__mdt>());
                    }
                    conditionMap.get(cond.Work_Type_Mapping_Config__c).add(cond);
                }
            }
        }
        
        // Process each work order
        for (WorkOrder workOrderRec : listWorkOrder) {
            for (Work_Type_Mapping_Config__mdt config : configMap.values()) {
                List<Work_Type_Mapping_Condition_Config__mdt> conditions = conditionMap.get(config.Id);
                Boolean isMatch = false;
                
                if (conditions != null && !conditions.isEmpty()) {
                    Integer totalCondition=conditions.size();
                    Integer successCondition=0;

                    for (Work_Type_Mapping_Condition_Config__mdt cond : conditions) {
                        String fieldName = cond.Field_API_Name__c;
                        Object fieldValue = getFieldValue(workOrderRec, fieldName);
                        String expected = cond.Value__c;
                        String operator = cond.Operator__c;
                        
                        if (evaluateCondition(fieldValue, expected, operator)) {
                            successCondition++;
                        }else{
                            break;
                        }
                    }

                    if (successCondition==totalCondition){
                        isMatch = true;
                    }
                }
                
                if (isMatch) {
                    Id workTypeId = workTypeNameToIdMap.get(config.Work_Type_Name__c);
                    if (workTypeId != null) {
                        workOrderRec.WorkTypeId = workTypeId;
                    }
                    break; // stop at first match
                }
            }
        }
    }
    
    private static Object getFieldValue(SObject obj, String fieldName) {
        if (obj.getSObjectType().getDescribe().fields.getMap().containsKey(fieldName)) {
            return obj.get(fieldName);
        }
        return null;
    }
    
    private static Boolean evaluateCondition(Object actual, String expected, String operator) {
        if (actual == null) return false;
        
        String actualStr = String.valueOf(actual).trim();
        expected = expected != null ? expected.trim() : '';
        
        switch on operator {
            when 'Equal'      { return actualStr == expected; }
            when 'Not Equal'  { return actualStr != expected; }
            when 'Contains'   { return actualStr.contains(expected); }
            when 'StartsWith' { return actualStr.startsWith(expected); }
            when 'EndsWith'   { return actualStr.endsWith(expected); }
            when else         { return false; }
        }
    }

    public static void createWorkPlan(List<WorkOrder> workOrders) {
        // Query work type to template mapping from custom metadata
        Map<String, String> workTypeToTemplateMap = new Map<String, String>();
        
        for (Work_Type_Mapping_Config__mdt config : [SELECT Work_Type_Name__c, Work_Plan_Template_Name__c
                                                        FROM Work_Type_Mapping_Config__mdt
                                                        WHERE Active__c = TRUE 
                                                        AND Manual__c = TRUE
                                                        AND Work_Plan_Template_Name__c != NULL]) {
            if (config.Work_Type_Name__c != null) {
                workTypeToTemplateMap.put(config.Work_Type_Name__c, config.Work_Plan_Template_Name__c);
            }
        }
        
        if (workTypeToTemplateMap.isEmpty()) {
            return; // Exit if no configurations found
        }
        
        // Query WorkTypes
        Map<String, Id> workTypeNameToIdMap = new Map<String, Id>();
        for (WorkType wt : [SELECT Id, Name FROM WorkType WHERE Name IN :workTypeToTemplateMap.keySet()]) {
            workTypeNameToIdMap.put(wt.Name, wt.Id);
        }
        
        if (workTypeNameToIdMap.isEmpty()) {
            return; // Exit if no work types found
        }
        
        // Query WorkPlanTemplates
        Map<String, WorkPlanTemplate> templateNameToTemplateMap = new Map<String, WorkPlanTemplate>();
        for (WorkPlanTemplate template : [SELECT Id, Description, Name FROM WorkPlanTemplate WHERE Name IN :workTypeToTemplateMap.values() AND IsActive = TRUE]) {
            templateNameToTemplateMap.put(template.Name, template);
        }
        
        if (templateNameToTemplateMap.isEmpty()) {
            return; // Exit if no templates found
        }
        
        // Group work orders by work type
        Map<Id, List<WorkOrder>> workTypeIdToWorkOrdersMap = new Map<Id, List<WorkOrder>>();
        for (WorkOrder wo : workOrders) {
            if (wo.WorkTypeId != null && workTypeNameToIdMap.values().contains(wo.WorkTypeId)) {
                if (!workTypeIdToWorkOrdersMap.containsKey(wo.WorkTypeId)) {
                    workTypeIdToWorkOrdersMap.put(wo.WorkTypeId, new List<WorkOrder>());
                }
                workTypeIdToWorkOrdersMap.get(wo.WorkTypeId).add(wo);
            }
        }
        
        if (workTypeIdToWorkOrdersMap.isEmpty()) {
            return; // Exit if no matching work orders
        }
        
        // Create WorkPlans
        List<WorkPlan> workPlansToInsert = new List<WorkPlan>();
        Map<Id, Id> workPlanToTemplateMap = new Map<Id, Id>(); // Track which template to use for each work plan
        
        for (String workTypeName : workTypeToTemplateMap.keySet()) {
            Id workTypeId = workTypeNameToIdMap.get(workTypeName);
            String templateName = workTypeToTemplateMap.get(workTypeName);
            WorkPlanTemplate template = templateNameToTemplateMap.get(templateName);
            
            if (workTypeId != null && template != null && workTypeIdToWorkOrdersMap.containsKey(workTypeId)) {
                for (WorkOrder wo : workTypeIdToWorkOrdersMap.get(workTypeId)) {
                    WorkPlan wp = new WorkPlan();
                    wp.WorkOrderId = wo.Id;
                    wp.Name = template.Name;
                    wp.Description = template.Description;
                    workPlansToInsert.add(wp);
                    // Store template Id for later use (will use index after insert)
                }
            }
        }
        
        if (!workPlansToInsert.isEmpty()) {
            insert workPlansToInsert;
            
            // Query all template entries for all templates
            Set<Id> templateIds = new Set<Id>();
            for (WorkPlanTemplate template : templateNameToTemplateMap.values()) {
                templateIds.add(template.Id);
            }
            
            Map<Id, List<WorkPlanTemplateEntry>> templateIdToEntriesMap = new Map<Id, List<WorkPlanTemplateEntry>>();
            for (WorkPlanTemplateEntry entry : [
                SELECT Id, WorkPlanTemplateId, ExecutionOrder, WorkStepTemplateId
                FROM WorkPlanTemplateEntry
                WHERE WorkPlanTemplateId IN :templateIds
                ORDER BY ExecutionOrder ASC
            ]) {
                if (!templateIdToEntriesMap.containsKey(entry.WorkPlanTemplateId)) {
                    templateIdToEntriesMap.put(entry.WorkPlanTemplateId, new List<WorkPlanTemplateEntry>());
                }
                templateIdToEntriesMap.get(entry.WorkPlanTemplateId).add(entry);
            }
            
            // Collect all WorkStepTemplate IDs
            Set<Id> workStepTemplateIds = new Set<Id>();
            for (List<WorkPlanTemplateEntry> entries : templateIdToEntriesMap.values()) {
                for (WorkPlanTemplateEntry entry : entries) {
                    if (entry.WorkStepTemplateId != null) {
                        workStepTemplateIds.add(entry.WorkStepTemplateId);
                    }
                }
            }
            
            // Query WorkStepTemplates
            Map<Id, WorkStepTemplate> workStepTemplateMap = new Map<Id, WorkStepTemplate>([
                SELECT Id, Name, Description, ActionDefinition, ActionType
                FROM WorkStepTemplate
                WHERE Id IN :workStepTemplateIds
            ]);
            
            // Create WorkSteps for each WorkPlan
            List<WorkStep> workStepsToInsert = new List<WorkStep>();
            
            for (WorkPlan wp : workPlansToInsert) {
                // Find the corresponding template based on work plan name
                WorkPlanTemplate wpTemplate = templateNameToTemplateMap.get(wp.Name);
                if (wpTemplate != null) {
                    List<WorkPlanTemplateEntry> templateEntries = templateIdToEntriesMap.get(wpTemplate.Id);
                    if (templateEntries != null) {
                        for (WorkPlanTemplateEntry entry : templateEntries) {
                            WorkStepTemplate template = workStepTemplateMap.get(entry.WorkStepTemplateId);
                            if (template != null) {
                                WorkStep ws = new WorkStep();
                                ws.WorkPlanId = wp.Id;
                                ws.Name = template.Name;
                                ws.Description = template.Description;
                                ws.ActionDefinition = template.ActionDefinition;
                                ws.ExecutionOrder = Integer.valueOf(entry.ExecutionOrder);
                                workStepsToInsert.add(ws);
                            }
                        }
                    }
                }
            }
            
            if (!workStepsToInsert.isEmpty()) {
                insert workStepsToInsert;
            }
        }
    }
}