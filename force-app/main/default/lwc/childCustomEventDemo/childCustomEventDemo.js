import { LightningElement } from 'lwc';

export default class ChildCustomEventDemo extends LightningElement {
    clickHandler(){

        let mycustomevent = new CustomEvent("displaymsg")

        this.dispatchEvent(mycustomevent);
    }
}