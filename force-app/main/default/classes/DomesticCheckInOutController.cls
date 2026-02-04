/**
 * @description       : 
 * @author            : Shashank.shekhar@appstrail.com
 * @group             : 
 * @last modified on  : 07-26-2025
 * @last modified by  : Shashank.shekhar@appstrail.com
**/
public without sharing class DomesticCheckInOutController {

    @AuraEnabled
    public static VisitDetail getServiceAppoinment(string recordId){
        try{
            ServiceAppointment serAppoinment = [SELECT ParentRecordId, Check_In_Timestamp__c, Check_Out_Timestamp__c, Check_In_Location__c, Check_Out_Location__c, Follow_Up_Visit_Date__c
                               FROM ServiceAppointment 
                              WHERE Id = :recordId OR ParentRecordId=:recordId
                           ORDER BY CreatedDate DESC
                              LIMIT 1];
            //return serAppoinment;

            List<WorkOrder> lstWO = [SELECT Check_In_Date_Time__c, Check_Out_Date_Time__c, Check_In_Location__c, Check_Out_Location__c, Follow_up_Date__c 
                                       FROM WorkOrder
                                      WHERE Id = :serAppoinment.ParentRecordId];

            if(!lstWO.isEmpty()){
                WorkOrder wo = lstWO.get(0);
                VisitDetail vd = new VisitDetail(
                    serAppoinment.Id,
                    serAppoinment.Follow_Up_Visit_Date__c,
                    wo.Check_In_Date_Time__c,
                    wo.Check_Out_Date_Time__c,
                    String.valueOf(wo.Check_In_Location__c),
                    String.valueOf(wo.Check_Out_Location__c)
                );

                return vd;
            }else{ 
                return null;
            }
        }catch(Exception e){
            AS_ErrorLogger.log('DomesticCheckInOutController', 'getServiceAppoinment', e, recordId);
            return null;
        }
    } 

    
    public class VisitDetail{
        @AuraEnabled public String serviceAppId;
        @AuraEnabled public Date followUpDate;
        @AuraEnabled public Datetime checkInDateTime;
        @AuraEnabled public Datetime checkOutDateTime;
        @AuraEnabled public String checkInLocation;
        @AuraEnabled public String checkOutLocation;
        public VisitDetail(String serviceAppId, Date followUpDate, Datetime checkInDateTime, Datetime checkOutDateTime, String checkInLocation, String checkOutLocation){
            this.serviceAppId = serviceAppId;
            this.followUpDate = followUpDate;
            this.checkInDateTime = checkInDateTime;
            this.checkOutDateTime = checkOutDateTime;
            this.checkInLocation = checkInLocation;
            this.checkOutLocation = checkOutLocation;
        }
    }
     
    @AuraEnabled
    public static string updateServiceAppoinment(String recordId, Double latitude, Double longitude, DateTime checkINDateTime, DateTime checkOutDateTime, string checkOutTime, string checkInTime, string checkInLocation, string checkOutLocation){
        
        try {
            
            System.debug('Inside Insert Attendence ::');
            System.debug('latitude::'+latitude) ;
            System.debug('longitude::'+longitude);
            
            String message = 'Success';
            
            ServiceAppointment serAppoinment = [SELECT Id, Check_In_Timestamp__c, Check_Out_Timestamp__c, Check_In_Location__c, 
                                                       Check_Out_Location__c,ParentRecordId,Appointment_Type__c,
                                                       FollowUpRemarks__c,Other_Follow_Up_Remark__c,Check_In_Location__latitude__s,
                                                       Check_In_Location__longitude__s, Status
                                                  FROM ServiceAppointment 
                                                 WHERE Id = :recordId
                                              ORDER BY CreatedDate DESC
                                                 LIMIT 1];

            WorkOrder workOrderRec = [SELECT Id, ServiceAppointmentCount__c FROM WorkOrder WHERE Id =: serAppoinment.ParentRecordId LIMIT 1];
            //workOrderRec.Id=serAppoinment.ParentRecordId;
            
            if  (checkInLocation =='' || checkInTime==''){

                serAppoinment.Check_In_Timestamp__c=checkINDateTime;
                serAppoinment.Check_In_Location__latitude__s = latitude;
                serAppoinment.Check_In_Location__longitude__s = longitude;
                serAppoinment.Check_Out_Timestamp__c=null;
                serAppoinment.Check_Out_Location__latitude__s =null;
                serAppoinment.Check_Out_Location__longitude__s =null;
                serAppoinment.Status='In Progress';
                serAppoinment.Appointment_Type__c = 'In Progress';

                workOrderRec.Check_In_Date_Time__c=checkINDateTime;
                workOrderRec.Check_In_Location__Latitude__s=latitude;
                workOrderRec.Check_In_Location__Longitude__s=longitude;
                workOrderRec.Status = 'In Progress';
                workOrderRec.Appointment_Status__c = 'In Progress';
				
                message = 'Check In Successfully';

            }else if(checkOutLocation=='' || checkOutTime==''){
                
                serAppoinment.Check_Out_Timestamp__c=checkOutDateTime;
                serAppoinment.Check_Out_Location__latitude__s = latitude;
                serAppoinment.Check_Out_Location__longitude__s = longitude;
                serAppoinment.Status='Completed';
                serAppoinment.Appointment_Type__c = 'Completed';

                // workOrderRec.Check_Out_Date_Time__c=checkOutDateTime;
                // workOrderRec.Check_Out_Location__Latitude__s=latitude;
                // workOrderRec.Check_Out_Location__Longitude__s=longitude;
                
                workOrderRec.Check_In_Date_Time__c = serAppoinment.Check_In_Timestamp__c;
                workOrderRec.Check_In_Location__latitude__s = serAppoinment.Check_In_Location__latitude__s;
                workOrderRec.Check_In_Location__longitude__s = serAppoinment.Check_In_Location__longitude__s;
                workOrderRec.Check_Out_Date_Time__c = checkOutDateTime;
                workOrderRec.Check_Out_Location__Latitude__s = latitude;
                workOrderRec.Check_Out_Location__Longitude__s = longitude;
                workOrderRec.Follow_up_Remarks__c = serAppoinment.FollowUpRemarks__c;
                workOrderRec.Other_Follow_Up_Remark__c = serAppoinment.Other_Follow_Up_Remark__c;

                Decimal count = workOrderRec.ServiceAppointmentCount__c == null ? 0 : workOrderRec.ServiceAppointmentCount__c;
                workOrderRec.ServiceAppointmentCount__c = count + 1;
                
                workOrderRec.Status='Completed';
                workOrderRec.Appointment_Status__c = 'Completed';
				
                message = 'Check Out Successfully';
            }
            
            update workOrderRec;
            update serAppoinment;
            
            if(message=='Check In Successfully'){
                updateWorkStepStatus(serAppoinment.ParentRecordId,'Check In');
            }else if(message=='Check Out Successfully'){
                updateWorkStepStatus(serAppoinment.ParentRecordId,'Check Out');
            }
            return message;
        }
        catch(Exception e) {
            AS_ErrorLogger.log('DomesticCheckInOutController', 'updateServiceAppoinment', e, recordId);
            return 'Error'+ e.getMessage();
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
}