import { LightningElement, api } from 'lwc';

export default class ChildCounter extends LightningElement {
   

    increment() {
        this.dispatchEvent(new CustomEvent('increment'));
    }

    decrement() {
        this.dispatchEvent(new CustomEvent('decrement'));
    }

    reset(){
        this.dispatchEvent(new CustomEvent('reset'));
    }
}