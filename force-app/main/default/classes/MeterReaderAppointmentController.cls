public with sharing class MeterReaderAppointmentController {
    @AuraEnabled(cacheable=true)
    public static List<ServiceAppointment> getTodaysAppointmentsForUser(Id userId) {
		
        Date today = Date.today();
        
        DateTime startOfUtcDay = DateTime.newInstanceGmt(today, Time.newInstance(0, 0, 0, 0));
        DateTime endOfUtcDay = DateTime.newInstanceGmt(today, Time.newInstance(23, 59, 59, 999));

        return [
            SELECT Id, Status, SchedStartTime, SchedEndTime, Customer_Name__c, Customer_Address__c
            FROM ServiceAppointment
            WHERE 
                SchedStartTime >= :startOfUtcDay AND
                SchedStartTime <= :endOfUtcDay AND
                Assigned_Meter_Reader__r.RelatedRecordId = :userId
        ];
    }
}