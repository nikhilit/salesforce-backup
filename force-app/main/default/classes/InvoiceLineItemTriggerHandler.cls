public class InvoiceLineItemTriggerHandler {
        public static void poplateProductDetails(List<Invoice_Line_Item__c> newlineitems){
            List<Id> productIds=new List<Id>();
            for (Invoice_Line_Item__c ln:newlineitems){
                productIds.add(ln.Product__c);
            }
            Map<Id,Product2> productDetailsMap=new Map<Id,Product2>([SELECT Id,Name,Rate__c,ProductCode FROM Product2 WHERE Id IN:productIds]);
            for (Invoice_Line_Item__c ln:newlineitems){
                ln.Description_of_Services__c=productDetailsMap.get(ln.Product__c).Name;
                ln.HSN_SAC__c=productDetailsMap.get(ln.Product__c).ProductCode;
                ln.Rate__c=productDetailsMap.get(ln.Product__c).Rate__c;
        }
    }
}