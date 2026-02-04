import { LightningElement,track,api } from 'lwc';

import saveMRJCData from '@salesforce/apex/MeterReplacementMRJCContr.saveMRJCData';
//import generateAndAttachPdf from '@salesforce/apex/MeterReplacementMRJCContr.generateAndAttachPdf';
import materialConsumption from '@salesforce/apex/MeterReplacementMRJCContr.materialConsumption';
import getItemDescriptionOptions from '@salesforce/apex/MeterReplacementMRJCContr.getItemDescriptionOptions';
import LightningAlert from 'lightning/alert';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class MeterReplacementMRJCComp extends LightningElement {

    @api recordId;
    @track isload=false;
    


    natureOfWorkOptions  = [
    { label: 'Old Meter Replacement Under Maintanace', value: 'Old Meter Replacement Under Maintanace' },
    { label: 'Meter Not Running', value: 'Meter Not Running' },
    { label: 'Meter Sound', value: 'Meter Sound' },
    { label: 'Counter Defactive / Smokey Glass', value: 'Counter Defactive / Smokey Glass' },
    { label: 'Faulty Meter', value: 'Faulty Meter' },
    { label: 'Other', value: 'Other' }
];


leakTestSolutionOptions  = [
    { label: 'Ok', value: 'Ok' },
    { label: 'Not Ok', value: 'Not Ok' },
    { label: 'NA', value: 'NA ' }

];

penumaticPressureOptions  = [
    { label: 'Ok', value: 'Ok' },
    { label: 'Not Ok', value: 'Not Ok' }
];

rubberTubeTypesOptions  = [
    { label: 'Suraksha Rubber Tube', value: 'Suraksha Rubber Tube' },
    { label: 'Neoprene Rubber Tube', value: 'Neoprene Rubber Tube' },
    { label: 'Other', value: 'Other' }

];

rubberTubeConditionOptions  = [
    { label: 'Ok', value: 'Ok' },
    { label: 'Not Ok', value: 'Not Ok' }
];

noGasLeakOptions  = [
    { label: 'Yes', value: 'Yes' },
    { label: 'No', value: 'No' }
];

satisOrNotSatisfactoryOptions  = [
    { label: 'Satisfactory', value: 'Satisfactory' },
    { label: 'Not Satisfactory', value: 'Not Satisfactory' }
];

        @track itemDescriptionOptions = [];


connectedCallback(){

     this.getItemDescriptionOptions();

}

 getItemDescriptionOptions(){
        getItemDescriptionOptions({})
            .then(result => {
                this.itemDescriptionOptions = result.map(value => ({ label: value, value }));
                console.log('Fetched item description options:', this.itemDescriptionOptions);
            })
            .catch(error => {
                console.error('Error fetching item description options:', error);
            });
}

  @track materialList = [{
        itemCode: '',
        itemDescription: '',
       // unit: '',
        quantity: ''
    }];

     handleMaterialChange(event) {
        const index = event.target.dataset.index;
        const field = event.target.name;
        const value = event.detail.value || event.target.value;

        console.log(`Material Change - Index: ${index}, Field: ${field}, Value: ${value}`);
        this.materialList[index][field] = value;
    }

    addMaterialRow() {
        console.log('Adding new material row');
        this.materialList.push({
            // itemCode: '',
            itemDescription: '',
          //  unit: '',
            quantity: ''
        });
    }

    removeMaterialRow(event) {
        const index = event.target.dataset.index;
        console.log(`Removing material row at index: ${index}`);
        if (this.materialList.length > 1) {
            this.materialList.splice(index, 1);
        }
    }

     hasValidMaterialData() {
        return this.materialList.some(row => 
            (row.itemCode && row.itemCode.trim() !== '') ||
            (row.itemDescription && row.itemDescription.trim() !== '') ||
          //  (row.unit && row.unit.trim() !== '') ||
            (row.quantity && row.quantity.trim() !== '')
        );
    }




@track mrjcReport = {
        natureOfWork : '',
        reason : '',
        leakTestSolution : '',
        penumaticPressure : '',
        gascoseekerReading : '',
        rubberTubeType : '',
        noGasLeak : '',
        actionTaken : '',
        materialRecovered : '',
        rubberTuberCondition : '',
        oldMeterMake : '',
        oldMeterSerialNo : '',
        oldMeterReading : '',
        oldRemark : '',
        newMeterMake : '',
        newMeterSerialNo : '',
        newMeterReading : '',
        newRemark : '',
        satisOrNotSatisfactory : ''
        
    };

    handleMRJCReport(event){

        const field = event.target.name;
        const value = event.target.value;

        if (field) {
            this.mrjcReport[field] = value;
        }
    }

   
   

    handleSave(){


        if(!this.mrjcReport.natureOfWork || !this.mrjcReport.reason || !this.mrjcReport.leakTestSolution || !this.mrjcReport.penumaticPressure ||
         !this.mrjcReport.gascoseekerReading ||  !this.mrjcReport.rubberTubeType || !this.mrjcReport.noGasLeak || !this.mrjcReport.actionTaken ||
          !this.mrjcReport.materialRecovered || !this.mrjcReport.oldMeterMake || !this.mrjcReport.oldMeterSerialNo || 
           !this.mrjcReport.newMeterMake || !this.mrjcReport.newMeterSerialNo || !this.mrjcReport.satisOrNotSatisfactory){

            console.log('inside if error');
          // this.showtoast('Warning','Please enter required fields.','warning');
           LightningAlert.open({
            message: 'Please enter required fields.',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        }).then(() => {
                 this.load=true;
         });
            return;
         }

    // this.isload = true;

       if (this.materialList.length > 0 && this.hasValidMaterialData()) {
                console.log('🔧 Saving Material Details:', JSON.stringify(this.materialList));

                materialConsumption({
                    recordId: this.recordId,
                    materialList: this.materialList

                });

                 }



    const jsonData = JSON.stringify(this.mrjcReport);

    console.log('Json data :::', jsonData);
        saveMRJCData({recordId : this.recordId, mrjcReport : jsonData})
        .then( result => {
            console.log('Result ::', result);
            // this.showtoast('Success','Record Updated Successfully.','Success');
             LightningAlert.open({
            message: 'Record Updated Successfully.',
            theme: 'success',   // red error dialog
            label: 'Success'    // header text
        }).then(() => {
                 this.load=false;

                 this.dispatchEvent(new CustomEvent('cancel'));
         });
    //    this.isload=false;
          
    //       this.dispatchEvent(new CustomEvent('cancel'));
          //  generateAndAttachPdf({worOrderId :this.recordId});



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