public without sharing class RiserReplacementPageContr {


public string wONumber {get;set;}
public string completedDate{get;set;}
public string bpNumber{get;set;}
public string address{get;set;}
public string copperPipeLength{get;set;}
public string testPressure{get;set;}
public Time stabilizationTime{get;set;}
public Time testingTime{get;set;}
public string result{get;set;}
public string leakageObserved{get;set;}
public string lengthRectified{get;set;}
public string meterReading{get;set;}


public string meterNumber{get;set;}
public string regulatorMake{get;set;}
public string pGCDInstrumentType{get;set;}
public String pGCDCalibrationCertificateNo{get;set;}
public string pGCDCalibrationDate{get;set;}
public string pGCDCalibrationDueDate{get;set;}

public string supervisoreName{get;set;}
public string tPEName{get;set;}
public string customerName{get;set;}

public string materialRecovered{get;set;}


public List<Material_Consumption__c> materialConsuption {get;set;}


public RiserReplacementPageContr(){

       // String accId   = ApexPages.currentPage().getParameters().get('Id');
        
     // String accId   =  '001fs000000SSZBAA4' ;
     String accId   = ApexPages.currentPage().getParameters().get('accountId'); 
 //  String  woId=  '0WOfs000001L8ATGA0';
     String  woId=   ApexPages.currentPage().getParameters().get('workOrderId'); 
        
       Account accDetails = [Select id,BP_Number__c,FirstName__c,LastName__c,Area__c,Building_Code__c,Building_name__c,Flat__c,Colony__c, 
                                    Plot__c,Floor__c,Society_Name__c,City__c,Postal_Code__c,Road_name__c ,Street__c,
                                 Street_Line_2__c , Street_Line_3__c , Street_Line_4__c , Street_Line_5__c , 
                                 Wing__c ,Zone__c ,Region__c ,Country_Key__c,Copper_MLC_Length__c,Meter_Reading__c,Meter_Number__c,Regulator_Make__c
                                                  
                                 
                                           from Account Where Id=:accId]; 
                                           
                    WorkOrder woDetail = [Select id,owner.Name,Riser_Supervisor_Name__c,RM_Instrument_Type_Range__c,
                                    RM_Calibration_Certificate_No__c,RM_Calibration_Date__c,
                                    RM_Calibration_Due_Date__c  from WorkOrder where id=:woId];                       
                                           
                                           
           //  WorkOrderLineItem wolItem  = [Select id,workOrderId,Instrument_Type_Range__c,Calibration_Certificate_No__c,Calibration_Date__c,
                                       //      Calibration_Due_Date__c,LastModifiedDate from WorkOrderLineItem Where WorkOrderId =: woId limit 1];     
                                             //AND LastModifiedDate=Today       
                   
              /* List<WorkOrderLineItem> lstWOLItem = [Select id,WorkOrderId from WorkOrderLineItem Where WorkOrderId =:woId];
               
              Set<Id> wolItemIds = new Set<Id>();
               
               for(WorkOrderLineItem woli: lstWOLItem){
               
                         wolItemIds.add(woli.Id);
               }      */
               
               
             // materialConsuption = [Select id,Work_Order_Line_Item__c,Item_Code_Riser_Activity__c, Item_Description_Riser_Activity__c, Quantity__c
                             //                              from Material_Consumption__c Where  Work_Order_Line_Item__c IN:wolItemIds];
                             // or Work_Order_Line_Item__c IN:wolItemIds
              
                    materialConsuption = [Select id,Business_Partner__c,Item_Code_Riser_Activity__c, Item_Description_Riser_Activity__c, Quantity__c
                                                           from Material_Consumption__c Where  Business_Partner__c =:accId ];
                                                         
                                           
                  completedDate = Date.today().format();  
                  
                  bpNumber =   accDetails.BP_Number__c;     
                                  
                   address   =  (accDetails.Area__c != null ? accDetails.Area__c : '') + ' ' +
                    (accDetails.Building_Code__c != null ? accDetails.Building_Code__c : '') + ' ' +
                    (accDetails.Building_name__c != null ? accDetails.Building_name__c : '') + ' ' +
                    (accDetails.Flat__c != null ? accDetails.Flat__c : '') + ' ' +
                    (accDetails.Colony__c != null ? accDetails.Colony__c : '') + ' ' +
                    (accDetails.Plot__c != null ? accDetails.Plot__c : '') + ' ' +
                    (accDetails.Floor__c != null ? accDetails.Floor__c : '') + ' ' +
                    (accDetails.Society_Name__c != null ? accDetails.Society_Name__c : '') + ' ' +
                    (accDetails.City__c != null ? accDetails.City__c : '') + ' ' +
                    (accDetails.Postal_Code__c != null ? accDetails.Postal_Code__c : '') + ' ' +
                    (accDetails.Road_name__c != null ? accDetails.Road_name__c : '') + ' ' +
                    (accDetails.Street__c != null ? accDetails.Street__c : '') + ' ' +
                    (accDetails.Street_Line_2__c != null ? accDetails.Street_Line_2__c : '') + ' ' +
                    (accDetails.Street_Line_3__c != null ? accDetails.Street_Line_3__c : '') + ' ' +
                    (accDetails.Street_Line_4__c != null ? accDetails.Street_Line_4__c : '') + ' ' +
                    (accDetails.Street_Line_5__c != null ? accDetails.Street_Line_5__c : '') + ' ' +
                    (accDetails.Wing__c != null ? accDetails.Wing__c : '') + ' ' +
                    (accDetails.Zone__c != null ? accDetails.Zone__c : '') + ' ' +
                    (accDetails.Region__c != null ? accDetails.Region__c : '') + ' ' +
                    (accDetails.Country_Key__c != null ? accDetails.Country_Key__c : '');  
    
                copperPipeLength=accDetails.Copper_MLC_Length__c;
                
              

    
                    meterReading = accDetails.Meter_Reading__c;
                    meterNumber=accDetails.Meter_Number__c;             
                   regulatorMake=accDetails.Regulator_Make__c;
                   pGCDInstrumentType= woDetail.RM_Instrument_Type_Range__c;
                   pGCDCalibrationCertificateNo = woDetail.RM_Calibration_Certificate_No__c;
                   pGCDCalibrationDate=woDetail.RM_Calibration_Date__c.format();
                   pGCDCalibrationDueDate= woDetail.RM_Calibration_Due_Date__c.format();                      
                   tPEName=woDetail.owner.Name;
                   supervisoreName=woDetail.Riser_Supervisor_Name__c; 
                   customerName = accDetails.FirstName__c  + ' ' + accDetails.LastName__c;
        
        
}


}