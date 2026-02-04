import { LightningElement, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import FORM_FACTOR from '@salesforce/client/formFactor';

import getUserRec from '@salesforce/apex/autoHomePageComponentController.getUserName';
import getKPIs from '@salesforce/apex/RTDashboardController.getKPIs';
import getCountByMetadataMatch from '@salesforce/apex/RTDashboardController.getCountByMetadataMatch';

import BackgroundImageRT from '@salesforce/resourceUrl/BackgroundImageRT';
import MglLogo from '@salesforce/resourceUrl/MglLogo';

import getPaymentSummary from '@salesforce/apex/RTDashboardController.getPaymentSummary';
 
export default class AutoHomePageComponent extends LightningElement {
    @track userName = '';
    @track currentDate = '';
    @track currentTime = ''; 
    @track greeting = '';
    @track openMainPage = true;
    //@track showDashboard = true;
    @track secondPage = false;
    @track showComponent3 = false;
    error;
    @track selectedStatus = '';
    wiredKpiResult;
    @track showChild = false;
    //@track callPrent = false;
    @track showSpinner = false;
    @track isCheckedIn = false;
    @track showDropdown = false;
    @track isDisabled = false;
    @track attendanceStatus = '';
    @track showSubmitButton = false;
    @track attendanceMarked = false;
    @track Logo=MglLogo;
    @track bgImg=BackgroundImageRT;
    @track selectedType;
    @track paymentToCollect = 0;
    @track totalAmountReceived = 0;


    get backgroundStyle() {
        return ` height: 170px; background-image: url(${this.bgImg}); background-size: cover; background-position: center; background-repeat: no-repeat;`;
    }
 

    renderedCallback() {
        const div = this.template.querySelector('.backgroundImage');
        // if (div) {
        //     console.log('Computed background style:', div.style.backgroundImage);
        // }
    }

    connectedCallback() {
        this.loadPaymentSummary();
        this.init();
        //Call every 3 seconds
        // this.intervalId = setInterval(() => {
        //     this.getKPIData();
        // }, 3000); 
    }

    loadPaymentSummary() { 
        getPaymentSummary()
        .then(result => {
            this.paymentToCollect = result.paymentToCollect;
            this.totalAmountReceived = result.totalAmountReceived;
        })
        .catch(error => {
            console.error('Error fetching payment summary:', error);
        });
    }

    // renderedCallback() {
    //     if(this.recursion){
    //         this.init();
    //         this.recursion=false;
    //     }
    //     this.setCardColor();
    // }

    init() {
        this.cardDetails();
        //this.getKPIData();
    }

    setCardColor() {
        this.kpisResult.forEach(item=>{
            var elm=this.template.querySelector('[data-card="'+item.label+'"]');
            if(elm){
                elm.style='background-color:'+item.cardColor+';';
            }
        })    
    }

    @track kpisResult=[];
    getKPIData(){
        getCountByMetadataMatch()
        .then(result => {
            this.kpisResult = result;
            console.log('=========kpisResult=========>>>', JSON.stringify(this.kpisResult));
        })
        .catch(error => {
            console.log('error:'+JSON.stringify(error));
            this.showToast('Error', 'Something went wrong.', 'error')
        });
    }

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

    resetUI() {
        this.attendanceMarked = true;
        this.isCheckedIn = false;
        this.showDropdown = false;
        this.showSubmitButton = false;
        this.isDisabled = true;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    handleNavigateHome() {
        this.secondPage = false;
        //this.showDashboard = true;
        this.openMainPage = true;
    }

    updateTime() {
        const now = new Date();
        this.currentDate = now.toLocaleDateString(undefined, {
            weekday: 'long', year: 'numeric', month: 'long', day: 'numeric'
        });
        this.currentTime = now.toLocaleTimeString(undefined, {
            hour: '2-digit', minute: '2-digit'
        });
        this.setGreeting();
    }

    setGreeting() {
        const hour = new Date().getHours();
        const name = this.userName || 'User';
        if (hour < 12) {
            this.greeting = `Good Morning, ${ name }`;
        } else if (hour < 17) {
            this.greeting = `Good Afternoon, ${ name }`;
        } else {
            this.greeting = `Good Evening, ${ name }`;
        }
    }

    // handleGetStarted() {
    //     this.showDashboard = true;
    // }

    get disabledClass() {
        return this.isCheckedIn ? '' : 'disabled-dashboard';
    }

    handleShowComponent3(event) {
        if (event.detail) {
            this.openMainPage = event.detail.openMainPage;
        }
    }

    @wire(getUserRec)
    wiredUser({ error, data }) {
        if (data) {
            this.userName = data.userName;
            this.setGreeting();
        } else if (error) {
            console.error('Error fetching user:', error);
        }
    }

    @track kpis={};
    @wire(getKPIs)
    wiredKpis(result) {
        this.wiredKpiResult = result;
        const { data, error } = result;
        if (data) {
            this.kpis = data;
            this.getKPIData();
            console.log('=========wiredKpiResult=========>>>', JSON.stringify(this.wiredKpiResult));
        } else if (error) {
            this.error = error;
        }
    }

    refreshDashboardData() {
        refreshApex(this.wiredKpiResult);
    }

    recursion=false;
    disconnectedCallback() {
        clearInterval(this.autoRefreshTimer);
        this.recursion=true;
        clearInterval(this.intervalId);
    }

    onTotalClick() {
        this.selectedType = null;
        this.togglePage('total', null);
    }

    onFollowUpClick() {
        this.selectedType = 'Follow Up';
        this.togglePage(null, 'Follow Up');
    }

    onDirectClick() {
        this.selectedType = 'Direct';
        this.togglePage(null, this.selectedType);
    }

    onRandomClick() {
        this.selectedType = 'Random';
        this.togglePage(null, this.selectedType);
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