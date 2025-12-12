import { LightningElement } from 'lwc';

export default class ParentCounter extends LightningElement {
    counter = 0;

    handleIncrement() {
        this.counter++;
    }

    handleDecrement() {
        this.counter--;
    }

    handlereset(){
        this.counter = 0;
    }
}