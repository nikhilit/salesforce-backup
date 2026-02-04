import { LightningElement,api,track } from 'lwc';
import saveIAndCData from '@salesforce/apex/IAndCContr.saveIAndCData';
import LightningAlert from 'lightning/alert';

export default class O_MI_CComp extends LightningElement {


@api recordId;
    @track isload=false;


yesNoOptions  = [
    { label: 'Yes', value: 'Yes' },
    { label: 'No', value: 'No' }

];

@track iAndCReport = {
        gasUsedFor : '',
        sapEquipmentNo : '',
        meterSerialNo : '',
        typeOfMeter : '',
        meterReading : '',
        meterMake : '',
        meterManufacturingYear : '',
        capacitySCMH : '',
        meterQmin : '',
        regulatorType : '',
        regulatorMake : '',
        regulatorCapacitySCMH : '',
        regulatorSupplyPressure : '',
        isolateGasSupply : '',
        connectDigitalPressure : '',
        checkSetPressure : '',
        pressureObservedDesign : '',
        checkReliefPressure : '',
        checkSSVSetting : '',
        checkLockUpPressure : '',
        closeInletValue : '',
        depressuriseTheSkid : '',
        openCheckStrainerCondition : '',
        cleanStrainer : '',
        malfunctioningRegulator : '',
        checkMeterCounter : '',
        checkSignBoards : '',
        checkPipeCondition : '',
        checkMeterBody : '',
        checkCrimpPosition : '',
        checkAllClamps : '',
        checkAllTesting : '',
        carryOutLeakTest : '',
        carryOutPainting : '',
        checkAllSeals : '',
        checkMGLSeal : '',
        checkForAnyIllegalTapping : '',
        checkAllValves : '',
        checkAllStudnuts : '',
        checkLevelingSR : '',
        checkConditionOfFoundation : '',
        checkConditionOfFRP : '',
        openOutletValve : '',
        observationifany : '',
        pbsRegulator : '',
        pbsSSV : '',
        pbsRelief : '',
        pbsLockPressure : '',
        pasRegulator : '',
        pasSSV : '',
        pasRelief : '',
        pasLockPressure : '',
        sealMechanicalMeter : '',
        sealElectronicMeter : '',
        sealRegulator : '',
        sealLockDetails : '',
      
        
    };

     handleICReport(event){

        const field = event.target.name;
        const value = event.target.value;

        if (field) {
            this.iAndCReport[field] = value;
        }
    }

    handleCancel() {

         setTimeout(() => {
            history.back();
        }, 1000);        
         console.log('inside handle cancel');
       
    }

    handleSave(){


            if(!this.iAndCReport.gasUsedFor || !this.iAndCReport.sapEquipmentNo || !this.iAndCReport.meterSerialNo || 
        !this.iAndCReport.typeOfMeter || !this.iAndCReport.meterReading || !this.iAndCReport.meterMake || 
        !this.iAndCReport.meterManufacturingYear || !this.iAndCReport.capacitySCMH || !this.iAndCReport.meterQmin || 
        !this.iAndCReport.regulatorType || !this.iAndCReport.regulatorMake || !this.iAndCReport.regulatorCapacitySCMH || 
        !this.iAndCReport.regulatorSupplyPressure || !this.iAndCReport.isolateGasSupply || !this.iAndCReport.connectDigitalPressure || 
        !this.iAndCReport.checkSetPressure || !this.iAndCReport.pressureObservedDesign || !this.iAndCReport.checkReliefPressure || 
        !this.iAndCReport.checkSSVSetting || !this.iAndCReport.checkLockUpPressure || !this.iAndCReport.closeInletValue || 
        !this.iAndCReport.depressuriseTheSkid || !this.iAndCReport.openCheckStrainerCondition || !this.iAndCReport.cleanStrainer || 
        !this.iAndCReport.malfunctioningRegulator || !this.iAndCReport.checkMeterCounter || !this.iAndCReport.checkSignBoards || 
        !this.iAndCReport.checkPipeCondition || !this.iAndCReport.checkMeterBody || !this.iAndCReport.checkCrimpPosition || 
        !this.iAndCReport.checkAllClamps || !this.iAndCReport.checkAllTesting || !this.iAndCReport.carryOutLeakTest || 
        !this.iAndCReport.carryOutPainting || !this.iAndCReport.checkAllSeals || !this.iAndCReport.checkMGLSeal || 
        !this.iAndCReport.checkForAnyIllegalTapping || !this.iAndCReport.checkAllValves || !this.iAndCReport.checkAllStudnuts || 
        !this.iAndCReport.checkLevelingSR || !this.iAndCReport.checkConditionOfFoundation || !this.iAndCReport.checkConditionOfFRP || 
        !this.iAndCReport.openOutletValve || !this.iAndCReport.observationifany || !this.iAndCReport.pbsRegulator || 
        !this.iAndCReport.pbsSSV || !this.iAndCReport.pbsRelief || !this.iAndCReport.pbsLockPressure ||!this.iAndCReport.pasRegulator || 
        !this.iAndCReport.pasSSV || !this.iAndCReport.pasRelief || !this.iAndCReport.pasLockPressure || !this.iAndCReport.sealMechanicalMeter || 
        !this.iAndCReport.sealElectronicMeter || !this.iAndCReport.sealRegulator || !this.iAndCReport.sealLockDetails) {
       
            console.log('inside if error');
           // this.showtoast('Warning','Please enter required fields.','warning');
             LightningAlert.open({
            message: 'Please enter required fields.',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        });
            return;
         }

     this.isload = true;



    const jsonData = JSON.stringify(this.iAndCReport);

    console.log('Json data :::', jsonData);
        saveIAndCData({recordId : this.recordId, iAndCReport : jsonData})
        .then( result => {
            console.log('Result ::', result);
            // this.showtoast('Success','Record Updated Successfully.','Success');
              LightningAlert.open({
            message: 'Record Updated Successfully.',
            theme: 'success',   // red error dialog
            label: 'Success'    // header text
        }).then(() => {
                this.isload=false;
        this.handleCancel();
         });
    //    this.isload=false;
    //     this.handleCancel();
        })
        .catch(error => {
            this.isload=false;
            console.log('Error :', error);
        })
         
    }

    showtoast(title, msg, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant
        });
        this.dispatchEvent(event);
    }



}