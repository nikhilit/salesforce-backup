/**
 * @description       : Ad-Hoc Appointment Controller
 * @author            : Shashank.shekhar@appstrail.com
 * @last modified on  : 13-08-2025
 * @last modified by  : Kartik Patkar, Appstrail
 **/
public without sharing class AdHocAppointmentController {
    
    public class PicklistWrapper {
        @AuraEnabled public List<String> identificationTypes;
        @AuraEnabled public List<String> appointmentTypes;
        
        public PicklistWrapper() {
            identificationTypes = new List<String>();
            appointmentTypes = new List<String>();
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static PicklistWrapper getPicklistValues() {
        System.debug('Fetching picklist values for identification and appointment types.');
        PicklistWrapper wrapper = new PicklistWrapper();
        
        Schema.DescribeFieldResult idTypeFieldResult = WorkOrder.Customer_Identification_Type__c.getDescribe();
        for (Schema.PicklistEntry entry : idTypeFieldResult.getPicklistValues()) {
            wrapper.identificationTypes.add(entry.getLabel());
        }
        
        Schema.DescribeFieldResult apptTypeFieldResult = ServiceAppointment.Appointment_Type__c.getDescribe();
        for (Schema.PicklistEntry entry : apptTypeFieldResult.getPicklistValues()) {
            wrapper.appointmentTypes.add(entry.getLabel());
        }
        
        System.debug('Identification Types: ' + wrapper.identificationTypes);
        System.debug('Appointment Types: ' + wrapper.appointmentTypes);
        return wrapper;
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String,Object> getValidAccounts(String searchKey) {
        List<ServiceTerritoryMember> serviceTerritoryMembers = [SELECT Id, ServiceResourceId, ServiceTerritory.Business_Partner_Category__c,
                                                        ServiceResource.Name, ServiceTerritory.Name, ServiceTerritory.Id,
                                                        ServiceResource.IsActive, ServiceTerritory.IsActive,
                                                        ServiceResource.Customer_Category__c 
                                                    FROM ServiceTerritoryMember
                                                    WHERE ServiceResource.IsActive=true 
                                                        AND ServiceTerritory.IsActive=true
                                                        AND ServiceResource.RelatedRecordId=:UserInfo.getUserId()
                                                    LIMIT 1];
                                                    
        
        if(serviceTerritoryMembers.isEmpty()){
            return null;
        }

        String query='SELECT Id, LastName__c FROM Account WHERE (LastName__c LIKE \'%' + searchKey + '%\' OR Name LIKE \'%' + searchKey + '%\') ';
        String category = serviceTerritoryMembers[0].ServiceResource.Customer_Category__c;
        if(category != null){
            query += 'AND Category__c =: category ';
        }

        Map<String,Object> result=new Map<String,Object>();
        result.put('accounts', Database.query(query));
        result.put('category', category);
        System.debug('Searching accounts with LastName__c like: ' + result);
        return result;
    }
    
    @AuraEnabled(cacheable=true)
    public static Account getAccountByIdentification(String idType, String idValue) {
        System.debug('Getting Account by identificationType: ' + idType + ', idValue: ' + idValue);
        
        if (String.isBlank(idType) || String.isBlank(idValue)) {
            throw new AuraHandledException('Identification Type and Value are required.');
        }
        
        String fieldAPI;
        switch on idType {
            when 'BP Number' {
                fieldAPI = 'BP_Number__c';
            }
            when 'Application Form Number' {
                fieldAPI = 'Application_Number__c';
            }
            when 'Meter Number' {
                fieldAPI = 'Meter_Number__c';
            }
            when 'CA Number' {
                fieldAPI = 'CA_Number__c';
            }
            when 'Mobile Number'{
                fieldAPI='Phone__c';
            }
            when else {
                throw new AuraHandledException('Unsupported Identification Type.');
            }
        }
        
        String query = 'SELECT Id, LastName__c,Phone__c, Phone, (SELECT Id, Name FROM Contacts LIMIT 1) FROM Account WHERE ' + fieldAPI + ' = :idValue LIMIT 1';
        System.debug('Executing dynamic SOQL: ' + query);
        List<Account> accounts = Database.query(query);
        
        System.debug('Accounts found: ' + accounts);
        
        if (!accounts.isEmpty()) {
            return accounts[0];
        }
        
        return null;
    }
    
    @AuraEnabled
    public static String createAdHocAppointment(String identificationType, String identificationValue,String accountId) {
        System.debug('Creating Ad-Hoc Appointment. Type: ' + identificationType + ', Value: ' + identificationValue);
        
        try {
            if (String.isBlank(accountId) || String.isBlank(accountId)) {
                throw new AuraHandledException('Missing required input fields.');
            }
            
            // String accountField;
            // switch on identificationType {
            //     when 'BP Number' {
            //         accountField = 'BP_Number__c';
            //     }
            //     when 'Application Form Number' {
            //         accountField = 'Application_Number__c';
            //     }
            //     when 'Meter Number' {
            //         accountField = 'Meter_Number__c';
            //     }
            //     when 'CA Number' {
            //         accountField = 'CA_Number__c';
            //     }
            //     when else {
            //         throw new AuraHandledException('Unsupported Identification Type selected.');
            //     }
            // }
            
            String query = 'SELECT Id, LastName__c, Phone, Category__c, (SELECT Id FROM Contacts LIMIT 1) FROM Account WHERE Id=:accountId LIMIT 1';
            
            System.debug('Dynamic SOQL for Account: ' + query);
            List<Account> accounts = Database.query(query);
            
            if (accounts.isEmpty()) {
                throw new AuraHandledException('No matching Account found.');
            }
            
            Account acc = accounts[0];
            //Contact contact = acc.Contacts.isEmpty() ? null : acc.Contacts[0];
            
            System.debug('Found Account: ' + acc);
            
            
            List<ServiceResource> srList = [
                SELECT Id, (SELECT Id,ServiceTerritoryId FROM ServiceTerritories LIMIT 1)
                FROM ServiceResource 
                WHERE RelatedRecordId = :UserInfo.getUserId()
                LIMIT 1
            ];
            
            // List<ServiceAppointmentMember> sAMemberList = [
            //     SELECT Id,ServiceResourceId,ServiceTerritoryId
            //     FROM ServiceAppointmentMember
            //     WHERE RelatedRecordId = :UserInfo.getUserId()
            //     LIMIT 1
            // ];
            
            if (srList.isEmpty()) {
                throw new AuraHandledException('No Service Resource found for current user.');
            }
            
            System.debug('Found ServiceResource: ' + srList[0].Id);
            System.debug('Account Category__c: ' + acc.Category__c);
            String gsRecordTypeID = Schema.getGlobalDescribe().get('WorkOrder').getDescribe().getRecordTypeInfosByDeveloperName()
                .get('MGL_Metering').getRecordTypeId();
            
            WorkOrder wo = new WorkOrder(
                Subject = 'Ad-Hoc Meter Reading',
                Work_Order_Type__c = 'Ad-Hoc',
                Status = 'New',
                Customer_Identification_Type__c = identificationType,
                Customer_Identification_Value__c = identificationValue,
                AccountId = acc.Id,
                //ContactId = contact != null ? contact.Id : null,
                Phone__c = acc.Phone,
                StartDate = DateTime.now(),
                Scheduled_Date__c = DateTime.now(),
                EndDate = DateTime.now().addHours(10),
                RecordTypeId=gsRecordTypeID,
                Assigned_Meter_Reader__c=srList[0].Id,
                ServiceTerritoryId = srList[0].ServiceTerritories.isEmpty() ? null : srList[0].ServiceTerritories[0].ServiceTerritoryId
            );

                
            if(!acc.Contacts.isEmpty()){
                wo.ContactId = acc.Contacts[0].Id;
            }
            
            // Conditionally set ad_hoc_customer__c only if filter is satisfied
            // if (acc.Category__c == 'Domestic') {
            //     // wo.ad_hoc_customer__c = acc.Id;
            // } else {
            //     System.debug('Skipping ad_hoc_customer__c assignment due to category mismatch: ' + acc.Category__c);
            // }
            
            
            if (identificationType == 'BP Number') {
                wo.Customer_BP_Number__c = identificationValue;
            }
            
            insert wo;

            List<ServiceTerritoryMember> serviceTerritoryMembers = [SELECT Id, ServiceResourceId, ServiceTerritory.Business_Partner_Category__c,
                                                        ServiceResource.Name, ServiceTerritory.Name, ServiceTerritory.Id,
                                                        ServiceResource.IsActive, ServiceTerritory.IsActive,
                                                        ServiceResource.Customer_Category__c 
                                                    FROM ServiceTerritoryMember
                                                    WHERE ServiceResource.IsActive=true 
                                                        AND ServiceTerritory.IsActive=true
                                                        AND ServiceResource.RelatedRecordId=:UserInfo.getUserId()
                                                    LIMIT 1];
                                                    
        
            if(serviceTerritoryMembers.isEmpty()){
                return null;
            }

            List<ServiceAppointment> serviceAppointments = [SELECT Id,ParentRecordId,SchedStartTime FROM ServiceAppointment 
                                                            WHERE ParentRecordId = :wo.Id LIMIT 1];
            if(!serviceAppointments.isEmpty()){
                System.debug('serviceAppointments::'+serviceAppointments);
                AssignedResource newAssignedResource = new AssignedResource();
                newAssignedResource.ServiceAppointmentId = serviceAppointments[0].Id;
                newAssignedResource.ServiceResourceId = serviceTerritoryMembers[0].ServiceResourceId;
                insert newAssignedResource;
            }
            else {
                throw new AuraHandledException('No Service Appointment found for the created Work Order.');
            }
            System.debug('Created WorkOrder: ' + wo.Id);
            
            return wo.Id;
            
        } catch (Exception e) {
            System.debug('Error creating Ad-Hoc appointment: ' + e.getMessage());
            throw new AuraHandledException('Failed to create appointment: ' + e.getMessage());
        }
    }
}