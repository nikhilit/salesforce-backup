public without sharing class CaseActionController {
 
    @AuraEnabled

    public static void processCase(Id caseId, String remarks) {

        if (caseId == null) {

            throw new AuraHandledException('Case Id is required.');

        }
 
        try {

            System.debug('processCase START - caseId=' + caseId + ', remarks=' + remarks);

            Case cs = [

                SELECT Id, Status, AccountId,TAT_in_minutes__c,Lead__c,TAT_in_days__c,Department__c, OwnerId,

                       Account.DRS_Master__c, SPOC__c,Reopen_Count__c,Bypass_Status_Validation__c,Department_Responded_On__c

                FROM Case

                WHERE Id = :caseId

                LIMIT 1

            ];
            Date olddepartmentrespondeddate = cs.Department_Responded_On__c;

            System.debug('processCase - Queried Case: ' + cs);
 
            if (cs.AccountId == null && cs.Lead__c==null) {

                throw new AuraHandledException('Tag BP/Prospect to this case.');

            }

            cs.Comments = remarks;

            cs.Reopen_Count__c = (cs.Reopen_Count__c != null) ? cs.Reopen_Count__c + 1 : 1;

            cs.Status = 'In-Progress';
cs.Outgoing_Calls_Count__c=0;
cs.Outbound_Call_1_Done_By__c=null;
cs.Outbound_Call_1_Done_Time__c=null;
cs.Outbound_Call_1_Remarks__c=null;
cs.Outbound_Call_2_Done_By__c=null;
cs.Outbound_Call_2_Done_Time__c=null;
cs.Outbound_Call_2_Remarks__c=null;
cs.Outbound_Call_3_Done_By__c=null;
cs.Outbound_Call_3_Done_Time__c=null;
cs.Outbound_Call_3_Remarks__c=null;
            cs.Current_Work_Type__c = '1';

            // Only change owner if SPOC__c is populated
            if (cs.SPOC__c != null) {
                cs.OwnerId = cs.SPOC__c;
                cs.Assigned_To__c = cs.SPOC__c;
                System.debug('Control is checking the SPOC');
            } else {
                System.debug('processCase - SPOC__c is null, keeping existing OwnerId=' + cs.OwnerId);
                // Optionally: throw a friendly error instead of silently keeping it
                throw new AuraHandledException('SPOC is not defined for this case. Please set SPOC before reopening.');
            }

            cs.Is_reponed__c = true;

            cs.Bypass_Status_Validation__c=!cs.Bypass_Status_Validation__c;

            cs.Case_Violation4__c = false;

            cs.Case_Violation3__c = false;

             cs.Case_Violation2__c = false;

              cs.Case_Violation1__c = false;

              cs.Case_Violation__c= false;

              cs.Department_Responded_on__c=null;
              cs.Last_Remarks__c = (remarks == null) ? null : remarks.trim();

              System.debug('processCase - Before first update of Case (reopen): ' + cs);

            update cs;


            createWorkOrderForReopen(cs.Id, remarks);
            //System.debug('processCase - After first Case update, calling createWorkOrderForReopen');

            Integer totalDays = 0;

            List<Case_Escalation__c> caseEscalationsToInactive = [SELECT Id, Is_Active__c,Total_Days_Consumed__c FROM Case_Escalation__c WHERE Case__c = :cs.Id];

            System.debug('processCase - caseEscalationsToInactive size: ' + caseEscalationsToInactive.size());


            for (Case_Escalation__c cse : caseEscalationsToInactive) {

                 if (cse.Total_Days_Consumed__c != null) {

                     totalDays += Integer.valueOf(cse.Total_Days_Consumed__c);

                   }

                 cse.Is_Active__c = false;
 
                }

           Integer tatDays = 0;

           System.debug('processCase - TAT Days: ' + tatDays + ', Total Escalation Days: ' + totalDays);


              if (cs.TAT_in_days__c != null) {

              tatDays = Integer.valueOf(cs.TAT_in_days__c);

             }
 
            Integer remainingDays = tatDays - totalDays;

            if(remainingDays>0){

            Integer remainingMinutes = remainingDays * 1440;

            cs.Remaining_TAT__c = String.valueOf(remainingMinutes);

            }else{

                cs.Remaining_TAT__c = cs.TAT_in_minutes__c;

            }

            System.debug('processCase - Before second update of Case (Remaining_TAT__c): ' + cs);

            update cs;

            System.debug('processCase - Before createCallCenterSLAForReopen. Case Id=' + cs.Id + ', Status=' + cs.Status + ', Remarks=' + remarks);

            createCallCenterSLAForReopen(cs, remarks,olddepartmentrespondeddate);

            if (!caseEscalationsToInactive.isEmpty()) {

                update caseEscalationsToInactive;

            }
 
             List<Case_Escalation__c> caseescalations = new List<Case_Escalation__c>();

             Case_Escalation__c escalation = new Case_Escalation__c(

                            Case__c = cs.Id,

                            Escalation_Type__c='Reopen',

                            Assigned_To_Department_1__c = System.today(),

                            Department_1__c = cs.Department__c,

                            Is_Active__c = true

                        );
 
            caseEscalations.add(escalation);

             if (!caseEscalations.isEmpty()) {

            insert caseEscalations;

            }

        } catch (Exception ex) {

            System.debug('ex.getMessage'+ex.getMessage());

            Error_Logger__c err = Error_LoggerClass.createErrorLogger(

                'CaseActionController', 'processCase',

                caseId, ex.getTypeName(), ex.getMessage(),

                ex.getLineNumber(), true

            );

            insert err;

        }

    }

 
    private static void createWorkOrderForReopen(Id caseId, String remarks) {

    if (caseId == null) {

        System.debug('createWorkOrderForReopen - EXIT | caseId is null');

        return;

    }
 
        // --- Query the Case (include Sub_Type__c for mapping) ---

        Case cs;

        try {

            cs = [

                SELECT Id, AccountId, Comments, Department__c, Sub_Type__c,ContactId

                FROM Case

                WHERE Id = :caseId

                LIMIT 1

            ];

        } catch (Exception e) {

            System.debug('createWorkOrderForReopen - ERROR querying Case: ' + e.getMessage());

            return;

        }

        cs.Comments = remarks;
 
        // --- Find the most recent existing WorkOrder for this Case (if any) ---

        Id existingWorkOrderId = null;

        try {

            List<WorkOrder> existingWOs = [

                SELECT Id

                FROM WorkOrder

                WHERE CaseId = :caseId

                ORDER BY CreatedDate DESC

                LIMIT 1

            ];

            if (!existingWOs.isEmpty()) {

                existingWorkOrderId = existingWOs[0].Id;

            }

        } catch (Exception e) {

            System.debug('createWorkOrderForReopen - ERROR finding existing WOs: ' + e.getMessage());

        }
 
        // --- Resolve WorkOrder Record Type (developer name MGL_O_M) ---

        Id woRecordTypeId = null;

        Map<String, Schema.RecordTypeInfo> rtiMap =

            Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName();

        System.debug('createWorkOrderForReopen - WorkOrder RTI map keys: ' + (rtiMap == null ? 'null' : String.valueOf(rtiMap.keySet())));

        if (rtiMap != null && rtiMap.containsKey('MGL_O_M')) {

            woRecordTypeId = rtiMap.get('MGL_O_M').getRecordTypeId();

        }

 
        // --- Preload WorkType mapping ---

        Map<String, Id> workTypeMap = new Map<String, Id>();

        for (WorkType wt : [

            SELECT Id, Name 

            FROM WorkType

            WHERE Name IN ('Individual Permanent Disconnection',
            'Rubber Hose Replacement',
            'Domestic Meter Checking',
            'Meter Replacement',
            'After Sales Service')

        ]) {

            workTypeMap.put(wt.Name, wt.Id);

        }

 
        // --- Map Sub_Type__c to WorkType name ---

        String workTypeName;

        if (cs.Sub_Type__c != null) {
            switch on cs.Department__c{
            when 'AFTER SALES'{
                workTypeName ='After Sales Service';
            }
            }
            switch on cs.Sub_Type__c {
                 when 'Individual Permanent Disconnection & Refund Processing' {
                workTypeName = 'Individual Permanent Disconnection';
            }
            when 'Old Meter Replacement' {
                workTypeName = 'Meter Replacement';
            }
            when 'Meter Checking' {
                workTypeName = 'Domestic Meter Checking';
            }
            
        }

        }
        

        Id workTypeId = (workTypeName == null) ? null : workTypeMap.get(workTypeName);

 
        // --- Build the WorkOrder record ---

        WorkOrder wo = new WorkOrder();

        wo.Subject = 'Reopen Work Order ';

        wo.CaseId = cs.Id; 

        wo.AccountId = cs.AccountId;
        wo.ContactId=cs.ContactId;

        wo.Status = 'New';

        wo.Department__c = (cs.Sub_Type__c == 'Rubber Tube') ? null : 'O&M';
        wo.Follow_up_Remarks__c='Reopened';

        if (workTypeId != null) {

            wo.WorkTypeId = workTypeId;

        }
 
        // Set ParentWorkOrderId if an existing WO was found

        if (existingWorkOrderId != null) {

            wo.ParentWorkOrderId = existingWorkOrderId;

        }
 
        if (woRecordTypeId != null) {

            wo.RecordTypeId = woRecordTypeId;

        }
 
        if (cs.Comments != null) {

            wo.Case_Remark__c = cs.Comments;

        }
        // if(cs.Sub_Type__c=='Rubber Tube'){
        //     wo.Sub_Type__c='Customer Complaints';
        // }

 
      

        Database.SaveResult[] results = null;

        results = Database.insert(new List<WorkOrder>{ wo }, false);

        System.debug('createWorkOrderForReopen - Database.insert called, results length=' + (results == null ? 'null' : String.valueOf(results.size())));
 
}

    private static void createCallCenterSLAForReopen(Case cs, String remarks,Date olddepartmentrespondeddate) {
        if (cs == null) {
            System.debug('createCallCenterSLAForReopen - EXIT | Case is null');
            return;
        }          
        DateTime nowDt = System.now();
        
        Call_Center_SLA__c sla = new Call_Center_SLA__c();
        sla.Status__c               = cs.Status;                
        sla.Remarks__c              = remarks;                 
        sla.Created_Date__c         = nowDt.date();            
        sla.Created_Time__c         = nowDt.time();  
        sla.Activity__c='Reopen';          
        sla.Case__c                 = cs.Id;   
        sla.Call_Center_Agent__c    = UserInfo.getUserId();  
        sla.Department_Responded_On__c=olddepartmentrespondeddate;                         

        insert sla;
        System.debug('createCallCenterSLAForReopen - Case Id=' + cs.Id + ', Status=' + cs.Status + ', Remarks=' + remarks);
    }

}