public class ServiceReportPdfQueueable implements Queueable, Database.AllowsCallouts {
    private Id workOrderId;
    private Integer attempt;
    private static final Integer MAX_RETRIES = 3;

    // Constructor: start with attempt = 0
    public ServiceReportPdfQueueable(Id workOrderId) {
        this(workOrderId, 0);
    }

    public ServiceReportPdfQueueable(Id workOrderId, Integer attempt) {
        this.workOrderId = workOrderId;
        this.attempt = (attempt == null) ? 0 : attempt;
    }

    public void execute(QueueableContext ctx) {
        try {
            System.debug('ServiceReportPdfQueueable START - WorkOrderId=' + workOrderId + ' attempt=' + attempt);

            // Re-query the WorkOrder with all fields your VF controller reads
            WorkOrder wo = [
                SELECT 
                    Id,
                    WorkOrderNumber,
                    BP_Customer_Address__c,
                    BP_Number__c,
                    Account.FirstName__c,
                    Account.LastName__c,
                    Account.Name,
                    Account.Customer_Contact_no__c,
                    O_M_Source__c,
                    Penumatic_Pressure_Test_At_32_mba__c,
                    CreatedDate,
                    Completion_Datetime__c,
                    Leak_Test_With_SOAP_Solution__c,
                    Gascoseeker_Reading__c,
                    Rubber_Tube_Type__c,
                    Ensure_No_Gas_Leakage_Before_LeavingSit__c,
                    Reason_MetRep_Pdf__c,
                    Action_Taken_MetRep_Pdf__c,
                    Material_Recovered__c,
                    Owner.Name,
                    ServiceTerritory.Name,
                    Agent__r.Name,
                    Agent__r.Supervisor__c,
                    Agent__r.Supervisor__r.Name,
                    Satisfactory__c,
                    Not_Satisfactory__c,
                    Rubber_Tube_Condition__c,
                    Old_Meter_Make__c,
                    Old_Meter_Serial_No__c,
                    Old_Meter_Reading__c,
                    Old_Remark__c,
                    New_Meter_Make__c,
                    New_Meter_Serial_No__c,
                    New_Meter_Reading__c,
                    New_Remark__c,
                    Subject,
                    Description,
                    The_Work_Done__c,
                    Meter_No_SR__c,
                    Meter_Reading_SR__c,
                    Rubber_Hose_Expiry_Date__c,
                    Check_In_Location__c,
                    Check_Out_Location__c
                FROM WorkOrder
                WHERE Id = :workOrderId
                LIMIT 1
            ];

            // DEBUG: dump the WorkOrder so you can see exactly what the Queueable saw
            System.debug('ServiceReportPdfQueueable - re-query result: ' + JSON.serializePretty(wo));

            // Define the *critical* fields your VF must have before rendering.
            // Adjust this list if VF needs more/less fields.
            List<String> missingFields = new List<String>();

            // Helper inline checks for common field types:
            if (wo.BP_Number__c == null || String.valueOf(wo.BP_Number__c).trim() == '') missingFields.add('BP_Number__c');
            if (wo.The_Work_Done__c == null || String.valueOf(wo.The_Work_Done__c).trim() == '') missingFields.add('The_Work_Done__c');
            if (wo.Satisfactory__c == null && wo.Not_Satisfactory__c == null) missingFields.add('Satisfactory__c / Not_Satisfactory__c');
            // VF uses Account fields too:
            if (wo.Account == null || (String.isBlank(wo.Account.FirstName__c) && String.isBlank(wo.Account.LastName__c) && String.isBlank(wo.Account.Name))) {
                missingFields.add('Account Name / First/Last');
            }
            // Example: check Old_Meter_Serial_No__c (adjust / add checks as needed)
            if (wo.Old_Meter_Serial_No__c == null || String.valueOf(wo.Old_Meter_Serial_No__c).trim() == '') missingFields.add('Old_Meter_Serial_No__c');

            if (!missingFields.isEmpty()) {
                System.debug('ServiceReportPdfQueueable - missingFields: ' + missingFields + ' (attempt=' + attempt + ')');

                // if we have retries left, re-enqueue
                if (attempt < MAX_RETRIES) {
                    Integer nextAttempt = attempt + 1;
                    System.debug('ServiceReportPdfQueueable - re-enqueueing for attempt ' + nextAttempt);
                    // Re-enqueue a new instance with incremented attempt count
                    System.enqueueJob(new ServiceReportPdfQueueable(workOrderId, nextAttempt));
                    return; // exit this execution
                } else {
                    // Retries exhausted: log and proceed to render anyway (or bail - choose approach)
                    System.debug('ServiceReportPdfQueueable - max retries reached, proceeding to render even with missing fields.');
                }
            } else {
                System.debug('ServiceReportPdfQueueable - required fields present, proceeding to render.');
            }

            // Prepare the PDF blob (avoid getContentAsPDF in tests)
            Blob pdfBlob;
            if (Test.isRunningTest()) {
                pdfBlob = Blob.valueOf('Test PDF content for WorkOrder ' + String.valueOf(workOrderId));
            } else {
               PageReference pdfPage = Page.MRJCReport;
                // MRJCReportContr expects parameter 'Id' (case-sensitive); pass exactly 'Id'
                pdfPage.getParameters().put('Id', String.valueOf(workOrderId));
                pdfBlob = pdfPage.getContentAsPDF();
            }

            // Insert ContentVersion and link to WorkOrder
            ContentVersion cv = new ContentVersion();
            cv.Title = 'Service Report ' + (wo.BP_Number__c != null ? wo.BP_Number__c : (wo.WorkOrderNumber != null ? wo.WorkOrderNumber : String.valueOf(workOrderId)));
            cv.PathOnClient = 'ServiceReport_' + String.valueOf(workOrderId) + '.pdf';
            cv.VersionData = pdfBlob;
            insert cv;

            ContentVersion insertedCv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];

            ContentDocumentLink cdl = new ContentDocumentLink(
                ContentDocumentId = insertedCv.ContentDocumentId,
                LinkedEntityId = workOrderId,
                ShareType = 'V',
                Visibility = 'AllUsers'
            );
            insert cdl;

            System.debug('ServiceReportPdfQueueable: PDF created and linked. WorkOrderId=' + workOrderId + ' ContentDocumentId=' + insertedCv.ContentDocumentId);

        } catch (Exception ex) {
            System.debug('ServiceReportPdfQueueable ERROR for WorkOrder ' + workOrderId + ' attempt=' + attempt + ' : ' + ex.getMessage());
        }
    }
}