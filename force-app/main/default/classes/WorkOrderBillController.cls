global without sharing class WorkOrderBillController {
    public WorkOrder currentWorkOrder { get; private set; }
    public String billUrl { get; private set; }

   public WorkOrderBillController() {
        Id woId = ApexPages.currentPage().getParameters().get('Id');
        String billNumber = ApexPages.currentPage().getParameters().get('bNo');

        if (woId != null) {
            currentWorkOrder = [
                SELECT Id, Bill_URL__c 
                FROM WorkOrder 
                WHERE Id = :woId
                LIMIT 1
            ];

            if (String.isNotBlank(currentWorkOrder.Bill_URL__c) && String.isNotBlank(billNumber)) {
                try {

                    List<Object> rawList = (List<Object>) JSON.deserializeUntyped(currentWorkOrder.Bill_URL__c);

                    if(!rawList.isEmpty()){
                        for(Object url : rawList){
                            Map<String, Object> urlMap = (Map<String, Object>) url;
                            if (urlMap.containsKey(billNumber)) {
                                billUrl = (String) urlMap.get(billNumber);
                                break;
                            }    
                        }
                    }

                } catch (Exception e) {
                    System.debug('Error parsing Bill_URL__c: ' + e.getMessage());
                    AS_ErrorLogger.log('WorkOrderBillController', 'WorkOrderBillController', e, woId);
                    billUrl = null;
                }
            }
        }
    }
}