/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : CreateWOLItemBasedOnRiserNumber
 * Author          : <YourName>
 * Created Date    : Jan 25, 2026
 * Last Modified By: <YourName>
 * Last Modified On: Jan 25, 2026
 * Description     : This class implements for......
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Jan 25, 2026  │ <YourName>   │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */

public without sharing class CreateWOLItemBasedOnRiserNumber {

	public static void afterUpdate(List<WorkOrder> newList, Map<Id, WorkOrder> oldMap) {

		try {

				system.debug('inside try block');
        String omRecordType = Schema.SObjectType.WorkOrder.getRecordTypeInfosByDeveloperName()
                     .get('MGL_O_M').getRecordTypeId();

					 

					 List<WorkOrderLineItem> lstWOLItem = new List<WorkOrderLineItem>();
					 Set<Id> setWOIds = new Set<Id>();


		  for (WorkOrder wo : newList) {

			system.debug('inside for loop 1');



            if (wo.RecordTypeId == omRecordType  &&  wo.Seal_Number_Visible__c ==false && wo.Seal_Number_Visible__c !=true
					 && wo.WorkTypeId !=null && !String.isBlank(wo.Number_of_Risers__c) 
					  && wo.Connection__c !=null )
			
				{

						system.debug('if condition satesfied');
						system.debug('WorkOrder details :: '+ wo);

					Integer riserNumberValue = Integer.valueOf(wo.Number_of_Risers__c);
						


					for(Integer i=1; i<= riserNumberValue; i++){

						system.debug('inside for loop workorderlineitem');

							WorkOrderLineItem wolitem = new WorkOrderLineItem();

							wolitem.Riser_Name__c	= 'Riser ' + i;
							wolitem.WorkOrderId = wo.Id;

							lstWOLItem.add(wolitem);
						}
							setWOIds.add(wo.Id);
	
			}		 

		  } 

		List<WorkOrder> lstUpdWO = [Select id,Seal_Number_Visible__c from WorkOrder where Id IN:setWOIds];

		for(WorkOrder woup : lstUpdWO){

			woup.Seal_Number_Visible__c = true;
		}

		if(!lstUpdWO.isEmpty()){

		update lstUpdWO;

		}

		  if(!lstWOLItem.isEmpty()){

			insert lstWOLItem;

			system.debug('WorkOrderLineItem inserted ::'+ lstWOLItem);
		}
		

		}
		catch(Exception e){

			system.debug('Error::'+ e.getLineNumber() + e.getMessage());
		}
}

}