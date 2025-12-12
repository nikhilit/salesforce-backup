import { LightningElement,api } from 'lwc';

export default class RecepieModal extends LightningElement {
    @api selectedMeal;
    clickHandler()
    {
        let myCustomEvent = new CustomEvent('closemodal');
        this.dispatchEvent(myCustomEvent);
    }
}