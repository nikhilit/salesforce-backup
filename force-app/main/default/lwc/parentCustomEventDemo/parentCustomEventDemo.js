import { LightningElement } from 'lwc';

export default class ParentCustomEventDemo extends LightningElement {
    displaymessage= false;

    displaymessageHandler(event) 
    {
        this.displaymessage = true;
    }
}