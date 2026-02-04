import { LightningElement, wire, track, api } from 'lwc';
import {getPicklistValues} from 'lightning/uiObjectInfoApi';
import {getObjectInfo} from 'lightning/uiObjectInfoApi';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import saveMultipleContacts from '@salesforce/apex/addmultipleContactsController.saveMultipleContacts';
import {CloseActionScreenEvent} from 'lightning/actions'  

import CONTACT_OBJECT from '@salesforce/schema/Contact'
import GENDER_IDENTITY_FIELD from '@salesforce/schema/Contact.GenderIdentity'

export default class ScreenQuickAction extends LightningElement {
    @track contacts = [];
    @api recordId;

    @wire(getObjectInfo,{objectApiName:CONTACT_OBJECT})
    contactObjectInfo;
    
    @wire(getPicklistValues,{recordTypeId:'$contactObjectInfo.data.defaultRecordTypeId', fieldApiName:GENDER_IDENTITY_FIELD})
    genderPicklistValues;

    get genderPicklistOptions(){
        return this.genderPicklistValues?.data?.values;
    }

    connectedCallback() {
        this.addNewContactHandler();
    }

    addNewContactHandler(event){
       this.contacts.push({
        tempId: Date.now()
        });
    }

deleteClickHandler(event){
    if (this.contacts.length == 1){
    this.ShowToast('You can not delete last Contact.');
    return;
    }
    let tempId = event.target?.dataset.tempId;
    this.contacts = this.contacts.filter(a => a.tempId != tempId); 

}

elementChangeHandler(event){
    let contactRow = this.contacts.find(a => a.tempId == event.target.dataset.tempId);
    if(contactRow){
        console.log('contactRow+++' +contactRow);
    contactRow[event.target.name] = event.target?.value;
    }
}

async submitHandler(event){
const allValid = this.checkControlValidity()
if(allValid){
this.contacts.forEach(a => a.AccountId = this.recordId);
let response = await saveMultipleContacts({conlist:this.contacts});
console.log('Check the response here '+response);
if(response.isSuccess){
this.ShowToast('Contacts Saved Successfully', 'success', 'success');
this.dispatchEvent(new CloseActionScreenEvent());
}else{
this.ShowToast('Something went Wrong while saving Contacts-' +response.message);
}
}
else{
this.ShowToast('Please correct below errors first to procced further');
}
}

checkControlValidity(){
    let isvalid = true,
        controls = this.template.querySelectorAll('lightning-input,lightning-combobox');
 
    controls.forEach(field => {
        if(!field.checkValidity()){
        field.reportValidity();
        isvalid = false;
    }
 });
 return isvalid;
}

    ShowToast(message, title ='Error', variant= 'error'){
        const event = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(event)

    }
}