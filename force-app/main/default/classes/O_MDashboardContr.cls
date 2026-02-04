/**
* @File Name : O_MDashboardContr.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : May 19, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | May 19, 2025 |   | Initial Version
**/

public with sharing class O_MDashboardContr {
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Integer> getKPIs() {
        Id userId = UserInfo.getUserId();
        Id serviceResourceId = [SELECT Id FROM ServiceResource WHERE RelatedRecordId = :userId LIMIT 1].Id;
        
        Date today = Date.today();
        Date startDate = today;
        Date endDate = today.addDays(1);
        
        Map<String, Integer> kpis = new Map<String, Integer>{
            'total' => 0,
            'unattempted' => 0,
            'completed' => 0,
            'incomplete' => 0
        };
        
        //Get all ServiceAppointments assigned to the user
        Set<Id> serviceAppointmentIds = new Set<Id>();
        for (AssignedResource ar : [
            SELECT ServiceAppointmentId
            FROM AssignedResource
            WHERE ServiceResourceId = :serviceResourceId
        ]) {
            if (ar.ServiceAppointmentId != null) {
                serviceAppointmentIds.add(ar.ServiceAppointmentId);
            }
        }
        
        if (serviceAppointmentIds.isEmpty()) {
            return kpis;
        }
               String gsRecordTypeID = Schema.getGlobalDescribe().get('WorkOrder').getDescribe().getRecordTypeInfosByDeveloperName().get('MGL_O_M').getRecordTypeId();

        // String gsRecordTypeID = Schema.getGlobalDescribe().get('WorkOrder')
        //     .getDescribe().getRecordTypeInfosByDeveloperName().get('MGL_O_M').getRecordTypeId();
        //Get today's scheduled ServiceAppointments
        List<ServiceAppointment> appointments = [
            SELECT Id, Status, SchedStartTime, SchedEndTime
            FROM ServiceAppointment
            WHERE Id IN :serviceAppointmentIds AND ParentRecord.RecordTypeId = :gsRecordTypeID
            //AND SchedStartTime >= :startDate AND SchedStartTime < :endDate
        ];
        
        //Classify based on Status
        for (ServiceAppointment sa : appointments) {
            kpis.put('total', kpis.get('total') + 1);
            system.debug('Service appointment status ::'+ sa.Status);
            if (sa.Status == 'Completed') {
                kpis.put('completed', kpis.get('completed') + 1);
            } else if (sa.Status == 'Cannot Complete' || sa.Status == 'In Progress') {
                kpis.put('incomplete', kpis.get('incomplete') + 1);
            } else if (sa.Status == 'Scheduled' || sa.Status == 'None'  || sa.Status == 'Dispatched') {
                kpis.put('unattempted', kpis.get('unattempted') + 1);
            }
        }
        
        return kpis;
    }
    
    @AuraEnabled(cacheable=false)
    public static List<DataWrapper> getCountByMetadataMatch() {
        Id serviceResourceId = [SELECT Id FROM ServiceResource WHERE RelatedRecordId = :UserInfo.getUserId() LIMIT 1].Id;
        //Get all ServiceAppointments assigned to the user
        Set<Id> serviceAppointmentIds = new Set<Id>();
        for (AssignedResource ar : [
            SELECT ServiceAppointmentId
            FROM AssignedResource
            WHERE ServiceResourceId = :serviceResourceId
        ]) {
            if (ar.ServiceAppointmentId != null) {
                serviceAppointmentIds.add(ar.ServiceAppointmentId);
            }
        }
        
        List<DataWrapper> results = new List<DataWrapper>();
        
        // Load and organize metadata
        List<Metering_Dashboard_Config__mdt> metaList = [
            SELECT Label__c, Field_API_Name__c, Values__c, Order__c,Card_Color__c,Icon_URL__c,Department__c
            FROM Metering_Dashboard_Config__mdt
            WHERE Active__c = true and Department__c='O&M'
            ORDER BY Order__c ASC
        ];
        
        // Map<FieldName, Map<ExpectedValue, Label>>
        Map<String, Map<String, String>> fieldValueToLabelMap = new Map<String, Map<String, String>>();
        Map<String, Integer> labelToCount = new Map<String, Integer>();
        Map<String, List<ServiceAppointment>> mapLabelListSA = new Map<String, List<ServiceAppointment>>();
        
        for (Metering_Dashboard_Config__mdt meta : metaList) {
            String fieldName = meta.Field_API_Name__c;
            String label = meta.Label__c;
            List<String> values = meta.Values__c != null ? new List<String>(meta.Values__c.split(',')) : new List<String>();
            
            if (!fieldValueToLabelMap.containsKey(fieldName)) {
                fieldValueToLabelMap.put(fieldName, new Map<String, String>());
            }
            
            for (String val : values) {
                fieldValueToLabelMap.get(fieldName).put(val.trim().toLowerCase(), label);
            }
            
            labelToCount.put(label, 0);
            mapLabelListSA.put(label, new List<ServiceAppointment>());
        }
        
        String gsRecordTypeID = Schema.getGlobalDescribe().get('WorkOrder')
            .getDescribe().getRecordTypeInfosByDeveloperName().get('MGL_O_M').getRecordTypeId();
        // Collect all relevant fields to query
        Set<String> allFields = new Set<String>(fieldValueToLabelMap.keySet());
        String soql = 'SELECT Id';
        for (String f : allFields) {
            soql += ', ' + f;
        }
        soql += ' FROM ServiceAppointment WHERE Id IN :serviceAppointmentIds AND ParentRecord.RecordTypeId = :gsRecordTypeID ';
        
        // Query appointments dynamically
        List<ServiceAppointment> appointments = Database.query(soql);
        results=getStatusByCount(appointments,metaList);
        return results;
    }
    
    public static List<DataWrapper> getStatusByCount(List<ServiceAppointment> listServiceAppointments,List<Metering_Dashboard_Config__mdt> metaList){
        // Load and organize metadata
        
        // Map<FieldName, Map<ExpectedValue, Label>>
        Map<String, Map<String, String>> fieldValueToLabelMap = new Map<String, Map<String, String>>();
        Map<String, Integer> labelToCount = new Map<String, Integer>();
        Map<String, List<ServiceAppointment>> mapLabelListSA = new Map<String, List<ServiceAppointment>>();
        
        for (Metering_Dashboard_Config__mdt meta : metaList) {
            String fieldName = meta.Field_API_Name__c;
            String label = meta.Label__c;
            List<String> values = meta.Values__c != null ? new List<String>(meta.Values__c.split(',')) : new List<String>();
            
            if (!fieldValueToLabelMap.containsKey(fieldName)) {
                fieldValueToLabelMap.put(fieldName, new Map<String, String>());
            }
            
            for (String val : values) {
                fieldValueToLabelMap.get(fieldName).put(val.trim().toLowerCase(), label);
            }
            
            labelToCount.put(label, 0);
            mapLabelListSA.put(label, new List<ServiceAppointment>());
        }
        List<DataWrapper> results = new List<DataWrapper>();
        // Collect all relevant fields to query
        Set<String> allFields = new Set<String>(fieldValueToLabelMap.keySet());
        // Count matches
        for (ServiceAppointment sa : listServiceAppointments) {
            for (String fieldName : allFields) {
                if (!sa.getSObjectType().getDescribe().fields.getMap().containsKey(fieldName)) continue;
                
                Object value = sa.get(fieldName);
                if (value == null) continue;
                
                String valueStr = String.valueOf(value).trim().toLowerCase();
                if (fieldValueToLabelMap.get(fieldName).containsKey(valueStr)) {
                    String label = fieldValueToLabelMap.get(fieldName).get(valueStr);
                    labelToCount.put(label, labelToCount.get(label) + 1);
                    mapLabelListSA.get(label).add(sa);
                }
                
            }
        }
        
        // Convert to wrapper
        for (Metering_Dashboard_Config__mdt meta : metaList) {
            results.add(
                new DataWrapper(
                meta.Label__c,
            labelToCount.get(meta.Label__c),
            mapLabelListSA.get(meta.Label__c),
            meta.Card_Color__c,
            meta.Icon_URL__c
                )
                );
        }
        
        return results;
    }
    
    public class DataWrapper {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String cardColor { get; set; }
        @AuraEnabled public String iconUrl { get; set; }
        @AuraEnabled public Decimal count { get; set; }
        @AuraEnabled public List<ServiceAppointment> listServiceAppointments{get;set;}
        
        public DataWrapper(String label, Decimal count, List<ServiceAppointment> listServiceAppointments,
        String cardColor,String iconUrl) {
            this.label = label;
            this.count = count;
            this.iconUrl= iconUrl;
            this.cardColor= cardColor;
            this.listServiceAppointments = listServiceAppointments;
        }
    }
}