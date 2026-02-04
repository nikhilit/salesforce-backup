public class BankGuaranteeTriggerHandler {
    public static void shareWithDealer(List<Bank_Guarantee__c> newList) {
        Set<Id> stationIds = new Set<Id>();
        for (Bank_Guarantee__c bg : newList) {
            if (bg.Station__c != null) {
                stationIds.add(bg.Station__c);
            }
        }

        if (stationIds.isEmpty()) return;

        // 2. Get Stations with Parent Account
        Map<Id, Account> stationMap = new Map<Id, Account>(
            [
                SELECT Id, ParentId
                FROM Account
                WHERE Id IN :stationIds
            ]
        );

        // 3. Collect Parent Account Ids
        Set<Id> accountIds = new Set<Id>();
        for (Account st : stationMap.values()) {
            if (st.ParentId != null) {
                accountIds.add(st.ParentId);
            }
        }

        if (accountIds.isEmpty()) return;

        // 4. Get Users whose AccountId matches Parent Account
        Map<Id, User> accountToUserMap = new Map<Id, User>();
        for (User u : [
            SELECT Id, AccountId
            FROM User
            WHERE AccountId IN :accountIds
            AND IsActive = true
        ]) {
            // One user per account (if multiple, first one is used)
            if (!accountToUserMap.containsKey(u.AccountId)) {
                accountToUserMap.put(u.AccountId, u);
            }
        }

        if (accountToUserMap.isEmpty()) return;

        // 5. Fetch existing shares to avoid duplicates
        Set<Id> bgIds = new Set<Id>();
        for (Bank_Guarantee__c bg : newList) {
            bgIds.add(bg.Id);
        }
        // 6. Create shares
        List<Bank_Guarantee__Share> sharesToInsert = new List<Bank_Guarantee__Share>();

        for (Bank_Guarantee__c bg : newList) {

            Account st = stationMap.get(bg.Station__c);
            if (st == null) continue;

            User dealerUser = accountToUserMap.get(st.ParentId);
            if (dealerUser == null) continue;


                sharesToInsert.add(new Bank_Guarantee__Share(
                    ParentId = bg.Id,
                    UserOrGroupId = dealerUser.Id,
                    AccessLevel = 'Read',
                    RowCause = Schema.Bank_Guarantee__Share.RowCause.Manual
                ));
            }

        if (!sharesToInsert.isEmpty()) {
            insert sharesToInsert;
        }
    }
}