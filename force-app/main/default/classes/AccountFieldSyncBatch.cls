global class AccountFieldSyncBatch implements Database.Batchable<SObject>, Schedulable  {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, 
                   /*Phone__c, Phone, 
                   Secondary_Phone__c, Secondary_Telephone__c, */
                   Email_Id__c, Account_Email__c
            FROM Account
            WHERE Is_Custom_Info_Different__c = TRUE
        ]);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        //List<Account> phoneList = new List<Account>();
        //List<Account> secondaryPhoneList = new List<Account>();
        List<Account> emailList = new List<Account>();

        for (Account acc : (List<Account>)scope) {
            // ✅ PHONE
            /*if (acc.Phone__c != acc.Phone) {
                phoneList.add(new Account(
                    Id = acc.Id,
                    Phone = acc.Phone__c != null ? acc.Phone__c : ''
                ));
            }*/

            // ✅ SECONDARY PHONE
            /*
            if (acc.Secondary_Phone__c != acc.Secondary_Telephone__c) {
                secondaryPhoneList.add(new Account(
                    Id = acc.Id,
                    Secondary_Telephone__c = acc.Secondary_Phone__c != null ? acc.Secondary_Phone__c : ''
                ));
            }
			*/

            // ✅ EMAIL
            if (acc.Email_Id__c != acc.Account_Email__c) {
                emailList.add(new Account(
                    Id = acc.Id,
                    Account_Email__c = acc.Email_Id__c != null ? acc.Email_Id__c : ''
                ));
            }
        }

        // ✅ Perform separate updates, avoid hitting DML limit
        /*
        if (!phoneList.isEmpty()) {
            Database.update(phoneList, false);
        }
        if (!secondaryPhoneList.isEmpty()) {
            Database.update(secondaryPhoneList, false);
        }
		*/
        if (!emailList.isEmpty()) {
            Database.update(emailList, false);
        }
    }

    global void finish(Database.BatchableContext bc) {
        // Optional logging or chaining
    }
    
    global void execute(SchedulableContext sc) {
        // Run batch with batch size 200
        Database.executeBatch(new AccountFieldSyncBatch(), 200);
    }
}