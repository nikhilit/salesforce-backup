import { LightningElement } from 'lwc';

export default class MyFirstLwcProject extends LightningElement {
    firstName = '';
    lastName = '';
    fullName='';
    

    handlechange(event) {
        if(event.target.label==="Enter First Name"){
            this.firstName = event.target.value;
        }
        else{
            this.lastName = event.target.value;
        }  
    }
    handleClick(){
        
        this.fullName= this.firstName +' '+this.lastName;
        console.log(this.fullName);
    }
}