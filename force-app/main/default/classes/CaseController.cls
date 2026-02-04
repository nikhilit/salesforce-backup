public with sharing class CaseController {
    private static String getPicklistApiValue(String objectName, String fieldName, String label) {
    Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(objectName);
    Schema.DescribeSObjectResult objDescribe = sObjType.getDescribe();
    Schema.DescribeFieldResult fieldResult = objDescribe.fields.getMap().get(fieldName).getDescribe();

    for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
        if (entry.getLabel() == label) {
            return entry.getValue();
        }
    }
    return label;
}

@AuraEnabled
    public static Case getCaseDetails(Id caseId) {
        return [
            SELECT Id, CaseNumber, Subject
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];
    }

    
    @AuraEnabled(cacheable=true)
    public static AccountWrapper getAccountInfo(Id recordId, String objectType) {
        if (objectType == 'Account') {
            Account acc = [
                SELECT Id, Name, Phone, BP_Number__c, Contract_Account__c, Account_Email__c,
                       Secondary_Telephone__c, Street__c, Application_Number__c,
                       Premise__r.Connection_Name__c, City__c, Postal_Code__c, DRS_Master__c
                FROM Account 
                WHERE Id = :recordId 
                LIMIT 1
            ];
            
            List<Case> relatedCases = new List<Case>();
            if (acc.BP_Number__c != null) {
                relatedCases = [
                    SELECT Id, CaseNumber,Created_Date__c,Created_Date_Old__c,Docket_Number__c, Type__c, Sub_Type__c, Status, Priority, toLabel(Category__c), Owner.Name, Subject
                    FROM Case
                    WHERE AccountId = :recordId 
                    ORDER BY CreatedDate DESC
                    LIMIT 5
                ];
            }
            System.debug(relatedCases);
            Identification_Number__c appNumber;
            List<Identification_Number__c> appNumberList = [
                SELECT Id, ID_Number__c
                FROM Identification_Number__c
                WHERE BP__c = :recordId AND Type_Desc__c = 'Application Form'
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            if (!appNumberList.isEmpty()) {
                appNumber = appNumberList[0];
            }
            
            return new AccountWrapper(acc, relatedCases, appNumber, null);
        } 
        else if (objectType == 'Lead') {
            Lead leadRecord = [
                SELECT Id, Name, Phone, MobilePhone, Email, Street__c, City__c, Postal_Code__c,Lead_No__c,
                       DRS__c, Company, Building_Name__c, Flat__c, Floor__c, House_Number__c,
                       Road_Name__c, Society_Name__c,Street_Line_3__c,Street_Line_4__c,Street_Line_5__c,Other_City__c,District__c
                FROM Lead
                WHERE Id = :recordId
                LIMIT 1
            ];
            
            // For leads, query cases by email or phone
           List<Case> relatedCases = [
        SELECT Id, CaseNumber, Type__c, Sub_Type__c, Status, Priority, toLabel(Category__c), Owner.Name, Subject,Created_Date_Old__c,Created_date__c
        FROM Case
        WHERE Lead__c = :recordId
        ORDER BY CreatedDate DESC
        LIMIT 5
    ];
            
            return new AccountWrapper(null, relatedCases, null, leadRecord);
        }
        
        return null;
    }

    public class AccountWrapper {
        @AuraEnabled public Account account { get; set; }
        @AuraEnabled public List<Case> cases { get; set; }
        @AuraEnabled public Identification_Number__c appNumber { get; set; }
        @AuraEnabled public Lead lead { get; set; }

        public AccountWrapper(Account account, List<Case> cases, Identification_Number__c appNumber, Lead lead) {
            this.account = account;
            this.cases = cases;
            this.appNumber = appNumber;
            this.lead = lead;
        }
    }

    @AuraEnabled
    public static Case createCaseRecord(
        Id recordId,
        String objectType,
        String category,
        String type,
        String subType,
        String description,
        String priority,
        Map<String, String> valueMap,
        String department,
        String spocId,
        String tat,
        String tatDays,
        String tatMinutes,
        Decimal refundAmount,
        String refundType,
        Date requestSubmissionDate,
        String origin,
        String subOrigin,
        String accountType,
        String bankName,
        String branchName,
        String ifscCode,
        String accountNumber,
        String accountHolderName,
        String ticketNumber,
        Id qrcprocess,
        Id attendancetrack,
        String modeOfPayment,
        String sendSmsTo,
        String transfertypevalue,
        String nameTransferMode,
        String contactdirection
        
    ) {
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1];
         Integer tatMinutesint = 0;
    Date benchmarkDate = null;
    
    // Only calculate benchmark if tatMinutes is not empty
    if (String.isNotBlank(tatMinutes)) {
        try {
            tatMinutesint = Integer.valueOf(tatMinutes);
            Long tatMilliseconds = tatMinutesint * 60 * 1000L;  
            DateTime benchmarkDateTime = BusinessHours.add(bh.Id, System.now(), tatMilliseconds);
            benchmarkDate = benchmarkDateTime.date();
        } catch (Exception e) {
            System.debug('Error processing TAT minutes: ' + e.getMessage());
        }
    }
    Map<String, String> additionalFieldsMap = new Map<String, String>();
    String actualSendSmsTo = sendSmsTo; // Store the actual SMS value
    
    if (String.isNotBlank(sendSmsTo)) {
        try {
            additionalFieldsMap = (Map<String, String>)JSON.deserialize(sendSmsTo, Map<String, String>.class);
            actualSendSmsTo = additionalFieldsMap.get('sendSmsTo');
        } catch (Exception e) {
            System.debug('Using sendSmsTo as actual value: ' + sendSmsTo);
        }
    }
    // Extract customer contact fields from additionalFieldsMap
    String newEmailId = additionalFieldsMap.get('newEmailId');
    String newContact = additionalFieldsMap.get('newContact');
    String newFirstName = additionalFieldsMap.get('newFirstName');
    String newMiddleName = additionalFieldsMap.get('newMiddleName');
    String newLastName = additionalFieldsMap.get('newLastName');
     String newSalutation = additionalFieldsMap.get('newSalutation');
    // Get Call Received From from valueMap
    String callReceivedFrom = (valueMap == null) ? null : valueMap.get('Call_Received_From__c');
    // Extract PD Reason & New Address from valueMap
    String pdReason =   (valueMap != null) ? valueMap.get('PD_Reason__c') : null;

    String newAddress = (valueMap != null) ? valueMap.get('New_Address__c') : null;


        // If Call Received From is Mendatory
        // if (origin == '1' && String.isBlank(callReceivedFrom)) {
        //     throw new AuraHandledException('Please enter Call Received From for Telephone origin.');
        // }


        Case newCase = new Case(
            Category__c = getPicklistApiValue('Case', 'Category__c', category),
            Type__c = type,
            Sub_Type__c = subType,
            PD_Reason__c = String.isNotBlank(pdReason) ? getPicklistApiValue('Case', 'PD_Reason__c', pdReason) : null,
            New_Address__c = newAddress,
            Remarks__c = description,
            Priority = getPicklistApiValue('Case', 'Priority', priority),
            Department__c = getPicklistApiValue('Case', 'Department__c', department),
            SPOC__c = spocId == '' ? null : spocId,
            Assigned_To__c = spocId == ''?null:spocId,
            TAT__c = tat,
            Remaining_TAT__c = tatMinutes,
            Remaining_Tat_2__c = '',
            Remaining_Tat_3__c = '',
            Remaining_Tat_4__c = '',
            TAT_in_days__c = tatDays,
            TAT_in_minutes__c = tatMinutes,
            Refund_Amount__c = refundAmount,
            Request_Submission_Date__c = requestSubmissionDate,
            Origin = getPicklistApiValue('Case', 'Origin', origin),
            Sub_Origin__c = subOrigin,
            Account_Type__c = accountType,
            Bank_Name__c = bankName,
            Branch_Name__c = branchName,
            IFSC_Code__c = ifscCode,
            Account_Number__c = accountNumber,
            Account_Holder_Name__c = accountHolderName,
            Ticket_Number__c = ticketNumber,
            //QRC_Process__c = qrcprocess,
            Attendance__c = attendancetrack,
            Send_SMS_to__c = actualSendSmsTo,
            Benchmark__c = benchmarkDate,
            Mode_Of_Payment__c = modeOfPayment,
            Transfer_Type__c = transfertypevalue,
            Name_Transfer_Mode__c = nameTransferMode,
            Contact_Directions__c = getPicklistApiValue('Case', 'Contact_Directions__c', contactdirection),
            Contacted_By__c = additionalFieldsMap.get('contactedBy'), 
            Relationship_to_the_owner__c = additionalFieldsMap.get('relationshipToOwner'),
            Is_Migrated__c=false,
            New_email_id__c = newEmailId,
            New_Contact__c = newContact,
            New_First_Name__c = newFirstName,     
            New_Middle_Name__c = newMiddleName,   
            New_Last_Name__c = newLastName, 
             New_Salutation__c=newSalutation,     
            Call_Received_From__c = callReceivedFrom
            
        );

        // Store Amount__c from valueMap
        if (valueMap != null && valueMap.containsKey('Amount__c')
            && String.isNotBlank(valueMap.get('Amount__c'))) {
            newCase.Amount__c = valueMap.get('Amount__c');
        }


        // Set the appropriate relationship based on object type
        if (objectType == 'Account') {
            System.debug(recordId+'AccountId found');
            newCase.AccountId = recordId;
        } else if (objectType == 'Lead') {
            Lead ld = [SELECT Id, Name, Email, Phone FROM Lead WHERE Id = :recordId LIMIT 1];
            newCase.Lead__c = recordId;
        }

        Id currentUserId = UserInfo.getUserId();
        String profileName = [SELECT Profile.Name FROM User WHERE Id = :currentUserId].Profile.Name;
        
        for (Integer i = 1; i <= 8; i++) {
            String key = 'Value' + i;
            String fieldName = 'Value_' + i + '__c';
            if (valueMap != null && valueMap.containsKey(key)) {
                newCase.put(fieldName, valueMap.get(key));
            }
        }
        if (valueMap != null && valueMap.containsKey('Meter_reading__c')) {
            newCase.put('Meter_reading__c', valueMap.get('Meter_reading__c'));
        }

        // Auto-populate From/To dates and Number_of_Months__c for Billing Shortfall
        Boolean isBillingShortfall =
            department == 'Billing' &&
            category == 'Request' &&
            type == 'Minimum / Shortfall Charges';

        if (isBillingShortfall) {
            // From Date = today (same as Created_Date__c formula DATEVALUE(CreatedDate))
            Date fromDate = Date.today();
            newCase.From_Date__c = fromDate;

            // To Date = From Date + 6 months - 1 day (inclusive period)
            Date toDate = fromDate.addMonths(6);
            newCase.To_Date__c = toDate;
        }


        // NEW: From / To / Number of Months from valueMap
        // if (valueMap != null) {
        //     // Number_of_Months__c is Text on Case, just copy as-is
        //     if (valueMap.containsKey('Number_of_Months__c')) {
        //         newCase.Number_of_Months__c = valueMap.get('Number_of_Months__c');
        //     }

        //     // From_Date__c
        //     if (valueMap.containsKey('From_Date__c')) {
        //         String fromDateStrVm = valueMap.get('From_Date__c');
        //         if (!String.isBlank(fromDateStrVm)) {
        //             try {
        //                 newCase.From_Date__c = Date.valueOf(fromDateStrVm);
        //             } catch (Exception e) {
        //                 System.debug('Invalid From_Date__c in valueMap: ' + fromDateStrVm + ' - ' + e.getMessage());
        //             }
        //         }
        //     }

        //     // To_Date__c
        //     if (valueMap.containsKey('To_Date__c')) {
        //         String toDateStrVm = valueMap.get('To_Date__c');
        //         if (!String.isBlank(toDateStrVm)) {
        //             try {
        //                 newCase.To_Date__c = Date.valueOf(toDateStrVm);
        //             } catch (Exception e) {
        //                 System.debug('Invalid To_Date__c in valueMap: ' + toDateStrVm + ' - ' + e.getMessage());
        //             }
        //         }
        //     }
        // }
        
        if (profileName.contains('CRM')) {
            newCase.Created_By__c = UserInfo.getUserId();
        }
    //    if (additionalFieldsMap.containsKey('fromDate')) {
    //         String fromDateStr = (String) additionalFieldsMap.get('fromDate');
    //         if (fromDateStr != null && fromDateStr != '') {
    //             newCase.From_Date__c = Date.valueOf(fromDateStr);
    //         }
    //     }
    //     if (additionalFieldsMap.containsKey('toDate')) {
    //         String toDateStr = (String) additionalFieldsMap.get('toDate');
    //         if (toDateStr != null && toDateStr != '') {
    //             newCase.To_Date__c = Date.valueOf(toDateStr);
    //         }
    //     }
        try {
            insert newCase;
    //         Case caseWithNumber = [
    //     SELECT Id, CaseNumber
    //     FROM Case
    //     WHERE Id = :newCase.Id
    // ];

    return newcase;
        } catch (Exception e) {
            throw new AuraHandledException('Error creating case: ' + e.getMessage()+e.getLineNumber());
        }
    }

