/**
* @File Name : O_MRiserWOAssignResource.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : October 13, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 13, 2025 |   | Initial Version
**/

public without sharing class O_MRiserWOAssignResource {

	public static void assignWorkOrder(List<WorkOrder> lstWorkOrder){

		try {

			System.debug('Inside update riser workorder details');
		    String workOrderRecordTypeId = Schema.getGlobalDescribe().get('WorkOrder').getDescribe().getRecordTypeInfosByDeveloperName().get('MGL_O_M').getRecordTypeId();

			 Set<Id> worIds =  new Set<Id>();
					        
			 Map<Id, WorkOrder> workOrderMap = new Map<Id, WorkOrder>();
 			List<AssignedResource> assignedToInsert = new List<AssignedResource>();
            List<ServiceAppointment> saToUpdate = new List<ServiceAppointment>();
            List<WorkOrder> woToUpdate = new List<WorkOrder>();

			for(WorkOrder wOrder : lstWorkOrder){

                System.debug('Work order::>>' + wOrder + '\nwOrder.Id::>>' + wOrder.Id);
                if(wOrder.RecordTypeId ==workOrderRecordTypeId && wOrder.Activity_Name_WorkType__c !=null){
                   
                    worIds.add(wOrder.Id);
                    workOrderMap.put(wOrder.Id, wOrder);

                }
            }

			    if(!worIds.isEmpty()) {

			   List<ServiceAppointment> serApp = [select id,ParentRecordId,Work_Order__c,SchedStartTime,SchedEndTime,Status,CreatedById,createdby.ManagerId from ServiceAppointment where ParentRecordId IN: worIds];

				system.debug('serApp::'+ serApp);

				Set<Id> createdByIds = new Set<Id>();
            for (ServiceAppointment sa : serApp) {
                if (sa.CreatedById != null)
                    createdByIds.add(sa.CreatedById);
            }

			system.debug('createdByIds::'+ createdByIds);

           
			Map<Id, ServiceResource> resourceMap = new Map<Id, ServiceResource>();
				for (ServiceResource sr : [SELECT Id, Name, RelatedRecordId FROM ServiceResource WHERE RelatedRecordId != null]) {
    				resourceMap.put(sr.RelatedRecordId, sr);
			}

			system.debug('resourceMap::'+ resourceMap);

			 for (ServiceAppointment sa : serApp) {
                WorkOrder wo = workOrderMap.get(sa.ParentRecordId);
                if (wo == null) continue;

                sa.SchedStartTime = wo.StartDate; 
                sa.SchedEndTime =  wo.StartDate.addDays(3);
				sa.Work_Order__c= sa.ParentRecordId;
              //  sa.Status = 'Dispatched';
                saToUpdate.add(sa);



                ServiceResource sr = resourceMap.get(sa.CreatedById);
                if (sr != null) {

					system.debug('inside sr matched with createdbyid');
                    AssignedResource ar = new AssignedResource(
                        ServiceAppointmentId = sa.Id,
                        ServiceResourceId = sr.Id
                    );
					system.debug('ar::'+ ar);
                    assignedToInsert.add(ar);

					system.debug('assign resource to insert::'+ assignedToInsert);
                    
					 WorkOrder woUpdate = new WorkOrder(Id = wo.Id,Agent__c = sr.Id,Approvar_User__c=sa.createdby.ManagerId);
  					 woToUpdate.add(woUpdate);
                }
            }

				system.debug('assign resource to insert out side for loop::'+ assignedToInsert);

            if (!saToUpdate.isEmpty()){

				update saToUpdate;

				system.debug('saToUpdate'+ saToUpdate);
			} 
            if (!assignedToInsert.isEmpty()){

				insert assignedToInsert;
				system.debug('assignedToInsert::'+ assignedToInsert);
			} 

			List<ServiceAppointment> lstSerStatusUpd =[Select id,status from ServiceAppointment where Id IN: saToUpdate];

			for(ServiceAppointment serAppUpd : lstSerStatusUpd){

				serAppUpd.Status ='Dispatched';
			}

			if(!lstSerStatusUpd.isEmpty()){

				update lstSerStatusUpd;
				system.debug('lstSerStatusUpd'+ lstSerStatusUpd);
			}
            if (!woToUpdate.isEmpty()){

				update woToUpdate;
				system.debug('woToUpdate::'+ woToUpdate);
			} 

				}

		}

		catch(Exception e) {

			system.debug('Error ::'+ e.getLineNumber() + e.getMessage());

		}

	}
}