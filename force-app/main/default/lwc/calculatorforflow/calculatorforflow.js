import { LightningElement, api } from 'lwc';
import {
    FlowAttributeChangeEvent,
    FlowNavigationNextEvent,
} from 'lightning/flowSupport';

export default class Calculatorforflow extends LightningElement {
    @api inputNumber1="";
    @api inputNumber2="";
   @api outputResult="";

    clickHandler(event){
        let name =event.target.name;

        if(name==='Add'){
            this.outputResult=Number(this.inputNumber1)+Number(this.inputNumber2);
        }else if(name==='Sub'){
            this.outputResult=Number(this.inputNumber1)-Number(this.inputNumber2);
        }else if(name==='Mul'){
            this.outputResult=Number(this.inputNumber1)*Number(this.inputNumber2);
        }else if (name==='Div'){
            this.outputResult=Number(this.inputNumber1)/Number(this.inputNumber2);
       }
       const attributeChangeEvent = new FlowAttributeChangeEvent(
        'outputResult',
        this.outputResult
    );
    this.dispatchEvent(attributeChangeEvent);
    }
}