public with sharing class CaseListViewController {

   @AuraEnabled(cacheable=true)
    public static CaseWrapper getCases(
        Integer pageSize, Integer pageNumber,
        String caseNumber, String businessPartner, String subject,
        String status, String origin, String category, String type,
        String subType, String value, String caseSource, String caseOwner, String department,
        String searchKey, String departmentRespondedFrom, String departmentRespondedTo,
        Boolean defaultFRL
    ) {
        System.debug('caseOwner parameter received: ' + caseOwner);
        System.debug('caseOwner is null: ' + (caseOwner == null));
        System.debug('caseOwner is empty string: ' + (caseOwner == ''));
        try {
            Integer offset = (pageNumber - 1) * pageSize;

            List<String> conditions = new List<String>();
            Map<String, Object> params = new Map<String, Object>();

            params.put('pageSize', pageSize);
            params.put('offset', offset);

            // Get current user's profile name
            String profileName = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1].Name.toLowerCase();
           
            // FIXED: Better profile detection for Call Center Team Lead
            Boolean isCallCenterTL = profileName.contains('call') &&
                                   profileName.contains('center') &&
                                   (profileName.contains('team lead') ||
                                    profileName.contains('teamlead') ||
                                    profileName.contains('team leader'));

            System.debug('isCallCenterTL: ' + isCallCenterTL);
            System.debug('profileName: ' + profileName);

            // FIXED: Simplified case owner empty detection
            Boolean isCaseOwnerEmpty = (caseOwner == null || caseOwner == '' || caseOwner == '[]');
            System.debug('isCaseOwnerEmpty: ' + isCaseOwnerEmpty);

            // Apply default filter for Call Center Team Lead
            if (isCallCenterTL && isCaseOwnerEmpty) {
                conditions.add('Owner.Name = :crmQueueName');
                params.put('crmQueueName', 'CRM Queue');
                System.debug('✅ Applied default CRM Queue filter for Call Center Team Lead');
            } else if (!isCaseOwnerEmpty) {
                // Handle case owner filter when explicitly provided
                List<String> caseOwnerList = extractCaseOwnerList(caseOwner);
                System.debug('Extracted caseOwnerList: ' + caseOwnerList);
               
                if(!caseOwnerList.isEmpty() && !caseOwnerList.contains('')) {
                    conditions.add('Owner.Name IN :caseOwnerList');
                    params.put('caseOwnerList', caseOwnerList);
                    System.debug('Applied case owner filter: ' + caseOwnerList);
                }
            }

            // Add debug to see if condition was added
            System.debug('Conditions after case owner logic: ' + conditions);
            System.debug('Params after case owner logic: ' + params);

            // ... rest of your existing code remains the same
            if (!String.isBlank(searchKey)) {
                String escapedSearch = '%' + String.escapeSingleQuotes(searchKey) + '%';
                List<String> searchConditions = new List<String>();
                searchConditions.add('CaseNumber LIKE :escapedSearch');
                searchConditions.add('Docket_Number__c LIKE :escapedSearch');
                searchConditions.add('Subject LIKE :escapedSearch');
                searchConditions.add('Status LIKE :escapedSearch');
                searchConditions.add('Origin LIKE :escapedSearch');
                searchConditions.add('Priority LIKE :escapedSearch');
                searchConditions.add('Category__c LIKE :escapedSearch');
                searchConditions.add('Type__c LIKE :escapedSearch');
                searchConditions.add('Sub_Type__c LIKE :escapedSearch');
                searchConditions.add('Value_1__c LIKE :escapedSearch');
                searchConditions.add('Department__c LIKE :escapedSearch');
                searchConditions.add('CreatedBy.Name LIKE :escapedSearch');
                searchConditions.add('Case_Source__c LIKE :escapedSearch');
                conditions.add('(' + String.join(searchConditions, ' OR ') + ')');
                params.put('escapedSearch', escapedSearch);
            }

            if (!String.isBlank(caseNumber)) {
                conditions.add('(CaseNumber LIKE :caseNumber OR Docket_Number__c LIKE :caseNumber)');
                params.put('caseNumber', '%' + caseNumber + '%');
            }
            if (!String.isBlank(subject)) {
                conditions.add('Subject LIKE :subject');
                params.put('subject', '%' + subject + '%');
            }
           
            if (!String.isBlank(status)) {
                List<String> statusList = extractStringList(status);
                if(!statusList.isEmpty()) {
                    conditions.add('Status IN :statusList');
                    params.put('statusList', statusList);
                }
            }
            if (!String.isBlank(origin)) {
                List<String> originList = extractStringList(origin);
                if(!originList.isEmpty()) {
                    List<String> originApiList = new List<String>();
                    for(String originLabel : originList) {
                        String originApi = getPicklistApiValue('Case', 'Origin', originLabel);
                        originApiList.add(originApi);
                    }
                    conditions.add('(Origin IN :originList OR Origin IN :originApiList)');
                    params.put('originList', originList);
                    params.put('originApiList', originApiList);
                }
            }
            if (!String.isBlank(category)) {
                List<String> categoryList = extractStringList(category);
                if(!categoryList.isEmpty()) {
                    List<String> categoryApiList = new List<String>();
                    for(String categoryLabel : categoryList) {
                        String categoryApi = getPicklistApiValue('Case', 'Category__c', categoryLabel);
                        categoryApiList.add(categoryApi);
                    }
                    conditions.add('(Category__c IN :categoryList OR Category__c IN :categoryApiList)');
                    params.put('categoryList', categoryList);
                    params.put('categoryApiList', categoryApiList);
                }
            }
            if (!String.isBlank(type)) {
                List<String> typeList = extractStringList(type);
                if(!typeList.isEmpty()) {
                    conditions.add('Type__c IN :typeList');
                    params.put('typeList', typeList);
                }
            }
            if (!String.isBlank(subType)) {
                List<String> subTypeList = extractStringList(subType);
                if(!subTypeList.isEmpty()) {
                    conditions.add('Sub_Type__c IN :subTypeList');
                    params.put('subTypeList', subTypeList);
                }
            }
            if (!String.isBlank(value)) {
                List<String> valueList = extractStringList(value);
                if(!valueList.isEmpty()) {
                    conditions.add('Value_1__c IN :valueList');
                    params.put('valueList', valueList);
                }
            }
            if (!String.isBlank(caseSource)) {
                List<String> caseSourceList = extractStringList(caseSource);
                if(!caseSourceList.isEmpty()) {
                    conditions.add('Case_Source__c IN :caseSourceList');
                    params.put('caseSourceList', caseSourceList);
                }
            }

            if (!String.isBlank(department)) {
                List<String> departmentList = extractStringList(department);
                if(!departmentList.isEmpty()) {
                    List<String> departmentApiList = new List<String>();
                    for(String departmentLabel : departmentList) {
                        String departmentApi = getPicklistApiValue('Case', 'Department__c', departmentLabel);
                        if(departmentApi != null) {
                            departmentApiList.add(departmentApi);
                        }
                    }
                    conditions.add('(Department__c IN :departmentList OR Department__c IN :departmentApiList)');
                    params.put('departmentList', departmentList);
                    params.put('departmentApiList', departmentApiList);
                }
            }

            // ADDED: FRL filter
            if (defaultFRL != null) {
                conditions.add('FRL__c = :defaultFRL');
                params.put('defaultFRL', defaultFRL);
            }

            if (!String.isBlank(departmentRespondedFrom) && !String.isBlank(departmentRespondedTo)) {
                Date fromDate = Date.valueOf(departmentRespondedFrom);
                Date toDate = Date.valueOf(departmentRespondedTo);
                conditions.add('Department_Responded_On__c >= :fromDate AND Department_Responded_On__c <= :toDate');
                params.put('fromDate', fromDate);
                params.put('toDate', toDate);
            } else if (!String.isBlank(departmentRespondedFrom)) {
                Date fromDate = Date.valueOf(departmentRespondedFrom);
                conditions.add('Department_Responded_On__c >= :fromDate');
                params.put('fromDate', fromDate);
            } else if (!String.isBlank(departmentRespondedTo)) {
                Date toDate = Date.valueOf(departmentRespondedTo);
                conditions.add('Department_Responded_On__c <= :toDate');
                params.put('toDate', toDate);
            }

            String query = 'SELECT Id, CaseNumber, Docket_Number__c, AccountId, Account.Name, Subject, Status, Origin, ' +
                           'Priority, Category__c, Type__c, Sub_Type__c, Value_1__c, CRM_Assigned_date__c, CreatedDate, ' +
                           'OwnerId, Owner.Name, Reopen_Count__c, Department__c, Assigned_To__c, Assigned_To__r.Name, ' +
                           'Outstanding_Payment_Cleared__c, Comments, CreatedBy.Name, Department_Responded_On__c, ' +
                           'Case_Source__c, FRL__c, Outgoing_Calls_Count__c ' + 
                           'FROM Case WHERE Id != null';

            if (!conditions.isEmpty()) {
                query += ' AND ' + String.join(conditions, ' AND ');
            }

            query += ' ORDER BY CreatedDate DESC LIMIT :pageSize OFFSET :offset';

            System.debug('Final Query: ' + query);
            System.debug('Query Params: ' + params);

            List<Case> cases = Database.queryWithBinds(query, params, AccessLevel.USER_MODE);

            Map<String, String> picklistMappings = getPicklistLabelMappings();
            for(Case caseRec : cases) {
                if(caseRec.Origin != null && picklistMappings.containsKey('Origin_' + caseRec.Origin)) {
                    caseRec.Origin = picklistMappings.get('Origin_' + caseRec.Origin);
                }
                if(caseRec.Department__c != null && picklistMappings.containsKey('Department__c_' + caseRec.Department__c)) {
                    caseRec.Department__c = picklistMappings.get('Department__c_' + caseRec.Department__c);
                }
                if(caseRec.Category__c != null && picklistMappings.containsKey('Category__c_' + caseRec.Category__c)) {
                    caseRec.Category__c = picklistMappings.get('Category__c_' + caseRec.Category__c);
                }
                if(caseRec.Priority != null && picklistMappings.containsKey('Priority_' + caseRec.Priority)) {
                    caseRec.Priority = picklistMappings.get('Priority_' + caseRec.Priority);
                }
            }

            String countQuery = 'SELECT COUNT() FROM Case WHERE Id != null';
            if (!conditions.isEmpty()) {
                countQuery += ' AND ' + String.join(conditions, ' AND ');
            }
           
            Map<String, Object> countParams = new Map<String, Object>(params);
            countParams.remove('pageSize');
            countParams.remove('offset');
           
            Integer totalSize = Database.countQueryWithBinds(countQuery, countParams, AccessLevel.USER_MODE);

            return new CaseWrapper(cases, totalSize);

        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving cases: ' + e.getMessage());
        }
    }
