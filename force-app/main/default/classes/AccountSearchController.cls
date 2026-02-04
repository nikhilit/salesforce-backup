public with sharing class AccountSearchController {

    public class AccountWithCANumber {
        @AuraEnabled public Account account { get; set; }
        @AuraEnabled public String caNumber { get; set; }
        
        public AccountWithCANumber(Account acc) {
            this.account = acc;
            this.caNumber = '';
        }
    }
    @AuraEnabled
    public static List<AccountWithCANumber> searchAccounts(
        String firstName, String lastName, String caNumber, String bpNumber,
        String teleNumber, String postalCode, String city, String registrationInfoName,
        String buildingName, String streetname, String connection, String email, 
        String meternumber, String invoicenumber
    ) {
        if (String.isBlank(firstName) && String.isBlank(lastName) &&
            String.isBlank(caNumber) && String.isBlank(bpNumber) &&
            String.isBlank(teleNumber) && String.isBlank(postalCode) &&
            String.isBlank(city) && String.isBlank(connection) &&
            String.isBlank(email) && String.isBlank(buildingName) && String.isBlank(streetname) &&
            String.isBlank(meternumber) && String.isBlank(invoicenumber) &&
            String.isBlank(registrationInfoName)) 
        {
            return new List<AccountWithCANumber>();
        }

        // Collect accountIds from related objects
        Set<Id> accountIdsFromCA     = new Set<Id>();
        
        Set<Id> accountIdsFromReg    = new Set<Id>();
        Set<Id> accountIdsFromMeter  = new Set<Id>();
        Set<Id> accountIdsFromBill   = new Set<Id>();

        // 🔎 Contract Account Number → BP Numbers
        // if (!String.isBlank(caNumber)) {
        //     for (Move_In_Out__c service : [
        //         SELECT BP_Number__c 
        //         FROM Move_In_Out__c 
        //         //WHERE Contract_Account__c LIKE :('%' + caNumber + '%')
        //         WHERE Contract_Account__c =:caNumber
        //         AND BP_Number__c != null
        //     ]) {
        //         accountIdsFromCA.add(service.BP_Number__c);
        //     }
        //     if (accountIdsFromCA.isEmpty()) {
        //         return new List<AccountWithCANumber>(); // no matches possible
        //     }
        // }
         if (!String.isBlank(caNumber)) {
            for (ServiceContract service : [
                SELECT AccountId,Contract_Account_Number__c 
                FROM ServiceContract 
              //  WHERE Contract_Account_Number__c LIKE :('%' + caNumber + '%')
               WHERE Contract_Account_Number__c =:caNumber
                AND AccountId != null
            ]) {
                accountIdsFromCA.add(service.AccountId);
            }
            if (accountIdsFromCA.isEmpty()) {
                return new List<AccountWithCANumber>(); // no matches possible
            }
        }

        // 🔎 Application Form Number → BP
        if (!String.isBlank(registrationInfoName)) {
            for (Identification_Number__c reg : [
                SELECT BP__c
                FROM Identification_Number__c 
                WHERE Type_Desc__c = 'Application Form' 
                AND ID_Number__c LIKE :('%' + registrationInfoName + '%')
                AND BP__c != null
            ]) {
                accountIdsFromReg.add(reg.BP__c);
            }
            if (accountIdsFromReg.isEmpty()) {
                return new List<AccountWithCANumber>(); // no matches possible
            }
        }

        // 🔎 Meter Number → Installation → BP
        // 🔎 Meter Number → Device Allocation → Installation → Account
 if (!String.isBlank(meternumber)) {
            Set<String> installationIds = new Set<String>();
            for (Device_Allocation__c dev : [
                SELECT Installation_Number__c
                FROM Device_Allocation__c
               // WHERE Device__r.Manuf_Serial_No__c LIKE :('%' + meternumber + '%')
                WHERE Device__r.Manuf_Serial_No__c = :meternumber
                AND Installation_Number__c != null
            ]) {
                installationIds.add(dev.Installation_Number__c);
            }

            if (!installationIds.isEmpty()) {
                for (Move_In_Out__c mio : [
                    SELECT BP_Number__c
                    FROM Move_In_Out__c 
                    WHERE Installation__c IN :installationIds 
                    AND BP_Number__c != null
                    AND Move_Out__c != NULL
                    ORDER BY Move_Out__c DESC
                ]) {
                    accountIdsFromMeter.add(mio.BP_Number__c);
                }
            }
            if (accountIdsFromMeter.isEmpty()) {
                return new List<AccountWithCANumber>(); // no matches possible
            }
        }


        if (!String.isBlank(invoicenumber)) {
            for (Billing__c bill : [
                SELECT Account__c
                FROM Billing__c 
                WHERE Print_Doc_Number__c LIKE :('%' + invoicenumber + '%')
                AND Account__c != null
            ]) {
                accountIdsFromBill.add(bill.Account__c);
            }
            if (accountIdsFromBill.isEmpty()) {
                return new List<AccountWithCANumber>(); // no matches possible
            }
        }

        String baseQuery = 
            'SELECT Id, FirstName__c, LastName__c, BP_Number__c, Phone, ' +
            'Connection_Object__c, Application_Number__c, Building_Name_Conn__c, ' +
            'Account_Email__c, Postal_Code__c, City__c, Floor__c, Room__c,CA_Number__c, ' +
            'Connection__r.Project_Area__c, Connection__r.Status__c,Status__c,Connection__r.Search_Term__c, ' +
            'Connection__r.Street_2__c, Connection__r.Street_3__c, Connection__r.Street__c, ' +
            'Connection__r.Street_4__c, Connection__r.Street_5__c, Connection__r.Region_Name__c, ' +
            'Connection__r.Region__c, Connection__r.Country__c, Connection__r.Country_Code__c, ' +
            'Connection__r.City__c, Street__c, Street_Line_2__c, Street_Line_3__c, Street_Line_4__c, Street_Line_5__c, ' +
            'Flat__c, Secondary_Telephone__c, Full_Name__c, Premise_Name__c, ' +
            '(SELECT ID_Number__c, Type_Desc__c FROM Identification_Numbers__r ' +
            ' WHERE Type_Desc__c = \'Application Form\' ORDER BY CreatedDate DESC LIMIT 1), ' +
            '(SELECT Move_In_Date__c, Move_Out_Date__c FROM Move_In_Outs__r LIMIT 1) ' +
            'FROM Account WHERE Id != null';

        if (!String.isBlank(firstName))    baseQuery += ' AND FirstName__c LIKE \'%' + String.escapeSingleQuotes(firstName) + '%\'';
        if (!String.isBlank(lastName))     baseQuery += ' AND LastName__c LIKE \'%' + String.escapeSingleQuotes(lastName) + '%\'';
        //if (!String.isBlank(bpNumber))     baseQuery += ' AND BP_Number__c LIKE \'%' + String.escapeSingleQuotes(bpNumber) + '%\'';
        if (!String.isBlank(bpNumber))baseQuery += ' AND BP_Number__c = \'' + String.escapeSingleQuotes(bpNumber) + '\'';
        if (!String.isBlank(teleNumber)) baseQuery += ' AND (Phone = \'' + String.escapeSingleQuotes(teleNumber) + '\' OR Secondary_Telephone__c = \'' + String.escapeSingleQuotes(teleNumber) + '\')';
       // if (!String.isBlank(teleNumber))   baseQuery += ' AND (Phone LIKE \'%' + String.escapeSingleQuotes(teleNumber) + '%\' OR Secondary_Telephone__c LIKE \'%' + String.escapeSingleQuotes(teleNumber) + '%\')';
        if (!String.isBlank(postalCode))   baseQuery += ' AND Postal_Code__c LIKE \'%' + String.escapeSingleQuotes(postalCode) + '%\'';
        if (!String.isBlank(city))         baseQuery += ' AND City__c LIKE \'%' + String.escapeSingleQuotes(city) + '%\'';
        if (!String.isBlank(buildingName)) baseQuery += ' AND Building_Name_Conn__c LIKE \'%' + String.escapeSingleQuotes(buildingName) + '%\'';
        if (!String.isBlank(streetname)) {
            String streetFilter = String.escapeSingleQuotes(streetname);
            baseQuery += ' AND (Street__c LIKE \'%' + streetFilter + '%\' OR ' +
                        'Street_Line_2__c LIKE \'%' + streetFilter + '%\' OR ' +
                        'Street_Line_3__c LIKE \'%' + streetFilter + '%\' OR ' +
                        'Street_Line_4__c LIKE \'%' + streetFilter + '%\' OR ' +
                        'Street_Line_5__c LIKE \'%' + streetFilter + '%\')';
        }
        if (!String.isBlank(connection))   baseQuery += ' AND Connection_Object__c LIKE \'%' + String.escapeSingleQuotes(connection) + '%\'';
        if (!String.isBlank(email))        baseQuery += ' AND Account_Email__c LIKE \'%' + String.escapeSingleQuotes(email) + '%\'';

        // Related filters
        if (!accountIdsFromReg.isEmpty())   baseQuery += ' AND Id IN :accountIdsFromReg';
        if (!accountIdsFromMeter.isEmpty()) baseQuery += ' AND Id IN :accountIdsFromMeter';
        if (!accountIdsFromBill.isEmpty())  baseQuery += ' AND Id IN :accountIdsFromBill';
        if (!accountIdsFromCA.isEmpty())    baseQuery += ' AND Id IN :accountIdsFromCA';

        baseQuery += ' LIMIT 5000';

        // Execute query
        List<Account> accounts = Database.query(baseQuery);

        // Wrap and enrich with CA number
        Map<Id, AccountWithCANumber> accountIdToWrapper = new Map<Id, AccountWithCANumber>();
        for (Account acc : accounts) {
            AccountWithCANumber wrapper = new AccountWithCANumber(acc);
            accountIdToWrapper.put(acc.Id, wrapper);
        }

        if (!accounts.isEmpty()) {
            // for (Move_In_Out__c service : [
            //     SELECT BP_Number__c, Contract_Account__c
            //     FROM Move_In_Out__c 
            //     WHERE BP_Number__c IN :accountIdToWrapper.keySet()
            //     ORDER BY CreatedDate DESC
            // ]) {
            //     if (accountIdToWrapper.containsKey(service.BP_Number__c)) {
            //         accountIdToWrapper.get(service.BP_Number__c).caNumber = service.Contract_Account__c;
            //     }
            // }
            for (ServiceContract service : [
                SELECT AccountId,Contract_Account_Number__c 
                FROM ServiceContract 
                //WHERE Contract_Account_Number__c LIKE :('%' + caNumber + '%')
                 WHERE Contract_Account_Number__c =:caNumber
                AND AccountId != null
            ])  {
                if (accountIdToWrapper.containsKey(service.AccountId)) {
                    accountIdToWrapper.get(service.AccountId).caNumber = service.Contract_Account_Number__c;
                }
            }
        }

        return accountIdToWrapper.values();
    }


    @AuraEnabled
    public static String createLead(
        String firstName,
        String lastName,
        String phone,
        String email,
        String drsId,
        String leadType,
        String floor,
        String buildingName,
        String buildingCode,
        String street,
        String street2,
        String street3,
        String street4,
        String street5,
        String flat,
        String city,
        String district,
        String postalCode,
        String country,
        String timeZone,
        String region,
        String othercity,
        String nameandNoofWings,
        String potentialInEachWing,
        String totalNosOfFloor,
        String gaValue,
        String plotNo
    ) {
        Group marketingQueue = [
            SELECT Id
            FROM Group
            WHERE Name = 'Marketing Queue' AND Type = 'Queue'
            LIMIT 1
        ];
        
        drsId = drsId == null || drsId == '' ? null : drsId;
        System.debug('nameandNoofWings'+nameandNoofWings);
        Lead newLead = new Lead(
            FirstName = firstName,
            LastName = lastName,
            Phone = phone,
            Email = email,
            OwnerId = marketingQueue.Id,
            DRS__c = drsId,
            Type__c = leadType,
            Floor__c = floor,
            GA__c = gaValue,
            Building_Name__c = buildingName,
            Building_Code__c = buildingCode,
            Street__c = street,
            Street_Line_2__c = street2,
            Street_Line_3__c = street3,
            Flat__c = flat,
            City__c = city,
            District__c = district,
            Postal_Code__c = postalCode,
            Country__c = country,
            Time_Zone__c = timeZone,
            Region__c = region,
            Street_Line_4__c = street4,
            Street_Line_5__c = street5,
            Other_City__c = othercity,
            Plot_No__c = plotNo,
            Total_Nos_Of_Floor__c = totalNosOfFloor,
            Name_No_of_Wings__c = nameandNoofWings,
            Potential_In_Each_Wing__c = potentialInEachWing
        );

        try {
            insert newLead;
            return newLead.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error creating Lead: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<DRS__c> getDRSList() {
        return [
            SELECT Id, Name 
            FROM DRS__c Where Is_CRM__c=true
            ORDER BY Name 
        ];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getLeadTypeValues() {
        List<String> values = new List<String>();
        for (Schema.PicklistEntry entry : Lead.Type__c.getDescribe().getPicklistValues()) {
            if (entry.isActive()) {
                values.add(entry.getLabel());
            }
        }
        return values;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Lead> searchLeads(
        String firstName, String lastName, String leadProspect, String phone,
        String email, String postalCode,
        String city, String street
    ) {
        String query = 'SELECT Id, FirstName, LastName, Lead_No__c, Phone, Email, ' +
            'Postal_Code__c, City__c, Street__c, Street_Line_2__c,Street_Line_3__c,Street_Line_4__c,Street_Line_5__c,Building_Name__c ' +
            'FROM Lead WHERE ';
        
        List<String> conditions = new List<String>();
        
        if (String.isNotBlank(firstName)) {
            conditions.add('FirstName LIKE \'%' + String.escapeSingleQuotes(firstName) + '%\'');
        }
        if (String.isNotBlank(lastName)) {
            conditions.add('LastName LIKE \'%' + String.escapeSingleQuotes(lastName) + '%\'');
        }
        if (String.isNotBlank(leadProspect)) {
            conditions.add('Lead_No__c LIKE \'%' + String.escapeSingleQuotes(leadProspect) + '%\'');
        }
        if (String.isNotBlank(phone)) {
            conditions.add('Phone LIKE \'%' + String.escapeSingleQuotes(phone) + '%\'');
        }
        if (String.isNotBlank(email)) {
            conditions.add('Email LIKE \'%' + String.escapeSingleQuotes(email) + '%\'');
        }
        if (String.isNotBlank(postalCode)) {
            conditions.add('Postal_Code__c LIKE \'%' + String.escapeSingleQuotes(postalCode) + '%\'');
        }
        if (String.isNotBlank(city)) {
            conditions.add('City__c LIKE \'%' + String.escapeSingleQuotes(city) + '%\'');
        }
        if (String.isNotBlank(street)) {
            conditions.add(
             '(Street__c LIKE \'%' + String.escapeSingleQuotes(street) + '%\' OR ' +
             'Street_Line_2__c LIKE \'%' + String.escapeSingleQuotes(street) + '%\' OR ' +
             'Street_Line_3__c LIKE \'%' + String.escapeSingleQuotes(street) + '%\' OR ' +
             'Street_Line_4__c LIKE \'%' + String.escapeSingleQuotes(street) + '%\' OR ' +
             'Street_Line_5__c LIKE \'%' + String.escapeSingleQuotes(street) + '%\')');
        }
        
        if (conditions.isEmpty()) {
            return new List<Lead>();
        }
        
        query += String.join(conditions, ' AND ') + ' LIMIT 5000';
        return Database.query(query);
    }
    
    @AuraEnabled(cacheable=true)
    public static String getGAForDrs(Id drsId) {
        DRS__c drs = [SELECT GA__c FROM DRS__c WHERE Id = :drsId LIMIT 1];
        return drs.GA__c;
    }
    @AuraEnabled(cacheable=true)
    public static List<String> getLeadGAValues() {
        List<String> values = new List<String>();
        for (Schema.PicklistEntry entry : Lead.GA__c.getDescribe().getPicklistValues()) {
            if (entry.isActive()) {
                values.add(entry.getLabel());
            }
        }
        return values;
    }
}