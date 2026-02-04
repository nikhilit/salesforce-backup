public class CaseEscalationHandler {
public static void updateRemainingTat(List<Case_Escalation__c> escalationList) {
     System.debug('escalationList'+escalationList);
    Set<Id> caseIds = new Set<Id>();
    for (Case_Escalation__c esc : escalationList) {
        if (esc.Case__c != null) {
            caseIds.add(esc.Case__c);
        }
    }

    Map<Id, Case> caseMap = new Map<Id, Case>(
        [SELECT Id, Remaining_TAT__c FROM Case WHERE Id IN :caseIds]
    );

    List<Case> casesToUpdate = new List<Case>();

    for (Case_Escalation__c esc : escalationList) {
        Case cs = caseMap.get(esc.Case__c);
        if (cs == null) continue;

        Integer remainingTat;

        // Apply your date-based logic
        if (esc.Assigned_To_Department_2__c == null) {
            remainingTat =
                esc.Actioned_By_Department__c.daysBetween(esc.Assigned_To_Department_1__c);
        } else {
            remainingTat =
                esc.Assigned_To_Department_2__c.daysBetween(esc.Assigned_To_Department_1__c);
        }

        // Assign depending on field type
        cs.Remaining_TAT__c = String.valueOf(remainingTat);

        casesToUpdate.add(cs);
    }

    if (!casesToUpdate.isEmpty()) {
        update casesToUpdate;
    }
}

}