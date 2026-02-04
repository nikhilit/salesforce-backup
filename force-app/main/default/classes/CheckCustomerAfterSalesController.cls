public without sharing class CheckCustomerAfterSalesController {

    /* =========================================================
       UPDATE WORK ORDER (Customer Availability = Yes)
       ========================================================= */
    @AuraEnabled
    public static void updateWorkOrder(String recordId, String customerAvailability) {

        WorkOrder wo = [
            SELECT Id, Check_Customer_Availability__c
            FROM WorkOrder
            WHERE Id = :recordId
            LIMIT 1
        ];

        wo.Check_Customer_Availability__c = customerAvailability;
        update wo;

       // updateWorkStepStatus(recordId, 'Check Customer Availability');

       List<WorkStep> steps = [
        SELECT Id, Status
        FROM WorkStep
        WHERE ParentRecordId = :recordId
          AND Name = 'Check Customer Availability'
        LIMIT 1
    ];

    if (!steps.isEmpty()) {
        WorkStep ws = steps[0];
        ws.Status = 'Completed';
        update ws;
    }

    }

    /* =========================================================
       UPDATE WORK STEP STATUS
       ========================================================= */
    

    /* =========================================================
       CHECK CHECK-IN WORK STEP STATUS
       ========================================================= */
    @AuraEnabled
    public static String checkWorkStepCheckin(String recordId) {
        try {
            WorkStep worStep = [
                SELECT Id, Status, Name
                FROM WorkStep
                WHERE ParentRecordId = :recordId
                  AND Name = 'Check-in'
                LIMIT 1
            ];

            return worStep.Status;

        } catch (Exception e) {
            System.debug('Error in checkWorkStepCheckin: ' + e.getMessage());
            return 'Error';
        }
    }

    /* =========================================================
       GET WORK ORDER WORK TYPE
       ========================================================= */
    @AuraEnabled
    public static String getWOrderWType(String recordId) {
        try {
            WorkOrder wOrder = [
                SELECT Id, WorkType.Name
                FROM WorkOrder
                WHERE Id = :recordId
                LIMIT 1
            ];

            return wOrder.WorkType.Name;

        } catch (Exception e) {
            System.debug('Error in getWOrderWType: ' + e.getMessage());
            return 'Error';
        }
    }

    /* =========================================================
       SUBMIT UNSUCCESSFUL VISIT
       ========================================================= */
   @AuraEnabled
public static void submitUnsuccessfulVisit(
    String workOrderId,
    String reason,
    String notes,
    Date followUpDate,
    List<FileWrapper> listFiles
) {
    try {

         List<WorkStep> steps = [
            SELECT Id, Status
            FROM WorkStep
            WHERE ParentRecordId = :workOrderId
              AND Name = 'Check Customer Availability'
            LIMIT 1
        ];

        if (!steps.isEmpty()) {
            WorkStep ws = steps[0];
            ws.Status = 'Completed';
            update ws;
        }

        // 🔹 Fetch parent Work Order
        WorkOrder wOrder = [
            SELECT Id,
                   Reason_ForUnavilability__c,
                   Reason_Other_Remark__c,
                   Check_Customer_Availability__c,
                   Follow_Up_Appointment_Date__c,
                   CaseId,
                   AccountId,
                   WorkTypeId,
                   RecordTypeId,
                   Department__c,
                   WorkType.Name,
				   Agent__c,
				   OwnerId,
				   ServiceTerritoryId,
                   Appointment_Status__c 
            FROM WorkOrder
            WHERE Id = :workOrderId
            LIMIT 1
        ];

        // 🔹 Update parent WO
        wOrder.Reason_ForUnavilability__c = reason;
        wOrder.Reason_Other_Remark__c = notes;
        wOrder.Check_Customer_Availability__c = 'No';
        wOrder.Follow_Up_Appointment_Date__c = followUpDate;

        if (reason == 'Customer Not Interested') {
    wOrder.Appointment_Status__c = 'Completed';
     }
        update wOrder;

        System.debug('Updated parent WorkOrder :: ' + wOrder);

        // =========================================================
// 🆕 UPDATE CASE (ONLY FOR CUSTOMER NOT INTERESTED)
// =========================================================
if (reason == 'Customer Not Interested' && wOrder.CaseId != null) {

    Case cs = [
        SELECT Id, Status, Standard_Remarks__c
        FROM Case
        WHERE Id = :wOrder.CaseId
        LIMIT 1
    ];

    cs.Status = 'Actioned by Department';
    cs.Standard_Remarks__c = notes;

    update cs;

    System.debug('✅ Case updated for Customer Not Interested :: ' + cs.Id);
}


        // =========================================================
        // 🆕 CREATE CHILD WORK ORDER (ONLY FOR HOUSE LOCK)
        // =========================================================
        if (reason == 'House Lock') {


			Id derivedOwnerId;

    // 🔹 If Agent exists on parent → derive Owner from ServiceResource
    if (wOrder.Agent__c != null) {

        ServiceResource sr = [
            SELECT Id, RelatedRecordId
            FROM ServiceResource
            WHERE Id = :wOrder.Agent__c
            LIMIT 1
        ];

        derivedOwnerId = sr.RelatedRecordId;
    }


            WorkOrder childWO = new WorkOrder();
            childWO.ParentWorkOrderId = wOrder.Id;
            childWO.CaseId = wOrder.CaseId;
            childWO.AccountId = wOrder.AccountId;
            childWO.WorkTypeId = wOrder.WorkTypeId;
            childWO.RecordTypeId = wOrder.RecordTypeId;
           // childWO.Department__c = wOrder.Department__c;
			//childWO.OwnerId = wOrder.OwnerId;
			childWO.Agent__c = wOrder.Agent__c;
			childWO.Agent__c = wOrder.Agent__c;
			childWO.ServiceTerritoryId = wOrder.ServiceTerritoryId;
            childWO.Reason_Other_Remark__c = wOrder.Reason_ForUnavilability__c;



			if (derivedOwnerId != null) {
        childWO.OwnerId = derivedOwnerId;
    }


            insert childWO;

            System.debug('Child WorkOrder created :: ' + childWO.Id);
			System.debug('Child WorkOrder owner id :: ' + childWO.OwnerId);
			System.debug('Parent WorkOrder owner id :: ' + wOrder.OwnerId);
			
			// =========================================================
// 🔁 SYNC CHILD SERVICE APPOINTMENT FROM PARENT
// =========================================================

// 1️⃣ Get parent Service Appointment
List<ServiceAppointment> parentSAList = [
    SELECT Id, SchedStartTime, SchedEndTime, Status
    FROM ServiceAppointment
    WHERE ParentRecordId = :wOrder.Id
    ORDER BY CreatedDate ASC
    LIMIT 1
];

if (!parentSAList.isEmpty()) {

    ServiceAppointment parentSA = parentSAList[0];

    // 2️⃣ Get child Service Appointment (auto-created)
    List<ServiceAppointment> childSAList = [
        SELECT Id, SchedStartTime, SchedEndTime, Status
        FROM ServiceAppointment
        WHERE ParentRecordId = :childWO.Id
        ORDER BY CreatedDate ASC
        LIMIT 1
    ];

    if (!childSAList.isEmpty()) {

        ServiceAppointment childSA = childSAList[0];

        // 3️⃣ Copy schedule fields
        // childSA.SchedStartTime = parentSA.SchedStartTime;
        // childSA.SchedEndTime   = parentSA.SchedEndTime;

        // update childSA;
        // 3️⃣ Set schedule fields from Follow-Up Appointment Date
if (wOrder.Follow_Up_Appointment_Date__c != null) {

   DateTime followUpStartDT = wOrder.Follow_Up_Appointment_Date__c;
    DateTime followUpEndDT   = followUpStartDT.addDays(3);

    childSA.SchedStartTime = followUpStartDT;
    childSA.SchedEndTime   = followUpEndDT;

} else {
    // 🔁 Fallback: copy parent schedule if follow-up date is missing
    childSA.SchedStartTime = parentSA.SchedStartTime;
    childSA.SchedEndTime   = parentSA.SchedEndTime;
}

// Keep status in sync
childSA.Status = parentSA.Status;

update childSA;


        System.debug('✅ Child ServiceAppointment schedule synced');

        // 4️⃣ Copy Assigned Resources
        List<AssignedResource> parentARList = [
            SELECT Id, ServiceResourceId
            FROM AssignedResource
            WHERE ServiceAppointmentId = :parentSA.Id
        ];

        if (!parentARList.isEmpty()) {

            List<AssignedResource> newChildARList = new List<AssignedResource>();

            for (AssignedResource ar : parentARList) {
                AssignedResource newAR = new AssignedResource();
                newAR.ServiceAppointmentId = childSA.Id;
                newAR.ServiceResourceId    = ar.ServiceResourceId;
                newChildARList.add(newAR);
            }

            insert newChildARList;

            System.debug('✅ Assigned Resources copied to child ServiceAppointment');
        }
    }
}


        }

        // =========================================================
        // 🔹 COMPLETE WORK STEP (MERGED HERE)
        // =========================================================
       


        // =========================================================
//  SAVE FILES TO WORK ORDER
// =========================================================
List<ContentVersion> contentVersions = new List<ContentVersion>(); 
System.debug('before lstfile check'); 
for (FileWrapper fw : listFiles)

 { 
    
    if(fw.base64Data !='')
    
    { 
        
        system.debug('inside listfile found');
        ContentVersion cv = new ContentVersion();
        cv.Title = fw.label;
        cv.PathOnClient = fw.fileName; 
        cv.VersionData = EncodingUtil.base64Decode(fw.base64Data); 
        contentVersions.add(cv); 
        
        } 
  
  } 
  
  insert contentVersions; 

  Map<Id, Id> versionToDocMap = new Map<Id, Id>();


   for (ContentVersion cv : [ SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :contentVersions ])
   
{ 
        
    versionToDocMap.put(cv.Id, cv.ContentDocumentId);
      
 } 
 
 List<ContentDocumentLink> links = new List<ContentDocumentLink>(); 
 
 for (Id versionId : versionToDocMap.keySet()) {
    
     links.add(new ContentDocumentLink(
        
         ContentDocumentId = versionToDocMap.get(versionId), 
         LinkedEntityId = workOrderId,
          ShareType = 'V', // View permission
           Visibility = 'AllUsers' )); 
           
           
           }
           
            insert links;


    } catch (Exception e) {
        System.debug(
            'Error in submitUnsuccessfulVisit :: ' +
            e.getLineNumber() + ' ' + e.getMessage()
        );
        throw new AuraHandledException('Something went wrong while saving data.');
    }
}

public class FileWrapper {
  @AuraEnabled public String base64Data{get;set;}
  @AuraEnabled public String fileName{get;set;} 
  @AuraEnabled public String label{get;set;}
}


}