/**
 * @description       : 
 * @author            : Neeraj dalal Appstrail
 * @group             : 
 * @last modified on  : 22-05-2025
 * @last modified by  : Neeraj dalal, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   18-05-2025   Neeraj dalal, Appstrail   Initial Version
**/
public class O_MWorkOrderAssignmentContr {

    public static void assignWorkOrder(List<WorkOrder> lstWorkOrder){

        try {
        
        String workOrderRecordTypeId = Schema.getGlobalDescribe().get('WorkOrder').getDescribe().getRecordTypeInfosByDeveloperName().get('MGL_O_M').getRecordTypeId();
        Map<Id,String> accId = new Map<Id,String>();

        Set<Id> worIds =  new Set<Id>();

            for(WorkOrder wOrder : lstWorkOrder){
                System.debug('Work order::>>' + wOrder + '\nwOrder.Id::>>' + wOrder.Id);
                if(wOrder.AccountId !=null && wOrder.Department__c !=null    && wOrder.RecordTypeId ==workOrderRecordTypeId){
                    if(wOrder.Department__c.contains('O&M')){
                    system.debug('inside if condition');
                    worIds.add(wOrder.Id);
                    }
                }
            }

            //&& wOrder.CaseId==null

    if(!worIds.isEmpty()) {

         List<WorkOrder> lstWorkOrders = [ SELECT Id, AccountId,WorkType.Name
                                                 FROM WorkOrder WHERE Id IN :worIds]; 

        system.debug('Work order details::'+ lstWorkOrders);

                  for(WorkOrder woOrder : lstWorkOrders){

                 accId.put(woOrder.AccountId, woOrder.WorkType.Name);
                 
                system.debug('Accid ::'+ accId);

                  }
                    
    }                          

        if(!accId.isEmpty()){
            List<Account>  lstAcc= [Select id,DRS_Master__c,DRS__c from Account where Id In:accId.keySet()];
            system.debug('Account ::'+ lstAcc);
        
        
           Map<Id, Id> mapAcc = new Map<Id, Id>();


               // Set<String> drsName = new Set<String>();

            
            for(Account acc : lstAcc){
                if(acc.DRS_Master__c !=null){
                  mapAcc.put(acc.Id,acc.DRS_Master__c);

                 // drsName.add(acc.DRS__c);
  
                }
            }

           // List<string> lstAgency = new List<string>();
            
            List<DRS_Contractor_Mapping_Master__c> lstDRSContMapMaster = [Select id,DRS__c,Agency__c,Activity_Name__c from DRS_Contractor_Mapping_Master__c where DRS__c IN:mapAcc.values()  AND Activity_Name__c IN:accId.values() ];
            system.debug('Drs cont map master:::'+ lstDRSContMapMaster);

            Map<Id, Id> mapDRS = new Map<Id, Id>();

                // Map<Id, DRS_Contractor_Mapping_Master__c> mapDRS = new Map<Id, DRS_Contractor_Mapping_Master__c>();

                Set<Id> setAgencyId = new Set<Id>();
                set<String> activityName = new Set<string>();

            for(DRS_Contractor_Mapping_Master__c drsContr : lstDRSContMapMaster){
                
                //  mapDRS.put(drsContr.DRS__c,drsContr);

                  setAgencyId.add(drsContr.Agency__c);
                  activityName.add(drsContr.Activity_Name__c);

               mapDRS.put(drsContr.DRS__c,drsContr.Agency__c);
             
             
               // lstAgency.add(drsContr.Agency__c);
                
            }

            system.debug('Map drs ::'+ mapDRS);
            
           // string agentId; 
           // system.debug('Agent Id:::'+ agentId);
            List<ServiceTerritoryMember> lstServiceTerritoryMember = [select id,ServiceTerritoryId,ServiceResource.Role__c,     
                                                                        ServiceResource.RelatedRecordId,ServiceResource.Activity_Name__c from ServiceTerritoryMember 
                                                                                  where ServiceTerritoryId IN:setAgencyId AND ServiceResource.Activity_Name__c IN:activityName];
    
            system.debug('ServiceTerritoryMember ::'+ lstServiceTerritoryMember);

            Map<Id, Id> mapSerTeam = new Map<Id, Id>();
            for(ServiceTerritoryMember servTerMember : lstServiceTerritoryMember){
                if(servTerMember.ServiceResource.Role__c=='Contractor'){

                    system.debug('inside role equal contractor');
    
                mapSerTeam.put(servTerMember.ServiceTerritoryId, servTerMember.ServiceResource.RelatedRecordId);
                   // agentId=servTerMember.ServiceResource.RelatedRecordId;
                   // break;
                }
            }
                    
                     List<WorkOrder> listUpdateWorkOrder=new List<WorkOrder>();
            for(WorkOrder wOrderUp : lstWorkOrder){

                system.debug('inside for loop of workorder');
                if( wOrderUp.AccountId!=null){
//(wOrderUp.caseId==null || wOrderUp.caseId=='')&&
                  system.debug('inside if condition case equal null and accountid not equal null');

                    
                    if(mapAcc.containsKey(wOrderUp.AccountId)){

                        system.debug('inside mapacc contains account id');

                        Id drsId=mapAcc.get(wOrderUp.AccountId);
                             WorkOrder wordUpd = new WorkOrder();

                        if(mapDRS.containsKey(drsId)){

                            system.debug('inside mapdrs contains drsid');
                            Id agencyId=mapDRS.get(drsId);

                            system.debug('agencyId ::'+ agencyId);
                            if(mapSerTeam.containsKey(agencyId))

                            system.debug('mapSerTeam containskey agencyId'+ mapSerTeam.containsKey(agencyId));

                            wordUpd.OwnerId=mapSerTeam.get(agencyId);
                            wordUpd.RecordTypeId=workOrderRecordTypeId;
                            wordUpd.ServiceTerritoryId = agencyId;

                            
                            wordUpd.Id = wOrderUp.Id;

                             listUpdateWorkOrder.add(wordUpd);

                             system.debug('singl wordUpd ::'+ wordUpd);
                        }
                    }
                                        
                }

            }

                    if(!listUpdateWorkOrder.isEmpty()){
                        update listUpdateWorkOrder;
                    }  

                    system.debug('listUpdateWorkOrder ::: '+ listUpdateWorkOrder);

       /*  List<WorkOrder> lstWorkOrd = [Select id,OwnerId,(Select id,OwnerId from ServiceAppointments) from WorkOrder where Id IN:listUpdateWorkOrder];
                          
              List<ServiceAppointment> appointmentsToUpdate = new List<ServiceAppointment>();

            for(WorkOrder wo : lstWorkOrd){
                for (ServiceAppointment sa : wo.ServiceAppointments) {
                ServiceAppointment serAppo = new ServiceAppointment();
           
               serAppo.Id = sa.Id;
               serAppo.OwnerId = wo.OwnerId;

			   appointmentsToUpdate.add(serAppo);
                }

}    

        if(!appointmentsToUpdate.isEmpty()){

            system.debug('updated serv app ::'+ appointmentsToUpdate);

            update appointmentsToUpdate;
        } */

         List<WorkOrder> updateWoTypePick = [Select id,WorkType.Name from WorkOrder where Id IN:listUpdateWorkOrder];
      
        List<WorkOrder> updateRubberHoseTypeOnly = new List<WorkOrder>();

                for(WorkOrder woTypePickUpd : updateWoTypePick){

                    if(woTypePickUpd.WorkType.Name == 'Rubber Hose Replacement'){

                        woTypePickUpd.Work_Order_Type__c='Rubber Hose Replacement';
                        updateRubberHoseTypeOnly.add(woTypePickUpd);
                    }
                }

                if(!updateRubberHoseTypeOnly.isEmpty()){

                    Update updateRubberHoseTypeOnly;
                }

                system.debug('updateRubberHoseTypeOnly:::'+ updateRubberHoseTypeOnly);

            }
        }   

         catch(Exception e){

        system.debug('Error update workorder ::'+ e.getLineNumber() + e.getMessage());
    }   

    }

   
               
  //  }

   
}