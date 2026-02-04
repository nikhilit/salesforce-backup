public class ICDisconnectionFollowupHandler implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Date threeDaysAgo = Date.today().addDays(-3);
        System.debug('📅 Batch Start - Checking for WOs with EndDate <= ' + threeDaysAgo);

        return Database.getQueryLocator([
            SELECT Id, AccountId, WorkType.Name, EndDate, Invoice__c, RecordTypeId, R_T_Agency__c
            FROM WorkOrder
            WHERE WorkType.Name = 'Disconnection Notice (R&T)'
              AND EndDate <= :threeDaysAgo
        ]);
    }

    public void execute(Database.BatchableContext bc, List<WorkOrder> scope) {
        System.debug('▶️ Execute Called - Scope size: ' + scope.size());
        if (scope.isEmpty()) return;

        Set<Id> disconnectionWOIds = new Set<Id>();
        Set<String> invoiceNumbers = new Set<String>();
        Set<Id> accountIds = new Set<Id>();

        for (WorkOrder wo : scope) {
            disconnectionWOIds.add(wo.Id);
            if (wo.Invoice__c != null) invoiceNumbers.add(wo.Invoice__c.trim());
            if (wo.AccountId != null) accountIds.add(wo.AccountId);
        }

        System.debug('🔍 Invoice Numbers: ' + invoiceNumbers);
        System.debug('🔍 Account IDs: ' + accountIds);

        // Check if Temporary Disconnection already exists
        Set<Id> alreadyFollowedUp = new Set<Id>();
        for (WorkOrder childWO : [
            SELECT ParentWorkOrderId
            FROM WorkOrder
            WHERE WorkType.Name = 'Temporary Disconnection (R&T)'
              AND ParentWorkOrderId IN :disconnectionWOIds
        ]) {
            alreadyFollowedUp.add(childWO.ParentWorkOrderId);
        }
        System.debug(' Already Followed Up WOs: ' + alreadyFollowedUp);

        List<WorkOrder> eligibleWOs = new List<WorkOrder>();
        for (WorkOrder wo : scope) {
            if (!alreadyFollowedUp.contains(wo.Id)) {
                eligibleWOs.add(wo);
            }
        }

        System.debug(' Eligible WOs for follow-up: ' + eligibleWOs.size());

        if (eligibleWOs.isEmpty()) {
            System.debug('ℹ️ No eligible Disconnection Notice WOs for follow-up.');
            return;
        }

        // Fetch Billing Data
        Map<String, Map<Id, Billing__c>> invoiceAccountToBilling = new Map<String, Map<Id, Billing__c>>();
        for (Billing__c bill : [
            SELECT Id, Invoice_Number__c, Due_Amount__c, Business_Partner__c
            FROM Billing__c
            WHERE Invoice_Number__c IN :invoiceNumbers
              AND Business_Partner__c IN :accountIds
        ]) {
            if (!invoiceAccountToBilling.containsKey(bill.Invoice_Number__c)) {
                invoiceAccountToBilling.put(bill.Invoice_Number__c, new Map<Id, Billing__c>());
            }
            invoiceAccountToBilling.get(bill.Invoice_Number__c).put(bill.Business_Partner__c, bill);
        }

        System.debug(' Billing Records Fetched: ' + invoiceAccountToBilling.size());

        // Get WorkTypeId for Temporary Disconnection
        Id tempDisconnectionWorkTypeId;
        try {
            tempDisconnectionWorkTypeId = getWorkTypeIdByName('Temporary Disconnection (R&T)');
            System.debug('WorkTypeId for Temporary Disconnection: ' + tempDisconnectionWorkTypeId);
        } catch (Exception e) {
            System.debug(' Error fetching WorkTypeId: ' + e.getMessage());
            return;
        }

        List<WorkOrder> newWorkOrders = new List<WorkOrder>();

        for (WorkOrder wo : eligibleWOs) {
            if (wo.Invoice__c == null || wo.AccountId == null) continue;

            Map<Id, Billing__c> billingByAcc = invoiceAccountToBilling.get(wo.Invoice__c.trim());
            Billing__c billing = (billingByAcc != null) ? billingByAcc.get(wo.AccountId) : null;

            if (billing != null && billing.Due_Amount__c > 0) {
                WorkOrder newWO = new WorkOrder(
                    AccountId = wo.AccountId,
                    Subject = 'Temporary Disconnection',
                    WorkTypeId = tempDisconnectionWorkTypeId,
                    ParentWorkOrderId = wo.Id,
                    StartDate = DateTime.now(),
                    EndDate = DateTime.now().addDays(2),
                    RecordTypeId = wo.RecordTypeId,
                    R_T_Agency__c = wo.R_T_Agency__c,
                    Invoice__c = wo.Invoice__c
                );
                newWorkOrders.add(newWO);
                System.debug(' Creating new WorkOrder for ParentWO: ' + wo.Id + ', Invoice: ' + wo.Invoice__c);
            }
        }

        if (!newWorkOrders.isEmpty()) {
            try {
                insert newWorkOrders;
                System.debug(' Inserted ' + newWorkOrders.size() + ' Temporary Disconnection WOs');
            } catch (Exception ex) {
                System.debug(' Error inserting WorkOrders: ' + ex.getMessage());
                for (WorkOrder wo : newWorkOrders) {
                    System.debug(' Failed WorkOrder: ' + JSON.serialize(wo));
                }
            }
        } else {
            System.debug(' No new WorkOrders created — all bills are cleared or already followed up.');
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Batch Completed: ICDisconnectionFollowupHandler');
    }

    public static Id getWorkTypeIdByName(String workTypeName) {
        return [SELECT Id FROM WorkType WHERE Name = :workTypeName LIMIT 1].Id;
    }
}