//     @AuraEnabled(cacheable=true)
//   public static Map<String, String> getDepartmentAndSPOC(String category, String type, String subType, Id recordId, String objectType) {
//     Map<String, String> result = new Map<String, String>{
//         'department' => '',
//         'spoc' => '',
//         'spocId' => '',
//         'tat' => '',
//         'qrcId' => '',
//         'beforeapprovaldpt' => ''
//     };

//     String drsId;
//     String gasifiedStatus = '';

//     if (objectType == 'Account') {
//         List<Account> accList = [
//             SELECT DRS_Master__c, Gasified__c
//             FROM Account 
//             WHERE Id = :recordId 
//             LIMIT 1
//         ];
//         if (!accList.isEmpty()) {
//             drsId = accList[0].DRS_Master__c;
//             gasifiedStatus = accList[0].Gasified__c;
//         }
//     } else if (objectType == 'Lead') {
//         List<Lead> leadList = [SELECT DRS__c FROM Lead WHERE Id = :recordId LIMIT 1];
//         if (!leadList.isEmpty()) {
//             drsId = leadList[0].DRS__c;
//         }
//     }

//     if (String.isBlank(drsId)) {
//         return result;
//     }

//     List<QRC_Process__c> mappings = [
//         SELECT Department__c, Department_1_Gasified__c, TAT_in_hours__c, Id, Before_Approval_dpt__c
//         FROM QRC_Process__c 
//         WHERE Category__c = :category 
//         AND Type__c = :type 
//         AND Sub_Type__c = :subType
//         LIMIT 1
//     ];

