/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 15-10-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   15-10-2025   Kartik Patkar, Appstrail   Initial Version
**/
import { LightningElement, api } from 'lwc';

export default class CustomImageCell extends LightningElement {

    @api value;

    handleClick(event) {
        event.stopPropagation(); // prevent row selection override
        console.log('🔹 Cell template handler fired::' + this.value);
        this.dispatchEvent(new CustomEvent('imageclick', {
            detail: { value: this.value },
            bubbles: true,
            composed: true
        }));
    }
}