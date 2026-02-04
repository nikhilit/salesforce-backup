/**
* @File Name : BpDetailsBasedOnConnectionContr.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : August 19, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | August 19, 2025 |   | Initial Version
**/

public without sharing class BpDetailsBasedOnConnectionContr {
	

    @AuraEnabled(cacheable=true)
    public static List<BPWrapper> getBPDetails(Id workOrderId) {

		WorkOrder wo = [Select id,Connection__c,Connection__r.Name from WorkOrder Where Id=: workOrderId];


        List<Account> lstAccount = [
            SELECT Id, BP_Number__c,Connection_Object__c,Connection__c
            FROM Account
            WHERE Connection__c = :wo.Connection__c
            ORDER BY CreatedDate ASC
        ];

        List<BPWrapper> wrapperList = new List<BPWrapper>();
        Integer index = 1;
        for (Account acc : lstAccount) {
            wrapperList.add(new BPWrapper(index, acc.Id, acc.BP_Number__c));
            index++;
        }
        return wrapperList;
    }

    public class BPWrapper {
        @AuraEnabled public Integer index { get; set; }
        @AuraEnabled public Id recordId { get; set; }
        @AuraEnabled public String name { get; set; }

        public BPWrapper(Integer idx, Id recId, String nm) {
            index = idx;
            recordId = recId;
            name = nm;
        }
    }

    @AuraEnabled
	public static void saveBPFoundDetails(string recordId, String havingBPValue, String customerDetails  ){

		try {

			system.debug('record id::'+ recordId);

		WorkOrder woUpdate = [Select Id, Any_customer_using_gas_but_not_having_bp__c,
									Customer_Details_Using_Gas_Not_Having_BP__c
									 
									from WorkOrder where Id=: recordId];

		

		woUpdate.Any_customer_using_gas_but_not_having_bp__c = havingBPValue;

		if(havingBPValue =='Yes'){

		woUpdate.Customer_Details_Using_Gas_Not_Having_BP__c = customerDetails;

		}


		Update woUpdate;


		}

		catch(Exception e){

			System.debug('Error updateworkorder details::'+ e.getLineNumber() + e.getMessage());
		}
	}

    @AuraEnabled
	public static WorkOrder getWorkOrder(String recordId){

		try {


			WorkOrder wo =[Select Id,Any_customer_using_gas_but_not_having_bp__c,
									Customer_Details_Using_Gas_Not_Having_BP__c
									 from WorkOrder where Id=: recordId];

			return wo;
		}
		catch(Exception e){

			return new WorkOrder();
		}
	}

	
}