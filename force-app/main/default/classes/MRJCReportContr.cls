/**
* @File Name : MRJCReportContr.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : June 26, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | June 26, 2025 |   | Initial Version
**/

public class MRJCReportContr {

    public String customerName { get; set; }
    public String customerAddress { get; set; }
    public String notificationNo { get; set; }
    public String contactNo { get; set; }
    
    public String bpNumber { get; set; }
    
    public String receivedFrom{ get; set; }
    public String receivedDate{ get; set; }
    public DateTime attendedDate { get; set; }
  //  public String natureOfWork { get; set; }
    public String reason { get; set; } 
    public String leakTestSOAP { get; set; } 
    public String rubberTubeType { get; set; }
    public String rubberTubeCondition{ get; set; } 
    public String noGasLeakage { get; set; } 
    public String actionTaken { get; set; } 
    public String materialUsed  { get; set; }  
    public String oldMeterMake { get; set; }
    public String oldMeterSerialNo { get; set; } 
    public String oldMeterReading { get; set; } 
    public String oldMeterRemark { get; set; }
    public String newMeterMake { get; set; } 
    public String newMeterSerialNo { get; set; } 
    public String newMeterReading { get; set; } 
    public String newMeterRemark { get; set; }   
    public String penumaticPressure { get; set; }
    public String gascoseekerReading { get; set; }   
    public String materialRecovered { get; set; } 
    public String contSupName { get; set; }
    public String contTechName { get; set; }
    public String  contractorName  { get; set; } 
    public String satisOrNotSatisfactory{ get; set; } 
    public List<Material_Consumption__c> materialConsuption {get;set;}

    
    public MRJCReportContr() {

      String workOrderId = ApexPages.currentPage().getParameters().get('Id');
      //String workOrderId='0WOfs000001Kgh3GAC';

        if (String.isNotBlank(workOrderId)) {
            try {
                WorkOrder wo = [SELECT Id,WorkOrderNumber,Account.FirstName__c,Account.LastName__c,BP_Customer_Address__c,BP_Number__c,
                                                Account.Customer_Contact_no__c,O_M_Source__c,Penumatic_Pressure_Test_At_32_mba__c,
                                            CreatedDate,Completion_Datetime__c,Leak_Test_With_SOAP_Solution__c,
                                            Gascoseeker_Reading__c,Rubber_Tube_Type__c,Ensure_No_Gas_Leakage_Before_LeavingSit__c,Reason_MetRep_Pdf__c,
                                            Action_Taken_MetRep_Pdf__c,Material_Recovered__c,owner.Name, ServiceTerritory.Name,Agent__r.Name,Agent__r.Supervisor__c,Agent__r.Supervisor__r.Name,
                                            Satisfactory__c,Not_Satisfactory__c,Rubber_Tube_Condition__c,Old_Meter_Make__c,Old_Meter_Serial_No__c,Old_Meter_Reading__c,
                                            Old_Remark__c ,New_Meter_Make__c,New_Meter_Serial_No__c,New_Meter_Reading__c,New_Remark__c
                                     FROM WorkOrder WHERE Id =: workOrderId];
                                     
                                     //Nature_of_work_type_of_request__c
                                     
                materialConsuption = [
                                        SELECT Id, Work_Order__c, Item_description__c, Quantity__c, Item_Code__c
                                        FROM Material_Consumption__c
                                        WHERE Work_Order__c = :workOrderId
                                    ];           

                // Assign text fields need to add again insde materialconsumption query  Unit__c MRJCReportContr
                    customerName = '';
                    if (wo != null && wo.Account != null) {
                        List<String> nameParts = new List<String>();
                        if (String.isNotBlank(wo.Account.FirstName__c)) {
                            nameParts.add(wo.Account.FirstName__c.trim());
                        }
                        if (String.isNotBlank(wo.Account.LastName__c)) {
                            nameParts.add(wo.Account.LastName__c.trim());
                        }
                        if (!nameParts.isEmpty()) {
                            customerName = String.join(nameParts, ' ');
                        } else {
                            // fallback: try Account.Name if First/Last not used or available
                            if (String.isNotBlank(wo.Account.Name)) {
                                customerName = wo.Account.Name;
                            } else {
                                customerName = '';
                            }
                        }
                    }
                customerAddress   = wo.BP_Customer_Address__c;
                contactNo         = wo.Account.Customer_Contact_no__c;
                bpNumber          = wo.BP_Number__c;
                notificationNo    = wo.WorkOrderNumber;
                attendedDate      = wo.Completion_Datetime__c;
                receivedFrom      =    wo.O_M_Source__c;
                receivedDate= wo.CreatedDate.format('dd-MM-yyyy HH:mm:ss');
               // natureOfWork = wo.Nature_of_work_type_of_request__c;
                reason = wo.Reason_MetRep_Pdf__c;
                leakTestSOAP = wo.Leak_Test_With_SOAP_Solution__c;
                penumaticPressure = wo.Penumatic_Pressure_Test_At_32_mba__c;
                gascoseekerReading = wo.Gascoseeker_Reading__c;
                rubberTubeType = wo.Rubber_Tube_Type__c;
                noGasLeakage = wo.Ensure_No_Gas_Leakage_Before_LeavingSit__c;
                actionTaken = wo.Action_Taken_MetRep_Pdf__c;
                
                materialUsed = 'new meter and wire';
                materialRecovered = wo.Material_Recovered__c;
                
                rubberTubeCondition=wo.Rubber_Tube_Condition__c;
                contTechName = (wo.Agent__r != null && String.isNotBlank(wo.Agent__r.Name)) ? wo.Agent__r.Name : '';
                contSupName = '';
                if (wo.Agent__r != null) {
                    if (wo.Agent__r.getSObject('Supervisor__r') != null) {
                        SObject sup = wo.Agent__r.getSObject('Supervisor__r');
                        if (sup != null && sup.get('Name') != null) {
                            contSupName = String.valueOf(sup.get('Name'));
                        }
                    }
                    if (String.isBlank(contSupName) && wo.Agent__r.get('Supervisor__c') != null) {
                        String supField = String.valueOf(wo.Agent__r.get('Supervisor__c'));
                        if (String.isNotBlank(supField)) {
                            contSupName = supField;
                        }
                    }
                }
                oldMeterMake = wo.Old_Meter_Make__c;
                oldMeterSerialNo =wo.Old_Meter_Serial_No__c;
                oldMeterReading = wo.Old_Meter_Reading__c;
                oldMeterRemark =wo.Old_Remark__c;
                newMeterMake = wo.New_Meter_Make__c;
                newMeterSerialNo = wo.New_Meter_Serial_No__c;
                newMeterReading = wo.New_Meter_Reading__c;
                newMeterRemark = wo.New_Remark__c;
                
               contractorName  = wo.ServiceTerritory.Name;
               
              // materialUsed =  matConsumption.Item_description__c + ', ' + 'Unit -' + ' ' + matConsumption.Unit__c + ' ,' + ' ' + 'Quantity - ' + ' ' + matConsumption.Quantity__c;
                
                if(wo.Satisfactory__c){
                
                satisOrNotSatisfactory='Satisfactory';
                }
                if(wo.Not_Satisfactory__c ){
                satisOrNotSatisfactory='Not Satisfactory';
                } 
                
                              
                
                
                
              
               
            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error loading job card data: ' + e.getMessage()));
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No Work Order ID provided.'));
        }
    }


}