public without sharing class MeterDetailsController {

//     @AuraEnabled
// public static void markCustomerUnavailable(Id recordId, String reason, String remarks, Date followUpDate) {
//     try {
//         System.debug('Step 1: Fetching WorkOrder');
//         WorkOrder wo = [
//             SELECT Id, Status, Attempt_Count__c, Enable_DPR_Submission__c
//             FROM WorkOrder
//             WHERE Id = :recordId
//             LIMIT 1
//         ];

//         System.debug('Step 2: Fetching ServiceAppointment');
//         List<ServiceAppointment> appointments = [
//             SELECT Id, ParentRecordId, Customer_Unavailability_Reason__c, Follow_up_Remarks__c, Follow_Up_Visit_Date__c
//             FROM ServiceAppointment
//             WHERE ParentRecordId = :wo.Id
//             ORDER BY CreatedDate DESC
//             LIMIT 1
//         ];

//         if (appointments.isEmpty()) {
//             throw new AuraHandledException('No ServiceAppointment found for this Work Order.');
//         }

//         ServiceAppointment sa = appointments[0];

//         System.debug('Step 3: Updating ServiceAppointment');
//         sa.Customer_Unavailability_Reason__c = reason;
//         sa.Follow_up_Remarks__c = remarks;
//         sa.SchedStartTime = followUpDate;
//         sa.SchedEndTime = followUpDate.addDays(7);
//         update sa;

//         System.debug('Step 4: Updating WorkOrder');
//         wo.Status = 'Customer Unavailable';
//         wo.Attempt_Count__c = (wo.Attempt_Count__c == null) ? 1 : wo.Attempt_Count__c + 1;

        
// // Add this logic block here:
// if (wo.Attempt_Count__c >= 4) {
//     wo.Status = 'Closed'; // or 'Request Closed'
//     wo.Enable_DPR_Submission__c = true; // optional
// }

//         update wo;

//         updateWorkStepStatus(recordId, 'Site Details');
       

//     } catch (Exception e) {
//         System.debug('Exception in markCustomerUnavailable: ' + e.getMessage());
//         throw new AuraHandledException('Server Error: ' + e.getMessage());
//     }
// }


@AuraEnabled
public static List<WorkOrder> followUpDetails(String recordId){

    try {

        List<WorkOrder> lstWOrder = [select id,ParentWorkOrderId,CreatedDate from workorder where ParentWorkOrderId=: recordId];


            return lstWOrder;
    }

    catch(Exception e) {

        system.debug('error :::'+ e.getMessage() + e.getLineNumber());

        return new List<WorkOrder>();


    }
}


@AuraEnabled(cacheable=true)
public static Date getLastUnavailableVisitDate(Id workOrderId) {
    List<ServiceAppointment> appointments = [
        SELECT Id, SchedStartTime, Customer_Unavailability_Reason__c
        FROM ServiceAppointment
        WHERE ParentRecordId = :workOrderId
        AND Customer_Unavailability_Reason__c != null
        ORDER BY SchedStartTime DESC
        LIMIT 1
    ];

    if (!appointments.isEmpty()) {
    return appointments[0].SchedStartTime.date(); // convert Datetime to Date
}


    return null;
}

 @AuraEnabled
    public static string checkWorkStep(string recordId){

        try {

            System.debug('inside check work step method in apex');
             System.debug('Record id::'+ recordId);

       WorkStep worStep = [SELECT Id, Status,Name
			FROM WorkStep
			WHERE ParentRecordId =: recordId AND Name='Check-in'];

    system.debug('Work step result ::'+ worStep.Status);
        return worStep.Status;
    
    }
    catch(Exception e){
        return 'Error';
    }
			
    }

 @AuraEnabled
    public static void uploadCNAPhoto(String fileName, string base64Data, String recordId) {
     
       
        System.debug('Inside upload file method:::');
 
        System.debug('fileName::' + fileName);
        System.debug('base64Data::' + base64Data);
        Blob fileBlob = EncodingUtil.base64Decode(base64Data);
   
        System.debug('File blob:::'+ fileBlob);

        WorkOrder woUpdate = [Select id,Check_Customer_Availability__c from WorkOrder where id=:recordId];
       
       woUpdate.Check_Customer_Availability__c	='CNA';

       update woUpdate;
 
            ContentVersion cv = new ContentVersion();
             cv.Title = fileName;
             cv.PathOnClient = fileName;
             cv.VersionData = fileBlob;
                System.debug('CV::::'+ cv);
                insert cv;
 
            ContentDocumentLink link = new ContentDocumentLink();
            link.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
            link.LinkedEntityId =  recordId;
            link.ShareType = 'I';
            System.debug('Link:::'+ link);
            insert link;            
 
        System.debug('contentversion :::'+ cv);      
         System.debug('Document Link:::'+ link);  

         	  updateWorkStepStatus(recordId,'Site Details');

 
        
 
       
   
}



	@AuraEnabled
    public static void savePhotoUploadsDomesticMeter(string recordId, List<FileWrapper> listFiles,String reason, String remarks, DateTime selectedDateTime, String selectedOption) {

        try {

                    System.debug('savePhotoUploads START for Record Id: ' + recordId);


              String childWOId='';

           List<WorkOrder> childWorkOrder = [Select Id,ParentWorkOrderId from workorder Where ParentWorkOrderId =:recordId];

             system.debug('childWorkOrder::'+ childWorkOrder.size());
              system.debug('selectedReason::'+ reason);
              system.debug('selected option::'+ selectedOption);

             system.debug('selectedDateTime::'+ selectedDateTime);


              WorkOrder wOrder = [Select id,Reason_ForUnavilability__c,Reason_Other_Remark__c,WorkTypeId,ServiceTerritoryId,ContactId,
                                 AccountId,OwnerId,Check_Customer_Availability__c,CaseId,Agent__c,AICRemark__c,Approval_Status_AIC__c,Agent__r.Supervisor__r.RelatedRecordId
                                        from WorkOrder where id =:recordId];

                  wOrder.Reason_ForUnavilability__c=reason;
                  wOrder.Check_Customer_Availability__c= selectedOption;
                 wOrder.Reason_Other_Remark__c = remarks;
                 wOrder.Approval_Status_AIC__c = 'Approved';
                wOrder.AICRemark__c = reason;
               




       

            if(reason =='House Lock' && selectedDateTime !=null && childWorkOrder.size() < 2){

                system.debug('inside premises locked and start date time not empty');

          Id woOMRecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('MGL O&M').getRecordTypeId();

                WorkOrder wo = new WorkOrder();

                wo.ParentWorkOrderId = recordId;
                wo.WorkTypeId = wOrder.WorkTypeId;
                wo.AccountId = wOrder.AccountId;
                wo.RecordTypeId = woOMRecordTypeId;
                wo.CaseId = wOrder.CaseId;
                wo.OwnerId = wOrder.OwnerId;
                wo.Agent__c = wOrder.Agent__c;
                wo.ServiceTerritoryId = wOrder.ServiceTerritoryId;
                wo.ContactId = wOrder.ContactId;


                insert wo;

                system.debug('Child Work order::'+ wo);

                 childWOId = wo.Id;


            ServiceAppointment updChildServiApp = [Select id,SchedStartTime,SchedEndTime,Work_Order__c,Status from ServiceAppointment Where ParentRecordId =:wo.Id];



                updChildServiApp.SchedStartTime=selectedDateTime;

               updChildServiApp.SchedEndTime = updChildServiApp.SchedStartTime.addDays(3);

				updChildServiApp.Work_Order__c= wo.Id;

                 update updChildServiApp;

                system.debug('serviceappointment updated::'+ updChildServiApp);

                AssignedResource ar = new AssignedResource(
                        ServiceAppointmentId = updChildServiApp.Id,
                        ServiceResourceId = wOrder.Agent__c
                    );

                    insert ar;

                     updChildServiApp.Status = 'Dispatched';

                 update updChildServiApp;

                 wOrder.OwnerId =  wOrder.Agent__r.Supervisor__r.RelatedRecordId;

                update wOrder;

                WorkOrderShare workOrderOldOwnerDelete = [select id,AccessLevel,UserOrGroup.Name from WorkOrderShare where ParentId =:wOrder.Id and
				UserOrGroup.Profile.name IN('Field Agent Riser','O&M Field Agent Riser Activity','O&M Supervisor IPD','Field Agent(O&M)- IPD','Field Agent(O&M)- IPD','O&M Supervisor DOMESTIC METER CHECKING', 'Field Agent(O&M)- AfterSalesService', 'Supervisor Building Demolition') limit 1];

		        delete workOrderOldOwnerDelete;
                
            }

            if(reason !='House Lock'){

                Case cs = [Select id,Status,Is_Cancelled__c,Current_Work_Type__c,Standard_Remarks__c from Case where id =: wOrder.CaseId limit 1];
           
                cs.Status = 'Actioned by Department';
                cs.Is_Cancelled__c=true;
             //   cs.Current_Work_Type__c='5';
                cs.Standard_Remarks__c =reason;

                update cs;

                wOrder.OwnerId =  wOrder.Agent__r.Supervisor__r.RelatedRecordId;

                update wOrder;

                 WorkOrderShare workOrderOldOwnerDelete = [select id,AccessLevel,UserOrGroup.Name from WorkOrderShare where ParentId =:wOrder.Id and
				UserOrGroup.Profile.name IN('Field Agent Riser','O&M Field Agent Riser Activity','O&M Supervisor IPD','Field Agent(O&M)- IPD','Field Agent(O&M)- IPD','O&M Supervisor DOMESTIC METER CHECKING', 'Field Agent(O&M)- AfterSalesService', 'Supervisor Building Demolition') limit 1];

		        delete workOrderOldOwnerDelete;
           
            }

            List<ContentVersion> contentVersions = new List<ContentVersion>();
            
            for (FileWrapper fw : listFiles) {

                if(fw.base64Data !=''){

                ContentVersion cv = new ContentVersion();
                cv.Title = fw.label;
                cv.PathOnClient = fw.fileName +'.jpg';
                cv.VersionData = EncodingUtil.base64Decode(fw.base64Data);
                contentVersions.add(cv);
            }
            }
            
            insert contentVersions;
            
            // Map ContentVersion Id to ContentDocumentId
            Map<Id, Id> versionToDocMap = new Map<Id, Id>();
            for (ContentVersion cv : [
            SELECT Id, ContentDocumentId 
            FROM ContentVersion 
            WHERE Id IN :contentVersions
        ]) {
                versionToDocMap.put(cv.Id, cv.ContentDocumentId);
            }
            
            // Create ContentDocumentLinks to associate files with the given record
            List<ContentDocumentLink> links = new List<ContentDocumentLink>();
            for (Id versionId : versionToDocMap.keySet()) {
                links.add(new ContentDocumentLink(
                    ContentDocumentId = versionToDocMap.get(versionId),
                LinkedEntityId = recordId,
                ShareType = 'V', // View permission
                Visibility = 'AllUsers'
                    ));
            }
            
            insert links;


            updateWorkStepStatus(recordId, 'Site Details');

            

        } catch (Exception e) {

            system.debug('Error:::'+ e.getLineNumber() + e.getMessage());

        }
    }

      public static void updateWorkStepStatus(Id workOrderId,String name){
        List<WorkStep> steps = [
			SELECT Id, Status
			FROM WorkStep
			WHERE ParentRecordId = :workOrderId
			AND Name = :name
			LIMIT 1
		];
        
        if (!steps.isEmpty()) {
            WorkStep ws = steps[0];
            ws.Status = 'Completed'; // Or whatever picklist value you use
            update ws;
        }
     }


  

    // Wrapper for Files from LWC
   public class FileWrapper{
        @AuraEnabled public String base64Data{get;set;}
        @AuraEnabled public String fileName{get;set;}
        @AuraEnabled public String label{get;set;}
    }



     @AuraEnabled
public static void updateMeterStatus(String recordId, String status, String beforeReading, String afterReading, String reason, String meterNumber, String isMeterAvailable, String isUsingGas, String gasLeakageCheckValue,String leakTestValue,String meterMake) {
    System.debug('updateMeterStatus Triggered');

    try {
      

        WorkOrder originalWO = [
            SELECT Id, Subject, CaseId, AccountId, Agent__c,New_Meter_Reading__c,Old_Meter_Reading__c,
            Abnormal_Reading_Reason__c,Is_Customer_Using_Gas__c,Is_Meter_Available__c,Meter_Status__c,
            Leak_Test_With_SOAP_Solution__c,Ensure_No_Gas_Leakage_Before_LeavingSit__c,Meter_Number__c,Meter_Make__c,
            Check_Customer_Availability__c	
            FROM WorkOrder
            WHERE Id = :recordId
            LIMIT 1
        ];

        originalWO.Is_Meter_Available__c = isMeterAvailable;
        originalWO.Is_Customer_Using_Gas__c = isUsingGas;
        originalWO.Abnormal_Reading_Reason__c = reason;
        // Update meter status
        originalWO.Meter_Status__c = status;
    originalWO.Old_Meter_Reading__c = beforeReading;
    originalWO.New_Meter_Reading__c = afterReading;
     originalWO.Leak_Test_With_SOAP_Solution__c	 = leakTestValue;
     originalWO.Meter_Make__c = meterMake;
     originalWO.Check_Customer_Availability__c='Yes';
     
    originalWO.Meter_Number__c = Decimal.valueOf(meterNumber);
    originalWO.Ensure_No_Gas_Leakage_Before_LeavingSit__c = gasLeakageCheckValue;

        update originalWO;
     


        if (status == 'No') {
            WorkOrder replacementWO = new WorkOrder(
                Subject = 'Meter Replacement - Auto Created',
                CaseId = originalWO.CaseId,
                AccountId = originalWO.AccountId,
                ParentWorkOrderId = originalWO.Id,
                Agent__c = originalWO.Agent__c
            );
            insert replacementWO;

            ServiceAppointment newSA = new ServiceAppointment(
                ParentRecordId = replacementWO.Id,
                Status = 'New',
                Subject = 'Meter Replacement Visit'
            );
            insert newSA;

        }

                  	  updateWorkStepStatus(recordId,'Site Details');


    } catch (Exception e) {
        System.debug('Error in updateMeterStatus: ' + e.getMessage());
       // throw new AuraHandledException('Meter update failed: ' + e.getMessage());
    }
}


@AuraEnabled
public static void updateGasStatus(Id recordId, String meterNumber, String reading, String reasonGasNotUsed) {
    if (String.isBlank(recordId)) {
        throw new AuraHandledException('Record Id is required.');
    }

    try {

        system.debug('meter number::'+ meterNumber);
        system.debug('meter reading::'+ reading);
        system.debug('reasongasnotused'+ reasonGasNotUsed);
        WorkOrder wo = [SELECT Id, Meter_Number__c, Meter_Reading__c, Reason_Gas_Not_Used_Remark__c	 
                        FROM WorkOrder 
                        WHERE Id = :recordId 
                        LIMIT 1];

        // Convert safely
        wo.Meter_Number__c = String.isNotBlank(meterNumber) ? Decimal.valueOf(meterNumber) : null;
        wo.Meter_Reading__c = String.isNotBlank(reading) ? Decimal.valueOf(reading) : null;
        wo.Reason_Gas_Not_Used_Remark__c = reasonGasNotUsed;

        update wo;

             	  updateWorkStepStatus(recordId,'Site Details');

    } catch (Exception e) {
        throw new AuraHandledException('Error updating gas status: ' + e.getMessage());
    }
}




@AuraEnabled
    public static void uploadPhotosToWorkOrder(String recordId, List<FileWrapper> listFiles) {

       // System.debug('Received PhotoWrapper List: ' + JSON.serializePretty(listFiles));

        try {
                    System.debug('Starting uploadPhotosToWorkOrder for Record Id: ' + recordId);

           
             List<ContentVersion> contentVersions = new List<ContentVersion>();
            
            for (FileWrapper fw : listFiles) {
                ContentVersion cv = new ContentVersion();
                cv.Title = fw.label;
                cv.PathOnClient = fw.fileName +'.jpg';
                cv.VersionData = EncodingUtil.base64Decode(fw.base64Data);
                contentVersions.add(cv);
            }
            
            insert contentVersions;

            system.debug('contentVersions:::'+ contentVersions);
            
            // Map ContentVersion Id to ContentDocumentId
            Map<Id, Id> versionToDocMap = new Map<Id, Id>();
            for (ContentVersion cv : [
            SELECT Id, ContentDocumentId 
            FROM ContentVersion 
            WHERE Id IN :contentVersions
        ]) {
                versionToDocMap.put(cv.Id, cv.ContentDocumentId);
            }
            
            // Create ContentDocumentLinks to associate files with the given record
            List<ContentDocumentLink> links = new List<ContentDocumentLink>();
            for (Id versionId : versionToDocMap.keySet()) {
                links.add(new ContentDocumentLink(
                    ContentDocumentId = versionToDocMap.get(versionId),
                LinkedEntityId = recordId,
                ShareType = 'V', // View permission
                Visibility = 'AllUsers'
                    ));
            }
            
            insert links;

            system.debug('links::'+links);

          updateWorkStepStatus(recordId,'Site Details');


        } catch (Exception e) {
            System.debug('Error saving photos: ' + e.getMessage() + ' at line ' + e.getLineNumber());
           // return 'ERROR: ' + e.getMessage();
        }
    }


    @AuraEnabled
public static void uploadPhotosToWorkOrderMeter(String recordId, List<FileWrapper> listFiles, String customerAvailableOrNot,String isMeterAvailable,String meterNotAvailableSelectedReasons,String miscellaneousRemark) {
       // System.debug('Received PhotoWrapper List: ' + JSON.serializePretty(listFiles));
  
        try {

                System.debug('Starting savePhotoUploads for Record Id: in uploadPhotosToWorkOrderMeter' + recordId);

          system.debug('customerAvailableOrNot ::'+ customerAvailableOrNot);
          system.debug('isMeterAvailable ::'+ isMeterAvailable);
          system.debug('meterNotAvailableSelectedReasons ::'+ meterNotAvailableSelectedReasons);
          system.debug('miscellaneousRemark ::'+ miscellaneousRemark);


            WorkOrder woUpdate = [Select id,Check_Customer_Availability__c,Is_Meter_Available__c,Meter_Not_Available_Reason__c,New_Remark__c
            	 from WorkOrder Where id=:recordId];

               woUpdate.Check_Customer_Availability__c=  customerAvailableOrNot;
               woUpdate.Is_Meter_Available__c =isMeterAvailable;
               woUpdate.Meter_Not_Available_Reason__c = meterNotAvailableSelectedReasons;
               woUpdate.New_Remark__c =miscellaneousRemark;

               update woUpdate;

             List<ContentVersion> contentVersions = new List<ContentVersion>();
            
            for (FileWrapper fw : listFiles) {

              if(fw.base64Data !=''){

                ContentVersion cv = new ContentVersion();
                cv.Title = fw.label;
                cv.PathOnClient = fw.fileName +'.jpg';
                cv.VersionData = EncodingUtil.base64Decode(fw.base64Data);
                contentVersions.add(cv);
           }
            }

            system.debug('contentVersions before insert:::'+ contentVersions);


            insert contentVersions;

            system.debug('contentVersions:::'+ contentVersions);
            
            // Map ContentVersion Id to ContentDocumentId
            Map<Id, Id> versionToDocMap = new Map<Id, Id>();
            for (ContentVersion cv : [
            SELECT Id, ContentDocumentId 
            FROM ContentVersion 
            WHERE Id IN :contentVersions
        ]) {
                versionToDocMap.put(cv.Id, cv.ContentDocumentId);
            }
            
            // Create ContentDocumentLinks to associate files with the given record
            List<ContentDocumentLink> links = new List<ContentDocumentLink>();
            for (Id versionId : versionToDocMap.keySet()) {
                links.add(new ContentDocumentLink(
                    ContentDocumentId = versionToDocMap.get(versionId),
                LinkedEntityId = recordId,
                ShareType = 'V', // View permission
                Visibility = 'AllUsers'
                    ));
            }
            
            insert links;

            system.debug('links::'+links);

          updateWorkStepStatus(recordId,'Site Details');


        } catch (Exception e) {
            System.debug('Error saving photos: ' + e.getMessage() + ' at line ' + e.getLineNumber());
          //  return 'ERROR: ' + e.getMessage();
        }
}


@AuraEnabled
public static void uploadPhotosToGas(Id recordId, List<FileWrapper> listFiles) {

        try {

                System.debug('Starting savePhotoUploads for Record Id: in uploadPhotosToGas' + recordId);

          

             List<ContentVersion> contentVersions = new List<ContentVersion>();
            
            for (FileWrapper fw : listFiles) {
                ContentVersion cv = new ContentVersion();
                cv.Title = fw.label;
                cv.PathOnClient = fw.fileName +'.jpg';
                cv.VersionData = EncodingUtil.base64Decode(fw.base64Data);
                contentVersions.add(cv);
            }
            
            insert contentVersions;

            system.debug('contentVersions:::'+ contentVersions);
            
            // Map ContentVersion Id to ContentDocumentId
            Map<Id, Id> versionToDocMap = new Map<Id, Id>();
            for (ContentVersion cv : [
            SELECT Id, ContentDocumentId 
            FROM ContentVersion 
            WHERE Id IN :contentVersions
        ]) {
                versionToDocMap.put(cv.Id, cv.ContentDocumentId);
            }
            
            // Create ContentDocumentLinks to associate files with the given record
            List<ContentDocumentLink> links = new List<ContentDocumentLink>();
            for (Id versionId : versionToDocMap.keySet()) {
                links.add(new ContentDocumentLink(
                    ContentDocumentId = versionToDocMap.get(versionId),
                LinkedEntityId = recordId,
                ShareType = 'V', // View permission
                Visibility = 'AllUsers'
                    ));
            }
            
            insert links;

            system.debug('links::'+links);

         updateWorkStepStatus(recordId,'Site Details');


        } catch (Exception e) {
            System.debug('Error saving photos: ' + e.getMessage() + ' at line ' + e.getLineNumber());
           // return 'ERROR: ' + e.getMessage();
        }
}
 

}