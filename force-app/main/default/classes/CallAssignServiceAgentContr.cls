/**
* @File Name : CallAssignServiceAgentContr.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : September 4, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | September 4, 2025 |   | Initial Version
**/

public without sharing class CallAssignServiceAgentContr {
	

  
    public class PagedWorkOrders {
        @AuraEnabled public List<WorkOrder> records;
        @AuraEnabled public Integer totalSize;
    }

   

   
    @AuraEnabled(cacheable=true)
    public static PagedWorkOrders getFilteredWorkOrders(
        Integer pageSize,
        Integer pageNumber,
        // Decimal invoiceFrom,
        // Decimal invoiceTo,
         String location,
        // String status,
         String pinCode,
         String roadName,
         String buildingName
        // Id agencyId,
        // Id agentServiceResourceId,
        // String activityType
    ) {
        if (pageSize == null || pageSize <= 0) pageSize = 10;
        if (pageNumber == null || pageNumber <= 0) pageNumber = 1;

        system.debug('pin code::'+ pinCode);
        system.debug('location::'+ location);
        system.debug('location::'+ buildingName);
        system.debug('location::'+ roadName);



		String WorkTypeName ='';
		
		User userDetails = [Select id,Profile.Name from User where id=: userInfo.getUserId()];

		if(userDetails.Profile.Name =='O&M Supervisor DOMESTIC METER CHECKING'|| userDetails.Profile.Name=='System Administrator'){

			WorkTypeName = 'Domestic Meter Checking';
		}

		if(userDetails.Profile.Name =='O&M Supervisor IPD' || userDetails.Profile.Name=='System Administrator'){

			WorkTypeName = 'Individual Permanent Disconnection';
		}
		if(userDetails.Profile.Name =='O&M Rubber Hose Supervisor' || userDetails.Profile.Name=='System Administrator'){

			WorkTypeName = 'Rubber Hose Replacement';
		}


        String whereClause = ' WHERE RecordType.DeveloperName = \'MGL_O_M\'';

			if (String.isNotBlank(workTypeName)) {
   				 whereClause += ' AND WorkType.Name = \'' + String.escapeSingleQuotes(workTypeName) + '\'';
			}

            whereClause += ' AND OwnerId = \'' + userDetails.Id + '\'';

            whereClause += ' AND Agent__c = \'\'';

             if (!String.isBlank(location)) {
            whereClause += ' AND Account.Location__c LIKE \'%' + String.escapeSingleQuotes(location) + '%\'';
        }

         if (!String.isBlank(pinCode)) {
            whereClause += ' AND Account.Postal_Code__c LIKE \'%' + String.escapeSingleQuotes(pinCode) + '%\'';
        }

          if (!String.isBlank(buildingName)) {
            whereClause += ' AND Account.Building_name__c LIKE \'%' + String.escapeSingleQuotes(buildingName) + '%\'';
        }

         if (!String.isBlank(roadName)) {
            whereClause += ' AND Account.Road_Name__c LIKE \'%' + String.escapeSingleQuotes(roadName) + '%\'';
        }

      
        String countQuery = 'SELECT count() FROM WorkOrder' + whereClause;
        Integer totalSize = 0;

		System.debug('=========countQuery========>'+countQuery);

        try {
			totalSize = Database.countQuery(countQuery);
		} catch (Exception ex) {

			system.debug('error cout detail::'+ ex.getMessage() + ex.getLineNumber());
			// Optional fallback if you’re not sure countQuery is valid for countQuery
			AggregateResult[] ar = Database.query(countQuery);
			if (!ar.isEmpty()) {
				totalSize = (Integer)ar[0].get('expr0');
			}
		}

        // Build select fields - include required fields
        // String selectClause = 'SELECT Id, WorkOrderNumber, Account.Inv_No__c, Account.Location__c, Account.Road_Name__c, Account.Postal_Code__c, '+
		// 							 'R_T_Agency__r.Name, R_T_Agency__c, Agent__c, WorkType.Name, WorkTypeId, StartDate, '+
		// 							 'EndDate, AccountId, Agent__r.Name, Appointment_Status__c'; 

		
		

		  String selectClause = 'SELECT Id, WorkOrderNumber,Account.Name,Account.Location__c, Account.Road_Name__c,Account.Building_name__c,Account.Postal_Code__c, '+ 'ServiceTerritory.Name,Agent__r.Name,WorkType.Name, '+ 'Appointment_Status__c';

				system.debug('select clause ::'+ selectClause);			 

        Integer offsetRows = (pageNumber - 1) * pageSize;
        String orderClause = ' ORDER BY CreatedDate ASC LIMIT ' + String.valueOf(pageSize) + ' OFFSET ' + String.valueOf(offsetRows);

        String finalQuery = selectClause + ' FROM WorkOrder' + whereClause + orderClause;

		System.debug('=========finalQuery========>'+finalQuery);

        List<WorkOrder> results = new List<WorkOrder>();
        if (!String.isBlank(finalQuery)) {
            results = Database.query(finalQuery);
        }

		System.debug('=========results========>'+results);
		System.debug('=========totalSize========>'+totalSize);

        PagedWorkOrders pw = new PagedWorkOrders();
        pw.records = results;
        pw.totalSize = totalSize;
        return pw;
    } 

  

}