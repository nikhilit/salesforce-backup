import { LightningElement, api , track } from 'lwc';

export default class ObjectForFlow extends LightningElement {

    @track _contacts = [];

    @api
    set contacts(contacts=[]){
        this._contacts = contacts;
    }
    

    get contacts(){
        return this._contacts;
    }

    get items(){
        let contactEmailArray = this._contacts.map((curritem) => {
            return{
                    type: 'icon',
                    label: curritem.Email,
                    name: 'iconpill',
                    iconName: 'standard:contact',
                    alternativeText: 'Contact Email',

            };
        });
        return contactEmailArray;
    }

}