private static List<String> extractStringList(String input) {
        if (String.isBlank(input)) {
            return new List<String>();
        }
       
        System.debug('extractStringList input: ' + input);
       
        // Handle JSON array format
        if (input.startsWith('[')) {
            try {
                List<String> result = (List<String>)JSON.deserialize(input, List<String>.class);
                System.debug('JSON deserialized result: ' + result);
                return result;
            } catch (Exception e) {
                System.debug('JSON deserialization failed, using as single value: ' + e.getMessage());
                return new List<String>{input};
            }
        }
       
        // Single value
        return new List<String>{input};
    }

    // Special handling for case owner lists
    private static List<String> extractCaseOwnerList(String caseOwnerParam) {
        if (String.isBlank(caseOwnerParam)) {
            return new List<String>();
        }
       
        System.debug('extractCaseOwnerList raw input: ' + caseOwnerParam);
       
        List<String> result = extractStringList(caseOwnerParam);
       
        // Additional cleanup for case owners
        List<String> cleanedList = new List<String>();
        for (String owner : result) {
            if (String.isNotBlank(owner) && owner != 'null') {
                cleanedList.add(owner);
            }
        }
       
        System.debug('Cleaned case owner list: ' + cleanedList);
        return cleanedList;
    }

    private static String getPicklistApiValue(String objectName, String fieldName, String label) {
        if(String.isBlank(label)) return label;
        
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        Schema.DescribeFieldResult fieldDescribe = objDescribe.fields.getMap().get(fieldName).getDescribe();
        
        for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
            if (entry.isActive() && entry.getLabel() == label) {
                return entry.getValue();
            }
        }
        return label;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getPicklistLabelMappings() {
        Map<String, String> apiToLabelMap = new Map<String, String>();
        
        for (Schema.PicklistEntry entry : Case.Department__c.getDescribe().getPicklistValues()) {
            if(entry.isActive()) {
                apiToLabelMap.put('Department__c_' + entry.getValue(), entry.getLabel());
            }
        }
        
        for (Schema.PicklistEntry entry : Case.Priority.getDescribe().getPicklistValues()) {
            if(entry.isActive()) {
                apiToLabelMap.put('Priority_' + entry.getValue(), entry.getLabel());
            }
        }
        
        for (Schema.PicklistEntry entry : Case.Origin.getDescribe().getPicklistValues()) {
            if(entry.isActive()) {
                apiToLabelMap.put('Origin_' + entry.getValue(), entry.getLabel());
            }
        }
        
        for (Schema.PicklistEntry entry : Case.Category__c.getDescribe().getPicklistValues()) {
            if(entry.isActive()) {
                apiToLabelMap.put('Category__c_' + entry.getValue(), entry.getLabel());
            }
        }
        
        for (Schema.PicklistEntry entry : Case.Case_Source__c.getDescribe().getPicklistValues()) {
            if(entry.isActive()) {
                apiToLabelMap.put('Case_Source__c_' + entry.getValue(), entry.getLabel());
            }
        }
        
        return apiToLabelMap;
    }

     @AuraEnabled(cacheable=true)
 
    public static UserProfileInfo getUserProfileInfo() {
 
        try {
 
            Id currentUserId = UserInfo.getUserId();
 
            User currentUser = [SELECT Id, Name, Profile.Name, UserRole.Name
 
                              FROM User
 
                              WHERE Id = :currentUserId
 
                              LIMIT 1];
 
            
 
            UserProfileInfo profileInfo = new UserProfileInfo();
 
            profileInfo.userId = currentUser.Id;
 
            profileInfo.userName = currentUser.Name;
 
            profileInfo.profileName = currentUser.Profile.Name;
 
            profileInfo.userRoleName = currentUser.UserRole.Name;
 
            
 
            String profileName = currentUser.Profile.Name.toLowerCase();
 
            
 
            // Check if user is Call Center
 
            profileInfo.isCallCenter = profileName.contains('call') && profileName.contains('center');
 
            
 
            // Check if user is Call Center Team Lead
 
            profileInfo.isCallCenterTL = profileInfo.isCallCenter &&
 
                                       (profileName.contains('team lead') || profileName.contains('team leader'));
 
            
 
            // Check if user is Back Office
 
            profileInfo.isBackOffice = profileName.contains('back') && profileName.contains('office');
 
            
 
            if (profileInfo.isCallCenter) {
 
                profileInfo.defaultStatus = new List<String>{'Actioned by Department'};
 
            }
 
            
 
            if (profileInfo.isCallCenterTL) {
 
                profileInfo.defaultCaseOwner = 'CRM Queue';
 
            }
 
            
 
            if (profileInfo.isBackOffice) {
 
                profileInfo.defaultOrigin = new List<String>{'Letters', 'E-mail'};
 
                profileInfo.defaultStatus = new List<String>{'Resolved', 'Not Actionable', 'Resolved by CRM', 'Customer Not Responded'};
 
                profileInfo.defaultFRL = false;
 
            }
 
            
 
            return profileInfo;
 
        } catch (Exception e) {
 
            throw new AuraHandledException('Error retrieving user profile info: ' + e.getMessage());
 
        }
 
    }
 
   
