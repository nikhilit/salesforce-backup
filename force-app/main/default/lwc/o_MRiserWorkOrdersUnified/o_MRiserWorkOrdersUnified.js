import { LightningElement, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { gql, graphql } from 'lightning/uiGraphQLApi';
import { getRecord } from 'lightning/uiRecordApi';
import userId from '@salesforce/user/Id';
import NAME_FIELD from '@salesforce/schema/User.Name';
import { NavigationMixin } from 'lightning/navigation';

// List view API names
const LIST_VIEWS = {
    All: 'O_MAllWorkOrder',
    Completed: 'O_MCompleteWorkOrder',
    Incomplete: 'O_MIncomplete_Work_Order',
    Unattempted: 'O_MUnattempted_Work_Order'
};

// GraphQL Queries
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
        where: { Active__c: { eq: true }, Department__c: { eq: $departmentType } },
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

const GET_WORKORDERS_FOR_USER = gql`
query getWorkOrdersForUser($userId: ID!) {
  uiapi {
    query {
      WorkOrder(
        where: { OwnerId: { eq: $userId } },
        orderBy: { CreatedDate: { order: DESC } },
        first: 1000
      ) {
        edges {
          node {
            Id
            WorkOrderNumber { value }
            Connection_Number__c { value }
            Building_Name__c { value }
            Address_1_ConnectionAddress__c { value }
            Appointment_Status__c { value }
          }
        }
      }
    }
  }
}
`;

const CACHE_KEYS = {
    listView: 'oMRiser_listViewCache',
    configs: 'oMRiser_configCache',
    kpisResult: 'oMRiser_kpisResultCache',
    serviceAppointments: 'oMRiser_serviceAppointmentsCache',
    userName: 'oMRiser_userNameCache'
};

export default class OMRiserWorkOrdersUnified extends NavigationMixin(LightningElement) {
    @track userName = '';
    @track currentDate = '';
    @track currentTime = '';
    @track greeting = '';
    @track openMainPage = true;
    @track showDashboard = true;
    @track secondPage = false;
    @track showSpinner = false;

    @track kpisResult = [];
    @track kpis = { total: 0, completed: 0, incomplete: 0, unattempted: 0 };
    @track configList = [];
    @track serviceAppointments = [];

    @track workOrders = [];
    @track isLoading = true;
    @track showOfflineListView = false;
    @track visibleListFilter = 'All';
    @track isNavigating = false;

    departmentType = 'O&M';
    developerNameFilter = 'MGL_O_M';

    wiredAppointmentsResult;
    wiredConfigsResult;
    wiredWorkOrdersResult;

    columns = [
        { label: 'Work Order Number', fieldName: 'workOrderNumber', type: 'text', initialWidth: 150 },
        { label: 'Connection', fieldName: 'connectionName', type: 'text', initialWidth: 180 },
        { label: 'Building Name', fieldName: 'buildingName', type: 'text', initialWidth: 200 },
        { label: 'Address', fieldName: 'address', type: 'text', wrapText: true, initialWidth: 400 }
    ];

    get isOnline() { return navigator.onLine; }
    get hasNoData() { return this.kpisResult.length === 0; }

    get filteredWorkOrders() {
        if (!this.workOrders?.length) return [];
        const filter = this.visibleListFilter.toLowerCase();
        return this.workOrders.filter(w => {
            const status = (w.appointmentStatus || '').toLowerCase();
            if (filter === 'all') return true;
            if (filter === 'completed') return status === 'completed';
            if (filter === 'incomplete') return status === 'in progress' || status === 'cannot complete' || status === 'cannotcomplete';
            if (filter === 'unattempted') return status === 'scheduled' || status === 'none' || status === 'dispatched';
            return true;
        });
    }

    get serviceVariables() { return { userId }; }
    get configVariables() { return { departmentType: this.departmentType }; }
    get workOrderVariables() { return { userId }; }

    @wire(getRecord, { recordId: userId, fields: [NAME_FIELD] })
    userRecord({ error, data }) {
        if (data) {
            this.userName = data.fields.Name.value;
            localStorage.setItem(CACHE_KEYS.userName, this.userName);
            this.setGreeting();
            this.cacheAllData();
        } else if (error) {
            this.loadCachedUser();
        }
    }

    @wire(graphql, { query: GET_SERVICE_APPOINTMENTS, variables: '$serviceVariables' })
    wiredServiceAppointments(result) {
        this.wiredAppointmentsResult = result;
        const { data, error } = result;
        if (data) this.processAppointmentsData(data);
        else if (error) this.loadCachedAppointments();
    }

    @wire(graphql, { query: GET_METADATA_CONFIG, variables: '$configVariables' })
    wiredConfigs(result) {
        this.wiredConfigsResult = result;
        const { data, error } = result;
        if (data) {
            this.configList = data.uiapi.query.Metering_Dashboard_Config__mdt.edges.map(e => ({
                Id: e.node.Id,
                label: e.node.Label__c.value,
                fieldApiName: e.node.Field_Api_Name__c.value,
                values: (e.node.Values__c.value || '').split(',').map(v => v.trim()),
                order: e.node.Order__c.value,
                cardColor: e.node.Card_Color__c.value,
                iconUrl: e.node.Icon_URL__c.value,
                department: e.node.Department__c.value,
                active: e.node.Active__c.value
            }));
            localStorage.setItem(CACHE_KEYS.configs, JSON.stringify(this.configList));
            this.generateKPIs();
            this.cacheAllData();
        } else if (error) this.loadCachedConfig();
    }

   @wire(graphql, { query: GET_WORKORDERS_FOR_USER, variables: '$workOrderVariables' })
wiredWorkOrders(result) {
    this.wiredWorkOrdersResult = result;
    const { data, error } = result;

    if (data) {
        const edges = data?.uiapi?.query?.WorkOrder?.edges || [];
        this.workOrders = edges.map(e => {
            let status = e.node.Appointment_Status__c?.value || '';
            // Map 'Dispatched' status to 'Unattempted'
            if (status.toLowerCase() === 'dispatched') {
                status = 'Unattempted';
            }
            return {
                id: e.node.Id,
                workOrderNumber: e.node.WorkOrderNumber?.value || '',
                connectionName: e.node.Connection_Number__c?.value || '',
                buildingName: e.node.Building_Name__c?.value || '',
                address: e.node.Address_1_ConnectionAddress__c?.value || '',
                appointmentStatus: status
            };
        });

        localStorage.setItem(CACHE_KEYS.listView, JSON.stringify({
            timestamp: new Date().toISOString(),
            workOrders: this.workOrders
        }));
        this.isLoading = false;
    } else if (error) {
        this.isLoading = false;
        this.loadCachedListView();
    }
}


    connectedCallback() {
        this.init();
        window.addEventListener('online', this.handleOnline.bind(this));
        window.addEventListener('offline', this.handleOnline.bind(this));
        window.addEventListener('popstate', this.handleBrowserBack);
        document.addEventListener('visibilitychange', this.handleMobileBack);
        window.addEventListener('pagehide', this.handleMobileBack);
        try { window.history.pushState({ step: 'listView' }, ''); } catch(e){}
    }

    disconnectedCallback() {
        window.removeEventListener('online', this.handleOnline.bind(this));
        window.removeEventListener('offline', this.handleOnline.bind(this));
        window.removeEventListener('popstate', this.handleBrowserBack);
        document.removeEventListener('visibilitychange', this.handleMobileBack);
        window.removeEventListener('pagehide', this.handleMobileBack);
        clearInterval(this.intervalId);
        clearInterval(this.autoRefreshTimer);
    }

    async init() {
        this.cardDetails();
        this.loadCachedData();
        if (this.isOnline) await this.refreshAllData();
        else this.showOfflineListView = true;
    }

    processAppointmentsData(graphqlData) {
        this.serviceAppointments = (graphqlData?.uiapi?.query?.AssignedResource?.edges || [])
            .map(e => e.node.ServiceAppointment)
            .filter(Boolean)
            .filter(sa => sa?.ParentRecord?.RecordType?.DeveloperName?.value === this.developerNameFilter)
            .map(sa => ({
                Id: sa.Id,
                Status: sa.Status?.value,
                Appointment_Type__c: sa.Appointment_Type__c?.value,
                SchedStartTime: sa.SchedStartTime?.value,
                Schedule_Start_Date__c: sa.Schedule_Start_Date__c?.value,
                Schedule_End_Date__c: sa.Schedule_End_Date__c?.value,
                Account: sa.Account ? Object.fromEntries(Object.entries(sa.Account).map(([k,v]) => [k, v?.value])) : {}
            }));
        localStorage.setItem(CACHE_KEYS.serviceAppointments, JSON.stringify(this.serviceAppointments));
        this.generateKPIs();
        this.calculateKPIs();
        this.cacheAllData();
    }

    generateKPIs() {
        if (!this.configList.length || !this.serviceAppointments.length) {
            this.kpisResult = [];
            return;
        }
        this.kpisResult = this.configList.map(meta => {
            const fieldName = meta.fieldApiName;
            const values = meta.values.map(v => String(v).toLowerCase());
            let matchingSA = [];

            if (fieldName === 'Status') {
                matchingSA = this.serviceAppointments.filter(sa => {
                    const status = sa.Status?.toLowerCase() || '';
                    if (meta.label === 'Completed' && status === 'completed') return true;
                    if (meta.label === 'Incomplete' && ['cannot complete', 'in progress'].includes(status)) return true;
                    if (meta.label === 'Unattempted' && ['scheduled','none','dispatched'].includes(status)) return true;
                    return false;
                });
            } else {
                matchingSA = this.serviceAppointments.filter(sa => values.includes(String(sa[fieldName]).toLowerCase()));
            }
            return {
                label: meta.label,
                cardColor: meta.cardColor,
                iconUrl: meta.iconUrl,
                count: matchingSA.length,
                order: meta.order,
                styleString: meta.cardColor ? `background-color: ${meta.cardColor}` : '',
                filteredAppointments: matchingSA
            };
        }).sort((a,b) => a.order - b.order);

        localStorage.setItem(CACHE_KEYS.kpisResult, JSON.stringify(this.kpisResult));
    }

    calculateKPIs() {
        const kpiTotals = this.serviceAppointments.reduce((acc, sa) => {
            acc.total++;
            const status = sa.Status?.toLowerCase();
            if (status === 'completed') acc.completed++;
            else if (['cannot complete', 'in progress'].includes(status)) acc.incomplete++;
            else if (['scheduled','none','dispatched'].includes(status)) acc.unattempted++;
            return acc;
        }, { total:0, completed:0, incomplete:0, unattempted:0 });
        this.kpis = kpiTotals;
        localStorage.setItem('oMRiser_kpisCache', JSON.stringify(kpiTotals));
    }

    cacheAllData() {
        try {
            localStorage.setItem(CACHE_KEYS.configs, JSON.stringify(this.configList));
            localStorage.setItem(CACHE_KEYS.kpisResult, JSON.stringify(this.kpisResult));
            localStorage.setItem(CACHE_KEYS.userName, this.userName);
            localStorage.setItem(CACHE_KEYS.serviceAppointments, JSON.stringify(this.serviceAppointments));
        } catch(e){console.error('cacheAllData', e);}
    }

    loadCachedData() {
        this.loadCachedConfig();
        this.loadCachedUser();
        this.loadCachedAppointments();
        this.loadCachedKpi();
        this.loadCachedListView();
    }

 loadCachedListView() {
    try {
        const raw = localStorage.getItem(CACHE_KEYS.listView);
        if (raw) {
            const cachedData = JSON.parse(raw).workOrders || [];
            // Normalize status for offline
            this.workOrders = cachedData.map(wo => {
                let status = wo.appointmentStatus || '';
                if (status.toLowerCase() === 'dispatched') status = 'Unattempted';
                return { ...wo, appointmentStatus: status };
            });
        }
    } catch(e) {
        console.error(e);
    } finally {
        this.isLoading = false;
    }
}


    loadCachedConfig() { try { const raw=localStorage.getItem(CACHE_KEYS.configs); if(raw)this.configList=JSON.parse(raw);} catch(e){console.error(e);} }
    loadCachedAppointments() { try { const raw=localStorage.getItem(CACHE_KEYS.serviceAppointments); if(raw){this.serviceAppointments=JSON.parse(raw); this.generateKPIs(); this.calculateKPIs();}} catch(e){console.error(e);} }
    loadCachedKpi() { try { const raw=localStorage.getItem(CACHE_KEYS.kpisResult); if(raw)this.kpisResult=JSON.parse(raw);} catch(e){console.error(e);} }
    loadCachedUser() { try { const raw=localStorage.getItem(CACHE_KEYS.userName); if(raw)this.userName=raw; this.setGreeting();} catch(e){console.error(e);} }

    onTotalClick(){ this.handleCardClick('All'); }
    onCardClick(e){ this.handleCardClick(e.currentTarget.dataset.card); }

    handleCardClick(action){
       this.visibleListFilter = action || 'All';
        localStorage.setItem('currentSelectedStatus', action);
        localStorage.setItem('navigationTimestamp', new Date().toISOString());

        const selectedKpi = this.kpisResult.find(k=>k.label===action);
        if(selectedKpi) localStorage.setItem('selectedKpiData', JSON.stringify(selectedKpi));

        this.showDashboard = false;
        this.secondPage = true;
        this.openMainPage = false;

        if(this.isOnline){
            this.showOfflineListView = false;
            this.navigateToListView(action);
        } else {
            // Force offline datatable to render
            this.showOfflineListView = true;

            // Trigger datatable refresh by changing reference
            this.workOrders = [...this.workOrders];
            this.isLoading = false;
        }
            }

    navigateToListView(action){
        const listViewName = LIST_VIEWS[action] || LIST_VIEWS.All;
        try{
            this.isNavigating = true;
            this[NavigationMixin.Navigate]({
                type:'standard__objectPage',
                attributes:{objectApiName:'WorkOrder', actionName:'list'},
                state:{filterName:listViewName}
            });
        } catch(e){ console.error(e); this.showToast('Error','Unable to open list view.','error'); this.isNavigating=false;}
        finally{ setTimeout(()=>{this.isNavigating=false;},1200);}
    }

    handleBackFromList(){
        this.secondPage=false;
        this.showDashboard=true;
        this.openMainPage=true;
        this.visibleListFilter='All';
        this.showOfflineListView=false;
    }

    refreshAllData(){
        if(!this.isOnline){ this.showToast('Offline','Cannot refresh while offline','warning'); return; }
        this.showSpinner=true;
        Promise.all([
            this.wiredAppointmentsResult?refreshApex(this.wiredAppointmentsResult):Promise.resolve(),
            this.wiredConfigsResult?refreshApex(this.wiredConfigsResult):Promise.resolve(),
            this.wiredWorkOrdersResult?refreshApex(this.wiredWorkOrdersResult):Promise.resolve()
        ]).then(()=>{ this.showToast('Success','Data refreshed','success'); this.showSpinner=false; this.cacheAllData(); })
        .catch(err=>{console.error(err); this.showToast('Error','Refresh failed','error'); this.showSpinner=false;});
    }

    handleOnline(){
        if(this.isOnline){ this.showToast('Online','You are online','success'); }
        else{ this.showToast('Offline','You are offline','warning'); this.showOfflineListView=true; this.isLoading=false;}
    }

    handleBrowserBack=()=>{ try{ history.pushState({step:'listView'},''); } catch(e){} this.handleBackFromList(); };
    handleMobileBack=(e)=>{ if(document.hidden || e.type==='pagehide') this.handleBackFromList(); };

    cardDetails(){
        this.updateTime();
        this.intervalId=setInterval(()=>this.updateTime(),30000);
        if(this.isOnline)this.autoRefreshTimer=setInterval(()=>this.refreshAllData(),300000);
    }

    updateTime(){
        const now=new Date();
        this.currentDate=now.toLocaleDateString(undefined,{ weekday:'long', year:'numeric', month:'long', day:'numeric' });
        this.currentTime=now.toLocaleTimeString(undefined,{ hour:'2-digit', minute:'2-digit' });
        this.setGreeting();
    }

    setGreeting(){
        const hour=new Date().getHours();
        const name=this.userName||'User';
        if(hour<12)this.greeting=`Good Morning, ${name}`;
        else if(hour<17)this.greeting=`Good Afternoon, ${name}`;
        else this.greeting=`Good Evening, ${name}`;
    }

    showToast(title,message,variant){ this.dispatchEvent(new ShowToastEvent({title,message,variant})); }
}