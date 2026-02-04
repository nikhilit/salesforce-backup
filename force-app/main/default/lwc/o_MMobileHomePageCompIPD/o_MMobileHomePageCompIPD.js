/**
 * @description       :
 * @author            : Neeraj dalal Appstrail
 * @group             :
 * @last modified on  : 19-05-2025
 * @last modified by  : Neeraj dalal, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   16-05-2025   Neeraj dalal, Appstrail   Initial Version
**/
import { LightningElement, track, wire, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
 
import FORM_FACTOR from '@salesforce/client/formFactor';
 
import getUserRec from '@salesforce/apex/O_MAutoHomePageComponentController.getUserName';
import getKPIs from '@salesforce/apex/O_MDashboardContr.getKPIs';
import getCountByMetadataMatch from '@salesforce/apex/O_MDashboardContr.getCountByMetadataMatch';
export default class O_MMobileHomePageCompIPD extends LightningElement {
    @track userName = '';
    @track currentDate = '';
    @track currentTime = '';
    @track greeting = '';
    @track openMainPage = true;
    @track showDashboard = true;
    @track secondPage = false;
    @track showComponent3 = false;
    error;
    @track selectedStatus = '';
    wiredKpiResult;
    @track showChild = false;
    @track callPrent = false;
    @track showSpinner = false;
    @track isCheckedIn = false;
    @track showDropdown = false;
    @track isDisabled = false;
    @track attendanceStatus = '';
    @track showSubmitButton = false;
    @track attendanceMarked = false;
 
        @track selectedType;
 
 
     showAppointmentScreen;
 
    connectedCallback() {
        this.init();
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
        this.getKPIData();
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
            console.log('kpisResult:'+JSON.stringify(this.kpisResult));
        })
        .catch(error => {
            console.log('error:'+JSON.stringify(error));
            this.showToast('Error', 'Something went wrong.', 'error')
        });
    }
 
    cardDetails(){
        this.platform = FORM_FACTOR === 'Large' ? 'desktop' : 'mobile';
        console.log('openMainPage', this.openMainPage);
        console.log('showDashboard: ', this.showDashboard);
 
        this.updateTime();
        this.intervalId = setInterval(() => {
            this.updateTime();
        }, 30000);
 
        this.autoRefreshTimer = setInterval(() => {
            this.refreshDashboardData();
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
        this.showDashboard = true;
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
 
    handleGetStarted() {
        this.showDashboard = true;
    }
 
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
        this.getKPIData();
        const { data, error } = result;
        if (data) {
            this.kpis = data;
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
    }
 
    onTotalClick() {
        //if (!this.isCheckedIn) return;
      this.selectedType = null;
      this.togglePage('total', null);
 
 
    }
 
    selectedType='All'
    onCardCLick(event){
        var action=event.currentTarget.dataset.card;
        this.selectedType='All'
        switch(action){
            case 'Unattempted':
                this.togglePage('unattempted',null);
                break;
            case 'Completed':
                this.togglePage('completed',null);
                break;
            case 'Incomplete':
                this.togglePage('incomplete',null);
                break;
           
            default:
                break;
        }
    }
 
    togglePage(status, appointmentType = null) {
        this.showSpinner = true;
        this.selectedType = appointmentType;
 
        this.showAppointmentScreen=true;
        this.selectedStatus = status;
        this.showChild = true;
        this.showDashboard = false;
        this.secondPage = true;
        this.openMainPage = false;
        setTimeout(() => {
            this.showSpinner = false;
        }, 1000);
    }
 
    handleChildEvent(event) {
        this.showAppointmentScreen=false;
        this.secondPage = event.detail.secondPage;
        this.showDashboard = event.detail.showDashboard;
         this.showChild = false;
        this.openMainPage = event.detail.openMainPage;
        this.callPrent = true;
        this.selectedType='All'
 
         
    }
 
}