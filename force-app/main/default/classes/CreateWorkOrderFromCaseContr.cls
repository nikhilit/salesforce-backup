/**
* @File Name : CreateWorkOrderFromCaseContr.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : August 10, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | August 10, 2025 |   | Initial Version
**/
 
public without sharing class CreateWorkOrderFromCaseContr {
   
        @TestVisible private static String testScenario = null;
 
 
    @AuraEnabled
    public static List<WorkType> getlstWorkType(){
 
        try {
           
           
 
                    User userDetail = [Select Id,Profile.Name from User Where Id=: UserInfo.getUserId() limit 1];
 
                if(userDetail.Profile.Name =='AIC (O&M- IPD)' || userDetail.Profile.Name =='RubberHose AIC' || userDetail.Profile.Name=='O&M AIC IPD' || userDetail.Profile.Name=='O&M AIC Rubber Hose' || (Test.isRunningTest()  && testScenario == 'IPD')) {
 
                    List<WorkType> getWorkTypes = [select Id,Name from WorkType where Name IN('Individual Permanent Disconnection', 'Rubber Hose Replacement','Building Demolition')];
 
                        system.debug('getWorkTypes ::'+ getWorkTypes);
 
                        return  getWorkTypes;                  
 
                }
 
                if(userDetail.Profile.Name=='AIC (O&M- Domestic Meter Checking)' || userDetail.Profile.Name=='Escalation SPOC' || (Test.isRunningTest() && testScenario == 'RubberHose')) {
 
 
        List<WorkType> getWorkTypes = [select Id,Name from WorkType where  Name IN('Domestic Meter Checking','Meter Replacement')];
 
 
   
        system.debug('getWorkTypes ::'+ getWorkTypes);
            return getWorkTypes;
 
                }

                 if(userDetail.Profile.Name =='AIC (O&M- Meter Replacement)' || (Test.isRunningTest()  && testScenario == 'IPD')) {
 
                    List<WorkType> getWorkTypes = [select Id,Name from WorkType where Name IN('Meter Replacement')];
 
                        system.debug('getWorkTypes ::'+ getWorkTypes);
 
                        return  getWorkTypes;                  
 
                }
 
                if(userDetail.Profile.Name=='AIC (O&M- AfterSalesService)'){
 
                List<WorkType> getWorkTypes = [select Id,Name from WorkType where  Name='After sales Service'];
 
 
   
        system.debug('getWorkTypes ::'+ getWorkTypes);
            return getWorkTypes;
 
                }
            //buiding demolition
            // if(userDetail.Profile.Name=='AIC Building Demolition'){
 
            //     List<WorkType> getWorkTypes = [select Id,Name from WorkType where  Name='Building Demolition'];
            //     system.debug('getWorkTypes ::'+ getWorkTypes);
            // return getWorkTypes;
 
            //     }
                //end
 
            // need to uncomment this code when after sales app developed
            /*  if(userDetail.Profile.Name =='AIC (O&M- After Sales)' || userDetail.Profile.Name=='OMAICAfterSales' ||  (Test.isRunningTest() && testScenario == 'RubberHose')) {
 
 
        List<WorkType> getWorkTypes = [select Id,Name from WorkType where  Name IN('After Sales')];
 
 
   
        system.debug('getWorkTypes ::'+ getWorkTypes);
            return getWorkTypes;
 
                } */
 
                    return new List<WorkType>();
 
 
 
        }
        catch(Exception e){
 
            system.debug('Error getting work type::'+ e.getLineNumber() + e.getMessage());
 
            return new List<WorkType>();
        }
    }
    @AuraEnabled
    public static String assignWorkTypeToWorkOrder(List<String> reactiveValue, String selectedWorkTypeId){
 
 
        try {
        system.debug('Select records ids::'+ reactiveValue);
        system.debug('Select worktype id::'+ selectedWorkTypeId);
        //for building demolition
         User u = [
            SELECT Id, Profile.Name
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ];
        //end
        WorkType wType = [Select id,Name from WorkType where Id=:selectedWorkTypeId limit 1];
 
        system.debug('work type details ::'+ wType);
        //for building demolition
        //  if (u.Profile.Name == 'AIC Building Demolition'
        //     && wType.Name == 'Building Demolition')
        {
           // System.debug('Redirecting to CreateDemolitionWorkOrdersController');
            // List<Id> caseIds = new List<Id>();
            // caseIds.addAll(reactiveValue);
             //System.debug('caseIds::'+caseIds);
           // Map<String, Object> resp = CreateDemolitionWorkOrdersController.createDemolitionWorkOrders(caseIds);
           //return 'DEMOLITION';

         //System.debug('Demolition WO Response :: ' + resp);
         // System.debug('Demolition WO Response status :: ' + resp.get('status'));
           // return (String) resp.get('status');
       
 
        }
        //end
        Id workOrderRecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('MGL O&M').getRecordTypeId();    
 
        List<Case> lstCase = [Select id,AccountId,Remarks__c,O_M_Assigned_Case_Status__c from Case where Id IN:reactiveValue];
 
        List<WorkOrder> lstWorkOrder = new List<WorkOrder>();
 
        for(Case cs : lstCase){
 
            WorkOrder wo = new WorkOrder();
            wo.AccountId = cs.AccountId;
            wo.WorkTypeId = selectedWorkTypeId;
            wo.Case_Remark__c = cs.Remarks__c;
            wo.CaseId = cs.Id;
            wo.RecordTypeId = workOrderRecordTypeId;
            wo.Department__c = 'O&M';
 
            if(wType.Name=='After Sales Service'){
 
                //wo.Work_Order_Type__c='After Sales Service';
            }
 
            lstWorkOrder.add(wo);
 
 
        }
 
        if(!lstWorkOrder.isEmpty()){
 
            insert lstWorkOrder;
        }
 
        Set<Id> caseIds = new Set<Id>();
 
        List<WorkOrder> lstWorkOrderInserted = [Select id,CaseId from Workorder Where id IN: lstWorkOrder];
 
 
 
        for(WorkOrder wolst : lstWorkOrderInserted){
 
            caseIds.add(wolst.CaseId);
 
        }
 
        List<Case> lstCaseUpdate = [Select id,O_M_Assigned_Case_Status__c from Case Where Id IN: caseIds];
 
        for(Case updCase :lstCaseUpdate){
 
            updCase.O_M_Assigned_Case_Status__c = 'In Progress';
 
        }
 
        if(!lstCaseUpdate.isEmpty()){
 
            update lstCaseUpdate;
        }
 
            return 'Success';
 
        }
        catch(Exception e){
 
            system.debug('Error ::'+ e.getMessage() + e.getLineNumber());
 
            return 'Error';
        }
 
 
    }
}