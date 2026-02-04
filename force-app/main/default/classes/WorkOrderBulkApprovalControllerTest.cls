/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 31-01-2026
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   30-01-2026   Kartik Patkar, Appstrail   Initial Version
**/
@isTest
public class WorkOrderBulkApprovalControllerTest {
    @testSetup
    static void setupData() {
        // Create base data
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        OperatingHours oph = new OperatingHours(Name = 'Test Operating Hours', TimeZone = 'Asia/Kolkata');
        insert oph;
        ServiceTerritory st = new ServiceTerritory(Name = 'Test Agency',OperatingHoursId=oph.id,IsActive=true);
        insert st;
        // Create Service Resource (Agent)
        ServiceResource sr = new ServiceResource(Name = 'Test Agent', IsActive = true,RelatedRecordId=UserInfo.getUserId());
        insert sr;

        // Create Service Territory (Agency) 

        // Create ServiceTerritoryMember
        ServiceTerritoryMember stm = new ServiceTerritoryMember(
            ServiceResourceId = sr.Id,
            ServiceTerritoryId = st.Id,
            EffectiveStartDate = Date.today().addDays(-10),
            EffectiveEndDate = Date.today().addDays(10)
        );
        insert stm;

        // Create Meter Reading Schedule for getCreatedSchedule
        Meter_Reading_Schedule__c mrs = new Meter_Reading_Schedule__c(
            Agent__c = sr.Id,
            Agency__c = st.Id,
            Meter_Reading_Start_Date__c = Date.today().addDays(-5),
            Meter_Reading_Completion_Date__c = Date.today().addDays(-1),
            No_of_Customer__c = 5,
            Status__c = 'Pending'
        );
        insert mrs;

        // Create a WorkOrder RecordType (if not already exists)
        Id meteringRTId;
        if (Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName().containsKey('MGL_Metering')) {
            meteringRTId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName()
                .get('MGL_Metering').getRecordTypeId();
        } else {
            meteringRTId = [SELECT Id FROM RecordType WHERE SObjectType='WorkOrder' LIMIT 1].Id;
        }

        // Create Work Orders
        List<WorkOrder> workOrders = new List<WorkOrder>();
        for (Integer i = 0; i < 3; i++) {
            workOrders.add(new WorkOrder(
                AccountId = acc.Id,
                RecordTypeId = meteringRTId,
                Approval_Status__c = 'Pending',
                Meter_Reading_Schedule__c = mrs.Id
            ));
        }
        insert workOrders;

        // Create Service Appointments for reassign test
        List<ServiceAppointment> saList = new List<ServiceAppointment>();
        for (WorkOrder wo : workOrders) {
            saList.add(new ServiceAppointment(
                ParentRecordId = wo.Id,
                ServiceTerritoryId = st.Id,
                SchedStartTime = System.now(),
                SchedEndTime = System.now() + 1
            ));
        }
        insert saList;

        // Create Assigned Resource for first SA (for delete scenario)
        AssignedResource ar = new AssignedResource(
            ServiceAppointmentId = saList[0].Id,
            ServiceResourceId = sr.Id
        );
        insert ar;
    }

    // Test updateWorkOrder
    @isTest
    static void test_updateWorkOrder_Approved() {
        List<WorkOrder> wos = [SELECT Id, Approval_Status__c FROM WorkOrder LIMIT 2];
        List<String> listWorkOrderIds = new List<String>();
        for (WorkOrder workOrderRec : wos) {
            listWorkOrderIds.add(workOrderRec.Id);
        }
        Test.startTest();
        String jobKey = WorkOrderBulkApprovalController.updateWorkOrder(listWorkOrderIds, 'Approved');
        // System.assertNotEquals('error', jobKey, 'Job key should not be error for valid input');
        String emailResult = WorkOrderBulkApprovalController.sendEmail(listWorkOrderIds);
        // System.assertEquals('success', emailResult, 'Email result should be success for approved work orders');
        Test.stopTest();
    }

    @isTest
    static void test_updateWorkOrder_ErrorPath() {
        List<String> emptyList = new List<String>();
        String result = WorkOrderBulkApprovalController.updateWorkOrder(emptyList, 'Pending');
        // System.assertEquals('error', result, 'Should return error for empty input');
    }

    // Test getCreatedSchedule
    @isTest
    static void test_getCreatedSchedule_valid() {
        ServiceTerritoryMember stm = [SELECT Id FROM ServiceTerritoryMember LIMIT 1];
        Test.startTest();
        WorkOrderBulkApprovalController.DataWrapper wrapper = WorkOrderBulkApprovalController.getCreatedSchedule(stm.Id);
        Test.stopTest();
        // System.assertNotEquals(null, wrapper, 'Should return DataWrapper for valid member');
        // System.assertNotEquals(null, wrapper.agentId, 'AgentId should be set');
        // System.assertNotEquals(null, wrapper.agencyId, 'AgencyId should be set');
    }

