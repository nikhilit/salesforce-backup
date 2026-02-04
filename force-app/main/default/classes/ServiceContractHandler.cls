public class ServiceContractHandler {
    public static void populateContractDetails(
        List<ServiceContract> newList,
        Map<Id, ServiceContract> oldMap
    ) {
        for (ServiceContract sc : newList) {
            ServiceContract oldSc = oldMap != null ? oldMap.get(sc.Id) : null;

            // 1. If record is new OR Business_Partner_Number__c changed
           if (oldSc == null || String.valueOf(sc.Business_Partner_Number__c) != String.valueOf(oldSc.Business_Partner_Number__c)) {
                  sc.To_Be_Processed__c = true;
          }


            // 2. If Contract_Account_Number__c changed
            if (oldSc == null || sc.Contract_Account_Number__c != oldSc.Contract_Account_Number__c) {
                if (sc.Contract_Account_Number__c != null) {
                    sc.Name = sc.Contract_Account_Number__c;
                }
            }
        }
    }
}