public without sharing class RiserMaintenancePageContr {

    public String wONumber {get;set;}
    public String issuedDate{get;set;}
    public String drsNo{get;set;}
    public String contractorName{get;set;}
    public String fieldAgent{get;set;}
    public String agencyName{get;set;}

    public String coNumber{get;set;}
    public String buildingName{get;set;}
    public String instrumentTypeAndRange{get;set;}
    public String calibrationDate{get;set;}
    public String calibrationCertificateNo{get;set;}
    public String calibrationDueDate{get;set;}
    public String comments{get;set;}
    public Datetime inpectionDate {get;set;}
    
    public List<WorkOrderLineItem> lstWOLItemAdded { get; set; }
    public List<LeakWrapper> leakList { get; set; }
    public List<Maintainence_Detail__c> mainDetails{get;set;} 

    public RiserMaintenancePageContr(){

        String workOrderLineItemId = ApexPages.currentPage().getParameters().get('Id');
        
        system.debug('workorderlineitemid::'+workOrderLineItemId);
        
        // Fetch WorkOrderLineItem
        WorkOrderLineItem woLineItem = [
            SELECT Id, WorkOrderId
            FROM WorkOrderLineItem
            WHERE Id = :workOrderLineItemId 
            LIMIT 1
        ];
        
        //Calibration_Certificate_No__c, Calibration_Date__c,Calibration_Due_Date__c, Instrument_Type_Range__c
        
        system.debug('workorderlineitem details::'+ woLineItem );
         
        // Fetch WorkOrder
        WorkOrder wo = [
            SELECT Id, WorkOrderNumber, Owner.Name, Agent__r.Name, Connection__c,
                   Connection__r.Name, Riser_Supervisor_Name__c, Connection__r.Building_Name__c,ServiceTerritory.Name,
                   RM_Instrument_Type_Range__c,RM_Calibration_Certificate_No__c,RM_Calibration_Date__c,
                     RM_Calibration_Due_Date__c
            FROM WorkOrder 
            WHERE Id = :woLineItem.WorkOrderId  
            LIMIT 1
        ];  
        
        system.debug('workorder details::'+ wo);
                              
        // Fetch Account
        Account accRecord = [
            SELECT Id, BP_Number__c, DRS_Master__c, DRS_Master__r.Name, Building_Name__c
            FROM Account
            WHERE Connection__c = :wo.Connection__c
            LIMIT 1
        ]; 
        
        system.debug('account:: '+ accRecord);       
                                                    
        // Assign page header values
        wONumber = wo.WorkOrderNumber;
        issuedDate = DateTime.newInstance(System.today(), Time.newInstance(0,0,0,0)).format('dd-MM-yyyy');
        drsNo = accRecord.DRS_Master__r.Name;
        contractorName = wo.Riser_Supervisor_Name__c;
        fieldAgent = wo.Agent__r.Name;
        agencyName = wo.ServiceTerritory.Name;
        coNumber = wo.Connection__r.Name;
        buildingName = wo.Connection__r.Building_Name__c;
       
       /* instrumentTypeAndRange = woLineItem.Instrument_Type_Range__c;
        calibrationDueDate = woLineItem.Calibration_Due_Date__c != null ? woLineItem.Calibration_Due_Date__c.format() : '';
        calibrationCertificateNo = woLineItem.Calibration_Certificate_No__c;
        calibrationDate = woLineItem.Calibration_Date__c != null ? woLineItem.Calibration_Date__c.format() : ''; */
        
         instrumentTypeAndRange = wo.RM_Instrument_Type_Range__c;
        calibrationDueDate = wo.RM_Calibration_Due_Date__c!= null ? wo.RM_Calibration_Due_Date__c.format() : '';
        calibrationCertificateNo = wo.RM_Calibration_Certificate_No__c;
        calibrationDate = wo.RM_Calibration_Date__c!= null ? wo.RM_Calibration_Date__c.format() : '';
                                                                
        // WorkOrderLineItems
        List<WorkOrderLineItem> lstWOLItem = [
            SELECT Id, WorkOrderId, Riser_Name__c, CreatedDate,
                   Test_Pressure__c, Duration__c, 
                   Number_of_leakages_rm__c, Riser_Tested_Status__c,
                   No_of_active_customers__c, Remark__c           
            FROM WorkOrderLineItem  
            WHERE  WorkOrderId = :woLineItem.WorkOrderId
        ];   
        
        system.debug('lstWOLItem ::'+ lstWOLItem );
        
        //Calibration_Certificate_No__c = :woLineItem.Calibration_Certificate_No__c 
                                                                         
        // Add 9 placeholders
        lstWOLItemAdded = new List<WorkOrderLineItem>();
        for (Integer i = 0; i < 9; i++) {
            if (i < lstWOLItem.size()) {
                lstWOLItemAdded.add(lstWOLItem[i]);
            } else {
                lstWOLItemAdded.add(new WorkOrderLineItem()); 
            }
        }
                                                                        
        // Leak detection WLIs
        List<WorkOrderLineItem> lstWOLItemDetection = [
            SELECT Id, WorkOrderId, 
             Number_of_leakages_rm__c,
                   Riser_Name__c, Leak_Locations_1__c, Leak_Locations_2__c, Leak_Locations_3__c,
                   Leak_Locations_4__c, Leak_Locations_5__c, Leak_Locations_6__c, Leak_Locations_7__c,
                   Leak_Locations_8__c, Leak_Locations_9__c, Leak_Locations_10__c        
            FROM WorkOrderLineItem  
            WHERE  WorkOrderId = :woLineItem.WorkOrderId
        ];   
        
        system.debug('lstWOLItemDetection:'+lstWOLItemDetection );
        
        //Calibration_Certificate_No__c = :woLineItem.Calibration_Certificate_No__c 
                                                                        
        leakList = new List<LeakWrapper>();

        if (!lstWOLItemDetection.isEmpty()) {
        system.debug('inside lstWOLItemDetection not empty');
            for (WorkOrderLineItem woli : lstWOLItemDetection) {
                    system.debug('inside lstWOLItemDetection not empty for loop');

                if (woli.Number_of_leakages_rm__c!= null) {
                                    
                        system.debug('inside if number of leakages not null');

                    Integer totalLeaks = Integer.valueOf(woli.Number_of_leakages_rm__c);
                    //woli.Number_of_leakages_rm__c.intValue();
                    system.debug('totalLeaks ::'+ totalLeaks );

                    
                    for (Integer i = 1; i <= totalLeaks && i <= 10; i++) {
                        String locationVal;
                        switch on i {
                            when 1 { locationVal = woli.Leak_Locations_1__c; }
                            when 2 { locationVal = woli.Leak_Locations_2__c; }
                            when 3 { locationVal = woli.Leak_Locations_3__c; }
                            when 4 { locationVal = woli.Leak_Locations_4__c; }
                            when 5 { locationVal = woli.Leak_Locations_5__c; }
                            when 6 { locationVal = woli.Leak_Locations_6__c; }
                            when 7 { locationVal = woli.Leak_Locations_7__c; }
                            when 8 { locationVal = woli.Leak_Locations_8__c; }
                            when 9 { locationVal = woli.Leak_Locations_9__c; }
                            when 10 { locationVal = woli.Leak_Locations_10__c; } 
                        } 
                         
                        if (String.isNotBlank(locationVal)) {
                        system.debug('locationVal ::'+ locationVal);
                            leakList.add(new LeakWrapper(i, woli.Riser_Name__c, locationVal));
                            
                        }
                    }
                }
            }
        }       

        // Query materials
        Set<Id> woliIds = new Set<Id>();
        for(WorkOrderLineItem woli : lstWOLItem) {
            woliIds.add(woli.Id);
        }
        system.debug('woliIds ::'+ woliIds);

        Map<Id, List<Material_Consumption__c>> woliIdToMaterials = new Map<Id, List<Material_Consumption__c>>();
        for(Material_Consumption__c mc : [
            SELECT Id, Work_Order_Line_Item__c,
                   Item_Code_Riser_Activity__c,
                   Item_Description_Riser_Activity__c,
                   Quantity__c
            FROM Material_Consumption__c
            WHERE Work_Order_Line_Item__c IN :woliIds
        ]){
            if(!woliIdToMaterials.containsKey(mc.Work_Order_Line_Item__c)){
                woliIdToMaterials.put(mc.Work_Order_Line_Item__c, new List<Material_Consumption__c>());
            }
            woliIdToMaterials.get(mc.Work_Order_Line_Item__c).add(mc);
        }

        // Attach materials into leakList
        for (LeakWrapper lw : leakList) {
            for (WorkOrderLineItem woli : lstWOLItemDetection) {
                if (lw.riserNumber == woli.Riser_Name__c && woliIdToMaterials.containsKey(woli.Id)) {
                    lw.materialList.addAll(woliIdToMaterials.get(woli.Id));
                }
            }
        }

    }                        
                                                                                                                    
    // === Inner Wrapper ===
    public class LeakWrapper {
        public Integer leakNumber {get; set;}
        public String  riserNumber {get; set;}
        public String  leakLocation {get; set;}
        public String  leakNature   {get; set;}
        public List<Material_Consumption__c> materialList {get; set;}

        public LeakWrapper() {
            materialList = new List<Material_Consumption__c>();
        }

        public LeakWrapper(Integer num, String riser, String location) {
            leakNumber   = num;
            riserNumber  = riser;
            leakLocation = location;
            leakNature   = '';
            materialList = new List<Material_Consumption__c>();
        }
    }
}