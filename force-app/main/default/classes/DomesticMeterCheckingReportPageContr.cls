public without sharing class DomesticMeterCheckingReportPageContr {

    public String getNatureOfWork() {
        return null;
    }



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

    public String leakTestSOAP { get; set; }
        public String noGasLeakage { get; set; }


    // Material Details
    public String oldMeterReading { get; set; }
    public Decimal newMeterSerialNo { get; set; }
    public String newMeterReading { get; set; }

    // Personnel
    public String contSupName { get; set; }
    public String contTechName { get; set; }
    public String contractorName { get; set; }
    
        public String materialUsed { get; set; }
        public String materialRecovered { get; set; }

        public String meterMake{ get; set; }


    // Status
   
    public String actionTakenMetRep { get; set; }
   


    public DomesticMeterCheckingReportPageContr () {
        String workOrderId = ApexPages.currentPage().getParameters().get('id');
       // this.materialUsed = ApexPages.currentPage().getParameters().get('materialUsed');

        if (String.isNotBlank(workOrderId)) {
            try {
                WorkOrder wo = [SELECT 
                    Account.FirstName__c,
                    Account.LastName__c,
                    BP_Customer_Address__c,
                    BP_Number__c,
                    Account.Customer_Contact_no__c,
                    WorkOrderNumber,
                    Leak_Test_With_SOAP_Solution__c,
                    Ensure_No_Gas_Leakage_Before_LeavingSit__c,                                                                      
                    Meter_Number__c,
                    New_Meter_Reading__c,
                    Meter_Status__c,
                    Remarks__c,
                    Owner.Name,
                    ServiceTerritory.Name,
                    Agent__r.Name,Agent__r.Supervisor__r.Name,
                    
                    Old_Meter_Reading__c,LastModifiedDate,Meter_Make__c
                                                         
                FROM WorkOrder WHERE Id = :workOrderId];
                
                //Material_Recovered__c, SR_Material_Used__c
                   
                
                /*O_M_Source__c,Completion_Datetime__c,CreatedDate, Reason_MetRep_Pdf__c,Action_Taken_MetRep_Pdf__c,Material_Recovered__c,Is_Customer_Using_Gas__c,
                  Is_Meter_Available__c,  Gascoseeker_Reading__c,
                    Rubber_Tube_Type__c,
                    Rubber_Tube_Condition__c,
                    Old_Meter_Make__c,
                    Old_Meter_Serial_No__c,
                    Old_Meter_Reading__c,
                    Old_Remark__c,
                    Meter_Status__c, New_Meter_Make__c, Satisfactory__c,
                    Not_Satisfactory__c, Before_Meter_Reading__c,
                    After_Meter_Reading__c,
                     Final_Remark__c,  */

               
                                     
                      ServiceAppointment serApp = [Select Id,ParentRecord.Id from serviceappointment where ParentRecord.Id=:workOrderId];
                      
                      AssignedResource assRes = [Select Id,ServiceAppointmentId, CreatedDate from AssignedResource where ServiceAppointmentId =:serApp.Id];             

                // Basic Customer Info  Item_Code__c
                customerName = wo.Account.FirstName__c + ' ' + wo.Account.LastName__c;
                customerAddress = wo.BP_Customer_Address__c;
                contactNo = wo.Account.Customer_Contact_no__c;
                bpNumber = wo.BP_Number__c;
                notificationNo = wo.WorkOrderNumber;
                
                receivedFrom = wo.Owner.Name;
                 contTechName = wo.Agent__r.Name;
                contSupName = wo.Agent__r.Supervisor__r.Name;
              //   contSupName = wo.Owner.Name;
                contractorName = wo.ServiceTerritory.Name;

                // Date/Time Formatting
                if (assRes.CreatedDate != null) {
                    receivedDate = assRes.CreatedDate.format('dd-MM-yyyy');
                    receivedTime = assRes.CreatedDate.format('HH:mm:ss');
                }
                if(wo.LastModifiedDate != null) {
                    attendedDate = wo.LastModifiedDate.format('dd-MM-yyyy');
                    attendedTime = wo.LastModifiedDate.format('HH:mm:ss');
                }  

                // Test Results
                leakTestSOAP = wo.Leak_Test_With_SOAP_Solution__c;
                noGasLeakage = wo.Ensure_No_Gas_Leakage_Before_LeavingSit__c;
                       actionTakenMetRep = wo.Meter_Status__c;
                       meterMake = wo.Meter_Make__c;

            //   materialRecovered = wo.Material_Recovered__c;
              //  materialUsed = wo.SR_Material_Used__c;

                // Material Details
               
                oldMeterReading = wo.Old_Meter_Reading__c;
                newMeterSerialNo = wo.Meter_Number__c;
                newMeterReading = wo.New_Meter_Reading__c;
                                                                   
                

               
            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error loading job card data: ' + e.getMessage()));
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No Work Order ID provided.'));
        }
    }





}