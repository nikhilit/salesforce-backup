public class CaseTriggerHandler {
<<<<<<< HEAD
    private static Boolean hasAlreadyExecuted = false;
    private static Boolean smsAlreadyExecuted = false;

    
public static void setStatusForContactDetailsUpdate(List<Case> newCases) {
    // Collect all emails from cases that meet the initial criteria
    Set<String> caseEmails = new Set<String>();
    Map<String, Case> emailToCaseMap = new Map<String, Case>();
    
    for (Case cs : newCases) {
        // Null checks 
        if (cs == null) continue;
 
        if (cs.Department__c == 'CRM' &&
            cs.Category__c == 'S' &&
            (cs.Type__c == 'Customer Contact Details - Update' || cs.Type__c == 'Name Correction') &&
            cs.Status != 'Resolved') {
            
            if (cs.SuppliedEmail != null) {
                caseEmails.add(cs.SuppliedEmail);
            }
        }
    }
            Set<String> existingAccountEmails = new Set<String>();

    
    // If we have emails to check, query accounts in bulk
    if (!caseEmails.isEmpty()) {
        // Query accounts with matching emails
        List<Account> matchingAccounts = [
            SELECT Id, Account_Email__c 
            FROM Account 
            WHERE Account_Email__c IN :caseEmails
        ];
        
        // Create a set of emails that exist in accounts
        for (Account acc : matchingAccounts) {
            existingAccountEmails.add(acc.Account_Email__c);
        }
        
    }
    for (Case cs : newCases) {
        // Null checks 
        if (cs == null) continue;
 
        if (cs.Department__c == 'CRM' &&
            cs.Category__c == 'S' &&
            (cs.Type__c == 'Customer Contact Details - Update' || cs.Type__c == 'Name Correction') && 
            cs.Status != 'Resolved') {
            
            if(cs.Suppliedemail!=null && !existingAccountEmails.contains(cs.SuppliedEmail)) {
                cs.addError('Cannot create a case for this type and subtype: No BP found with email ' + cs.SuppliedEmail);
            }else{
                if(cs.Type__c == 'Customer Contact Details - Update' || cs.Type__c == 'Name Correction')
                cs.Status='Resolved';
            }
            }
        }
}
 public static void mergeCases(List<Case> cases){
        Set<Id> casestodelete = new Set<Id>();
        List<Case> updateCases=new List<case>();
        Set<String> emailAddress = new Set<String>();        
        Map<Id,Case> updateoldcases = new Map<Id,Case>();
        Set<Id> caseId= new Set<Id>();
        Set<String> excludedEmails = new Set<String>(
    System.Label.Excluded_Supplied_Emails.split(',')
);
        for(Case cs:cases){
            if(cs.Origin=='4'&& String.isNotBlank(cs.Subject) && String.isNotBlank(cs.SuppliedEmail)&&!excludedEmails.contains(cs.SuppliedEmail)){
                emailAddress.add(cs.SuppliedEmail);
                caseId.add(cs.Id);
            }
        }
        List<case> existingCases = new List<Case>();

        Group junkQueue;
        if(!caseId.isEmpty()){
            existingCases= [SELECT Id,Subject,SuppliedEmail FROM Case WHERE Isclosed=false and Suppliedemail in :emailAddress and IsMerged__c=false and Id NOT In:caseId ORDER BY CreatedDate DESC];
            junkQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Junk_Queue' LIMIT 1];
        }
        Map<String,Map<String,Case>> emailtoCaseMap = new Map<String,Map<String,Case>>();
        for(Case cs:existingCases){
            if (!emailtoCaseMap.containsKey(cs.SuppliedEmail)) {
            emailtoCaseMap.put(cs.SuppliedEmail, new Map<String, Case>());
              }
            emailtoCaseMap.get(cs.SuppliedEmail).put(cs.Subject, cs);

        }
        for(Case cs:cases){
            if(cs.Origin=='4'&&cs.Subject!=null&&cs.SuppliedEmail!=null&&!excludedEmails.contains(cs.SuppliedEmail)){
                if(emailtoCaseMap!=null && emailtoCaseMap.get(cs.SuppliedEmail)!=null){
                    Case parentCase = emailtoCaseMap.get(cs.SuppliedEmail).get(cs.Subject);
                    if(parentCase!=null){
                        Case newcse = new Case();
                        newcse.Id = cs.Id;
                        newcse.IsMerged__c = true;
                        newcse.OwnerId = junkQueue.Id;
                        newcse.ParentId = parentCase.Id;
                        updateCases.add(newcse);
                        casestodelete.add(newcse.Id);
                        if (updateoldcases.get(parentCase.Id) == null) {
                            updateoldcases.put(
                                parentCase.Id,
                                new Case(
                                    Id = parentCase.Id,
                                    Comments = cs.CaseNumber + ' is Merged '
                                )
                            );
                        } else {
                            String existingComment = updateoldcases.get(parentCase.Id).Comments;
                            updateoldcases.put(
                                parentCase.Id,
                                new Case(
                                    Id = parentCase.Id,
                                    Comments = existingComment + cs.CaseNumber + ' is Merged '
                                )
                            );
                        }                
                    }
                }
            }
        }
        for(Id recId:updateoldcases.keyset()){
            updateCases.add(updateoldcases.get(recId));
        }
        if(!updateCases.isEmpty()){
            update updateCases;
            System.enqueueJob(new CaseMergeQueueable(casestodelete));
        }
}
public static void createWorkOrders(List<Case> cases, Map<Id, Case> oldCaseMap) {
    if (hasAlreadyExecuted) return;
        hasAlreadyExecuted = true;
    Set<String> typesOfIssues = new Set<String>();
    Set<Id> accountIds = new Set<Id>();
    Set<Id> leadIds = new Set<Id>();
    // Initial case processing
    for (Case cs : cases) {
        Case oldCase=null;
        if(oldCaseMap != null){
          oldCase = oldCaseMap.get(cs.Id);
        }
        if (oldCase==null && (cs.Created_Date_OLd__c == null ||cs.Application_Number__c != null)) {
            typesOfIssues.add(cs.Type__c);
           if (cs.AccountId != null) {
            accountIds.add(cs.AccountId);
            }
           if (cs.Lead__c != null) {
            leadIds.add(cs.Lead__c);
            }
        }
       else if (oldCase != null && (cs.Created_Date_OLd__c==null  ||cs.Application_Number__c != null) &&(
            oldCase.AccountId != cs.AccountId || cs.QRC_Process__c==null)) {
            typesOfIssues.add(cs.Type__c);
             if (cs.AccountId != null) {
            accountIds.add(cs.AccountId);
            }
           if (cs.Lead__c != null) {
            leadIds.add(cs.Lead__c);
            }

        }
    }
    if (typesOfIssues.isEmpty()) {
        return;
    }
    List<Account> accountList=new List<Account>();
    Map<Id, Account> accountMap = new Map<Id, Account>();
        if(accountIds.size()>0){
             accountList = [
        SELECT Id, DRS_Master__c, DRS_Master__r.Name
        FROM Account
        WHERE Id IN :accountIds
    ];
        }
       Map<Id, Lead> leadMap = new Map<Id, Lead>();
    List<Lead> leadList =new List<Lead>();
        if(leadIds.size()>0){
           leadList = [
        SELECT Id, DRS__c,drs__r.name
        FROM Lead
        WHERE Id IN :leadIds
    ];
        }
    Set<Id> drsIds = new Set<Id>();
    for (Account acc : accountList) {
        accountMap.put(acc.Id, acc);
        if (acc.DRS_Master__c != null) {
            drsIds.add(acc.DRS_Master__c);
        }
    }
    for (Lead ld : leadList) {
                leadMap.put(ld.Id, ld);
        if (ld.DRS__c != null) {
            drsIds.add(ld.DRS__c);
        }
    }

    List<QRC_Process__c> departmentTagging = [
        SELECT Id, Department__c, Type__c, Sub_Type__c, Value_1__c,Category__c,
               TAT_in_hours__c, Before_Approval_dpt__c
        FROM QRC_Process__c
        WHERE isActive__c = true AND Type__c IN :typesOfIssues
    ];

    Map<String, String> categoryValueToLabelMap = new Map<String, String>();
    Schema.DescribeFieldResult categoryField = Case.Category__c.getDescribe();

   for (Schema.PicklistEntry entry : categoryField.getPicklistValues()) {
    categoryValueToLabelMap.put(entry.getValue(), entry.getLabel());
    }

    Map<String, QRC_Process__c> departmentTaggingMap = new Map<String, QRC_Process__c>();
    for (QRC_Process__c mapping : departmentTagging) {
       String key = (
        mapping.Category__c +
        mapping.Type__c +
        mapping.Sub_Type__c +
        mapping.Value_1__c
    ).toLowerCase();
        departmentTaggingMap.put(key, mapping);
    }
    List<Departments_SPOC_Mapping__c> spocMappings =new List<Departments_SPOC_Mapping__c>();
        if(drsIds.size()>0){
          spocMappings=   [
        SELECT SPOC_Id__c, DRS__c, Department__c, QRC_Process__c
        FROM Departments_SPOC_Mapping__c
        WHERE DRS__c IN :drsIds
    ];
        }

    Map<String, Departments_SPOC_Mapping__c> deptspocmapping = new Map<String, Departments_SPOC_Mapping__c>();
    for (Departments_SPOC_Mapping__c dept : spocMappings) {
        String mapKey = (dept.DRS__c + dept.Department__c + dept.QRC_Process__c).toLowerCase();
        deptspocmapping.put(mapKey, dept);
    }
   
    List<Case> casesToUpdate = new List<Case>();
    List<Case_Escalation__c> caseescalations = new List<Case_Escalation__c>();
    Set<Id> caseIds = new Set<Id>();
    BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1];

    for (Case cs : cases) {
        Case oldCase = oldCaseMap.get(cs.Id);
if(!(oldCase != null && (cs.Created_Date_OLd__c==null ||cs.Application_Number__c!=null) &&(
            oldCase.AccountId != cs.AccountId || cs.Qrc_process__c==null))){
            continue;
        }
    String categoryLabel = '';
    if (cs.Category__c != null && categoryValueToLabelMap.containsKey(cs.Category__c)) {
        categoryLabel = categoryValueToLabelMap.get(cs.Category__c);
    }

    String key = (categoryLabel  + cs.Type__c + cs.Sub_Type__c +
                     cs.Value_1__c).toLowerCase();
        QRC_Process__c mapping = departmentTaggingMap.get(key);
        Case updatedCase = new Case(Id = cs.Id);
       
        if (cs.AccountId != null) {
            Account acc1 = accountMap.get(cs.AccountId);
            if (acc1 != null && acc1.DRS_Master__c != null && acc1.DRS_Master__r != null) {
                updatedCase.DRS_Name__c = acc1.DRS_Master__r.Name;
            }
        } else if (cs.Lead__c != null) {
            // FIXED: Now we can access DRS__r.Name because we queried it
            Lead relatedLead = leadMap.get(cs.Lead__c);
            if (relatedLead != null && relatedLead.DRS__c != null && relatedLead.DRS__r != null) {
                updatedCase.DRS_Name__c = relatedLead.DRS__r.Name;
            }
        }
       
        if (cs.Category__c == null || cs.Type__c == null) {
            continue;
        }
       
        if(cs.AccountId==null&&cs.lead__c==null){
            cs.addError('BP or Prospect not found. Cannot proceed.');
            continue;
        }
        if (mapping != null) {
            updatedCase.QRC_Process__c = mapping.Id;
            if (mapping.TAT_in_hours__c != null) {
                Decimal tatHours = mapping.TAT_in_hours__c;
                Integer tatDays = (Integer)(tatHours / 24);
                Integer tatMinutes = (Integer)Math.round(tatHours * 60);
                Long tatMilliseconds = (tatHours * 60 * 60 * 1000).longValue();
                updatedCase.TAT__c = String.valueOf(tatHours);
                DateTime benchmark = BusinessHours.add(bh.Id, System.now(), tatMilliseconds);
                updatedCase.Benchmark__c = benchmark.date();
                updatedCase.Remaining_TAT__c = String.valueOf(tatMinutes);
                updatedCase.TAT_in_days__c = String.valueOf(tatDays);
                updatedCase.TAT_in_minutes__c = String.valueOf(tatMinutes);
            }
        } else {
            updatedCase.QRC_Process__c = null;
            updatedCase.TAT__c = null;
            updatedCase.Benchmark__c = null;
            updatedCase.TAT_in_days__c = null;
            updatedCase.TAT_in_minutes__c = null;
            updatedCase.Remaining_TAT__c = '1';
            if (cs.Department__c != null) {
                cs.addError('QRC Process is required when Department is selected (no QRC mapping found for this combination).');
            }
        }

        // Get DRS ID
        Id drsId;
        if (cs.AccountId != null && accountMap.containsKey(cs.AccountId)) {
            drsId = accountMap.get(cs.AccountId).DRS_Master__c;
        } else if (cs.Lead__c != null && leadMap.containsKey(cs.Lead__c)) {
            drsId = leadMap.get(cs.Lead__c).DRS__c;
        }

        if (drsId != null) {
            Departments_SPOC_Mapping__c spocMap;
            String spocMapKey;
           
            if(mapping!=null){
                spocMapKey = (drsId + mapping.Department__c + mapping.Id).toLowerCase();
                spocMap = deptspocmapping.get(spocMapKey);
            }
            if (spocMap != null && spocMap.SPOC_Id__c != null) {
                updatedCase.SPOC__c = spocMap.SPOC_Id__c;
                updatedCase.Assigned_To__c = spocMap.SPOC_Id__c;
                updatedCase.Categorised_By__c = UserInfo.getUserId();
                if (cs.Category__c != null && !cs.Category__c.toLowerCase().startsWith('q')&&cs.Type__c!='Name Transfer Processed'&&cs.Type__c!='AMR Update by CRM') {
                    updatedCase.Status = 'In-Progress';
                    updatedCase.Current_Work_Type__c = '1';
                    updatedCase.OwnerId = spocMap.SPOC_Id__c;
                    updatedCase.Bypass_Status_Validation__c = true;
                    updatedCase.Assigned_To_Department__c = System.today();
                    updatedCase.Latest_Assigned_to_Dept_Date__c = System.today();
                    //updatedCase.Assigned_to_department_time__c = System.now();
                    caseIds.add(cs.Id);

                    Case_Escalation__c cse = new Case_Escalation__c();
                    cse.Case__c = cs.Id;
                    cse.Escalation_Type__c = 'New';
                    cse.Assigned_To_Department_1__c = System.today();
                    cse.Department_1__c = cs.Department__c;
                    cse.Is_Active__c = true;
                    caseescalations.add(cse);
                }
            }

            casesToUpdate.add(updatedCase);
        } else {
            cs.addError('DRS not found on Account or Lead. Cannot proceed.');
            continue;
        }
    }
    if (!casesToUpdate.isEmpty()) {
        update casesToUpdate;
        if (!caseescalations.isEmpty()) {
            insert caseescalations;
        }
        if (!caseIds.isEmpty()) {
            callSMSClass(caseIds);
            simpleUpdate(caseIds);
        }
    }
}
public static void updatemilestone(List<Case> newCases, Map<Id,Case> oldValues) {
        Set<Id> caseIdsToUpdate=new Set<Id>();    
        try{
            for (Case newCase : newCases) {
                Case oldCaseValue=oldValues.get(newCase.Id);
                if (newCase.Created_Date_OLd__c==null &&((oldCaseValue.Status!='Actioned By Department' && newCase.Status == 'Actioned By Department')||(oldCaseValue.Status!='Resolved' && newCase.Status == 'Resolved')||(oldCaseValue.Status!='Not Actionable' && newCase.Status == 'Not Actionable') || (oldCaseValue.Status!='Customer Not Responded' && newCase.Status == 'Customer Not Responded')|| (oldCaseValue.Status!='Resolved by CRM' && newCase.Status == 'Resolved by CRM'))){
                        caseIdsToUpdate.add(newCase.Id);
                }
            }
            if (!caseIdsToUpdate.isEmpty()) {
                List<CaseMilestone> milestonesToUpdate = new List<CaseMilestone>();
                List<MilestoneType> milestoneIds = [SELECT Id, Name FROM MilestoneType WHERE Name LIKE '%TAT for % closure'];
                Set<Id> milestoneTypeIds = new Set<Id>();
                for(MilestoneType mt : milestoneIds) {
                    milestoneTypeIds.add(mt.Id);
                }
               
               
                for (CaseMilestone milestone : [SELECT Id, CompletionDate, CaseId, IsCompleted,MilestoneTypeId
                                                FROM CaseMilestone
                                                WHERE CaseId IN : caseIdsToUpdate AND IsCompleted = FALSE AND MilestoneTypeId IN:milestoneTypeIds]) {
                                                    milestone.CompletionDate = System.now();
                                                    milestonesToUpdate.add(milestone);
                }
                if (!milestonesToUpdate.isEmpty()) {
                    update milestonesToUpdate;
                }
            }
        }
        catch(Exception ex) {
         }
    }
   
   public static void updateTatWarning(List<Case> newList, Map<Id, Case> oldMap) {
        for (Case c : newList) {
            Case oldCase = oldMap.get(c.Id);
            if (
                c.Status != null && c.Created_Date_OLd__c==null &&
                (c.Status.equalsIgnoreCase('Resolved') || c.Status.equalsIgnoreCase('Not Actionable') || c.Status.equalsIgnoreCase('Customer Not Responded') || c.Status.equalsIgnoreCase('Resolved by CRM')) &&
                c.Status != oldCase.Status
            ) {
                c.TAT_Warning__c = false;
                c.CRM_Closure_TAT_warning__c =false;
                c.Closed_By__c = UserInfo.getUserId();
            }

            //    Only update Comments when Standard Remarks CHANGED and is not blank
            if (
                c.Standard_Remarks__c != oldCase.Standard_Remarks__c &&
                !String.isBlank(c.Standard_Remarks__c)
            ) {
                String remarks = c.Standard_Remarks__c;

                // ensure 4000 char limit
                if (remarks.length() > 4000) {
                    remarks = remarks.substring(0, 4000);
                }

                c.Comments = remarks;
            }

            if (oldCase != null && c.Status != oldCase.Status) {
                c.Previous_Status__c = oldCase.Status;
            }


        }
    }

   
    public static void setStatusForQueryCases(List<Case> newCases, Map<Id, Case> oldMap) {
        Set<Id> accountIds = new Set<Id>();
        for (Case c : newCases) {
            if (Trigger.isUpdate) {
                if (c.Category__c != null && c.Category__c.toLowerCase().startsWith('q')&&c.Created_Date_OLd__c==null) {
                        Case oldCase = oldMap != null ? oldMap.get(c.Id) : null;    
                    if (oldCase != null && c.Status != oldCase.Status && c.Status != 'Resolved by CRM') {
                        c.Status.addError('Status cannot be changed for a Query category case');
                    }
                    if (c.Status != 'Resolved by CRM') {
                        c.Status = 'Resolved by CRM';
                    }
                }
            } else {
                if (c.Category__c != null && c.Category__c.toLowerCase().startsWith('q')&&c.Created_Date_OLd__c==null) {
                    if (c.Status != 'Resolved by CRM') {
                        c.Status = 'Resolved by CRM';
                    }
                }
            }
              //  if (c.Status == 'New' && c.NewAfter24hours__c == null && c.Created_Date_OLd__c==null && c.NewAfter48hours__c == null) {
                 if (c.Status == 'New' && c.NewAfter24hours__c == null && c.Created_Date_OLd__c==null) {
                c.NewAfter24hours__c = System.now().addHours(24);
                //c.NewAfter48hours__c = System.now().addHours(48);
            }
               if (c.Type__c == 'Name Transfer Processed' && c.AccountId != null&&c.Created_date_old__c==null) {
                accountIds.add(c.AccountId);
            }
        }
                if (!accountIds.isEmpty()) {
                Map<Id, Account> accountMap = new Map<Id, Account>(
                [SELECT Id, Name, FirstName__c, LastName__c, Middle_Name__c, Account_Email__c, Phone, Full_Name__c,Person_Title__c  
                    FROM Account WHERE Id IN :accountIds]
                );
       
            for (Case c : newCases) {

        // Check if Type changed to Name Transfer Processed
        Case oldCase = oldMap != null ? oldMap.get(c.Id) : null;
        Boolean typeChangedToNTP = (
            oldCase != null &&
            oldCase.Type__c != 'Name Transfer Processed' &&
            c.Type__c == 'Name Transfer Processed'
        );

        // Apply OR condition: Status = New OR Type Changed
        if ( (Trigger.isinsert || typeChangedToNTP) && c.AccountId != null ) {

            Account acc = accountMap.get(c.AccountId);

            if (acc != null) {
                c.Existing_Name__c = acc.Full_Name__c;
                c.Existing_Contact__c = acc.Phone;
                c.Existing_First_Name__c = acc.FirstName__c;
                c.Existing_Last_Name__c = acc.LastName__c;
                c.Existing_Middle_Name__c = acc.Middle_Name__c;
                c.Existing_email_id__c = acc.Account_Email__c;
                c.Existing_Salutation__c = acc.Person_Title__c;
=======
    public static void populateCaseNumber(List<Case> caseList)
    {
        List<Account> accList= new  List<Account>();
        for(Case cs : caseList)
        {
            if(cs.AccountId!=null)
            {
                Account acc = new Account();
                acc.id=cs.AccountId;
                acc.Latest_Case_Number__c=cs.CaseNumber;
                accList.add(acc);
            }
        }
        if(!accList.isEmpty())
        {
            update accList;
        }
    }
    
    public static void CaseDeletionByAdmin(List<Case> caseList)
    {
        Profile p=[select id from profile WHERE Name = 'System Administrator'];
        
        for(case c : caseList)
        {
            if(Userinfo.getprofileid() != p.Id)
            {
                c.adderror('only system adminsitrator can delete case');
>>>>>>> e604021b64f33882bfed07c2bfed265ad53326cf
            }
        }
    }

<<<<<<< HEAD
        }
    }
   
    public static void sendResolvedSms(List<Case> newCases, Map<Id, Case> oldMap, String loggedInUserProfileName) {
        //User loggedInUser =[SELECT Id,Profile.Name FROM User WHERE Id=:UserInfo.getUserId()];
        Set<Id> caseIds=new Set<Id>();
        for (Case cs : newCases) {
            if ((cs.Created_Date_OLd__c!=null && loggedInUserProfileName!='System Administrator') || (cs.Created_Date_OLd__c==null && (cs.Status == 'Resolved' || cs.Status=='Resolved by CRM' ||cs.Status=='Customer Not Responded' )&& oldMap.get(cs.Id).Status!=cs.Status)) {
                    caseIds.add(cs.Id);
            }
        }
        if(caseIds.size()>0){
            callSMSClass(caseIds);
        }
    }
   
public static void callSMSClass(Set<Id> caseIds) {
    if (smsAlreadyExecuted) return;  
    smsAlreadyExecuted = true;
    if (caseIds == null || caseIds.isEmpty()) return;

    Set<Id> qrcProcessIds = new Set<Id>();
    Set<String> statusList = new Set<String>();
    Map<String, Case_Type_SMS__c> subTypeToSms = new Map<String, Case_Type_SMS__c>();
    List<Notification__c> notificationsToInsert = new List<Notification__c>();
    List<SmsData> smsDataList = new List<SmsData>();

    // Query cases
    List<Case> casesList = [
        SELECT Id, Account.Phone, Account.FirstName__c, Account.LastName__c,
               Account.Room__c, Account.Building_Name_Conn__c, Account.Building_Code__c,
               Lead__r.Phone, Lead__r.FirstName, Lead__r.LastName,
               Lead__r.Flat__c, Lead__r.Building_Name__c,
               Name_Transfer_Request_Status__c, Mode_of_payment__c,
               QRC_Process__c, QRC_Process__r.Name, Department__c,
               Status, Docket_Number__c, Cheque_Number__c,
               Courier_Reference_Number__c, Refund_Amount__c, Bank_Name__c,
               Send_SMS_to__c, New_Contact__c, AccountId, Lead__c
        FROM Case
        WHERE Id IN :caseIds
    ];

    // Collect QRC Process IDs and statuses
    for (Case cs : casesList) {
        if (cs.QRC_Process__c != null) qrcProcessIds.add(cs.QRC_Process__c);
        if (cs.Status != null) statusList.add(cs.Status);
    }

    // Query Case_Type_SMS__c based on available QRC process IDs
    List<Case_Type_SMS__c> typeSMSList = qrcProcessIds.isEmpty() ? [
        SELECT Status__c, Template_Id__c, Message__c, QRC_Process__c,
               Whatsapp_Template_Name__c, QRC_Process__r.Name
        FROM Case_Type_SMS__c
        WHERE QRC_Process__c = null
        AND Status__c IN :statusList
    ] : [
        SELECT Status__c, Template_Id__c, Message__c, QRC_Process__c,
               Whatsapp_Template_Name__c, QRC_Process__r.Name
        FROM Case_Type_SMS__c
        WHERE QRC_Process__c IN :qrcProcessIds
    ];

    // Map Case_Type_SMS__c by unique key (Status + QRC Process)
    for (Case_Type_SMS__c sms : typeSMSList) {
        String key = sms.Status__c + String.valueOf(sms.QRC_Process__c);
        subTypeToSms.put(key, sms);
    }

    // Iterate through each case
    for (Case cs : casesList) {
        String accountPhone = cs.Account != null ? cs.Account.Phone : null;
        String leadPhone = cs.Lead__r != null ? cs.Lead__r.Phone : null;
        String newContactPhone = !String.isBlank(cs.New_Contact__c) ? cs.New_Contact__c : null;
        String sendSmsToPhone = cs.Send_SMS_to__c;

        // Determine WhatsApp/SMS primary number
        String whatsappPhone = !String.isBlank(newContactPhone) ? newContactPhone :
                               (!String.isBlank(accountPhone) ? accountPhone :
                               (!String.isBlank(leadPhone) ? leadPhone : sendSmsToPhone));

        // Prepare merge fields
        Map<String, String> mergeFields = new Map<String, String>();
        if (cs.Account != null) {
            mergeFields.put('Name', cs.Account.FirstName__c + ' ' + cs.Account.LastName__c);
            mergeFields.put('flatname', cs.Account.Room__c);
            mergeFields.put('buildingname', cs.Account.Building_Name_Conn__c);
            mergeFields.put('chequenumber', cs.Cheque_Number__c);
            mergeFields.put('courierrefno', cs.Courier_Reference_Number__c);
            mergeFields.put('refundamount', String.valueOf(cs.Refund_Amount__c));
            mergeFields.put('bankname', cs.Bank_Name__c);
            mergeFields.put('address', cs.Account.Room__c + ' ' + cs.Account.Building_Name_Conn__c);
        } else if (cs.Lead__r != null) {
            mergeFields.put('Name', cs.Lead__r.FirstName + ' ' + cs.Lead__r.LastName);
            mergeFields.put('flatname', cs.Lead__r.Flat__c);
            mergeFields.put('buildingname', cs.Lead__r.Building_Name__c);
        }
        mergeFields.put('caseNumber', cs.Docket_Number__c);

        // Determine message key
        String key = cs.Status + String.valueOf(cs.QRC_Process__c);
        Case_Type_SMS__c smsConfig = subTypeToSms.get(key);

        // Fallback: Name Transfer or Mode of Payment status
        if (smsConfig == null) {
            if (!String.isBlank(cs.Name_Transfer_Request_Status__c)) {
                String keyNameTransfer = cs.Name_Transfer_Request_Status__c + String.valueOf(cs.QRC_Process__c);
                smsConfig = subTypeToSms.get(keyNameTransfer);
            } else if (cs.Status == 'Actioned by Department' && cs.Department__c == 'CRM' && !String.isBlank(cs.Mode_of_payment__c)) {
                String keyPayment = cs.Mode_of_Payment__c + String.valueOf(cs.QRC_Process__c);
                smsConfig = subTypeToSms.get(keyPayment);
            }
        }

        // If valid config found → send SMS + WhatsApp
        if (smsConfig != null && !String.isBlank(smsConfig.Message__c)) {
            // ✅ SMS (to all valid phone numbers)
            List<String> phonesToSend = new List<String>{ newContactPhone, accountPhone, leadPhone, sendSmsToPhone };
            for (String phone : phonesToSend) {
                if (!String.isBlank(phone)) {
                    if(newContactPhone!=null&&phone==newContactPhone){
                    smsDataList.add(new SmsData(
                        phone,
                        smsConfig.Message__c,
                        String.valueOf(cs.Id),
                        mergeFields,
                        smsConfig.Template_Id__c
                    ));
                }
                    else if(newContactPhone==null){
                        smsDataList.add(new SmsData(
                        phone,
                        smsConfig.Message__c,
                        String.valueOf(cs.Id),
                        mergeFields,
                        smsConfig.Template_Id__c
                    ));
                    }
                }
            }

            // ✅ WhatsApp (only to preferred phone)
            if (!String.isBlank(smsConfig.Whatsapp_Template_Name__c) && !String.isBlank(whatsappPhone)) {
                List<Map<String, String>> dynamicComponents = extractDynamicComponents(smsConfig.Message__c, mergeFields);
                notificationsToInsert.add(new Notification__c(
                    Case__c = cs.Id,
                    Type__c = 'WhatsApp',
                    Sent_Timestamp__c = System.now(),
                    Status__c = 'Pending',
                    Phone_Number__c = whatsappPhone,
                    Business_Partner__c = cs.AccountId,
                    Template_Name__c = smsConfig.Whatsapp_Template_Name__c,
                    Dynamic_Components__c = JSON.serialize(dynamicComponents)
                ));
            }
        }
    }

    // Bulk send SMS
    if (!smsDataList.isEmpty()) {
        sendBulkSms(smsDataList);
    }

    // Insert WhatsApp notifications
    if (!notificationsToInsert.isEmpty()) {
        insert notificationsToInsert;
    }
}

    public static List<Map<String, String>> extractDynamicComponents(String message, Map<String, String> mergeFields) {
        List<Map<String, String>> orderedComponents = new List<Map<String, String>>();
   
        if (String.isBlank(message)) return orderedComponents;
   
        Pattern tokenPattern = Pattern.compile('\\{!([^}]+)\\}');
        Matcher matcher = tokenPattern.matcher(message);
   
        while (matcher.find()) {
            String token = matcher.group(1);
            if (mergeFields.containsKey(token)) {
                orderedComponents.add(new Map<String, String>{ token => mergeFields.get(token) });
            }
        }
   
        return orderedComponents;
    }

    public static void validateCaseStatus(List<Case> newCases, Map<Id, Case> oldCasesMap) {
        Set<String> syncFields = new Set<String>{
            'Department__c','Category__c','Contact_Directions__c','Status','Sub_Type__c','IsClosed',
            'Customer_BP_Number__c','Contacted_By__c','Remarks__c','Created_Date__c','Created_Time__c',
            'Send_SMS_to__c','Account_email__c'
        };
        for(Case newcs : newCases){
            Case oldCase = oldCasesMap!= null?oldCasesMap.get(newcs.Id):null;
       
            if (oldCase != null && oldCase.Status == 'New' && newcs.Status != 'New'&&newcs.Created_Date_OLd__c==null) {
                newcs.NewAfter24hours__c = null;
                //newcs.NewAfter48hours__c = null;
            }
            Boolean needsSync = false;
          if(newcs.Created_Date_Old__c==null&&oldCase!=null){
            for (String f : syncFields) {
                Object oldVal = oldCase.get(f);
                Object newVal = newcs.get(f);

                if (oldVal != newVal) {
                    needsSync = true;
                    break;
                }
            }

             if (needsSync) {
                newcs.To_be_Updated_in_SAP__c  = 'true';
            }
if(newcs.Created_Date_Old__c==null&&Trigger.isInsert){
newcs.To_be_Updated_in_SAP__c  = 'true';
        }
}
        }
    }
   
   public static void sendCaseCreationSms(Set<Id> caseIds) {
        List<Case> casesList = [
            SELECT Id, CaseNumber, Send_SMS_to__c,Docket_Number__c,
                   AccountId, Account.Phone, Account.FirstName__c, Account.LastName__c, Account.Room__c, Account.Building_Name_Conn__c,New_Contact__c,
                   Lead__c, Lead__r.Phone, Lead__r.FirstName, Lead__r.LastName,Cheque_Number__c,Courier_Reference_Number__c,Refund_Amount__c,Bank_Name__c
            FROM Case
            WHERE Id IN :caseIds AND Created_Date_Old__c=null
        ];

        // SMS template from custom label
        String messageTemplate = System.Label.CaseCreationSMS;
        String templateid = System.Label.CaseCreationTempId;
        List<SmsData> smsDataList = new List<SmsData>(); // Bulk SMS collection

        for (Case cs : casesList) {
            Set<String> phoneNumbers = new Set<String>();

            // Add Account phone if present
            if (cs.Account != null && !String.isBlank(cs.Account.Phone)) {
                phoneNumbers.add(cs.Account.Phone);
            }

            // Add Lead phone if present and no Account
            if (cs.Account == null && cs.Lead__r != null && !String.isBlank(cs.Lead__r.Phone)) {
                phoneNumbers.add(cs.Lead__r.Phone);
            }

            // Add Send_SMS_to__c if manually specified
            if (!String.isBlank(cs.Send_SMS_to__c)) {
                phoneNumbers.add(cs.Send_SMS_to__c);
            }
            if (!String.isBlank(cs.New_Contact__c)) {
                phoneNumbers.add(cs.New_Contact__c);
            }

            // Skip if no numbers
            if (phoneNumbers.isEmpty()) continue;

            // Merge fields depending on source
            String firstName = '';
            String lastName = '';
            String flat = '';
            String building = '';
            String courierno = '';
            String flatbuilding = '';
            String banknames = '';
            String chequeno = '';
            String refundamt = '';

            if (cs.Account != null) {
                firstName = cs.Account.FirstName__c != null ? cs.Account.FirstName__c : '';
                lastName = cs.Account.LastName__c != null ? cs.Account.LastName__c : '';
                flat = cs.Account.Room__c != null ? cs.Account.Room__c : '';
                chequeno  = cs.Cheque_Number__c!= null ? cs.Cheque_Number__c : '';
                courierno = cs.Courier_Reference_Number__c != null ? cs.Courier_Reference_Number__c : '';
                refundamt = cs.Refund_Amount__c != null ? String.valueOf(cs.Refund_Amount__c) : '0';
                banknames = cs.Bank_Name__c != null ? cs.Bank_Name__c : '';
                building = cs.Account.Building_Name_Conn__c != null ? cs.Account.Building_Name_Conn__c : '';
            } else if (cs.Lead__r != null) {
                firstName = cs.Lead__r.FirstName != null ? cs.Lead__r.FirstName : '';
                lastName = cs.Lead__r.LastName != null ? cs.Lead__r.LastName : '';
                // No flat/building on Lead
            }

            Map<String, String> mergeFields = new Map<String, String>{
                'Name'         => (firstName + (lastName != '' ? ' ' + lastName : '')).trim(),
                'chequenumber' => chequeno,
                'courierrefno' => courierno,
                'refundamount' => refundamt,
                'flatname'     => flat,
                'buildingname' => building,
                'bankname'     => banknames,
                'address'         => (flat + (building != '' ? ' ' + building : '')).trim(),
                'CaseNumber'   => cs.Docket_Number__c != null ? cs.Docket_Number__c : ''
            };

            for (String phone : phoneNumbers) {
                // Add to bulk SMS list instead of individual calls
                if (phone.length() >= 10){
                smsDataList.add(new SmsData(
                    phone,
                    messageTemplate,
                    String.valueOf(cs.Id),
                    mergeFields,
                    templateid
                ));
                }
            }
        }

        // Send all SMS in bulk
        if (!smsDataList.isEmpty()) {
            sendBulkSms(smsDataList);
        }
    }

    private static Set<String> CHECKIN_FIELDS;
    private static Set<String> getCheckinFields() {
        if (CHECKIN_FIELDS == null) {
            CHECKIN_FIELDS = new Set<String>();
            String labelValue = System.Label.Case_Checkin_Fields;

            if (!String.isBlank(labelValue)) {
                // Support both comma and semicolon separators
                for (String f : labelValue.split('[,;]')) {
                    f = f.trim();
                    if (!String.isBlank(f)) {
                        CHECKIN_FIELDS.add(f);
                    }
                }
            }
        }
        return CHECKIN_FIELDS;
    }

    private static Boolean isFieldChanged(SObject oldRec, SObject newRec, String fieldApiName) {
        Object oldVal = oldRec.get(fieldApiName);
        Object newVal = newRec.get(fieldApiName);

        if (oldVal == null && newVal == null) {
            return false;
        }
        if (oldVal == null || newVal == null) {
            return true;
        }
        // Safe comparison via String
        return String.valueOf(oldVal) != String.valueOf(newVal);
    }

    public static void mapDepartmentAndSPOC(List<Case> caseList, String loggedInUserProfileName) {    
        Map<Id, Case> oldMap = Trigger.isUpdate ? (Map<Id, Case>) Trigger.oldMap : null;
        List<Case> filteredCases = new List<Case>();

        for (Case cs : caseList) {
            
            if (cs.Created_Date_OLd__c == null) {
                filteredCases.add(cs);
            }
        }

        if (filteredCases.isEmpty()) return;

        Id currentUserId = UserInfo.getUserId();
        //String profileName = [SELECT Profile.Name FROM User WHERE Id = :currentUserId].Profile.Name;

        // Get the configured fields that require check-in
        Set<String> checkinFields = getCheckinFields();

        // If there are no configured fields, nothing requires check-in
        if (checkinFields.isEmpty()) {
            return;
        }

        if (loggedInUserProfileName.contains('CRM')) {
            List<Attendance__c> att = [
                SELECT Id, Day_In_Timestamp__c, Day_Out_Timestamp__c
                FROM Attendance__c
                WHERE CreatedDate = TODAY AND CreatedById = :currentUserId
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
        
            List<Break__c> openBreaks = new List<Break__c>();
            if (!att.isEmpty()) {
                openBreaks = [
                    SELECT Id 
                    FROM Break__c
                    WHERE Attendance__c = :att[0].Id 
                    AND Break_End_Time__c = null
                    LIMIT 1
                ];
            }

            for (Case cs : filteredCases) {
                // Default: this record does NOT require check-in
                Boolean requiresCheckIn = false;

                if (oldMap != null &&
                    oldMap.containsKey(cs.Id) &&
                    oldMap.get(cs.Id).Bypass_Status_Validation__c == cs.Bypass_Status_Validation__c) {

                    // Only mark requiresCheckIn = true if any "check-in" field actually changed
                    for (String fieldApi : checkinFields) {
                        if (isFieldChanged(oldMap.get(cs.Id), cs, fieldApi)) {
                            requiresCheckIn = true;
                            break;
                        }
                    }
                }

                // For inserts (oldMap == null) or when no tracked field changed,
                // skip the check-in validation entirely.
                if (!requiresCheckIn) {
                    continue;
                }

                // Existing validation logic
                if (att.isEmpty() || att[0].Day_Out_Timestamp__c != null) {
                    cs.addError('You must be checked-in to update Case details.');
                }
                if (!openBreaks.isEmpty()) {
                    cs.addError('You are currently on a break. Please end your break to proceed.');
                }
            }
        }
    }

   
  /*public static void mapDepartmentAndSPOC(List<Case> caseList) {    
    Map<Id, Case> oldMap = Trigger.isUpdate ? (Map<Id, Case>) Trigger.oldMap : null;
    List<Case> filteredCases = new List<Case>();

    for (Case cs : caseList) {
        if (cs.Created_By__c == null) {
                cs.Created_By__c = UserInfo.getUserId();
            }
        if (cs.Created_Date_OLd__c == null) {
            filteredCases.add(cs);
        }
        }

    if (filteredCases.isEmpty()) return;

    Id currentUserId = UserInfo.getUserId();
    String profileName = [SELECT Profile.Name FROM User WHERE Id = :currentUserId].Profile.Name;
   
      if(profileName.contains('CRM')){
    List<Attendance__c> att = [
        SELECT Id, Day_In_Timestamp__c, Day_Out_Timestamp__c
        FROM Attendance__c
        WHERE CreatedDate = TODAY AND CreatedById = :currentUserId
        ORDER BY CreatedDate DESC
        LIMIT 1
    ];
   
    List<Break__c> openBreaks = new List<Break__c>();
    if (att.size() > 0) {
        openBreaks = [
            SELECT Id FROM Break__c
            WHERE Attendance__c = :att[0].Id AND Break_End_Time__c = null
            LIMIT 1
        ];
    }
    for (Case cs : filteredCases) {
if (
                oldMap != null &&
                oldMap.containsKey(cs.Id) &&
                oldMap.get(cs.Id).Bypass_Status_Validation__c == cs.Bypass_Status_Validation__c
            ) {            if (att.size() == 0 || att[0].Day_Out_Timestamp__c != null) {
                cs.addError('You must be checked-in to update Case details.');
            }
            if (!openBreaks.isEmpty()) {
                cs.addError('You are currently on a break. Please end your break to proceed.');
            }
        }
       
    }
      }
}*/
/*  
public static void mapDepartmentAndSPOC(List<Case> caseList) {    
    Map<Id, Case> oldMap = Trigger.isUpdate ? (Map<Id, Case>) Trigger.oldMap : null;
    List<Case> filteredCases = new List<Case>();

    for (Case cs : caseList) {
        if (cs.Created_By__c == null) {
                cs.Created_By__c = UserInfo.getUserId();
            }
        if (Trigger.isInsert && cs.Created_Date_OLd__c == null) {
            filteredCases.add(cs);
        } else if (Trigger.isUpdate && oldMap != null) {
            Case oldCase = oldMap.get(cs.Id);
            if (cs.Created_Date_OLd__c == null && (
                oldCase.AccountId != cs.AccountId ||
                oldCase.Category__c != cs.Category__c ||
                oldCase.Type__c != cs.Type__c ||
                oldCase.Sub_Type__c != cs.Sub_Type__c
            )) {
                filteredCases.add(cs);
            }
        }
    }

    if (filteredCases.isEmpty()) return;

    Id currentUserId = UserInfo.getUserId();
    String profileName = [SELECT Profile.Name FROM User WHERE Id = :currentUserId].Profile.Name;
   
    List<Attendance__c> att = [
        SELECT Id, Day_In_Timestamp__c, Day_Out_Timestamp__c
        FROM Attendance__c
        WHERE CreatedDate = TODAY AND CreatedById = :currentUserId
        ORDER BY CreatedDate DESC
        LIMIT 1
    ];
   
    List<Break__c> openBreaks = new List<Break__c>();
    if (att.size() > 0) {
        openBreaks = [
            SELECT Id FROM Break__c
            WHERE Attendance__c = :att[0].Id AND Break_End_Time__c = null
            LIMIT 1
        ];
    }
    for (Case cs : filteredCases) {
        if (profileName.contains('CRM')) {
            if (att.size() == 0 || att[0].Day_Out_Timestamp__c != null) {
                cs.addError('You must be checked-in to update Case details.');
            }
            if (!openBreaks.isEmpty()) {
                cs.addError('You are currently on a break. Please end your break to proceed.');
            }
        }
       
    }
}
*/
 
public static void handleTAT(List<Case> cases, Map<Id, Case> oldMap) {
   // BusinessHours bh1 = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1];

    for (Case c : cases) {
        Case oldC = oldMap != null ? oldMap.get(c.Id) : null;
       
        if (oldC !=null && oldC.Status != 'On Hold' && c.Status == 'On Hold') {
               c.IsStopped = true;
               c.On_Hold_Start__c = System.now();
               c.after_24_working_hours__c = System.now().addHours(24);
             
            }

            // Resume milestones if status changes from On Hold
            if (oldC !=null && oldC.Status == 'On Hold' && c.Status != 'On Hold') {
               c.IsStopped = false;
                c.On_Hold_Start__c = null;
                 c.after_24_working_hours__c =null;
            }
    }
}
   
public static void handleViolationCases(List<Case> newList, Map<Id, Case> oldMap) {

    /* ================= Category Picklist Label Mapping ================= */
    Map<String, String> categoryValueToLabelMap = new Map<String, String>();
    for (Schema.PicklistEntry pe : Case.Category__c.getDescribe().getPicklistValues()) {
        categoryValueToLabelMap.put(pe.getValue(), pe.getLabel());
    }

    /* ================= Priority Picklist Label Mapping ================= */
    Map<String, String> priorityValueToLabelMap = new Map<String, String>();
    for (Schema.PicklistEntry pe : Case.Priority.getDescribe().getPicklistValues()) {
        priorityValueToLabelMap.put(pe.getValue(), pe.getLabel());
    }

    /* ================= Identify Target Cases (Level 1 + BIS) ================= */
    Map<Id, Case> targetCases = new Map<Id, Case>();
    Set<Id> accountIds = new Set<Id>();

    for (Case cs : newList) {
        Case oldCs = oldMap.get(cs.Id);

        if (
            oldCs != null &&
            !oldCs.Case_Violation__c &&
            cs.Case_Violation__c &&
            cs.AccountId != null &&
            cs.Department__c == 'BIS' &&
            cs.Created_Date_OLd__c == null
        ) {
            targetCases.put(cs.Id, cs);
            accountIds.add(cs.AccountId);
        }
    }

    if (targetCases.isEmpty()) return;

    /* ================= Account Data ================= */
    Map<Id, Account> accountMap = new Map<Id, Account>(
        [SELECT Id, FirstName__c, LastName__c FROM Account WHERE Id IN :accountIds]
    );

    /* ================= SPOC Users ================= */
    Set<Id> spocIds = new Set<Id>();
    for (Case cs : targetCases.values()) {
        if (cs.SPOC__c != null) {
            spocIds.add(cs.SPOC__c);
        }
    }

    Map<Id, User> spocUserMap = new Map<Id, User>(
        [SELECT Id, Name, Email FROM User WHERE Id IN :spocIds]
    );

    /* ================= Org-Wide Email ================= */
    String fromEmail = System.Label.Escalation_Email_From_Address;
    OrgWideEmailAddress owea = [
        SELECT Id
        FROM OrgWideEmailAddress
        WHERE Address = :fromEmail
        LIMIT 1
    ];

    /* ================= Email Construction ================= */
    List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

    for (Case cs : targetCases.values()) {

        User spocUser = spocUserMap.get(cs.SPOC__c);
        if (spocUser == null || String.isBlank(spocUser.Email)) continue;

        Account acc = accountMap.get(cs.AccountId);

        String categoryLabel = categoryValueToLabelMap.containsKey(cs.Category__c)
            ? categoryValueToLabelMap.get(cs.Category__c)
            : cs.Category__c;

        String priorityLabel = priorityValueToLabelMap.containsKey(cs.Priority)
            ? priorityValueToLabelMap.get(cs.Priority)
            : cs.Priority;

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setOrgWideEmailAddressId(owea.Id);
        email.setToAddresses(new String[] { spocUser.Email });
        email.setWhatId(cs.Id);

        email.setSubject(
            'Reminder: Case ' + cs.Docket_Number__c + ' – TAT Breached'
        );

        /* ================= EMAIL BODY ================= */
        email.setHtmlBody(
            'Hello ' + spocUser.Name + ',<br/><br/>' +

            'This is an automated reminder to inform you that the following case ' +
            'has breached its defined TAT and requires immediate attention.<br/><br/>' +

            '<b>Details:</b><br/>' +
            'Case Number: ' + cs.Docket_Number__c + '<br/>' +
            'Type: ' + cs.Type__c + '<br/>' +
            'Priority: ' + priorityLabel + '<br/>' +
            'Created On: ' + cs.CreatedDate.format('dd/MM/yyyy hh:mm a') + '<br/>' +
            'Current Status: ' + cs.Status + '<br/><br/>' +

            '<b>Action Required:</b><br/>' +
            'Please review and take necessary action on this case at the earliest ' +
            'and update the status in Salesforce.<br/><br/>' +

            'Thank you for your cooperation.<br/><br/>' +
            'Regards,<br/>' +
            '<b>MGL-CRM</b>'
        );

        emails.add(email);
    }

    /* ================= Send Emails ================= */
    if (!emails.isEmpty()) {
        Messaging.sendEmail(emails);
    }
}



     @future
    public static void simpleUpdate(Set<Id> caseIds){
            List<Case> cs=[SELECT Id,Bypass_Status_Validation__c FROM Case WHERE Id In:caseIds];
            List<Case> res=new list<Case>();
            for(Case ins:cs){
                if(ins.Bypass_Status_Validation__c)
                ins.Bypass_Status_Validation__c=false;
                res.add(ins);
            }
            update res;
    }

    public static void handleDocumentsandOutstandingChanged(List<Case> newCases, Map<Id, Case> oldCaseMap) {
        Set<Id> caseIds = new Set<Id>();
        List<Case_Escalation__c> caseEscalations = new List<Case_Escalation__c>();
        List<Case> casesToUpdate = new List<Case>();
        Set<Id> casesForSAPCallout = new Set<Id>();
       
        for (Case newCase : newCases) {
            Case oldCase = oldCaseMap.get(newCase.Id);

            Boolean isOutstandingChanged =
                newCase.Outstanding_Payment_Cleared__c != oldCase.Outstanding_Payment_Cleared__c;
            Boolean isMoveOutChanged = newCase.Move_Out_Date__c != oldCase.Move_Out_Date__c;
           
            if (((isOutstandingChanged && newCase.Outstanding_Payment_Cleared__c) ||
                (isMoveOutChanged && newCase.Move_Out_Date__c != null))
            ) {
                casesForSAPCallout.add(newCase.Id);
            }
           
            // Name Transfer Request Status logic
            if (oldCase.Name_Transfer_Request_Status__c != newCase.Name_Transfer_Request_Status__c) {
                if (newCase.Name_Transfer_Request_Status__c == 'Approved') {
                    if (newCase.SPOC__c != null) {
                        Case caseUpdate = new Case(
                            Id = newCase.Id,
                            Status = 'In-Progress',
                            Current_Work_Type__c = '1',
                            OwnerId = newCase.SPOC__c,
                            Bypass_Status_Validation__c = true,
                            Assigned_To_Department__c = System.today(),
                            Latest_Assigned_to_Dept_Date__c = System.today()
                            //Assigned_to_department_time__c = System.now(),
                        );
                        casesToUpdate.add(caseUpdate);
                       
                        Case_Escalation__c escalation = new Case_Escalation__c(
                            Case__c = newCase.Id,
                            Escalation_Type__c = 'New',
                            Assigned_To_Department_1__c = System.today(),
                            Department_1__c = newCase.Department__c,
                            Is_Active__c = true
                        );
                        caseEscalations.add(escalation);
                    }
                }
                caseIds.add(newCase.Id);
            }
        }

        // Update cases and insert escalations first
        if (!casesToUpdate.isEmpty()) {
            update casesToUpdate;
        }
        if (!caseEscalations.isEmpty()) {
            insert caseEscalations;
        }

        // Call SMS and simple update
        if (!caseIds.isEmpty()) {
            callSMSClass(caseIds);
            simpleupdate(caseIds);
        }

        // Call the bulkified method
        if (!casesForSAPCallout.isEmpty()) {
            NameTransferUpdate.sendToSAPAsync(casesForSAPCallout);
        }
    }
public static void handleDuplicateCheck(List<Case> newCases,Map<Id, Case> oldCaseMap) {        
    Set<Id> accountIds = new Set<Id>();
    List<Case> casesToCheck = new List<Case>();
   
    for (Case c : newCases) {
    Case oldC = oldCaseMap != null ? oldCaseMap.get(c.Id) : null;

        // Base conditions
        Boolean baseCondition = (c.AccountId != null && c.Created_Date_Old__c == null);
        // Additional condition: old values blank → new values filled
        Boolean fieldChangeCondition = false;
        if (oldC != null) {
            fieldChangeCondition =
                (String.isBlank(oldC.Category__c) && !String.isBlank(c.Category__c));
        }

        if (baseCondition && fieldChangeCondition) {
            accountIds.add(c.AccountId);
            casesToCheck.add(c);
        }
    }
    if (casesToCheck.isEmpty()) {
        return;
    }

    List<Case> existingCases = [
        SELECT Id, AccountId, Category__c, Type__c, Sub_Type__c, Department__c,
               Value_1__c
        FROM Case
        WHERE AccountId IN :accountIds
        AND IsClosed = false
    ];

    // Create map for faster lookup
    Map<Id, List<Case>> accountToCasesMap = new Map<Id, List<Case>>();
    for (Case existing : existingCases) {
        if (!accountToCasesMap.containsKey(existing.AccountId)) {
            accountToCasesMap.put(existing.AccountId, new List<Case>());
        }
        accountToCasesMap.get(existing.AccountId).add(existing);
    }
    // Step 3: Prepare platform events
    List<DuplicateCaseEvent__e> eventsToPublish = new List<DuplicateCaseEvent__e>();

    // Step 4: Compare each incoming case with existing ones
    for (Case newCase : casesToCheck) {
        List<Case> accountExistingCases = accountToCasesMap.get(newCase.AccountId);
        if (accountExistingCases == null) continue;

        String newKey = getCompositeKey(newCase);
        for (Case existing : accountExistingCases) {
            if (existing.Id == newCase.Id) {
                continue;
            }

            String existingKey = getCompositeKey(existing);
            if (existingKey == newKey) {
                newCase.Is_Duplicate__c = true;
                eventsToPublish.add(new DuplicateCaseEvent__e(
                    CaseId__c = existing.Id,
                    Message__c = '⚠️ A duplicate Case already exists for this account.',
                    WarnOnly__c = true
                ));
            }
        }

    }

    // Step 5: Publish events
    if (!eventsToPublish.isEmpty()) {
        EventBus.publish(eventsToPublish);
    }
}

    private static String getCompositeKey(Case c) {
        return String.valueOf(c.Category__c) + '|' +
               String.valueOf(c.Type__c) + '|' +
               String.valueOf(c.Sub_Type__c) + '|' +
               String.valueOf(c.Department__c) + '|' +
               String.valueOf(c.Value_1__c);
    }
   
 public static void validateAndTransferInternalComments(List<Case> newCases, Map<Id, Case> oldMap, String loggedInUserProfileName) {
    //String profileName = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()].Name;

   Boolean isCRMUser = false;
    if (loggedInUserProfileName != null) {
        String lowerProfile = loggedInUserProfileName.toLowerCase();
        isCRMUser = lowerProfile == 'crm backoffice agent' ||
                    lowerProfile == 'crm callcenter agent' ||
                    lowerProfile == 'crm frontoffice agent' ||
            lowerProfile == 'crm call center teamlead';
    }

    for (Case newCase : newCases) {
        Case oldCase = oldMap.get(newCase.Id);

        // If Status has changed
        if (newCase.Status != oldCase.Status) {
            // Apply profile-based validation only for CRM users
            if (isCRMUser) {
               if ((newCase.Status == 'Assigned' || newCase.Status == 'In-Progress') &&
                         oldCase.Bypass_Status_Validation__c ==newCase.Bypass_Status_Validation__c ) {
                    newCase.addError('You are not allowed to perform this action');
                }
            }
        }
    }
}

   
public static void populateDocketNumber(List<Case> newCases) {
    List<Case> casesToUpdate = new List<Case>();
    Set<String> proposedDockets = new Set<String>();

    // Step 1: Build proposed docket numbers
    for (Case c : newCases) {
        if (String.isBlank(c.Docket_Number__c) && c.CaseNumber != null) {
            proposedDockets.add(c.CaseNumber);
        }
    }

    // Step 2: Query existing docket numbers to avoid duplicates
    Map<String, Id> existingDockets = new Map<String, Id>();
    if (!proposedDockets.isEmpty()) {
        for (Case existing : [
            SELECT Id, Docket_Number__c
            FROM Case
            WHERE Docket_Number__c IN :proposedDockets
        ]) {
            existingDockets.put(existing.Docket_Number__c, existing.Id);
        }
    }

    // Step 3: Prepare update list
    for (Case c : newCases) {
        if (String.isBlank(c.Docket_Number__c) && c.CaseNumber != null && !existingDockets.containsKey(c.CaseNumber)) {
            // --- Pad CaseNumber to 12 digits with leading zeros ---
            String paddedCaseNumber = padWithZeros(c.CaseNumber, 12);
           
            casesToUpdate.add(new Case(
                Id = c.Id,
                Docket_Number__c = paddedCaseNumber
            ));
        }
    }

    // Step 4: Perform update
    if (!casesToUpdate.isEmpty()) {
        update casesToUpdate;
    }
}

// Helper method to pad with leading zeros up to desired length
private static String padWithZeros(String input, Integer totalLength) {
    if (input == null) input = '';
    Integer pads = totalLength - input.length();
    if (pads <= 0) return input;
    String zeros = '';
    for (Integer i = 0; i < pads; i++) {
        zeros += '0';
    }
    return zeros + input;
}

    public static void SAPAutomations(List<Case> newList,Map<Id,Case> oldValues){
        for (Case c : newList) {
            if (c.Category__c == 'O') {
                c.Category__c = 'Q';
            }
            
            if (c.Customer_Information__c == null && c.Status__c == null) continue;

            String newStatus;

            if (c.Customer_Information__c != 'SL' &&
                c.Status__c != 'TSCO' &&
                c.Status__c != 'TSRL') {
                newStatus = 'In-Progress';
            } else if (c.Status__c == 'TSRL') {
                newStatus = 'Actioned By Department';
            } else if (c.Customer_Information__c == 'SL' ||
                       c.Status__c == 'TSCO') {
                newStatus = 'Resolved';
            }
if (
    newStatus != null &&
    c.Status != newStatus &&
    (
        Trigger.isInsert ||
        (
            oldValues != null && 
            (
                oldValues.get(c.Id).Customer_Information__c != c.Customer_Information__c ||
                oldValues.get(c.Id).Status__c != c.Status__c
            )
        )
    )
) {
                c.Status = newStatus;
            }
        }
    }
  public static void processCasesAfterUpdate(List<Case> newList, Map<Id, Case> oldMap) {
        Set<Id> caseIdsToProcess = new Set<Id>();
        for (Case cs : newList) {
            Case oldCs = oldMap.get(cs.Id);
            if (oldCs == null) continue;
            if (cs.Status == 'Actioned by Department' && cs.Created_Date_OLd__c==null
                && cs.Department__c == 'CRM'&&cs.Type__c!='Name Transfer Processed'
                && oldCs.Status != cs.Status) {
                caseIdsToProcess.add(cs.Id);
            }
        }

        if (!caseIdsToProcess.isEmpty()) {
            callSMSClass(caseIdsToProcess); // This now uses bulk SMS internally
        }
    }  
// Bulk SMS wrapper class to hold SMS data
  public class SmsData {
    public String mobileNumber;
    public String message;
    public String recordId;
    public Map<String, String> mergeFields;
    public String templateId;
   
    // Add this constructor
    public SmsData(String mobileNumber, String message, String recordId, Map<String, String> mergeFields, String templateId) {
        this.mobileNumber = mobileNumber;
        this.message = message;
        this.recordId = recordId;
        this.mergeFields = mergeFields;
        this.templateId = templateId;
    }
}   // Method to collect and send bulk SMS
    private static void sendBulkSms(List<SmsData> smsDataList) {
        if (smsDataList == null || smsDataList.isEmpty()) {
            return;
        }
       
        List<String> mobileNumbers = new List<String>();
        List<String> messages = new List<String>();
        List<String> recordIds = new List<String>();
        List<Map<String, String>> mergeFieldsList = new List<Map<String, String>>();
        List<String> templateIds = new List<String>();
       
        for (SmsData sms : smsDataList) {
            mobileNumbers.add(sms.mobileNumber);
            messages.add(sms.message);
            recordIds.add(sms.recordId);
            mergeFieldsList.add(sms.mergeFields != null ? sms.mergeFields : new Map<String, String>());
            templateIds.add(sms.templateId != null ? sms.templateId : '');
        }
       
        // Call bulk SMS API
        BulkSmsApiCallout.sendBulkSmsFuture(
            JSON.serialize(mobileNumbers),
            JSON.serialize(messages),
            JSON.serialize(recordIds),
            JSON.serialize(mergeFieldsList),
            JSON.serialize(templateIds)
        );
    }

public static void createWorkOrdersforOM(List<Case> newList, Map<Id, Case> oldMap) {

    if (newList == null || newList.isEmpty()) return;

    List<WorkOrder> workOrdersToInsert = new List<WorkOrder>();
    List<Case> casesToUpdate = new List<Case>();

    Set<Id> caseIds = new Set<Id>();
    Set<Id> accountIds = new Set<Id>();

    /* -------------------------------------------------
       STEP 1: Collect ONLY eligible cases
    ------------------------------------------------- */
    for (Case cs : newList) {
        caseIds.add(cs.Id);

        if (cs.AccountId != null) {
            accountIds.add(cs.AccountId);
        }
    }

    if (caseIds.isEmpty()) return;

    /* -------------------------------------------------
       STEP 2: Existing WorkOrders (prevent duplicates)
    ------------------------------------------------- */
    Set<Id> existingWOCaseIds = new Set<Id>();
    for (WorkOrder wo : [
        SELECT CaseId
        FROM WorkOrder
        WHERE CaseId IN :caseIds
    ]) {
        existingWOCaseIds.add(wo.CaseId);
    }

    /* -------------------------------------------------
       STEP 3: Account → Contact Map (Person Accounts)
    ------------------------------------------------- */
    Map<Id, Id> accountToContactMap = new Map<Id, Id>();
    if (!accountIds.isEmpty()) {
        for (Account acc : [
            SELECT Id, PersonContactId
            FROM Account
            WHERE Id IN :accountIds
        ]) {
            if (acc.PersonContactId != null) {
                accountToContactMap.put(acc.Id, acc.PersonContactId);
            }
        }
    }

    /* -------------------------------------------------
       STEP 4: WorkOrder Record Type
    ------------------------------------------------- */
    Id woRecordTypeId = Schema.SObjectType.WorkOrder
        .getRecordTypeInfosByDeveloperName()
        .get('MGL_O_M')
        .getRecordTypeId();

    /* -------------------------------------------------
       STEP 5: WorkType Map
    ------------------------------------------------- */
    Map<String, Id> workTypeMap = new Map<String, Id>();
    for (WorkType wt : [
        SELECT Id, Name
        FROM WorkType
        WHERE Name IN (
            'Individual Permanent Disconnection',
            'Rubber Hose Replacement',
            'Domestic Meter Checking',
            'Meter Replacement',
            'After Sales Service'
        )
    ]) {
        workTypeMap.put(wt.Name, wt.Id);
    }

    /* -------------------------------------------------
       STEP 6: Main Logic
    ------------------------------------------------- */
    for (Case cs : newList) {

        if (existingWOCaseIds.contains(cs.Id)) continue;
        if (cs.Category__c == 'Q') continue;
        if (cs.Department__c == null && (oldMap == null || oldMap.get(cs.Id).Category__c != null)) continue;

        String workTypeName;

        switch on cs.Sub_Type__c {
            when 'Individual Permanent Disconnection & Refund Processing' {
                workTypeName = 'Individual Permanent Disconnection';
            }
            when 'Old Meter Replacement' {
                workTypeName = 'Meter Replacement';
            }
            when else {
                continue;
            }
        }

        Id workTypeId = workTypeMap.get(workTypeName);
        if (workTypeId == null) continue;

        workOrdersToInsert.add(new WorkOrder(
            Subject        = 'Work Order for Case ' + cs.CaseNumber,
            CaseId         = cs.Id,
            AccountId      = cs.AccountId,
            ContactId      = accountToContactMap.get(cs.AccountId),
            Department__c = (cs.Sub_Type__c == 'Rubber Tube') ? null : 'O&M',
            WorkTypeId     = workTypeId,
            RecordTypeId   = woRecordTypeId,
            Status         = 'New',
            Case_Remark__c = cs.Remarks__c
        ));

        casesToUpdate.add(new Case(
            Id = cs.Id,
            O_M_Assigned_Case_Status__c = 'In Progress'
        ));
    }

    /* -------------------------------------------------
       STEP 7: DML
    ------------------------------------------------- */
    if (!workOrdersToInsert.isEmpty()) {
        insert workOrdersToInsert;
    }

    if (!casesToUpdate.isEmpty()) {
        update casesToUpdate;
    }
}


// public static void createWorkOrdersforOM(List<Case> newList, Map<Id, Case> oldMap) {
//     List<WorkOrder> workOrdersToInsert = new List<WorkOrder>();
//     List<Case> casesToUpdate = new List<Case>();
//     // Get Work Order Record Type
//     Id woRecordTypeId;
//     try {
//         woRecordTypeId = Schema.SObjectType.WorkOrder
//             .getRecordTypeInfosByDeveloperName()
//             .get('MGL_O_M')
//             .getRecordTypeId();
//     } catch (Exception e) {
//         return;
//     }

//     // Preload WorkType mapping
//     Map<String, Id> workTypeMap = new Map<String, Id>();
//     for (WorkType wt : [
//         SELECT Id, Name
//         FROM WorkType
//         WHERE Name IN ('Individual Permanent Disconnection', 'Rubber Hose Replacement', 'Domestic Meter Checking','Meter Replacement','After Sales Service')
//     ]) {
//         workTypeMap.put(wt.Name, wt.Id);
//     }

//     // Prevent duplicate WOs for same Case
//     Set<Id> caseIds = new Set<Id>();
//     for (Case cs : newList) {
//         if (cs.Id != null) caseIds.add(cs.Id);
//     }

//     Set<Id> existingWOCaseIds = new Set<Id>();
//     if (!caseIds.isEmpty()) {
//         for (WorkOrder wo : [SELECT CaseId FROM WorkOrder WHERE CaseId IN :caseIds]) {
//             existingWOCaseIds.add(wo.CaseId);
//         }
//     }

//     // Main logic
//     for (Case cs : newList) {
//         if (existingWOCaseIds.contains(cs.Id)) continue;

//         Boolean shouldCreateWO = false;

//         // Create WO only if Department__c not null and not Category 'Q'
//         if (cs.Department__c != null && cs.Category__c != 'Q') {
//             shouldCreateWO = true;
//         } else if (oldMap != null && oldMap.containsKey(cs.Id)) {
//             Case oldCs = oldMap.get(cs.Id);
//             if (oldCs.Category__c == null && cs.Category__c != null && cs.Category__c != 'Q') {
//                 shouldCreateWO = true;
//             }
//         }

//         if (!shouldCreateWO) continue;

//         // Map subtype to WorkType name
//         String workTypeName;
//         /*switch on cs.Department__c{
//             when 'AFTER SALES'{
//                 workTypeName ='After Sales Service';
//             }
//         }*/
//         switch on cs.Sub_Type__c {
//             when 'Individual Permanent Disconnection & Refund Processing' {
//                 workTypeName = 'Individual Permanent Disconnection';
//             }
//             /*when 'Rubber Tube' {
//                 workTypeName = 'Rubber Hose Replacement';
//             }
//             when 'Meter Checking' {
//                workTypeName = 'Domestic Meter Checking';
//             }*/
//             when 'Old Meter Replacement'{
//                 workTypeName = 'Meter Replacement';
//             }
//         }

//         Id workTypeId = workTypeMap.get(workTypeName);
//         if (workTypeId == null) {
//             continue;
//         }

//         // Create WorkOrder
//         WorkOrder wo = new WorkOrder(
//             Subject = 'Work Order for Case ' + cs.CaseNumber,
//             CaseId = cs.Id,
//             AccountId = cs.AccountId,
//             Department__c = (cs.Sub_Type__c == 'Rubber Tube') ? null : 'O&M',
//             WorkTypeId = workTypeId,
//             RecordTypeId = woRecordTypeId,
//             Status = 'New',
//             Case_Remark__c=cs.Remarks__c
//         );
//         /*if(cs.Sub_Type__c=='Rubber Tube'){
//             wo.Sub_Type__c='Customer Complaints';
//         }*/

//         workOrdersToInsert.add(wo);
//       // Prepare Case update (mark as In Progress)
//         Case updateCase = new Case(
//             Id = cs.Id,
//             O_M_Assigned_Case_Status__c = 'In Progress'
//         );
//         casesToUpdate.add(updateCase);
//     }


//     // Insert final list
//     if (!workOrdersToInsert.isEmpty()) {
//         insert workOrdersToInsert;
//          if (!casesToUpdate.isEmpty()) {
//             update casesToUpdate;
//         }
//     } else {
//     }
// }


 public static void updateSalutationValues(List<Case> newCases) {
        Set<String> salutationLabels = new Set<String>();

        // Collect all entered salutations
        for (Case c : newCases) {
            if (!String.isBlank(c.New_Salutation__c)) {
                salutationLabels.add(c.New_Salutation__c.trim());
            }
        }

        if (salutationLabels.isEmpty()) return;

        // Query Custom Metadata where Label__c matches entered salutation
        Map<String, Case_New_Salutation__mdt> metaMap = new Map<String, Case_New_Salutation__mdt>();
        for (Case_New_Salutation__mdt meta : [
            SELECT Label__c, API_Name__c
            FROM Case_New_Salutation__mdt
            WHERE Label__c IN :salutationLabels
        ]) {
            metaMap.put(meta.Label__c, meta);
        }

        // Replace label value with API Name in Case record
        for (Case c : newCases) {
            if (!String.isBlank(c.New_Salutation__c) && metaMap.containsKey(c.New_Salutation__c)) {
                c.New_Salutation__c = metaMap.get(c.New_Salutation__c).API_Name__c;
            }
        }
    }
  public static void handleFRLSentUpdate(List<Case> newList, Map<Id, Case> oldMap) {
    if (newList == null || newList.isEmpty()) {
        return;
    }

    // Proceed only if oldMap is available (before update context)
    if (oldMap == null || oldMap.isEmpty()) {
        return;
    }

    for (Case cs : newList) {
        if (cs == null || !oldMap.containsKey(cs.Id)) {
            continue;
        }

        Case oldCs = oldMap.get(cs.Id);
        if (oldCs == null) {
            continue;
        }

        // Check if FRL__c changed from false → true
        if (oldCs.FRL__c == false && cs.FRL__c == true) {
            cs.FRL_Sent_Date__c = Date.today(); // Use DateTime.now() if you need timestamp
            cs.FRL_Sent_By__c = UserInfo.getUserId();
        }
    }
}
// public static void updateCustomerRespondedDate(List<Case> newCases, Map<Id, Case> oldMap) {
//     for (Case newCase : newCases) {
//         Case oldCase = oldMap.get(newCase.Id);
       
//         // Check if status changed to "Customer Responded"
//         if (oldCase != null &&
//             oldCase.Status != 'Customer Responded' &&
//             newCase.Status == 'Customer Responded' &&
//             newCase.Customer_Responded_On_Dtae__c == null) {
           
//             newCase.Customer_Responded_On_Dtae__c = System.now();
//         }
//     }
// }
// 

    public static void ccSLAForOwnerChange(List<Case> newList, Map<Id, Case> oldMap) {
        createCallCenterSLAForOwnerChange(newList, oldMap);
    }

    private static void createCallCenterSLAForOwnerChange(List<Case> newList, Map<Id, Case> oldMap) {
        List<Call_Center_SLA__c> slasToInsert = new List<Call_Center_SLA__c>();
    
        // 1) Collect all owner Ids (old + new) where owner actually changed
        Set<Id> ownerIds = new Set<Id>();
        for (Case cs : newList) {
            Case oldCs = oldMap.get(cs.Id);
            if (oldCs == null) continue;
    
            if (cs.OwnerId != oldCs.OwnerId && cs.OwnerId != null) {
                ownerIds.add(cs.OwnerId);
                ownerIds.add(oldCs.OwnerId);
            }
        }
    
        if (ownerIds.isEmpty()) {
            return;
        }
    
        // 2) Query User and Group (Owner can be User or Queue)
        Map<Id, String> ownerNames = new Map<Id, String>();
        // Keep track of which User Ids are CRM CallCenter Agents
        Set<Id> callCenterAgentUserIds = new Set<Id>();
    
        // 3) Build SLA records ONLY when new owner is CRM CallCenter Agent
        for (Case cs : newList) {
            Case oldCs = oldMap.get(cs.Id);
            if (oldCs == null) continue;
    
            // owner changed AND new owner is a CRM CallCenter Agent user
            if (cs.OwnerId != oldCs.OwnerId &&
                cs.OwnerId != null &&
                cs.Case_Owner_Profile_Name__c=='CRM CallCenter Agent') {
    
                DateTime nowDt = System.now();
                Call_Center_SLA__c sla = new Call_Center_SLA__c();
                sla.Case__c              = cs.Id;
                sla.Call_Center_Agent__c = cs.OwnerId;
                sla.Created_Date__c      = nowDt.date();
                sla.Created_Time__c      = nowDt.time();
                sla.Activity__c='Assigned';
                sla.Department_Responded_On__c=cs.Department_Responded_On__c;
                slasToInsert.add(sla);
            }
        }
    
        if (!slasToInsert.isEmpty()) {
            insert slasToInsert;
        }
    }
    
    public static void convertNameTransferFieldsToUpper(List<Case> caseList) {
        if (caseList == null || caseList.isEmpty()) {
            return;
        }

        for (Case c : caseList) {
            if (c == null) continue;

            if (c.Created_By__c == null) {
                c.Created_By__c = UserInfo.getUserId();
            }

            // New First Name
            if (String.isNotBlank(c.New_First_Name__c)) {
                c.New_First_Name__c = c.New_First_Name__c.toUpperCase();
            }
            // New Middle Name
            if (String.isNotBlank(c.New_Middle_Name__c)) {
                c.New_Middle_Name__c = c.New_Middle_Name__c.toUpperCase();
            }
            // New Last Name
            if (String.isNotBlank(c.New_Last_Name__c)) {
                c.New_Last_Name__c = c.New_Last_Name__c.toUpperCase();
            }
        }
    }


    
    
public static void handleContactDetailsUpdateToSAP(List<Case> newCases, Map<Id, Case> oldMap) {

    Set<Id> casesForSAPCallout = new Set<Id>();
    
    for (Case newCase : newCases) {
        
        Case oldCase = oldMap != null ? oldMap.get(newCase.Id) : null;
        
        // For INSERT - if case is created as contact update with contact data
        if (oldCase == null) {
            
            Boolean isContactUpdateCase = (
                (newCase.Type__c     == 'Customer Contact Details - Update' || newCase.Type__c == 'Name Correction') &&
                (newCase.Sub_Type__c == 'Email Address' ||
                 newCase.Sub_Type__c == 'Mobile No' ||
                 newCase.Sub_Type__c == 'Mobile No & Email Address' ||
                 newCase.Sub_Type__c == 'Name Correction' ||
                 newCase.Sub_Type__c == 'Name Correction - Title Error') &&
                (!String.isBlank(newCase.New_Contact__c) || 
                 !String.isBlank(newCase.New_email_id__c) || 
                 !String.isBlank(newCase.New_First_Name__c) || 
                 !String.isBlank(newCase.New_Middle_Name__c) || 
                 !String.isBlank(newCase.New_Last_Name__c)||
                 !String.isBlank(newCase.New_Salutation__c))
            );
            
            Boolean hasContactData = (!String.isBlank(newCase.New_Contact__c) || 
                                     !String.isBlank(newCase.New_email_id__c) || 
                                     !String.isBlank(newCase.New_First_Name__c) || 
                                     !String.isBlank(newCase.New_Middle_Name__c) || 
                                     !String.isBlank(newCase.New_Last_Name__c) ||
                                     !String.isBlank(newCase.New_Salutation__c));
            
            if (isContactUpdateCase) {
                casesForSAPCallout.add(newCase.Id);
            } else {
            }
        }
        // For UPDATE - when Type/SubType are changed TO contact update values with contact data
        else if (oldCase != null) {
            
            Boolean becameContactUpdateCase = (
                // Type changed to contact update
                (
                    (oldCase.Type__c != 'Customer Contact Details - Update' && newCase.Type__c == 'Customer Contact Details - Update') ||
                    (oldCase.Type__c != 'Name Correction' && newCase.Type__c == 'Name Correction')
                ) ||
                // SubType changed to contact update values
                (oldCase.Sub_Type__c != newCase.Sub_Type__c &&
                 (newCase.Sub_Type__c == 'Email Address' ||
                  newCase.Sub_Type__c == 'Mobile No' ||
                  newCase.Sub_Type__c == 'Mobile No & Email Address' ||
                  newCase.Sub_Type__c == 'Name Correction' ||
                  newCase.Sub_Type__c == 'Name Correction - Title Error'))
            );
            
            
            Boolean hasContactData = (!String.isBlank(newCase.New_Contact__c) || 
                                     !String.isBlank(newCase.New_email_id__c) || 
                                     !String.isBlank(newCase.New_First_Name__c) || 
                                     !String.isBlank(newCase.New_Middle_Name__c) || 
                                     !String.isBlank(newCase.New_Last_Name__c) ||
                                     !String.isBlank(newCase.New_Salutation__c));
            
            if (becameContactUpdateCase && hasContactData) {
                casesForSAPCallout.add(newCase.Id);
            }
        }
    }
    
    
    // Call SAP integration for eligible cases
    if (!casesForSAPCallout.isEmpty()) {
        NameTransferUpdate.sendToSAPAsync(casesForSAPCallout);
    } 
}

    public static void blockRecentNameCorrectionCases(List<Case> newCases, String loggedInUserProfileName) {
        Set<Id> accountIds = new Set<Id>();
        Map<Id, List<Case>> accountToNewCases = new Map<Id, List<Case>>();

        for (Case c : newCases) {

            if (
                c.AccountId != null &&
                c.Department__c == 'CRM' &&
                c.Category__c=='S' &&
                c.Type__c == 'Name Correction' &&
                (
                    c.Sub_Type__c == 'Name Correction' ||
                    c.Sub_Type__c == 'Name Correction - Title Error'
                )
            ) {

                accountIds.add(c.AccountId);

                if (!accountToNewCases.containsKey(c.AccountId)) {
                    accountToNewCases.put(c.AccountId, new List<Case>());
                }
                accountToNewCases.get(c.AccountId).add(c);
            }
        }

        if (accountIds.isEmpty()) {
            return;
        }
        //User loggedInUser =[SELECT Id,Profile_Name__c FROM User WHERE Id=:UserInfo.getUserId()];
        if(loggedInUserProfileName=='CRM Front Office TeamLead'){
            return;
        }
        Date sixMonthsAgo = System.today().addMonths(-6);
       
        Set<Id> currentCaseIds = new Set<Id>();
        for (Case c : newCases) {
            if (c.Id != null) {
                currentCaseIds.add(c.Id);
            }
        }   

        List<Case> recentCases = [
            SELECT Id, AccountId, CreatedDate
            FROM Case
            WHERE AccountId IN :accountIds
            AND Department__c = 'CRM'
            AND Type__c = 'Name Correction'
            AND Category__c ='S'
            AND Sub_Type__c IN ('Name Correction', 'Name Correction - Title Error')
            AND CreatedDate >= :sixMonthsAgo
            AND Id NOT IN :currentCaseIds
        ];

        
        Map<Id, Integer> accountToRecentCount = new Map<Id, Integer>();
        for (Case c : recentCases) {
            accountToRecentCount.put(
                c.AccountId,
                (accountToRecentCount.containsKey(c.AccountId)
                    ? accountToRecentCount.get(c.AccountId)
                    : 0
                ) + 1
            );
        }

        for (Id accId : accountToNewCases.keySet()) {

            Integer recentCount = accountToRecentCount.containsKey(accId)
                ? accountToRecentCount.get(accId)
                : 0;

           

            // Block
            if (recentCount > 0) {


                for (Case c : accountToNewCases.get(accId)) {
                    c.addError(
                        'A Name Correction case already exists for this Business Partner within the last 6 months.'
                    );
                }

            }
        }

    }

    public static void setStatusForAMRUpdate(List<Case> newCases) {

        for (Case cs : newCases) {
            if (cs == null) continue;

            // Apply only on insert
            if (
                cs.Department__c == 'CRM' &&
                cs.Category__c == 'S' &&
                cs.Type__c == 'AMR Update by CRM' 
            ) {
                cs.Status = 'Resolved';
            }
        }
    }


public static void captureViolationTimestamps(
    List<Case> newList,
    Map<Id, Case> oldMap
) {
    DateTime nowDt = System.now();

    for (Case c : newList) {
        Case oldC = oldMap != null ? oldMap.get(c.Id) : null;
        if (oldC == null) continue;

        // Violation 0 → Time 1
        if (!oldC.Case_Violation__c &&
             c.Case_Violation__c &&
             c.Case_Violation_Time_1__c == null) {
            c.Case_Violation_Time_1__c = nowDt;
        }

        // Violation 1 → Time 2
        if (!oldC.Case_Violation1__c &&
             c.Case_Violation1__c &&
             c.Case_Violation_Time_2__c == null) {
            c.Case_Violation_Time_2__c = nowDt;
        }

        // Violation 2 → Time 3
        if (!oldC.Case_Violation2__c &&
             c.Case_Violation2__c &&
             c.Case_Violation_Time_3__c == null) {
            c.Case_Violation_Time_3__c = nowDt;
        }

        // Violation 3 → Time 4
        if (!oldC.Case_Violation3__c &&
             c.Case_Violation3__c &&
             c.Case_Violation_Time_4__c == null) {
            c.Case_Violation_Time_4__c = nowDt;
        }

        // Violation 4 → Time 5
        if (!oldC.Case_Violation4__c &&
             c.Case_Violation4__c &&
             c.Case_Violation_Time_5__c == null) {
            c.Case_Violation_Time_5__c = nowDt;
        }
    }
}


// public static void mapBulkInsertValues(List<Case> newCases) {

//     if (newCases == null || newCases.isEmpty()) return;

//     /* ------------------------------------
//        1. Collect BP Numbers
//     ------------------------------------ */
//     Set<String> bpNumbers = new Set<String>();
//     for (Case c : newCases) {
//         if (c.AccountId == null && !String.isBlank(c.BP_Number__c)) {
//             bpNumbers.add(c.BP_Number__c.trim());
//         }
//     }

//     /* ------------------------------------
//        2. BP → AccountId (SINGLE SOQL)
//     ------------------------------------ */
//     Map<String, Id> bpToAccountId = new Map<String, Id>();
//     if (!bpNumbers.isEmpty()) {
//         for (Account acc : [
//             SELECT Id, BP_Number__c
//             FROM Account
//             WHERE BP_Number__c IN :bpNumbers
//         ]) {
//             bpToAccountId.put(acc.BP_Number__c, acc.Id);
//         }
//     }

//     /* ------------------------------------
//        3. Picklist LABEL → VALUE maps
//           (Describe only, NO SOQL)
//     ------------------------------------ */
//     Map<String, String> categoryMap  =
//         getPicklistLabelToValueMap(Case.Category__c);

//     Map<String, String> originMap    =
//         getPicklistLabelToValueMap(Case.Origin);

//     Map<String, String> directionMap =
//         getPicklistLabelToValueMap(Case.Contact_Directions__c);

//     Map<String, String> priorityMap  =
//         getPicklistLabelToValueMap(Case.Priority);

//     /* ------------------------------------
//        4. Apply mappings
//     ------------------------------------ */
//     for (Case c : newCases) {

//         /* BP → Account */
//         if (c.AccountId == null && !String.isBlank(c.BP_Number__c)) {
//             if (!bpToAccountId.containsKey(c.BP_Number__c)) {
//                 c.addError(
//                     'No Account found for BP Number: ' + c.BP_Number__c
//                 );
//                 continue;
//             }
//             c.AccountId = bpToAccountId.get(c.BP_Number__c);
//         }

//         /* Category (HARDCODED: TEXT label → PICKLIST API value) */
//         if (!String.isBlank(c.Category__c)) {

//             String categoryLabel = c.Category__c.trim().toLowerCase();

//             if (categoryLabel == 'request') {
//                 c.Category__c = 'S';
//             }
//             else if (categoryLabel == 'complaint') {
//                 c.Category__c = 'C';
//             }
//             // else if (categoryLabel == 'query') {
//             //     c.Category__c = 'Q';
//             // }
//         }



//         System.debug(
//             'BEFORE INSERT FINAL | Category__c = ' + c.Category__c
//         );



//         /* Origin (TEXT → PICKLIST) */
//         if (!String.isBlank(c.Origin__c) &&
//             originMap.containsKey(c.Origin__c)) {

//             c.Origin =
//                 originMap.get(c.Origin__c);
//         }

//         /* Contact Direction (TEXT → PICKLIST) */
//         if (!String.isBlank(c.Contact_Direction__c) &&
//             directionMap.containsKey(c.Contact_Direction__c)) {

//             c.Contact_Directions__c =
//                 directionMap.get(c.Contact_Direction__c);
//         }

//         /* Priority (TEXT → PICKLIST) */
//         if (!String.isBlank(c.Priority__c) &&
//             priorityMap.containsKey(c.Priority__c)) {

//             c.Priority =
//                 priorityMap.get(c.Priority__c);
//         }

//     }
// }

    private static Map<String, String>
    getPicklistLabelToValueMap(Schema.SObjectField fieldRef) {

            Map<String, String> labelToValue = new Map<String, String>();

            for (Schema.PicklistEntry pe :
                fieldRef.getDescribe().getPicklistValues()) {
                labelToValue.put(pe.getLabel(), pe.getValue());
            }
            return labelToValue;
        }

    


    


=======
>>>>>>> e604021b64f33882bfed07c2bfed265ad53326cf
}