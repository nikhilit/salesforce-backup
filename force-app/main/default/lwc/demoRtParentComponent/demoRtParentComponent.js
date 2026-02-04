import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import FORM_FACTOR from '@salesforce/client/formFactor';
export default class DemoRtParentComponent extends LightningElement {
    @track openMainPage = true;
    //@track showDashboard = true;
    @track showChild = false;
   
 


    get getTotal(){
        return (this.kpis.total + this.kpis.followup);
    }

    cardDetails(){
        this.platform = FORM_FACTOR === 'Large' ? 'desktop' : 'mobile';
        console.log('openMainPage', this.openMainPage);
        //console.log('showDashboard: ', this.showDashboard);

        this.updateTime();
        this.intervalId = setInterval(() => {
            this.updateTime();
        }, 30000);

        this.autoRefreshTimer = setInterval(() => {
            this.refreshDashboardData();
            this.loadPaymentSummary();
        }, 2000);
    }


    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    handleNavigateHome() {
        this.secondPage = false;
        //this.showDashboard = true;
        this.openMainPage = true;
    }

    selectedType='All'
    onCardCLick(event){
        var action=event.currentTarget.dataset.card;
        this.selectedType='All'
        switch(action){
            case 'Unattempted':
                this.togglePage('unattempted', null);
                break;
            case 'Completed':
                this.togglePage('completed', null);
                break;
            case 'Incomplete':
                this.togglePage('incomplete', null);
                break;
            case 'Ad-hoc':
                this.selectedType='Ad-hoc';
                this.onTotalClick();
                break;
            default:
                break;
        }
    } 
    @track kpisResult = [
        {
            label: 'Unattempted',
            count: 10,
            iconUrl: 'utility:close',
            cardColor: 'white;'
        },
    ];
    togglePage(status, appointmentType = null) {

        console.log('togglePage called with status:', status, 'and appointmentType:', appointmentType);

        this.showSpinner = true;
        this.selectedStatus = status;
        this.selectedType = appointmentType;
        this.showChild = true;
        //this.showDashboard = false;
        this.secondPage = true;
        this.openMainPage = false;

        setTimeout(() => {
            this.showSpinner = false;
        }, 1000);
    }

    handleChildEvent(event) {

        //console.log('handleChildEvent received:', JSON.stringify(event.detail));

        this.secondPage = event.detail.secondPage;
        //this.showDashboard = event.detail.showDashboard;
        this.openMainPage = event.detail.openMainPage;
        this.showChild = false;
        this.selectedType='All'
    }
}