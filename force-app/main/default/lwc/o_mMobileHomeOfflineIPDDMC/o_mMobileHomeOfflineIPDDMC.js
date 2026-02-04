import { LightningElement, track, wire, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { gql, graphql } from 'lightning/uiGraphQLApi';
import { getRecord } from 'lightning/uiRecordApi';
import userId from '@salesforce/user/Id';
import NAME_FIELD from '@salesforce/schema/User.Name';

// GraphQL Queries for offline support - REMOVED DATE FILTERING
const GET_SERVICE_APPOINTMENTS = gql`
query getAssignedResources($userId: ID!) {
  uiapi {
    query {
      AssignedResource(
        where: { ServiceResource: { RelatedRecordId: { eq: $userId } } }
        first: 2000
      ) {
        edges {
          node {
            Id
            ServiceAppointment {
              Id
              Status { value }
              Appointment_Type__c { value }
              SchedStartTime { value }
              SchedEndTime { value }
              Schedule_Start_Date__c { value }
              Schedule_End_Date__c { value }
              ParentRecord {
                ... on WorkOrder {
                  Id
                  RecordType { DeveloperName { value } }
                }
              }
              Account {
                Id
                Name { value }
                Building_name__c { value }
                Street__c { value }
                Colony__c { value }
                Wing__c { value }
                Floor__c { value }
                Flat__c { value }
                Road_name__c { value }
                BP_Number__c { value }
                FirstName__c { value }
                LastName__c { value }
              }
            }
          }
        }
      }
    }
  }
}
`;

const GET_METADATA_CONFIG = gql`
query getConfigs($departmentType: Picklist!) {
  uiapi {
    query {
      Metering_Dashboard_Config__mdt(
        where: { 
          Active__c: { eq: true }, 
          Department__c: { eq: $departmentType }
        }, 
        first: 200
      ) {
        edges {
          node {
            Id
            Label__c { value }
            Field_Api_Name__c { value }
            Values__c { value }
            Order__c { value }
            Card_Color__c { value }
            Icon_URL__c { value }
            Department__c { value }
            Active__c { value }
          }
        }
      }
    }
  }
}
`;

const GET_SERVICE_RESOURCE = gql`
  query getServiceResource($userId: ID!) {
    uiapi {
      query {
        ServiceTerritoryMember(
          where: {
            ServiceResource: { RelatedRecordId: { eq: $userId }, IsActive: { eq: true } },
            ServiceTerritory: { IsActive: { eq: true } }
          }
          first: 1
        ) {
          edges {
            node {
              ServiceResource { Id Name { value } }
              ServiceTerritory { Id Name { value } }
            }
          }
        }
      }
    }
  }
`;
export default class O_mMobileHomeOfflineIPDDMC extends LightningElement {
    // ---- Reactive State ----
    @track userName = '';
    @track currentDate = '';
    @track currentTime = '';
    @track greeting = '';
    @track openMainPage = true;
    @track showDashboard = true;
    @track secondPage = false;
    @track showChild = false;
    @track showSpinner = false;
    @track selectedStatus = '';
    @track selectedType = 'All';
    @track kpisResult = [];
    @track kpis = { total: 0, completed: 0, incomplete: 0, unattempted: 0 };
    @track configList = [];
    @track serviceAppointments = [];
    @track serviceResourceId;
    @track showWorkOrderList = false;
    @track showIncompleteWorkOrderList = false;
    @track showUnattemptedWorkOrderList = false;
    @track showCompleteWorkOrderList = false;
    error;

    departmentType = 'O&M';
    developerNameFilter = 'MGL_O_M';

    intervalId;
    autoRefreshTimer;

    // Getter for online status
    get isOnline() {
        return navigator.onLine;
    }

    // Getter for no data state
    get hasNoData() {
        return this.kpisResult.length === 0;
    }

    // Add this method to your JavaScript class
renderedCallback() {
    // Ensure Total card has the correct color
    const totalCard = this.template.querySelector('.total-card');
    if (totalCard) {
        totalCard.style.backgroundColor = '#6EB1D6';
    }
    
    // The KPI cards will automatically get their colors from the styleString
    // which is set in the generateKPIs method from the metadata
}

    connectedCallback() {
        this.init();
        window.addEventListener('online', () => this.syncWhenOnline());
        window.addEventListener('offline', () => this.showToast('Offline','You are now offline','warning'));
    }

    disconnectedCallback() {
        clearInterval(this.intervalId);
        clearInterval(this.autoRefreshTimer);
    }

    init() {
        this.cardDetails();
        // Load cached data immediately, then try to refresh if online
        this.loadCachedData();
        if (this.isOnline) {
            this.refreshAllData();
        }
    }

    // Load all cached data for offline support
    loadCachedData() {
        this.loadCachedKpi();
        this.loadCachedUser();
        this.loadCachedAppointments();
    }

    // Cache all relevant data
    cacheAllData() {
        localStorage.setItem('kpisResultCache', JSON.stringify(this.kpisResult));
        localStorage.setItem('userNameCache', this.userName);
        localStorage.setItem('serviceAppointmentsCache', JSON.stringify(this.serviceAppointments));
        localStorage.setItem('kpisCache', JSON.stringify(this.kpis));
    }

    // ----------------- GraphQL Wires for Offline Support -----------------

    // Get user name using UI API
    @wire(getRecord, { recordId: userId, fields: [NAME_FIELD] })
    userRecord({ error, data }) {
        if (data) {
            this.userName = data.fields.Name.value;
            localStorage.setItem('userNameCache', this.userName);
            this.setGreeting();
        } else if (error) {
            this.loadCachedUser();
        }
    }

    // Get service resource
    get serviceResourceVariables() {
        return { userId };
    }

    @wire(graphql, { query: GET_SERVICE_RESOURCE, variables: '$serviceResourceVariables' })
    wiredServiceResource({ error, data }) {
        if (data) {
            const stmEdge = data.uiapi.query.ServiceTerritoryMember?.edges?.[0];
            if (stmEdge) {
                this.serviceResourceId = stmEdge.node.ServiceResource.Id;
            }
        }
    }

    // Get metadata config
    get configVariables() {
        return { departmentType: this.departmentType };
    }

    @wire(graphql, { query: GET_METADATA_CONFIG, variables: '$configVariables' })
    wiredConfigs({ error, data }) {
        if (data) {
            this.configList = data.uiapi.query.Metering_Dashboard_Config__mdt.edges.map(edge => {
                return {
                    Id: edge.node.Id,
                    label: edge.node.Label__c.value,
                    fieldApiName: edge.node.Field_Api_Name__c.value,
                    values: (edge.node.Values__c.value || '') ? edge.node.Values__c.value.split(',').map(v => v.trim()) : [],
                    order: edge.node.Order__c.value,
                    cardColor: edge.node.Card_Color__c.value,
                    iconUrl: edge.node.Icon_URL__c.value,
                    department: edge.node.Department__c.value,
                    active: edge.node.Active__c.value
                };
            });
            this.generateKPIs();
        } else if (error) {
            this.loadCachedConfig();
        }
    }

    // Get service appointments with GraphQL - REMOVED DATE FILTERING
    get appointmentVariables() {
        return { userId };
    }

    @wire(graphql, { query: GET_SERVICE_APPOINTMENTS, variables: '$appointmentVariables' })
    wiredAppointments({ error, data }) {
        if (data) {
            // REMOVED DATE FILTERING - Get all appointments regardless of date
            this.serviceAppointments = (data?.uiapi?.query?.AssignedResource?.edges || [])
                .map(edge => edge.node.ServiceAppointment)
                .filter(Boolean)
                .filter(sa => {
                    // Only filter by record type, not by date
                    const recordType = sa?.ParentRecord?.RecordType?.DeveloperName?.value;
                    const timeOk = sa?.SchedStartTime?.value && sa?.SchedEndTime?.value;
                    
                    return (
                        recordType === this.developerNameFilter &&
                        timeOk
                        // REMOVED: start <= today && end >= today
                    );
                })
                .map(sa => ({
                    Id: sa.Id,
                    Status: sa.Status?.value,
                    Appointment_Type__c: sa.Appointment_Type__c?.value,
                    SchedStartTime: sa.SchedStartTime?.value,
                    Schedule_Start_Date__c: sa.Schedule_Start_Date__c?.value, // Keep for reference
                    Schedule_End_Date__c: sa.Schedule_End_Date__c?.value, // Keep for reference
                    Account: {
                        Id: sa.Account?.Id,
                        Name: sa.Account?.Name?.value,
                        Building_name__c: sa.Account?.Building_name__c?.value,
                        Street__c: sa.Account?.Street__c?.value,
                        Colony__c: sa.Account?.Colony__c?.value,
                        Wing__c: sa.Account?.Wing__c?.value,
                        Floor__c: sa.Account?.Floor__c?.value,
                        Flat__c: sa.Account?.Flat__c?.value,
                        Road_name__c: sa.Account?.Road_name__c?.value,
                        BP_Number__c: sa.Account?.BP_Number__c?.value,
                        FirstName__c: sa.Account?.FirstName__c?.value,
                        LastName__c: sa.Account?.LastName__c?.value
                    }
                }));

            console.log('Fetched ALL Service Appointments:', this.serviceAppointments.length);
            this.debugServiceAppointments();
            
            localStorage.setItem('serviceAppointmentsCache', JSON.stringify(this.serviceAppointments));
            this.generateKPIs();
            this.calculateKPIs();
        } else if (error) {
            console.error('GraphQL error:', error);
            this.loadCachedAppointments();
        }
    }

    // ----------------- Client-side KPI Generation -----------------
    generateKPIs() {
        if (!this.configList.length || !this.serviceAppointments.length) {
            this.kpisResult = [];
            return;
        }

        console.log('Generating KPIs with config:', this.configList.length, 'and ALL appointments:', this.serviceAppointments.length);

        const results = this.configList.map(meta => {
            const fieldName = meta.fieldApiName;
            const values = meta.values.map(v => String(v).toLowerCase());
            
            let matchingSA = [];
            
            // Special handling for Status field to match Apex logic exactly
            if (fieldName === 'Status') {
                matchingSA = this.serviceAppointments.filter(sa => {
                    const status = sa.Status ? sa.Status.toLowerCase() : '';
                    
                    // Match the exact Apex controller status mapping
                    if (meta.label === 'Completed' && status === 'completed') {
                        return true;
                    } else if (meta.label === 'Incomplete' && 
                              (status === 'cannot complete' || status === 'in progress')) {
                        return true;
                    } else if (meta.label === 'Unattempted' && 
                              (status === 'scheduled' || status === 'none' || status === 'dispatched')) {
                        return true;
                    }
                    return false;
                });
            } else {
                // For other fields, use the original logic
                matchingSA = this.serviceAppointments.filter(sa => {
                    const value = sa[fieldName];
                    if (!value) return false;
                    return values.includes(String(value).toLowerCase());
                });
            }

            console.log(`KPI ${meta.label}: ${matchingSA.length} matches`);

            // Pre-calculate the style string here
            const styleString = meta.cardColor ? `background-color: ${meta.cardColor}` : '';

            return {
                label: meta.label,
                cardColor: meta.cardColor,
                iconUrl: meta.iconUrl,
                count: matchingSA.length,
                order: meta.order,
                styleString: styleString
            };
        }).sort((a, b) => a.order - b.order);

        this.kpisResult = results;
        localStorage.setItem('kpisResultCache', JSON.stringify(results));
        
        console.log('Final KPI Results (ALL TIME):', JSON.stringify(results));
    }

    calculateKPIs() {
        const kpiTotals = this.serviceAppointments.reduce((acc, sa) => {
            acc.total++;
            const status = sa.Status ? sa.Status.toLowerCase() : '';
            
            // Match the exact Apex controller logic
            if (status === 'completed') {
                acc.completed++;
            } else if (status === 'cannot complete' || status === 'in progress') {
                acc.incomplete++;
            } else if (status === 'scheduled' || status === 'none' || status === 'dispatched') {
                acc.unattempted++;
            }
            return acc;
        }, { total: 0, completed: 0, incomplete: 0, unattempted: 0 });

        this.kpis = kpiTotals;
        localStorage.setItem('kpisCache', JSON.stringify(kpiTotals));
        
        console.log('Calculated ALL TIME KPIs:', JSON.stringify(this.kpis));
    }

    // Debug method to check service appointment data
    debugServiceAppointments() {
        const statusCount = {};
        this.serviceAppointments.forEach(sa => {
            const status = sa.Status || 'Unknown';
            statusCount[status] = (statusCount[status] || 0) + 1;
        });
        console.log('ALL Service Appointment Status Count:', statusCount);
        console.log('Total Service Appointments (ALL TIME):', this.serviceAppointments.length);
    }

    // ----------------- Cache Management -----------------
    loadCachedKpi() {
        const cache = localStorage.getItem('kpisResultCache');
        if (cache) {
            this.kpisResult = JSON.parse(cache);
            console.log('Loaded cached KPI results:', this.kpisResult);
        }
    }

    loadCachedUser() {
        const cachedName = localStorage.getItem('userNameCache');
        if (cachedName) {
            this.userName = cachedName;
            this.setGreeting();
        }
    }

    loadCachedAppointments() {
        const cache = localStorage.getItem('serviceAppointmentsCache');
        if (cache) {
            this.serviceAppointments = JSON.parse(cache);
            console.log('Loaded ALL cached appointments:', this.serviceAppointments.length);
            this.generateKPIs();
            this.calculateKPIs();
        }
    }

    loadCachedConfig() {
        const cache = localStorage.getItem('configCache');
        if (cache) {
            this.configList = JSON.parse(cache);
        }
    }

    loadCachedKPIs() {
        const cache = localStorage.getItem('kpisCache');
        if (cache) {
            this.kpis = JSON.parse(cache);
            console.log('Loaded cached KPIs:', this.kpis);
        }
    }

    // ----------------- Online/Offline Management -----------------
    refreshAllData() {
        // This will trigger all GraphQL wires to refresh
        // The cache will be updated automatically in the wire handlers
        this.showSpinner = true;
        setTimeout(() => {
            this.showSpinner = false;
        }, 1000);
    }

    syncWhenOnline() {
        this.showToast('Online', 'You are back online. Syncing data...', 'success');
        this.refreshAllData();
    }

    // ----------------- UI Methods -----------------
    cardDetails() {
        this.updateTime();
        this.intervalId = setInterval(() => this.updateTime(), 30000);

        if (this.isOnline) {
            this.autoRefreshTimer = setInterval(() => this.refreshAllData(), 30000);
        }
    }

    updateTime() {
        const now = new Date();
        this.currentDate = now.toLocaleDateString(undefined,
            { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' });
        this.currentTime = now.toLocaleTimeString(undefined,
            { hour: '2-digit', minute: '2-digit' });
        this.setGreeting();
    }

    setGreeting() {
        const hour = new Date().getHours();
        const name = this.userName || 'User';
        if (hour < 12) this.greeting = `Good Morning, ${name}`;
        else if (hour < 17) this.greeting = `Good Afternoon, ${name}`;
        else this.greeting = `Good Evening, ${name}`;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    setCardColor() {
        if (Array.isArray(this.kpisResult)) {
            this.kpisResult.forEach(item => {
                const elm = this.template.querySelector(`[data-card="${item.label}"]`);
                if (elm) elm.style = 'background-color:' + item.cardColor + ';';
            });
        }
    }

    onTotalClick() {
        this.showWorkOrderListComponent('Completed');
    }

    onCardCLick(event) {
        const action = event.currentTarget.dataset.card;
        this.selectedType = 'All';
        console.log ('Selected Card Name:',action);
        
        switch (action) {
            case 'Unattempted': 
                this.showUnattemptedWorkOrderListComponent('Unattempted');
                break;
            case 'Completed': 
                this.showCompleteWorkOrderListComponent('Completed');
                break;
            case 'Incomplete': 
                this.showIncompleteWorkOrderListComponent('Incomplete');
                break;
            default: 
                break;
        }
    }

     showCompleteWorkOrderListComponent(status) {
        console.log('showCompleteWorkOrderList',status);
        this.showSpinner = true;
        this.selectedStatus = status;
        this.showCompleteWorkOrderList = true;
        this.showWorkOrderList = false;
        this.showIncompleteWorkOrderList = false;
        this.showUnattemptedWorkOrderList = false;
        this.showChild = false;
        this.showDashboard = false;
        this.secondPage = true;
        this.openMainPage = false;
        
        setTimeout(() => {
            this.showSpinner = false;
        }, 1000);
    }

    showWorkOrderListComponent(status) {
        console.log('showWorkOrderListComponent',status);
        this.showSpinner = true;
        this.selectedStatus = status;
        this.showWorkOrderList = true;
        this.showCompleteWorkOrderList = false;
        this.showIncompleteWorkOrderList = false;
        this.showUnattemptedWorkOrderList = false;
        this.showChild = false;
        this.showDashboard = false;
        this.secondPage = true;
        this.openMainPage = false;
        
        setTimeout(() => {
            this.showSpinner = false;
        }, 1000);
    }

    showIncompleteWorkOrderListComponent(status) {
        console.log('showIncompleteWorkOrderListComponent',status);
        this.showSpinner = true;
        this.selectedStatus = status;
        this.showIncompleteWorkOrderList = true;
        this.showCompleteWorkOrderList = false;
        this.showWorkOrderList = false;
        this.showUnattemptedWorkOrderList = false;
        this.showChild = false;
        this.showDashboard = false;
        this.secondPage = true;
        this.openMainPage = false;
        
        setTimeout(() => {
            this.showSpinner = false;
        }, 1000);
    }

    showUnattemptedWorkOrderListComponent(status) {
        console.log('showUnattemptedWorkOrderListComponent',status);
        this.showSpinner = true;
        this.selectedStatus = status;
        this.showUnattemptedWorkOrderList = true;
        this.showCompleteWorkOrderList = false;
        this.showWorkOrderList = false;
        this.showIncompleteWorkOrderList = false;
        this.showChild = false;
        this.showDashboard = false;
        this.secondPage = true;
        this.openMainPage = false;
        
        setTimeout(() => {
            this.showSpinner = false;
        }, 1000);
    }

    togglePage(status, appointmentType = null) {
        this.showSpinner = true;
        this.selectedType = appointmentType;
        this.selectedStatus = status;
        this.showChild = true;
        this.showWorkOrderList = false;
        this.showIncompleteWorkOrderList = false;
        this.showDashboard = false;
        this.secondPage = true;
        this.openMainPage = false;
        setTimeout(() => { this.showSpinner = false; }, 1000);
    }

    handleChildEvent(event) {
        this.secondPage = event.detail.secondPage;
        this.showDashboard = event.detail.showDashboard;
        this.showChild = false;
        this.showWorkOrderList = false;
        this.showIncompleteWorkOrderList = false;
        this.openMainPage = event.detail.openMainPage;
        this.selectedType = 'All';
    }
    
     handleCompleteWorkOrderListBack() {
        this.showCompleteWorkOrderList = false;
        this.showDashboard = true;
        this.openMainPage = true;
        this.secondPage = false;
    }


    handleWorkOrderListBack() {
        this.showWorkOrderList = false;
        this.showDashboard = true;
        this.openMainPage = true;
        this.secondPage = false;
    }


    handleIncompleteWorkOrderListBack() {
        this.showIncompleteWorkOrderList = false;
        this.showDashboard = true;
        this.openMainPage = true;
        this.secondPage = false;
    }

    handleUnattemptedWorkOrderListBack() {
        this.showUnattemptedWorkOrderList = false;
        this.showDashboard = true;
        this.openMainPage = true;
        this.secondPage = false;
    }

}