/**
* @File Name : IAndCContr.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : July 4, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | July 4, 2025 |   | Initial Version
**/

public without sharing class IAndCContr {
		
	@AuraEnabled
	public static string saveIAndCData(string recordId, string iAndCReport){


		try {

   Map<String, Object> dataMap = (Map<String, Object>) JSON.deserializeUntyped(iAndCReport);

 WorkOrder wOrder = [
        SELECT id,Gas_Used_For__c, SAP_Equipment_No__c,New_Meter_Serial_No__c,Type_Of_Meter_I_C__c,
                                 Meter_Reading_I_C__c,New_Meter_Make__c,Meter_Manufacturing_Year__c,Capacity_SCMH__c,Meter_Qmin__c,Regulator_Type__c,
                                 Regulator_Make__c,Regulator_Capacity_SCMH__c,Regulator_Supply_Pressure__c,
                                 Isolate_Gas_Supply__c,Connect_Digital_pressure__c,Check_set_pressure__c,Pressure_observed_design__c,
                                 Check_relief_pressure__c,Check_SSV_setting__c,
                                 Check_the_lock_up_pressure__c,Close_Inlet_Valve__c,Depressurise_the_skid__c,
                                 Open_and_Check_Strainer__c,Clean_and_replace_strainer__c,Malfunctioning_corrosion_of_regulator__c,
                                 Check_meter_counter__c,Check_sign_boards__c,Check_condition_of_pipe__c,Check_meter_for_corrosion__c,
                                 Check_crimp_position__c,Check_all_clamps__c,Check_all_testing_points__c,Carry_out_leak_test__c,
                                 Carry_out_painting_of_piping__c,Check_all_seals__c,Check_MGL_seal__c,Check_for_illegal_tapping__c,
                                 Check_all_valves_are_operative__c,Check_all_stud_nuts__c,Check_the_leveling_alignment__c,Check_condition_of_foundation__c,
                                 Check_condition_of_FRP_cover__c,Open_the_outlet_valve__c,
                                 
                                 Observation_if_any_I_C__c,PBS_Regulator__c,PBS_SSV__c,PBS_Relief__c,PBS_Lock_Pressure__c,
                                 PAS_Regulator__c,PAS_SSV__c,PAS_Relief__c,PAS_Lock_Pressure__c,
                                 Seal_Mechanical_Meter__c,Seal_Electronic_Meter__c,Seal_Regulator__c,Seal_Lock_Details__c
                                                                           
                     from WorkOrder  WHERE Id = :recordId LIMIT 1
    ];

wOrder.Gas_Used_For__c = String.isNotBlank((String)dataMap.get('gasUsedFor')) ? (String)dataMap.get('gasUsedFor') : null;
wOrder.SAP_Equipment_No__c = String.isNotBlank((String)dataMap.get('sapEquipmentNo')) ? (String)dataMap.get('sapEquipmentNo') : null;
wOrder.New_Meter_Serial_No__c = String.isNotBlank((String)dataMap.get('meterSerialNo')) ? (String)dataMap.get('meterSerialNo') : null;
wOrder.Type_Of_Meter_I_C__c = String.isNotBlank((String)dataMap.get('typeOfMeter')) ? (String)dataMap.get('typeOfMeter') : null;
wOrder.Meter_Reading_I_C__c = String.isNotBlank((String)dataMap.get('meterReading')) ? (String)dataMap.get('meterReading') : null;
wOrder.New_Meter_Make__c = String.isNotBlank((String)dataMap.get('meterMake')) ? (String)dataMap.get('meterMake') : null;
wOrder.Meter_Manufacturing_Year__c = String.isNotBlank((String)dataMap.get('meterManufacturingYear')) ? (String)dataMap.get('meterManufacturingYear') : null;
wOrder.Capacity_SCMH__c = String.isNotBlank((String)dataMap.get('capacitySCMH')) ? (String)dataMap.get('capacitySCMH') : null;
wOrder.Meter_Qmin__c = String.isNotBlank((String)dataMap.get('meterQmin')) ? (String)dataMap.get('meterQmin') : null;
wOrder.Regulator_Type__c = String.isNotBlank((String)dataMap.get('regulatorType')) ? (String)dataMap.get('regulatorType') : null;
wOrder.Regulator_Make__c = String.isNotBlank((String)dataMap.get('regulatorMake')) ? (String)dataMap.get('regulatorMake') : null;
wOrder.Regulator_Capacity_SCMH__c = String.isNotBlank((String)dataMap.get('regulatorCapacitySCMH')) ? (String)dataMap.get('regulatorCapacitySCMH') : null;
wOrder.Regulator_Supply_Pressure__c = String.isNotBlank((String)dataMap.get('regulatorSupplyPressure')) ? (String)dataMap.get('regulatorSupplyPressure') : null;
wOrder.Isolate_Gas_Supply__c = String.isNotBlank((String)dataMap.get('isolateGasSupply')) ? (String)dataMap.get('isolateGasSupply') : null;
wOrder.Connect_Digital_pressure__c = String.isNotBlank((String)dataMap.get('connectDigitalPressure')) ? (String)dataMap.get('connectDigitalPressure') : null;
wOrder.Check_set_pressure__c = String.isNotBlank((String)dataMap.get('checkSetPressure')) ? (String)dataMap.get('checkSetPressure') : null;
wOrder.Pressure_observed_design__c = String.isNotBlank((String)dataMap.get('pressureObservedDesign')) ? (String)dataMap.get('pressureObservedDesign') : null;
wOrder.Check_relief_pressure__c = String.isNotBlank((String)dataMap.get('checkReliefPressure')) ? (String)dataMap.get('checkReliefPressure') : null;
wOrder.Check_SSV_setting__c = String.isNotBlank((String)dataMap.get('checkSSVSetting')) ? (String)dataMap.get('checkSSVSetting') : null;
wOrder.Check_the_lock_up_pressure__c = String.isNotBlank((String)dataMap.get('checkLockUpPressure')) ? (String)dataMap.get('checkLockUpPressure') : null;
wOrder.Close_Inlet_Valve__c = String.isNotBlank((String)dataMap.get('closeInletValue')) ? (String)dataMap.get('closeInletValue') : null;
wOrder.Depressurise_the_skid__c = String.isNotBlank((String)dataMap.get('depressuriseTheSkid')) ? (String)dataMap.get('depressuriseTheSkid') : null;
wOrder.Open_and_Check_Strainer__c = String.isNotBlank((String)dataMap.get('openCheckStrainerCondition')) ? (String)dataMap.get('openCheckStrainerCondition') : null;
wOrder.Clean_and_replace_strainer__c = String.isNotBlank((String)dataMap.get('cleanStrainer')) ? (String)dataMap.get('cleanStrainer') : null;
wOrder.Malfunctioning_corrosion_of_regulator__c = String.isNotBlank((String)dataMap.get('malfunctioningRegulator')) ? (String)dataMap.get('malfunctioningRegulator') : null;
wOrder.Check_meter_counter__c = String.isNotBlank((String)dataMap.get('checkMeterCounter')) ? (String)dataMap.get('checkMeterCounter') : null;
wOrder.Check_sign_boards__c = String.isNotBlank((String)dataMap.get('checkSignBoards')) ? (String)dataMap.get('checkSignBoards') : null;
wOrder.Check_condition_of_pipe__c = String.isNotBlank((String)dataMap.get('checkPipeCondition')) ? (String)dataMap.get('checkPipeCondition') : null;
wOrder.Check_meter_for_corrosion__c = String.isNotBlank((String)dataMap.get('checkMeterBody')) ? (String)dataMap.get('checkMeterBody') : null;
wOrder.Check_crimp_position__c = String.isNotBlank((String)dataMap.get('checkCrimpPosition')) ? (String)dataMap.get('checkCrimpPosition') : null;
wOrder.Check_all_clamps__c = String.isNotBlank((String)dataMap.get('checkAllClamps')) ? (String)dataMap.get('checkAllClamps') : null;
wOrder.Check_all_testing_points__c = String.isNotBlank((String)dataMap.get('checkAllTesting')) ? (String)dataMap.get('checkAllTesting') : null;
wOrder.Carry_out_leak_test__c = String.isNotBlank((String)dataMap.get('carryOutLeakTest')) ? (String)dataMap.get('carryOutLeakTest') : null;
wOrder.Carry_out_painting_of_piping__c = String.isNotBlank((String)dataMap.get('carryOutPainting')) ? (String)dataMap.get('carryOutPainting') : null;
wOrder.Check_all_seals__c = String.isNotBlank((String)dataMap.get('checkAllSeals')) ? (String)dataMap.get('checkAllSeals') : null;
wOrder.Check_MGL_seal__c = String.isNotBlank((String)dataMap.get('checkMGLSeal')) ? (String)dataMap.get('checkMGLSeal') : null;
wOrder.Check_for_illegal_tapping__c = String.isNotBlank((String)dataMap.get('checkForAnyIllegalTapping')) ? (String)dataMap.get('checkForAnyIllegalTapping') : null;
wOrder.Check_all_valves_are_operative__c = String.isNotBlank((String)dataMap.get('checkAllValves')) ? (String)dataMap.get('checkAllValves') : null;
wOrder.Check_all_stud_nuts__c = String.isNotBlank((String)dataMap.get('checkAllStudnuts')) ? (String)dataMap.get('checkAllStudnuts') : null;
wOrder.Check_the_leveling_alignment__c = String.isNotBlank((String)dataMap.get('checkLevelingSR')) ? (String)dataMap.get('checkLevelingSR') : null;
wOrder.Check_condition_of_foundation__c = String.isNotBlank((String)dataMap.get('checkConditionOfFoundation')) ? (String)dataMap.get('checkConditionOfFoundation') : null;
wOrder.Check_condition_of_FRP_cover__c = String.isNotBlank((String)dataMap.get('checkConditionOfFRP')) ? (String)dataMap.get('checkConditionOfFRP') : null;
wOrder.Open_the_outlet_valve__c = String.isNotBlank((String)dataMap.get('openOutletValve')) ? (String)dataMap.get('openOutletValve') : null;
wOrder.Observation_if_any_I_C__c = String.isNotBlank((String)dataMap.get('observationifany')) ? (String)dataMap.get('observationifany') : null;
wOrder.PBS_Regulator__c = String.isNotBlank((String)dataMap.get('pbsRegulator')) ? (String)dataMap.get('pbsRegulator') : null;
wOrder.PBS_SSV__c = String.isNotBlank((String)dataMap.get('pbsSSV')) ? (String)dataMap.get('pbsSSV') : null;
wOrder.PBS_Relief__c = String.isNotBlank((String)dataMap.get('pbsRelief')) ? (String)dataMap.get('pbsRelief') : null;
wOrder.PBS_Lock_Pressure__c = String.isNotBlank((String)dataMap.get('pbsLockPressure')) ? (String)dataMap.get('pbsLockPressure') : null;
wOrder.PAS_Regulator__c = String.isNotBlank((String)dataMap.get('pasRegulator')) ? (String)dataMap.get('pasRegulator') : null;
wOrder.PAS_SSV__c = String.isNotBlank((String)dataMap.get('pasSSV')) ? (String)dataMap.get('pasSSV') : null;
wOrder.PAS_Relief__c = String.isNotBlank((String)dataMap.get('pasRelief')) ? (String)dataMap.get('pasRelief') : null;
wOrder.PAS_Lock_Pressure__c = String.isNotBlank((String)dataMap.get('pasLockPressure')) ? (String)dataMap.get('pasLockPressure') : null;
wOrder.Seal_Mechanical_Meter__c = String.isNotBlank((String)dataMap.get('sealMechanicalMeter')) ? (String)dataMap.get('sealMechanicalMeter') : null;
wOrder.Seal_Electronic_Meter__c = String.isNotBlank((String)dataMap.get('sealElectronicMeter')) ? (String)dataMap.get('sealElectronicMeter') : null;
wOrder.Seal_Regulator__c = String.isNotBlank((String)dataMap.get('sealRegulator')) ? (String)dataMap.get('sealRegulator') : null;
wOrder.Seal_Lock_Details__c = String.isNotBlank((String)dataMap.get('sealLockDetails')) ? (String)dataMap.get('sealLockDetails') : null;

        update wOrder;

        system.debug('Updated work order ::'+ wOrder);

	  updateWorkStepStatus(recordId,'Service Report');

        generateAndAttachPdf(recordId);

	return 'Success';

		}
		catch(Exception e){
            system.debug('Error ::'+ e.getLineNumber() + e.getMessage());
			return  'Error';
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
            ws.Status = 'Completed'; 
            update ws;
        }
     }

     
    public static Id generateAndAttachPdf(String worOrderId) {

        WorkOrder worOrder = [Select id,BP_Number__c from WorkOrder where id=: worOrderId];

        system.debug('Inside generateAndAttachPdf'+ worOrderId);

        PageReference pdfPage = Page.O_MIANDCPage;

        system.debug('Pdfpage :'+ pdfPage);
        pdfPage.getParameters().put('id', worOrderId);
        Blob pdfBlob = pdfPage.getContentAsPDF();

        ContentVersion cv = new ContentVersion(
            Title = 'Service Report' + ' ' + worOrder.BP_Number__c + '.pdf',
            PathOnClient = 'O_MMeterDetails_' + worOrderId + '.pdf',
            VersionData = pdfBlob
        );
        insert cv;

        system.debug('Content version::'+ cv);

        ContentDocument cd = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :cv.Id LIMIT 1];
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cd.Id,
            LinkedEntityId = worOrderId,
            ShareType = 'V'
        );
        insert cdl;

        system.debug('cdl::'+ cdl);

        return cd.Id;
    }





}