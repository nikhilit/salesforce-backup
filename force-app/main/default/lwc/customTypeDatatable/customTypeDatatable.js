/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 20-11-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   13-10-2025   Kartik Patkar, Appstrail   Initial Version
**/
import { api, LightningElement } from 'lwc';
import LightningDatatable from "lightning/datatable";
// import customNameTemplate from "./customName.html";
import htmlCellTemplate from './htmlCellTemplate.html';
import formulaCellTemplate from './formulaCellTemplate.html';
export default class CustomTypeDatatable extends LightningDatatable {

    // @api selectedRows; 

    static customTypes = {
        html: {
            template: htmlCellTemplate,
            standardCellLayout: true,
            typeAttributes: ['value']
        },
        formula:{
            template:formulaCellTemplate,
            standardCellLayout: true,
            typeAttributes: ['value']
        }
    };

}