import { LightningElement,wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getDealerDetails from '@salesforce/apex/CNG_ProfileCardController.currentstationDetails';

export default class Cng_dashboardStats extends LightningElement {

    recordId;
    stationName;
    showCart = false;

    toggleCart() {
        this.showCart = !this.showCart;
    }

    closeCart() {
        this.showCart = false;
    }

    get cartSidebarClass() {
        return this.showCart ? 'cart-sidebar open' : 'cart-sidebar';
    }

    // ✅ EXPERIENCE CLOUD RECORD ID
    @wire(CurrentPageReference)
    getPageRef(pageRef) {
        if (pageRef?.attributes?.recordId) {
            this.recordId = pageRef.attributes.recordId;
            console.log('✅ Parent recordId:', this.recordId);
        }
    }

    connectedCallback(){
        getDealerDetails({stationId:this.recordId})
        .then(result => {
            this.stationName = result;})
        }
}