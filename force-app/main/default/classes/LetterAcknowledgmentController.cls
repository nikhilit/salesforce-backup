public class LetterAcknowledgmentController {
    public Id caseId { get; set; }
    public String objectType { get; set; }
    public Case caseRecord { get; set; }
    public Account acc { get; set; }
    public Lead relatedLead { get; set; }
    public String templateSubject { get; set; }
    public String templateBody { get; private set; }

    // Today in dd.MM.yyyy format
    public String today {
        get {
            Date d = System.today();
            Datetime dt = DateTime.newInstance(d, Time.newInstance(0, 0, 0, 0));
            return dt.format('dd.MM.yyyy');
        }
    }

    // Constructor for Visualforce page
    public LetterAcknowledgmentController() {
        caseId = ApexPages.currentPage().getParameters().get('id');
        objectType = ApexPages.currentPage().getParameters().get('objectType');
        templateBody = ApexPages.currentPage().getParameters().get('templateBody');

        if (caseId != null) {
            caseRecord = [
                SELECT Id, CaseNumber, Subject, Type, Priority, Origin, 
                       Category__c, CreatedDate, Owner.Name, AccountId, Lead__c
                FROM Case 
                WHERE Id = :caseId
            ];

            if (caseRecord.AccountId != null) {
                acc = [
                    SELECT Id, Name, Flat__c, Floor__c, Building_Name__c, City__c, 
                           Postal_Code__c, Phone, Secondary_Telephone__c, BP_Number__c, 
                           Full_Name__c, Person_Title__c, Room__c, Supplement__c,
                           Building_Name_Conn__c, Street__c, Street_Line_3__c,
                           Street_Line_4__c, Street_Line_5__c, Other_City__c, District__c
                    FROM Account 
                    WHERE Id = :caseRecord.AccountId
                ];
            } else if (caseRecord.Lead__c != null) {
                relatedLead = [
                    SELECT Id, Name, FirstName, LastName, Phone, MobilePhone, Email,
                           Building_Code__c, Building_Name__c, Flat__c, Floor__c, 
                           House_Number__c, Room_Number__c, Street__c, Street_Line_2__c,
                           Street_Line_3__c, Street_Line_4__c, Street_Line_5__c, Road_Name__c,
                           City__c, Other_City__c, District__c, Postal_Code__c, Country__c,
                           Region__c, Society_Name__c, Time_Zone__c
                    FROM Lead
                    WHERE Id = :caseRecord.Lead__c
                ];
            }
        }
    }

    // Constructor for after-insert scenario
    public LetterAcknowledgmentController(Case insertedCase) {
        if (insertedCase == null) {
            System.debug('No Case provided!');
            return;
        }
        caseRecord = insertedCase;
        caseId = insertedCase.Id;

        if (caseRecord.AccountId != null) {
            acc = [
                SELECT Id, Name, Flat__c, Floor__c, Building_Name__c, City__c, 
                       Postal_Code__c, Phone, Secondary_Telephone__c, BP_Number__c, 
                       Full_Name__c, Person_Title__c, Room__c, Supplement__c,
                       Building_Name_Conn__c, Street__c, Street_Line_3__c,
                       Street_Line_4__c, Street_Line_5__c, Other_City__c, District__c
                FROM Account
                WHERE Id = :caseRecord.AccountId
            ];
        } else if (caseRecord.Lead__c != null) {
            relatedLead = [
                SELECT Id, Name, FirstName, LastName, Phone, MobilePhone, Email,
                       Building_Code__c, Building_Name__c, Flat__c, Floor__c, 
                       House_Number__c, Room_Number__c, Street__c, Street_Line_2__c,
                       Street_Line_3__c, Street_Line_4__c, Street_Line_5__c, Road_Name__c,
                       City__c, Other_City__c, District__c, Postal_Code__c, Country__c,
                       Region__c, Society_Name__c, Time_Zone__c
                FROM Lead
                WHERE Id = :caseRecord.Lead__c
            ];
        }
    }
    
    public String referenceNumber {
        get {
            System.debug('---Entering referenceNumber getter---');

            // If we don't have a Case record, fallback to caseId
            if (caseRecord == null) {
                System.debug('caseRecord is null, returning fallback ID');
                return caseId != null ? 'MGL/CRM/' + caseId + '/FY' : '';
            }

            // If CaseNumber is blank, query it from the database
            String caseNum = caseRecord.CaseNumber;
            if (String.isBlank(caseNum) && caseRecord.Id != null) {
                System.debug('CaseNumber is blank, querying from database');
                try {
                    Case queriedCase = [
                        SELECT CaseNumber 
                        FROM Case 
                        WHERE Id = :caseRecord.Id
                        LIMIT 1
                    ];
                    caseNum = queriedCase.CaseNumber;
                } catch (Exception e) {
                    System.debug('Error querying CaseNumber: ' + e.getMessage());
                    caseNum = caseRecord.Id; // fallback
                }
            }

            // Calculate Fiscal Year
            Date d = System.today();
            Integer year = d.year();
            Integer month = d.month();
            System.debug('Current Year: ' + year + ', Month: ' + month);

            String fy;
            if (month >= 4) {
                fy = String.valueOf(year) + '-' + String.valueOf((year + 1)).substring(2);
            } else {
                fy = String.valueOf(year - 1) + '-' + String.valueOf(year).substring(2);
            }
            System.debug('Fiscal Year calculated: ' + fy);

            String ref = 'MGL/CRM/' + caseNum + '/' + fy;
            System.debug('Reference Number to return: ' + ref);

            return ref;
        }
    }

    // Helper getters for VF page
    public String getCaseNumber() {
        return caseRecord?.CaseNumber;
    }
    public String getCaseSubject() {
        return caseRecord?.Subject ?? 'your request';
    }
    public String getCaseType() {
        return caseRecord?.Type ?? 'request';
    }
    public String getCaseCategory() {
        return caseRecord?.Category__c ?? '';
    }
    public String getCasePriority() {
        return caseRecord?.Priority ?? '';
    }
    public String getCaseOrigin() {
        return caseRecord?.Origin ?? '';
    }
    public String getCaseOwner() {
        return caseRecord?.Owner?.Name ?? 'Customer Service Team';
    }
    public String getCaseCreatedDate() {
        return caseRecord?.CreatedDate?.format('MMMM d, yyyy') ?? '';
    }
}