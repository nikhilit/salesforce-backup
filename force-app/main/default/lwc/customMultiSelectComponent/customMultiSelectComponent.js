/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 03-11-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   03-11-2025   Kartik Patkar, Appstrail   Initial Version
**/
import { api, LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class CustomMultiSelectComponent extends LightningElement {

    _options=[];
    @api 
    set options(value){
        console.log('options value'+JSON.stringify(value));
        this._options=value;
        this.init();
    }
    get options(){
        return this._options;
    }
    @api label='Label';
    @api specialOption='';
    @api selectedOption='';
    @api requiredField=false;

    @track error;
    @track dropdown='slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
    @track dataList;
    @track dropdownList = 'slds-media slds-listbox__option slds-listbox__option_entity slds-listbox__option_has-meta';
    @track selectedValue = '';
    @track selectedListOfValues='';
    load=false;
    showSelectedBox=false;

    connectedCallback(){
        // this.init();
    }

    init(){
        this.load=false;
        if(this._options.length==0){
            this.showToastMessage('Option List is Empty.','error');
            return;
        }
        var optionsModify=[];
        for(let i=0;i<this._options.length;i++){
            var option=this._options[i];
            console.log('options:::'+JSON.stringify(option));
            var newOption={
                'value':option.value,
                'label':option.label,
                'class':this.dropdownList,
            }
            optionsModify.push(newOption);
        }
        this._options=optionsModify;

        if(this.selectedOption!=''){
            this.defaultSelectedValue();
        }
        this.load=true;
        console.log('special::'+this.specialOption);
        console.log('selected::'+this.selectedOption);
        this.onOptionSelected();
    }

    renderedCallback(){
        if(this.selectedListOfValues.length==0){
            this.showSelectedBox=false;
        }else{
            this.showSelectedBox=true;
        }
    }

    openDropdown(){
        this.dropdown='slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open';  
    }

    closeDropDown(){
        this.dropdown='slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
    }

    onOptionSelected(){
        const custEvent = new CustomEvent('changevalue',{
            detail: {value:this.selectedListOfValues}
        });
        this.dispatchEvent(custEvent);
    }

    selectOption(event){
        var isCheck = event.currentTarget.dataset.id;
        var label = event.currentTarget.dataset.name;
        var selectedListData=[];
        var selectedOption='';
        var allOptions = this._options;
        var count=0;
            for(let i=0;i<allOptions.length;i++){ 
                if(allOptions[i].label===label){ 
                    if(isCheck==='true'){ 
                        allOptions[i].isChecked = false;
                        allOptions[i].class = this.dropdownList;
                    }
                    else{ 
                        allOptions[i].isChecked = true; 
                        allOptions[i].class='slds-media slds-listbox__option slds-listbox__option_plain slds-media_small slds-media_center slds-is-selected';
                    }
                } 
                //special option
                if(this.specialOption!=''){
                    if(allOptions[i].label===label && allOptions[i].isChecked && allOptions[i].label===this.specialOption){ 
                        console.log('in special');
                        this.deselectAllOptions();
                        selectedListData=[];
                        allOptions[i].isChecked=true;
                        allOptions[i].class='slds-media slds-listbox__option slds-listbox__option_plain slds-media_small slds-media_center slds-is-selected';
                        selectedListData.push(allOptions[i].value); 
                        console.log('selectedListData::'+JSON.stringify(selectedListData));
                        count=1;
                        break;
                    }
                    if(allOptions[i].isChecked && allOptions[i].label!=this.specialOption){
                        this.deselectAllOptions(this.specialOption);
                        selectedListData.push(allOptions[i].value); 
                        count++;
                    }
                }else{
                    if(allOptions[i].isChecked){
                        selectedListData.push(allOptions[i].value); 
                        count++;
                    }
                }   
            }
        
        if(count === 1){
            selectedOption = count+' Selected';
        }
        else if(count>1){
            selectedOption = count+' Selected';
        }
        this._options = allOptions;
        this.selectedValue = selectedOption;
        this.selectedListOfValues = selectedListData;
        this.onOptionSelected();
    }

    removeRecord(event){
        var value = event.detail.name;
        var removedOptions = this._options;
        var count = 0;
        var selectedListData=[];
        for(let i=0; i < removedOptions.length; i++){
            if(removedOptions[i].value === value){
                removedOptions[i].isChecked = false;
                removedOptions[i].class = this.dropdownList;
            }
            if(removedOptions[i].isChecked){
                selectedListData.push(removedOptions[i].value); 
                count++;
            }   
        }
        var selectedOption;
        if(count === 1){
            selectedOption = count+' Selected';
        }
        else if(count>1){
            selectedOption = count+' Selected';
        }
        else if(count === 0){
            selectedOption = '';
            selectedListData = "";
        }
        this.selectedListOfValues = selectedListData;
        this.selectedValue = selectedOption;
        this._options = removedOptions;
        this.onOptionSelected();
    }

    deselectAllOptions(option){
        var removedOptions = this._options;
        var selectedListData=[];
        var count=0;
        if(option==null){
            for(let i=0; i < removedOptions.length; i++){
                removedOptions[i].isChecked = false;
                removedOptions[i].class = this.dropdownList;
                selectedListData=[];
                count++;
            }
        }else{
            for(let i=0; i < removedOptions.length; i++){
                if(removedOptions[i].label==option){
                    removedOptions[i].isChecked = false;
                    removedOptions[i].class = this.dropdownList;
                    selectedListData=[]; 
                    count++;
                } 
            }
        }
        this.selectedValue=count+' Selected';
        this.selectedListOfValues = selectedListData;
        this._options = removedOptions;
    }

    defaultSelectedValue(){
        var selectedListData=[];
        var count=0;
        for(let j=0;j<this.selectedOption.length;j++){
            for(let i=0;i<this._options.length;i++){
                if(this._options[i].label===this.selectedOption[j]){
                    selectedListData.push(this._options[i].value);
                    this._options[i].class='slds-media slds-listbox__option slds-listbox__option_plain slds-media_small slds-media_center slds-is-selected';
                    this._options[i].isChecked=true;
                    count++;
                }
            }
        }
        this.selectedValue = count+' Selected';
        this.selectedListOfValues = selectedListData;
        this.showSelectedBox=true;
    }

    showToastMessage(title,variant){
        const evt = new ShowToastEvent({
            title: title, 
            variant: variant,
            mode: 'pester'
        });
        this.dispatchEvent(evt);
    }
}