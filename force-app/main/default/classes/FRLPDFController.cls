public with sharing class FRLPDFController {
    public Id caseId { get; private set; }
    public Case currentCase { get; private set; }
    public Account relatedAccount { get; private set; }
    public Lead relatedLead { get; private set; } // Added for Lead-based Cases
    public String todayDateStr { get; private set; }
    public String templateBody { get; private set; }
    public Id dataId { get; private set; }

    // Constructor — invoked automatically when VF loads
    public FRLPDFController() {
        caseId = ApexPages.currentPage().getParameters().get('caseId');
        dataId = ApexPages.currentPage().getParameters().get('dataId');

        // Format today's date as dd.MM.yyyy
        Date d = Date.today();
        todayDateStr = DateTime.newInstance(d.year(), d.month(), d.day(), 0, 0, 0).format('dd.MM.yyyy');
        System.debug('dataId'+dataId);
        templateBody = [select Id,Template_Body__c FROM FRL_Template_Data__c WHERE Id=:dataId].Template_Body__c;

        if (caseId != null) {
            currentCase = [
                SELECT Id, CaseNumber, AccountId, Lead__c
                FROM Case
                WHERE Id = :caseId
                LIMIT 1
            ];

            if (currentCase.AccountId != null) {
                relatedAccount = [
                    SELECT Id, Name, FirstName__c, LastName__c, Phone, Secondary_Telephone__c,
                           BP_Number__c, Flat__c, Floor__c, Building_Name_Conn__c, Street__c,
                           Street_Line_2__c, Street_Line_3__c, City__c, Postal_Code__c,Supplement__c,District__c,Other_City__c
                    FROM Account
                    WHERE Id = :currentCase.AccountId
                    LIMIT 1
                ];
            } else if (currentCase.Lead__c != null) {
                relatedLead = [
                    SELECT Id, FirstName, LastName, Email, Phone,
                           House_Number__c, Flat__c, Floor__c, Building_Name__c,
                           Street__c, Street_Line_2__c, Street_Line_3__c, City__c,
                           Postal_Code__c,District__c,Other_City__c
                    FROM Lead
                    WHERE Id = :currentCase.Lead__c
                    LIMIT 1
                ];
            }
        }
    }

    // Public property returning safe HTML for address block
    public String addressHtml {
        get {
            List<String> parts = new List<String>();

            if (relatedAccount != null) {
                String name = !String.isBlank(relatedAccount.FirstName__c) || !String.isBlank(relatedAccount.LastName__c)
                            ? (relatedAccount.FirstName__c + ' ' + relatedAccount.LastName__c).trim()
                            : relatedAccount.Full_Name__c;
                if (!String.isBlank(name)) parts.add(name);
                if (!String.isBlank(relatedAccount.Flat__c)) parts.add('Flat No: ' + relatedAccount.Flat__c);
                if (!String.isBlank(relatedAccount.Floor__c)) parts.add('Floor No: ' + relatedAccount.Floor__c);
                if (!String.isBlank(relatedAccount.Building_Name_Conn__c)) parts.add('Building: ' + relatedAccount.Building_Name_Conn__c);

                List<String> premiseLines = new List<String>();
                if (!String.isBlank(relatedAccount.Street__c)) premiseLines.add(relatedAccount.Street__c);
                if (!String.isBlank(relatedAccount.Street_Line_2__c)) premiseLines.add(relatedAccount.Street_Line_2__c);
                if (!String.isBlank(relatedAccount.Street_Line_3__c)) premiseLines.add(relatedAccount.Street_Line_3__c);
                if (!premiseLines.isEmpty()) parts.add(String.join(premiseLines, ', '));

                if (!String.isBlank(relatedAccount.City__c)) parts.add(relatedAccount.City__c);
                if (!String.isBlank(relatedAccount.District__c)) parts.add(relatedAccount.District__c);
                if (!String.isBlank(relatedAccount.Postal_Code__c)) parts.add(relatedAccount.Postal_Code__c);
 if             (!String.isBlank(relatedAccount.Other_City__c)) parts.add(relatedAccount.Other_City__c);

            } else if (relatedLead != null) {
                String name = ((relatedLead.FirstName != null ? relatedLead.FirstName : '') + ' ' +
                               (relatedLead.LastName != null ? relatedLead.LastName : '')).trim();
                if (!String.isBlank(name)) parts.add(name);
                if (!String.isBlank(relatedLead.Flat__c)) parts.add('Flat No: ' + relatedLead.Flat__c);
                if (!String.isBlank(relatedLead.Floor__c)) parts.add('Floor No: ' + relatedLead.Floor__c);
                if (!String.isBlank(relatedLead.Building_Name__c)) parts.add('Building: ' + relatedLead.Building_Name__c);

                List<String> premiseLines = new List<String>();
                if (!String.isBlank(relatedLead.Street__c)) premiseLines.add(relatedLead.Street__c);
                if (!String.isBlank(relatedLead.Street_Line_2__c)) premiseLines.add(relatedLead.Street_Line_2__c);
                if (!String.isBlank(relatedLead.Street_Line_3__c)) premiseLines.add(relatedLead.Street_Line_3__c);
                if (!premiseLines.isEmpty()) parts.add(String.join(premiseLines, ', '));

                if (!String.isBlank(relatedLead.City__c)) parts.add(relatedLead.City__c);
                if (!String.isBlank(relatedLead.Postal_Code__c)) parts.add(relatedLead.Postal_Code__c);
                if (!String.isBlank(relatedLead.Phone)) parts.add('Tel: ' + relatedLead.Phone);
                if (!String.isBlank(relatedLead.Email)) parts.add('Email: ' + relatedLead.Email);

            } else {
                return 'No Account or Lead information available';
            }

            String addressHtml = '';
            for (String line : parts) {
               addressHtml += '<div>' + escapeHtml(line) + '</div>';
            }
            return addressHtml;
        }
    }

    // Escapes HTML special characters
    public static String escapeHtml(String input) {
        if (input == null) return '';
        String result = input;
        result = result.replace('&', '&amp;');
        result = result.replace('<', '&lt;');
        result = result.replace('>', '&gt;');
        result = result.replace('"', '&quot;');
        result = result.replace('\'', '&#39;');
        return result;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getCaseAccountInfo(Id caseId) {
        Map<String, Object> result = new Map<String, Object>();

        Case c = [SELECT Id, CaseNumber, AccountId, Lead__c,Type__c,Created_Date__c FROM Case WHERE Id = :caseId LIMIT 1];
        result.put('caseNumber', c.CaseNumber);
        result.put('casetype', c.Type__c);
        result.put('createdate', c.Created_Date__c);

        Map<String, Object> ownerInfo = new Map<String, Object>();

        if (c.AccountId != null) {
            Account a = [SELECT Full_Name__c, Phone, Secondary_Telephone__c, BP_Number__c, Room__c, Floor__c, Building_Name_Conn__c,District__c,
                                Street__c, Street_Line_2__c, Street_Line_3__c, City__c, Postal_Code__c,Person_Title__c,Other_City__c,Street_Line_5__c,Street_Line_4__c,Supplement__c
                         FROM Account WHERE Id = :c.AccountId LIMIT 1];
            ownerInfo = new Map<String, Object>{
                'Name' => a.Full_Name__c,
                'Phone' => a.Phone,
                'Secondary_Telephone__c' => a.Secondary_Telephone__c,
                'BP_Number__c' => a.BP_Number__c,
                'Room__c' => a.Room__c,
                'Floor__c' => a.Floor__c,
                'Building_Name_Conn__c' => a.Building_Name_Conn__c,
                'Street__c' => a.Street__c,
                'Street_Line_2__c' => a.Street_Line_2__c,
                'Street_Line_3__c' => a.Street_Line_3__c,
                'Street_Line_4__c' => a.Street_Line_4__c,
                'Street_Line_5__c'=> a.Street_Line_5__c,
                'City__c' => a.City__c,
                'Postal_Code__c' => a.Postal_Code__c,
                'Person_Title__c' => a.Person_Title__c,
                'District__c'=> a.District__c,
                'Supplement__c' => a.Supplement__c,
                'Other_City__c' => a.Other_City__c,
                'ownerType' => 'account'

            };
        } else if (c.Lead__c != null) {
            Lead l = [SELECT FirstName, LastName, Email, Phone, House_Number__c, Flat__c, Floor__c, Building_Name__c,
                              Street__c, Street_Line_2__c, Street_Line_3__c, City__c, Postal_Code__c,Other_City__c,District__c,Street_Line_4__c,Street_Line_5__c,Lead_No__c
                       FROM Lead WHERE Id = :c.Lead__c LIMIT 1];
            ownerInfo = new Map<String, Object>{
                'Name' => (l.FirstName != null ? l.FirstName : '') + ' ' + (l.LastName != null ? l.LastName : ''),
                'Email' => l.Email,
                'Phone' => l.Phone,
                'Floor__c' => l.Floor__c,
                'Room__c'  => l.Flat__c,
                'Building_Name_Conn__c' => l.Building_Name__c,
                'Street__c' => l.Street__c,
                'Street_Line_2__c' => l.Street_Line_2__c,
                'Street_Line_3__c' => l.Street_Line_3__c,
                'City__c' => l.City__c,
                'Postal_Code__c' => l.Postal_Code__c,
               'Street_Line_4__c' => l.Street_Line_4__c,
                'District__c'=> l.District__c,
                'Street_Line_5__c' => l.Street_Line_5__c,
                'Other_City__c' => l.Other_City__c,
                'BP_Number__c' => l.Lead_No__c,
                'ownerType' => 'lead'
            };
        }

        result.put('account', ownerInfo);
        result.put('ownerType', ownerInfo.get('ownerType'));
        result.put('todayDate', DateTime.now().format('dd.MM.yyyy'));

        return result;
    }
}