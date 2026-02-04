/**
 * @description       :
 * @author            : Kartik Patkar Appstrail
 * @group             :
 * @last modified on  : 28-05-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   19-05-2025   Kartik Patkar, Appstrail   Initial Version
 **/
public without sharing class CheckInCheckOutCompContr {
    
        @AuraEnabled
        public static ServiceAppointment getCheckInStatus(string recordId) {
        
        try {
            
            
            ServiceAppointment sa = [
                SELECT Id, O_MCheckInTimestamp__c,O_MCheckOutTimestamp__c,Check_In_Lat_Long__c,Check_Out_Lat_Long__c	
                FROM ServiceAppointment
                WHERE Id = :recordId OR ParentRecordId =:recordId limit 1
                
            ];
            System.debug('checkin and out data::>>' + sa);
            return sa;

           

           
        } catch (Exception e) {
            //return null;
            throw new AuraHandledException('Error fetching appointment data: ' + e.getMessage());
            

        }

        
    }

    @AuraEnabled
    public static String updateServiceAppoinment(String recordId, Double lat, Double lon,Boolean checkIn, DateTime currentDateTime) {
        System.debug('==== markCheckIn Called ====');
        System.debug('Appointment ID: ' + recordId);
        System.debug('Input Lat: ' + lat);
        System.debug('Input Lon: ' + lon);
        


        try {

            // Validate input
            if (recordId == null || lat == null || lon == null) {
                system.debug('inside missing value');
                return 'MISSING_VALUES';
            }

             String message = 'Success';


          
            // Fetch appointment
            ServiceAppointment sa = [
                SELECT Id,ParentRecordId, O_MCheckInTimestamp__c,O_MCheckOutTimestamp__c,Check_In_Lat_Long__c,
                Check_Out_Lat_Long__c,Scheduled_Location__latitude__s, Scheduled_Location__longitude__s,
                ServiceTerritoryId
                 FROM ServiceAppointment WHERE Id = :recordId OR ParentRecordId = :recordId LIMIT 1
            ];



         //   WorkOrder wOrderUpd = [Select id,ServiceTerritoryId,Appointment_Status__c,Completion_Datetime__c from WorkOrder Where Id=: sa.ParentRecordId];

          //system.debug('Work order ::'+ wOrderUpd);

            // Calculate distance
             Double distanceKm = calculateHaversineDistance(
              (Double) sa.Scheduled_Location__latitude__s,
              (Double) sa.Scheduled_Location__longitude__s,
                lat,lon); 
            System.debug('Distance (km): ' + distanceKm);
            Double distanceMeters = distanceKm * 1000;
           System.debug('Distance (meters): ' + distanceMeters);
          Double allowedRadius = 1000.0;
            System.debug('Scheduled Lat: ' + sa.Scheduled_Location__latitude__s);
        System.debug('Scheduled Lon: ' + sa.Scheduled_Location__longitude__s);

             if (distanceMeters > allowedRadius) {
                 system.debug('insdie too far location');
                 message = 'TOO_FAR_FROM_LOCATION';
               return 'TOO_FAR_FROM_LOCATION';

             } 

            // Update check-in info
            // if(sa.Check_In_Lat_Long__c == null){

            system.debug('check in ::'+ checkIn);
            if(checkIn){
                system.debug('inside if');
            sa.O_MCheckInTimestamp__c=currentDateTime ;
            sa.Check_In_Lat_Long__latitude__s= lat;
            sa.Check_In_Lat_Long__longitude__s=lon;
            sa.Status='In Progress';
          //  sa.ServiceTerritoryId = wOrderUpd.ServiceTerritoryId;

            //wOrderUpd.Appointment_Status__c='In Progress';
            //update wOrderUpd;

                message = 'Check In Successfully';
            }
             
            
            
            else if(checkIn==false) {
                system.debug('inside else if');
            sa.O_MCheckOutTimestamp__c= currentDateTime;
            sa.Check_Out_Lat_Long__latitude__s = lat;
            sa.Check_Out_Lat_Long__longitude__s=lon;
            sa.Status='Completed';
           // wOrderUpd.Appointment_Status__c='Completed';
            //wOrderUpd.Completion_Datetime__c= System.now();


                //update wOrderUpd;
              //  system.debug('update work order::'+wOrderUpd);

                message = 'Check Out Successfully';

            }

             update sa;
            // sa.Status='Completed';
            // update sa;
             system.debug('Service appointment ::'+ sa);
            if(message=='Check In Successfully'){
                updateWorkStepStatus(sa.ParentRecordId,'Check In');
            }else if(message=='Check Out Successfully'){
                updateWorkStepStatus(sa.ParentRecordId,'Check Out');
            }
            return message;
           // }

// 			else {
//     // Already checked in, optionally handle this scenario
//     return 'ALREADY_CHECKED_IN';
// }

           

        } catch (Exception e) {
            System.debug('Check-in Error: ' + e.getMessage() + e.getLineNumber());
            return e.getMessage();
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

    // Haversine formula
    private static Double calculateHaversineDistance(Double lat1, Double lon1, Double lat2, Double lon2) {
        Double R = 6371.0;
        Double dLat = degreesToRadians(lat2 - lat1);
        Double dLon = degreesToRadians(lon2 - lon1);
        Double a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
                   Math.cos(degreesToRadians(lat1)) * Math.cos(degreesToRadians(lat2)) *
                   Math.sin(dLon / 2) * Math.sin(dLon / 2);
        Double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    }
  

    private static Double degreesToRadians(Double degrees) {
        return degrees * Math.PI / 180;
    }


     @AuraEnabled
    public static void checkWorkStep(string recordId){

     /*   try {

            System.debug('inside check work step method in apex');
             System.debug('Record id::'+ recordId);

             String checkInStatus = '';
             String uploadExecutionDetail= '';

        WorkOrder worder = [select id,WorkTypeId,WorkType.Name  from workorder where  id=: recordId];

    if(worder.WorkType.Name=='Riser Painting'){
     List<WorkStep> worStep = [SELECT Id, Status,Name
			FROM WorkStep
			WHERE ParentRecordId =: recordId AND Name IN ('Check-in', 'CO Execution Detail')];
   
     for(WorkStep woStep : worStep){
         if (woStep.Name == 'Check-in') {
            system.debug('Work order ::'+ woStep.Status);

            checkInStatus = woStep.Status;
        

        } else{
            system.debug('Work order ::'+ woStep.Status);
            uploadExecutionDetail = woStep.Status;
        }


    }

    if (checkInStatus != 'Completed' && uploadExecutionDetail != 'Completed') {
        system.debug('Check in '+ checkInStatus + ' '+ uploadExecutionDetail);
        return 'riserPaintingSuccess';
    }
     if (checkInStatus == 'Completed' && uploadExecutionDetail != 'Completed') {
        system.debug('Check in '+ checkInStatus + ' '+ uploadExecutionDetail);
        return 'riserPainting';
    }
   
    }
    else{
       List<WorkStep> worStep = [SELECT Id, Status,Name
			FROM WorkStep
			WHERE ParentRecordId =: recordId AND Name IN ('Check-in', 'Service Report')];
    
    for(WorkStep woStep : worStep){
         if (woStep.Name == 'Check-in') {
            system.debug('Work order ::'+ woStep.Status);

            checkInStatus = woStep.Status;
        

        } else{
            system.debug('Work order ::'+ woStep.Status);
            uploadExecutionDetail = woStep.Status;
        }

    }

    if (checkInStatus != 'Completed' && uploadExecutionDetail != 'Completed') {
        system.debug('Check in '+ checkInStatus + ' '+ uploadExecutionDetail);
        return 'Success';
    }
     if (checkInStatus == 'Completed' && uploadExecutionDetail != 'Completed') {
        system.debug('Check in '+ checkInStatus + ' '+ uploadExecutionDetail);
        return 'showWarning';
    }

    }

 

    return 'OK';

    // system.debug('Work step result ::'+ worStep.Status);
    //     return worStep.Status;
    
    }
    catch(Exception e){
        return 'Error';
    } */
			
    } 
}