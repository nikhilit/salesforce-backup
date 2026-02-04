public with sharing class O_MIANDCContr {

public string wONumber {get;set;}
public string issueDate{get;set;}
public string activityStartTime{get;set;}
public string activityEndTime{get;set;}
public string bpNumber{get;set;}
public string customerName{get;set;}
public string gasUsedFor{get;set;}
public string SAPEquipmentNo{get;set;}
public string district{get;set;}
public string meterSerialNo{get;set;}
public string contactNumber{get;set;}
public string typeOfMeter{get;set;}
public string meterReading{get;set;}
public string meterMake{get;set;}
public string meterManufacturingYear{get;set;}
public string capacity{get;set;}
public string meterQmin{get;set;}
public string regulatoryType{get;set;}
public string regulatorMake{get;set;}
public string regulatorCapacity{get;set;}
public string regulatorySupplyPressure{get;set;}

public string isolateGasSupply{get;set;}
public string connectDigitalPressure{get;set;}
public string CheckSetPressure{get;set;}
public string pressureObserved{get;set;}
public string checkReliefPressure{get;set;}
public string checkSSVSetting{get;set;}
public string checkLockPressure{get;set;}
public string closeInletValue{get;set;}
public string depressuriseSkid{get;set;}
public string openStrainer{get;set;}
public string clearnStrainer{get;set;}
public string malfunctioningOrCorrosionRegulatory{get;set;}
public string checkMeterCounter{get;set;}
public string checkSignBoards{get;set;}
public string checkPipeCondition{get;set;}
public string checkMeterBody{get;set;}
public string checkCrimpPosition{get;set;}
public string checkClamps{get;set;}
public string checkPointsProperlyPlugged{get;set;}
public string carryOutLeakTest{get;set;}
public string carryOutPainting{get;set;}
public string checkAllSeals{get;set;}
public string checkMGLSeal{get;set;}
public string checkIllegalTapping{get;set;}
public string checkAllValuesOperative{get;set;}
public string checkAllStudnuts{get;set;}
public string checkLevelingOfSR{get;set;}
public string checkFoundationConditionAndBolt{get;set;}
public string checkConditionFRPCover{get;set;}
public string openOutletValue{get;set;}

public string anyObservation{get;set;}

public string pBSRegulator{get;set;}
public string pBSSSV{get;set;}
public string pBSRelief{get;set;}
public string pBSLockPressure{get;set;}


public string pASRegulator{get;set;}
public string pASSSV{get;set;}
public string pASRelief{get;set;}
public string pASLockPressure{get;set;}



public string sealMechanicalMeter{get;set;}
public string sealElectronicMeter{get;set;}
public string sealRegulator{get;set;}
public string sealLockDetails{get;set;}

public string checkInTimeStamp{get;set;}

public string technicianName{get;set;}

public string agencySupervisor{get;set;}

public List<Material_Consumption__c> lstMaterialConsumption{get;set;}




public O_MIANDCContr (){



         String workOrderId = ApexPages.currentPage().getParameters().get('Id');
         
         WorkOrder wo = [Select id,WorkOrderNumber,Completion_Datetime__c,BP_Number__c, Account.FirstName__c,Account.LastName__c,Gas_Used_For__c,
                                 SAP_Equipment_No__c,Account.Customer_Contact_no__c,Account.District__c,New_Meter_Serial_No__c,Type_Of_Meter_I_C__c,
                                 Meter_Reading_I_C__c,New_Meter_Make__c,Meter_Manufacturing_Year__c,Capacity_SCMH__c,Meter_Qmin__c,Regulator_Type__c,
                                 Regulator_Make__c,Regulator_Capacity_SCMH__c,Regulator_Supply_Pressure__c,
                                 Isolate_Gas_Supply__c,Connect_Digital_pressure__c,Check_set_pressure__c,Pressure_observed_design__c,Check_relief_pressure__c,
                                 Check_SSV_setting__c,Check_the_lock_up_pressure__c,Close_Inlet_Valve__c,Depressurise_the_skid__c,
                                 Open_and_Check_Strainer__c,Clean_and_replace_strainer__c,Malfunctioning_corrosion_of_regulator__c,
                                 Check_meter_counter__c,Check_sign_boards__c,Check_condition_of_pipe__c,Check_meter_for_corrosion__c,
                                 Check_crimp_position__c,Check_all_clamps__c,Check_all_testing_points__c,Carry_out_leak_test__c,
                                 Carry_out_painting_of_piping__c,Check_all_seals__c,Check_MGL_seal__c,Check_for_illegal_tapping__c,
                                 Check_all_valves_are_operative__c,Check_all_stud_nuts__c,Check_the_leveling_alignment__c,Check_condition_of_foundation__c,
                                 Check_condition_of_FRP_cover__c,Open_the_outlet_valve__c,
                                 
                                 Observation_if_any_I_C__c,PBS_Regulator__c,PBS_SSV__c,PBS_Relief__c,PBS_Lock_Pressure__c,
                                 PAS_Regulator__c,PAS_SSV__c,PAS_Relief__c,PAS_Lock_Pressure__c,
                                 Seal_Mechanical_Meter__c,Seal_Electronic_Meter__c,Seal_Regulator__c,Seal_Lock_Details__c,
                                 Agent__c,Agent__r.Name,ServiceTerritoryId,
                                 (select id,O_MCheckInTimestamp__c from ServiceAppointments)
         
                     from WorkOrder where Id =:workOrderId limit 1 ];
                     
                   //  List<Material_Consumption__c> matConsumption Unit__c,Item_Code__c
                     lstMaterialConsumption = [Select id,Work_Order__c,Quantity__c,Item_description__c 
                                                                          from Material_Consumption__c where Work_Order__c=:workOrderId];             

                     
                     string serviceTerritoryId = wo.ServiceTerritoryId;
                     
                  ServiceTerritoryMember serTeMember = [select id,serviceTerritoryId,ServiceResourceId,ServiceResource.Name,
                                                                      ServiceResource.Role__c  from ServiceTerritoryMember 
                                                                  where serviceTerritoryId =:serviceTerritoryId  And ServiceResource.Role__c='Contractor'];
           

            wONumber = wo.WorkOrderNumber;
            issueDate = wo.Completion_Datetime__c.format('dd-MM-yyyy HH:mm:ss');
            activityStartTime = '';
            activityEndTime = '';
            bpNumber = wo.BP_Number__c;
            customerName = wo.Account.FirstName__c + ' ' + wo.Account.LastName__c;
            gasUsedFor = wo.Gas_Used_For__c;
            SAPEquipmentNo = wo.SAP_Equipment_No__c;
            district    = wo.Account.District__c;
            meterSerialNo = wo.New_Meter_Serial_No__c;
            contactNumber = wo.Account.Customer_Contact_no__c;
            typeOfMeter = wo.Type_Of_Meter_I_C__c;
            meterReading = wo.Meter_Reading_I_C__c;
            meterMake = wo.New_Meter_Make__c;
            meterManufacturingYear = wo.Meter_Manufacturing_Year__c;
            capacity = wo.Capacity_SCMH__c;
            meterQmin = wo.Meter_Qmin__c;
            regulatoryType = wo.Regulator_Type__c;
            regulatorMake = wo.Regulator_Make__c;
            regulatorCapacity = wo.Regulator_Capacity_SCMH__c;
            regulatorySupplyPressure = wo.Regulator_Supply_Pressure__c;
              
            
            isolateGasSupply = wo.Isolate_Gas_Supply__c;
            connectDigitalPressure = wo.Connect_Digital_pressure__c;
            CheckSetPressure = wo.Check_set_pressure__c;
            pressureObserved = wo.Pressure_observed_design__c;
            checkReliefPressure = wo.Check_relief_pressure__c;
            checkSSVSetting = wo.Check_SSV_setting__c;
            checkLockPressure = wo.Check_the_lock_up_pressure__c;
            closeInletValue = wo.Close_Inlet_Valve__c;
            depressuriseSkid = wo.Depressurise_the_skid__c;
            openStrainer = wo.Open_and_Check_Strainer__c;
            clearnStrainer = wo.Clean_and_replace_strainer__c;
            malfunctioningOrCorrosionRegulatory = wo.Malfunctioning_corrosion_of_regulator__c;
            checkMeterCounter = wo.Check_meter_counter__c;
            checkSignBoards = wo.Check_sign_boards__c;
            checkPipeCondition = wo.Check_condition_of_pipe__c;
            checkMeterBody = wo.Check_meter_for_corrosion__c;
            checkCrimpPosition = wo.Check_crimp_position__c;
            checkClamps = wo.Check_all_clamps__c;
            checkPointsProperlyPlugged =  wo.Check_all_testing_points__c;
            carryOutLeakTest =  wo.Carry_out_leak_test__c;
            carryOutPainting = wo.Carry_out_painting_of_piping__c;
            checkAllSeals = wo.Check_all_seals__c;
            checkMGLSeal = wo.Check_MGL_seal__c;
            checkIllegalTapping = wo.Check_for_illegal_tapping__c;
            checkAllValuesOperative = wo.Check_all_valves_are_operative__c;
            
            checkAllStudnuts = wo.Check_all_stud_nuts__c;
            checkLevelingOfSR = wo.Check_the_leveling_alignment__c;
            checkFoundationConditionAndBolt = wo.Check_condition_of_foundation__c;
            checkConditionFRPCover = wo.Check_condition_of_FRP_cover__c;
            openOutletValue  = wo.Open_the_outlet_valve__c;
            
            
            anyObservation = wo.Observation_if_any_I_C__c;

            pBSRegulator = wo.PBS_Regulator__c;
            pBSSSV    = wo.PBS_SSV__c;
            pBSRelief = wo.PAS_Relief__c;
            pBSLockPressure = wo.PAS_Lock_Pressure__c;
                      
            pASRegulator = wo.PAS_Regulator__c;
            pASSSV = wo.PAS_SSV__c;
            pASRelief = wo.PAS_Relief__c;
            pASLockPressure = wo.PAS_Lock_Pressure__c;
                      
            sealMechanicalMeter = wo.Seal_Mechanical_Meter__c;
            sealElectronicMeter = wo.Seal_Electronic_Meter__c;
            sealRegulator = wo.Seal_Regulator__c;
            sealLockDetails = wo.Seal_Lock_Details__c;
            
            technicianName = wo.Agent__r.Name;
           agencySupervisor =   serTeMember.ServiceResource.Name;                                      

            
       if (wo != null && wo.ServiceAppointments != null && !wo.ServiceAppointments.isEmpty()) {
    DateTime checkInDt = wo.ServiceAppointments[0].O_MCheckInTimestamp__c;
    if (checkInDt != null) {
        checkInTimeStamp = checkInDt.format('dd-MM-yyyy HH:mm:ss');
    }
}

}

}