//     if (mappings.isEmpty()) {
//         return result;
//     }

//     QRC_Process__c mapping = mappings[0];
//     String selectedDepartment;

//     // Determine the correct department based on your new logic
//     if (mapping.Before_Approval_dpt__c != null) {
//         selectedDepartment = mapping.Before_Approval_dpt__c;
//     } else if (objectType == 'Account' && gasifiedStatus == 'Gasified' && String.isNotBlank(mapping.Department_1_Gasified__c)) {
//         selectedDepartment = mapping.Department_1_Gasified__c;
//     } else {
//         selectedDepartment = mapping.Department__c;
//     }

//     // Fetch the SPOC Mapping based on the resolved department
//     List<Departments_SPOC_Mapping__c> spocMappings = [
//         SELECT SPOC_Id__r.Name, SPOC_Id__c, Department__c
//         FROM Departments_SPOC_Mapping__c
//         WHERE DRS__c = :drsId
//         AND Department__c = :selectedDepartment
//         LIMIT 1
//     ];

//     result.put('beforeapprovaldpt', mapping.Before_Approval_dpt__c);
//     result.put('department', selectedDepartment);
//     result.put('qrcId', mapping.Id);
//     result.put('tat', mapping.TAT_in_hours__c != null ? String.valueOf(mapping.TAT_in_hours__c) : '');

