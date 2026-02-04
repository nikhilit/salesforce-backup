/**
 * @description       :
 * @author            : Kartik Patkar Appstrail
 * @group             :
 * @last modified on  : 22-01-2026
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   08-05-2025   Kartik Patkar, Appstrail   Initial Version
 **/
public without sharing class WorkOrderTriggerHandler {
    /**
     * @description
     * @author Kartik Patkar, Appstrail | 15-05-2025
     * @param List<WorkOrder> newList
     **/
    public static void beforeInsert(List<WorkOrder> newList) {
        checkWorkTypeAssigned(newList);

        List<WorkOrder> filteredWorkOrders = new List<WorkOrder>();
        
        for(WorkOrder wo : newList){
            if(wo.Record_Type_Developer_Name__c == 'MGL_R_T' && wo.Customer_BP_Number__c != null && 
               wo.Agent_ID__c != null && wo.Agency_Name__c != null && //wo.Billing_portion__c != null &&
               wo.AccountId == null && wo.Agent__c == null && wo.R_T_Agency__c == null //&& wo.Portion__c == null
            ){
                filteredWorkOrders.add(wo);
            }
        }
        
        if(!filteredWorkOrders.isEmpty()){
			populateRelatedFields(filteredWorkOrders);
        }

        //Populate address fields from related BP for FieldSense WorkOrders
        List<WorkOrder> fieldSenseWorkOrders = new List<WorkOrder>();
        Set<String> fieldSenseWT = new Set<String>();

        for (String s : Label.AS_FieldSenseFlowLabel.split(',')) {
            if (!String.isBlank(s)) {
                fieldSenseWT.add(s.trim());
            }
        }

        Set<Id> workTypeIds = new Set<Id>();

        for (WorkOrder wo : newList) {
            if (wo.WorkTypeId != null) {
                workTypeIds.add(wo.WorkTypeId);
            }
        }

        Map<Id, WorkType> wtMap = new Map<Id, WorkType>([SELECT Id, Name FROM WorkType WHERE Id IN :workTypeIds]);

        for(WorkOrder wo: newList){
            if (wo.WorkTypeId == null) 
            continue;

            WorkType wt = wtMap.get(wo.WorkTypeId);

            if (fieldSenseWT.contains(wt.Name.toLowerCase())) {
                fieldSenseWorkOrders.add(wo);
            }
        }

        if(!fieldSenseWorkOrders.isEmpty()){
            populateAddress(fieldSenseWorkOrders);
            // phone, sencondary phone, email
            populateFields(fieldSenseWorkOrders);
        }
    }

    public static void populateFields(List<WorkOrder> workOrders) {
        Set<Id> accountIds = new Set<Id>();
        Map<Id, Account> updateAccounts = new Map<Id, Account>();

        for (WorkOrder wo : workOrders) {
            if (wo.AccountId != null) {
                accountIds.add(wo.AccountId);
            }
        }

        if (accountIds.isEmpty()) return;

        Map<Id, Account> acctMap = new Map<Id, Account>(
            [SELECT Id,
                    Phone__c,
                    Secondary_Phone__c,
                    Email_Id__c,
                    RT_Phone_1__c,
                    RT_Phone_2__c,
                    RT_Email__c
            FROM Account
            WHERE Id IN :accountIds]
        );

        for (WorkOrder wo : workOrders) {
            if (wo.AccountId == null || !acctMap.containsKey(wo.AccountId)) continue;

            Account acc = acctMap.get(wo.AccountId);
            Account updateAccount = updateAccounts.containsKey(acc.Id)
                ? updateAccounts.get(acc.Id)
                : new Account(Id = acc.Id);

            // RT_Phone_1__c
            String phone1 = buildCommaSeparated(acc.Phone__c, wo.New_Mobile_Number__c);
            if (phone1 != null) {
                updateAccount.RT_Phone_1__c = phone1;
            }

            // RT_Phone_2__c
            String phone2 = buildCommaSeparated(acc.Secondary_Phone__c, wo.Phone__c);
            if (phone2 != null) {
                updateAccount.RT_Phone_2__c = phone2;
            }

            // RT_Email__c
            String email = buildCommaSeparated(acc.Email_Id__c, wo.Email_ID__c);
            if (email != null) {
                updateAccount.RT_Email__c = email;
            }

            updateAccounts.put(updateAccount.Id, updateAccount);
        }

        if (!updateAccounts.isEmpty()) {
            update updateAccounts.values();
        }
    }

    private static String buildCommaSeparated(String val1, String val2) {
        List<String> values = new List<String>();

        if (val1 != null) values.add(val1);
        if (val2 != null) values.add(val2);

        return values.isEmpty() ? null : String.join(values, ', ');
    }


    //Populate address from related BP
    public static void populateAddress(List<WorkOrder> workOrders){

        Set<Id> accountIds = new Set<Id>();

        for(WorkOrder wo : workOrders){
            if(wo.AccountId != null){
                accountIds.add(wo.AccountId);
            }
        }

        if(accountIds.isEmpty()) return;

        Map<Id, Account> acctMap = new Map<Id, Account>([SELECT Id,
         Road_name__c,Landmark__c,Location__c,City__c,Postal_Code__c,Street_Line_5__c,Building_name__c,Flat__c,Floor__c,Wing__c,Plot__c,Colony__c,District__c
         FROM Account
         WHERE Id IN :accountIds]
        );

        for(WorkOrder wo : workOrders){
            if(wo.AccountId != null && acctMap.containsKey(wo.AccountId)){
                Account acc = acctMap.get(wo.AccountId);
                wo.New_Road_Name__c = acc.Street_Line_5__c;
                wo.New_Landmark__c = acc.Landmark__c;
                wo.New_Location__c = acc.Location__c;
                wo.City__c = acc.City__c;
                wo.Postal_Code__c = acc.Postal_Code__c;
                wo.Building_Name__c = acc.Building_name__c;
                wo.New_Flat__c= acc.Flat__c;
                wo.New_Floor__c = acc.Floor__c;
                wo.New_Wing__c = acc.Wing__c;
                wo.New_Plot__c = acc.Plot__c;
                wo.New_Colony__c = acc.Colony__c;
                wo.DISTRICT__c = acc.District__c;
            }
        }
    }
    
    /**
     * @description
     * @author Kartik Patkar, Appstrail | 15-05-2025
     * @param List<WorkOrder> newList
     **/
    private static void checkWorkTypeAssigned(List<WorkOrder> newList){
        List<WorkOrder> workOrdersToUpdate = new List<WorkOrder>();
        // Check if WorkType is assigned
        for (WorkOrder workOrderRec : newList) {
            if (workOrderRec.WorkTypeId == null) {
                workOrdersToUpdate.add(workOrderRec);
            }
        }
        
        if(!workOrdersToUpdate.isEmpty()){
            WorkTypeAssignmentHandler.assignWorkTypes(workOrdersToUpdate);
        }
    }
    
    /*public static void assignAddressesAndCreateAppointments(List<WorkOrder> workOrders) {
        // Different address street names for each batch of 20 work orders
        List<String> streetList = new List<String>{
            'BDA Complex Road, Sector 1', '24th Main Road, Sector 2', '17th B Cross Road, Sector 3',
            '17th Main Road, Sector 4', '8th Main Road, Sector 5', '27th A Main Road, Sector 6 & 7'
        };
        List<String> cityList = new List<String>{
            'HSR Layout, Bangalore', 'HSR Layout, Bangalore', 'HSR Layout, Bangalore',
            'HSR Layout, Bangalore', 'HSR Layout, Bangalore', 'HSR Layout, Bangalore'
        };
        
        for (Integer i = 0; i < workOrders.size(); i++) {
            Integer groupIndex = i / 20;
            if (groupIndex >= streetList.size()) groupIndex = streetList.size() - 1;
            
            WorkOrder wo = workOrders[i];
            wo.Street = streetList[groupIndex];
            wo.City = cityList[groupIndex];
            wo.State = 'Karnataka';
            wo.PostalCode = '560001';
            wo.Country = 'India';
        }
    }*/
    
    // Method to create ServiceAppointments after insert
    /*public static void createServiceAppointmentsAfterInsert(List<WorkOrder> workOrders) {
        List<ServiceAppointment> appointmentsToInsert = new List<ServiceAppointment>();
        List<AssignedResource> assignedResourcesToInsert = new List<AssignedResource>();
        
        // Fetch one available active field agent with 'Meter Reader' type
        List<ServiceTerritoryMember> stmList = [
            SELECT ServiceResourceId, ServiceTerritoryId
            FROM ServiceTerritoryMember
            WHERE ServiceResource.IsActive = true
            AND ServiceResource.Service_Resource_Type__c = 'Meter Reader'
            LIMIT 1
        ];
        
        if (stmList.isEmpty()) {
            System.debug('No available Meter Readers found.');
            return;
        }
        
        
        ServiceTerritoryMember assignedMember = stmList[0];
        System.debug('Selected Meter Reader: ' + assignedMember.ServiceResourceId);
        
        // Create ServiceAppointments
        for (WorkOrder wo : workOrders) {
            ServiceAppointment sa = new ServiceAppointment(
                ParentRecordId = wo.Id,
            Work_Order__c = wo.Id,
            Subject = 'Meter Reading - ' + wo.WorkOrderNumber,
            Duration = 60,
            Status = 'None',
            ServiceTerritoryId = assignedMember.ServiceTerritoryId,
            Assigned_Meter_Reader__c = assignedMember.ServiceResourceId,
            SchedStartTime = System.now().addHours(1),
            SchedEndTime = System.now().addDays(1)
                );
            appointmentsToInsert.add(sa);
        }
        
        if (!appointmentsToInsert.isEmpty()) {
            try {
                insert appointmentsToInsert;
                System.debug('Inserted ' + appointmentsToInsert.size() + ' Service Appointments successfully.');
                
                // Create AssignedResource records
                for (ServiceAppointment sa : appointmentsToInsert) {
                    AssignedResource ar = new AssignedResource(
                        ServiceAppointmentId = sa.Id,
                    ServiceResourceId = assignedMember.ServiceResourceId
                        // AssignmentStatus = 'Scheduled'
                    );
                    assignedResourcesToInsert.add(ar);
                }
                
                if (!assignedResourcesToInsert.isEmpty()) {
                    insert assignedResourcesToInsert;
                    System.debug('Inserted ' + assignedResourcesToInsert.size() + ' AssignedResource records.');
                }
                
            } catch (Exception e) {
                System.debug('Error: ' + e.getMessage());
            }
        } else {
            System.debug('No Service Appointments prepared for insert.');
        }
    }*/
    public static void createDispenserPoints(List<WorkOrder> workOrders) {
        Set<Id> accountIds = new Set<Id>();
        
        for (WorkOrder wo : workOrders) {
            if (wo.AccountId != null) {
                accountIds.add(wo.AccountId);
            }
        }
        system.debug('accountIds::'+accountIds);
        // Get all Account Dispensers for the related accounts
        Map<Id, List<Account_Dispensor__c>> accDispenserMap = new Map<Id, List<Account_Dispensor__c>>();
        for (Account_Dispensor__c ad : [
            SELECT Id, Name, Closing_Reading__c, Business_Partner__c ,Opening_Reading__c
            FROM Account_Dispensor__c 
            WHERE Business_Partner__c IN :accountIds
        ]) {
            system.debug('ad::'+ad);
            if (!accDispenserMap.containsKey(ad.Business_Partner__c)) {
                accDispenserMap.put(ad.Business_Partner__c, new List<Account_Dispensor__c>());
            }
            accDispenserMap.get(ad.Business_Partner__c).add(ad);
        }
        System.debug('accDispenserMap::'+accDispenserMap);
        // Create Dispenser_Point__c records
        List<Dispenser_Point__c> dpList = new List<Dispenser_Point__c>();
        
        for (WorkOrder wo : workOrders) {
            if (accDispenserMap.containsKey(wo.AccountId)) {
                for (Account_Dispensor__c ad : accDispenserMap.get(wo.AccountId)) {
                    Dispenser_Point__c dp = new Dispenser_Point__c();
                    dp.WorkOrderId__c = wo.Id;
                    dp.Account_Dispensor__c = ad.Id; // optional, for reference
                    dp.Dispenser_Name__c = ad.Name;
                    dp.Dispenser_Number__c= 'DIS-'+String.valueOf(100000 + (Integer)(Math.random() * 900000));
                    // dp.CNG_Meter_reading__c='a1mfs0000000GeHAAU';
                    dp.Opening_Reading__c = ad.Opening_Reading__c;
                    dp.Closing_Reading__c = ad.Closing_Reading__c;
                    dp.Dispenser_Number_Value__c = extractLastNumber(ad.Name);
                    dp.Live__c = true;
                    dpList.add(dp);
                }
            }
        }
        system.debug('dpList::'+dpList);
        if (!dpList.isEmpty()) {
            insert dpList;
        }
    }
    public static Integer extractLastNumber(String name) {
        if (String.isBlank(name)) return null;
        
        Pattern p = Pattern.compile('\\d+');
        Matcher m = p.matcher(name);
        
        Integer lastNumber = null;
        while (m.find()) {
            lastNumber = Integer.valueOf(m.group());
        }
        return lastNumber;
    }

    public static void attachPDFsAsync(List<Id> workOrderIds) {
        attachPDFsAsync(workOrderIds, null);
    }
    
    public static void attachPDFsAsync(List<Id> workOrderIds, String jobKey) {
        if(System.isBatch() || System.isFuture()){
            // attachPDFs(workOrderIds);
            System.enqueueJob(new WO_DeleteOldPDFs_Queueable(workOrderIds, jobKey));
        }else{
            // attachPDFsAsyncCall(workOrderIds);
            System.enqueueJob(new WO_DeleteOldPDFs_Queueable(workOrderIds, jobKey));
        }
    }

    //Update meter readings when work order Approval status changes to approved
    public static void updateMeterReadings(List<Id> workOrderIds){
        List<Dispenser_Point__c> dispenserPoints = [SELECT id,Account_Dispensor__c,Closing_Reading__c,WorkOrderID__c,CreatedDate,Account_Dispensor__r.Closing_Reading__c 
                                                    FROM Dispenser_Point__c 
                                                    WHERE Live__c = true 
                                                        AND WorkOrderID__c IN:workOrderIds 
                                                    ORDER BY WorkOrderID__c, CreatedDate DESC];

        Map<Id, Dispenser_Point__c> latestDpPerWO = new Map<Id, Dispenser_Point__c>();

        List<Account_Dispensor__c> accDispensersToUpdate = new List<Account_Dispensor__c>();
        Map<Id, Account_Dispensor__c> accDispMap = new Map<Id, Account_Dispensor__c>();
        for (Dispenser_Point__c dp : dispenserPoints) {
            // if (!latestDpPerWO.containsKey(dp.WorkOrderID__c)) {
            //     latestDpPerWO.put(dp.WorkOrderID__c, dp); 
            // }
            if(dp.Account_Dispensor__c!=null){     
                Account_Dispensor__c accDisp = new Account_Dispensor__c();
                accDisp.Id = dp.Account_Dispensor__c;
                accDisp.SCADA_Closing_Reading__c = dp.Account_Dispensor__r.Closing_Reading__c ?? 0;
                accDisp.Opening_Reading__c = dp.Closing_Reading__c;
                accDisp.Closing_Reading__c = dp.Closing_Reading__c;
                accDispensersToUpdate.add(accDisp);
                accDispMap.put(dp.Account_Dispensor__c, accDisp);
            }
        }

        // if (latestDpPerWO.isEmpty()) {
        //     return;
        // }

        // Map<Id, Dispenser_Point__c> latestDpPerAccount = new Map<Id, Dispenser_Point__c>();
        // for (Dispenser_Point__c dp : latestDpPerWO.values()) {
        //     latestDpPerAccount.put(dp.Account_Dispensor__c, dp);
        // }

        // List<Account_Dispensor__c> accDispensers = [SELECT Id, Closing_Reading__c FROM Account_Dispensor__c 
        //                                             WHERE Id IN :latestDpPerAccount.keySet()];

        // for (Account_Dispensor__c accDisp : accDispensers) {

        //     Dispenser_Point__c dp = latestDpPerAccount.get(accDisp.Id);

        //     accDisp.SCADA_Closing_Reading__c = accDisp.Closing_Reading__c ?? 0;
        //     accDisp.Opening_Reading__c = dp.Closing_Reading__c;
        //     accDisp.Closing_Reading__c = dp.Closing_Reading__c;
        // }

        if (!accDispensersToUpdate.isEmpty()) {
            // update accDispensersToUpdate;
            update accDispMap.values();
        }
       
    }

    // @future(callout=true)
    // public static void attachPDFsAsyncCall(List<Id> workOrderIds) {
    //     attachPDFs(workOrderIds);
    // }
    
    // public static void attachPDFs(List<Id> workOrderIds) {
    //     List<ContentVersion> contentVersions = new List<ContentVersion>();
    //     List<ContentDocumentLink> contentLinks = new List<ContentDocumentLink>();
    //     List<WorkOrder> woList=[SELECT Id,Account.BP_Number__c,From_Date__c,To_Date__c,Customer_Representative__c,BP_Number__c,Account.Name FROM WorkOrder WHERE Id=:workOrderIds];

    //     List<ContentDocumentLink> existingContentLinks = [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :workOrderIds AND (ContentDocument.Title LIKE 'Live_Update_%' OR ContentDocument.Title LIKE '%_JT_%')];

    //     Set<Id> setContentId=new Set<Id>();
    //     for(ContentDocumentLink cdl:existingContentLinks){
    //         setContentId.add(cdl.ContentDocumentId);
    //     }

    //     List<ContentDocument> contentDocuments = [SELECT Id, LatestPublishedVersionId FROM ContentDocument WHERE Id IN :setContentId];

    //     if(!contentDocuments.isEmpty()){
    //         delete contentDocuments;
    //     }

    //     for (WorkOrder wo : woList) {
    //         wo.Send_Email__c=true;
    //         // Generate PDF from VF Page 1
    //         PageReference page1 = Page.JointTicketPdf;
    //         page1.getParameters().put('id', wo.Id);
    //         Blob pdfBlob1;//Changed by Rishikesh for covering Test Class
    //         if (Test.isRunningTest()) {
    //             pdfBlob1 = Blob.valueOf('Test');
    //         } else {
    //             pdfBlob1 = page1.getContentAsPDF();
    //         }
            
    //         System.debug('wo.Account.BP_Number__c'+wo.Account.BP_Number__c);
    //         System.debug('wo.From_Date__c'+wo.From_Date__c);
    //         System.debug('wo.To_Date__c'+wo.To_Date__c);
    //         System.debug('pdfBlob1'+pdfBlob1);
    //         // OMC name_JT_RO ID_RO name_ FROM DATE_TO DATE.PDF
    //         String fileName = wo.Customer_Representative__c+'_JT_'+wo.BP_Number__c+'_'+wo.Account.Name
    //                             +'_'+wo.From_Date__c.format()+'_'+wo.To_Date__c.format()+'.pdf';

    //         ContentVersion cv1 = new ContentVersion(
    //             Title = fileName,
    //             // Title = 'Joint_Ticket_'+wo.Account.BP_Number__c+'_'+wo.From_Date__c.format()+'_'+wo.To_Date__c.format()+'.pdf',
    //         PathOnClient = 'JointTicket1.pdf',
    //         VersionData = pdfBlob1
    //             );
    //         contentVersions.add(cv1);
            
    //         // Generate PDF from VF Page 2
    //         PageReference page2 = Page.JointTicketPdf2;
    //         page2.getParameters().put('id', wo.Id);
            
    //         Blob pdfBlob2;
    //         if (Test.isRunningTest()) {
    //             pdfBlob2 = Blob.valueOf('Test');
    //         }
    //         else {
    //             pdfBlob2 = page2.getContentAsPDF();
    //         }
            
    //         ContentVersion cv2 = new ContentVersion(
    //             Title = 'Live_Update_'+wo.Account.BP_Number__c+'_'+wo.From_Date__c.format()+'_'+wo.To_Date__c.format()+'.pdf',
    //         PathOnClient = 'JointTicket2.pdf',
    //         VersionData = pdfBlob2
    //             );
    //         contentVersions.add(cv2);
    //     }
        
    //     insert contentVersions;
        
    //     // Retrieve inserted versions with their ContentDocumentId
    //     List<ContentVersion> insertedVersions = [
    //         SELECT Id, ContentDocumentId FROM ContentVersion
    //         WHERE Id IN :contentVersions
    //     ];
        
    //     Integer i = 0;
    //     for (Id wo : workOrderIds) {
    //         contentLinks.add(new ContentDocumentLink(
    //             ContentDocumentId = insertedVersions[i].ContentDocumentId,
    //         LinkedEntityId = wo,
    //         ShareType = 'V',
    //         Visibility = 'AllUsers'
    //             ));
    //         i++;
    //         contentLinks.add(new ContentDocumentLink(
    //             ContentDocumentId = insertedVersions[i].ContentDocumentId,
    //         LinkedEntityId = wo,
    //         ShareType = 'V',
    //         Visibility = 'AllUsers'
    //             ));
    //         i++;
    //     }
        
    //     insert contentLinks;

    //     // update woList;
    //     System.enqueueJob(new WOStatusUpdater(workOrderIds));
    // }
    /*
public static void handleWorkOrderUpdate(List<WorkOrder> newList, Map<Id, WorkOrder> oldMap) {
    if (newList.isEmpty()) return;

    System.debug('280::insideSendSMs');

    // Collect WorkOrder Ids first
    Set<Id> woIdsToQuery = new Set<Id>();
    for (WorkOrder wo : newList) {
        woIdsToQuery.add(wo.Id);
    }

    // Query WorkOrders with WorkType.Name and Agent__c
    Map<Id, WorkOrder> queriedWoMap = new Map<Id, WorkOrder>(
        [SELECT Id, Agent__c, WorkTypeId, WorkType.Name 
         FROM WorkOrder 
         WHERE Id IN :woIdsToQuery]
    );

    Set<Id> woIds = new Set<Id>();
    Set<Id> agentIds = new Set<Id>();
    Map<Id, WorkOrder> woMap = new Map<Id, WorkOrder>();

    // Filter based on agent change and WorkType.Name
    for (WorkOrder woFromTrigger : newList) {
        WorkOrder wo = queriedWoMap.get(woFromTrigger.Id);
        WorkOrder oldWO = oldMap.get(woFromTrigger.Id);

        Boolean agentChanged = (oldWO == null || woFromTrigger.Agent__c != oldWO.Agent__c);

        System.debug('wo.WorkType.Name: ' + wo.WorkType.Name);

        if (agentChanged &&
            wo.Agent__c != null &&
            wo.WorkTypeId != null &&
            (wo.WorkType.Name == 'Rubber Hose Replacement' ||
             wo.WorkType.Name == 'Individual Permanent Disconnection' ||
             wo.WorkType.Name == 'Domestic Meter Checking')) {

            woIds.add(wo.Id);
            agentIds.add(wo.Agent__c);
            woMap.put(wo.Id, wo);
        }
    }

    System.debug('301::WorkOrders to Process: ' + woIds);
    if (woIds.isEmpty()) return;

    // Fetch SMS Template
    Case_Type_SMS__c smsTemplate = [
        SELECT Status__c, Template_Id__c, Message__c, Sender__c
        FROM Case_Type_SMS__c
        WHERE Template_Name__c = 'O&M'
        LIMIT 1
    ];

    // Fetch ServiceResources for agents
    Map<Id, ServiceResource> serviceResourceMap = new Map<Id, ServiceResource>(
        [SELECT Id, Name FROM ServiceResource WHERE Id IN :agentIds]
    );

    // Fetch ServiceAppointments related to WorkOrders
    List<ServiceAppointment> appointments = [
        SELECT Id, ParentRecordId, SchedStartTime, SchedEndTime, Subject, AppointmentNumber,
               WorkType.Name,
               Account.Name,
               Account.Phone,
               (SELECT Id, ServiceResource.Name FROM ServiceResources)
        FROM ServiceAppointment
        WHERE ParentRecordId IN :woIds
    ];

    for (ServiceAppointment sa : appointments) {
        if (sa.Account == null) continue;

        WorkOrder relatedWO = woMap.get(sa.ParentRecordId);
        String assignedTech = 'our technician';

        if (relatedWO != null && relatedWO.Agent__c != null && serviceResourceMap.containsKey(relatedWO.Agent__c)) {
            assignedTech = serviceResourceMap.get(relatedWO.Agent__c).Name;
        } else if (sa.ServiceResources != null && !sa.ServiceResources.isEmpty()) {
            assignedTech = sa.ServiceResources[0].ServiceResource.Name;
        }

        String scheduledDate      = (sa.SchedStartTime != null) ? sa.SchedStartTime.format('dd-MMM-yyyy') : '';
        String scheduledStartTime = (sa.SchedStartTime != null) ? sa.SchedStartTime.format('hh:mm a') : '';
        String scheduledEndTime   = (sa.SchedEndTime != null) ? sa.SchedEndTime.format('hh:mm a') : '';
        String activityType       = (sa.WorkType != null) ? sa.WorkType.Name : 'the scheduled work';

        String technicianLink = 'Test';

        Map<String, String> mergeFields = new Map<String, String>{
            'assignedTech'       => assignedTech,
            'scheduledDate'      => scheduledDate,
            'scheduledstartTime' => scheduledStartTime,
            'scheduledEndTime'   => scheduledEndTime,
            'activityType'       => activityType,
            'technicianLink'     => ''
        };

        String finalMessage = smsTemplate.Message__c;
        for (String key : mergeFields.keySet()) {
            finalMessage = finalMessage.replace('{' + key + '}', mergeFields.get(key));
        }

        if (!String.isBlank(sa.Account.Phone)) {
            System.debug('Sending SMS to: ' + sa.Account.Phone + ' | Message: ' + finalMessage);

            SmsApiCallout.sendSmsFuture(
                sa.Account.Phone,
                smsTemplate.Message__c,
                sa.ParentRecordId,
                mergeFields,
                smsTemplate.Template_Id__c,
                smsTemplate.Sender__c
            );
        }
    }
}
*/

    public static void handleStatusUpdate(List<WorkOrder> newList, Map<Id, WorkOrder> oldMap) {
        List<Task> tasksToInsert = new List<Task>();
        Set<Id> workOrderIds = new Set<Id>();
        
        for (WorkOrder wo : newList) {
            WorkOrder oldWo = oldMap.get(wo.Id);
            
            Boolean isFollowUpChanged = wo.Follow_Up_Appointment_Date__c != null &&
                wo.Follow_Up_Appointment_Date__c != oldWo.Follow_Up_Appointment_Date__c;
            
            Boolean isStatusChanged = wo.Appointment_Status__c == 'Incomplete' &&
                oldWo.Appointment_Status__c != 'Incomplete';
            
            if (wo.Follow_Up_Appointment_Date__c != null &&
                wo.Appointment_Status__c == 'Incomplete' &&
            (isFollowUpChanged || isStatusChanged)) {
                
                workOrderIds.add(wo.Id);
            }
        }
        
        if (workOrderIds.isEmpty()) return;
        
        // Query again to ensure relationship fields are available
        List<WorkOrder> eligibleWOs = [
            SELECT Id, WorkOrderNumber, Follow_Up_Appointment_Date__c,
                   Assigned_Meter_Reader__r.RelatedRecordId
            FROM WorkOrder
            WHERE Id IN :workOrderIds
        ];
        
        for (WorkOrder wo : eligibleWOs) {
            if (wo.Assigned_Meter_Reader__r != null && wo.Assigned_Meter_Reader__r.RelatedRecordId != null) {
                Task t = new Task();
                t.Subject = wo.WorkOrderNumber;
                t.WhatId = wo.Id;
                t.ActivityDate = Date.valueOf(wo.Follow_Up_Appointment_Date__c);
                t.OwnerId = wo.Assigned_Meter_Reader__r.RelatedRecordId;
                
                tasksToInsert.add(t);
            }
        }
        
        if (!tasksToInsert.isEmpty()) {
            insert tasksToInsert;
        }
    }
    
    public static void handleAfterSave(List<WorkOrder> newList, Map<Id, WorkOrder> oldMap) {
        List<WorkOrder> filtered = new List<WorkOrder>();
        for (WorkOrder wo : newList) {
            if (wo.Record_Type_Developer_Name__c != 'MGL_R_T') continue;
            if (wo.AccountId == null) continue;
            if (wo.Due_Amount__c == null || wo.Due_Amount__c <= 0) continue;

            // filter for INSERT only
            if (oldMap == null && wo.SMS_Sent__c == true) {
                continue; // skip insert if SMS already sent
            }

            filtered.add(wo);
        }
        

        if (!filtered.isEmpty()) {
            WorkOrderNotificationService.processNotifications(filtered, oldMap);
        }
    }
    
    public static void populateRelatedFields(List<WorkOrder> workOrders){

        if(workOrders.isEmpty()) return;

        // Collect IDs for queries
        Set<String> bpNumbers = new Set<String>();
        Set<String> agentIds = new Set<String>();
        Set<String> agencyCodes = new Set<String>();
        Set<String> portions = new Set<String>();

        for(WorkOrder wo : workOrders){
            if(wo.Customer_BP_Number__c != null && wo.AccountId == null){
                bpNumbers.add(wo.Customer_BP_Number__c);
            }
            if(wo.Agent_ID__c != null && wo.Agent__c == null){
                agentIds.add(wo.Agent_ID__c);
            }
            if(wo.Agency_Name__c != null && wo.R_T_Agency__c == null){
                agencyCodes.add(wo.Agency_Name__c);
            }
            if(wo.Billing_portion__c != null && wo.Portion__c == null){
                portions.add(wo.Billing_portion__c);
            }
        }

        // Query Accounts
        Map<String, Id> bpToAccountId = new Map<String, Id>();
        if(!bpNumbers.isEmpty()){
            for(Account acc : [SELECT Id, BP_Number__c FROM Account WHERE BP_Number__c IN :bpNumbers]){
                bpToAccountId.put(acc.BP_Number__c, acc.Id);
            }
        }
        
        // Query ServiceResources (Agents)
        Map<String, Id> agentIdToSRId = new Map<String, Id>();
        if(!agentIds.isEmpty()){
            for(ServiceResource sr : [SELECT Id, Agent_ID__c FROM ServiceResource WHERE Agent_ID__c IN :agentIds]){
                agentIdToSRId.put(sr.Agent_ID__c, sr.Id);
            }
        }

        // Query ServiceTerritories (Agencies)
        Map<String, Id> agencyCodeToSTId = new Map<String, Id>();
        if(!agencyCodes.isEmpty()){
            for(ServiceTerritory st : [SELECT Id, AgencyCode__c FROM ServiceTerritory WHERE AgencyCode__c IN :agencyCodes]){
                agencyCodeToSTId.put(st.AgencyCode__c, st.Id);
            }
        }

        // Query Portions
        Map<String, Id> portionToId = new Map<String, Id>();
        if(!portions.isEmpty()){
            for(Portion__c po : [SELECT Id, Name FROM Portion__c WHERE Name IN :portions]){
                portionToId.put(po.Name, po.Id);
            }
        }

        // Populate WorkOrder fields
        for(WorkOrder wo : workOrders){
            if(wo.Customer_BP_Number__c != null && wo.AccountId == null && bpToAccountId.containsKey(wo.Customer_BP_Number__c)){
                wo.AccountId = bpToAccountId.get(wo.Customer_BP_Number__c);
            }

            if(wo.Agent_ID__c != null && wo.Agent__c == null && agentIdToSRId.containsKey(wo.Agent_ID__c)){
                wo.Agent__c = agentIdToSRId.get(wo.Agent_ID__c);
            }

            if(wo.Agency_Name__c != null && wo.R_T_Agency__c == null && agencyCodeToSTId.containsKey(wo.Agency_Name__c)){
                wo.R_T_Agency__c = agencyCodeToSTId.get(wo.Agency_Name__c);
            }

            if(wo.Billing_portion__c != null && wo.Portion__c == null && portionToId.containsKey(wo.Billing_portion__c)){
                wo.Portion__c = portionToId.get(wo.Billing_portion__c);
            }
        }
    }

    public static void syncOfflineSaStatus(List<WorkOrder> newList, Map<Id, WorkOrder> oldMap) {
        if (newList == null || newList.isEmpty()) return;

        Id meteringRtId;
        try {
            meteringRtId = Schema.SObjectType.WorkOrder
                .getRecordTypeInfosByDeveloperName()
                .get('MGL_Metering')
                .getRecordTypeId();
        } catch (Exception e) {
            // If RT not found, nothing to do
            return;
        }

        // WorkOrder Id → Target SA Status (Offline_Target_SA_Status__c)
        Map<Id, String> woIdToTargetStatus = new Map<Id, String>();

        for (WorkOrder wo : newList) {
            if (wo.RecordTypeId != meteringRtId) {
                continue;
            }

            String newVal = (String)wo.Offline_Target_SA_Status__c;
            String oldVal = oldMap != null && oldMap.containsKey(wo.Id)
                ? (String)oldMap.get(wo.Id).Offline_Target_SA_Status__c
                : null;

            // Skip if blank or unchanged → avoids unnecessary SOQL/DML
            if (String.isBlank(newVal) || newVal == oldVal) {
                continue;
            }

            woIdToTargetStatus.put(wo.Id, newVal.trim());
        }

        if (woIdToTargetStatus.isEmpty()) {
            return;
        }

        List<ServiceAppointment> saList = [
            SELECT Id, ParentRecordId, Status
            FROM ServiceAppointment
            WHERE ParentRecordId IN :woIdToTargetStatus.keySet()
        ];

        if (saList.isEmpty()) {
            return;
        }

        List<ServiceAppointment> saToUpdate = new List<ServiceAppointment>();

        for (ServiceAppointment sa : saList) {
            String targetStatus = woIdToTargetStatus.get(sa.ParentRecordId);
            if (String.isBlank(targetStatus)) {
                continue;
            }

            // Skip if already same status → avoid extra DML
            if (sa.Status == targetStatus) {
                continue;
            }

            sa.Status = targetStatus;
            saToUpdate.add(sa);
        }

        if (!saToUpdate.isEmpty()) {
            update saToUpdate;
        }
    }

}