public class MoveInOutTriggerHandler {

    public static void markMoveOutToBeProcessed(
        List<Move_In_Out__c> newList, 
        Map<Id, Move_In_Out__c> oldMap
    ) {
        Set<Id> bpNumberIds = new Set<Id>();
        for (Move_In_Out__c move : newList) {
            if (move.BP_Number__c != null) {
                bpNumberIds.add(move.BP_Number__c);
            }
        }

        Map<Id, String> accountBPMap = new Map<Id, String>();
        if (!bpNumberIds.isEmpty()) {
            for (Account acc : [
                SELECT Id, BP_Number__c
                FROM Account
                WHERE Id IN :bpNumberIds
            ]) {
                accountBPMap.put(acc.Id, acc.BP_Number__c);
            }
        }

        for (Move_In_Out__c move : newList) {
            Boolean isNew = oldMap == null || !oldMap.containsKey(move.Id);

            Boolean hasNullLookup = 
                move.BP_Number__c == null ||
                move.Premise_Name__c == null ||
                move.Installation_Name__c == null ||
                move.Contract_Account_Name__c == null;
            
            Boolean bpMismatch = false;
            if (move.BP_Number__c != null) {
                String accBP = accountBPMap.get(move.BP_Number__c);
                bpMismatch = accBP != null && accBP != move.Business_Partner__c;
            }

            Boolean businessPartnerChanged = false;
            if (!isNew) {
                Move_In_Out__c oldMove = oldMap.get(move.Id);
                businessPartnerChanged = (move.Business_Partner__c != oldMove.Business_Partner__c);
            }

            if (isNew || hasNullLookup || bpMismatch || businessPartnerChanged) {
                move.To_be_processed__c = true;
            }

            if ((isNew || businessPartnerChanged) && String.isNotBlank(move.Business_Partner__c)) {
                move.Name = move.Contract__c;
            }
        }
    }
}