//     if (!spocMappings.isEmpty()) {
//         Departments_SPOC_Mapping__c spoc = spocMappings[0];
//         result.put('spocId', spoc.SPOC_Id__c != null ? String.valueOf(spoc.SPOC_Id__c) : '');
//         result.put('spoc', spoc.SPOC_Id__c != null && spoc.SPOC_Id__r.Name != null ? spoc.SPOC_Id__r.Name : '');
//     }

//     return result;
// }
@AuraEnabled(cacheable=true)
public static Map<String, String> getDepartmentAndSPOC(String department,String category, String type, String subType,String value1, Id recordId, String objectType) {
   
    Map<String, String> result = new Map<String, String>{
        'department' => '',
        'spoc' => '',
        'spocId' => '',
        'tat' => '',
        'qrcId' => '',
        'beforeapprovaldpt' => ''
    };

    String drsId;

    if (objectType == 'Account') {
        List<Account> accList = [
            SELECT DRS_Master__c
            FROM Account 
            WHERE Id = :recordId 
            LIMIT 1
        ];
        if (!accList.isEmpty()) {
            drsId = accList[0].DRS_Master__c;
        }
    } else if (objectType == 'Lead') {
        List<Lead> leadList = [SELECT DRS__c FROM Lead WHERE Id = :recordId LIMIT 1];
        if (!leadList.isEmpty()) {
            drsId = leadList[0].DRS__c;
        }
    }

    if (String.isBlank(drsId)) {
        return result;
    }

    List<QRC_Process__c> mappings = new List<QRC_Process__c>();
    if(value1!=''){
        mappings=[
        SELECT Department__c, TAT_in_hours__c, Id, Before_Approval_dpt__c
        FROM QRC_Process__c 
        WHERE Category__c = :category 
        AND Type__c = :type 
        AND Sub_Type__c = :subType
        AND Value_1__c = :value1
        AND Department__c = :department
        LIMIT 1
    ];
        }
    else{
         mappings=[
        SELECT Department__c, TAT_in_hours__c, Id, Before_Approval_dpt__c
        FROM QRC_Process__c 
        WHERE Category__c = :category 
        AND Type__c = :type 
        AND Sub_Type__c = :subType
        AND Department__c = :department
        LIMIT 1
    ];
    }
  
    if (mappings.isEmpty()) {
        return result;
    }

    QRC_Process__c mapping = mappings[0];
    String selectedDepartment;
    // Determine the correct department based on existing logic
        selectedDepartment = mapping.Department__c;
        result.put('department', mapping.Department__c);

    // Debug logs to verify the department mapping
    System.debug('Final selectedDepartment: ' + selectedDepartment);
    System.debug('Type: ' + type);
    System.debug('SubType: ' + subType);
    
    // Fetch the SPOC Mapping based on the resolved department
    List<Departments_SPOC_Mapping__c> spocMappings = [
        SELECT SPOC_Id__r.Name, SPOC_Id__c, Department__c
        FROM Departments_SPOC_Mapping__c
        WHERE DRS__c = :drsId
        AND Department__c = :selectedDepartment
        AND QRC_Process__c =:mapping.Id
        LIMIT 1
    ];
System.debug('Final spocMapping: ' + spocMappings);
    result.put('qrcId', mapping.Id);
    result.put('tat', mapping.TAT_in_hours__c != null ? String.valueOf(mapping.TAT_in_hours__c) : '');

    if (!spocMappings.isEmpty()) {
        Departments_SPOC_Mapping__c spoc = spocMappings[0];
        result.put('spocId', spoc.SPOC_Id__c != null ? String.valueOf(spoc.SPOC_Id__c) : '');
        result.put('spoc', spoc.SPOC_Id__c != null && spoc.SPOC_Id__r.Name != null ? spoc.SPOC_Id__r.Name : '');
        
        // Debug log for SPOC mapping
        System.debug('Found SPOC: ' + spoc.SPOC_Id__r.Name + ' (ID: ' + spoc.SPOC_Id__c + ')');
    } else {
        System.debug('No SPOC mapping found for department: ' + selectedDepartment);
    }

    return result;
}
    // @AuraEnabled(cacheable=true)
    // public static Map<String, String> getDepartmentAndSPOCByType(String category, String type, Id recordId, String objectType) {
    //     Map<String, String> result = new Map<String, String>{
    //         'department' => '',
    //         'spoc' => '',
    //         'spocId' => '',
    //         'tat' => '',
    //         'qrcId' => '',
    //         'beforeapprovaldpt' => ''
    //     };

    //     String drsId;
    //     if (objectType == 'Account') {
    //         List<Account> accList = [SELECT DRS_Master__c FROM Account WHERE Id = :recordId LIMIT 1];
    //         if (!accList.isEmpty()) {
    //             drsId = accList[0].DRS_Master__c;
    //         }
    //     } else if (objectType == 'Lead') {
    //         List<Lead> leadList = [SELECT DRS__c FROM Lead WHERE Id = :recordId LIMIT 1];
    //         if (!leadList.isEmpty()) {
    //             drsId = leadList[0].DRS__c;
    //         }
    //     }

    //     if (String.isBlank(drsId)) {
    //         return result;
    //     }

    //     List<QRC_Process__c> mappings = [
    //         SELECT Department__c, TAT_in_hours__c, Id, Before_Approval_dpt__c
    //         FROM QRC_Process__c 
    //         WHERE Category__c = :category 
    //         AND Type__c = :type
    //         LIMIT 1
    //     ];

    //     if (mappings.isEmpty()) {
    //         return result;
    //     }

    //     QRC_Process__c mapping = mappings[0];
        
    //     List<Departments_SPOC_Mapping__c> spocMappings = new List<Departments_SPOC_Mapping__c>();
        
    //     if (mapping.Before_Approval_dpt__c != null) {
    //         spocMappings = [
    //             SELECT SPOC_Id__r.Name, SPOC_Id__c, Department__c
    //             FROM Departments_SPOC_Mapping__c
    //             WHERE DRS__c = :drsId
    //             AND Department__c = :mapping.Before_Approval_dpt__c
    //             LIMIT 1
    //         ];
    //     } else {
    //         spocMappings = [
    //             SELECT SPOC_Id__r.Name, SPOC_Id__c, Department__c
    //             FROM Departments_SPOC_Mapping__c
    //             WHERE DRS__c = :drsId
    //             AND Department__c = :mapping.Department__c
    //             LIMIT 1
    //         ];
    //     }

    //     result.put('beforeapprovaldpt', mapping.Before_Approval_dpt__c);
    //     result.put('department', mapping.Before_Approval_dpt__c != null ? mapping.Before_Approval_dpt__c : mapping.Department__c);
    //     result.put('qrcId', mapping.Id);
    //     result.put('tat', mapping.TAT_in_hours__c != null ? String.valueOf(mapping.TAT_in_hours__c) : '');

    //     if (!spocMappings.isEmpty()) {
    //         Departments_SPOC_Mapping__c spoc = spocMappings[0];
    //         result.put('spocId', spoc.SPOC_Id__c != null ? String.valueOf(spoc.SPOC_Id__c) : '');
    //         result.put('spoc', spoc.SPOC_Id__c != null && spoc.SPOC_Id__r.Name != null ? spoc.SPOC_Id__r.Name : '');
    //     }

    //     return result;
    // }
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getDepartmentAndSPOCByType(String department, String category, String type, Id recordId, String objectType) {
        Map<String, String> result = new Map<String, String>{
        'department' => '',
        'spoc' => '',
        'spocId' => '',
        'tat' => '',
        'qrcId' => '',
        'beforeapprovaldpt' => ''
    };

    String drsId;

    if (objectType == 'Account') {
        List<Account> accList = [
            SELECT DRS_Master__c
            FROM Account 
            WHERE Id = :recordId 
            LIMIT 1
        ];
        if (!accList.isEmpty()) {
            drsId = accList[0].DRS_Master__c;
        }
    } else if (objectType == 'Lead') {
        List<Lead> leadList = [SELECT DRS__c FROM Lead WHERE Id = :recordId LIMIT 1];
        if (!leadList.isEmpty()) {
            drsId = leadList[0].DRS__c;
        }
    }

    if (String.isBlank(drsId)) {
        return result;
    }

    List<QRC_Process__c> mappings = [
        SELECT Department__c, TAT_in_hours__c, Id, Before_Approval_dpt__c
        FROM QRC_Process__c 
        WHERE Category__c = :category 
        AND Type__c = :type
        AND Department__c = :department
        LIMIT 1
    ];
  
    if (mappings.isEmpty()) {
        return result;
    }

    QRC_Process__c mapping = mappings[0];
    String selectedDepartment;
    // Determine the correct department based on existing logic
        selectedDepartment = mapping.Department__c;
        result.put('department', mapping.Department__c);

    // Debug logs to verify the department mapping
    System.debug('Final selectedDepartment: ' + selectedDepartment);
    System.debug('Type: ' + type);
    
    // Fetch the SPOC Mapping based on the resolved department
    List<Departments_SPOC_Mapping__c> spocMappings = [
        SELECT SPOC_Id__r.Name, SPOC_Id__c, Department__c
        FROM Departments_SPOC_Mapping__c
        WHERE DRS__c = :drsId
        AND Department__c = :selectedDepartment
         AND QRC_Process__c =:mapping.Id
        LIMIT 1
    ];
System.debug('Final spocMapping: ' + spocMappings);
    result.put('qrcId', mapping.Id);
    result.put('tat', mapping.TAT_in_hours__c != null ? String.valueOf(mapping.TAT_in_hours__c) : '');

    if (!spocMappings.isEmpty()) {
        Departments_SPOC_Mapping__c spoc = spocMappings[0];
        result.put('spocId', spoc.SPOC_Id__c != null ? String.valueOf(spoc.SPOC_Id__c) : '');
        result.put('spoc', spoc.SPOC_Id__c != null && spoc.SPOC_Id__r.Name != null ? spoc.SPOC_Id__r.Name : '');
        
        // Debug log for SPOC mapping
        System.debug('Found SPOC: ' + spoc.SPOC_Id__r.Name + ' (ID: ' + spoc.SPOC_Id__c + ')');
    } else {
        System.debug('No SPOC mapping found for department: ' + selectedDepartment);
    }

    return result;
}

