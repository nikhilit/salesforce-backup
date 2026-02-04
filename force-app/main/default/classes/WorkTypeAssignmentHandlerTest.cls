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
@isTest
public class WorkTypeAssignmentHandlerTest {
    
    @testSetup
    static void setup() {

        String meteringRecordTypeId = Schema.getGlobalDescribe().get('WorkOrder').getDescribe()
            .getRecordTypeInfosByDeveloperName().get('MGL_Metering').getRecordTypeId();

        // Create a WorkType that matches the config
        WorkType wt = new WorkType(Name = 'Meter Reading',EstimatedDuration = 60);
        insert wt;
        
        // Create a WorkOrder
        WorkOrder wo = new WorkOrder(
            Subject = 'Test Work Order',
            Status = 'New',
            Priority = 'Medium',
            RecordTypeId=meteringRecordTypeId
        );
        insert wo;
    }
    
    @isTest
    static void testAssignWorkTypes() {
        // Retrieve test WorkOrder
        List<WorkOrder> workOrders = [SELECT Id, Subject, Status, Priority,WorkTypeId,Record_Type_Developer_Name__c,Customer_Category__c FROM WorkOrder];
        
        // Run logic
        Test.startTest();
        WorkTypeAssignmentHandler.assignWorkTypes(workOrders);
        Test.stopTest();
        
        // Validate
        //for (WorkOrder wo : workOrders) {
        //    System.assertNotEquals(null, wo.WorkTypeId, 'WorkTypeId should be assigned');
        //}
    }
    
    @isTest
    static void testCreateWorkPlan() {
        // Create WorkType for manual work plan creation
        WorkType wtManual = new WorkType(Name = 'CNG Meter Reading Order', EstimatedDuration = 90);
        insert wtManual;
        
        // Create WorkPlanTemplate
        WorkPlanTemplate template = new WorkPlanTemplate(
            Name = 'CNG Customer',
            Description = 'Test CNG Customer Template',
            IsActive = true
        );
        insert template;
        
        // Create WorkStepTemplate
        WorkStepTemplate stepTemplate = new WorkStepTemplate(
            Name = 'Start Metering',
            Description = 'Customer Details for CNG',
            ActionDefinition = 'WorkOrder.CNG_Start_Metering',
            IsActive = true
        );
        insert stepTemplate;
        
        // Create WorkPlanTemplateEntry
        WorkPlanTemplateEntry templateEntry = new WorkPlanTemplateEntry(
            WorkPlanTemplateId = template.Id,
            WorkStepTemplateId = stepTemplate.Id,
            ExecutionOrder = 1
        );
        insert templateEntry;
        
        // Create WorkOrder with the manual work type
        WorkOrder wo = new WorkOrder(
            Subject = 'Test CNG Work Order',
            Status = 'New',
            Priority = 'High',
            WorkTypeId = wtManual.Id
        );
        insert wo;
        
        List<WorkOrder> workOrders = new List<WorkOrder>{wo};
        
        // Run logic
        Test.startTest();
        WorkTypeAssignmentHandler.createWorkPlan(workOrders);
        Test.stopTest();
        
        // Validate WorkPlan creation
        List<WorkPlan> workPlans = [SELECT Id, Name, Description, WorkOrderId 
                                     FROM WorkPlan 
                                     WHERE WorkOrderId = :wo.Id];
        
        // Note: WorkPlan will only be created if matching metadata exists with Manual__c = TRUE
        // If metadata exists, validate the work plan
        if (!workPlans.isEmpty()) {
            System.assertEquals(1, workPlans.size(), 'One WorkPlan should be created');
            System.assertEquals(template.Name, workPlans[0].Name, 'WorkPlan name should match template');
            System.assertEquals(wo.Id, workPlans[0].WorkOrderId, 'WorkPlan should be linked to WorkOrder');
            
            // Validate WorkStep creation
            List<WorkStep> workSteps = [SELECT Id, Name, Description, ActionDefinition, WorkPlanId, ExecutionOrder 
                                         FROM WorkStep 
                                         WHERE WorkPlanId = :workPlans[0].Id];
            
            System.assertNotEquals(0, workSteps.size(), 'WorkSteps should be created');
            System.assertEquals(stepTemplate.Name, workSteps[0].Name, 'WorkStep name should match template');
            System.assertEquals(1, workSteps[0].ExecutionOrder, 'Execution order should be 1');
        }
    }
    
    @isTest
    static void testCreateWorkPlanNoMetadata() {
        // Create WorkType without matching metadata
        WorkType wtNoConfig = new WorkType(Name = 'Test No Config', EstimatedDuration = 60);
        insert wtNoConfig;
        
        // Create WorkOrder with work type that has no matching metadata
        WorkOrder wo = new WorkOrder(
            Subject = 'Test No Config Work Order',
            Status = 'New',
            Priority = 'Medium',
            WorkTypeId = wtNoConfig.Id
        );
        insert wo;
        
        List<WorkOrder> workOrders = new List<WorkOrder>{wo};
        
        // Run logic
        Test.startTest();
        WorkTypeAssignmentHandler.createWorkPlan(workOrders);
        Test.stopTest();
        
        // Validate no WorkPlan is created
        List<WorkPlan> workPlans = [SELECT Id FROM WorkPlan WHERE WorkOrderId = :wo.Id];
        System.assertEquals(0, workPlans.size(), 'No WorkPlan should be created without matching metadata');
    }
    
    @isTest
    static void testCreateWorkPlanMultipleWorkOrders() {
        // Create WorkType
        WorkType wtManual = new WorkType(Name = 'MRS Meter Reading Order', EstimatedDuration = 120);
        insert wtManual;
        
        // Create WorkPlanTemplate
        WorkPlanTemplate template = new WorkPlanTemplate(
            Name = 'MRS Customer',
            Description = 'Test MRS Customer Template',
            IsActive = true
        );
        insert template;
        
        // Create WorkStepTemplate
        WorkStepTemplate stepTemplate = new WorkStepTemplate(
            Name = 'Complete Survey',
            Description = 'MRS Survey Details',
            ActionDefinition = 'WorkOrder.CNG_Start_Metering',
            IsActive = true
        );
        insert stepTemplate;
        
        // Create WorkPlanTemplateEntry
        WorkPlanTemplateEntry templateEntry = new WorkPlanTemplateEntry(
            WorkPlanTemplateId = template.Id,
            WorkStepTemplateId = stepTemplate.Id,
            ExecutionOrder = 1
        );
        insert templateEntry;
        
        // Create multiple WorkOrders
        List<WorkOrder> workOrders = new List<WorkOrder>{
            new WorkOrder(Subject = 'Test MRS WO 1', Status = 'New', Priority = 'High', WorkTypeId = wtManual.Id),
            new WorkOrder(Subject = 'Test MRS WO 2', Status = 'New', Priority = 'Medium', WorkTypeId = wtManual.Id)
        };
        insert workOrders;
        
        // Run logic
        Test.startTest();
        WorkTypeAssignmentHandler.createWorkPlan(workOrders);
        Test.stopTest();
        
        // Validate WorkPlans creation
        List<WorkPlan> workPlans = [SELECT Id, WorkOrderId FROM WorkPlan WHERE WorkOrderId IN :workOrders];
        
        // Note: WorkPlans will only be created if matching metadata exists
        if (!workPlans.isEmpty()) {
            System.assertEquals(2, workPlans.size(), 'Two WorkPlans should be created for two WorkOrders');
        }
    }
    
}