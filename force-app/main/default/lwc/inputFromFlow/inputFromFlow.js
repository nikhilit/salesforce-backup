import { LightningElement, api } from 'lwc';
import {
    FlowAttributeChangeEvent,
    FlowNavigationNextEvent,
} from 'lightning/flowSupport';

export default class InputFromFlow extends LightningElement {
    @api inputName;

    chnageHandler(event) {
        this.inputName = event.target.value;

        const attributeChangeEvent = new FlowAttributeChangeEvent(
            'inputName',
            this.inputName
        );
        this.dispatchEvent(attributeChangeEvent);
    }
}