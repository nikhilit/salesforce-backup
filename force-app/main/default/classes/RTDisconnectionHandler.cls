public class RTDisconnectionHandler {

    public static void processAccounts(Set<Id> accountIds) {
        
        // 🔁 Step 0: Fetch Custom Metadata
        Temporary_Disconnection__mdt config = [
            SELECT max_Due_Amount__c, Bills_To_Check__c 
            FROM Temporary_Disconnection__mdt 
            LIMIT 1
        ];
        Decimal maxDueAmount = config.max_Due_Amount__c;
        Integer billsToCheck = Integer.valueOf(config.Bills_To_Check__c);
        
        // Step 1: Fetch accounts
        List<Account> accountList = [
            SELECT Id, Name, Account_Email__c,Temp_Disconnection_Email_send_date__c
            FROM Account
            WHERE Id IN :accountIds
        ];

        // Step 2: Fetch latest WorkOrder per account
        Map<Id, WorkOrder> latestWorkOrderMap = new Map<Id, WorkOrder>();
        List<WorkOrder> workOrders = [
            SELECT Id, AccountId, Due_Amount__c, CreatedDate, Appointment_Status__c, R_T_Agency__c,RecordTypeId
            FROM WorkOrder
            WHERE AccountId IN :accountIds
            ORDER BY CreatedDate DESC
        ];

        for (WorkOrder wo : workOrders) {
            if (!latestWorkOrderMap.containsKey(wo.AccountId)) {
                latestWorkOrderMap.put(wo.AccountId, wo); // Latest due to DESC
            }
        }

        // Step 3: Fetch last 3 billing records
        Map<Id, List<Billing__c>> billsMap = new Map<Id, List<Billing__c>>();
        List<Billing__c> billingRecords = [
            SELECT Id, Business_Partner__c, Payment_Status__c, CreatedDate
            FROM Billing__c
            WHERE Business_Partner__c IN :accountIds
            ORDER BY CreatedDate DESC
        ];

        for (Billing__c bill : billingRecords) {
            if (!billsMap.containsKey(bill.Business_Partner__c)) {
                billsMap.put(bill.Business_Partner__c, new List<Billing__c>());
            }
            if (billsMap.get(bill.Business_Partner__c).size() < billsToCheck) {
                billsMap.get(bill.Business_Partner__c).add(bill);
            }
        }

        // Step 4: Final logic
        List<Account> accountsToUpdate = new List<Account>();

        for (Account acc : accountList) {
            Boolean shouldSend = false;

            if (latestWorkOrderMap.containsKey(acc.Id)) {
                WorkOrder wo = latestWorkOrderMap.get(acc.Id);
                if (wo.Due_Amount__c != null && wo.Due_Amount__c > maxDueAmount) {
                    shouldSend = true;
                }
            }

            if (!shouldSend && billsMap.containsKey(acc.Id)) {
                List<Billing__c> bills = billsMap.get(acc.Id);
                if (bills.size() == billsToCheck) {
                    Integer notPaidCount = 0;
                    for (Billing__c b : bills) {
                        if (b.Payment_Status__c == 'Not Paid') {
                            notPaidCount++;
                        }
                    }
                    if (notPaidCount == billsToCheck) {
                        shouldSend = true;
                    }
                }
            }

            if (
                shouldSend &&
                String.isNotBlank(acc.Account_Email__c) &&
                (acc.Temp_Disconnection_Email_send_date__c == null)
            ) {
                WorkOrder wo = latestWorkOrderMap.get(acc.Id);
                sendDisconnectionEmail(acc, wo.Id); // only first time
                acc.Temp_Disconnection_Email_send_date__c = Date.today();
                accountsToUpdate.add(acc);
            }
        }

        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }

    public static void followUpAfter15Days() {
         // Step 1: Fetch accounts where 15+ days have passed since email sent
        List<Account> accountsToCheck = [
            SELECT Id, Name, Temp_Disconnection_Email_send_date__c
            FROM Account
            WHERE Temp_Disconnection_Email_send_date__c <= :Date.today().addDays(-15)
        ];
    
        Set<Id> accountIds = new Set<Id>();
        for (Account acc : accountsToCheck) {
            accountIds.add(acc.Id);
        }
    
        // Step 2: Fetch latest WorkOrder for these accounts
        Map<Id, WorkOrder> workOrderMap = new Map<Id, WorkOrder>();
        for (WorkOrder wo : [
            SELECT Id, AccountId, Appointment_Status__c, CreatedDate, RecordTypeId, R_T_Agency__c
            FROM WorkOrder
            WHERE AccountId IN :accountIds
            ORDER BY CreatedDate DESC
        ]) {
            if (!workOrderMap.containsKey(wo.AccountId)) {
                workOrderMap.put(wo.AccountId, wo); // Latest per account
            }
        }
    
        // Step 3: Create new WorkOrders if status is Incomplete or Unattempted
        List<WorkOrder> newWorkOrders = new List<WorkOrder>();
        Id tempDisconnectionWorkTypeId = getWorkTypeIdByName('Temporary Disconnection (R&T)');
    
        for (Account acc : accountsToCheck) {
            WorkOrder latestWO = workOrderMap.get(acc.Id);
            if (latestWO != null && 
               (latestWO.Appointment_Status__c == 'Incomplete' || latestWO.Appointment_Status__c == 'Unattempted')) {
    
                Date emailSentDate = acc.Temp_Disconnection_Email_send_date__c;
                if (emailSentDate != null) {
                    DateTime startDateTime = DateTime.newInstance(emailSentDate.addDays(15), Time.newInstance(9, 0, 0, 0));
                    DateTime endDateTime   = DateTime.newInstance(emailSentDate.addDays(15), Time.newInstance(18, 0, 0, 0));
    
                    WorkOrder newWO = new WorkOrder();
                    newWO.AccountId = acc.Id;
                    newWO.Subject = 'Temporary Disconnection';
                    newWO.WorkTypeId = tempDisconnectionWorkTypeId;
                    newWO.ParentWorkOrderId = latestWO.Id;
                    newWO.StartDate = startDateTime;
                    newWO.RecordTypeId = latestWO.RecordTypeId;
                    newWO.R_T_Agency__c = latestWO.R_T_Agency__c;
                    newWO.EndDate = endDateTime;
                    newWorkOrders.add(newWO);
                }
            }
        }
    
        if (!newWorkOrders.isEmpty()) {
            insert newWorkOrders;
        }
    }

public static void sendDisconnectionEmail(Account acc, Id workOrderId) {
    try {
        // Generate PDF from VF page
        PageReference pdfPage = Page.DisconnectionNoticeForDomestic;
        pdfPage.getParameters().put('id', workOrderId); // Pass WorkOrder Id

        // Render as PDF
        Blob pdfBlob = pdfPage.getContentAsPDF();

        // Create attachment
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName('Disconnection_Notice.pdf');
        attachment.setBody(pdfBlob);
        attachment.setContentType('application/pdf');

        // Prepare email
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[] { acc.Account_Email__c });
        email.setSubject('Disconnection Notice');
        email.setPlainTextBody(
            'Dear Customer,\n\nPlease find attached your disconnection notice.\n\nRegards,\nSupport Team'
        );
        email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });

        // Send
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });

        System.debug('Email sent with PDF to Account: ' + acc.Id);
    } catch (Exception e) {
        System.debug('Email failed for Account: ' + acc.Id + ', Error: ' + e.getMessage());
    }
}

    public static Id getWorkTypeIdByName(String workTypeName) {
        WorkType wt = [SELECT Id FROM WorkType WHERE Name = :workTypeName LIMIT 1];
        return wt.Id;
    }
}