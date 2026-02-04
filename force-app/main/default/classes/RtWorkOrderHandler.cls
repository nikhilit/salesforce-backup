public class RtWorkOrderHandler {
    
    // Use static block to fetch only once per transaction
    private static final Id MGL_RT_RecordTypeId = [
        SELECT Id FROM RecordType
        WHERE SObjectType = 'WorkOrder' AND DeveloperName = 'MGL_R_T'
        LIMIT 1
    ].Id;
    
    public static void sendSmsAfterCreation(List<WorkOrder> workOrders) {
        System.debug('WorkOrder Triggered - Count: ' + workOrders.size());
    
        Set<Id> accountIds = new Set<Id>();
        List<WorkOrder> filteredWOs = new List<WorkOrder>();
    
        for (WorkOrder wo : workOrders) {
            if (
                wo.AccountId != null &&
                wo.RecordTypeId == MGL_RT_RecordTypeId &&
                wo.EndDate != null
            ) {
                filteredWOs.add(wo);
                accountIds.add(wo.AccountId);
                System.debug('Selected WorkOrder: ' + wo.Id);
            } else {
                System.debug('Skipped WorkOrder: ' + wo.Id + ' | Reason: ' +
                    (wo.AccountId == null ? 'No AccountId; ' : '') +
                    (wo.RecordTypeId != MGL_RT_RecordTypeId ? 'Wrong RecordTypeId; ' : '') +
                    (wo.EndDate == null ? 'No EndDate; ' : ''));
            }
        }
    
        if (filteredWOs.isEmpty()) {
            System.debug('No WorkOrders with valid Account and MGL R&T RecordType');
            return;
        }
    
        Map<Id, Account> accMap = new Map<Id, Account>(
            [SELECT Id, Phone, Full_Name__c FROM Account WHERE Id IN :accountIds]
        );
        System.debug('Accounts fetched: ' + accMap.keySet());
    
        for (WorkOrder wo : filteredWOs) {
            Account acc = accMap.get(wo.AccountId);
            if (acc == null || String.isBlank(acc.Phone)) {
                System.debug('Skipping WO ' + wo.Id + ' due to missing phone/account.');
                continue;
            }
    
            Map<String, String> mergeFields = new Map<String, String>();
            mergeFields.put('Name', acc.Full_Name__c);
            mergeFields.put('EndDate', String.valueOf(wo.EndDate.format()));
    
            String message = 'Dear {!Name}, please pay before {!EndDate}.';
    
            // RTSmsApiCallout.sendSmsFuture(
            //     acc.Phone,
            //     message,
            //     String.valueOf(wo.Id),
            //     mergeFields
            // );
    
            System.debug('SMS send call made for WorkOrder: ' + wo.Id);
        }
    }
    
    
    // Send Mobile SMS once WorkOrder is marked Completed
    public static void sendSmsAfterCompletion(List<WorkOrder> updatedList, Map<Id, WorkOrder> oldMap) {
        System.debug('Checking WorkOrders for completion status...');
    
        Set<Id> accountIds = new Set<Id>();
        List<WorkOrder> eligibleWorkOrders = new List<WorkOrder>();
    
        for (WorkOrder wo : updatedList) {
            WorkOrder oldWo = oldMap.get(wo.Id);
    
            Boolean isNowCompleted = wo.Appointment_Status__c == 'Completed';
            Boolean wasNotCompleted = oldWo != null && oldWo.Appointment_Status__c != 'Completed';
    
            if (
                wo.RecordTypeId == MGL_RT_RecordTypeId &&
                isNowCompleted && wasNotCompleted &&
                wo.AccountId != null
            ) {
                eligibleWorkOrders.add(wo);
                accountIds.add(wo.AccountId);
                System.debug('WorkOrder eligible for completion SMS: ' + wo.Id);
            }
        }
    
        if (eligibleWorkOrders.isEmpty()) {
            System.debug('No eligible WorkOrders found for completion SMS.');
            return;
        }
    
        Map<Id, Account> accMap = new Map<Id, Account>(
            [SELECT Id, Phone, FirstName__c, LastName__c, Full_Name__c FROM Account WHERE Id IN :accountIds]
        );
    
        for (WorkOrder wo : eligibleWorkOrders) {
            Account acc = accMap.get(wo.AccountId);
            if (acc == null || String.isBlank(acc.Phone)) {
                System.debug('Skipping SMS for WorkOrder ' + wo.Id + ' due to missing phone or account.');
                continue;
            }
    
            Map<String, String> mergeFields = new Map<String, String>();
            mergeFields.put('Name', acc.Full_Name__c);
    
            String message = 'Dear {!Name}, your work has been completed.';
    
            // RTSmsApiCallout.sendSmsFuture(
            //     acc.Phone,
            //     message,
            //     String.valueOf(wo.Id),
            //     mergeFields
            // );
    
            System.debug('SMS sent for completed WorkOrder: ' + wo.Id);
        }
    }
    
    
    public static void assignAccountFromBPNumber(List<WorkOrder> workOrders) {
        System.debug('Starting assignAccountFromBPNumber...');
    
        // 1) Fetch MGL R&T RecordTypeId
        Id rtMglRtId = Schema.SObjectType.WorkOrder
            .getRecordTypeInfosByDeveloperName()
            .get('MGL_R_T')
            .getRecordTypeId();
    
        // 2) Collect BP numbers only for MGL R&T records
        Set<String> bpNumbers = new Set<String>();
        for (WorkOrder wo : workOrders) {
            if (wo.RecordTypeId == rtMglRtId && !String.isBlank(wo.Customer_BP_Number__c)) {
                bpNumbers.add(wo.Customer_BP_Number__c.trim());
            }
        }
        System.debug('BP numbers to query = ' + bpNumbers);
    
        if (bpNumbers.isEmpty()) {
            System.debug('No BP numbers found; exiting.');
            return;
        }
    
        // 3) Query Accounts and log exactly what we got back
        Map<String, Account> bpToAccountMap = new Map<String, Account>();
        for (Account acc : [
            SELECT Id, BP_Number__c 
            FROM Account 
            WHERE BP_Number__c IN :bpNumbers
        ]) {
            String bp = acc.BP_Number__c != null ? acc.BP_Number__c.trim() : '(null)';
            bpToAccountMap.put(bp, acc);
            System.debug('Found Account: Id=' + acc.Id + ', BP=' + bp);
        }
    
        // 4) Assign AccountId and log per record
        for (WorkOrder wo : workOrders) {
            if (wo.RecordTypeId != rtMglRtId || String.isBlank(wo.Customer_BP_Number__c)) {
                continue;
            }
            String bpKey = wo.Customer_BP_Number__c.trim();
            Account match = bpToAccountMap.get(bpKey);
            if (match != null) {
                wo.AccountId = match.Id;
            } else {
                System.debug(
                    'No matching Account for WO Number=' + wo.WorkOrderNumber +
                    ' (BP=' + bpKey + ')'
                );
            }
        }
        System.debug('assignAccountFromBPNumber completed.');
    }
    
    
 // Create Notification
public static void createNotificationAfterWorkOrderCreation(List<WorkOrder> workOrders) {
    Set<Id> rtIds = new Set<Id>();
    Set<Id> accIds = new Set<Id>();

    for (WorkOrder wo : workOrders) {
        System.debug('Checking WorkOrder: Id=' + wo.Id + ', RecordTypeId=' + wo.RecordTypeId + ', AccountId=' + wo.AccountId);
        if (wo.RecordTypeId != null) {
            rtIds.add(wo.RecordTypeId);
        }
        if (wo.AccountId != null) {
            accIds.add(wo.AccountId);
        }
    }

    // Fetch record type names
    Map<Id, String> rtIdToName = new Map<Id, String>();
    for (RecordType rt : [SELECT Id, Name FROM RecordType WHERE Id IN :rtIds AND SObjectType = 'WorkOrder']) {
        rtIdToName.put(rt.Id, rt.Name);
        System.debug('🗂 RecordType Fetched: ' + rt.Name + ' (Id=' + rt.Id + ')');
    }

    // Fetch accounts with phone numbers
    Map<Id, Account> accountMap = new Map<Id, Account>(
        [SELECT Id, Phone FROM Account WHERE Id IN :accIds]
    );

    for (Account acc : accountMap.values()) {
        System.debug('Account Phone Found: Id=' + acc.Id + ', Phone=' + acc.Phone);
    }

    List<Notification__c> notificationList = new List<Notification__c>();

    for (WorkOrder wo : workOrders) {
        String rtName = rtIdToName.get(wo.RecordTypeId);

        if (rtName == 'MGL R&T') {
            Notification__c notif = new Notification__c();
            notif.Status__c = 'Pending';
            notif.Type__c = 'WhatsApp';
            notif.Work_Order__c = wo.Id;
            notif.Template_Name__c = 'Sample Message Template';

            if (wo.AccountId != null && accountMap.containsKey(wo.AccountId)) {
                notif.Phone_Number__c = accountMap.get(wo.AccountId).Phone;
                notif.Business_Partner__c = wo.AccountId;
            }

            System.debug('Creating Notification for WO: ' + wo.Id + ', Phone: ' + notif.Phone_Number__c);
            notificationList.add(notif);
        } else {
            System.debug('WO: ' + wo.Id + ' - RecordType is not MGL R&T');
        }
    }

    
    if (!notificationList.isEmpty()) {
        insert notificationList;
        System.debug('Inserted ' + notificationList.size() + ' Notification(s)');
    } else {
        System.debug('No notifications to insert');
    }
}



}