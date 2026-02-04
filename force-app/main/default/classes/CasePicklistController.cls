public with sharing class CasePicklistController {
    
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
    
    @AuraEnabled(cacheable=true)
    public static List<QRC_Process__c> getPicklistValues(String department, String category, String type) {
        List<QRC_Process__c> queryResult = new List<QRC_Process__c>();
        if (String.isBlank(type)) {
            queryResult = [
                SELECT Department__c, Category__c, Type__c, Sub_Type__c, Value_1__c, TAT_in_hours__c
                FROM QRC_Process__c
                WHERE Department__c = :department
                AND Category__c = :category
                AND isActive__c = true
                ORDER BY Sub_Type__c
            ];
        } else {
            queryResult = [
                SELECT Department__c, Category__c, Type__c, Sub_Type__c, Value_1__c, TAT_in_hours__c
                FROM QRC_Process__c
                WHERE Department__c = :department
                AND Category__c = :category
                AND Type__c = :type
                AND isActive__c = true
                ORDER BY Sub_Type__c
            ];
        }
        System.debug('queryResult: ' + queryResult);
        return queryResult;
    }

    private static Boolean isCrmBackofficeAgent() {
        return [
            SELECT Name
            FROM Profile
            WHERE Id = :UserInfo.getProfileId()
            LIMIT 1
        ].Name == 'CRM Backoffice Agent';
    }

    @AuraEnabled
    public static void updateCaseRecord(
        Id caseId,
        String department,
        String category,
        String type,
        String subType,
        String value1,
        Map<String, String> valueMap,
        Decimal tatHours,
        String remarks,
        String newEmailId,
        String newContact,
        String newFirstName,
        String newMiddleName,
        String newLastName,
        String newSalutation,
        String meterReading,
        Date fromDate,
        Date toDate,
        String amount

    ) {
        if(caseId == null) {
            throw new AuraHandledException('Case Id is required');
        }
        
        Set<String> LETTER_ORIGIN_API_VALUES = new Set<String>{
            '2', '8', '9', '17', '22', '23'
        };
        
        Case cs=[SELECT id,department__c, origin from case where id=:caseId];


        if (
            isCrmBackofficeAgent() &&
            type == 'Customer Contact Details - Update' &&
            cs.Origin != null &&
            LETTER_ORIGIN_API_VALUES.contains(cs.Origin)
        ) {
            Integer attachmentCount = getAttachmentCount(caseId);

            if (attachmentCount == 0) {
                throw new AuraHandledException(
                    'No documents are attached to this case. Please upload at least one document before categorising.'
                );
            }
        }

        // Attachment Validation BEFORE update – only for specific QRC_Process__c
        Boolean needAttachmentValidation =
            requiresAttachmentValidation(department, category, type, subType, value1);

        if (needAttachmentValidation) {
            Integer attachmentCount = getAttachmentCount(caseId);
            System.debug('### ATTACHMENT COUNT = ' + attachmentCount);

            if (attachmentCount == 0) {
                throw new AuraHandledException(
                    'Please upload at least one document before categorising this case.'
                );
            }
        }


        

        // Convert labels to API values
        String departmentApiValue = getPicklistApiValue('Case', 'Department__c', department);
        String categoryApiValue = getPicklistApiValue('Case', 'Category__c', category);

        Case c = new Case(Id = caseId);

        if(department != null) c.Department__c = departmentApiValue;
        if(category != null)   c.Category__c   = categoryApiValue;
        if(type != null)       c.Type__c       = type;
        if(subType != null)    c.Sub_Type__c   = subType;
        if(value1 != null)     c.Value_1__c    = value1;
        if(remarks != null)    c.Remarks__c    = remarks;
        if(amount != null)    c.Amount__c     = amount;
        c.Is_Migrated__c = false;
        
        // Set new fields for CRM Contact Updates
        if (newEmailId != null) c.New_email_id__c = newEmailId;
        if (newContact != null) c.New_Contact__c = newContact;

        if (newFirstName != null)  c.New_First_Name__c  = newFirstName;
        if (newMiddleName != null) c.New_Middle_Name__c = newMiddleName;
        if (newLastName != null)   c.New_Last_Name__c   = newLastName;
        if (newSalutation != null) c.New_Salutation__c = newSalutation;


        // Set billing shortfall fields
        if (meterReading != null) c.Meter_reading__c = meterReading;
        if (fromDate != null) c.From_Date__c = fromDate;
        if (toDate != null) c.To_Date__c = toDate;

        


        if(CaseController.getLatestAttendanceToday() == null){
            throw new AuraHandledException('Check In before categorising a case');
        } 
        // else if(cs.department__c == null) {
        //     c.Attendance__c = CaseController.getLatestAttendanceToday().Id;
        //     List<Break__c> ongoingBreaks = [
        //     SELECT Id, Break_Codes__c, Break_Start_Time__c
        //     FROM Break__c
        //     WHERE Attendance__c = : c.Attendance__c AND Break_End_Time__c = null
        //     LIMIT 1
        // ];
        //     }
        else if (cs.Department__c == null) {
    // Get today's attendance record
    Attendance__c attendanceRec = CaseController.getLatestAttendanceToday();

    if (attendanceRec != null) {
        c.Attendance__c = attendanceRec.Id;

        // Check for ongoing break
        List<Break__c> ongoingBreaks = [
            SELECT Id, Break_Codes__c, Break_Start_Time__c
            FROM Break__c
            WHERE Attendance__c = :attendanceRec.Id
            AND Break_End_Time__c = null
            LIMIT 1
        ];

        // If an ongoing break is found
        if (!ongoingBreaks.isEmpty()) {
            // Option 1: throw an error to stop further processing
            throw new AuraHandledException('You are currently on a break and cannot categorize this case.');
        }
    }
}


        if (tatHours != null) {
            c.TAT__c = String.valueOf(tatHours);
            c.TAT_in_minutes__c = String.valueOf(tatHours * 60);
            c.TAT_in_days__c = String.valueOf(tatHours / 24);
        }

        if (valueMap != null) {
            if (valueMap.containsKey('PD_Reason__c')) {
                c.PD_Reason__c = valueMap.get('PD_Reason__c');
            }
            if (valueMap.containsKey('New_Address__c')) {
                c.New_Address__c = valueMap.get('New_Address__c');
            }
        }



        update c;
    }
    
    @AuraEnabled(cacheable=true)
    public static Case getCaseRecord(Id caseId) {
        return [
            SELECT Id, 
                    toLabel(Department__c), 
                    toLabel(Category__c), 
                    Type__c, 
                    Sub_Type__c, 
                    PD_Reason__c,
                    New_Address__c,
                    Value_1__c, 
                    Remarks__c,
                    Account.FirstName__c,
                    Account.Middle_Name__c,
                    Account.LastName__c,
                    Account.Full_Name__c,
                    New_First_Name__c,
                    New_Middle_Name__c,
                    New_Last_Name__c,
                    toLabel(New_Salutation__c) New_Salutation__c,
                    New_email_id__c, 
                    New_Contact__c,
                    Meter_reading__c, 
                    From_Date__c, 
                    To_Date__c, 
                    Created_Date__c, 
                    CreatedDate,
                    Amount__c
                    
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];
    }

    public static Integer getAttachmentCount(Id caseId) {
        if (caseId == null) {
            return 0;
        }

        // Count classic Attachments
        Integer legacyAttachmentCount = [
            SELECT COUNT()
            FROM Attachment
            WHERE ParentId = :caseId
        ];

        // Count Files (ContentDocumentLink)
        Integer fileCount = [
            SELECT COUNT()
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :caseId
        ];


        return legacyAttachmentCount + fileCount;
    }

    // Returns the set of QRC_Process__c Ids that require attachment validation
    private static Set<Id> getQrcIdsRequiringAttachment() {
        Set<Id> ids = new Set<Id>();
        String raw = System.Label.QRC_For_Validation;  // comma/semicolon/space separated Ids

        if (String.isBlank(raw)) {
            return ids;
        }

        // Split on comma / semicolon / whitespace
        for (String token : raw.split('[,;\\s]+')) {
            token = token.trim();
            if (String.isBlank(token)) continue;

            try {
                ids.add((Id) token);
            } catch (Exception e) {
                // Ignore any bad tokens in the label
            }
        }
        return ids;
    }

    // Check whether the current selected QRC (Dept/Category/Type/SubType/Value1)
    // is in the "requires attachment" list.
    private static Boolean requiresAttachmentValidation(
        String department,
        String category,
        String type,
        String subType,
        String value1
    ) {
        // If key fields are blank, we can't identify a QRC_Process__c
        if (String.isBlank(department) ||
            String.isBlank(category)   ||
            String.isBlank(type)       ||
            String.isBlank(subType)) {
            return false;
        }

        Set<Id> qrcIdsForValidation = getQrcIdsRequiringAttachment();
        if (qrcIdsForValidation.isEmpty()) {
            return false;
        }

        // Find the QRC_Process__c that matches the current selection
        List<QRC_Process__c> qrcList = [
            SELECT Id
            FROM QRC_Process__c
            WHERE Department__c = :department
            AND Category__c   = :category
            AND Type__c       = :type
            AND Sub_Type__c   = :subType
            AND Value_1__c    = :value1
            AND isActive__c   = true
            LIMIT 1
        ];

        return !qrcList.isEmpty() && qrcIdsForValidation.contains(qrcList[0].Id);
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getSalutationPicklist() {
        List<Map<String, String>> options = new List<Map<String, String>>();

        Schema.DescribeFieldResult fieldDesc =
            Case.New_Salutation__c.getDescribe();

        for (Schema.PicklistEntry ple : fieldDesc.getPicklistValues()) {
            if (ple.isActive()) {
                options.add(new Map<String, String>{
                    'label' => ple.getLabel(),
                    'value' => ple.getValue()   // <-- API NAME (0001, 0002)
                });
            }
        }
        return options;
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getPDReasonPicklist() {
        List<Map<String, String>> options = new List<Map<String, String>>();

        Schema.DescribeFieldResult fieldDesc =
            Case.PD_Reason__c.getDescribe();

        for (Schema.PicklistEntry ple : fieldDesc.getPicklistValues()) {
            if (ple.isActive()) {
                options.add(new Map<String, String>{
                    'label' => ple.getLabel(),
                    'value' => ple.getValue()
                });
            }
        }
        return options;
    }



}