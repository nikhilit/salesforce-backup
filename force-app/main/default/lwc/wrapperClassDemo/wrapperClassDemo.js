import { LightningElement, track, wire } from 'lwc';
import fetchAccAndCons from '@salesforce/apex/WrapperClassController.fetchAccAndCons';


export default class WrapperClassDemo extends LightningElement {
    data;
    error;


    @wire(fetchAccAndCons)
    accs({error,data})
    {
        if(data){
            this.data=data;
        }
        else if(error){
            this.error=error;
        }
    }
}