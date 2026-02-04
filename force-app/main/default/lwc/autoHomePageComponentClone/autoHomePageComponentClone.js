import { LightningElement, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import FORM_FACTOR from '@salesforce/client/formFactor';

// --- ONLINE APEX IMPORTS ---
import getUserRec from '@salesforce/apex/autoHomePageComponentController.getUserName';
import getKPIs from '@salesforce/apex/RTDashboardController.getKPIs';
import getCountByMetadataMatch from '@salesforce/apex/RTDashboardController.getCountByMetadataMatch';
import getPaymentSummary from '@salesforce/apex/RTDashboardController.getPaymentSummary';

import BackgroundImageRT from '@salesforce/resourceUrl/BackgroundImageRT';
import MglLogo from '@salesforce/resourceUrl/MglLogo';

// --- OFFLINE GRAPHQL IMPORTS ---
import { gql, graphql } from 'lightning/uiGraphQLApi';
import userId from '@salesforce/user/Id';
import { getRecord } from 'lightning/uiRecordApi';
import NAME_FIELD from '@salesforce/schema/User.Name';

// --- GRAPHQL: METADATA CONFIG ---
const GET_METADATA_CONFIG = gql`
  query getConfigs {
    uiapi {
      query {
        Metering_Dashboard_Config__mdt(
          where: { Active__c: { eq: true }, Department__c: { eq: "R&T" } }
          orderBy: { Order__c: { order: ASC } }
          first: 200
        ) {
          edges {
            node {
              Label__c { value }
              Field_Api_Name__c { value }
              Values__c { value }
              Card_Color__c { value }
              Icon_URL__c { value }
              Order__c { value }
            }
          }
        }
      }
    }
  }
`;

// --- GRAPHQL: APPOINTMENTS ---
const GET_OFFLINE_DATA = gql`
  query getDataOffline($userId: ID!) {
    uiapi {
      query {
        AssignedResource(
          where: { ServiceResource: { RelatedRecordId: { eq: $userId } } }
          first: 1000
        ) {
          edges {
            node {
              Id
              ServiceAppointment {
                Id
                Status { value }
                SchedStartTime { value }
                SchedEndTime { value }
                Schedule_Start_Date__c { value }
                Schedule_End_Date__c { value }
                Appointment_Type__c { value }
                Random_Visit_Date__c { value }
                Follow_Up_Visit_Date__c { value }
                DisplaySpecificRangeVisits__c { value }
                Due_Amount__c { value }
                
                ParentRecord {
                  ... on WorkOrder {
                    Id
                    RecordType { DeveloperName { value } }
                    Payment_Mode__c { value }
                    Status { value }
                    Due_Amount__c { value }
                    Amount_Received__c { value }
                    Follow_up_Date__c { value }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
`;

export default class AutoHomePageComponentClone extends LightningElement {
    @track userName = '';
    @track currentDate = '';
    @track currentTime = ''; 
    @track greeting = '';
    @track openMainPage = true;
    @track secondPage = false;
    @track showComponent3 = false;
    error;
    
    // KPI State
    @track kpis = { total: 0, unattempted: 0, completed: 0, incomplete: 0, followup: 0, random: 0, direct: 0 };
    @track kpisResult = [];
    @track paymentToCollect = 0;
    @track totalAmountReceived = 0;

    // UI State
    @track selectedStatus = '';
    @track showChild = false;
    @track showSpinner = false;
    @track isCheckedIn = false;
    @track Logo = MglLogo;
    @track bgImg = BackgroundImageRT;
    @track selectedType = 'All';

    // Connectivity
    @track isOnline = navigator.onLine;
    @track refreshKey = 0; 

    get backgroundStyle() {
        return `height: 170px; background-image: url(${this.bgImg}); background-size: cover; background-position: center; background-repeat: no-repeat;`;
    }
    
    get getTotal(){
        return (this.kpis.total + this.kpis.followup);
    }

    // =================================================================
    // LIFECYCLE
    // =================================================================

    renderedCallback() {
        this.setCardColor();
    }

    connectedCallback() {
        window.addEventListener('online', this.handleNetworkChange);
        window.addEventListener('offline', this.handleNetworkChange);
        this.updateTime();
        this.init();

        this.intervalId = setInterval(() => { this.updateTime(); }, 30000);
        this.autoRefreshTimer = setInterval(() => {
            if(this.isOnline) {
                this.refreshDashboardData();
                this.loadPaymentSummary();
            }
        }, 5000);
        
        // Initial Debug Toast
        if(!this.isOnline) {
             this.debugToast('Offline Mode', 'Component initialized in Offline Mode.');
        }
    }

    disconnectedCallback() {
        clearInterval(this.autoRefreshTimer);
        clearInterval(this.intervalId);
        window.removeEventListener('online', this.handleNetworkChange);
        window.removeEventListener('offline', this.handleNetworkChange);
    }

    handleNetworkChange = () => {
        this.isOnline = navigator.onLine;
        if(this.isOnline) {
            this.refreshDashboardData();
        } else {
            this.debugToast('Network Change', 'Switched to Offline. Attempting to load cache.');
            this.refreshKey++;
        }
    }

    init() {
        this.cardDetails();
        if(this.isOnline) {
            this.loadPaymentSummary();
            this.getKPIData();
        }
    }

    // =================================================================
    // DEBUG HELPER
    // =================================================================
    debugToast(title, message) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: 'info',
                mode: 'dismissable'
            })
        );
    }

    // =================================================================
    loadPaymentSummary() { 
        if(!this.isOnline) return;
        getPaymentSummary().then(result => {
            this.paymentToCollect = result.paymentToCollect;
            this.totalAmountReceived = result.totalAmountReceived;
        }).catch(error => console.error(error));
    }

    getKPIData(){
        if(!this.isOnline) return;
        getCountByMetadataMatch().then(result => {
            this.kpisResult = result;
        }).catch(error => console.error(error));
    }

    wiredKpiResult;
    @wire(getUserRec)
    wiredUser({ error, data }) {
        if (!this.isOnline) return;
        if (data) {
            this.userName = data.userName;
            this.setGreeting();
        }
    }

    @wire(getKPIs)
    wiredKpis(result) {
        if (!this.isOnline) return;
        this.wiredKpiResult = result;
        const { data, error } = result;
        if (data) {
            this.kpis = data;
            this.getKPIData(); 
        }
    }

    refreshDashboardData() {
        if(this.isOnline && this.wiredKpiResult) refreshApex(this.wiredKpiResult);
        else if(!this.isOnline) this.refreshKey++;
    }

    // =================================================================
    // OFFLINE LOGIC 
    // =================================================================

    @wire(getRecord, { recordId: userId, fields: [NAME_FIELD] })
    wiredUserOffline({ error, data }) {
        if (this.isOnline) return;
        if (data) {
            this.userName = data.fields.Name.value;
            this.setGreeting();
        } else if (error) {
            this.debugToast('User Error', JSON.stringify(error));
        }
    }

    @track offlineConfigList = [];

    get metaVars() {
    return { refreshKey: String(this.refreshKey) };
    }

    @wire(graphql, { query: GET_METADATA_CONFIG, variables: '$metaVars' })
    wiredMetaOffline({ errors, data }) {
        if (this.isOnline) return;
        
        if (data) {
            const edges = data.uiapi.query.Metering_Dashboard_Config__mdt?.edges || [];
            this.debugToast('Meta Loaded', `Found ${edges.length} config records.`);
            
            this.offlineConfigList = edges.map(edge => ({
                label: edge.node.Label__c.value,
                fieldApiName: edge.node.Field_Api_Name__c.value,
                values: (edge.node.Values__c.value || '').split(',').map(v => v.trim().toLowerCase()),
                cardColor: edge.node.Card_Color__c.value,
                iconUrl: edge.node.Icon_URL__c.value,
                order: edge.node.Order__c.value
            }));
            
            this.calculateOfflineKPIs();
        } else if (errors) {
            this.debugToast('Meta Error', 'Failed to load Metadata. Check console.');
            console.error('GraphQL Meta Error:', JSON.stringify(error));
        }
    }

    get dataVars() {
        return {
            userId,
            refreshKey: String(this.refreshKey)
        };
    }


    // 3. Appointments Data Offline
    @track rawOfflineAppointments = [];
    @wire(graphql, { query: GET_OFFLINE_DATA, variables: '$dataVars' })
    wiredDataOffline({ errors, data }) {
        if (this.isOnline) return;

        try {
            if (errors) {
                this.debugToast('Data Error', 'GraphQL returned errors. Check console.');
                console.error('GraphQL Data Errors:', JSON.stringify(errors));
                return;
            }

            if (!data) return;

            const edges = data?.uiapi?.query?.AssignedResource?.edges || [];
            this.debugToast('Raw Data', `Fetched ${edges.length} AssignedResource records.`);

            const toYmd = (val) => {
                if (!val) return null;
                if (typeof val === 'string' && val.length >= 10) {
                    return val.substring(0, 10);
                }
                const d = new Date(val);
                return isNaN(d.getTime()) ? null : d.toISOString().substring(0, 10);
            };

            const today = new Date().toISOString().substring(0, 10);

            const debug = {
                total: 0,
                noSA: 0,
                noParent: 0,
                rtMismatch: 0,
                missingDates: 0,
                outOfRange: 0,
                followUpExcluded: 0,
                displayFlagExcluded: 0,
                passed: 0
            };

            this.rawOfflineAppointments = edges
                .map(e => e?.node?.ServiceAppointment)
                .filter(sa => {
                    debug.total++;

                    if (!sa) {
                        debug.noSA++;
                        return false;
                    }

                    const parent = sa.ParentRecord;
                    if (!parent) {
                        debug.noParent++;
                        return false;
                    }

                    const rtDevName = parent?.RecordType?.DeveloperName?.value;

                    if (rtDevName && rtDevName !== 'MGL_R_T') {
                        debug.rtMismatch++;
                        return false;
                    }

                    // Date range check (use Schedule dates first, else SchedStart/SchedEnd)
                    const start = toYmd(sa.Schedule_Start_Date__c?.value) || toYmd(sa.SchedStartTime?.value);
                    const end   = toYmd(sa.Schedule_End_Date__c?.value)   || toYmd(sa.SchedEndTime?.value);

                    if (!start || !end) {
                        debug.missingDates++;
                        return false;
                    }

                    if (!(start <= today && end >= today)) {
                        debug.outOfRange++;
                        return false;
                    }

                    // Follow-up exclusion
                    if (sa.Follow_Up_Visit_Date__c?.value) {
                        debug.followUpExcluded++;
                        return false;
                    }

                    const display = sa.DisplaySpecificRangeVisits__c?.value;
                    if (display === false) {
                        debug.displayFlagExcluded++;
                        return false;
                    }

                    debug.passed++;
                    return true;
                });

            this.debugToast(
                'Filtering',
                `Total:${debug.total}, Passed:${debug.passed}, RTMismatch:${debug.rtMismatch}, MissingDates:${debug.missingDates}, OutOfRange:${debug.outOfRange}, FollowUp:${debug.followUpExcluded}, DisplayFalse:${debug.displayFlagExcluded}`
            );

            // Calculate KPIs if we have filtered appointments
            this.calculateOfflineKPIs();

        } catch (e) {
            //this.debugToast('Data Error', 'Exception in wiredDataOffline. Check console.');
            console.error('wiredDataOffline exception:', e);
        }
    }


    calculateOfflineKPIs() {
        if (this.isOnline) return;
        if (this.rawOfflineAppointments.length === 0) {
            if(this.offlineConfigList.length > 0) {
                 this.debugToast('Calc Skip', 'No valid appointments to calculate.');
            }
            // Ensure we at least show empty 0 cards if we have metadata
            if(this.offlineConfigList.length > 0 && this.kpisResult.length === 0){
                 this.kpisResult = this.offlineConfigList.map(c => ({
                    count: 0, label: c.label, iconUrl: c.iconUrl, cardColor: c.cardColor
                 }));
                 setTimeout(() => this.setCardColor(), 500);
            }
            return;
        }
        
        if (this.offlineConfigList.length === 0) {
            this.debugToast('Calc Wait', 'Waiting for Metadata Config...');
            return;
        }

        this.debugToast('Calculating', `Processing ${this.rawOfflineAppointments.length} appointments...`);

        let stats = { total: 0, unattempted: 0, completed: 0, incomplete: 0, followup: 0, random: 0, direct: 0 };
        let payCollect = 0;
        let payRec = 0;

        let metaMap = {}; 
        let metaCounts = {}; 
        this.offlineConfigList.forEach(c => {
            if (!metaMap[c.fieldApiName]) metaMap[c.fieldApiName] = {};
            c.values.forEach(v => {
                metaMap[c.fieldApiName][v] = c.label;
            });
            metaCounts[c.label] = { 
                count: 0, 
                label: c.label, 
                iconUrl: c.iconUrl, 
                cardColor: c.cardColor
            };
        });

        // Iterate
        this.rawOfflineAppointments.forEach(sa => {
            const parent = sa.ParentRecord || {};
            const status = sa.Status?.value;
            const apptType = sa.Appointment_Type__c?.value;
            const randomDate = sa.Random_Visit_Date__c?.value;
            const payMode = parent.Payment_Mode__c?.value;
            const woStatus = parent.Status?.value;

            // 1. Direct Payment
            if (woStatus === 'Completed' && payMode === 'Directly Paid by Customer') {
                stats.direct++;
            } else {
                if (randomDate) {
                    stats.random++;
                } else {
                    stats.total++;
                    if (apptType === 'Follow Up') stats.followup++;

                    if (status === 'Completed') stats.completed++;
                    else if (status === 'Cannot Complete') stats.incomplete++;
                    else if (['Scheduled','None','In Progress','Dispatched'].includes(status)) stats.unattempted++;
                }
            }

            // 2. Payment
            if (payMode !== 'Directly Paid by Customer') {
                const due = parseFloat(sa.Due_Amount__c?.value || parent.Due_Amount__c?.value || 0);
                const rec = parseFloat(parent.Amount_Received__c?.value || 0);
                payCollect += due;
                payRec += rec;
            }

            // 3. Metadata Cards
            const isDirect = (woStatus === 'Completed' && payMode === 'Directly Paid by Customer');
            const isFollowUp = (apptType === 'Follow Up');
            const isRandom = (randomDate != null || apptType === 'Random');

            if (!isDirect && !isFollowUp && !isRandom) {
                Object.keys(metaMap).forEach(fieldApi => {
                    let val = sa[fieldApi]?.value;
                    if (val) {
                        val = val.toString().trim().toLowerCase();
                        if (metaMap[fieldApi][val]) {
                            let label = metaMap[fieldApi][val];
                            if (metaCounts[label]) metaCounts[label].count++;
                        }
                    }
                });
            }
        });

        this.kpis = stats;
        this.paymentToCollect = payCollect;
        this.totalAmountReceived = payRec;
        this.kpisResult = this.offlineConfigList.map(c => metaCounts[c.label]);

        this.debugToast('Success', `Calculated. Total: ${stats.total}, Cards: ${this.kpisResult.length}`);
        setTimeout(() => this.setCardColor(), 500);
    }

    // =================================================================
    // =================================================================
    cardDetails() {
        this.platform = FORM_FACTOR === 'Large' ? 'desktop' : 'mobile';
        this.updateTime();
    }
    updateTime() {
        const now = new Date();
        this.currentDate = now.toLocaleDateString(undefined, { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' });
        this.currentTime = now.toLocaleTimeString(undefined, { hour: '2-digit', minute: '2-digit' });
        this.setGreeting();
    }
    setGreeting() {
        const hour = new Date().getHours();
        const name = this.userName || 'User';
        if (hour < 12) this.greeting = `Good Morning, ${ name }`;
        else if (hour < 17) this.greeting = `Good Afternoon, ${ name }`;
        else this.greeting = `Good Evening, ${ name }`;
    }
    setCardColor() {
        if(this.kpisResult && this.kpisResult.length > 0){
            this.kpisResult.forEach(item => {
                var elm = this.template.querySelector('[data-card="' + item.label + '"]');
                if (elm) elm.style = 'background-color:' + item.cardColor + ';';
            });
        }
    }
    handleRefresh() {
        this.showSpinner = true;
        if(this.isOnline) this.refreshDashboardData();
        else this.refreshKey++;
        setTimeout(() => { this.showSpinner = false; }, 1500);
    }
    onTotalClick() { this.togglePage('total', null); }
    onFollowUpClick() { this.togglePage(null, 'Follow Up'); }
    onDirectClick() { this.togglePage(null, 'Direct'); }
    onRandomClick() { this.togglePage(null, 'Random'); }
    onCardCLick(event) {
        var action = event.currentTarget.dataset.card;
        this.selectedType = 'All';
        switch (action) {
            case 'Unattempted': this.togglePage('unattempted', null); break;
            case 'Completed': this.togglePage('completed', null); break;
            case 'Incomplete': this.togglePage('incomplete', null); break;
            case 'Ad-hoc': this.selectedType = 'Ad-hoc'; this.onTotalClick(); break;
        }
    }
    togglePage(status, appointmentType = null) {
        this.showSpinner = true;
        this.selectedStatus = status;
        this.selectedType = appointmentType;
        this.showChild = true;
        this.secondPage = true;
        this.openMainPage = false;
        setTimeout(() => { this.showSpinner = false; }, 1000);
    }
    handleChildEvent(event) {
        this.secondPage = event.detail.secondPage;
        this.openMainPage = event.detail.openMainPage;
        this.showChild = false;
        this.selectedType = 'All';
        if(this.isOnline) this.refreshDashboardData();
        else this.refreshKey++;
    }
}