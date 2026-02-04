@isTest
public class RiserMaintenancePageContrTest {
    
     @isTest
    static void testControllerConstructor() {
        
        Connection__c con = new Connection__c(Name = 'Test Connection');
        insert con;
        
        Account acc = new Account(
            Name = 'Test Account',
            Connection__c = con.Id,
            BP_Number__c = 'BP123',
            Building_Name__c = 'Test Building'
        );
        insert acc;

        DRS__c drs = new DRS__c(Name = 'DRS-01');
        insert drs;
        acc.DRS_Master__c = drs.Id;
        update acc;

        WorkOrder wo = new WorkOrder(
            AccountId = acc.Id,
            Connection__c = con.Id,
            Riser_Supervisor_Name__c = 'Contractor Test'
        );
        insert wo;

        WorkOrderLineItem woli = new WorkOrderLineItem(
            WorkOrderId = wo.Id,
            Riser_Name__c = 'Riser-1',
            Calibration_Certificate_No__c = 'CERT-001',
            Calibration_Date__c = System.today(),
            Calibration_Due_Date__c = System.today().addDays(90),
            Instrument_Type_Range__c = 'Type-1',
            Number_of_leakages_rm__c = 2,
            Leak_Locations_1__c = 'Kitchen',
            Leak_Locations_2__c = 'Bathroom'
        );
        insert woli;

        Material_Consumption__c mc = new Material_Consumption__c(
            Work_Order_Line_Item__c = woli.Id,
            Item_Code_Riser_Activity__c = '1030203010011',
            Item_Description_Riser_Activity__c = 'Meter Control Valve 1/2"',
            Quantity__c = 5
        );
        insert mc;

        Test.startTest();
        PageReference pageRef = Page.riserMaintenancePage; 
        pageRef.getParameters().put('Id', woli.Id);
        Test.setCurrentPage(pageRef);

        RiserMaintenancePageContr controller = new RiserMaintenancePageContr();
        Test.stopTest();

      
    }

}