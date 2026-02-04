/**
* @File Name : WorkOrderLItemRiserPaintingContr.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : August 17, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | August 17, 2025 |   | Initial Version
**/

public without sharing class WorkOrderLItemRiserPaintingContr {
    @AuraEnabled(cacheable=true)
    public static List<WorkOrderLineItemWrapper> getWorkOrderLineItems(Id workOrderId) {
        List<WorkOrderLineItem> items = [
            SELECT Id, Riser_Name__c
            FROM WorkOrderLineItem
            WHERE WorkOrderId = :workOrderId
            ORDER BY CreatedDate ASC
        ];

        List<WorkOrderLineItemWrapper> wrapperList = new List<WorkOrderLineItemWrapper>();
        Integer index = 1;
        for (WorkOrderLineItem woli : items) {
            wrapperList.add(new WorkOrderLineItemWrapper(index, woli.Id, woli.Riser_Name__c));
            index++;
        }
        return wrapperList;
    }

    public class WorkOrderLineItemWrapper {
        @AuraEnabled public Integer index { get; set; }
        @AuraEnabled public Id recordId { get; set; }
        @AuraEnabled public String name { get; set; }

        public WorkOrderLineItemWrapper(Integer idx, Id recId, String nm) {
            index = idx;
            recordId = recId;
            name = nm;
        }
    }
}