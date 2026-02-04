trigger InvoiceLineItemTrigger on Invoice_Line_Item__c (before insert) {

    InvoiceLineItemTriggerHandler.poplateProductDetails(trigger.new);

}