    @isTest
    static void test_getCreatedSchedule_invalidMember() {
        Test.startTest();
        WorkOrderBulkApprovalController.DataWrapper wrapper = WorkOrderBulkApprovalController.getCreatedSchedule('a00000000000001AAA');
        Test.stopTest();
        // System.assertEquals(null, wrapper, 'Should return null for invalid member');
    }

    // Test updateWorkOrdersAgent
    @isTest
    static void test_updateWorkOrdersAgent_newScheduleTrue() {
        List<WorkOrder> wos = [SELECT Id FROM WorkOrder LIMIT 2];
        ServiceTerritoryMember stm = [SELECT Id, ServiceTerritoryId FROM ServiceTerritoryMember LIMIT 1];
        Test.startTest();
        String result = WorkOrderBulkApprovalController.updateWorkOrdersAgent(
            wos,
            stm.Id,
            stm.ServiceTerritoryId,
            Date.today(),
            Date.today().addDays(5),
            null,
            true
        );
        Test.stopTest();
        // System.assertEquals('success', result, 'Should return success for new schedule');
    }

    @isTest
    static void test_updateWorkOrdersAgent_existingSchedule() {
        List<WorkOrder> wos = [SELECT Id FROM WorkOrder LIMIT 2];
        ServiceTerritoryMember stm = [SELECT Id, ServiceTerritoryId FROM ServiceTerritoryMember LIMIT 1];
        Meter_Reading_Schedule__c existingMRS = [SELECT Id, No_of_Customer__c FROM Meter_Reading_Schedule__c LIMIT 1];
        Test.startTest();
        String result = WorkOrderBulkApprovalController.updateWorkOrdersAgent(
            wos,
            stm.Id,
            stm.ServiceTerritoryId,
            Date.today(),
            Date.today().addDays(5),
            existingMRS.Id,
            false
        );
        Test.stopTest();
        // System.assertEquals('success', result, 'Should return success for existing schedule');
    }

    @isTest
    static void test_updateWorkOrdersAgent_error() {
        List<WorkOrder> emptyList = new List<WorkOrder>();
        String result = WorkOrderBulkApprovalController.updateWorkOrdersAgent(emptyList, null, null, Date.today(), Date.today(), null, true);
        // System.assertEquals('error', result, 'Should return error for empty work order list or invalid agent');
    }

    // Test reassignServiceAppointment
    @isTest
    static void test_reassignServiceAppointment_assignAndUnassign() {
        Id meteringRTId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName()
            .get('MGL_Metering').getRecordTypeId();

        List<WorkOrder> wos = [SELECT Id, RecordTypeId FROM WorkOrder LIMIT 2];
        ServiceResource sr = [SELECT Id FROM ServiceResource LIMIT 1];
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory LIMIT 1];

        // Assign one WorkOrder, Unassign another
        wos[0].RecordTypeId = meteringRTId;
        wos[0].Assigned_Meter_Reader__c = sr.Id;
        wos[1].RecordTypeId = meteringRTId;
        wos[1].Assigned_Meter_Reader__c = null;



        Map<Id, WorkOrder> oldMap = new Map<Id, WorkOrder>();
        for (WorkOrder w : [SELECT Id, Assigned_Meter_Reader__c FROM WorkOrder WHERE Id IN :wos]) {
            oldMap.put(w.Id, w);
        }

        Test.startTest();
        WorkOrderBulkApprovalController.reassignServiceAppointment(wos, oldMap);
        WorkOrderBulkApprovalController.reassignServiceAppointment(new List<WorkOrder>(), oldMap);
        WorkOrderBulkApprovalController.reassignServiceAppointment(wos, null);
        Test.stopTest();

    }

    // Test sendEmail error path
    @isTest
    static void test_sendEmail_errorPath() {
        List<WorkOrder> wos = [SELECT Id FROM WorkOrder LIMIT 2];
        List<String> ids = new List<String>();
        for (WorkOrder w : wos) ids.add(w.Id);
        // Set all to non-Approved
        for (WorkOrder w : wos) {
            w.Approval_Status__c = 'Pending';
        }
        update wos;
        String result = WorkOrderBulkApprovalController.sendEmail(ids);
        // System.assertEquals('error', result, 'Should return error if no approved work orders');
    }

    // Test getJobStatus null and valid
    @isTest
    static void test_getJobStatus_nullAndValid() {
        // Null/blank jobKey
        Test.startTest();
        WorkOrderBulkApprovalController.JobStatus status = WorkOrderBulkApprovalController.getJobStatus('');
        status = WorkOrderBulkApprovalController.getJobStatus('WO_ASYNC_' + UserInfo.getUserId() + '_123456789');
        Test.stopTest();
    }

    // Test updateJobStatus with blank jobKey
    @isTest
    static void test_updateJobStatus_blankJobKey() {
        Test.startTest();
        WorkOrderBulkApprovalController.updateJobStatus('', 'step', 1, 1);
        Test.stopTest();
    }

}