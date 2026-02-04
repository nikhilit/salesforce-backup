import { LightningElement, api } from 'lwc';

export default class MiniLayoutHover extends LightningElement {
    @api accountName = 'Acme Corporation';
    @api industry = 'Technology';
    @api annualRevenue = '10M USD';
    
    showDetails = false;

    handleMouseOver() {
        this.showDetails = true;
    }

    handleMouseOut() {
        this.showDetails = false;
    }
}