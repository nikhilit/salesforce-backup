/**
* @description       :
* @author            : Kartik Patkar Appstrail
* @group             :
* @last modified on  : 02-02-2026
* @last modified by  : Kartik Patkar, Appstrail
* Modifications Log
* Ver   Date         Author                     Modification
* 1.0   03-11-2025   Kartik Patkar, Appstrail   Initial Version
**/
public with sharing class MeteringWorkOrderListViewController {
    
    public class ListViewConfigResponse {
        @AuraEnabled public String listViewLabel;
        @AuraEnabled public String listViewDeveloperName;
        @AuraEnabled public String objectApiName;
        @AuraEnabled public String recordTypeDevName;
        @AuraEnabled public String imageFields;
        @AuraEnabled public String htmlFields;
        @AuraEnabled public String customerCategory;
        @AuraEnabled public String filters;
        @AuraEnabled public List<Map<String,Object>> columns;
    }
    
    // utils
    private static List<String> splitPath(String f){
        return f.contains('.') ? f.split('\\.') : new List<String>{f};
            }
    
    private static String flat(String f){
        return f.replace('.', '_');
    }
    private static Boolean isParentField(String f){ return f.contains('.'); }
    private static String last(String f){ List<String> p = splitPath(f); return p[p.size()-1]; }
    private static Schema.SObjectType getType(String obj){ Map<String,Schema.SObjectType> gd = Schema.getGlobalDescribe(); if(!gd.containsKey(obj)) throw new AuraHandledException('Invalid Object API: '+obj); return gd.get(obj); }
    
    // column builder
    @AuraEnabled
    public static ListViewConfigResponse getDynamicColumns(String listViewName){
        String q = 'SELECT MasterLabel,Record_Type_Developer_Name__c, Field_to_Display__c, Image_Fields__c, Active__c,DeveloperName,Object_API_Name__c,HTML_Fields__c,Customer_Category__c,Filters__c FROM Metering_Listview_Config__mdt WHERE Active__c=true';
        if(!String.isBlank(listViewName)) q+=' AND DeveloperName = :listViewName';
        q+=' LIMIT 1';
        List<Metering_Listview_Config__mdt> cfg = Database.query(q);
        if(cfg.isEmpty()) throw new AuraHandledException('No active configuration found.');
        Metering_Listview_Config__mdt c = cfg[0];
        
        ListViewConfigResponse r = new ListViewConfigResponse();
        r.listViewLabel = c.MasterLabel;
        r.listViewDeveloperName = c.DeveloperName;
        r.objectApiName = c.Object_API_Name__c;
        r.recordTypeDevName = c.Record_Type_Developer_Name__c;
        r.imageFields = c.Image_Fields__c;
        r.htmlFields = c.HTML_Fields__c;
        r.customerCategory = c.Customer_Category__c;
        r.filters = c.Filters__c;
        
        Map<String,Object> fm = (Map<String,Object>)JSON.deserializeUntyped(c.Field_to_Display__c);
        
        Set<String> imageSet = new Set<String>();
        if(!String.isBlank(c.Image_Fields__c)) for(String s : c.Image_Fields__c.split(',')) imageSet.add(s.trim());
        Set<String> htmlSet = new Set<String>();
        if(!String.isBlank(c.HTML_Fields__c)) for(String s : c.HTML_Fields__c.split(',')) htmlSet.add(s.trim());
        
        Map<String,Schema.SObjectField> rootFields = getType(c.Object_API_Name__c).getDescribe().fields.getMap();
        List<Map<String,Object>> cols = new List<Map<String,Object>>();
        
        for(String api : fm.keySet()){
            Map<String,Object> col = new Map<String,Object>();
            // label: use metadata or auto-generate
            String labelFromMetadata = (String)fm.get(api);
            if(String.isBlank(labelFromMetadata)){
                // auto-generate from leaf
                String lp = last(api).replace('__c','').replace('__r','').replaceAll('([a-z])([A-Z])','$1 $2').replace('_',' ');
                List<String> words = lp.split(' ');
                for(Integer i=0;i<words.size();i++) if(words[i].length()>0) words[i]=words[i].substring(0,1).toUpperCase()+words[i].substring(1).toLowerCase();
                col.put('label', String.join(words,' '));
            } else col.put('label', labelFromMetadata);
            
            col.put('fieldName', isParentField(api) ? flat(api) : api);
            col.put('sortable', true);
            col.put('wrapText',false);
            String type = 'text';
            Map<String,Object> typeAttrs = new Map<String,Object>();
            
            if(imageSet.contains(api)){
                type='html';
                col.put('fixedWidth', 300);
                // FIX: cast fieldName to String and use Map<String,Object> for nested map
                String fn = (String)col.get('fieldName');
                typeAttrs.put('value', new Map<String,Object>{'fieldName' => fn});
            }
            else if(htmlSet.contains(api)){
                type='formula';
                String fn = (String)col.get('fieldName');
                typeAttrs.put('value', new Map<String,Object>{'fieldName' => fn});
            }
            else if(!isParentField(api) && rootFields.containsKey(api)){
                Schema.DisplayType dt = rootFields.get(api).getDescribe().getType();
                switch on dt {
                    when Date { type='date'; }
                    when DateTime {
                        type='date';
                        typeAttrs.put('day','numeric'); typeAttrs.put('month','short'); typeAttrs.put('year','numeric');
                        typeAttrs.put('hour','2-digit'); typeAttrs.put('minute','2-digit');
                    }
                    when Boolean { type='boolean'; }
                    when Double, Currency, Integer, Percent { type='number'; }
                    when Url {
                        type='url';
                        typeAttrs.put('label', new Map<String,Object>{'fieldName'=>api});
                    }
                    when else { type='text'; }
                }
            }
            
            col.put('type', type);
            if(!typeAttrs.isEmpty()) col.put('typeAttributes', typeAttrs);
            col.put('fieldName', isParentField(api) ? flat(api) : api);
            col.put('originalApi', api);
            cols.add(col);
        }
        
        r.columns = cols; return r;
    }
    
    @AuraEnabled(cacheable=false)
    public static void saveUserColumnConfig(String listViewName, String selectedFields) {
        try {
            Id userId = UserInfo.getUserId();
            
            System.debug('🔵 SAVING - userId: ' + userId);
            System.debug('🔵 SAVING - listViewName: ' + listViewName);
            System.debug('🔵 SAVING - selectedFields: ' + selectedFields);
            
            // Query existing record using listViewName (DeveloperName from metadata)
            List<User_ListView_Config__c> existingConfigs = [
                SELECT Id FROM User_ListView_Config__c 
                WHERE User__c = :userId 
                AND Name = :listViewName
                LIMIT 1
            ];
            
            System.debug('🔵 SAVING - existingConfigs count: ' + existingConfigs.size());
            
            User_ListView_Config__c config = new User_ListView_Config__c();
            
            if (!existingConfigs.isEmpty()) {
                // Update existing record
                config = existingConfigs[0];
                System.debug('🔵 SAVING - Updating existing record: ' + config.Id);
            } else {
                System.debug('🔵 SAVING - Creating new record');
            }
            
            // Set values
            config.User__c = userId;
            config.Name = listViewName;  // Store listViewName (matches metadata DeveloperName)
            config.Object_API_Name__c = listViewName;  // Also set this for reference
            config.Selected_Fields__c = selectedFields;
            config.Is_Active__c = true;
            
            // Upsert the record
            upsert config;
            
            System.debug('🟢 SAVED Successfully - config Id: ' + config.Id);
            System.debug('🟢 SAVED - Name field: ' + config.Name);
            System.debug('🟢 SAVED - Selected_Fields__c: ' + config.Selected_Fields__c);
            
        } catch (Exception e) {
            System.debug('🔴 ERROR SAVING: ' + e.getMessage());
            throw new AuraHandledException('Error saving column configuration: ' + e.getMessage());
        }
    }
    
    /**
* Get user's saved column preferences from User_ListView_Config__c object
* THE KEY FIX: Query by Name field (listViewName) instead of Object_API_Name__c
*/
    @AuraEnabled(cacheable=false)
    public static User_ListView_Config__c getUserColumnConfig(String listViewName) {
        try {
            Id userId = UserInfo.getUserId();
            
            System.debug('🔵 RETRIEVING - userId: ' + userId);
            System.debug('🔵 RETRIEVING - listViewName: ' + listViewName);
            
            // Query using listViewName (which matches metadata DeveloperName)
            List<User_ListView_Config__c> configs = [
                SELECT Id, Selected_Fields__c, Name, User__c, Is_Active__c
                FROM User_ListView_Config__c 
                WHERE User__c = :userId 
                AND Name = :listViewName
                AND Is_Active__c = true
                LIMIT 1
            ];
            
            System.debug('🔵 RETRIEVING - configs found: ' + configs.size());
            
            if (!configs.isEmpty()) {
                System.debug('🟢 FOUND - Selected_Fields__c: ' + configs[0].Selected_Fields__c);
                System.debug('🟢 FOUND - Name: ' + configs[0].Name);
                return configs[0];
            }
            
            System.debug('🟡 NO CONFIG FOUND for this user/listView');
            return null;
            
        } catch (Exception e) {
            System.debug('🔴 ERROR RETRIEVING: ' + e.getMessage());
            throw new AuraHandledException('Error retrieving column configuration: ' + e.getMessage());
        }
    }
    
    
    
    // build select list (keeps parent field syntax)
    private static List<String> buildSelectList(List<String> fields){
        List<String> out = new List<String>();
        for(String f : fields) out.add(f);
        return out;
    }
    
    // extract parent value safely and flatten into map using underscore format
    // private static void extractParentValue(SObject row, String parentField, Map<String,Object> out){
    //     List<String> path = splitPath(parentField);
    //     SObject cur = row;
    //     for(Integer i=0;i<path.size()-1;i++){
    //         if(cur==null) return;
    //         cur = (SObject)cur.getSObject(path[i]);
    //     }
    //     if(cur!=null) out.put(flat(parentField), cur.get(path[path.size()-1]));
    // }
    
    // private static Map<String,Object> flattenRow(SObject sobj, List<String> fieldList){
    //     Map<String,Object> m = new Map<String,Object>();
    //     for(String f : fieldList){
    //         if(isParentField(f)) extractParentValue(sobj,f,m);
    //         else m.put(f, sobj.get(f));
    //     }
    //     return m;
    // }
    
    // Cache parsed field paths so split() is NOT called repeatedly
    // private static Map<String, List<String>> FIELD_PATH_CACHE = new Map<String, List<String>>();
    
    // // Return cached split path
    // private static List<String> getPath(String fieldPath) {
    //     if (!FIELD_PATH_CACHE.containsKey(fieldPath)) {
    //         FIELD_PATH_CACHE.put(fieldPath, fieldPath.split('\\.'));
    //     }
    //     return FIELD_PATH_CACHE.get(fieldPath);
    // }
    
    // // Create a single underscore key like Account_Owner_Name
    // private static String flatKey(String fieldPath) {
    //     return fieldPath.replace('.', '_');
    // }
    
    // // Extract parent field value using pre-parsed paths
    // private static Object extractParentValueFast(SObject row, String fieldPath) {
    //     List<String> path = getPath(fieldPath);
    
    //     SObject current = row;
    
    //     // Traverse parent(s)
    //     for (Integer i = 0; i < path.size() - 1; i++) {
    //         if (current == null) return null;
    //         current = current.getSObject(path[i]);
    //     }
    
    //     if (current == null) return null;
    
    //     return current.get(path[path.size() - 1]);
    // }
    
    // // Flatten row into a map (optimized)
    // private static Map<String, Object> flattenRow(SObject sobj, List<String> fieldList) {
    //     Map<String, Object> out = new Map<String, Object>();
    
    //     for (String f : fieldList) {
    
    //         if (f.contains('.')) {
    //             out.put(flatKey(f), extractParentValueFast(sobj, f));
    //         } else {
    //             out.put(f, sobj.get(f));
    //         }
    //     }
    
    //     return out;
    // }
    
    // ==========================================================
    // 🚀 CPU-Optimized Flatten Utilities (Replace only this block)
    // ==========================================================
    
    // Cache parsed field paths so split() is NOT called repeatedly
    private static Map<String, List<String>> FIELD_PATH_CACHE = new Map<String, List<String>>();
    
    // Return cached split path
    private static List<String> getPath(String fieldPath) {
        if (!FIELD_PATH_CACHE.containsKey(fieldPath)) {
            FIELD_PATH_CACHE.put(fieldPath, fieldPath.contains('.') ? fieldPath.split('\\.') : new List<String>{ fieldPath });
        }
        return FIELD_PATH_CACHE.get(fieldPath);
    }
    
    // Create a single underscore key like Account_Owner_Name
    private static String flatKey(String fieldPath) {
        return fieldPath.replace('.', '_');
    }
    
    // Extract parent field value using pre-parsed paths
    private static Object extractParentValueFast(SObject row, String fieldPath) {
        List<String> path = getPath(fieldPath);
        
        SObject current = row;
        Integer lastIndex = path.size() - 1;
        
        // FAST: unrolled traversal for up to 3 levels
        if (lastIndex == 1) {
            if (current != null) current = current.getSObject(path[0]);
        }
        else if (lastIndex == 2) {
            if (current != null) current = current.getSObject(path[0]);
            if (current != null) current = current.getSObject(path[1]);
        }
        else if (lastIndex == 3) {
            if (current != null) current = current.getSObject(path[0]);
            if (current != null) current = current.getSObject(path[1]);
            if (current != null) current = current.getSObject(path[2]);
        }
        else {
            // fallback loop (rarely used)
            for (Integer i = 0; i < lastIndex && current != null; i++) {
                current = current.getSObject(path[i]);
            }
        }
        
        return (current == null) ? null : current.get(path[lastIndex]);
    }
    
    // Flatten row into a map (optimized)
    public static Map<String, Object> flattenRow(SObject sobj, List<String> fieldList) {
        Map<String, Object> out = new Map<String, Object>();
        
        for (String f : fieldList) {
            if (f.contains('.')) {
                out.put(flatKey(f), extractParentValueFast(sobj, f));
            } else {
                out.put(f, sobj.get(f));
            }
        }
        return out;
    }
    
    
    @AuraEnabled
    public static List<Map<String,Object>> getWorkOrdersDynamic(
        String recordTypeDevName,
        String fieldJson,
        String objectApiName,
        String customerCategory,
        String limitRec
    ){
        if(String.isBlank(recordTypeDevName)) throw new AuraHandledException('RecordTypeDevName missing');
        if(String.isBlank(objectApiName)) throw new AuraHandledException('ObjectApiName missing');
        
        Map<String,Object> fm = (Map<String,Object>)JSON.deserializeUntyped(fieldJson);
        List<String> soqlFields = new List<String>(fm.keySet()); // original
        List<String> displayFields = new List<String>();
        
        for (String f : fm.keySet()) {
            displayFields.add(isParentField(f) ? flat(f) : f);
        }
        if(!soqlFields.contains('Id')) soqlFields.add('Id');
        
        System.debug('soqlFields: ' + soqlFields);
        System.debug('displayFields: ' + displayFields);
        
        Map<String,Schema.RecordTypeInfo> rt = getType(objectApiName).getDescribe().getRecordTypeInfosByDeveloperName();
        if(!rt.containsKey(recordTypeDevName)) throw new AuraHandledException('Invalid RecordTypeDevName');
        Id rtId = rt.get(recordTypeDevName).getRecordTypeId();
        
        String soql = 'SELECT '+ String.join(buildSelectList(soqlFields), ',') +
            ' FROM '+objectApiName +
            ' WHERE RecordTypeId=:rtId AND Customer_Category__c=:customerCategory ORDER BY CreatedDate DESC LIMIT '+limitRec;
        
        List<SObject> rows = Database.query(soql);
        List<Map<String,Object>> out = new List<Map<String,Object>>();
        for(SObject s : rows) out.add(flattenRow(s, soqlFields));
        return out;
    }
    
    @AuraEnabled
    public static String getContentVersionBase64(String vid){
        if(String.isBlank(vid)) return null;
        ContentVersion cv=[SELECT VersionData FROM ContentVersion WHERE Id=:vid LIMIT 1];
        return EncodingUtil.base64Encode(cv.VersionData);
    }
    
    @AuraEnabled
    public static List<String> getContentVersionsBase64(List<String> contentVersionIds, Integer maxIds) {
        if (maxIds == null) maxIds = 4;
        List<String> base64List = new List<String>();
        
        if (contentVersionIds == null || contentVersionIds.isEmpty()) {
            return base64List;
        }
        
        // Limit to max 4 IDs manually
        List<String> idsToQuery = new List<String>();
        Integer limitCount = Math.min(contentVersionIds.size(), maxIds);
        for (Integer i = 0; i < limitCount; i++) {
            idsToQuery.add(contentVersionIds[i]);
        }
        
        // Query ContentVersion for VersionData
        List<ContentVersion> versions = [
            SELECT Id, VersionData
            FROM ContentVersion
            WHERE Id IN :idsToQuery
            LIMIT :maxIds
        ];
        
        for (ContentVersion cv : versions) {
            base64List.add(EncodingUtil.base64Encode(cv.VersionData));
        }
        
        return base64List;
    }
    
    /**
* @description
*
* @param objectName
* @param fieldName
* @return  `List<OptionsWrapper>`
*/
    @AuraEnabled
    public static List<OptionsWrapper> fieldPicklistValue(String objectName,String fieldName){
        List<OptionsWrapper> optionList=new List<OptionsWrapper>();
        Schema.SObjectType s = Schema.getGlobalDescribe().get(objectName) ;
        Schema.DescribeSObjectResult r = s.getDescribe();
        Map<String,Schema.SObjectField> fields = r.fields.getMap() ;
        Schema.DescribeFieldResult fieldResult = fields.get(fieldName).getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            OptionsWrapper option=new OptionsWrapper();
            option.label=pickListVal.getLabel();
            option.value=pickListVal.getValue();
            optionList.add(option);
        }
        return optionList;
    }
    
    public class OptionsWrapper{
        @AuraEnabled public String label{get;set;}
        @AuraEnabled public String value{get;set;}
    }
    
    @AuraEnabled
    public static List<OptionsWrapper> getGroupMasterOptions(){
        try {
            List<OptionsWrapper> listGroupMasterOptions = new List<OptionsWrapper>();
            List<Group_Master__c> ListGroupMasters = [SELECT Id, Name,Default__c,Group_Code__c
                                                      FROM Group_Master__c
                                                      ORDER BY Group_Code__c ASC];
            
            for (Group_Master__c groupMasterRec : ListGroupMasters) {
                OptionsWrapper groupWrapper = new OptionsWrapper();
                groupWrapper.label = groupMasterRec.Group_Code__c +' - '+ groupMasterRec.Name;
                groupWrapper.value = groupMasterRec.Id;
                listGroupMasterOptions.add(groupWrapper);
            }
            return listGroupMasterOptions;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<OptionsWrapper> getGroupCodeOptions(String groupMasterId){
        try {
            String query='SELECT Id,Name,Description__c,Default__c,Show_Meter_Reading_Option__c,Code__c,Testing_Not_possible__c,Plausibility_Check_Options__c,'+
                'Testing_Possible_Default__c,Meter_not_working__c,Meter_working__c '+
                'FROM Group_Code__c WHERE Active__c=true AND Group_Master__c=:groupMasterId';
            
            List<Group_Code__c> listGroupCodes = Database.query(query);
            
            List<OptionsWrapper> listGroupCodeOptions = new List<OptionsWrapper>();
            for(Group_Code__c groupCodeRec:listGroupCodes){
                OptionsWrapper groupWrapper = new OptionsWrapper();
                groupWrapper.label = groupCodeRec.Code__c+' - '+ groupCodeRec.Description__c;
                groupWrapper.value = groupCodeRec.Id;
                listGroupCodeOptions.add(groupWrapper);
            }
            return listGroupCodeOptions;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<OptionsWrapper> getGroupMessageOptions(String groupCodeId){
        try {
            String query = 'SELECT Id,Name,Description__c,Show_Meter_Reading_Option__c,No_of_Photos__c ,Group_Message_Code__c,LPG_Supplier__c '+
                'FROM Group_Message__c WHERE Active__c=true AND Group_Code__c=: groupCodeId';
            
            List<Group_Message__c> listGroupMessages = Database.query(query);
            
            List<OptionsWrapper> listGroupMessageOptions = new List<OptionsWrapper>();
            for(Group_Message__c groupMessageRec:listGroupMessages){
                OptionsWrapper groupWrapper = new OptionsWrapper();
                groupWrapper.label = groupMessageRec.Description__c;
                groupWrapper.value = groupMessageRec.Id;
                listGroupMessageOptions.add(groupWrapper);
            }
            return listGroupMessageOptions;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<Map<String,Object>> getWorkOrdersByFilters(
        List<String> bpNumbers,
        List<String> caNumbers,
        Date fromDate,
        Date toDate,
        String agency,
        String agent,
        String groupMasterId,
        String groupCodeId,
        String groupMessageId,
        String appointmentStatus,
        String meterNumber,
        String mruCategoryValue,
        String recordTypeDevName,
        String fieldJson,
        String objectApiName,
        String customerCategory,
        String limitRec,
        String approvalStatus,
        String area,
        String gaWiseValue,
        String locationValue
    ) {
        // Basic validation
        if (String.isBlank(recordTypeDevName)) throw new AuraHandledException('Record Type Developer Name cannot be blank');
        if (String.isBlank(objectApiName)) throw new AuraHandledException('Object API Name cannot be blank');
        
        // Parse requested fields: fm keys must be ORIGINAL API names (e.g. Account__r.Name)
        Map<String,Object> fm = (String.isBlank(fieldJson)) ? new Map<String,Object>() :
        (Map<String,Object>) JSON.deserializeUntyped(fieldJson);
        
        List<String> soqlFields = new List<String>(fm.keySet()); // original names used in SELECT
        if (!soqlFields.contains('Id')) soqlFields.add('Id');
        
        // Validate object
        Map<String,Schema.SObjectType> gd = Schema.getGlobalDescribe();
        if (!gd.containsKey(objectApiName)) throw new AuraHandledException('Invalid Object API Name: ' + objectApiName);
        
        // Get RecordTypeId
        Map<String,Schema.RecordTypeInfo> rtMap = gd.get(objectApiName).getDescribe().getRecordTypeInfosByDeveloperName();
        if (!rtMap.containsKey(recordTypeDevName)) throw new AuraHandledException('Invalid Record Type Developer Name: ' + recordTypeDevName);
        Id recordTypeId = rtMap.get(recordTypeDevName).getRecordTypeId();
        
        // Build static filters (use bind-style text — keep same style as your existing code)
        List<String> staticFilters = new List<String>();
        
        if (fromDate != null && toDate != null) {
            // Check if StartDate to EndDate range overlaps with fromDate to toDate range
            // Using DAY_ONLY to ensure full day comparison for DateTime fields
            staticFilters.add('(DAY_ONLY(StartDate) <= :toDate AND DAY_ONLY(EndDate) >= :fromDate)');
        } else if (fromDate != null) {
            staticFilters.add('DAY_ONLY(EndDate) >= :fromDate');
        } else if (toDate != null) {
            staticFilters.add('DAY_ONLY(StartDate) <= :toDate');
        }
        
        // ensure start/end added to fields so we can flatten later
        if (!soqlFields.contains('StartDate')) soqlFields.add('StartDate');
        if (!soqlFields.contains('EndDate')) soqlFields.add('EndDate');
        
        if (!String.isBlank(agency)) {
            staticFilters.add('Metering_Agency__c = \''+agency+'\'');
            if (!soqlFields.contains('Metering_Agency__c')) soqlFields.add('Metering_Agency__c');
        }
        if (!String.isBlank(agent)) {
            staticFilters.add('Assigned_Meter_Reader__c = \''+agent+'\'');
            if (!soqlFields.contains('Assigned_Meter_Reader__c')) soqlFields.add('Assigned_Meter_Reader__c');
        }
        if (!String.isBlank(groupMasterId)) {
            staticFilters.add('Group_Master__c = \''+groupMasterId+'\'');
            if (!soqlFields.contains('Group_Master__c')) soqlFields.add('Group_Master__c');
        }
        if (!String.isBlank(groupCodeId)) {
            staticFilters.add('Group_Code__c = \''+groupCodeId+'\'');
            if (!soqlFields.contains('Group_Code__c')) soqlFields.add('Group_Code__c');
        }
        if (!String.isBlank(groupMessageId)) {
            staticFilters.add('Group_Message__c = \''+groupMessageId+'\'');
            if (!soqlFields.contains('Group_Message__c')) soqlFields.add('Group_Message__c');
        }
        if (!String.isBlank(appointmentStatus)) {
            staticFilters.add('Appointment_Status__c = \''+appointmentStatus+'\'');
            if (!soqlFields.contains('Appointment_Status__c')) soqlFields.add('Appointment_Status__c');
        }
        if (!String.isBlank(meterNumber)) {
            staticFilters.add('Meter_Number__c = \''+meterNumber+'\'');
            if (!soqlFields.contains('Meter_Number__c')) soqlFields.add('Meter_Number__c');
        }
        if(!String.isBlank(mruCategoryValue)){
            staticFilters.add('Account.MRU_Category__c = \''+mruCategoryValue+'\'');
            if (!soqlFields.contains('Account.MRU_Category__c')) soqlFields.add('Account.MRU_Category__c');
        }
        if(!String.isBlank(approvalStatus)){
            staticFilters.add('Approval_Status__c = \''+approvalStatus+'\'');
            if (!soqlFields.contains('Approval_Status__c')) soqlFields.add('Approval_Status__c');
        }
        if(!String.isBlank(area)){
            staticFilters.add('Area__c = \''+area+'\'');
            if (!soqlFields.contains('Area__c')) soqlFields.add('Area__c');
        }
        if(!String.isBlank(gaWiseValue)){
            staticFilters.add('GA_Wise__c = \''+gaWiseValue+'\'');
            if (!soqlFields.contains('GA_Wise__c')) soqlFields.add('GA_Wise__c');
        }
        if(!String.isBlank(locationValue)){
            staticFilters.add('Account.Location__c = \''+locationValue+'\'');
            if (!soqlFields.contains('Account.Location__c')) soqlFields.add('Account.Location__c');
        }
        
        // Your business static conditions
        staticFilters.add('Customer_Category__c = \''+customerCategory+'\'');
        staticFilters.add('RecordTypeId = :recordTypeId');
        
        String staticWhere = staticFilters.isEmpty() ? '' : ' AND ' + String.join(staticFilters, ' AND ');
        
        // Prepare deduplicated sets
        Set<String> uniqueBPs = (bpNumbers != null) ? new Set<String>(bpNumbers) : new Set<String>();
        Set<String> uniqueCAs = (caNumbers != null) ? new Set<String>(caNumbers) : new Set<String>();
        
        // if nothing provided -> error
        if (uniqueBPs.isEmpty() && uniqueCAs.isEmpty()
            && fromDate == null && toDate == null
            && String.isBlank(agency) && String.isBlank(agent)
            && String.isBlank(groupMasterId) && String.isBlank(groupCodeId)
            && String.isBlank(groupMessageId) && String.isBlank(appointmentStatus)
            && String.isBlank(meterNumber) && String.isBlank(mruCategoryValue)
            && String.isBlank(area) && String.isBlank(gaWiseValue)&& String.isBlank(approvalStatus)&&String.isBlank(locationValue)) {
                throw new AuraHandledException('Please provide at least one search parameter.');
            }
        
        List<Map<String,Object>> finalRows = new List<Map<String,Object>>();
        Integer batchSize = 2000;
        Integer queryCount = 0;
        
        // If BP list present, run batched queries on BP_Number__c
        if (!uniqueBPs.isEmpty()) {
            finalRows.addAll(runBatchedQueriesForFilters(uniqueBPs, 'BP_Number__c', staticWhere, batchSize, queryCount, soqlFields, recordTypeId, fromDate, toDate,limitRec));
        } else if (!uniqueCAs.isEmpty()) {
            finalRows.addAll(runBatchedQueriesForFilters(uniqueCAs, 'Customer_CA_Number__c', staticWhere, batchSize, queryCount, soqlFields, recordTypeId, fromDate, toDate,limitRec));
        } else {
            // No BP/CA — single query using staticWhere
            String whereClause = staticWhere.replaceFirst('^ AND ', '');
            String q = 'SELECT ' + String.join(soqlFields, ',') + ' FROM WorkOrder ' + (String.isBlank(whereClause) ? '' : ' WHERE ' + whereClause);
            q+= ' ORDER BY CreatedDate DESC LIMIT '+limitRec;
            List<SObject> rows = Database.query(q);
            for (SObject s : rows) finalRows.add(flattenRow(s, soqlFields));
        }
        
        return finalRows;
    }
    
    // Helper: run batched queries for large BP/CA sets and flatten results
    private static List<Map<String,Object>> runBatchedQueriesForFilters(
        Set<String> values,
        String fieldName,
        String staticWhere,
        Integer batchSize,
        Integer queryCount,
        List<String> soqlFields,
        Id recordTypeId,
        Date fromDate,
        Date toDate,
        String limitRec
    ) {
        List<Map<String,Object>> results = new List<Map<String,Object>>();
        List<String> chunk = new List<String>();
        for (String v : values) {
            chunk.add(v);
            if (chunk.size() == batchSize) {
                queryCount++;
                if (queryCount > 100) throw new AuraHandledException('You have exceeded the maximum search limit. Please reduce the number of BP or CA Numbers and try again.');
                results.addAll(runDynamicQueryForFilters(fieldName, chunk, staticWhere, soqlFields, recordTypeId, fromDate, toDate, limitRec));
                chunk.clear();
            }
        }
        if (!chunk.isEmpty()) {
            queryCount++;
            if (queryCount > 100) throw new AuraHandledException('You have exceeded the maximum search limit. Please reduce the number of BP or CA Numbers and try again.');
            results.addAll(runDynamicQueryForFilters(fieldName, chunk, staticWhere, soqlFields, recordTypeId, fromDate, toDate, limitRec));
        }
        return results;
    }
    
    // Helper: run one dynamic query for a single chunk and flatten rows
    private static List<Map<String,Object>> runDynamicQueryForFilters(
        String fieldName,
        List<String> values,
        String staticWhere,
        List<String> soqlFields,
        Id recordTypeId,
        Date fromDate,
        Date toDate,
        String limitRec
    ) {
        String whereClause = fieldName + ' IN :values';
        
        // ✅ Strip leading AND or spaces to avoid "AND AND"
        String cleanStaticWhere = staticWhere;
        if (cleanStaticWhere.startsWith(' AND')) {
            cleanStaticWhere = cleanStaticWhere.substring(4);
        }
        cleanStaticWhere = cleanStaticWhere.trim();
        
        // ✅ Append safely
        if (!String.isBlank(cleanStaticWhere)) {
            whereClause += ' AND ' + cleanStaticWhere;
        }
        
        String q = 'SELECT ' + String.join(soqlFields, ',') +
            ' FROM WorkOrder WHERE ' + whereClause +
            ' ORDER BY CreatedDate DESC LIMIT '+limitRec;
        
        List<SObject> rows = Database.query(q);
        
        List<Map<String,Object>> out = new List<Map<String,Object>>();
        for (SObject s : rows) {
            out.add(flattenRow(s, soqlFields));
        }
        return out;
    }
    
    @AuraEnabled
    public static List<OptionsWrapper> getMRUCategoryOptions(){
        try {
            List<AggregateResult> listMRUCategories = [SELECT MRU_Category__c FROM Account WHERE MRU_Category__c!=null AND Category__c ='MRS' group by MRU_Category__c];
            
            List<OptionsWrapper> listMRUCategoryOptions = new List<OptionsWrapper>();
            for(AggregateResult ar:listMRUCategories){
                OptionsWrapper categoryWrapper = new OptionsWrapper();
                categoryWrapper.label = (String)ar.get('MRU_Category__c');
                categoryWrapper.value = (String)ar.get('MRU_Category__c');
                listMRUCategoryOptions.add(categoryWrapper);
            }
            
            return listMRUCategoryOptions;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled(cacheable=true)
    public static List<OptionsWrapper> getareaOptions() {
        try {
            // Get Metering Record Type ID
            String meteringRecordTypeId = Schema.getGlobalDescribe()
                .get('WorkOrder')
                .getDescribe()
                .getRecordTypeInfosByDeveloperName()
                .get('MGL_Metering')
                .getRecordTypeId();
            
            // Aggregate query to fetch DISTINCT Area__c values
            List<AggregateResult> results = [
                SELECT Account.Area__c Area__c
                FROM WorkOrder 
                WHERE Account.Area__c != null
                AND RecordTypeId = :meteringRecordTypeId
                GROUP BY Account.Area__c
                ORDER BY Account.Area__c
            ];
            
            List<OptionsWrapper> areaOptions = new List<OptionsWrapper>();
            
            for (AggregateResult ar : results) {
                String area = (String) ar.get('Area__c');
                
                OptionsWrapper option = new OptionsWrapper();
                option.label = area;
                option.value = area;
                areaOptions.add(option);
            }
            
            return areaOptions;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<OptionsWrapper> getGAWiseOptions() {
        try {
            // Get Metering Record Type ID
            String meteringRecordTypeId = Schema.getGlobalDescribe()
                .get('WorkOrder')
                .getDescribe()
                .getRecordTypeInfosByDeveloperName()
                .get('MGL_Metering')
                .getRecordTypeId();
            
            // Aggregate query to fetch DISTINCT GA_Wise__c values
            List<AggregateResult> results = [
                SELECT Account.GA_Wise__c GA_Wise__c
                FROM WorkOrder
                WHERE Account.GA_Wise__c  != null
                AND RecordTypeId = :meteringRecordTypeId
                GROUP BY Account.GA_Wise__c 
                ORDER BY Account.GA_Wise__c 
            ];
            
            List<OptionsWrapper> gaWiseOptions = new List<OptionsWrapper>();
            
            for (AggregateResult ar : results) {
                String gaWise = (String) ar.get('GA_Wise__c');
                
                OptionsWrapper option = new OptionsWrapper();
                option.label = gaWise;
                option.value = gaWise;
                gaWiseOptions.add(option);
            }
            
            return gaWiseOptions;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /*public static List<Map<String, Object>> runMassiveQuery(String soql){
List<Map<String, Object>> finalList = new List<Map<String, Object>>();

String baseUrl = System.Url.getOrgDomainUrl().toExternalForm();
String apiVersion = 'v60.0';

Http http = new Http();
HttpRequest req = new HttpRequest();
req.setMethod('GET');
req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
req.setTimeout(120000); // 2 minutes per call

// FIRST CALL
req.setEndpoint(baseUrl + '/services/data/' + apiVersion + '/query?q=' +
EncodingUtil.urlEncode(soql, 'UTF-8'));

while (true) {
HttpResponse res = http.send(req);

if(res.getStatusCode() >= 300){
throw new AuraHandledException('REST Query Error: ' + res.getBody());
}

Map<String, Object> result =
(Map<String, Object>) JSON.deserializeUntyped(res.getBody());

List<Object> records = (List<Object>) result.get('records');

for(Object row : records){
finalList.add((Map<String,Object>)row);
}

Boolean done = (Boolean) result.get('done');
if(done){
break;
}

// NEXT PAGE
String nextUrl = (String) result.get('nextRecordsUrl');
req.setEndpoint(baseUrl + nextUrl);
}

return finalList;
}*/
    @AuraEnabled(cacheable=true)
    public static List<OptionsWrapper> getLocationOptions() {
        try {
            // Get Metering Record Type ID
            String meteringRecordTypeId = Schema.getGlobalDescribe()
                .get('WorkOrder')
                .getDescribe()
                .getRecordTypeInfosByDeveloperName()
                .get('MGL_Metering')
                .getRecordTypeId();
            
            // Aggregate query to fetch DISTINCT Account.Location__c values
            List<AggregateResult> results = [
                SELECT Account.Location__c loc
                FROM WorkOrder
                WHERE Account.Location__c != null
                AND RecordTypeId = :meteringRecordTypeId
                GROUP BY Account.Location__c
                ORDER BY Account.Location__c
            ];
            
            List<OptionsWrapper> locationOptions = new List<OptionsWrapper>();
            
            for (AggregateResult ar : results) {
                String loc = (String) ar.get('loc');
                
                OptionsWrapper option = new OptionsWrapper();
                option.label = loc;
                option.value = loc;
                locationOptions.add(option);
            }
            
            return locationOptions;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    
    
    
    
    @AuraEnabled
    public static Map<String, String> getS3PathByContentVersionId(List<String> contentVersionIds) {
        try {
            System.debug('🔵 ========== START getS3PathByContentVersionId ==========');
            System.debug('🔵 Received ContentVersionIds: ' + contentVersionIds.size());
            for(String id : contentVersionIds) {
                System.debug('   - ' + id);
            }
            
            Map<String, String> resultMap = new Map<String, String>();
            
            if (contentVersionIds == null || contentVersionIds.isEmpty()) {
                System.debug('🟡 No ContentVersionIds provided');
                return resultMap;
            }
            
            // Initialize result map
            for (String cvId : contentVersionIds) {
                resultMap.put(cvId, '');
            }
            
            // ====== STEP 1: Get ContentDocumentIds and CV details ======
            System.debug('🔵 STEP 1: Fetching ContentDocumentIds from ContentVersions...');
            
            Map<String, String> cvIdToContentDocId = new Map<String, String>();
            Map<String, ContentVersion> cvMap = new Map<String, ContentVersion>();
            
            List<ContentVersion> contentVersions = [
                SELECT Id, ContentDocumentId, Title, FileExtension, CreatedDate
                FROM ContentVersion
                WHERE Id IN :contentVersionIds
            ];
            
            System.debug('🔵 ContentVersions found: ' + contentVersions.size());
            
            for (ContentVersion cv : contentVersions) {
                cvIdToContentDocId.put(cv.Id, cv.ContentDocumentId);
                cvMap.put(cv.Id, cv);
                System.debug('🟢 CV: ' + cv.Id + ' | Title: ' + cv.Title + ' -> ContentDoc: ' + cv.ContentDocumentId);
            }
            
            if (cvIdToContentDocId.isEmpty()) {
                System.debug('🔴 NO ContentDocumentIds found');
                return resultMap;
            }
            
            Set<String> contentDocIds = new Set<String>(cvIdToContentDocId.values());
            System.debug('🔵 Unique ContentDocumentIds: ' + contentDocIds.size());
            
            // ====== STEP 2: Find Document__c records linked via ContentDocumentLink ======
            System.debug('🔵 STEP 2: Querying ContentDocumentLink to find linked Documents...');
            
            // Get Document__c object key prefix dynamically
            String documentPrefix = Schema.getGlobalDescribe().get('Document__c').getDescribe().getKeyPrefix();
            System.debug('🔵 Document__c Key Prefix: ' + documentPrefix);
            
            List<ContentDocumentLink> links = [
                SELECT Id, LinkedEntityId, ContentDocumentId
                FROM ContentDocumentLink
                WHERE ContentDocumentId IN :contentDocIds
            ];
            
            System.debug('🔵 ContentDocumentLinks found: ' + links.size());
            
            Set<String> documentIds = new Set<String>();
            Map<String, String> contentDocIdToDocumentId = new Map<String, String>();
            
            for (ContentDocumentLink link : links) {
                String linkedId = link.LinkedEntityId;
                
                // Check if linked to a Document__c using dynamic prefix
                if (linkedId.startsWith(documentPrefix)) {
                    documentIds.add(linkedId);
                    contentDocIdToDocumentId.put(link.ContentDocumentId, linkedId);
                    System.debug('🟢 Link: ContentDoc ' + link.ContentDocumentId + ' -> Document ' + linkedId);
                }
            }
            
            System.debug('🔵 Documents found via ContentDocumentLink: ' + documentIds.size());
            
            if (documentIds.isEmpty()) {
                System.debug('🟡 NO Document__c records linked to these ContentDocuments');
                return resultMap;
            }
            
            // ====== STEP 3: Query Document__c records ======
            System.debug('🔵 STEP 3: Querying Document__c records...');
            
            List<Document__c> documents = [
                SELECT Id, S3_path__c, File_Name__c, Work_Order__c, CreatedDate
                FROM Document__c
                WHERE Id IN :documentIds
                AND S3_path__c != null
                AND S3_path__c != ''
            ];
            
            System.debug('🔵 Document__c records with S3_path: ' + documents.size());
            
            Map<String, String> documentIdToS3Path = new Map<String, String>();
            
            for (Document__c doc : documents) {
                documentIdToS3Path.put(doc.Id, doc.S3_path__c);
                System.debug('🟢 Document: ' + doc.Id + ' -> S3: ' + doc.S3_path__c + ' | File: ' + doc.File_Name__c);
            }
            
            // ====== STEP 4: Map ContentVersionIds to S3 Paths ======
            System.debug('🔵 STEP 4: Matching ContentVersionIds to S3 Paths...');
            
            for (String cvId : cvIdToContentDocId.keySet()) {
                String contentDocId = cvIdToContentDocId.get(cvId);
                String documentId = contentDocIdToDocumentId.get(contentDocId);
                
                if (documentId != null && documentIdToS3Path.containsKey(documentId)) {
                    String s3Path = documentIdToS3Path.get(documentId);
                    resultMap.put(cvId, s3Path);
                    System.debug('🟢 MATCHED: ' + cvId + ' -> ContentDoc: ' + contentDocId + ' -> Doc: ' + documentId + ' -> S3: ' + s3Path);
                } else {
                    System.debug('🟡 NO MATCH: ' + cvId + ' -> ContentDoc: ' + contentDocId + ' -> Doc: ' + documentId);
                }
            }
            
            // ====== FINAL RESULTS ======
            System.debug('🔵 ========== FINAL RESULTS ==========');
            Integer matched = 0;
            for (String cvId : resultMap.keySet()) {
                String path = resultMap.get(cvId);
                if (path != '') {
                    matched++;
                    System.debug('✅ ' + cvId + ' -> ' + path);
                } else {
                    System.debug('❌ ' + cvId + ' -> NOT FOUND');
                }
            }
            System.debug('🔵 Matched: ' + matched + ' / ' + contentVersionIds.size());
            System.debug('🟢 Final map: ' + JSON.serialize(resultMap));
            
            return resultMap;
            
        } catch (Exception e) {
            System.debug('🔴 ERROR: ' + e.getMessage());
            System.debug('🔴 STACK: ' + e.getStackTraceString());
            throw new AuraHandledException('Error matching images: ' + e.getMessage());
        }
    }

    /**
     * @description Executes the WorkOrderImageBatch to process and assign images to WorkOrder fields
     * @return String - Batch Job ID
    */
    
        @AuraEnabled
    public static String executeBatchImageProcess() {
        try {
            // Get RecordTypeId
            Id meteringRecordTypeId = Schema.getGlobalDescribe()
                .get('WorkOrder')
                .getDescribe()
                .getRecordTypeInfosByDeveloperName()
                .get('MGL_Metering')
                .getRecordTypeId();
            
            // Build WHERE clause
            String whereClause = 'WHERE Customer_Category__c = \'MRS\' AND RecordTypeId = \'' + meteringRecordTypeId + '\'';
            
            // Pass to batch constructor
            WorkOrderImageBatch batch = new WorkOrderImageBatch(whereClause);
            
            // Execute batch
            String jobId = Database.executeBatch(batch, 200);
            
            System.debug('✅ Batch Job Started with ID: ' + jobId);
            return jobId;
            
        } catch (Exception e) {
            System.debug('❌ Error: ' + e.getMessage());
            throw new AuraHandledException('Batch execution failed: ' + e.getMessage());
        }
    }
}