/**
 * @description       : 
 * @author            : Shashank.shekhar@appstrail.com
 * @group             : 
 * @last modified on  : 07-25-2025
 * @last modified by  : Shashank.shekhar@appstrail.com
**/
public without sharing class RTDashboardController {
    
    public static Map<Id, WorkOrder> mapWorkOrder = new Map<Id, WorkOrder>();

    @AuraEnabled(cacheable=true)
    public static Map<String, Integer> getKPIs() {

        Id userId = UserInfo.getUserId();
        Date todayDate = Date.today();
          
        //userId = '005fs0000000ALxAAM';
        //userId = '005fs00000099vJAAQ'; // testAgent1
        //userId = '005fs0000001mvSAAQ'; // Abhi
        
        Id serviceResourceId = [SELECT Id FROM ServiceResource WHERE RelatedRecordId = :userId LIMIT 1].Id;
        
        Map<String, Integer> kpis = new Map<String, Integer>{
            'total' => 0,
            'unattempted' => 0,
            'completed' => 0,
            'incomplete' => 0,
            'followup' => 0,
            'random' => 0,
            'direct' => 0
        }; 
        
        //Get all ServiceAppointments assigned to the user
        Set<Id> serviceAppointmentIds = new Set<Id>();

        for (AssignedResource ar : [SELECT ServiceAppointmentId
                                      FROM AssignedResource
                                     WHERE ServiceResourceId = :serviceResourceId]) {

            if (ar.ServiceAppointmentId != null) {
                serviceAppointmentIds.add(ar.ServiceAppointmentId);
            }
        } 
        
        if (serviceAppointmentIds.isEmpty()) {
            return kpis;
        }
        
        String gsRecordTypeID = Schema.getGlobalDescribe().get('WorkOrder').getDescribe().getRecordTypeInfosByDeveloperName().get('MGL_R_T').getRecordTypeId();

        mapWorkOrder = new Map<Id, WorkOrder>([SELECT Id, Payment_Mode__c, Status, Appointment_Status__c
                                                 FROM WorkOrder 
                                                WHERE Status = 'Completed' 
                                                  AND Payment_Mode__c = 'Directly Paid by Customer'
                                                  AND Id 
                                                   IN (SELECT ParentRecordId 
                                                         FROM ServiceAppointment 
                                                        WHERE Id IN :serviceAppointmentIds
                                                          AND ParentRecord.RecordTypeId =: gsRecordTypeID
                                                          AND Follow_Up_Visit_Date__c = null
                                                          AND DisplaySpecificRangeVisits__c = true)]);

        //Get today's scheduled ServiceAppointments
        List<ServiceAppointment> appointments = [SELECT Id, Status, SchedStartTime, SchedEndTime, Appointment_Type__c, ParentRecordId, Random_Visit_Date__c
                                                   FROM ServiceAppointment 
                                                  WHERE Id IN :serviceAppointmentIds 
                                                    AND ParentRecord.RecordTypeId = :gsRecordTypeID
                                                    AND Follow_Up_Visit_Date__c = null
                                                    AND DisplaySpecificRangeVisits__c = true];
 
        //Classify based on Status
        for (ServiceAppointment sa : appointments) {

            WorkOrder wo = mapWorkOrder.get(sa.ParentRecordId);

            if(wo != null && wo.Status == 'Completed' && wo.Payment_Mode__c == 'Directly Paid by Customer'){
                kpis.put('direct', kpis.get('direct') + 1);
            }else{
                if(sa.Random_Visit_Date__c == null){
                    kpis.put('total', kpis.get('total') + 1);

                    if (sa.Appointment_Type__c == 'Follow Up') { 
                        kpis.put('followup', kpis.get('followup') + 1);
                    }
                    
                    if (sa.Status == 'Completed') {
                        kpis.put('completed', kpis.get('completed') + 1);
                    } else if (sa.Status == 'Cannot Complete') {
                        kpis.put('incomplete', kpis.get('incomplete') + 1);
                    } else if ((sa.Status == 'Scheduled' || sa.Status == 'None' || sa.Status == 'In Progress' || sa.Status == 'Dispatched')) {
                        kpis.put('unattempted', kpis.get('unattempted') + 1);
                    }
                }else{
                    kpis.put('random', kpis.get('random') + 1);
                }
            }
        }
        return kpis;
    }
    
    @AuraEnabled
    public static List<DataWrapper> getCountByMetadataMatch() {

        Id userId = UserInfo.getUserId();
        Date todayDate = Date.today();
        
        //userId = '005fs0000000ALxAAM';
        //userId = '005fs00000099vJAAQ'; // testAgent1
        //userId = '005fs0000001mvSAAQ'; // Abhi

        Id serviceResourceId = [SELECT Id FROM ServiceResource WHERE RelatedRecordId =:userId LIMIT 1].Id;

        //Get all ServiceAppointments assigned to the user
        Set<Id> serviceAppointmentIds = new Set<Id>();

        for (AssignedResource ar : [SELECT ServiceAppointmentId FROM AssignedResource WHERE ServiceResourceId = :serviceResourceId]) {
            if (ar.ServiceAppointmentId != null) {
                serviceAppointmentIds.add(ar.ServiceAppointmentId);
            }
        }
        
        List<DataWrapper> results = new List<DataWrapper>();
        
        // Load and organize metadata
        List<Metering_Dashboard_Config__mdt> metaList = [SELECT Label__c, Field_API_Name__c, Values__c, Order__c,Card_Color__c,Icon_URL__c
                                                           FROM Metering_Dashboard_Config__mdt
                                                          WHERE Active__c = true 
                                                            AND Department__c = 'R&T'
                                                       ORDER BY Order__c ASC];
        
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
        
        String gsRecordTypeID = Schema.getGlobalDescribe().get('WorkOrder').getDescribe().getRecordTypeInfosByDeveloperName().get('MGL_R_T').getRecordTypeId();

        mapWorkOrder = new Map<Id, WorkOrder>([SELECT Id, Payment_Mode__c, Status, Appointment_Status__c
                                                 FROM WorkOrder 
                                                WHERE Status = 'Completed' 
                                                  AND Payment_Mode__c = 'Directly Paid by Customer'
                                                  AND Id 
                                                   IN (SELECT ParentRecordId 
                                                         FROM ServiceAppointment 
                                                        WHERE Id IN :serviceAppointmentIds
                                                          AND ParentRecord.RecordTypeId =: gsRecordTypeID
                                                          AND Follow_Up_Visit_Date__c = null
                                                          AND DisplaySpecificRangeVisits__c = true)]);

        // Collect all relevant fields to query
        Set<String> allFields = new Set<String>(fieldValueToLabelMap.keySet()); //{Status => {{Completed=>Completed}, {Cannot Complete=>Incompleted}, {None=>Un-attempted, In Progress=>Un-attempted}}}

        String soql = 'SELECT Id';

        for (String f : allFields) {
            soql += ', ' + f;
        }

        Set<Id> setId = mapWorkOrder.keySet();

        soql += ' FROM ServiceAppointment WHERE Id IN :serviceAppointmentIds'+
                 ' AND ParentRecord.RecordTypeId = :gsRecordTypeID AND Appointment_Type__c NOT IN (\'Follow Up\', \'Random\') AND Follow_Up_Visit_Date__c = null'+
                 ' AND DisplaySpecificRangeVisits__c = true AND Random_Visit_Date__c = null'+
                 ' AND ParentRecordId NOT IN :setId';
        //AND Appointment_Type__c = \'Scheduled\'';
        
        // Query appointments dynamically 
        List<ServiceAppointment> appointments = Database.query(soql);
        results = getStatusByCount(appointments,metaList);
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

                //{Status => {{Completed=>Completed}, {Cannot Complete=>Incompleted}, {None=>Un-attempted, In Progress=>Un-attempted}}}

                if (fieldValueToLabelMap.get(fieldName).containsKey(valueStr)) {

                    String label = fieldValueToLabelMap.get(fieldName).get(valueStr);

                    labelToCount.put(label, labelToCount.get(label) + 1);//{{Completed=>2}, {In Complete=>3}}

                    mapLabelListSA.get(label).add(sa); //{{Completed=>SA1,SA2}, {In Complete=>SA3,SA4,SA5}}
                }
                
            }
            
        }
        
        // Convert to wrapper
        for (Metering_Dashboard_Config__mdt meta : metaList) {

            results.add(new DataWrapper(
                meta.Label__c,
                labelToCount.get(meta.Label__c),
                mapLabelListSA.get(meta.Label__c),
                meta.Card_Color__c,
                meta.Icon_URL__c
            ));
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

    @AuraEnabled
    public static PaymentSummary getPaymentSummary() { 

        Id userId = UserInfo.getUserId();

        //userId = '005fs00000099vJAAQ'; // testAgent1
        //userId = '005fs0000001mvSAAQ'; // Abhi

        Date today = Date.today();

        // Get ServiceResource
        ServiceResource sr = [SELECT Id FROM ServiceResource WHERE RelatedRecordId = :userId LIMIT 1];

        List<ServiceAppointment> validAppointments = [SELECT Id, ParentRecordId
                                                        FROM ServiceAppointment
                                                       WHERE Id IN (SELECT ServiceAppointmentId
                                                                      FROM AssignedResource
                                                                     WHERE ServiceResourceId = :sr.Id)
                                                         AND ParentRecordId != null
                                                         AND DisplaySpecificRangeVisits__c = true
                                                         AND Follow_Up_Visit_Date__c = null];

        Set<Id> workOrderIds = new Set<Id>();

        for (ServiceAppointment sa : validAppointments) {
            workOrderIds.add(sa.ParentRecordId);
        }

        if (workOrderIds.isEmpty()) {
            return new PaymentSummary(0, 0);
        }

        // Aggregate WorkOrder data
        AggregateResult result = [SELECT SUM(Due_Amount__c) totalDue, SUM(Amount_Received__c) totalReceived
                                    FROM WorkOrder
                                   WHERE Id IN :workOrderIds
                                     AND Payment_Mode__c != 'Directly Paid by Customer'];

        Decimal totalDue = (Decimal)(result.get('totalDue') != null ? result.get('totalDue') : 0);
        Decimal totalReceived = (Decimal)(result.get('totalReceived') != null ? result.get('totalReceived') : 0);
 
        return new PaymentSummary(totalDue, totalReceived);
    }

    public class PaymentSummary {
        @AuraEnabled public Decimal paymentToCollect { get; set; }
        @AuraEnabled public Decimal totalAmountReceived { get; set; }

        public PaymentSummary(Decimal paymentToCollect, Decimal totalAmountReceived) {
            this.paymentToCollect = paymentToCollect;
            this.totalAmountReceived = totalAmountReceived;
        }
    }
}