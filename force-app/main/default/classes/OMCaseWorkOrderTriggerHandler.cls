/**
* @File Name : OMCaseWorkOrderTriggerHandler.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : December 3, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | December 3, 2025 |   | Initial Version
**/

public class OMCaseWorkOrderTriggerHandler {

public static void updateOMWorkOrderAndAccount(List<Case> lstCase,Map<Id, Case> oldMap){


try {

	system.debug('Update OM workorder and account method' + lstCase);

	Set<Id> accIds = new Set<Id>();
	Set<Id> workorderIds = new Set<Id>();

	Map<Id,Case> caseMap = new Map<Id,Case>();
		Map<Id,Case> caseMapWO = new Map<Id,Case>();

		Set<Id> csIds = new Set<Id>();

		//Set<Id> rejectedCaseIds = new Set<Id>();


	for(Case cs : lstCase){

		System.debug('case details:::cs.Standard_Remarks__c' + cs.Standard_Remarks__c + '\ncs.Is_Updated_OM_WorkOrder_and_Account__c::' + cs.Is_Updated_OM_WorkOrder_and_Account__c);

		if(cs.Standard_Remarks__c != null && cs.Is_Updated_OM_WorkOrder_and_Account__c == False && 
		   cs.Work_Order_ID__c != oldMap.get(cs.Id).Work_Order_ID__c  && cs.Work_Order_ID__c !=null  ){
		
			system.debug('inside if condition match');

			// workorderIds.add(cs.Work_Order_ID__c);
			workorderIds.add(Id.valueOf(cs.Work_Order_ID__c));
			caseMapWO.put(cs.Work_Order_ID__c,cs);

			// if(cs.Approval_Status_AIC__c=='Rejected'){


			// 	rejectedCaseIds.add(cs.Id);
			// }
		}

		if(cs.Approval_Status_AIC__c =='Approved' && cs.Move_Out_Date_BP__c !=null && cs.AccountId !=null && 
		   cs.Is_Updated_OM_WorkOrder_and_Account__c == False && 
		   cs.Move_Out_Date_BP__c != oldMap.get(cs.Id).Move_Out_Date_BP__c){

			System.debug('inside account match condition');

			accIds.add(cs.AccountId);
			caseMap.put(cs.AccountId,cs);
			csIds.add(cs.Id);


		}
	}
    List<Account> lstAccounts=new List<Account>();
    if(accIds.size()>0){

		lstAccounts = [Select id,Move_Out_Date__c from Account where Id IN: accIds];
    }

		List<WorkOrder> lstWorkOrders = [Select id,Approval_Status_AIC__c,AICRemark__c from WorkOrder where Id IN:workorderIds];

		
			if(!lstAccounts.isEmpty()){

			for(Account acc : lstAccounts){

				if(caseMap.containskey(acc.Id)){

				system.debug('inside account map contains account id');

				Case cs = caseMap.get(acc.Id);


				acc.Move_Out_Date__c = cs.Move_Out_Date_BP__c;


				}
			}

			if(!lstAccounts.isEmpty()){

				update lstAccounts;

				system.debug('Updated account detials::'+ lstAccounts);
			}

			}

			system.debug('Workorder details::'+ lstWorkOrders);

			if(!lstWorkOrders.isEmpty()){

			for(WorkOrder wo : lstWorkOrders){

				if(caseMapWO.containskey(wo.Id)){

				system.debug('inside workorder map contains workorder id');

				Case cswo = caseMapWO.get(wo.Id);


				wo.Approval_Status_AIC__c = cswo.Approval_Status_AIC__c;
				wo.AICRemark__c = cswo.Standard_Remarks__c;


				}
			}

			if(!lstWorkOrders.isEmpty()){

				update lstWorkOrders;

				system.debug('WorkOrder updated details::'+ lstWorkOrders);
			}

			}

			List<Case> lstCaseUpd = [Select id,Is_Updated_OM_WorkOrder_and_Account__c from case where Id IN: csIds];

			if(!lstCaseUpd.isEmpty()){

				for(Case csupdate : lstCaseUpd){

					csupdate.Is_Updated_OM_WorkOrder_and_Account__c = true;
				}

				Update lstCaseUpd;
			}

			// List<Case> rejectedCaselst = [Select id,Work_Order_ID__c from Case where Id IN: rejectedCaseIds];

			// if(!rejectedCaselst.isEmpty()){

			// for(Case cswoidUpd : rejectedCaselst){

			// 	cswoidUpd.Work_Order_ID__c=null;
			// }

			// 	update rejectedCaselst;
			// }

	

}
catch(Exception e){

	System.debug('Error updating workorder and account'+ e.getLineNumber() + ' ' + e.getMessage());
}
}
}