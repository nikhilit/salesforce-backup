public without sharing class DMCReportContr {
    // Customer Information
    public String customerName { get; set; }
    public String customerAddress { get; set; }
    public String notificationNo { get; set; }
    public String contactNo { get; set; }
    public String bpNumber { get; set; }
    public String receivedFrom { get; set; }
    public String receivedDate { get; set; }
    public String receivedTime { get; set; }
    public String attendedDate { get; set; }
    public String attendedTime { get; set; }

    // Test Results
    public String leakTestSOAP { get; set; }
    public String pneumaticPressureTest { get; set; }
    public String gascoSeekerReading { get; set; }
    public String noGasLeakage { get; set; }
    public String rubberTubeType { get; set; }
    public String rubberTubeCondition { get; set; }

    // Material Details
    public String materialUsed { get; set; }
    public String materialRecovered { get; set; }
    public String oldMeterMake { get; set; }
    public String oldMeterSerialNo { get; set; }
    public String oldMeterReading { get; set; }
    public String oldMeterRemark { get; set; }
    public String newMeterMake { get; set; }
    public String newMeterSerialNo { get; set; }
    public String newMeterReading { get; set; }
    public String newMeterRemark { get; set; }

    // Personnel
    public String contSupName { get; set; }
    public String contTechName { get; set; }
    public String contractorName { get; set; }

    // Status
    public String satisOrNotSatisfactory { get; set; }
    public String natureOfWork { get; set; }
    public String reasonMetRep { get; set; }
    public String actionTakenMetRep { get; set; }
    public String isCustomerUsingGas { get; set; }
    public String isMeterAvailable { get; set; }
    public String meterStatus { get; set; }
    public Decimal beforeMeterReading { get; set; }
    public Decimal afterMeterReading { get; set; }
    public String abnormalReadingReason { get; set; }

    public List<Material_Consumption__c> materialConsuption { get; set; }

    public DMCReportContr() {
        String workOrderId = ApexPages.currentPage().getParameters().get('id');
        this.materialUsed = ApexPages.currentPage().getParameters().get('materialUsed');

        if (String.isNotBlank(workOrderId)) {
            try {
                WorkOrder wo = [SELECT 
                    Account.FirstName__c,
                    Account.LastName__c,
                    BP_Customer_Address__c,
                    BP_Number__c,
                    Account.Customer_Contact_no__c,
                    WorkOrderNumber,
                    O_M_Source__c,
                    Completion_Datetime__c,
                    CreatedDate,
                    Leak_Test_With_SOAP_Solution__c,
                    Penumatic_Pressure_Test_At_32_mba__c,
                    Ensure_No_Gas_Leakage_Before_LeavingSit__c,
                    Gascoseeker_Reading__c,
                    Rubber_Tube_Type__c,
                    Rubber_Tube_Condition__c,
                    Old_Meter_Make__c,
                    Old_Meter_Serial_No__c,
                    Old_Meter_Reading__c,
                    Old_Remark__c,
                    New_Meter_Make__c,
                    New_Meter_Serial_No__c,
                    New_Meter_Reading__c,
                    New_Remark__c,
                    Owner.Name,
                    ServiceTerritory.Name,
                    Agent__r.Name,
                    Satisfactory__c,
                    Not_Satisfactory__c,
                   // Nature_of_work_type_of_request__c,
                    Reason_MetRep_Pdf__c,
                    Action_Taken_MetRep_Pdf__c,
                    Material_Recovered__c,
                    Is_Customer_Using_Gas__c,
                    Is_Meter_Available__c,
                    Meter_Status__c,
                    Before_Meter_Reading__c,
                    After_Meter_Reading__c,
                     Final_Remark__c,
                    Abnormal_Reading_Reason__c
                FROM WorkOrder WHERE Id = :workOrderId];

                materialConsuption = [SELECT Item_description__c, Quantity__c 
                                     FROM Material_Consumption__c 
                                     WHERE Work_Order__c = :workOrderId];

                // Basic Customer Info  Item_Code__c
                customerName = wo.Account.FirstName__c + ' ' + wo.Account.LastName__c;
                customerAddress = wo.BP_Customer_Address__c;
                contactNo = wo.Account.Customer_Contact_no__c;
                bpNumber = wo.BP_Number__c;
                notificationNo = wo.WorkOrderNumber;
                receivedFrom = wo.Owner.Name;

                // Date/Time Formatting
                if (wo.CreatedDate != null) {
                    receivedDate = wo.CreatedDate.format('dd-MM-yyyy');
                    receivedTime = wo.CreatedDate.format('HH:mm:ss');
                }
                if (wo.Completion_Datetime__c != null) {
                    attendedDate = wo.Completion_Datetime__c.format('dd-MM-yyyy');
                    attendedTime = wo.Completion_Datetime__c.format('HH:mm:ss');
                }

                // Test Results
                leakTestSOAP = wo.Leak_Test_With_SOAP_Solution__c;
                pneumaticPressureTest = wo.Penumatic_Pressure_Test_At_32_mba__c;
                noGasLeakage = wo.Ensure_No_Gas_Leakage_Before_LeavingSit__c;
                gascoSeekerReading = wo.Gascoseeker_Reading__c;
                rubberTubeType = wo.Rubber_Tube_Type__c;
                rubberTubeCondition = wo.Rubber_Tube_Condition__c;

                // Material Details
                materialRecovered = wo.Material_Recovered__c;
                oldMeterMake = wo.Old_Meter_Make__c;
                oldMeterSerialNo = wo.Old_Meter_Serial_No__c;
                oldMeterReading = wo.Old_Meter_Reading__c;
                oldMeterRemark = wo.Old_Remark__c;
                newMeterMake = wo.New_Meter_Make__c;
                newMeterSerialNo = wo.New_Meter_Serial_No__c;
                newMeterReading = wo.New_Meter_Reading__c;
                newMeterRemark = wo.New_Remark__c;

                // Personnel
                contTechName = wo.Agent__r.Name;
                contSupName = wo.Owner.Name;
                contractorName = wo.ServiceTerritory.Name;

                // Status
               // natureOfWork = wo.Nature_of_work_type_of_request__c;
                reasonMetRep = wo.Reason_MetRep_Pdf__c;
                actionTakenMetRep = wo.Final_Remark__c;
                isCustomerUsingGas = String.valueOf(wo.Is_Customer_Using_Gas__c);
                isMeterAvailable = String.valueOf(wo.Is_Meter_Available__c);
                meterStatus = wo.Meter_Status__c;
                beforeMeterReading = wo.Before_Meter_Reading__c;
                afterMeterReading = wo.After_Meter_Reading__c;
                abnormalReadingReason = wo.Abnormal_Reading_Reason__c;

                if (wo.Satisfactory__c) {
                    satisOrNotSatisfactory = 'Satisfactory';
                } else if (wo.Not_Satisfactory__c) {
                    satisOrNotSatisfactory = 'Not Satisfactory';
                }

            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error loading job card data: ' + e.getMessage()));
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No Work Order ID provided.'));
        }
    }

    @AuraEnabled
    public static WorkOrder getWorkOrderDetails(String workOrderId) {
        return [SELECT Id, WorkOrderNumber FROM WorkOrder WHERE Id = :workOrderId LIMIT 1];
    }
    @AuraEnabled
public static String saveMeterCheckingData(String workOrderId, String materialUsed) {
    try {
        WorkOrder wo = [SELECT Id, SR_Material_Used__c FROM WorkOrder WHERE Id = :workOrderId LIMIT 1];
        wo.SR_Material_Used__c = materialUsed;
        update wo;

          updateWorkStepStatus(workOrderId,'Service Report');

        return 'Success';


    } catch (Exception e) {
        System.debug('Error in saveMeterCheckingData: ' + e.getMessage());
        return 'Error';
    }
}
@AuraEnabled
public static String generateAndAttachPdf(String workOrderId, String materialUsed) {
    try {
        // Render the VF page to PDF
        PageReference pdfPage = Page.domesticMeterCheckingReport;
        pdfPage.getParameters().put('id', workOrderId);
        pdfPage.getParameters().put('materialUsed', materialUsed);
        Blob pdfBlob = pdfPage.getContentAsPDF();

        // Fetch Work Order Number for filename
        WorkOrder wo = [SELECT WorkOrderNumber FROM WorkOrder WHERE Id = :workOrderId];

        // Create ContentVersion (upload PDF)
        ContentVersion cv = new ContentVersion(
            Title = 'Meter Checking Report - ' + wo.WorkOrderNumber,
            PathOnClient = 'MeterCheckingReport.pdf',
            VersionData = pdfBlob
        );
        insert cv;

        // Retrieve the ContentDocumentId from the inserted ContentVersion
        Id contentDocumentId = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
            LIMIT 1
        ].ContentDocumentId;

        // Create the link between ContentDocument and WorkOrder
        ContentDocumentLink link = new ContentDocumentLink(
            ContentDocumentId = contentDocumentId,
            LinkedEntityId = workOrderId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert link;

        return 'Success';

    } catch (Exception e) {
        System.debug('Error in generateAndAttachPdf: ' + e.getMessage());
        return 'Error';
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
            ws.Status = 'Completed'; // Or whatever picklist value you use
            update ws;
        }
     }

// @AuraEnabled
// public static void completeServiceReportStep(Id workOrderId) {
//     try {
//         // Query the WorkStep (or correct object name)
//         List<WorkStep> workSteps = [
//             SELECT Id, Status, Name, WorkOrderId
//             FROM WorkStep
//             WHERE WorkOrderId = :workOrderId
//             AND Name = 'Service Report'
//             LIMIT 1
//         ];

//         if (!workSteps.isEmpty()) {
//             WorkStep ws = workSteps[0];
//             ws.Status = 'Completed'; // ✅ Adjust based on your picklist values
//             update ws;
//            // return 'Success';
//         }
//         // else {
//         //     return 'NotFound';
//         // }

//     } catch (Exception e) {
//        // return 'Error: ' + e.getMessage();
//     }
// }
@AuraEnabled
public static String generateIDPAndAttachPdf(String workOrderId, String materialUsed) {
    try {
        // Render the VF page to PDF
        PageReference pdfPage = Page.domesticMeterCheckingReport;
        pdfPage.getParameters().put('id', workOrderId);
        pdfPage.getParameters().put('materialUsed', materialUsed);
        Blob pdfBlob = pdfPage.getContentAsPDF();

        // Fetch Work Order Number for filename
        WorkOrder wo = [SELECT WorkOrderNumber FROM WorkOrder WHERE Id = :workOrderId];

        // Create ContentVersion (upload PDF)
        ContentVersion cv = new ContentVersion(
            Title = 'Meter Checking Report - ' + wo.WorkOrderNumber,
            PathOnClient = 'MeterCheckingReport.pdf',
            VersionData = pdfBlob
        );
        insert cv;

        // Retrieve the ContentDocumentId from the inserted ContentVersion
        Id contentDocumentId = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
            LIMIT 1
        ].ContentDocumentId;

        // Create the link between ContentDocument and WorkOrder
        ContentDocumentLink link = new ContentDocumentLink(
            ContentDocumentId = contentDocumentId,
            LinkedEntityId = workOrderId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert link;

        return 'Success';

    } catch (Exception e) {
        System.debug('Error in generateAndAttachPdf: ' + e.getMessage());
        return 'Error';
    }
}


}