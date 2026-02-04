/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 22-01-2026
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   08-07-2025   Kartik Patkar, Appstrail   Initial Version
**/
public without sharing class WorkOrderCreationController {
    
    @AuraEnabled(cacheable=true)
    public static Map<String,Object> getComponentData(){
        try {
            List<ServiceTerritoryMember> serviceTerritoryMembers = [SELECT Id, ServiceResourceId, ServiceTerritory.Business_Partner_Category__c,
                                                                        ServiceResource.Customer_Category__c,
                                                                        ServiceResource.Name, ServiceTerritory.Name, ServiceTerritory.Id,
                                                                        ServiceResource.IsActive, ServiceTerritory.IsActive 
                                                                    FROM ServiceTerritoryMember
                                                                    WHERE ServiceResource.IsActive=true 
                                                                        AND ServiceTerritory.IsActive=true
                                                                        AND ServiceResource.RelatedRecordId=:UserInfo.getUserId()
                                                                    LIMIT 1];
                                                                        
            List<AccountWrapper> accountWrapperList = new List<AccountWrapper>();
            Map<String,Object> result=new Map<String,Object>();
            Set<String> setLocations = new Set<String>();
            Set<String> setZones = new Set<String>();
            Set<String> setRepresentativeCompanies = new Set<String>();

            if(!serviceTerritoryMembers.isEmpty()){

                String gsRecordTypeID = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId();
                AgentWrapper agentRec=new AgentWrapper(serviceTerritoryMembers[0]);
                result.put('agentDetails', agentRec);
                String customerCategory = serviceTerritoryMembers[0].ServiceResource.Customer_Category__c;
                List<Account> accountList = [SELECT Id, Name, BP_Number__c, AMR_Name__c,AMR_Device_No__c,Location__c,
                                                Zone__c,Representative_Company__c,Meter_Number__c
                                            FROM Account WHERE Category__c=:customerCategory ORDER BY Name ASC];
                                                //AND RecordTypeId=:gsRecordTypeID

                List<OptionsWrapper> locationsList = new List<OptionsWrapper>();
                locationsList.add(new OptionsWrapper('--None--', ''));
                List<OptionsWrapper> zonesList = new List<OptionsWrapper>();
                zonesList.add(new OptionsWrapper('--None--', ''));
                List<OptionsWrapper> representativeCompaniesList = new List<OptionsWrapper>();
                representativeCompaniesList.add(new OptionsWrapper('--None--', ''));
                for(Account acc : accountList){
                    if(acc.Location__c != null && !setLocations.contains(acc.Location__c)) {
                        setLocations.add(acc.Location__c);
                        locationsList.add(new OptionsWrapper(acc.Location__c, acc.Location__c));
                    }
                    if(acc.Zone__c != null && !setZones.contains(acc.Zone__c)) {
                        setZones.add(acc.Zone__c);
                        zonesList.add(new OptionsWrapper(acc.Zone__c, acc.Zone__c));
                    }
                    if(acc.Representative_Company__c != null && !setRepresentativeCompanies.contains(acc.Representative_Company__c)) {
                        setRepresentativeCompanies.add(acc.Representative_Company__c);
                        representativeCompaniesList.add(new OptionsWrapper(acc.Representative_Company__c, acc.Representative_Company__c));
                    }
                    accountWrapperList.add(new AccountWrapper(acc));
                }

                result.put('accountList', accountWrapperList);
                result.put('locationsList', locationsList);
                result.put('zonesList', zonesList);
                result.put('representativeCompaniesList', representativeCompaniesList);
            }
            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string createWorkOrder(AccountWrapper selectedAccount, AgentWrapper agentDetails) {
        try {
            if(selectedAccount == null || String.isBlank(selectedAccount.accountId)) {
                throw new AuraHandledException('No account selected for work order creation.');
            }

            List<AssignedResource> assignedResourceList = [SELECT Id, ServiceAppointmentId,ServiceAppointment.AccountId
                                                            FROM AssignedResource
                                                            WHERE ServiceResourceId=:agentDetails.agentId
                                                                AND ServiceAppointmentId!=null
                                                                AND ServiceAppointment.AccountId=:selectedAccount.accountId
                                                                AND ServiceAppointment.Schedule_Start_Date__c=:System.today()
                                                                AND ServiceAppointment.Schedule_End_Date__c=:System.today()
                                                            LIMIT 1];

            if(!assignedResourceList.isEmpty()) {
                return 'appointment created';
            }

            String meteringRecordTypeId = Schema.getGlobalDescribe().get('WorkOrder').getDescribe().getRecordTypeInfosByDeveloperName()
                                            .get('MGL_Metering').getRecordTypeId();
            // Create a new Work Order
            WorkOrder newWorkOrder = new WorkOrder();
            newWorkOrder.RecordTypeId = meteringRecordTypeId;
            // newWorkOrder.Name = selectedAccount.accountName;
            newWorkOrder.AccountId = selectedAccount.accountId;
            newWorkOrder.Subject = 'Metering for ' + selectedAccount.accountName;
            newWorkOrder.Status = 'New';
            newWorkOrder.Assigned_Meter_Reader__c = agentDetails.agentId;
            newWorkOrder.Metering_Agency__c = agentDetails.agencyId;
            newWorkOrder.Scheduled_Date__c = System.today();
            newWorkOrder.StartDate=System.today();
            newWorkOrder.EndDate=System.today();
            newWorkOrder.Work_Order_Type__c = 'Standard';
            insert newWorkOrder;

            List<ServiceAppointment> serviceAppointments = [SELECT Id,ParentRecordId,SchedStartTime FROM ServiceAppointment 
                                                            WHERE ParentRecordId = :newWorkOrder.Id LIMIT 1];
            if(!serviceAppointments.isEmpty()){
                System.debug('serviceAppointments::'+serviceAppointments);
                AssignedResource newAssignedResource = new AssignedResource();
                newAssignedResource.ServiceAppointmentId = serviceAppointments[0].Id;
                newAssignedResource.ServiceResourceId = agentDetails.agentId;
                insert newAssignedResource;
                return newWorkOrder.Id;
            }
            else {
                throw new AuraHandledException('No Service Appointment found for the created Work Order.');
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String,Object> getUserDetails(){
        try {
            List<ServiceTerritoryMember> serviceTerritoryMembers = [SELECT Id, ServiceResourceId, ServiceTerritory.Business_Partner_Category__c,
                                                                        ServiceResource.Name, ServiceTerritory.Name, ServiceTerritory.Id,
                                                                        ServiceResource.IsActive, ServiceTerritory.IsActive ,ServiceResource.Customer_Category__c
                                                                    FROM ServiceTerritoryMember
                                                                    WHERE ServiceResource.IsActive=true 
                                                                        AND ServiceTerritory.IsActive=true
                                                                        AND ServiceResource.RelatedRecordId=:UserInfo.getUserId()
                                                                    LIMIT 1];
                                                                        
            List<AccountWrapper> accountWrapperList = new List<AccountWrapper>();
            Map<String,Object> result=new Map<String,Object>();

            if(!serviceTerritoryMembers.isEmpty()){
                AgentWrapper agentRec=new AgentWrapper(serviceTerritoryMembers[0]);
                result.put('agentDetails', agentRec);
                String customerCategory = serviceTerritoryMembers[0].ServiceResource.Customer_Category__c;
                
                Set<Id> serviceAppointmentIds = new Set<Id>();
                for (AssignedResource ar : [
                    SELECT ServiceAppointmentId
                    FROM AssignedResource
                    WHERE ServiceResourceId = :agentRec.agentId
                ]) {
                    if (ar.ServiceAppointmentId != null) {
                        serviceAppointmentIds.add(ar.ServiceAppointmentId);
                    }
                }
                
                // String gsRecordTypeID = Schema.getGlobalDescribe().get('WorkOrder')
                //     .getDescribe().getRecordTypeInfosByDeveloperName().get('MGL_Metering').getRecordTypeId();
                //Get today's scheduled ServiceAppointments
                DateTime nowTime = System.now();
                Date today = Date.today();
                // List<ServiceAppointment> appointments = [
                //     SELECT Id, Status, SchedStartTime, SchedEndTime
                //     FROM ServiceAppointment
                //     WHERE Id IN :serviceAppointmentIds AND ParentRecord.RecordTypeId = :gsRecordTypeID
                //         AND SchedStartTime != NULL AND SchedEndTime != NULL
                //         AND Schedule_Start_Date__c <= :today AND Schedule_End_Date__c >= :today
                //         ORDER BY SchedEndTime DESC LIMIT 1
                // ];

                List<Meter_Reading_Schedule__c> listMRSs=[SELECT Id,Meter_Reading_Start_Date__c,Meter_Reading_Completion_Date__c FROM Meter_Reading_Schedule__c
                                                            WHERE Meter_Reading_Start_Date__c <=: today
                                                                AND Meter_Reading_Completion_Date__c >=:today
                                                                AND Agent__c=:agentRec.agentId 
                                                                ORDER BY Meter_Reading_Completion_Date__c DESC LIMIT 1];

                DataWrapper data=new DataWrapper();
                data.showAlert = false;
                if(!listMRSs.isEmpty()){
                    
                    data.lastDate=DateTime.newInstance(listMRSs[0].Meter_Reading_Completion_Date__c, Time.newInstance(19, 30, 0, 0));
                    // if(data.lastDate.date()==System.today()){
                        data.showAlert = true;
                    // }
                }
                result.put('data', data);
            }
            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class AccountWrapper{
        @AuraEnabled public String accountId{get;set;}
        @AuraEnabled public String accountName{get;set;}
        @AuraEnabled public String BP_Number{get;set;}
        @AuraEnabled public String AMR_Name{get;set;}
        @AuraEnabled public String AMR_Device_No{get;set;}
        @AuraEnabled public String Location{get;set;}
        @AuraEnabled public String Zone{get;set;}
        @AuraEnabled public String Representative_Company{get;set;}
        @AuraEnabled public String Meter_Number{get;set;}

        public AccountWrapper(){
            this.accountId = '';
            this.accountName = '';
            this.BP_Number = '';
            this.AMR_Name = '';
            this.AMR_Device_No = '';
            this.Location = '';
            this.Zone = '';
            this.Representative_Company = '';
            this.Meter_Number = '';
        }

        public AccountWrapper(Account acc){
            this.accountId = acc.Id;
            this.accountName = acc.Name;
            this.BP_Number = acc.BP_Number__c;
            this.AMR_Name = acc.AMR_Name__c;
            this.AMR_Device_No = acc.AMR_Device_No__c;
            this.Location = acc.Location__c;
            this.Zone = acc.Zone__c;
            this.Representative_Company = acc.Representative_Company__c;
            this.Meter_Number = acc.Meter_Number__c;
        }
    }

    public class AgentWrapper{
        @AuraEnabled public String agentId{get;set;}
        @AuraEnabled public String agentName{get;set;}
        @AuraEnabled public String agencyName{get;set;}
        @AuraEnabled public String agencyId{get;set;}
        @AuraEnabled public String customerCategory{get;set;}

        public AgentWrapper(){
            this.agentId = '';
            this.agentName = '';
            this.agencyName = '';
            this.agencyId = '';
            this.customerCategory = '';
        }

        public AgentWrapper(ServiceTerritoryMember stm){
            this.agentId = stm.ServiceResourceId;
            this.agentName = stm.ServiceResource.Name;
            this.agencyName = stm.ServiceTerritory.Name;
            this.agencyId = stm.ServiceTerritory.Id;
            this.customerCategory = stm.ServiceResource.Customer_Category__c;
        }
    }

    public class DataWrapper{
        @AuraEnabled public Datetime lastDate{get;set;}
        @AuraEnabled public Boolean showAlert{get;set;}
    }

    public class OptionsWrapper{
        @AuraEnabled public String label{get;set;}
        @AuraEnabled public String value{get;set;}

        public OptionsWrapper() {
            this.label = '';
            this.value = '';
        }

        public OptionsWrapper(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }
}