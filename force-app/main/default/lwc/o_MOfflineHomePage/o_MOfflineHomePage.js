import { LightningElement, track, wire, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { gql, graphql } from 'lightning/uiGraphQLApi';
import { getRecord } from 'lightning/uiRecordApi';
import userId from '@salesforce/user/Id';
import NAME_FIELD from '@salesforce/schema/User.Name';
 
// GraphQL Queries for offline support
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
 
export default class O_MOfflineHomePage extends LightningElement {
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
 
    // Track GraphQL wire results for refresh
    wiredAppointmentsResult;
    wiredConfigsResult;
 
    // Getter for online status
    get isOnline() {
        return navigator.onLine;
    }
 
    // Getter for no data state
    get hasNoData() {
        return this.kpisResult.length === 0;
    }
 
    connectedCallback() {
        this.init();
        window.addEventListener('online', () => this.syncWhenOnline());
        window.addEventListener('offline', () => {
            this.showToast('Offline', 'You are now offline', 'warning');
            this.loadCachedData(); // Reload cached data when going offline
        });
       
        // Add event listener for child toast events
        this.template.addEventListener('showtoast', this.handleChildToast.bind(this));
    }
 
    disconnectedCallback() {
        clearInterval(this.intervalId);
        clearInterval(this.autoRefreshTimer);
        this.template.removeEventListener('showtoast', this.handleChildToast.bind(this));
    }
 
    async init() {
        this.cardDetails();
        // Load cached data immediately
        this.loadCachedData();
       
        // If online, refresh data and cache it
        if (this.isOnline) {
            await this.refreshAllData();
        }
    }
 
    // Load all cached data for offline support
    loadCachedData() {
        console.log('Loading cached data for offline mode...');
        this.loadCachedConfig();
        this.loadCachedUser();
        this.loadCachedAppointments();
        this.loadCachedKpi();
        this.loadCachedKPIs();
        this.cacheListViewData(); // Ensure list view data is cached
    }
 
    // Cache all relevant data
    cacheAllData() {
        try {
            localStorage.setItem('configCache', JSON.stringify(this.configList));
            localStorage.setItem('kpisResultCache', JSON.stringify(this.kpisResult));
            localStorage.setItem('userNameCache', this.userName);
            localStorage.setItem('serviceAppointmentsCache', JSON.stringify(this.serviceAppointments));
            localStorage.setItem('kpisCache', JSON.stringify(this.kpis));
            this.cacheListViewData(); // Cache list view data specifically
            console.log('All data cached successfully for offline use');
        } catch (error) {
            console.error('Error caching data:', error);
        }
    }
 
    // NEW METHOD: Cache list view data for offline access
    cacheListViewData() {
        if (this.serviceAppointments.length > 0) {
            const listViewData = {
                timestamp: new Date().toISOString(),
                serviceAppointments: this.serviceAppointments,
                kpisResult: this.kpisResult,
                kpis: this.kpis,
                lastSync: new Date().toLocaleString()
            };
            localStorage.setItem('listViewCache', JSON.stringify(listViewData));
            console.log('List view data cached for offline use. Total appointments:', this.serviceAppointments.length);
        }
    }
 
    // Handle toast events from child components
    handleChildToast(event) {
        const { title, message, variant } = event.detail;
        this.showToast(title, message, variant);
        event.stopPropagation();
    }
 
    // ----------------- GraphQL Wires for Offline Support -----------------
 
    // Get user name using UI API
    @wire(getRecord, { recordId: userId, fields: [NAME_FIELD] })
    userRecord({ error, data }) {
        if (data) {
            this.userName = data.fields.Name.value;
            localStorage.setItem('userNameCache', this.userName);
            this.setGreeting();
            this.cacheAllData(); // Cache after user data is loaded
        } else if (error) {
            console.error('Error loading user data:', error);
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
        this.wiredConfigsResult = data;
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
            // Cache config immediately
            localStorage.setItem('configCache', JSON.stringify(this.configList));
            this.generateKPIs();
            this.cacheAllData();
        } else if (error) {
            console.error('Error loading config:', error);
            this.loadCachedConfig();
        }
    }
 
    // Get service appointments with GraphQL
    get appointmentVariables() {
        return { userId };
    }
 
    @wire(graphql, { query: GET_SERVICE_APPOINTMENTS, variables: '$appointmentVariables' })
    wiredAppointments({ error, data }) {
        this.wiredAppointmentsResult = data;
        if (data) {
            this.processAppointmentsData(data);
        } else if (error) {
            console.error('GraphQL error:', error);
            this.loadCachedAppointments();
        }
    }
 
    // Process appointments data
    processAppointmentsData(graphqlData) {
        this.serviceAppointments = (graphqlData?.uiapi?.query?.AssignedResource?.edges || [])
            .map(edge => edge.node.ServiceAppointment)
            .filter(Boolean)
            .filter(sa => {
                const recordType = sa?.ParentRecord?.RecordType?.DeveloperName?.value;
                const timeOk = sa?.SchedStartTime?.value && sa?.SchedEndTime?.value;
               
                return (
                    recordType === this.developerNameFilter &&
                    timeOk
                );
            })
            .map(sa => ({
                Id: sa.Id,
                Status: sa.Status?.value,
                Appointment_Type__c: sa.Appointment_Type__c?.value,
                SchedStartTime: sa.SchedStartTime?.value,
                Schedule_Start_Date__c: sa.Schedule_Start_Date__c?.value,
                Schedule_End_Date__c: sa.Schedule_End_Date__c?.value,
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
       
        // Cache appointments immediately
        localStorage.setItem('serviceAppointmentsCache', JSON.stringify(this.serviceAppointments));
        this.generateKPIs();
        this.calculateKPIs();
        this.cacheAllData();
        this.cacheListViewData(); // Cache specifically for list views
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
 
            const styleString = meta.cardColor ? `background-color: ${meta.cardColor}` : '';
 
            return {
                label: meta.label,
                cardColor: meta.cardColor,
                iconUrl: meta.iconUrl,
                count: matchingSA.length,
                order: meta.order,
                styleString: styleString,
                // Store the filtered appointments for this KPI
                filteredAppointments: matchingSA
            };
        }).sort((a, b) => a.order - b.order);
 
        this.kpisResult = results;
        localStorage.setItem('kpisResultCache', JSON.stringify(results));
       
        console.log('Final KPI Results (ALL TIME):', JSON.stringify(results));
        this.cacheAllData();
        this.cacheListViewData(); // Cache specifically for list views
    }
 
    calculateKPIs() {
        const kpiTotals = this.serviceAppointments.reduce((acc, sa) => {
            acc.total++;
            const status = sa.Status ? sa.Status.toLowerCase() : '';
           
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
        try {
            const cache = localStorage.getItem('kpisResultCache');
            if (cache) {
                this.kpisResult = JSON.parse(cache);
                console.log('Loaded cached KPI results:', this.kpisResult.length);
            }
        } catch (error) {
            console.error('Error loading cached KPI:', error);
        }
    }
 
    loadCachedUser() {
        try {
            const cachedName = localStorage.getItem('userNameCache');
            if (cachedName) {
                this.userName = cachedName;
                this.setGreeting();
            }
        } catch (error) {
            console.error('Error loading cached user:', error);
        }
    }
 
    loadCachedAppointments() {
        try {
            const cache = localStorage.getItem('serviceAppointmentsCache');
            if (cache) {
                this.serviceAppointments = JSON.parse(cache);
                console.log('Loaded ALL cached appointments:', this.serviceAppointments.length);
                this.generateKPIs();
                this.calculateKPIs();
            }
        } catch (error) {
            console.error('Error loading cached appointments:', error);
        }
    }
 
    loadCachedConfig() {
        try {
            const cache = localStorage.getItem('configCache');
            if (cache) {
                this.configList = JSON.parse(cache);
                console.log('Loaded cached config:', this.configList.length);
                this.generateKPIs();
            }
        } catch (error) {
            console.error('Error loading cached config:', error);
        }
    }
 
    loadCachedKPIs() {
        try {
            const cache = localStorage.getItem('kpisCache');
            if (cache) {
                this.kpis = JSON.parse(cache);
                console.log('Loaded cached KPIs:', this.kpis);
            }
        } catch (error) {
            console.error('Error loading cached KPIs:', error);
        }
    }
 
    // ----------------- Online/Offline Management -----------------
    async refreshAllData() {
        if (!this.isOnline) {
            this.showToast('Offline', 'Cannot refresh while offline', 'warning');
            return;
        }
 
        this.showSpinner = true;
        console.log('Refreshing all data...');
       
        try {
            // Refresh GraphQL data
            if (this.wiredAppointmentsResult) {
                await refreshApex(this.wiredAppointmentsResult);
            }
            if (this.wiredConfigsResult) {
                await refreshApex(this.wiredConfigsResult);
            }
           
            this.showToast('Success', 'Data refreshed successfully', 'success');
        } catch (error) {
            console.error('Error refreshing data:', error);
            this.showToast('Error', 'Failed to refresh data', 'error');
        } finally {
            setTimeout(() => {
                this.showSpinner = false;
            }, 1000);
        }
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
            this.autoRefreshTimer = setInterval(() => {
                console.log('Auto-refreshing data...');
                this.refreshAllData();
            }, 300000); // Refresh every 5 minutes when online
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
 
    // Pass filtered data to child components
    getFilteredAppointmentsForStatus(status) {
        const kpi = this.kpisResult.find(k => k.label === status);
        return kpi ? kpi.filteredAppointments : [];
    }
 
    onTotalClick() {
        this.showWorkOrderListComponent('All');
    }
 
    onCardCLick(event) {
        const action = event.currentTarget.dataset.card;
        this.selectedType = 'All';
        console.log('Selected Card Name:', action);
       
        // Store the current status and timestamp for child components
        localStorage.setItem('currentSelectedStatus', action);
        localStorage.setItem('navigationTimestamp', new Date().toISOString());
       
        // Store the current KPI data before navigating
        const selectedKpi = this.kpisResult.find(kpi => kpi.label === action);
        if (selectedKpi) {
            localStorage.setItem('selectedKpiData', JSON.stringify(selectedKpi));
        }
       
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
                this.showWorkOrderListComponent(action);
                break;
        }
    }
 
    showCompleteWorkOrderListComponent(status) {
        console.log('showCompleteWorkOrderList', status);
        this.navigateToWorkOrderList(status, 'showCompleteWorkOrderList');
    }
 
    showWorkOrderListComponent(status) {
        console.log('showWorkOrderListComponent', status);
        this.navigateToWorkOrderList(status, 'showWorkOrderList');
    }
 
    showIncompleteWorkOrderListComponent(status) {
        console.log('showIncompleteWorkOrderListComponent', status);
        this.navigateToWorkOrderList(status, 'showIncompleteWorkOrderList');
    }
 
    showUnattemptedWorkOrderListComponent(status) {
        console.log('showUnattemptedWorkOrderListComponent', status);
        this.navigateToWorkOrderList(status, 'showUnattemptedWorkOrderList');
    }
 
    navigateToWorkOrderList(status, componentFlag) {
        this.showSpinner = true;
        this.selectedStatus = status;
       
        // Reset all component flags
        this.showCompleteWorkOrderList = false;
        this.showWorkOrderList = false;
        this.showIncompleteWorkOrderList = false;
        this.showUnattemptedWorkOrderList = false;
        this.showChild = false;
       
        // Set the specific component flag
        this[componentFlag] = true;
        this.showDashboard = false;
        this.secondPage = true;
        this.openMainPage = false;
       
        // Ensure list view data is cached before navigating
        this.cacheListViewData();
       
        setTimeout(() => {
            this.showSpinner = false;
        }, 500);
    }
 
    // Handle back from all child components
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
 
    // Handle child events
    handleChildEvent(event) {
        this.secondPage = event.detail.secondPage;
        this.showDashboard = event.detail.showDashboard;
        this.showChild = false;
        this.showWorkOrderList = false;
        this.showIncompleteWorkOrderList = false;
        this.openMainPage = event.detail.openMainPage;
        this.selectedType = 'All';
    }
}