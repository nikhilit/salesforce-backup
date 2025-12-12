import { LightningElement, api} from 'lwc';

export default class ContactItem extends LightningElement {
    @api contact;

    clickhHandler(event){

    //prevent the anchor element from navigation
     event.preventDefault();
    // 1. creation of custom event

    const selectionevent = new CustomEvent("selection",{
        detail: this.contact.id
    });

    //2. dispatch the event 
    this.dispatchEvent(selectionevent);
}
}