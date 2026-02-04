/**
 * @description       :
 * @author            : Kartik Patkar Appstrail
 * @group             :
 * @last modified on  : 01-12-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   03-11-2025   Kartik Patkar, Appstrail   Initial Version
 **/
public with sharing class MeteringWorkOrderCNGListViewController {
    
    @AuraEnabled
    public static Map<String,Object> getCNGWorkOrderRecords(DataWrapper metadataConfig,String limitRec){
        try {
            String meteringRecordTypeId = Schema.getGlobalDescribe().get('WorkOrder').getDescribe()
                .getRecordTypeInfosByDeveloperName().get('MGL_Metering').getRecordTypeId();
            
            if(metadataConfig!=null){
                Map<String,Object> result=new Map<String,Object>();
                String query = 'SELECT Id, WorkOrderNumber, Account.Name,Account.Location__c,Account.Representative_Company__c,Approval_Status__c,From_Date__c,To_Date__c,(SELECT Id';
                Map<String,Object> fm = (Map<String,Object>)JSON.deserializeUntyped(metadataConfig.fields);
                for(String api : fm.keySet()){
                    if(isParentField(api)){
                        List<String> pathParts = splitPath(api);
                        String parentField = pathParts[0];
                        if(!query.contains(parentField+'.')){
                            query+=','+parentField+'.Id';
                        }
                        for(Integer i=1;i<pathParts.size();i++){
                            query+=','+parentField+'.'+pathParts[i];
                        }
                    } else {
                        query+=','+api;
                    }
                }
                query+=' FROM Dispenser_Points__r ORDER BY Point_Number__c ASC) FROM WorkOrder WHERE RecordTypeId=\''+meteringRecordTypeId+'\' AND Customer_Category__c=\'CNG/LNG\' ORDER BY CreatedDate DESC,WorkOrderNumber DESC LIMIT '+limitRec;
                System.debug('CNG Work Order Query: '+query);
                result.put('query', query);
                List<WorkOrder> listWorkOrders=(List<WorkOrder>)Database.query(query);
                result.put('records', listWorkOrders);
                Set<Id> workOrderIds = new Set<Id>();
                for(WorkOrder wo : listWorkOrders){
                    workOrderIds.add(wo.Id);
                }
                
                List<ContentDocumentLink> cdlList = [SELECT ContentDocumentId, LinkedEntityId,
                                                    ContentDocument.Title, ContentDocument.FileType, ContentDocument.LatestPublishedVersionId
                                                FROM ContentDocumentLink
                                                WHERE LinkedEntityId IN :workOrderIds ORDER BY ContentDocument.CreatedDate DESC];
                result.put('contentDocMap', cdlList);
                return result;
            }
            else{
                return null;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static DataWrapper getColumnInfo(String metadataConfigApiName){
        try {
            DataWrapper dw = new DataWrapper();
            List<Metering_Listview_Config__mdt> meteringListviewConfigs = [SELECT MasterLabel,Record_Type_Developer_Name__c, Field_to_Display__c, 
                                                                                Image_Fields__c, Active__c,DeveloperName,Object_API_Name__c,HTML_Fields__c,
                                                                                Customer_Category__c,Filters__c,Excel_Fields__c
                                                                            FROM Metering_Listview_Config__mdt 
                                                                            WHERE DeveloperName = :metadataConfigApiName 
                                                                                AND Active__c = true
                                                                            LIMIT 1];
            
            if(meteringListviewConfigs.size()>0){
                dw.columns = datatableColumns(meteringListviewConfigs[0]);
                dw.listViewLabel = meteringListviewConfigs[0].MasterLabel;
                dw.listViewDeveloperName = meteringListviewConfigs[0].DeveloperName;
                dw.objectApiName = meteringListviewConfigs[0].Object_API_Name__c;
                dw.recordTypeDevName = meteringListviewConfigs[0].Record_Type_Developer_Name__c;
                dw.imageFields = meteringListviewConfigs[0].Image_Fields__c;
                dw.htmlFields = meteringListviewConfigs[0].HTML_Fields__c;
                dw.customerCategory = meteringListviewConfigs[0].Customer_Category__c;
                dw.filters = meteringListviewConfigs[0].Filters__c;
                dw.fields = meteringListviewConfigs[0].Field_to_Display__c;
                dw.excelFields = meteringListviewConfigs[0].Excel_Fields__c;
                return dw;
            }
            return null;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    // utils
    private static List<String> splitPath(String f){
        return f.contains('.') ? f.split('\\.') : new List<String>{f};
    }
    private static String flat(String f){
        return f.replace('.', '_');
    }
    private static Boolean isParentField(String f){
        return f.contains('.');
    }
    private static String last(String f){
        List<String> p = splitPath(f);
        return p[p.size()-1];
    }
    private static Schema.SObjectType getType(String obj){
        Map<String,Schema.SObjectType> gd = Schema.getGlobalDescribe();
        if(!gd.containsKey(obj)){
            throw new AuraHandledException('Invalid Object API: '+obj);
        }
        return gd.get(obj);
    }
    
    public static List<Map<String,Object>> datatableColumns(Metering_Listview_Config__mdt configRec){
        Map<String,Object> fm = (Map<String,Object>)JSON.deserializeUntyped(configRec.Field_to_Display__c);
        
        Set<String> imageSet = new Set<String>();
        if(!String.isBlank(configRec.Image_Fields__c)) {
            for(String s : configRec.Image_Fields__c.split(',')) {
                imageSet.add(s.trim());
            }
        }
        Set<String> htmlSet = new Set<String>();
        if(!String.isBlank(configRec.HTML_Fields__c)){
            for(String s : configRec.HTML_Fields__c.split(',')) {
                htmlSet.add(s.trim());
            }
        }
        
        Map<String,Schema.SObjectField> rootFields = getType(configRec.Object_API_Name__c).getDescribe().fields.getMap();
        List<Map<String,Object>> cols = new List<Map<String,Object>>();
        
        for(String api : fm.keySet()){
            Map<String,Object> col = new Map<String,Object>();
            // label: use metadata or auto-generate
            String labelFromMetadata = (String)fm.get(api);
            if(String.isBlank(labelFromMetadata)){
                // auto-generate from leaf
                String lp = last(api).replace('__c','').replace('__r','').replaceAll('([a-z])([A-Z])','$1 $2').replace('_',' ');
                List<String> words = lp.split(' ');
                for(Integer i=0;i<words.size();i++){
                    if(words[i].length()>0){
                        words[i]=words[i].substring(0,1).toUpperCase()+words[i].substring(1).toLowerCase();
                    }
                }
                col.put('label', String.join(words,' '));
            } else {
                col.put('label', labelFromMetadata);
            }
            
            col.put('fieldName', isParentField(api) ? flat(api) : api);
            col.put('sortable', true);
            col.put('initialWidth', 120);
            String type = 'text';
            Map<String,Object> typeAttrs = new Map<String,Object>();
            
            if(imageSet.contains(api)){
                type='html';
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
        
        return cols;
    }
    
    @AuraEnabled
    public static Map<String, Object> getExcelData(
        DataWrapper metadataConfig,
    Date fromDate,
    Date toDate,
    String appointmentStatus,
    String agency,
    String agent,
    String omc,
    String zone,
    String location,
    String outlet,
    String limitRec,
    String approvalstatus,
    List<String> bpNumbers,
    String fuelPoint,
    String typeOfFuelSold,       
    String salesOfficerName,      
    String omcOfficeName          
    ) { 
        // Deserialize Excel field map
        Map<String, Object> fm = (Map<String, Object>) JSON.deserializeUntyped(metadataConfig.excelFields);
        List<String> excelFieldList = new List<String>();
        
        for (String api : fm.keySet()) {
            if (!excelFieldList.contains(api)) excelFieldList.add(api);
        }
        excelFieldList.add('Id'); // Always include Id
        
        // Get record type ID for MGL_Metering
        String meteringRecordTypeId = Schema.getGlobalDescribe()
            .get('WorkOrder')
            .getDescribe()
            .getRecordTypeInfosByDeveloperName()
            .get('MGL_Metering')
            .getRecordTypeId();
        
        // Base query
        String baseQuery = 'SELECT ' + String.join(excelFieldList, ',') +
            ' FROM Dispenser_Point__c WHERE WorkOrderID__c != null' +
            ' AND WorkOrderID__r.RecordTypeId = :meteringRecordTypeId' +
            ' AND WorkOrderID__r.Customer_Category__c = \''+metadataConfig.customerCategory+'\'';
        
        // Dynamic filters
        List<String> filters = new List<String>();
        // Prepare deduplicated sets
        Set<String> uniqueBPs = (bpNumbers != null) ? new Set<String>(bpNumbers) : new Set<String>();
        if (!uniqueBPs.isEmpty()) {
            filters.add('WorkOrderID__r.Account.BP_Number__c IN :uniqueBPs');
        }
        
        if (fromDate != null && toDate != null)
            filters.add('WorkOrderID__r.Check_Out_Date_formula__c >= :fromDate AND WorkOrderID__r.Check_Out_Date_formula__c <= :toDate');
        else if (fromDate != null)
            filters.add('WorkOrderID__r.Check_Out_Date_formula__c >= :fromDate');
        else if (toDate != null)
            filters.add('WorkOrderID__r.Check_Out_Date_formula__c <= :toDate');
        
        if (!String.isBlank(appointmentStatus))
            filters.add('WorkOrderID__r.Appointment_Status__c = :appointmentStatus');
        if (!String.isBlank(agency))
            filters.add('WorkOrderID__r.Metering_Agency__c = :agency');
        if (!String.isBlank(agent))
            filters.add('WorkOrderID__r.Assigned_Meter_Reader__c = :agent');
        if (!String.isBlank(omc))
            filters.add('WorkOrderID__r.Account.Representative_Company__c = :omc');
        if (!String.isBlank(zone))
            filters.add('WorkOrderID__r.Account.Zone__c = :zone');
        if (!String.isBlank(location))
            filters.add('WorkOrderID__r.Account.Location__c = :location');
        if (!String.isBlank(outlet))
            filters.add('WorkOrderID__r.AccountId = :outlet');
        if (!String.isBlank(approvalstatus )) {
            filters.add('WorkOrderID__r.Approval_Status__c = :approvalstatus');
        }
        if (!String.isBlank(fuelPoint)) {
            filters.add('WorkOrderID__r.Account.Fuel_Point__c = :fuelPoint');
        }
        if (!String.isBlank(typeOfFuelSold)) {
            filters.add('WorkOrderID__r.Account.Type_of_Fuel_Sold__c = :typeOfFuelSold');
        }
        if (!String.isBlank(salesOfficerName)) {                                        
            filters.add('WorkOrderID__r.Account.Sales_Officer_Name__c = :salesOfficerName');
        }
        if (!String.isBlank(omcOfficeName)) {                                          
            filters.add('WorkOrderID__r.Account.OMC_Office_Name__c = :omcOfficeName');
        }
        
        // Combine dynamic filters
        if (!filters.isEmpty()) {
            baseQuery += ' AND ' + String.join(filters, ' AND ');
        }
        
        // Add ORDER BY and LIMIT
        baseQuery += ' ORDER BY WorkOrderID__r.CreatedDate DESC,WorkOrderID__r.WorkOrderNumber DESC,Point_Number__c ASC' +
            ' LIMIT ' + limitRec;
        
        // Log and execute
        System.debug('Excel Data Query: ' + baseQuery);
        
        // Query execution
        List<Dispenser_Point__c> listDispenserPoints = Database.query(baseQuery);
        
        // Response
        Map<String, Object> result = new Map<String, Object>();
        result.put('query', baseQuery);
        result.put('records', listDispenserPoints);
        return result;
    }
    
    @AuraEnabled
public static String getContentVersionBase64(Id contentVersionId) {
    ContentVersion cv = [SELECT VersionData FROM ContentVersion WHERE Id = :contentVersionId LIMIT 1];
    return EncodingUtil.base64Encode(cv.VersionData);
}

    @AuraEnabled
    public static List<OptionsWrapper> getAccountOptions(String fieldApiName){
        try {
            String query = 'SELECT '+fieldApiName+' FROM Account WHERE '+fieldApiName+'!=null AND Category__c =\'CNG/LNG\' GROUP BY '+fieldApiName;
            List<AggregateResult> listResult = Database.query(query);
            
            List<OptionsWrapper> listOptions = new List<OptionsWrapper>();
            for(AggregateResult ar:listResult){
                OptionsWrapper categoryWrapper = new OptionsWrapper();
                categoryWrapper.label = (String)ar.get(fieldApiName);
                categoryWrapper.value = (String)ar.get(fieldApiName);
                listOptions.add(categoryWrapper);
            }
            
            return listOptions;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Map<String, Object> getCNGWorkOrderFilterRecords(
        DataWrapper metadataConfig,
    Date fromDate,
    Date toDate,
    String appointmentStatus,
    String agency,
    String agent,
    String omc,
    String zone,
    String location,
    String outlet,
    String limitRec,
    String approvalstatus,
    String fuelPoint,           
    String typeOfFuelSold,
    String salesOfficerName,      
    String omcOfficeName, 
    List<String> bpNumbers
    ) {
        try {
            // Record Type ID for Metering
            String meteringRecordTypeId = Schema.getGlobalDescribe()
                .get('WorkOrder').getDescribe()
                .getRecordTypeInfosByDeveloperName()
                .get('MGL_Metering').getRecordTypeId();
            
            Map<String, Object> result = new Map<String, Object>();
            
            if (metadataConfig == null) {
                return result;
            }
            
            // ✅ Step 1: Build SELECT clause dynamically from metadataConfig
            String query = 'SELECT Id, WorkOrderNumber, Approval_Status__c,Account.Name, Account.Location__c,Account.Zone__c, ' +
                'Account.Representative_Company__c, From_Date__c, To_Date__c,Check_Out_Date_formula__c,Account.BP_Number__c, ' +
                '(SELECT Id';
            
            Map<String, Object> fm = (Map<String, Object>) JSON.deserializeUntyped(metadataConfig.fields);
            for (String api : fm.keySet()) {
                if (isParentField(api)) {
                    List<String> pathParts = splitPath(api);
                    String parentField = pathParts[0];
                    if (!query.contains(parentField + '.')) {
                        query += ',' + parentField + '.Id';
                    }
                    for (Integer i = 1; i < pathParts.size(); i++) {
                        query += ',' + parentField + '.' + pathParts[i];
                    }
                } else {
                    query += ',' + api;
                }
            }
            query += ' FROM Dispenser_Points__r) FROM WorkOrder WHERE RecordTypeId = :meteringRecordTypeId ' +
                'AND Customer_Category__c = \'CNG/LNG\'';
            
            // Prepare deduplicated sets
            Set<String> uniqueBPs = (bpNumbers != null) ? new Set<String>(bpNumbers) : new Set<String>();
            
            // ✅ Step 2: Build filter conditions dynamically
            List<String> conditions = new List<String>();
            
            if (!uniqueBPs.isEmpty()) {
                conditions.add('Account.BP_Number__c IN :uniqueBPs');
            }
            
            if (fromDate != null) {
                conditions.add('Check_Out_Date_formula__c >= :fromDate');
            }
            if (toDate != null) {
                conditions.add('Check_Out_Date_formula__c <= :toDate');
            }
            if (!String.isBlank(appointmentStatus)) {
                conditions.add('Appointment_Status__c = :appointmentStatus');
            }
            if (!String.isBlank(agency)) {
                conditions.add('Metering_Agency__c = :agency');
            }
            if (!String.isBlank(agent)) {
                conditions.add('Assigned_Meter_Reader__c = :agent');
            }
            if (!String.isBlank(omc)) {
                conditions.add('Account.Representative_Company__c = :omc');
            }
            if (!String.isBlank(zone)) {
                conditions.add('Account.Zone__c = :zone');
            }
            if (!String.isBlank(location)) {
                conditions.add('Account.Location__c = :location');
            }
            if (!String.isBlank(outlet)) {
                conditions.add('AccountId = :outlet');
            }
            if (!String.isBlank(approvalstatus )) {
                conditions.add('Approval_Status__c = :approvalstatus');
            }
            if (!String.isBlank(fuelPoint)) {
                conditions.add('Account.Fuel_Point__c = :fuelPoint');
            }
            if (!String.isBlank(typeOfFuelSold)) {
                conditions.add('Account.Type_of_Fuel_Sold__c = :typeOfFuelSold');
            }
            if (!String.isBlank(salesOfficerName)) {          
                conditions.add('Account.Sales_Officer_Name__c = :salesOfficerName');
            }
            if (!String.isBlank(omcOfficeName)) {                     
                conditions.add('Account.OMC_Office_Name__c = :omcOfficeName');
            }
            
            // ✅ Step 3: Append conditions dynamically
            if (!conditions.isEmpty()) {
                query += ' AND ' + String.join(conditions, ' AND ');
            }
            
            // ✅ Step 4: Add sorting + limit
            query += ' ORDER BY CreatedDate DESC LIMIT ' + limitRec;
            
            System.debug('CNG Work Order Query => ' + query);
            
            // ✅ Step 5: Execute dynamic SOQL
            List<WorkOrder> listWorkOrders = Database.query(query);
            
            result.put('query', query);
            result.put('records', listWorkOrders);
            
            // ✅ Step 6: Collect related ContentDocumentLinks
            Set<Id> workOrderIds = new Set<Id>();
            for (WorkOrder wo : listWorkOrders) {
                workOrderIds.add(wo.Id);
            }
            
            if (!workOrderIds.isEmpty()) {
                List<ContentDocumentLink> cdlList = [
                SELECT ContentDocumentId, LinkedEntityId,
                       ContentDocument.Title, ContentDocument.FileType,
                       ContentDocument.LatestPublishedVersionId
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :workOrderIds
                ORDER BY ContentDocument.CreatedDate DESC
            ];
                result.put('contentDocMap', cdlList);
            }
            
            return result;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching CNG Work Orders: ' + e.getMessage());
        }
    }
    
    
    public class DataWrapper{
        @AuraEnabled public String listViewLabel{get; set;}
        @AuraEnabled public String listViewDeveloperName{get; set;}
        @AuraEnabled public String objectApiName{get; set;}
        @AuraEnabled public String recordTypeDevName{get; set;}
        @AuraEnabled public String imageFields{get; set;}
        @AuraEnabled public String htmlFields{get; set;}
        @AuraEnabled public String customerCategory{get; set;}
        @AuraEnabled public String filters{get; set;}
        @AuraEnabled public String fields{get; set;}
        @AuraEnabled public String excelFields{get; set;}
        @AuraEnabled public List<Map<String,Object>> columns;
    }
    
    public class OptionsWrapper{
        @AuraEnabled public String label{get;set;}
        @AuraEnabled public String value{get;set;}
    }
    
}