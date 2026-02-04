@isTest
public class IPDReportContrTest {

    @isTest
    static void testIPDReportContr() {

        // Create Account
        Account acc = new Account(
            Name = 'Test Account',
            FirstName__c = 'John',
            LastName__c = 'Doe',
            Customer_Contact_no__c = '9999999999'
        );
        insert acc;
        
          OperatingHours oph = new OperatingHours(Name = 'Test Operating Hours', TimeZone = 'Asia/Kolkata');
        insert oph;

        ServiceTerritory st = new ServiceTerritory(Name = 'Test Territory', IsActive = true, OperatingHoursId = oph.Id, Business_Partner_Category__c = 'Domestic');
        insert st;

       

        // Create Supervisor (User)
       // User supUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];

        // Create Agent (User)
      /*  User agent = new User(
            Alias = 'tagent',
            Email = 'testagent@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Agent',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = supUser.ProfileId,
            TimeZoneSidKey = 'Asia/Kolkata',
            Username = 'testagent' + System.currentTimeMillis() + '@test.com'
        );
        insert agent; */

        // Create WorkOrder
        WorkOrder wo = new WorkOrder(
            AccountId = acc.Id,
            ServiceTerritoryId = st.Id,
          //  WorkOrderNumber = 'WO-123',
          //  BP_Customer_Address__c = 'Test Address',
          //  BP_Number__c = 'BP123',
            Completion_Datetime__c = System.now(),
            Ensure_No_Gas_Leakage_Before_LeavingSit__c = 'Yes',
           // Agent__c = agent.Id,
            New_Meter_Make__c = 'Elster',
            Meter_Number__c = 12345,
            Final_Meter_Reading__c = 50,
            Final_Remark__c = 'Meter found Ok'
            //Plug_From__c = 'Plug Used'
        );
        insert wo;

        // Create ServiceAppointment
        ServiceAppointment sa = new ServiceAppointment(
            ParentRecordId = wo.Id,
            SchedStartTime = System.now().addDays(-1),
            SchedEndTime = System.now()
        );
        insert sa;

        // Create Material Consumption
        Material_Consumption__c mc = new Material_Consumption__c(
            Work_Order__c = wo.Id,
            Meter_Bracket__c = '1',
            Meter_Regulator__c = '1',
            Meter_Control_Valve__c = '1',
            Appliance_Valve__c = '2',
            Copper_Pipe_12mm_In_meter__c = '3',
            Br_Disconnection_Union_1_2_x_12mm__c = '1',
            Br_Disconnection_Union_3_4_x_12mm__c = '1',
            Meter_Inlet_Adaptor_3_4_x_3_4__c = '1',
            Meter_Outlet_Adaptor_3_4_x_12mm__c = '2',
            GI_Pipe__c = '5',
            Barrel_Nipple__c = '2',
            PRE_SLEEVED_GI_HOLE_PIECE__c = '1',
            Anaconda__c = '1',
            Br_Fitting_1_2_x_1_2__c = '1',
            MLC_Pipe_Length__c = '10'
        );
        insert mc;

        // Simulate VF Page parameter
        Test.startTest();
        PageReference pageRef = Page.IPDReport; // ⚡ Replace with actual VF page name
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', wo.Id);

        // Instantiate controller
        IPDReportContr controller = new IPDReportContr();

        // Assertions
       

        Test.stopTest();
    }

    @isTest
    static void testNoWorkOrderId() {
        Test.startTest();
        PageReference pageRef = Page.IPDReport; // ⚡ Replace with actual VF page name
        Test.setCurrentPage(pageRef);
        // No Id passed
        IPDReportContr controller = new IPDReportContr();
        Test.stopTest();
    }
}