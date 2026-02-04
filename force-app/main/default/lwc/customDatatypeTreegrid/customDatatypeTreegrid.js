/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 10-11-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   10-11-2025   Kartik Patkar, Appstrail   Initial Version
**/
import { LightningElement } from 'lwc';
import LightningTreeGrid from "lightning/treeGrid";
import htmlCellTemplate from './htmlCellTemplate.html';
import formulaCellTemplate from './formulaCellTemplate.html';
export default class CustomDatatypeTreegrid extends LightningTreeGrid {
    static customTypes = {
        html: {
            template: htmlCellTemplate,
            standardCellLayout: true,
            typeAttributes: ['value']
        },
        formula: {
            template: formulaCellTemplate,
            standardCellLayout: true,
            typeAttributes: ['value']
        }
    };
}