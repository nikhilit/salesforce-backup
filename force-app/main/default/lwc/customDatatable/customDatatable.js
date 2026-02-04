import { LightningElement } from 'lwc';
// import imageTemplate from './customImageCell.html';
import imageTemplate from './imageCell.html';
import LightningDatatable from 'lightning/datatable';
import childTemplate from './childCell.html';

export default class CustomDatatable extends LightningDatatable {
    static customTypes = {
        image: {
            template: imageTemplate,
            standardCellLayout: true,
            typeAttributes: ['value']
        },
        child: {
            template: childTemplate,
            standardCellLayout: true,
            typeAttributes: ['fieldLabel','value','apiName'] 
        }
    };
}