public class DocumentMetadataWrapper {
    @AuraEnabled public String docType{get;set;}
    @AuraEnabled public String description{get;set;}
}
    @AuraEnabled
    public static void relateDocumentsToCase(Id caseId, Map<Id, DocumentMetadataWrapper> documentIdToMetadata) {
        System.debug('documentIdToMetadata'+documentIdToMetadata);
        try {
            if (caseId == null || documentIdToMetadata == null || documentIdToMetadata.isEmpty()) {
                throw new AuraHandledException('Case ID and Document metadata are required.');
            }
            
            List<Case> cases = [SELECT Id FROM Case WHERE Id = :caseId LIMIT 1];
            if (cases.isEmpty()) {
                throw new AuraHandledException('Case not found with ID: ' + caseId);
            }
            
            Set<Id> docIds = documentIdToMetadata.keySet();
            List<ContentDocument> existingDocs = [SELECT Id FROM ContentDocument WHERE Id IN :docIds];
            if (existingDocs.size() != docIds.size()) {
                throw new AuraHandledException('One or more documents not found');
            }

            List<ContentDocumentLink> links = new List<ContentDocumentLink>();
            List<ContentVersion> versionsToUpdate = new List<ContentVersion>();

            for (Id docId : documentIdToMetadata.keySet()) {
                DocumentMetadataWrapper metadata = documentIdToMetadata.get(docId);
                String docType = metadata != null ? metadata.docType : null;
                String docDesc = metadata != null ? metadata.description : null;

                links.add(new ContentDocumentLink(
                    ContentDocumentId = docId,
                    LinkedEntityId = caseId,
                    ShareType = 'V',
                    Visibility = 'AllUsers'
                ));

                List<ContentVersion> cvs = [
                    SELECT Id, Type_Of_Document__c, Description 
                    FROM ContentVersion 
                    WHERE ContentDocumentId = :docId 
                    AND IsLatest = true
                    LIMIT 1
                ];

                if (!cvs.isEmpty()) {
                    ContentVersion cv = cvs[0];
                    if (String.isNotBlank(docType)) cv.Selected_Document_Names__c = docType;
                    if (String.isNotBlank(docDesc)) cv.Description = docDesc;
                    versionsToUpdate.add(cv);
                }
            }

            if (!links.isEmpty()) {
                insert links;
            }
            if (!versionsToUpdate.isEmpty()) {
                update versionsToUpdate;
            }
        } catch (Exception e) {
            System.debug('Error in relateDocumentsToCase: ' + e.getLineNumber() + ' StackTrace: ' + e.getStackTraceString());
            throw new AuraHandledException('An error occurred while linking documents to the case. Please contact your administrator.');
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<PicklistValueWrapper> getTypeOfDocumentPicklistValues() {
        List<PicklistValueWrapper> options = new List<PicklistValueWrapper>();
        Schema.DescribeFieldResult fieldDesc = ContentVersion.Type_Of_Document__c.getDescribe();

        for (Schema.PicklistEntry entry : fieldDesc.getPicklistValues()) {
            if (entry.isActive()) {
                options.add(new PicklistValueWrapper(entry.getLabel(), entry.getValue()));
            }
        }

        return options;
    }

    public class PicklistValueWrapper {
        @AuraEnabled public String label;
        @AuraEnabled public String value;

        public PicklistValueWrapper(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    @AuraEnabled(cacheable=true)
    public static Case getSidebarCaseDetails(Id caseId) {
        List<Case> cases = [
            SELECT 
                CaseNumber,
                toLabel(Origin),
                CreatedDate,
                ClosedDate,
                LastModifiedDate,
                Previous_Status__c,
                Lead__c,
                Is_Duplicate__c,
                toLabel(Department__c),
                toLabel(Category__c),
                Send_SMS_to__c,
                Case_Number__c,
                Docket_Number__c
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];
        return cases.isEmpty() ? null : cases[0];
    }

  @AuraEnabled
public static Boolean isDuplicateCase(
    Id recordId,
    String objectType,
    String category,
    String type,
    String subType,
    String department,
    Map<String, String> valueMap
) {
    try {
        // Base query: only OPEN cases
        String query = 'SELECT Id, Is_Duplicate__c FROM Case WHERE Closed__c = false';

        // =============================
        // Account / Lead conditions
        // =============================
        if (objectType == 'Account') {

            query += ' AND AccountId = \'' +
                     String.escapeSingleQuotes(String.valueOf(recordId)) + '\'';

        } else if (objectType == 'Lead') {

            Lead ld = [
                SELECT Email, Phone
                FROM Lead
                WHERE Id = :recordId
                LIMIT 1
            ];

            if (String.isNotBlank(ld.Email)) {
                query += ' AND (ContactEmail = \'' +
                         String.escapeSingleQuotes(ld.Email) + '\'';

                if (String.isNotBlank(ld.Phone)) {
                    query += ' OR ContactPhone = \'' +
                             String.escapeSingleQuotes(ld.Phone) + '\'';
                }

                query += ')';

            } else if (String.isNotBlank(ld.Phone)) {
                query += ' AND ContactPhone = \'' +
                         String.escapeSingleQuotes(ld.Phone) + '\'';
            } else {
                // No identifying info to check duplicates
                return false;
            }
        }

        // =============================
        // Category
        // =============================
        if (String.isNotBlank(category)) {
            String categoryApi =
                getPicklistApiValue('Case', 'Category__c', category);

            query += ' AND Category__c = \'' +
                     String.escapeSingleQuotes(categoryApi) + '\'';
        }

        // =============================
        // Type / Sub Type
        // =============================
        if (String.isNotBlank(type)) {
            query += ' AND Type__c = \'' +
                     String.escapeSingleQuotes(type) + '\'';
        }

        if (String.isNotBlank(subType)) {
            query += ' AND Sub_Type__c = \'' +
                     String.escapeSingleQuotes(subType) + '\'';
        }

        // =============================
        // Department
        // =============================
        if (String.isNotBlank(department)) {
            String departmentApi =
                getPicklistApiValue('Case', 'Department__c', department);

            query += ' AND Department__c = \'' +
                     String.escapeSingleQuotes(departmentApi) + '\'';
        }

        // =============================
        // Dynamic Value_1__c to Value_8__c
        // =============================
        if (valueMap != null && !valueMap.isEmpty()) {
            for (Integer i = 1; i <= 8; i++) {
                String key = 'Value' + i;
                if (valueMap.containsKey(key) &&
                    String.isNotBlank(valueMap.get(key))) {

                    query += ' AND Value_' + i + '__c = \'' +
                             String.escapeSingleQuotes(valueMap.get(key)) + '\'';
                }
            }
        }

        // Limit to existence check
        query += ' LIMIT 1';

        System.debug('Final Duplicate Query: ' + query);

        List<Case> results = Database.query(query);

        return !results.isEmpty();

    } catch (Exception ex) {
        System.debug('Error in isDuplicateCase: ' + ex.getMessage());
        return false;
    }
}



    @AuraEnabled(cacheable=true)
    public static Decimal fetchTAT(String category, String type, String subType) {
        try {
            List<QRC_Process__c> qrcList = [
                SELECT TAT_in_hours__c
                FROM QRC_Process__c
                WHERE Category__c = :category
                AND Type__c = :type
                AND Sub_Type__c = :subType
                LIMIT 1
            ];

            if (!qrcList.isEmpty()) {
                return qrcList[0].TAT_in_hours__c;
            }

            return null;
        } catch (Exception ex) {
            System.debug('Error in fetchTAT: ' + ex.getMessage());
            return null;
        }
    }
    @AuraEnabled
public static Attendance__c getLatestAttendanceToday() {
    Id userId = UserInfo.getUserId();

    List<Attendance__c> records = [
        SELECT Id, Day_In_Timestamp__c, Day_Out_Timestamp__c
        FROM Attendance__c
        WHERE CreatedDate = TODAY AND CreatedById = :userId
        ORDER BY CreatedDate DESC
        LIMIT 1
    ];

    return records.isEmpty() ? null : records[0];
}
 @AuraEnabled(cacheable=true)
    public static Lead getRelatedLeadDetails(Id leadId) {
        return [SELECT Id, Name, FirstName, LastName, Status, Phone, Email, Company, 
                       CreatedDate, Owner.Name, OwnerId,Lead_No__c,Type__c,DRS__c,DRS__r.Name,Floor__c,Building_Name__c,Building_Code__c,Street__c,Street_Line_2__c,Street_Line_3__c,Street_Line_4__c,Street_Line_5__c,Flat__c,City__c,Other_City__c,District__c,Country__c,Postal_Code__c,Region__c,Time_Zone__c
                FROM Lead 
                WHERE Id = :leadId 
                LIMIT 1];
    }
  @AuraEnabled
public static void generateAndAttachLetterPDF(Id caseId, String objectType,String templateBody) {
    // Fetch the Case
    Case c = [SELECT Id, CaseNumber, Origin FROM Case WHERE Id = :caseId];

    // Check if Origin contains the word "letter" (case-insensitive)
    // if (c.Origin == null || !c.Origin.toLowerCase().contains('letter')) {
    //     return;
    // }
    Set<String> letterOriginApiNames = new Set<String>{'2', '8', '9', '17', '22', '23'};

if (c.Origin == null || !letterOriginApiNames.contains(c.Origin)) {
    System.debug('ENterded If');
    return;
}

PageReference pdfPage = Page.LetterAcknowledgmentPDF;
            pdfPage.getParameters().put('caseId', caseId);
            pdfPage.getParameters().put('objectType', objectType);
            pdfPage.getParameters().put('templateBody',templateBody);
            Blob pdfBlob = pdfPage.getContent();
    // Generate PDF
    // PageReference pdfPage = Page.LetterAcknowledgmentPDF;
    // pdfPage.getParameters().put('id', caseId);
    // pdfPage.getParameters().put('objectType', objectType);

    // Blob pdfBlob;
    // if (Test.isRunningTest()) {
    //     pdfBlob = Blob.valueOf('Test PDF Content');
    // } else {
    //     pdfBlob = pdfPage.getContentAsPDF();
    // }

    // Create and insert ContentVersion
    ContentVersion cv = new ContentVersion();
    cv.Title = 'Acknowledgment Letter - Case ' + c.CaseNumber;
    cv.PathOnClient = 'Acknowledgment-' + c.CaseNumber + '.pdf';
    cv.VersionData = pdfBlob;
    cv.FirstPublishLocationId = caseId;
    insert cv;
}

@AuraEnabled
public static void generateRefundLetter(Id caseId, String objectType,String templateBody) {
    // Fetch the Case
    Case c = [SELECT Id, CaseNumber, Origin FROM Case WHERE Id = :caseId];

PageReference pdfPage = Page.LetterAcknowledgmentPDF;
            pdfPage.getParameters().put('caseId', caseId);
            pdfPage.getParameters().put('objectType', objectType);
            pdfPage.getParameters().put('templateBody',templateBody);
            Blob pdfBlob = pdfPage.getContent();
    ContentVersion cv = new ContentVersion();
    cv.Title = 'Refund Letter ' + c.CaseNumber;
    cv.PathOnClient = 'Refund Letter-' + c.CaseNumber + '.pdf';
    cv.VersionData = pdfBlob;
    cv.FirstPublishLocationId = caseId;
    insert cv;
}
@AuraEnabled(cacheable=true)
public static User getUserInfo() {
    return [SELECT Id, Type_Of_Work__c,Profile.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
}
 @AuraEnabled(cacheable=true)
    public static Case getCaseWithNumber(Id caseId) {
        if (caseId == null) {
            throw new AuraHandledException('Invalid Case Id');
        }

        List<Case> caseList = [
            SELECT Id, CaseNumber,Lead__r.Lead_No__c
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];

        if (!caseList.isEmpty()) {
            return caseList[0];
        } else {
            throw new AuraHandledException('Case not found with the provided Id.');
        }
    }
    

}