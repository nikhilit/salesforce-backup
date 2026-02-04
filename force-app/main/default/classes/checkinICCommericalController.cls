/**
* @File Name : checkinICCommericalController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : December 1, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | December 1, 2025 |   | Initial Version
**/

public without sharing class checkinICCommericalController {


    @AuraEnabled
    public static WorkOrder checkUploadSiteDocumentApproved(string recordId){

        try {

            WorkOrder wo =[Select id,Approval_Status__c,Appointment_Status__c,WorkType.Name,(select id,name,status from worksteps where name='check-in' and Status='Completed') from workorder where id=: recordId and (Appointment_Status__c ='In Progress' or Appointment_Status__c='Completed' or Appointment_Status__c !='Unattempted')
             and (worktype.name='Riser Maintenance' or worktype.name='Riser Replacement' or worktype.name='Riser Painting' or worktype.name='Individual Permanent Disconnection') ];
            return wo;


        }
        catch(Exception e){

            system.debug('Error ::'+ e.getLineNumber() + e.getMessage());

            return new WorkOrder();
        }
    }

    public class CheckInControllerWrapper {
        @AuraEnabled public Document__c documentRecordDetail {get; set;}
        @AuraEnabled public String profileName {get; set;}
    }


     @AuraEnabled
    public static CheckInControllerWrapper getApprovalStatus() {

        try{

            //userDetail.Profile.Name =='Domestic Meter Checking Field Agent' || userDetail.Profile.Name =='O&M Field Agent DOMESTIC METER CHECKING' ||  userDetail.Profile.Name =='O&M Supervisor DOMESTIC METER CHECKING'
//userDetail.Profile.Name =='Rubber Hose Field Agent' || userDetail.Profile.Name =='O&M Rubber Hose Supervisor' || userDetail.Profile.Name =='O&M Rubber Hose Field Agent'
            User userDetail = [Select id,Name,UserName,Profile.Name from User Where Id=: userInfo.getUserId()];

            Document__c doucmentRecord = [Select id,Submitted_Agent_Name__c,Approval_Status_O_M__c	from Document__c where Submitted_Agent_Name__c=: userDetail.UserName];

          CheckInControllerWrapper result = new CheckInControllerWrapper();
            result.documentRecordDetail = doucmentRecord;
            result.profileName = userDetail.Profile.Name;
            return result;

    }
    catch(Exception e){

         return new CheckInControllerWrapper(); 
    }

    }

    
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



            WorkOrder wOrderUpd = [Select id,ServiceTerritoryId,Appointment_Status__c,Completion_Datetime__c,Attended_Date__c from WorkOrder Where Id=: sa.ParentRecordId];

          	system.debug('Work order ::'+ wOrderUpd);

 			List<WorkOrderLineItem> lstWorkOrderLItem = [Select id,Riser_Tested_Status__c from WorkOrderLineItem
                                                 Where Riser_Tested_Status__c='Not OK' AND WorkOrderId=:recordId];

            system.debug('check in ::'+ checkIn);
            if(checkIn){
                system.debug('inside if');
            sa.O_MCheckInTimestamp__c=currentDateTime ;
            sa.Check_In_Lat_Long__latitude__s= lat;
            sa.Check_In_Lat_Long__longitude__s=lon;

             system.debug('inside before if conditon appointment status in progress or completed'+ wOrderUpd.Appointment_Status__c);

            if(wOrderUpd.Appointment_Status__c !='In Progress'){

                system.debug('inside if conditon appointment status in progress or completed'+ wOrderUpd.Appointment_Status__c);
            sa.Status='In Progress';
           
            sa.ServiceTerritoryId = wOrderUpd.ServiceTerritoryId;

            wOrderUpd.Appointment_Status__c='In Progress';
            wOrderUpd.Attended_Date__c	= system.today();
            update wOrderUpd;
           
            }
                message = 'Check In Successfully';
            }
            else if(checkIn==false) {
                system.debug('inside else if');
            sa.O_MCheckOutTimestamp__c= currentDateTime;
            sa.Check_Out_Lat_Long__latitude__s = lat;
            sa.Check_Out_Lat_Long__longitude__s=lon;

                system.debug('inside before check out if conditon appointment status in progress or completed'+ wOrderUpd.Appointment_Status__c);


            if(lstWorkOrderLItem.isEmpty() && wOrderUpd.Appointment_Status__c !='Completed'){

             system.debug('inside if conditon check out appointment status in progress or completed'+ wOrderUpd.Appointment_Status__c);


            sa.Status='Completed';
            wOrderUpd.Appointment_Status__c='Completed';
            wOrderUpd.Completion_Datetime__c= System.now();
                update wOrderUpd;
            }
                system.debug('update work order::'+wOrderUpd);

                message = 'Check Out Successfully';

            }

             update sa;
             system.debug('Service appointment ::'+ sa);
            if(message=='Check In Successfully'){
                updateWorkStepStatus(sa.ParentRecordId,'Check-in');
            }else if(message=='Check Out Successfully'){
                updateWorkStepStatus(sa.ParentRecordId,'Check-out');
            }
            return message;
    
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


     @AuraEnabled
    public static string checkWorkStep(string recordId){

        try {

            System.debug('inside check work step method in apex');
             System.debug('Record id::'+ recordId);

             String checkInStatus = '';
             String uploadExecutionDetail= '';

        WorkOrder worder = [select id,WorkTypeId,WorkType.Name  from workorder where  id=: recordId];

    if(worder.WorkType.Name=='Riser Painting' || worder.WorkType.Name=='Riser Maintenance' || worder.WorkType.Name=='Riser Replacement' ){
     List<WorkStep> worStep = [SELECT Id, Status,Name
			FROM WorkStep
			WHERE ParentRecordId =: recordId AND Name IN ('Check-in', 'CO Execution Detail' )];
   
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

     if(worder.WorkType.Name=='Domestic Meter Checking'){
     List<WorkStep> worStep = [SELECT Id, Status,Name
			FROM WorkStep
			WHERE ParentRecordId =: recordId AND Name IN ('Check-in', 'Site Details' )];
   
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
        return 'domesticMeterCheckingSuccess';
    }
     if (checkInStatus == 'Completed' && uploadExecutionDetail != 'Completed') {
        system.debug('Check in '+ checkInStatus + ' '+ uploadExecutionDetail);
        return 'domesticMeterChecking';
    }
   
    }
    else{
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
        return 'Success';
    }
     if (checkInStatus == 'Completed' && uploadExecutionDetail != 'Completed') {
        system.debug('Check in '+ checkInStatus + ' '+ uploadExecutionDetail);
        return 'showWarning';
    }

    }

    return 'OK';
    
    }
    catch(Exception e){
        return 'Error';
    }
			
    }
}