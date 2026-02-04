@isTest
public class COExecutionDetailsRiserMaintenanceTest {

    @TestSetup
    static void setupTestData() {
        // Create a WorkType
        WorkType testWorkType = new WorkType(
            Name = 'Test WorkType',
            EstimatedDuration = 2.5,
            DurationType = 'Hours'
        );
        insert testWorkType;

        // 2️⃣ Create a WorkOrder
       /* WorkOrder testWorkOrder = new WorkOrder(
            WorkTypeId = testWorkType.Id,
            Status = 'New',
            Approval_Status__c = getValidApprovalStatus()
        );
        insert testWorkOrder; */
           
        
         Account acc = new Account(Name = 'Test Account');
        insert acc;
        
         String workOrderRecordTypeId = Schema.getGlobalDescribe().get('WorkOrder').getDescribe().getRecordTypeInfosByDeveloperName().get('MGL_O_M').getRecordTypeId();

        WorkOrder wo = new WorkOrder(
            Subject = 'Test WorkOrder',
            AccountId = acc.Id,
            Number_of_Risers__c = '1',
            Number_of_Floors__c = 1,
            Sample_BP_Number_1__c ='1',
            Sample_BP_Number_2__c ='1',
            Information_Board_available__c = 'No',
            Type_of_Riser__c = 'Welded',
            New_information_board_installed__c = 'Yes',
            RM_Instrument_Type_Range__c ='Type and Range',
            RM_Calibration_Certificate_No__c = '2233',
            RM_Calibration_Date__c = system.today(),
            RM_Calibration_Due_Date__c = system.today(),
            Instrument_Serial_Number__c = '22',
            RecordTypeId = workOrderRecordTypeId
            
        );
        insert wo;
        
        ServiceAppointment serApp = new ServiceAppointment();
        serApp.ParentRecordId = wo.Id;
        serApp.EarliestStartTime = system.now();
        serApp.DueDate = system.now();
        serApp.Is_Any_Copper_Leakage_Found__c = 'Yes';
        serApp.Is_Any_Crimp_Guard_Leakage_Found__c = 'Yes';
        serApp.Is_Any_SR_Leakage_Found__c = 'Yes';
        serApp.CopperLeakageFoundNotificationNo__c = '11';
        serApp.CrimpLeakageFoundNotificationNo__c = '22';
        serApp.SRLeakageFountNotificationNo__c = '33';

        insert serApp;
       
        
        
        WorkPlan testWorkPlan = new WorkPlan(
            Name = 'Test WorkPlan',
            WorkOrderId = wo.Id
        );
        insert testWorkPlan;
        
         List<WorkStep> workSteps = new List<WorkStep>{
            new WorkStep(
                Name = 'CO Execution Detail',
                WorkPlanId = testWorkPlan.Id,
                Status = 'New'
            ),
            new WorkStep(
                Name = 'Upload Site Documents',
                WorkPlanId = testWorkPlan.Id,
                Status = 'New'
            )
        };
        insert workSteps;

    }
 

    @isTest
    static void testUpdateWorkStepStatus() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        Test.startTest();
        COExecutionDetailsRiserMaintenanceContr.updateWorkStepStatus(wo.Id, 'CO Execution Detail');
        Test.stopTest();

        WorkStep ws = [SELECT Status FROM WorkStep WHERE ParentRecordId = :wo.Id AND Name='CO Execution Detail' LIMIT 1];
        System.assertEquals('Completed', ws.Status, 'WorkStep status should be updated');
    }
    
    @isTest
    static void getWorkOrderTest(){
        
        WorkOrder wo = [Select id,  Number_of_Risers__c,Number_of_Floors__c,Sample_BP_Number_1__c,
           				 Sample_BP_Number_2__c,Information_Board_available__c,Type_of_Riser__c,
           				 New_information_board_installed__c,RM_Instrument_Type_Range__c,RM_Calibration_Certificate_No__c,
                        RM_Calibration_Date__c,RM_Calibration_Due_Date__c,Instrument_Serial_Number__c from WorkOrder limit 1];
        
        String recordId = wo.Id;
        
        Test.startTest();
        
        COExecutionDetailsRiserMaintenanceContr.getWorkOrder(recordId);
        
        Test.stopTest();
    }

     @isTest
    static void getWorkOrderTestCatch(){
        
       /* WorkOrder wo = [Select id, Number_of_Floors__c,Sample_BP_Number_1__c,
           				 Sample_BP_Number_2__c,Information_Board_available__c,Type_of_Riser__c,
           				 New_information_board_installed__c from WorkOrder limit 1];
        
        String recordId = wo.Id; */
        
        Test.startTest();
        
            String fakeId = Id.valueOf('006000000000000AAA'); 

        
        COExecutionDetailsRiserMaintenanceContr.getWorkOrder(fakeId);
        
        Test.stopTest();
    }
    
     @isTest
    static void saveCODetailsTest(){
        
        WorkOrder wo = [Select id,  Number_of_Risers__c,Number_of_Floors__c,Sample_BP_Number_1__c,
           				 Sample_BP_Number_2__c,Information_Board_available__c,Type_of_Riser__c,
           				 New_information_board_installed__c,RM_Instrument_Type_Range__c,RM_Calibration_Certificate_No__c,
                        RM_Calibration_Date__c,RM_Calibration_Due_Date__c,Instrument_Serial_Number__c from WorkOrder limit 1];
        
        ServiceAppointment serApp = [Select id,ParentRecordId,Is_Any_Copper_Leakage_Found__c,Is_Any_Crimp_Guard_Leakage_Found__c,Is_Any_SR_Leakage_Found__c,
										CopperLeakageFoundNotificationNo__c,CrimpLeakageFoundNotificationNo__c,SRLeakageFountNotificationNo__c from ServiceAppointment limit 1];
        String recordId = wo.Id;
        
        String noOfFloors = string.valueOf(wo.Number_of_Floors__c);
        
        Test.startTest();
        
        COExecutionDetailsRiserMaintenanceContr.saveCODetails(recordId,wo.Number_of_Risers__c,
         wo.Sample_BP_Number_1__c,wo.Sample_BP_Number_2__c,wo.Information_Board_available__c,noOfFloors,
                                     wo.Type_of_Riser__c,wo.New_information_board_installed__c,wo.RM_Instrument_Type_Range__c,
                                   wo.RM_Calibration_Certificate_No__c,wo.RM_Calibration_Date__c,wo.RM_Calibration_Due_Date__c,wo.Instrument_Serial_Number__c
                                                             ,'Yes','22','Yes','33','Yes','44');
        
        Test.stopTest();
    }



}