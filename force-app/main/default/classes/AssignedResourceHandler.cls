public with sharing class AssignedResourceHandler {
public static void handleAfterInsert(List<AssignedResource> newResources) {
    if (newResources.isEmpty()) return;

    // Step 1: Collect Service Appointment IDs
    Set<Id> saIds = new Set<Id>();
    for (AssignedResource ar : newResources) {
        if (ar.ServiceAppointmentId != null) {
            saIds.add(ar.ServiceAppointmentId);
        }
    }

    if (saIds.isEmpty()) return;

    // Step 2: Fetch SMS Template from Case_Type_SMS__c
    Case_Type_SMS__c smsTemplate = [
        SELECT Status__c, Template_Id__c, Message__c, Sender__c
        FROM Case_Type_SMS__c
        WHERE Template_Name__c = 'O&M'
        LIMIT 1
    ];
    // Step 3: Query ServiceAppointment + AssignedResource + related data
    List<ServiceAppointment> appointments = [
        SELECT Id, SchedStartTime, SchedEndTime, Subject, AppointmentNumber,
               WorkType.Name,
               Account.Name,
               Account.Phone,
               (SELECT Id, ServiceResource.Name
                FROM ServiceResources)
        FROM ServiceAppointment
        WHERE Id IN :saIds
    ];

    for (ServiceAppointment sa : appointments) {
        if (sa.Account == null) continue;

        // Step 4: Prepare Merge Fields
        String assignedTech = (sa.ServiceResources != null && !sa.ServiceResources.isEmpty()) 
            ? sa.ServiceResources[0].ServiceResource.Name 
            : 'our technician';

        String scheduledDate = (sa.SchedStartTime != null) 
            ? sa.SchedStartTime.format('dd-MMM-yyyy') 
            : '';

        String scheduledStartTime = (sa.SchedStartTime != null) 
            ? sa.SchedStartTime.format('hh:mm a') 
            : '';

        String scheduledEndTime = (sa.SchedEndTime != null) 
            ? sa.SchedEndTime.format('hh:mm a') 
            : '';

        String activityType = (sa.WorkType != null) 
            ? sa.WorkType.Name 
            : 'the scheduled work';

        // Generate technician verification link dynamically
        String technicianLink = '';

        Map<String, String> mergeFields = new Map<String, String>{
            'assignedTech'      => assignedTech,
            'scheduledDate'     => scheduledDate,
            'scheduledStartTime'=> scheduledStartTime,
            'scheduledEndTime'  => scheduledEndTime,
            'activityType'      => activityType,
            'technicianLink'    => technicianLink
        };

        // Step 5: Merge Template Message with Fields
        String finalMessage = smsTemplate.Message__c;
        for (String key : mergeFields.keySet()) {
            finalMessage = finalMessage.replace('{' + key + '}', mergeFields.get(key));
        }

        // Step 6: Send SMS via API
        if (!String.isBlank(sa.Account.Phone)) {
            /*SmsApiCallout.sendSmsFuture(
                sa.Account.Phone,
                finalMessage,
                sa.Id,
                mergeFields,
                smsTemplate.Template_Id__c,
                smsTemplate.Sender__c
            );*/
        }
    }
}

}