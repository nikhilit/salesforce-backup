public class MeterReplacement_Detail_Controller {
   // Header & basic info (used by VF page)
    public String recordNumber        { get; set; }   // WorkOrderNumber
    public String customerNameAddress { get; set; }
    public String notificationNumber  { get; set; }   // Meter_Reading_Order__c (SAP notif)
    public String otherDetails        { get; set; }

    public String receivedFrom        { get; set; }
    public String receivedDate        { get; set; }
    public String customerBPNumber    { get; set; }
    public String contactNumber       { get; set; }
    public String attendedDate        { get; set; }
    public String attendedTime        { get; set; }

    // Nature of work checkboxes
    public Boolean oldMeterReplacement { get; set; }  // Meter_replaced__c
    public Boolean meterNotRunning     { get; set; }  // Meter_Not_Running__c
    public Boolean meterSound          { get; set; }  // Add_Meter_Sound__c
    public Boolean counterDefective    { get; set; }  // Counter_defective_smokey__c
    public Boolean faultyMeter         { get; set; }  // Meter_Faulty__c
    public Boolean otherWork           { get; set; }  // Reason_Other_Remark__c not blank

    // Test section
    public String leakTestWithSoap    { get; set; }  // Leak_Test_With_SOAP_Solution__c
    public String pneumaticTest       { get; set; }  // Penumatic_Pressure_Test_At_32_mba__c
    public String  gasLeakReading      { get; set; }  // Gascoseeker_Reading__c
    public String  rubberTubeType      { get; set; }  // Rubber_Tube_Type__c
    public String  rubberTubeCondition { get; set; }  // Rubber_Tube_Condition__c
    public String ensureNoGasLeak     { get; set; }  // Ensure_No_Gas_Leakage_Before_LeavingSit__c

    // Reason / action
    public String reasonText      { get; set; }       // Reason_MetRep_Pdf__c
    public String actionTaken     { get; set; }       // Action_Taken_MetRep_Pdf__c

    // Meter details
    public String oldMeterMake    { get; set; }       // Old_Meter_Make__c
    public String oldMeterSerial  { get; set; }       // Old_Meter_Serial_No__c
    public String oldMeterReading { get; set; }       // Old_Meter_Reading__c
    public String oldMeterRemark  { get; set; }       // Remarks_Meter_Repl__c (if you want)

    public String newMeterMake    { get; set; }       // New_Meter_Make__c
    public String newMeterSerial  { get; set; }       // New_Meter_Serial_No__c
    public String newMeterReading { get; set; }       // New_Meter_Reading__c
    public String newMeterRemark  { get; set; }

    // Contractor section
    public String contractorTechnician { get; set; }  // Agent__r.Name
    public String contractorSupervisor { get; set; }  // can map if you get separate field later
    public String contractorName       { get; set; }  // Agency_Name__c
    public Boolean workSatisfactory    { get; set; }  // Satisfactory__c
    public Boolean workNotSatisfactory { get; set; }  // Not_Satisfactory__c

    public String additionalRemarks    { get; set; }  // Final_Remark__c

    public MeterReplacement_Detail_Controller() {

        String woId = ApexPages.currentPage().getParameters().get('id');

        if (String.isBlank(woId)) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR,
                'No Work Order Id passed in the URL.'
            ));
            return;
        }

        try {
            WorkOrder wo = [
                SELECT WorkOrderNumber,
                       BP_Number__c,
                       Customer_BP_Number__c,
                       Customer_Name__c,
                       Customer_Contact_Number__c,
                       Address_Line_1__c,
                       Address_Line_2__c,
                       Building_Name__c,
                       Colony__c,
                       City__c,
                       Postal_Code__c,
                       Meter_Reading_Order__c,
                       Request_Submission_Date__c,
                       Attended_Date__c,
                       Check_In_Date_Time__c,
                       Meter_replaced__c,
                       Meter_Not_Running__c,
                       Add_Meter_Sound__c,
                       Old_Meter_Rusted__c,
                       Counter_defective_smokey__c,
                       Meter_Faulty__c,
                       Reason_Other_Remark__c,
                       Leak_Test_With_SOAP_Solution__c,
                       Penumatic_Pressure_Test_At_32_mba__c,
                       Gascoseeker_Reading__c,
                       Rubber_Tube_Type__c,
                       Rubber_Tube_Condition__c,
                       Ensure_No_Gas_Leakage_Before_LeavingSit__c,
                       Reason_MetRep_Pdf__c,
                       Action_Taken_MetRep_Pdf__c,
                       Old_Meter_Make__c,
                       Old_Meter_Serial_No__c,
                       Old_Meter_Reading__c,
                       New_Meter_Make__c,
                       New_Meter_Serial_No__c,
                       New_Meter_Reading__c,
                       Remarks_Meter_Repl__c,
                       Satisfactory__c,
                       Not_Satisfactory__c,
                       Final_Remark__c,
                       Agency_Name__c,
                       Agent__r.Name
                FROM WorkOrder
                WHERE Id = :woId
                LIMIT 1
            ];

            // === HEADER SECTION ===
            recordNumber = wo.WorkOrderNumber;

            // Notification No. – SAP meter reading order
            notificationNumber = String.valueOf(wo.Meter_Reading_Order__c);

            // Customer name + address block
            List<String> addrLines = new List<String>();
            if (!String.isBlank(wo.Customer_Name__c)) addrLines.add(wo.Customer_Name__c);
            if (!String.isBlank(wo.Address_Line_1__c)) addrLines.add(wo.Address_Line_1__c);
            if (!String.isBlank(wo.Address_Line_2__c)) addrLines.add(wo.Address_Line_2__c);
            if (!String.isBlank(wo.Building_Name__c)) addrLines.add(wo.Building_Name__c);
            if (!String.isBlank(wo.Colony__c)) addrLines.add(wo.Colony__c);
            if (!String.isBlank(wo.City__c) || !String.isBlank(wo.Postal_Code__c)) {
                addrLines.add( (wo.City__c == null ? '' : wo.City__c + ' ')
                             + (wo.Postal_Code__c == null ? '' : wo.Postal_Code__c));
            }
            customerNameAddress = String.join(addrLines, '<br/>');

            // Received From / Date – you can tweak mapping if business says otherwise
            receivedFrom = wo.Agency_Name__c;
            if (wo.Request_Submission_Date__c != null) {
                receivedDate = wo.Request_Submission_Date__c.format();
            }

            customerBPNumber = String.isNotBlank(wo.Customer_BP_Number__c)
                               ? wo.Customer_BP_Number__c
                               : wo.BP_Number__c;

            contactNumber    = wo.Customer_Contact_Number__c;

            // Attended date & time
            if (wo.Check_In_Date_Time__c != null) {
                DateTime dt = wo.Check_In_Date_Time__c;
                attendedDate = dt.date().format();
                attendedTime = dt.format('HH:mm');
            } else if (wo.Attended_Date__c != null) {
                attendedDate = wo.Attended_Date__c.format();
            }

            // === NATURE OF WORK ===
            oldMeterReplacement = wo.Meter_replaced__c;
            meterNotRunning     = wo.Meter_Not_Running__c;
            meterSound          = wo.Add_Meter_Sound__c;
            counterDefective    = wo.Counter_defective_smokey__c;
            faultyMeter         = wo.Meter_Faulty__c;
            otherWork           = !String.isBlank(wo.Reason_Other_Remark__c);

            // === TEST SECTION ===
            leakTestWithSoap    = wo.Leak_Test_With_SOAP_Solution__c;
            pneumaticTest       = wo.Penumatic_Pressure_Test_At_32_mba__c;
            gasLeakReading      = wo.Gascoseeker_Reading__c;
            rubberTubeType      = wo.Rubber_Tube_Type__c;
            rubberTubeCondition = wo.Rubber_Tube_Condition__c;
            ensureNoGasLeak     = wo.Ensure_No_Gas_Leakage_Before_LeavingSit__c;

            // === REASON / ACTION ===
            reasonText  = wo.Reason_MetRep_Pdf__c;
            actionTaken = wo.Action_Taken_MetRep_Pdf__c;

            // === METER DETAILS ===
            oldMeterMake    = wo.Old_Meter_Make__c;
            oldMeterSerial  = wo.Old_Meter_Serial_No__c;
            oldMeterReading = wo.Old_Meter_Reading__c;
            oldMeterRemark  = wo.Remarks_Meter_Repl__c;

            newMeterMake    = wo.New_Meter_Make__c;
            newMeterSerial  = wo.New_Meter_Serial_No__c;
            newMeterReading = wo.New_Meter_Reading__c;
            newMeterRemark  = ''; // map some other field if required

            // === CONTRACTOR ===
            contractorTechnician = (wo.Agent__r != null) ? wo.Agent__r.Name : null;
            contractorSupervisor = ''; // no field right now – fill later if you get one
            contractorName       = wo.Agency_Name__c;
            workSatisfactory     = wo.Satisfactory__c;
            workNotSatisfactory  = wo.Not_Satisfactory__c;

            additionalRemarks    = wo.Final_Remark__c;
        }
        catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR,
                'Error loading Work Order details: ' + e.getMessage()
            ));
        }
    }
}