import { LightningElement, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import FORM_FACTOR from '@salesforce/client/formFactor';

import getUserRec from '@salesforce/apex/O_MAutoHomePageComponentController.getUserName';
import getKPIs from '@salesforce/apex/O_MWorkOrderBPDashboardContr.getKPIs';
import getCountByMetadataMatch from '@salesforce/apex/O_MWorkOrderBPDashboardContr.getCountByMetadataMatch';

import BackgroundImageRT from '@salesforce/resourceUrl/BackgroundImageRT';
import MglLogo from '@salesforce/resourceUrl/MglLogo';

export default class O_MWorkOrderBPDashboard extends LightningElement {
 
    @track userName = '';
    @track currentDate = '';
    @track currentTime = '';
    @track greeting = '';
    @track Logo=MglLogo;
    @track bgImg=BackgroundImageRT;
    error;
    @track selectedStatus = '';
    wiredKpiResult;
    @track selectedType;
    @track kpis={};
    @track kpisResult=[];
    selectedType='All'

    @track openMainPage = true;
    @track secondPage = false;
    @track showChild = false;
    @track showSpinner = false;
    recursion=false;

    renderedCallback() {
        const div = this.template.querySelector('.backgroundImage');
        if (div) {
            console.log('Computed background style:', div.style.backgroundImage);
        }
    }

    connectedCallback() {
        this.init();
        // Call every 3 seconds
        // this.intervalId = setInterval(() => {
        //     this.getKPIData();
        // }, 3000);
    }

    renderedCallback() {
        if(this.recursion){
            this.init();
            this.recursion=false;
        }
        this.setCardColor();
    }

    init() {
        this.cardDetails();
        //this.getKPIData();
    }

    getKPIData(){
        getCountByMetadataMatch()
        .then(result => {
            this.kpisResult = result;
        })
        .catch(error => {
            this.showToast('Error', 'Something went wrong.', 'error')
        });
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

    @wire(getKPIs)
    wiredKpis(result) {

        this.wiredKpiResult = result;
        const { data, error } = result;
        if (data) {
            this.kpis = data;
            this.getKPIData();
        } else if (error) {
            this.error = error;
        }
    } 

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
        this.selectedStatus = status;
        this.selectedType = appointmentType;

        this.showChild = true;
        this.secondPage = true;
        this.openMainPage = false;
        this.showSpinner = true;

        setTimeout(() => {
            this.showSpinner = false;
        }, 1000);
    }

    handleChildEvent(event) {
        this.secondPage = event.detail.secondPage;
        this.openMainPage = event.detail.openMainPage;
        this.showChild = false;
        this.selectedType='All'
    }





    get backgroundStyle() {
        return ` height: 170px; background-image: url(${this.bgImg}); background-size: cover; background-position: center; background-repeat: no-repeat;`;
    }

    setCardColor() {
        this.kpisResult.forEach(item=>{
            var elm=this.template.querySelector('[data-card="'+item.label+'"]');
            if(elm){
                elm.style='background-color:'+item.cardColor+';';
            }
        })    
    }

    cardDetails(){
        this.platform = FORM_FACTOR === 'Large' ? 'desktop' : 'mobile';
    
        this.updateTime();
        this.intervalId = setInterval(() => {
            this.updateTime();
        }, 30000);

        this.autoRefreshTimer = setInterval(() => {
            this.refreshDashboardData();
        }, 2000);
    }

    refreshDashboardData() {
        refreshApex(this.wiredKpiResult);
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
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
}