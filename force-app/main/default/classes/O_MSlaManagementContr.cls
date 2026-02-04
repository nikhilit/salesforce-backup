public class O_MSlaManagementContr {


         public static void updateServiceAppointment(List<AssignedResource> lstAssignedResource){ 
            Integer TAT = Integer.valueOf(Label.Turnaround_Time_TAT);
            Integer IPDisconectionRubberHoseMeterReplacementTAT = 4;
            Integer DomesticMeterCheckingTAT = 5;
             
    
           Set<Id> serAppIds = new Set<Id>();
            for(AssignedResource assRes : lstAssignedResource){           
          
              serAppIds.add(assRes.ServiceAppointmentId);  

        }

        List<ServiceAppointment> lstSerApp = [Select id,ParentRecord.RecordType.Name,WorkType.Name from ServiceAppointment where Id IN:serAppIds AND ParentRecord.RecordType.Name ='MGL O&M'];

        List<ServiceAppointment> updateServApp = new List<ServiceAppointment>();

        for(ServiceAppointment serAppoin : lstSerApp){

            ServiceAppointment serAppointment = new ServiceAppointment();

             serAppointment.Id = serAppoin.Id;

             if(serAppoin.WorkType.Name =='Riser Maintenance'){

            serAppointment.Turnaround_Time_TAT__c=TAT;

             }
             if(serAppoin.WorkType.Name =='Meter Replacement' || serAppoin.WorkType.Name =='Rubber Hose Replacement' || serAppoin.WorkType.Name =='Individual Permanent Disconnection'){

            serAppointment.Turnaround_Time_TAT__c=IPDisconectionRubberHoseMeterReplacementTAT;
            
             }
            if(serAppoin.WorkType.Name =='Domestic Meter Checking'){

            serAppointment.Turnaround_Time_TAT__c=DomesticMeterCheckingTAT;
            
             }

            serAppointment.SLA_Status__c='On Track';
            serAppointment.Department__c='O&M';
            serAppointment.Status='Scheduled';

            updateServApp.add(serAppointment);
        }

        if(!updateServApp.isEmpty()){

            Update updateServApp;
        }
       
    }
}