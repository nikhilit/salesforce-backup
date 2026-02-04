public class CustomAccountTriggerHandler {
    public static void populateRelatedDescription(List<Account__c> accList) {
        Map<Id, String> branchToUpdate = new Map<Id, String>();

        for (Account__c acc : accList) {
            if (acc.Branch_ID__c != null && acc.Description__c != null) {
                branchToUpdate.put(acc.Branch_ID__c, acc.Description__c);
            }
        }

        if (!branchToUpdate.isEmpty()) {
            List<Branch__c> branchList = [SELECT Id, Description__c FROM Branch__c WHERE Id IN :branchToUpdate.keySet()];

            for (Branch__c branch : branchList) {
                branch.Description__c = branchToUpdate.get(branch.Id);
            }

            if (!branchList.isEmpty()) {
                update branchList;
            }
        }
    }
}