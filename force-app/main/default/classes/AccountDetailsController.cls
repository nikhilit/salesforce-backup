public with sharing class AccountDetailsController {
    public class AccountWrapper {
        @AuraEnabled public Account account;
        @AuraEnabled public Device__c device;
        @AuraEnabled public Security_Deposit__c securitydeposit;
        @AuraEnabled public Identification_Number__c idnumber;
        @AuraEnabled public Identification_Number__c domId;
        @AuraEnabled public String status;
        @AuraEnabled public ServiceContract servicecontract;
        @AuraEnabled public String prospectNumber;
        @AuraEnabled public Chronology__c lastamountpaid;
        @AuraEnabled public Installation__c minimumcharges;
    }

    @AuraEnabled(cacheable=true)
    public static AccountWrapper getAccountDetails(Id accrcaseId) {
        System.debug('recordId: ' + accrcaseId);
        AccountWrapper wrapper = new AccountWrapper();

        Id accountId;
        Id leadId;

        if (accrcaseId != null && String.valueOf(accrcaseId).startsWith('500')) {
            // It's a Case ID, fetch related Account and Lead
            Case relatedCase = [
                SELECT Id, AccountId, Lead__c, Lead__r.Lead_No__c
                FROM Case
                WHERE Id = :accrcaseId
                LIMIT 1
            ];
            accountId = relatedCase.AccountId;
            leadId = relatedCase.Lead__c;
            wrapper.prospectNumber = relatedCase.Lead__r?.Lead_No__c; // Get Prospect Number from Lead
            System.debug('accountId from case: ' + accountId);
        } else {
            // Direct Account Id
            accountId = accrcaseId;
            System.debug('accountId directly used: ' + accountId);
        }

        // NULL check: If no account found, return early
        if (accountId == null && leadId == null) {
            wrapper.status = 'No Account or Lead Found';
            return wrapper;
        }

        // Fetch Account if available
        if (accountId != null) {
            wrapper.account = [
                SELECT Id, Name, FirstName__c, LastName__c, Account_Email__c,Building_Name_Conn__c,
                       Description, Phone__c, Room__c, City__c, Postal_Code__c,Security_Deposit__c,
                       Street__c, Street_Line_2__c, Street_Line_3__c, Street_Line_4__c, Street_Line_5__c,
                       Building_Code__c, BP_Number__c, Connection_Object__c, Secondary_Telephone__c, Phone,
                       Move_In_Date__c, Move_Out_Date__c, Blocking_Reason__c, Installation_Valid_From__c, Installation_Valid_To__c,
                       Full_Name__c, Floor__c,Service_Contract__r.Id,VIP_Customer__c,Remarks__c
                FROM Account
                WHERE Id = :accountId
                LIMIT 1
            ];

            if (wrapper.account.Move_Out_Date__c != null && wrapper.account.Move_Out_Date__c < System.today()) {
                wrapper.status = 'Inactive';
            } else {
                wrapper.status = 'Active';
            }

            // Fetch additional account data only if account exists
            List<Device__c> deviceList = [
                SELECT Id, Name, Last_Meter_Reading__c,Last_Meter_Date__c
                FROM Device__c
                WHERE Business_Partner__c = :accountId
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            wrapper.device = deviceList.isEmpty() ? null : deviceList[0];

            List<Security_Deposit__c> depositList = [
                SELECT Id, Req_Amount__c,Cash_Amount__c,Return_Date__c,Start_Date__c
                FROM Security_Deposit__c
                WHERE BP_Number__c = :accountId
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            wrapper.securitydeposit = depositList.isEmpty() ? null : depositList[0];
           
          List<Chronology__c> lastamountpaid = [
    SELECT Id, Credit_Amt__c
    FROM Chronology__c
    WHERE Credit_Amount_Currency__c != null
      AND Credit_Amount_Currency__c != 0.000
      AND Business_Partner__c = :accountId
    ORDER BY Net_Due_Date__c DESC
    LIMIT 1
];

wrapper.lastamountpaid = lastamountpaid.isEmpty() ? null : lastamountpaid[0];
 
/*List<Installation__c> minimumcharges = [
    SELECT Id, Charges_Valid_From__c, Charges_Valid_To__c, Minimum_Charges__c
    FROM Installation__c
    WHERE Minimum_Charges__c = 'true'
      AND BP__c = :accountId
    ORDER BY Charges_Valid_From__c DESC
    LIMIT 1
];
wrapper.minimumcharges = minimumcharges.isEmpty()? null : minimumcharges[0];
*/
            List<Identification_Number__c> idList = [
                SELECT Id, Name, ID_Number__c
                FROM Identification_Number__c 
                WHERE BP__c = :accountId AND Type_Desc__c = 'Application Form'
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            wrapper.idnumber = idList.isEmpty() ? null : idList[0];
            List<Identification_Number__c> domList = [
                SELECT Id, Name, ID_Number__c,Type__c,Type_Desc__c,Payment_Scheme__c
                FROM Identification_Number__c 
                WHERE BP__c = :accountId AND Type__c LIKE '%DOM%'
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            wrapper.domId = domList.isEmpty() ? null : domList[0];
            List<ServiceContract> caNumber=[SELECT Id,Contract_Account_Number__c FROM ServiceContract WHERE Business_Partner_Number__c=:wrapper.account.BP_Number__c];
            wrapper.servicecontract = caNumber.isEmpty() ? null : caNumber[0];
        } else if (leadId != null) {
            // If only Lead exists (no Account)
            wrapper.status = 'Prospect';
        }

        return wrapper;
    }
     @AuraEnabled
    public static Decimal getTotalCashAmount(Id accountId) {
    Decimal totalCashAmount = 0;

    List<Security_Deposit__c> deposits = [
        SELECT Id, Cash_Amount__c 
        FROM Security_Deposit__c 
        WHERE BP_Number__c = :accountId
    ];

    for (Security_Deposit__c dep : deposits) {
        if (dep.Cash_Amount__c != null) {
            totalCashAmount += dep.Cash_Amount__c;
        }
    }

    return totalCashAmount;
}
@AuraEnabled
public static Decimal getTotalCashAmountFromCase(Id caseId) {
    Decimal totalCashAmount = 0;

    // Get the related Account from Case
    Case c = [
        SELECT Id, AccountId
        FROM Case
        WHERE Id = :caseId
        LIMIT 1
    ];

    if (c.AccountId == null) {
        return 0; // No related account, return 0
    }

    // Fetch deposits using Account Id
    List<Security_Deposit__c> deposits = [
        SELECT Id, Cash_Amount__c 
        FROM Security_Deposit__c 
        WHERE BP_Number__c = :c.AccountId
    ];

    for (Security_Deposit__c dep : deposits) {
        if (dep.Cash_Amount__c != null) {
            totalCashAmount += dep.Cash_Amount__c;
        }
    }

    return totalCashAmount;
}

}