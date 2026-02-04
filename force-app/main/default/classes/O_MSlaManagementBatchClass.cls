global class O_MSlaManagementBatchClass implements Database.Batchable<sObject> {
   
     global Database.QueryLocator start(Database.BatchableContext BC)
    {
       
        system.debug('inside batch class start method');
        try{
                              
          return Database.getQueryLocator([SELECT id,Turnaround_Time_TAT__c,SLA_Status__c,Breach_Timestamp__c from ServiceAppointment where (SLA_Status__c='On Track' or SLA_Status__c='SLA Breached') and Turnaround_Time_TAT__c !=null]);
         
        }
        catch(Exception e){
            system.debug('Error ::'+ e.getMessage() + '  ' + e.getLineNumber());
            return null;
        }
       
    }
   
    global void execute(Database.BatchableContext BC, List<ServiceAppointment> serAppointmentList) {


        try {
                            
        system.debug('insdie execute method'+ serAppointmentList);
        List<ServiceAppointment> lstServiceAppointment = new List<ServiceAppointment>();


        for (ServiceAppointment serApp : serAppointmentList) {
           
            //serApp.Turnaround_Time_TAT__c = (serApp.Turnaround_Time_TAT__c == null ? 0 : serApp.Turnaround_Time_TAT__c) - 1;
				serApp.Turnaround_Time_TAT__c -= 1;
             if (serApp.Turnaround_Time_TAT__c <= 0) {
                serApp.SLA_Status__c = 'SLA Breached';
                serApp.Breach_Timestamp__c = System.now();                           
            }
             lstServiceAppointment.add(serApp);  
        }
                    
            if(!lstServiceAppointment.isEmpty()){
                system.debug('List of updated serviceappointment ::'+ lstServiceAppointment);
            update lstServiceAppointment;
            system.debug('After insert::'+ lstServiceAppointment);
                    
             }

             List<ServiceAppointment> lstUpdateServiceAppointment = [Select id,ParentRecordId from ServiceAppointment where Id IN:lstServiceAppointment];


            Set<String> lstWorkOrderUpd = new Set<String>();

            if(!lstUpdateServiceAppointment.isEmpty()){

             for(ServiceAppointment serAppoi : lstUpdateServiceAppointment){


                lstWorkOrderUpd.add(serAppoi.ParentRecordId); 

             }

            }

             system.debug('lstWorkOrderUpd ::'+ lstWorkOrderUpd);

             if(!lstWorkOrderUpd.isEmpty()){

             List<WorkOrder> updateWoList = [Select id,Priority from WorkOrder Where Id IN:lstWorkOrderUpd];

             for(WorkOrder updWo : updateWoList){

                updWo.Priority='Critical';
             }

                 update updateWoList;

                 system.debug('Final wokrorder list updated::'+ updateWoList);


             }

        }

        catch(Exception e){

            system.debug('Error::'+ e.getLineNumber() + e.getMessage());
        }
    
                             
    }
   
     global void finish(Database.BatchableContext BC)
    {
        system.debug('Batch job completed.');
    }
}


// global class O_MSlaManagementBatchClass implements Database.Batchable<sObject> {
   
//      global Database.QueryLocator start(Database.BatchableContext BC)
//     {
       
//         system.debug('inside batch class start method');
//         try{
                              
//           return Database.getQueryLocator([SELECT id,Turnaround_Time_TAT__c,SLA_Status__c,Breach_Timestamp__c from ServiceAppointment where (SLA_Status__c='On Track' or SLA_Status__c='SLA Breached') and Turnaround_Time_TAT__c !=null]);
         
//         }
//         catch(Exception e){
//             system.debug('Error ::'+ e.getMessage() + '  ' + e.getLineNumber());
//             return null;
//         }
       
//     }
   
//     global void execute(Database.BatchableContext BC, List<ServiceAppointment> serAppointmentList) {


//         try{
                            
//         system.debug('insdie execute method'+ serAppointmentList);
//         List<ServiceAppointment> lstServiceAppointment = new List<ServiceAppointment>();

//         for (ServiceAppointment serApp : serAppointmentList) {
           
//             //serApp.Turnaround_Time_TAT__c = (serApp.Turnaround_Time_TAT__c == null ? 0 : serApp.Turnaround_Time_TAT__c) - 1;
// 				serApp.Turnaround_Time_TAT__c -= 1;
//              if (serApp.Turnaround_Time_TAT__c <= 0) {
//                 serApp.SLA_Status__c = 'SLA Breached';
//                 serApp.Breach_Timestamp__c = System.now();                           
//             }
//              lstServiceAppointment.add(serApp);  
//         }
                    
//             if(!lstServiceAppointment.isEmpty()){
//                 system.debug('List of updated serviceappointment ::'+ lstServiceAppointment);
//             update lstServiceAppointment;
//             system.debug('After insert::'+ lstServiceAppointment);
                    
//              }
//         }
//         catch(Exception e){

//             system.debug('error::'+ e.getLineNumber() + e.getMessage());
//         }
                             
//     }
   
//      global void finish(Database.BatchableContext BC)
//     {
//         system.debug('Batch job completed.');
//     }
// }