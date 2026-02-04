public class BillingHandler {

    public static void markBillingToBeProcessed(List<Billing__c> newList, Map<Id, Billing__c> oldMap) {
        for (Billing__c bill : newList) {

            Boolean isNew = (oldMap == null || !oldMap.containsKey(bill.Id));
            Boolean textFieldChanged = false;
            Boolean hasNullLookup = false;
            Boolean invoiceNumberChanged = false;

            if (!isNew) {
                Billing__c oldBill = oldMap.get(bill.Id);

                if (bill.Contract_Account__c != oldBill.Contract_Account__c ||
                    bill.Business_Partner__c != oldBill.Business_Partner__c) {
                    textFieldChanged = true;
                }

                if (bill.Print_Doc_Number__c != oldBill.Print_Doc_Number__c) {
                    invoiceNumberChanged = true;
                }
            }
            if (bill.Contract_Account_Map__c  == null || bill.Account__c == null) {
                hasNullLookup = true;
            }

            if (isNew || textFieldChanged || hasNullLookup) {
                bill.To_be_processed__c = true;
            }

            if ((isNew || invoiceNumberChanged) && String.isNotBlank(bill.Print_Doc_Number__c)) {
                bill.Name = bill.Print_Doc_Number__c;
            }
        }
    }
}