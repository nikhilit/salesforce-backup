/**
 * @description       : O&M Home Page – Offline GraphQL parity (Metering equivalent)
 * @author            : Appstrail
 * @last modified on  : 06-11-2025
 * @last modified by  : Appstrail
**/
import { LightningElement, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import FORM_FACTOR from '@salesforce/client/formFactor';
import userId from '@salesforce/user/Id';

// ======= ONLINE (Apex) =======
import getUserRec from '@salesforce/apex/O_MAutoHomePageComponentController.getUserName';
import getKPIs from '@salesforce/apex/O_MDashboardContr.getKPIs';
import getCountByMetadataMatch from '@salesforce/apex/O_MDashboardContr.getCountByMetadataMatch';
import { NavigationMixin } from 'lightning/navigation';
// ======= OFFLINE (GraphQL) =======
import { gql, graphql,  refreshGraphQL } from 'lightning/uiGraphQLApi';
import USER_ID from '@salesforce/user/Id';
// ---- GraphQL Queries ----
const GET_ASSIGNED_RESOURCES = gql`
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
          }
        }
      }
    }
  }
}
`;

const GET_TBT_WORKORDER = gql`
query getTBTStatus($userId: ID!) {
  uiapi {
    query {
      WorkOrder(
        where: {
          OwnerId: { eq: $userId }
          RecordType: {
            DeveloperName: { eq: "TBT" }
          }
        }
        first: 1
      ) {
        edges {
          node {
            Id
            Approval_Status__c {
              value
            }
          }
        }
      }
    }
  }
}
`;


export default class O_MMobileHomePageComp extends NavigationMixin(LightningElement) {
  // ---- UI/State ----
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
  @track kpis = { total: 0, completed: 0, incomplete: 0, unattempted: 0 };
  @track kpisResult = [];

  error;
  wiredKpiResult;
  intervalId;
  autoRefreshTimer;
  @track isOnline = navigator.onLine;

  @track configList = [];
  @track serviceAppointments = [];
  @track refreshKey = true;

  connectedCallback() {
    this.init();
    window.addEventListener('online', () => this.syncWhenOnline());
    window.addEventListener('offline', () => {
      this.isOnline = false;
      this.showToast('Offline', 'Switching to GraphQL offline data', 'warning');
    });
  }

  disconnectedCallback() {
    clearInterval(this.intervalId);
    clearInterval(this.autoRefreshTimer);
  }

  init() {
    this.updateTime();
    this.loadOnlineData();
  }

  updateTime() {
    const now = new Date();
    this.currentDate = now.toLocaleDateString(undefined, {
      weekday: 'long', year: 'numeric', month: 'long', day: 'numeric'
    });
    this.currentTime = now.toLocaleTimeString(undefined, { hour: '2-digit', minute: '2-digit' });
    this.setGreeting();
  }

  setGreeting() {
    const hour = new Date().getHours();
    const name = this.userName || 'User';
    this.greeting = hour < 12 ? `Good Morning, ${name}`
      : hour < 17 ? `Good Afternoon, ${name}`
      : `Good Evening, ${name}`;
  }

  // ===== ONLINE (Apex) =====
  loadOnlineData() {
    if (!this.isOnline) return;
    getCountByMetadataMatch()
      .then(result => {
        this.kpisResult = (result || []).map(r => ({
          label: r.label,
          count: Number(r.count || 0),
          cardColor: r.cardColor,
          iconUrl: r.iconUrl
        }));
        requestAnimationFrame(() => this.setCardColor());
      })
      .catch(() => this.showToast('Error', 'Failed loading KPI cards', 'error'));

    getKPIs()
      .then(data => { this.kpis = data || this.kpis; })
      .catch(err => { this.error = err; });
  }

  @wire(getUserRec)
  wiredUser({ data, error }) {
    if (data) {
      this.userName = data.userName;
      this.setGreeting();
    } else if (error) {
      this.error = error;
    }
  }

  @wire(getKPIs)
  wiredKpis(result) {
    this.wiredKpiResult = result;
    const { data, error } = result || {};
    if (data) {
      this.kpis = data;
    } else if (error) {
      this.error = error;
    }
  }

  syncWhenOnline() {
    this.isOnline = true;
    this.showToast('Online', 'You are back online. Syncing data…', 'success');
    this.loadOnlineData();
    refreshApex(this.wiredKpiResult);
  }

  refreshDashboardData() {
    if (this.isOnline && this.wiredKpiResult) {
      refreshApex(this.wiredKpiResult);
    } else {
      this.refreshKey = !this.refreshKey;
    }
  }

  // ===== OFFLINE (GRAPHQL) =====
  get variables() {
    return { userId };
  }

  get configVariables() {
    return { departmentType: 'O&M', refreshKey: this.refreshKey };
  }

  // Load O&M Dashboard Config metadata
  @wire(graphql, { query: GET_METADATA_CONFIG, variables: '$configVariables' })
  wiredConfigs({ error, data }) {
    if (this.isOnline) return;
    if (data && !this.isOnline) {
      const edges = data.uiapi.query.Metering_Dashboard_Config__mdt.edges || [];
      this.configList = edges.map(edge => ({
        label: edge.node.Label__c.value,
        fieldApiName: edge.node.Field_Api_Name__c.value,
        values: (edge.node.Values__c.value || '').split(',').map(v => v.trim().toLowerCase()),
        order: parseInt(edge.node.Order__c.value || 0, 10),
        cardColor: edge.node.Card_Color__c.value,
        iconUrl: edge.node.Icon_URL__c.value
      }));
      //this.showToast('GraphQL', `Loaded ${this.configList.length} metadata configs`, 'info');
      this.checkAndGenerateKPIs();
    } else if (error) {
      this.error = error;
      //this.showToast('GraphQL', `Metadata error: ${error.body?.message || error}`, 'error');
    }
  }

  // Load AssignedResource → ServiceAppointment
  @wire(graphql, { query: GET_ASSIGNED_RESOURCES, variables: '$variables' })
  wiredAssignedResources({ error, data }) {
    if (this.isOnline) return;
    if (error) {
      this.error = error;
      this.showToast('GraphQL', `Error: ${error.body?.message || error}`, 'error');
      return;
    }
    if (data && !this.isOnline) {
      const allAppointments = (data?.uiapi?.query?.AssignedResource?.edges || [])
        .map(e => e.node?.ServiceAppointment)
        .filter(Boolean)
        .filter(sa => sa?.ParentRecord?.RecordType?.DeveloperName?.value === 'MGL_O_M');
        const today = new Date().toISOString().split('T')[0];
        this.serviceAppointments = allAppointments.filter(sa => {
          const hasTimes = sa?.SchedStartTime?.value && sa?.SchedEndTime?.value;
          const start = sa?.Schedule_Start_Date__c?.value;
          const end = sa?.Schedule_End_Date__c?.value;
          return hasTimes && start <= today && end >= today;
        });
      this.serviceAppointments = allAppointments;
      //this.showToast('GraphQL', `Loaded ${allAppointments.length} O&M appointments`, 'info');
      this.checkAndGenerateKPIs();
    }
  }

  checkAndGenerateKPIs() {
    if (this.isOnline) return;
    if (this.configList.length > 0 && this.serviceAppointments.length > 0) {
      this.generateKPIs();
      //this.showToast('GraphQL', 'Offline KPI Computed Successfully ', 'success');
    }
  }

  generateKPIs() {
    const appointments = this.serviceAppointments || [];
    if (!this.configList.length || !appointments.length) {
      this.kpisResult = [];
      return;
    }

    const results = this.configList.map(meta => {
      const fieldName = meta.fieldApiName;
      const values = meta.values.map(v => v.toLowerCase());
      const label = meta.label;
      const color = meta.cardColor;
      const icon = meta.iconUrl;
      const order = meta.order;

      const matching = appointments.filter(sa => {
        const value = sa[fieldName]?.value;
        if (!value) return false;
        return values.includes(String(value).toLowerCase());
      });

      return { label, cardColor: color, iconUrl: icon, count: matching.length, order };
    });

    this.kpisResult = results.sort((a, b) => a.order - b.order);
    this.kpis.total = appointments.length;
    this.kpis.completed = appointments.filter(sa => sa.Status?.value === 'Completed').length;
    this.kpis.incomplete = appointments.filter(sa => sa.Status?.value === 'Cannot Complete').length;
    this.kpis.unattempted = this.kpis.total - (this.kpis.completed + this.kpis.incomplete);
    requestAnimationFrame(() => this.setCardColor());
  }

  // ===== UI =====
  showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }

  setCardColor() {
    if (!Array.isArray(this.kpisResult)) return;
    this.kpisResult.forEach(item => {
      const elm = this.template.querySelector(`[data-card="${item.label}"]`);
      if (elm && item.cardColor) elm.style.backgroundColor = item.cardColor;
    });
  }

  onTotalClick() {
    this.selectedType = null;
    this._togglePage('total', null);
  }

  onCardCLick(event) {
    const action = event.currentTarget.dataset.card;
    this.selectedType = 'All';
    switch (action) {
      case 'Unattempted': this._togglePage('unattempted'); break;
      case 'Completed': this._togglePage('completed'); break;
      case 'Incomplete': this._togglePage('incomplete'); break;
      default: break;
    }
  }

  _togglePage(status, appointmentType = null) {
    this.showSpinner = true;
    this.selectedType = appointmentType;
    this.selectedStatus = status;
    this.showChild = true;
    this.showDashboard = false;
    this.secondPage = true;
    this.openMainPage = false;
    setTimeout(() => { this.showSpinner = false; }, 400);
  }

  handleChildEvent(event) {
    this.secondPage = event.detail.secondPage;
    this.showDashboard = event.detail.showDashboard;
    this.showChild = false;
    this.openMainPage = event.detail.openMainPage;
    this.selectedType = 'All';
    requestAnimationFrame(() => this.setCardColor());
  }

  
  @track tbtStatus = 'Upload TBT'; 
  @track tbtrecordid='';  
                    
    handleuploadtbtdo() {
        console.log('Upload TBT');
        console.log(' this.tbtrecordid::::', this.tbtrecordid);
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.tbtrecordid,
                objectApiName: 'WorkOrder',
                actionName: 'view'
            }
        });
    }

        handlerefreshtbtdo(event) {
          console.log('handlerefreshtbtdo::');

        
            event.stopPropagation(); 
              if (this.wiredTbtResult) {
        refreshApex(this.wiredTbtResult);
              }
    }

    wiredTBTWorkOrderResult;


    @wire(graphql, {
        query: GET_TBT_WORKORDER,
        variables: {
            userId: USER_ID
        }
    })
    wiredWorkOrder(result) {

      console.log('wiredWorkOrderTBT::');
        this.wiredTBTWorkOrderResult = result; 

        const { data, errors } = result;

        if (data) {
            const edges = data.uiapi.query.WorkOrder.edges;
            if (edges.length > 0) {
                const wo = edges[0].node;
                this.tbtrecordid = wo.Id;
                console.log('approval status:::',wo.Approval_Status__c.value);
                if(wo.Approval_Status__c.value !='Pending'){
                this.tbtStatus =  'Approval Status : ' + ' ' +  wo.Approval_Status__c.value;
                }
                else if (wo.Approval_Status__c.value == null || wo.Approval_Status__c.value === 'Pending'){
                  this.tbtStatus = 'Upload TBT';
                }else{
                  this.tbtStatus=wo.Approval_Status__c.value;
                }
              
            }
         
            console.log(' this.tbtStatus :::', this.tbtStatus );
            console.log(' this.tbtrecordid::::', this.tbtrecordid);

        } else if (errors) {
            console.error(errors);
        }
    }

    handletbtRefresh(event) {

         console.log('before true showspinner::', this.showSpinner);

  this.showSpinner = true;
    console.log('showspinner::', this.showSpinner);
      console.log('refresh::');
      event.stopPropagation(); 
        if (this.wiredTBTWorkOrderResult) {
          console.log('inside if::');
              refreshGraphQL(this.wiredTBTWorkOrderResult);
        }
           console.log('handletbtRefresh::');

           setTimeout(() => {
      this.showSpinner = false;
    }, 500);
 // }
    }

}