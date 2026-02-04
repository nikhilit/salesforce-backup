/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 26-11-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   22-11-2025   Kartik Patkar, Appstrail   Initial Version
**/
public class WO_UpdateSendEmail_Batch implements Database.Batchable<SObject>, Database.Stateful {

    List<Id> woIds;

    public WO_UpdateSendEmail_Batch(List<Id> woIds) {
        this.woIds = woIds;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Send_Email__c
            FROM WorkOrder
            WHERE Id IN :woIds AND Send_Email__c = false
        ]);
    }

    public void execute(Database.BatchableContext bc, List<WorkOrder> scope) {
        // Enable bypass
        Metering_Bypass_Validation__c bs = Metering_Bypass_Validation__c.getInstance(UserInfo.getUserId());
        if (bs == null) {
            bs = new Metering_Bypass_Validation__c();
            bs.SetupOwnerId = UserInfo.getUserId();
        }
        bs.Bypass__c = true;
        upsert bs;
        
        for (WorkOrder wo : scope) {
            wo.Send_Email__c = true;
        }
        // update scope;
        Database.update(scope, false);

        // Disable bypass
        bs.Bypass__c = false;
        upsert bs;
    }

    public void finish(Database.BatchableContext bc) {}
}