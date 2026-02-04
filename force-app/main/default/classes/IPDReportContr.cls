public without sharing class IPDReportContr {
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

    
    public String noGasLeakage { get; set; }
   

    public String materialUsed { get; set; }
    public String materialRecovered { get; set; }
    
    public String newMeterMake { get; set; }
    public String newMeterSerialNo { get; set; }
    public String newMeterReading { get; set; }
    public String newMeterRemark { get; set; }

    public String contSupName { get; set; }
    public String contTechName { get; set; }
    public String contractorName { get; set; }



    public IPDReportContr() {

        String workOrderId = ApexPages.currentPage().getParameters().get('id');

        system.debug('inside vf page contr ::'+ workOrderId);

        if (String.isNotBlank(workOrderId)) {
            try {

                system.debug('inside workorderid not blank');
              

                WorkOrder wo = [SELECT Account.FirstName__c, Account.LastName__c, Account.Customer_Contact_no__c,
                        BP_Customer_Address__c, BP_Number__c, WorkOrderNumber,
                        Completion_Datetime__c, CreatedDate, Owner.Name, ServiceTerritory.Name,
                        Ensure_No_Gas_Leakage_Before_LeavingSit__c,Agent__r.Name,Agent__r.Supervisor__r.Name,                   
                        New_Meter_Make__c, Meter_Number__c, Final_Meter_Reading__c, Final_Remark__c                                        
                            FROM WorkOrder 
                            WHERE Id = :workOrderId
                            LIMIT 1
                         ];

                ServiceAppointment serApp = [
                    SELECT Id,SchedStartTime, SchedEndTime 
                    FROM ServiceAppointment 
                    WHERE ParentRecordId = :workOrderId 
                    LIMIT 1
                ];         

                

                Material_Consumption__c matCons = [Select id,            
                          Meter_Bracket__c, Meter_Regulator__c, Meter_Control_Valve__c,
                        Appliance_Valve__c, Copper_Pipe_12mm_In_meter__c,
                        Br_Disconnection_Union_1_2_x_12mm__c, Br_Disconnection_Union_3_4_x_12mm__c,
                        Meter_Inlet_Adaptor_3_4_x_3_4__c, Meter_Outlet_Adaptor_3_4_x_12mm__c,
                        GI_Pipe__c, Barrel_Nipple__c, PRE_SLEEVED_GI_HOLE_PIECE__c,
                        Anaconda__c, Br_Fitting_1_2_x_1_2__c, MLC_Pipe_Length__c
                                                     from Material_Consumption__c
                                                      where Work_Order__c = :workOrderId];

                // Set Customer Information
                customerName = (wo.Account != null) ? 
                    ((wo.Account.FirstName__c != null ? wo.Account.FirstName__c + ' ' : '') + 
                    (wo.Account.LastName__c != null ? wo.Account.LastName__c : '')) : '';
                customerAddress = wo.BP_Customer_Address__c != null ? wo.BP_Customer_Address__c : '';
                contactNo = wo.Account.Customer_Contact_no__c != null ? wo.Account.Customer_Contact_no__c : '';
                bpNumber = wo.BP_Number__c != null ? wo.BP_Number__c : '';
                notificationNo = wo.WorkOrderNumber != null ? wo.WorkOrderNumber : '';
                receivedFrom = wo.Agent__r.Supervisor__r.Name!= null ? wo.Agent__r.Supervisor__r.Name: '';
                // Set Date/Time fields with proper null checks
                if (serApp != null && serApp.SchedStartTime != null) {
                    receivedDate = serApp.SchedStartTime.format('dd-MM-yyyy');
                    receivedTime = serApp.SchedStartTime.format('HH:mm');
                } else if (wo.CreatedDate != null) {
                    receivedDate = wo.CreatedDate.format('dd-MM-yyyy');
                    receivedTime = wo.CreatedDate.format('HH:mm');
                } else {
                    receivedDate = '';
                    receivedTime = '';
                }

                if (wo.Completion_Datetime__c != null) {
                    attendedDate = wo.Completion_Datetime__c.format('dd-MM-yyyy');
                    attendedTime = wo.Completion_Datetime__c.format('HH:mm');
                } else {
                    attendedDate = '';
                    attendedTime = '';
                }

              
                // materialUsed = wo.Plug_From__c;
                               
             noGasLeakage = wo.Ensure_No_Gas_Leakage_Before_LeavingSit__c ;

             system.debug('nogasleakage::'+ wo.Ensure_No_Gas_Leakage_Before_LeavingSit__c);


                 List<String> materials = new List<String>();

                   if (String.isNotBlank(matCons.Meter_Bracket__c)) materials.add('Meter Bracket: ' + matCons.Meter_Bracket__c);
        if (String.isNotBlank(matCons.Meter_Regulator__c)) materials.add('Meter Regulator: ' + matCons.Meter_Regulator__c);
        if (String.isNotBlank(matCons.Meter_Control_Valve__c)) materials.add('Meter Control Valve: ' + matCons.Meter_Control_Valve__c);
        if (String.isNotBlank(matCons.Appliance_Valve__c)) materials.add('Appliance Valve: ' + matCons.Appliance_Valve__c);
        if (String.isNotBlank(matCons.Copper_Pipe_12mm_In_meter__c)) materials.add('Copper Pipe 12mm: ' + matCons.Copper_Pipe_12mm_In_meter__c);
        if (String.isNotBlank(matCons.Br_Disconnection_Union_1_2_x_12mm__c)) materials.add('Br Disconnection Union 1/2": ' + matCons.Br_Disconnection_Union_1_2_x_12mm__c);
        if (String.isNotBlank(matCons.Br_Disconnection_Union_3_4_x_12mm__c)) materials.add('Br Disconnection Union 3/4": ' + matCons.Br_Disconnection_Union_3_4_x_12mm__c);
        if (String.isNotBlank(matCons.Meter_Inlet_Adaptor_3_4_x_3_4__c)) materials.add('Meter Inlet Adaptor: ' + matCons.Meter_Inlet_Adaptor_3_4_x_3_4__c);
        if (String.isNotBlank(matCons.Meter_Outlet_Adaptor_3_4_x_12mm__c)) materials.add('Meter Outlet Adaptor: ' + matCons.Meter_Outlet_Adaptor_3_4_x_12mm__c);
        if (String.isNotBlank(matCons.GI_Pipe__c)) materials.add('GI Pipe: ' + matCons.GI_Pipe__c);
        if (String.isNotBlank(matCons.Barrel_Nipple__c)) materials.add('Barrel Nipple: ' + matCons.Barrel_Nipple__c);
        if (String.isNotBlank(matCons.PRE_SLEEVED_GI_HOLE_PIECE__c)) materials.add('Pre-Sleeved GI: ' + matCons.PRE_SLEEVED_GI_HOLE_PIECE__c);
        if (String.isNotBlank(matCons.Anaconda__c)) materials.add('Anaconda: ' + matCons.Anaconda__c);
        if (String.isNotBlank(matCons.Br_Fitting_1_2_x_1_2__c)) materials.add('Br Fitting 1/2": ' + matCons.Br_Fitting_1_2_x_1_2__c);
        if (String.isNotBlank(matCons.MLC_Pipe_Length__c)) materials.add('MLC Pipe Length: ' + matCons.MLC_Pipe_Length__c);
        
        materialRecovered = String.join(materials, ', ');

        system.debug('materials::'+ materials);


                newMeterMake = wo.New_Meter_Make__c != null ? wo.New_Meter_Make__c : '';
                newMeterSerialNo = wo.Meter_Number__c != null ? String.valueOf(wo.Meter_Number__c) : '';
                newMeterReading = wo.Final_Meter_Reading__c != null ? String.valueOf(wo.Final_Meter_Reading__c) : '';
                newMeterRemark = wo.Final_Remark__c != null ? wo.Final_Remark__c : '';

                contTechName = wo.Agent__r != null && wo.Agent__r.Name != null ? wo.Agent__r.Name : '';
                contSupName = wo.Agent__r.Supervisor__r.Name != null ? wo.Agent__r.Supervisor__r.Name : '';
                contractorName = wo.ServiceTerritory != null && wo.ServiceTerritory.Name != null ? wo.ServiceTerritory.Name : '';

               
               
              

            } catch (Exception e) {
                System.debug('Error loading job card data: ' + e.getMessage() + ' Stack Trace: ' + e.getStackTraceString());
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error loading job card data: ' + e.getMessage()));
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No Work Order ID provided.'));
        }
    }

  
}