@AuraEnabled(cacheable=false)
    public static Bulk_Update_Result__c getJobStatus(String jobId) {
        List<Bulk_Update_Result__c> results = [
            SELECT Status__c, Message__c
            FROM Bulk_Update_Result__c
            WHERE JobId__c = :jobId
            LIMIT 1
        ];

        if (!results.isEmpty()) {
            return results[0];
        }
        return null; // still processing
    }

    @AuraEnabled(cacheable=true)
    public static List<QRC_Process__c> getPicklistValues(String department, String category, String type) {
        try {
            String query = 'SELECT Department__c, Category__c, Type__c, Sub_Type__c, Value_1__c, TAT_in_hours__c ' +
                        'FROM QRC_Process__c ' +
                        'WHERE isActive__c = true';
            
            Map<String, Object> params = new Map<String, Object>();
            
            if (!String.isBlank(department)) {
                // Check if department is a JSON array (multiple departments)
                if (department.startsWith('[')) {
                    List<String> departmentList = (List<String>)JSON.deserialize(department, List<String>.class);
                    if(!departmentList.isEmpty()) {
                        List<String> departmentApiList = new List<String>();
                        for(String departmentLabel : departmentList) {
                            String departmentApi = getPicklistApiValue('Case', 'Department__c', departmentLabel);
                            if(departmentApi != null) {
                                departmentApiList.add(departmentApi);
                            }
                        }
                        // Combine both label and API values
                        List<String> allDepartments = new List<String>();
                        allDepartments.addAll(departmentList);
                        allDepartments.addAll(departmentApiList);
                        
                        query += ' AND Department__c IN :allDepartments';
                        params.put('allDepartments', allDepartments);
                    }
                } else {
                    // Single department (backward compatibility)
                    String departmentApi = getPicklistApiValue('Case', 'Department__c', department);
                    query += ' AND (Department__c = :department OR Department__c = :departmentApi)';
                    params.put('department', department);
                    params.put('departmentApi', departmentApi);
                }
            }
            
            if (!String.isBlank(category)) {
                String categoryApi = getPicklistApiValue('Case', 'Category__c', category);
                query += ' AND (Category__c = :category OR Category__c = :categoryApi)';
                params.put('category', category);
                params.put('categoryApi', categoryApi);
            }
            
            if (!String.isBlank(type)) {
                query += ' AND Type__c = :type';
                params.put('type', type);
            }
            
            query += ' ORDER BY Category__c, Type__c, Sub_Type__c';
            
            return Database.queryWithBinds(query, params, AccessLevel.USER_MODE);
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving picklist values: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<ColumnConfig> getListViewColumns() {
        List<ColumnConfig> columns = new List<ColumnConfig>();
        
        columns.add(new ColumnConfig('Case Number', 'Docket_Number__c', 'text'));
        columns.add(new ColumnConfig('Business Partner Name', 'Account.Name', 'text'));
        columns.add(new ColumnConfig('Subject', 'Subject', 'text'));
        columns.add(new ColumnConfig('Status', 'Status', 'text'));
        columns.add(new ColumnConfig('Case Origin', 'Origin', 'text'));
        columns.add(new ColumnConfig('Priority', 'Priority', 'text'));
        columns.add(new ColumnConfig('Department', 'Department__c', 'text'));
        columns.add(new ColumnConfig('Category', 'Category__c', 'text'));
        columns.add(new ColumnConfig('Type', 'Type__c', 'text'));
        columns.add(new ColumnConfig('Sub Type', 'Sub_Type__c', 'text'));
        columns.add(new ColumnConfig('Value', 'Value_1__c', 'text'));
        columns.add(new ColumnConfig('CRM Assigned date', 'CRM_Assigned_date__c', 'date'));
        columns.add(new ColumnConfig('Date/Time Opened', 'CreatedDate', 'date'));
        columns.add(new ColumnConfig('Case Owner Name', 'Owner.Name', 'text'));
        columns.add(new ColumnConfig('Reopen Count', 'Reopen_Count__c', 'number'));
        columns.add(new ColumnConfig('FRL', 'FRL__c', 'boolean'));
        
        return columns;
    }

    @AuraEnabled(cacheable=true)
    public static List<PicklistOption> getDepartmentOptions() {
        return getPicklistOptions('Case', 'Department__c');
    }

    @AuraEnabled(cacheable=true)
    public static List<PicklistOption> getPriorityOptions() {
        return getPicklistOptions('Case', 'Priority');
    }

    @AuraEnabled(cacheable=true)
    public static List<PicklistOption> getOriginOptions() {
        return getPicklistOptions('Case', 'Origin');
    }

    @AuraEnabled(cacheable=true)
    public static List<PicklistOption> getCategoryOptions() {
        return getPicklistOptions('Case', 'Category__c');
    }

    @AuraEnabled(cacheable=true)
    public static List<PicklistOption> getStatusOptions() {
        return getPicklistOptions('Case', 'Status');
    }

    @AuraEnabled(cacheable=true)
    public static List<PicklistOption> getCaseSourceOptions() {
        return getPicklistOptions('Case', 'Case_Source__c');
    }

    private static List<PicklistOption> getPicklistOptions(String objectName, String fieldName) {
        List<PicklistOption> options = new List<PicklistOption>();
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        Schema.DescribeFieldResult fieldDescribe = objDescribe.fields.getMap().get(fieldName).getDescribe();
        
        for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
            if (entry.isActive()) {
                options.add(new PicklistOption(entry.getLabel(), entry.getValue()));
            }
        }
        return options;
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getDepartments() {
        try {
            List<Case> cases = [
                SELECT Department__c 
                FROM Case 
                WHERE Department__c != null 
                ORDER BY Department__c
                LIMIT 10000
            ];
            
            Set<String> uniqueDepartments = new Set<String>();
            for (Case c : cases) {
                if (!String.isBlank(c.Department__c)) {
                    String formattedDept = formatDepartmentName(c.Department__c);
                    if(formattedDept != null) {
                        uniqueDepartments.add(formattedDept);
                    }
                }
            }
            
            List<String> allowedDepartments = new List<String>{
                'Aftersales','BIS','Billing','CRM','Marketing','Metering',
                'O&M District Office','O&M Support Online','Project'
            };
            
            uniqueDepartments.addAll(allowedDepartments);
            
            List<String> departmentList = new List<String>(uniqueDepartments);
            departmentList.sort();
            
            return removeDuplicateAndUnwantedDepartments(departmentList);
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving departments: ' + e.getMessage());
        }
    }

    private static List<String> removeDuplicateAndUnwantedDepartments(List<String> departments) {
        Set<String> seen = new Set<String>();
        List<String> result = new List<String>();
        
        Set<String> excludedDepartments = new Set<String>{
            'C&P - Stores', 'Finance', 'EMERGENCY', 'O & M Service'
        };
        
        Map<String, String> normalizedMapping = new Map<String, String>{
            'after sales' => 'Aftersales',
            'o&m service' => 'O&M District Office',
            'o & m service' => 'O&M District Office',
            'o and m service' => 'O&M District Office'
        };
        
        for(String dept : departments) {
            if(String.isNotBlank(dept)) {
                String normalizedDept = dept.toLowerCase().trim();
                
                if(excludedDepartments.contains(dept)) {
                    continue;
                }
                
                if(normalizedMapping.containsKey(normalizedDept)) {
                    String standardDept = normalizedMapping.get(normalizedDept);
                    if(!seen.contains(standardDept)) {
                        result.add(standardDept);
                        seen.add(standardDept);
                    }
                } else {
                    if(!seen.contains(dept)) {
                        result.add(dept);
                        seen.add(dept);
                    }
                }
            }
        }
        
        result.sort();
        return result;
    }

    private static String formatDepartmentName(String departmentName) {
        if (departmentName == null) return null;
        String lowerName = departmentName.toLowerCase().trim();
        
        if(lowerName.contains('c&p') || lowerName.contains('finance') || lowerName.contains('emergency')) {
            return null;
        }
        
        Map<String, String> departmentMapping = new Map<String, String>{
            'project' => 'Project',
            'o&m support online' => 'O&M Support Online',
            'o&m district office' => 'O&M District Office',
            'o & m district office' => 'O&M District Office',
            'o and m district office' => 'O&M District Office',
            'o&m service' => 'O&M District Office',
            'o & m service' => 'O&M District Office',
            'aftersales' => 'Aftersales',
            'after sales' => 'Aftersales',
            'after-sales' => 'Aftersales',
            'bis' => 'BIS',
            'billing' => 'Billing',
            'crm' => 'CRM',
            'marketing' => 'Marketing',
            'metering' => 'Metering'
        };
        
        if (departmentMapping.containsKey(lowerName)) {
            return departmentMapping.get(lowerName);
        }
        return capitalizeWords(departmentName);
    }

    private static String capitalizeWords(String input) {
        if (input == null) return null;
        String[] words = input.split(' ');
        for (Integer i = 0; i < words.size(); i++) {
            if (words[i].length() > 0) {
                words[i] = words[i].substring(0, 1).toUpperCase() + words[i].substring(1).toLowerCase();
            }
        }
        return String.join(words, ' ');
    }

    @AuraEnabled(cacheable=true)
    public static List<User> getAssignedToUsers() {
        try {
            return [
                SELECT Id, Name 
                FROM User 
                WHERE IsActive = true 
                AND (UserType = 'Standard' OR UserType = 'PowerPartner')
                ORDER BY Name
                LIMIT 1000
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving users: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void assignCases(List<String> caseIds, String assignedTo) {
        if (caseIds == null || caseIds.isEmpty()) {
            throw new AuraHandledException('Please select at least one case to assign.');
        }
        List<Case> casesToUpdate = new List<Case>();
        for (String caseId : caseIds) {
            casesToUpdate.add(new Case(Id = caseId, Assigned_To__c = assignedTo));
        }
        if (!casesToUpdate.isEmpty()) update casesToUpdate;
    }

    @AuraEnabled
    public static String updateCases(Map<String, Object> fieldValues, List<String> caseIds) {
        if (caseIds == null || caseIds.isEmpty()) 
            throw new AuraHandledException('Please select at least one case.');
        if (fieldValues == null || fieldValues.isEmpty()) 
            throw new AuraHandledException('No field values provided to update.');

        // Enqueue the Queueable job for asynchronous execution
        CaseUpdateQueueable job = new CaseUpdateQueueable(fieldValues, caseIds);
        String jobId = System.enqueueJob(job);
        return jobId; 
    }

    public class CaseWrapper {
        @AuraEnabled public List<Case> records;
        @AuraEnabled public Integer totalSize;
        public CaseWrapper(List<Case> records, Integer totalSize) {
            this.records = records;
            this.totalSize = totalSize;
        }
    }

    public class ColumnConfig {
        @AuraEnabled public String label;
        @AuraEnabled public String fieldName;
        @AuraEnabled public String type;
        public ColumnConfig(String label, String fieldName, String type) {
            this.label = label;
            this.fieldName = fieldName;
            this.type = type;
        }
    }

    public class PicklistOption {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        public PicklistOption(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    public class UserProfileInfo {
        @AuraEnabled public String userId;
        @AuraEnabled public String userName;
        @AuraEnabled public String profileName;
        @AuraEnabled public String userRoleName;
        @AuraEnabled public List<String> defaultStatus;
        @AuraEnabled public List<String> defaultOrigin;
        @AuraEnabled public Boolean defaultFRL;
        @AuraEnabled public String queueId;
        @AuraEnabled public Boolean isCallCenterTL;
        @AuraEnabled public Boolean isCallCenter;
        @AuraEnabled public Boolean isBackOffice;
        @AuraEnabled public String defaultCaseOwner;
    }

@AuraEnabled(cacheable=true)
public static List<PicklistOption> getCaseOwnerOptions() {
    try {
        List<PicklistOption> options = new List<PicklistOption>();

        // 1. Fetch active users
        for (User u : [
            SELECT Name 
            FROM User 
            WHERE IsActive = true and profile_name__c like 'CRM %'
            ORDER BY Name
            LIMIT 500
        ]) {
            options.add(new PicklistOption(u.Name, u.Name));
        }

        // 2. Fetch case queues
        for (Group g : [
            SELECT Name 
            FROM Group 
            WHERE Type = 'Queue'
            ORDER BY Name
            LIMIT 200
        ]) {
            options.add(new PicklistOption(g.Name, g.Name));
        }

        return options;
        
    } catch (Exception e) {
        throw new AuraHandledException(
            'Error retrieving case owners: ' + e.getMessage()
        );
    }
}



}