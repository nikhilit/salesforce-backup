public without sharing class UnsuccessfulVisitControllerIP {

    @AuraEnabled
public static void submitUnsuccessfulVisit(string workOrderId, String reason, String notes, Date followUpDate,List<FileWrapper> listFiles) {
   

try {
    
 WorkOrder wOrder = [Select id,Reason_ForUnavilability__c,Reason_Other_Remark__c,CaseId,
                                      Check_Customer_Availability__c,Agent__r.RelatedRecord.managerid,
                                      WorkTypeId,ServiceTerritoryId,ContactId,
                                 AccountId,OwnerId,Agent__c,AICRemark__c,Approval_Status_AIC__c                            
                                       from WorkOrder where id =:workOrderId];
    
    system.debug('wOrder details ::'+ wOrder);
   

            wOrder.Reason_ForUnavilability__c=reason;
            wOrder.Reason_Other_Remark__c = notes;
            wOrder.Check_Customer_Availability__c= 'No';
            wOrder.Follow_up_Date__c=followUpdate;
            wOrder.Approval_Status_AIC__c = 'Approved';
            wOrder.AICRemark__c = reason;
           // update wOrder;

             if(reason =='House Lock' && followUpDate !=null){

                system.debug('inside premises locked and start date time not empty');

          Id woOMRecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('MGL O&M').getRecordTypeId();

                WorkOrder wo = new WorkOrder();

                wo.ParentWorkOrderId = workOrderId;
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



          /*  ServiceAppointment updChildServiApp = [Select id,SchedStartTime,SchedEndTime,Work_Order__c,Status from ServiceAppointment Where ParentRecordId =:wo.Id];

				system.debug('updChildServiApp:'+ updChildServiApp);

                updChildServiApp.SchedStartTime=followUpDate;

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

                 update updChildServiApp; */
                 
                 List<ServiceAppointment> saList = [
    SELECT Id, SchedStartTime, SchedEndTime, Work_Order__c, Status
    FROM ServiceAppointment
    WHERE ParentRecordId = :wo.Id
];

if (!saList.isEmpty()) {
    ServiceAppointment updChildServiApp = saList[0];
    
    // Your existing logic
    updChildServiApp.SchedStartTime = followUpDate;
    updChildServiApp.SchedEndTime = followUpDate.addDays(3);
    updChildServiApp.Work_Order__c = wo.Id;
    update updChildServiApp;

    AssignedResource ar = new AssignedResource(
        ServiceAppointmentId = updChildServiApp.Id,
        ServiceResourceId = wOrder.Agent__c
    );
    insert ar;

    updChildServiApp.Status = 'Dispatched';
    update updChildServiApp;
}

                 wOrder.OwnerId =  wOrder.Agent__r.RelatedRecord.managerid;

                update wOrder;

              /*  WorkOrderShare workOrderOldOwnerDelete = [select id,AccessLevel,UserOrGroup.Name from WorkOrderShare where ParentId =:wOrder.Id and
				UserOrGroup.Profile.name IN('Field Agent Riser','O&M Field Agent Riser Activity','O&M Supervisor IPD','Field Agent(O&M)- IPD','Field Agent(O&M)- IPD','O&M Supervisor DOMESTIC METER CHECKING', 'Field Agent(O&M)- AfterSalesService', 'Supervisor Building Demolition') limit 1];

		        delete workOrderOldOwnerDelete; */
                
            }

              if(reason !='House Lock'){

                Case cs = [Select id,Status,Is_Cancelled__c,Current_Work_Type__c,Standard_Remarks__c from Case where id =: wOrder.CaseId limit 1];
           
                cs.Status = 'Actioned by Department';
                cs.Is_Cancelled__c=true;
                cs.Current_Work_Type__c='5';
                cs.Standard_Remarks__c =reason;

                update cs;

                wOrder.OwnerId =  wOrder.Agent__r.RelatedRecord.managerid;

                update wOrder;

             /*    WorkOrderShare workOrderOldOwnerDelete = [select id,AccessLevel,UserOrGroup.Name from WorkOrderShare where ParentId =:wOrder.Id and
				UserOrGroup.Profile.name IN('Field Agent Riser','O&M Field Agent Riser Activity','O&M Supervisor IPD','Field Agent(O&M)- IPD','Field Agent(O&M)- IPD','O&M Supervisor DOMESTIC METER CHECKING', 'Field Agent(O&M)- AfterSalesService', 'Supervisor Building Demolition') limit 1];

		        delete workOrderOldOwnerDelete; */
                  
           
            }

            system.debug('updated workorder details ::'+ wOrder);
    
     List<WorkOrderShare> workOrderOldOwnerDelete = [select id,AccessLevel,UserOrGroup.Name from WorkOrderShare where ParentId =:wOrder.Id and
				UserOrGroup.Profile.name IN('Field Agent Riser','O&M Field Agent Riser Activity','O&M Supervisor IPD','Field Agent(O&M)- IPD','Field Agent(O&M)- IPD','O&M Supervisor DOMESTIC METER CHECKING', 'Field Agent(O&M)- AfterSalesService', 'Supervisor Building Demolition') limit 1];

                  if(!workOrderOldOwnerDelete.isEmpty()){
		        delete workOrderOldOwnerDelete;
                  }


        system.debug('lstfile data::'+ listFiles);


  List<ContentVersion> contentVersions = new List<ContentVersion>();

             System.debug('before lstfile check');



            
            for (FileWrapper fw : listFiles) {

                if(fw.base64Data !=''){

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
            for (ContentVersion cv : [
            SELECT Id, ContentDocumentId 
            FROM ContentVersion 
            WHERE Id IN :contentVersions
        ]) {
                versionToDocMap.put(cv.Id, cv.ContentDocumentId);
            }
            
            List<ContentDocumentLink> links = new List<ContentDocumentLink>();
            for (Id versionId : versionToDocMap.keySet()) {
                links.add(new ContentDocumentLink(
                    ContentDocumentId = versionToDocMap.get(versionId),
                LinkedEntityId = workOrderId,
                ShareType = 'V', // View permission
                Visibility = 'AllUsers'
                    ));
            }
            
            insert links;

 
                  updateWorkStepStatus(workOrderId, 'Check Customer Availability');

}
        
        catch(Exception e){

            system.debug('Error::'+ e.getLineNumber() + ' ' + e.getMessage());
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
            ws.Status = 'Completed'; 
            update ws;
        }
    }

     public class FileWrapper{
        @AuraEnabled public String base64Data{get;set;}
        @AuraEnabled public String fileName{get;set;}
        @AuraEnabled public String label{get;set;}
    }
}