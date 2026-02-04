global class O_MWorkOrderCreationPeriodicBatchClass implements Database.Batchable<sObject> {
    
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        
        system.debug('inside batch class start method');
        try{
            
            //Days__mdt getDay = [select id,NumberOfDays__c from Days__mdt limit 1];
            
            Days__mdt getDay;
            if (Test.isRunningTest()) {
                // Provide fallback when running tests
                getDay = (Days__mdt) JSON.deserialize(
                    '{"NumberOfDays__c":30}', Days__mdt.class
                );
            } else {
                // Real metadata query
                getDay = [SELECT Id, NumberOfDays__c FROM Days__mdt LIMIT 1];
            }
            
            Integer compareDays = Integer.valueOf(getDay.NumberOfDays__c);
            Date compareDate = Date.today().addDays(-compareDays);
            
            system.debug('Get day::'+ compareDays);
            system.debug('compare date::'+ compareDate);
            
            
            return Database.getQueryLocator([SELECT id,Previous_Maintenance_Date__c from Account where Previous_Maintenance_Date__c = :compareDate]);
            
        }
        catch(Exception e){
            system.debug('Error ::'+ e.getMessage() + '  ' + e.getLineNumber());
            return null;
        }
        
    }
    
    global void execute(Database.BatchableContext BC, List<Account> accList) {
        
        system.debug('insdie execute method');
        List<WorkOrder> lstWorkOrder = new List<WorkOrder>();
        
        String workTypeName = Label.Riser_Maintenance_WorkType;
        string OMContractorUser = Label.O_M_Contractor_User;
        string workOrderSubject = Label.Periodic_Riser_Maintenance;
        string workOrderCategory = Label.WorkOrderRiserMaintenanceCategory;
        
        Id workOrderRecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('MGL O&M').getRecordTypeId();     
        
        User user = [Select id from User Where Name=:OMContractorUser limit 1];
        
        system.debug('User ::'+ user);
        WorkType wType = [Select id from WorkType Where Name=:workTypeName limit 1];
        system.debug('work type::'+ wType);
        for (Account acc : accList) {
            
            WorkOrder wOrder = new WorkOrder();
            wOrder.Subject = workOrderSubject;
            wOrder.WorkTypeId = wType.Id; 
            wOrder.Category__c = workOrderCategory;
            wOrder.AccountId = acc.Id;
            wOrder.OwnerId = user.Id;  
            wOrder.StartDate = system.now();
            wOrder.RecordTypeId = workOrderRecordTypeId;
            
            // wOrder.ServiceTerritoryId = serviceTerritoryId;
            
            lstWorkOrder.add(wOrder);
            
            
        }
        
        if(!lstWorkOrder.isEmpty()){
            insert lstWorkOrder;
        }
        
    }
    
    global void finish(Database.BatchableContext BC)
    {
        system.debug('Batch job completed.');
    }
    
    
    
}