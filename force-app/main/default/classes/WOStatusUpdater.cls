/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 21-11-2025
 * @last modified by  : Kartik Patkar Appstrail 
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   21-11-2025   Kartik Patkar, Appstrail   Initial Version
**/
public class WOStatusUpdater implements Queueable, Database.AllowsCallouts {
    List<Id> woIds;

    public WOStatusUpdater(List<Id> woIds) {
        this.woIds = woIds;
    }

    public void execute(QueueableContext qc) {
        List<WorkOrder> wos = [
            SELECT Id, Send_Email__c 
            FROM WorkOrder 
            WHERE Id IN :woIds
        ];

        for (WorkOrder wo : wos) {
            wo.Send_Email__c = true;
        }

        if (!wos.isEmpty()) {
            update wos;
        }
    }
}