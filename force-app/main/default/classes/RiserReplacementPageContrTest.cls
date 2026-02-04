@isTest
public class RiserReplacementPageContrTest {
    
    

    @testSetup
    static void setupTestData() {
        // Create Account
        Account acc = new Account(
            Name = 'Test Account',
            FirstName__c = 'John',
            LastName__c = 'Doe',
            BP_Number__c = 'BP123',
            Area__c = 'Area A',
            Building_Code__c = 'B01',
            Building_name__c = 'Test Building',
            Flat__c = '101',
            Colony__c = 'Test Colony',
            Plot__c = 'P123',
            Floor__c = '1st',
            Society_Name__c = 'Society 1',
            City__c = 'TestCity',
            Postal_Code__c = '123456',
            Road_name__c = 'Test Road',
            Street__c = 'Main St',
            Copper_MLC_Length__c = '15',
            Meter_Reading__c = '200',
            Meter_Number__c = 'MTR001',
            Regulator_Make__c = 'RegMake'
        );
        insert acc;

        // Create WorkOrder
        WorkOrder wo = new WorkOrder(
        Subject = 'Test WO',
        Status = 'New',
        OwnerId = UserInfo.getUserId(),
        Riser_Supervisor_Name__c = 'Supervisor 1',
        RM_Instrument_Type_Range__c = 'Type 1',
        RM_Calibration_Certificate_No__c = 'Cert123',
        RM_Calibration_Date__c = Date.today(),
        RM_Calibration_Due_Date__c = Date.today().addMonths(6)
    );
    insert wo;

        // Create WorkOrderLineItem (with calibration fields)
        WorkOrderLineItem woli = new WorkOrderLineItem(
        WorkOrderId = wo.Id,
        Description = 'Test WOLI'
    );
    insert woli;

        // Create Material Consumption linked to WorkOrderLineItem
       Material_Consumption__c mc = new Material_Consumption__c(
        Business_Partner__c = acc.Id,
        Work_Order_Line_Item__c = woli.Id,
        Item_Code_Riser_Activity__c = '1030203010011',
        Item_Description_Riser_Activity__c = 'Meter Control Valve 1/2"',
        Quantity__c = 2
    );
    insert mc;
    }

    @isTest
    static void testControllerConstructor() {
        // Get data
        Account acc = [SELECT Id FROM Account LIMIT 1];
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        // Set VF page and parameters
        Test.startTest();
        PageReference pageRef = Page.riserReplacementPage; // your VF page
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('accountId', acc.Id);
        ApexPages.currentPage().getParameters().put('workOrderId', wo.Id);

        // Instantiate controller
        RiserReplacementPageContr contr = new RiserReplacementPageContr();

        Test.stopTest();

        
    }



}